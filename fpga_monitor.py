#!/usr/bin/env python3

import argparse
import curses
import sys
import threading
import time
from collections import deque
from datetime import datetime

try:
    import serial  # pyserial
except ImportError:
    serial = None


ABI_NAMES = [
    "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
    "s0", "s1", "a0", "a1", "a2", "a3", "a4", "a5",
    "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
    "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6",
]


class Entry:
    """A single parsed write-back event."""
    __slots__ = ("seq", "ts", "reg", "value", "raw")

    def __init__(self, seq, reg, value, raw):
        self.seq = seq
        self.ts = datetime.now()
        self.reg = reg          # int 0..31, or None if unparseable
        self.value = value      # int 0..0xFFFFFFFF, or None
        self.raw = raw          # original stripped line

    def signed(self):
        if self.value is None:
            return None
        return self.value - (1 << 32) if self.value & 0x8000_0000 else self.value

    def reg_label(self):
        if self.reg is None:
            return "??"
        return f"x{self.reg}/{ABI_NAMES[self.reg]}"

    def format_row(self):
        ts = self.ts.strftime("%H:%M:%S")
        if self.reg is None or self.value is None:
            return f"{self.seq:>6} {ts}  [unparsed] {self.raw}"
        return (
            f"{self.seq:>6} {ts}  "
            f"{self.reg_label():<8} "
            f"hex={self.value:08X}  "
            f"u={self.value:>10}  "
            f"s={self.signed():>11}"
        )

    def csv_row(self):
        if self.reg is None or self.value is None:
            return f"{self.seq},{self.ts.isoformat()},,,,{self.raw}"
        return (
            f"{self.seq},{self.ts.isoformat()},{self.reg},"
            f"{ABI_NAMES[self.reg]},{self.value:08X},"
            f"{self.value},{self.signed()}"
        )


def parse_line(text):
    """Parse 'RR=VVVVVVVV'. Returns (reg:int, value:int) or (None, None)."""
    text = text.strip()
    if "=" not in text:
        return None, None
    left, _, right = text.partition("=")
    try:
        reg = int(left, 16)
        value = int(right, 16)
    except ValueError:
        return None, None
    if not (0 <= reg <= 31) or not (0 <= value <= 0xFFFF_FFFF):
        return None, None
    return reg, value


class SerialReader(threading.Thread):
    """Background thread: reads lines from the serial port into a shared buffer."""

    def __init__(self, port, baud, store, log_fp=None):
        super().__init__(daemon=True)
        self.port = port
        self.baud = baud
        self.store = store          
        self.log_fp = log_fp
        self.running = True
        self.error = None

    def run(self):
        try:
            ser = serial.Serial(self.port, self.baud, timeout=0.2)
        except Exception as e: 
            self.error = f"Could not open {self.port}: {e}"
            return
        buf = b""
        while self.running:
            try:
                chunk = ser.read(256)
            except Exception as e: 
                self.error = f"Read error: {e}"
                break
            if chunk:
                buf += chunk
                buf = buf.replace(b"\r", b"\n")
                while b"\n" in buf:
                    line, _, buf = buf.partition(b"\n")
                    s = line.decode("ascii", errors="replace").strip()
                    if s:
                        reg, value = parse_line(s)
                        self.store.add(reg, value, s, self.log_fp)
        ser.close()

    def stop(self):
        self.running = False


class Store:
    """Thread-safe ring buffer of entries with a filter."""

    def __init__(self, maxlen=100_000):
        self.lock = threading.Lock()
        self.entries = deque(maxlen=maxlen)
        self.seq = 0
        self.filter_reg = None  # int or None

    def add(self, reg, value, raw, log_fp):
        with self.lock:
            self.seq += 1
            e = Entry(self.seq, reg, value, raw)
            self.entries.append(e)
        if log_fp:
            log_fp.write(e.csv_row() + "\n")
            log_fp.flush()

    def view(self):
        """Return the list of entries passing the current filter."""
        with self.lock:
            if self.filter_reg is None:
                return list(self.entries)
            return [e for e in self.entries if e.reg == self.filter_reg]

    def clear(self):
        with self.lock:
            self.entries.clear()


class Monitor:
    def __init__(self, stdscr, store, reader, port, baud):
        self.scr = stdscr
        self.store = store
        self.reader = reader
        self.port = port
        self.baud = baud
        self.top = 0           
        self.follow = True
        self.message = ""

    def run(self):
        curses.curs_set(0)
        self.scr.nodelay(True)
        self.scr.timeout(150)
        try:
            curses.mousemask(curses.ALL_MOUSE_EVENTS)
        except curses.error:
            pass
        while True:
            self.draw()
            ch = self.scr.getch()
            if ch == -1:
                continue
            if not self.handle_key(ch):
                break

    def body_height(self):
        h, _ = self.scr.getmaxyx()
        return max(1, h - 3)  # header + footer + status

    def handle_key(self, ch):
        view_len = len(self.store.view())
        page = self.body_height()
        if ch in (ord("q"), ord("Q")):
            return False
        elif ch == curses.KEY_UP:
            self.follow = False
            self.top = max(0, self.top - 1)
        elif ch == curses.KEY_DOWN:
            self.top += 1
            self._clamp(view_len)
        elif ch == curses.KEY_PPAGE:  # PgUp
            self.follow = False
            self.top = max(0, self.top - page)
        elif ch == curses.KEY_NPAGE:  # PgDn
            self.top += page
            self._clamp(view_len)
        elif ch == curses.KEY_HOME:
            self.follow = False
            self.top = 0
        elif ch == curses.KEY_END:
            self.follow = True
        elif ch in (ord("f"), ord("F")):
            self.follow = not self.follow
        elif ch in (ord("c"), ord("C")):
            self.store.clear()
            self.top = 0
        elif ch == ord("/"):
            self.prompt_filter()
        elif ch == curses.KEY_MOUSE:
            try:
                _, _, _, _, bstate = curses.getmouse()
                if bstate & curses.BUTTON4_PRESSED:      # wheel up
                    self.follow = False
                    self.top = max(0, self.top - 3)
                elif bstate & getattr(curses, "BUTTON5_PRESSED", 0):  # wheel down
                    self.top += 3
                    self._clamp(view_len)
            except curses.error:
                pass
        return True

    def _clamp(self, view_len):
        max_top = max(0, view_len - self.body_height())
        if self.top >= max_top:
            self.top = max_top
            self.follow = True
        self.top = max(0, min(self.top, max_top))

    def prompt_filter(self):
        curses.echo()
        self.scr.timeout(-1)
        h, w = self.scr.getmaxyx()
        self.scr.move(h - 1, 0)
        self.scr.clrtoeol()
        self.scr.addstr(h - 1, 0, "Filter register (0-31, blank=clear): ")
        try:
            raw = self.scr.getstr(h - 1, 37, 4).decode("ascii", "replace").strip()
        except curses.error:
            raw = ""
        curses.noecho()
        self.scr.timeout(150)
        if raw == "":
            self.store.filter_reg = None
            self.message = "Filter cleared"
        else:
            try:
                r = int(raw)
                if 0 <= r <= 31:
                    self.store.filter_reg = r
                    self.message = f"Filtering x{r}/{ABI_NAMES[r]}"
                else:
                    self.message = "Register out of range"
            except ValueError:
                self.message = "Invalid register"
        self.top = 0
        self.follow = True

    def safe_addstr(self, y, x, text, attr=curses.A_NORMAL):
        h, w = self.scr.getmaxyx()
        if y < 0 or y >= h:
            return
        maxlen = max(0, w - 1)          # leave the last column untouched
        text = text[:maxlen].ljust(maxlen)
        try:
            self.scr.addnstr(y, x, text, maxlen, attr)
        except curses.error:
            pass

    def draw(self):
        self.scr.erase()
        h, w = self.scr.getmaxyx()
        body = self.body_height()
        view = self.store.view()

        if self.follow:
            self.top = max(0, len(view) - body)

        # Header
        flt = (f"  filter=x{self.store.filter_reg}"
               if self.store.filter_reg is not None else "")
        header = f" FPGA monitor  {self.port} @ {self.baud}  ({len(view)} lines){flt}"
        self.safe_addstr(0, 0, header, curses.A_REVERSE)

        # Body
        for row, e in enumerate(view[self.top:self.top + body]):
            attr = curses.A_DIM if (e.reg is None) else curses.A_NORMAL
            self.safe_addstr(1 + row, 0, e.format_row(), attr)

        # Status / footer
        mode = "FOLLOW" if self.follow else "PAUSED"
        pos = f"{self.top + 1}-{min(self.top + body, len(view))}/{len(view)}"
        status = f" [{mode}] {pos}   {self.message}"
        self.safe_addstr(h - 2, 0, status, curses.A_REVERSE)
        keys = " Up/Dn PgUp/PgDn Home/End  f=follow  /=filter  c=clear  q=quit"
        self.safe_addstr(h - 1, 0, keys)

        if self.reader.error:
            self.safe_addstr(h - 2, 0,
                             " ERROR: " + self.reader.error,
                             curses.A_BOLD)
        self.scr.refresh()


def main():
    ap = argparse.ArgumentParser(
        description="Scrollable terminal monitor for the RISC-V FPGA UART stream.")
    ap.add_argument("port", help="serial device, e.g. /dev/ttyUSB1 or COM3")
    ap.add_argument("--baud", type=int, default=115200, help="baud rate (default 115200)")
    ap.add_argument("--log", metavar="FILE", help="also append parsed rows as CSV to FILE")
    args = ap.parse_args()

    if serial is None:
        sys.exit("pyserial is not installed. Run:  pip install pyserial")

    log_fp = None
    if args.log:
        log_fp = open(args.log, "a", buffering=1)
        if log_fp.tell() == 0:
            log_fp.write("seq,timestamp,reg,abi,hex,unsigned,signed\n")

    store = Store()
    reader = SerialReader(args.port, args.baud, store, log_fp)
    reader.start()

    try:
        curses.wrapper(lambda scr: Monitor(scr, store, reader, args.port, args.baud).run())
    finally:
        reader.stop()
        if log_fp:
            log_fp.close()


if __name__ == "__main__":
    main()