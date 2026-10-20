#!/usr/bin/env python3
"""Drive the booted iOS Simulator without UI-automation tools (iOS standard §2.6).

Usage:  sim-drive.py <udid> <outdir> cmd [args] ...
  tap X Y          tap at logical point (393-pt iPhone coordinates, top-left origin)
  drag X1 Y1 X2 Y2 slow drag (use for scrolling: drag 196 650 196 250 = scroll down)
  shot NAME        save <outdir>/NAME.png (full res) and NAME-sm.png (590 wide preview)
  sleep S
Finds the Simulator window via System Events, so it works wherever the window is.
Assumes an iPhone 16-class device bezel (screen inset 26,72 pt inside a 447-pt-wide window
at default zoom); re-measure with `screencapture` if the device or zoom changes.
"""
import sys, time, subprocess
import Quartz
def window_origin():
    out = subprocess.run(['osascript', '-e', 'tell application "System Events" to tell process "Simulator" to get position of window 1'], capture_output=True, text=True).stdout
    x, y = [int(v) for v in out.strip().split(',')]
    return x + 26, y + 72
udid, outdir, cmds = sys.argv[1], sys.argv[2], sys.argv[3:]
subprocess.run(['osascript', '-e', 'tell application "Simulator" to activate']); time.sleep(0.5)
OX, OY = window_origin()
def ev(kind, x, y): Quartz.CGEventPost(Quartz.kCGHIDEventTap, Quartz.CGEventCreateMouseEvent(None, kind, (x, y), Quartz.kCGMouseButtonLeft))
def tap(x, y):
    x, y = OX + x, OY + y; ev(Quartz.kCGEventMouseMoved, x, y); time.sleep(0.05); ev(Quartz.kCGEventLeftMouseDown, x, y); time.sleep(0.06); ev(Quartz.kCGEventLeftMouseUp, x, y)
def drag(x1, y1, x2, y2, steps=30):
    x1, y1, x2, y2 = OX + x1, OY + y1, OX + x2, OY + y2
    ev(Quartz.kCGEventMouseMoved, x1, y1); time.sleep(0.1); ev(Quartz.kCGEventLeftMouseDown, x1, y1); time.sleep(0.15)
    for i in range(1, steps + 1): ev(Quartz.kCGEventLeftMouseDragged, x1 + (x2 - x1) * i / steps, y1 + (y2 - y1) * i / steps); time.sleep(0.02)
    time.sleep(0.1); ev(Quartz.kCGEventLeftMouseUp, x2, y2)
def shot(name):
    p = f'{outdir}/{name}.png'; subprocess.run(['xcrun', 'simctl', 'io', udid, 'screenshot', p], capture_output=True)
    subprocess.run(['sips', '--resampleWidth', '590', p, '--out', f'{outdir}/{name}-sm.png'], capture_output=True)
i = 0
while i < len(cmds):
    c = cmds[i]
    if c == 'tap': tap(float(cmds[i+1]), float(cmds[i+2])); i += 3; time.sleep(1.2)
    elif c == 'drag': drag(*map(float, cmds[i+1:i+5])); i += 5; time.sleep(1.0)
    elif c == 'shot': shot(cmds[i+1]); i += 2
    elif c == 'sleep': time.sleep(float(cmds[i+1])); i += 2
    else: sys.exit(f'unknown command {c}')
