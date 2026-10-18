"""Braillix cell wiring diagrams -> PDF."""
import sys
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.colors import HexColor, white

W, H = landscape(A4)

RED    = HexColor("#cc0000")
BLACK  = HexColor("#111111")
BLUE   = HexColor("#0044cc")
YELLOW = HexColor("#a07800")
ORANGE = HexColor("#d2691e")
PINK   = HexColor("#cc0088")
GREEN  = HexColor("#0a7d33")
GREY   = HexColor("#9aa3ad")
SLATE  = HexColor("#5a6472")
NAVY   = HexColor("#1b3a6b")
FILL   = HexColor("#eef2f7")
WARN   = HexColor("#b00020")

c = canvas.Canvas(sys.argv[1], pagesize=landscape(A4))

Y5, Y33, YG = 508, 478, 62


def title(t, sub):
    c.setFillColor(NAVY); c.setFont("Helvetica-Bold", 15)
    c.drawString(40, H - 40, t)
    c.setFillColor(HexColor("#555555")); c.setFont("Helvetica", 8.2)
    c.drawString(40, H - 53, sub)
    c.setStrokeColor(HexColor("#cfd6de")); c.setLineWidth(0.8)
    c.line(40, H - 60, W - 40, H - 60)


def box(x, y, w, h, name, sub=None):
    c.setFillColor(FILL); c.setStrokeColor(NAVY); c.setLineWidth(1.2)
    c.rect(x, y, w, h, fill=1, stroke=1)
    c.setFillColor(NAVY); c.rect(x, y + h - 15, w, 15, fill=1, stroke=0)
    c.setFillColor(white); c.setFont("Helvetica-Bold", 8.5)
    c.drawCentredString(x + w / 2, y + h - 11, name)
    if sub:
        c.setFillColor(HexColor("#666666")); c.setFont("Helvetica", 6.2)
        c.drawCentredString(x + w / 2, y + h - 25, sub)


def txt(x, y, s, align="left", size=6.8, col=None, bold=False):
    c.setFillColor(col or HexColor("#222222"))
    c.setFont("Helvetica-Bold" if bold else "Helvetica", size)
    {"left": c.drawString, "right": c.drawRightString,
     "mid": c.drawCentredString}[align](x, y - 2.3, s)


def wire(pts, col, lw=1.5, dash=None):
    c.setStrokeColor(col); c.setLineWidth(lw); c.setDash(dash or [])
    for i in range(len(pts) - 1):
        c.line(pts[i][0], pts[i][1], pts[i + 1][0], pts[i + 1][1])
    c.setDash()


def dot(x, y, col, r=2.3):
    c.setFillColor(col); c.circle(x, y, r, fill=1, stroke=0)


def tag(x, y, s, col, size=6.3):
    tw = c.stringWidth(s, "Helvetica-Bold", size)
    c.setFillColor(white); c.setStrokeColor(col); c.setLineWidth(0.6)
    c.rect(x - tw / 2 - 2.5, y - 4.3, tw + 5, 9.2, fill=1, stroke=1)
    c.setFillColor(col); c.setFont("Helvetica-Bold", size)
    c.drawCentredString(x, y - 1.9, s)


def res(x, y, label=""):
    c.setFillColor(white); c.setStrokeColor(HexColor("#333333")); c.setLineWidth(0.9)
    c.rect(x - 4, y - 8, 8, 16, fill=1, stroke=1)
    if label:
        txt(x + 7, y, label, size=5.9, col=HexColor("#333333"))


def caution(x, y, w, s):
    c.setFillColor(HexColor("#fdf0f2")); c.setStrokeColor(WARN); c.setLineWidth(0.9)
    c.rect(x, y, w, 24, fill=1, stroke=1)
    c.setFillColor(WARN); c.setFont("Helvetica-Bold", 7)
    c.drawString(x + 7, y + 14, "CAUTION")
    c.setFillColor(HexColor("#3a3a3a")); c.setFont("Helvetica", 6.8)
    c.drawString(x + 7, y + 4.8, s)


# ========================= PAGE 1 =========================
title("Braillix - one cell, every connection",
      "Power at the top, ground at the bottom, signal left to right. "
      "Crossing lines are NOT joined; a dot marks a join. Revision 2026-10-18.")

wire([(48, Y5), (W - 48, Y5)], RED, 2.3)
txt(48, Y5 + 8, "5 V RAIL   -   adapter, motor, driver, hall sensor", col=RED, bold=True, size=7.6)
wire([(48, Y33), (470, Y33)], ORANGE, 2.0)
txt(470, Y33 + 7, "3.3 V   -   logic only, from the ESP32 3V3 pin", "right", col=ORANGE, bold=True, size=7.2)
wire([(48, YG), (W - 48, YG)], BLACK, 2.3)
txt(48, YG - 11, "GROUND RAIL   -   shared by everything", col=BLACK, bold=True, size=7.6)

box(52, 300, 122, 160, "ESP32 DevKit", "3.3 V logic")
box(262, 240, 170, 230, "MCP23017", "expander, address 0x20")
box(522, 300, 140, 160, "ULN2003AN", "DIP-16, in a socket")
box(722, 310, 100, 115, "28BYJ-48", "stepper motor")
box(290, 140, 145, 58, "A3144 hall", "TO-92")
box(52, 112, 160, 104, "5-pin pogo", "dock, to cell 2")

# --- pin stubs + inside labels ---
for yy, nm in ((420, "3V3"), (370, "GPIO 21"), (350, "GPIO 22")):
    wire([(174, yy), (188, yy)], GREY, 1.0); txt(168, yy, nm, "right", bold=True)
for yy, nm in ((420, "9  VDD"), (370, "13 SDA"), (350, "12 SCL")):
    wire([(248, yy), (262, yy)], GREY, 1.0); txt(268, yy, nm)
for yy, nm in ((420, "21 GPA0"), (400, "22 GPA1"), (380, "23 GPA2"), (360, "24 GPA3")):
    wire([(432, yy), (446, yy)], GREY, 1.0); txt(426, yy, nm, "right")
for yy, nm in ((420, "1 IN1"), (400, "2 IN2"), (380, "3 IN3"), (360, "4 IN4")):
    wire([(508, yy), (522, yy)], GREY, 1.0); txt(528, yy, nm)
for yy, nm in ((420, "16 OUT1"), (400, "15 OUT2"), (380, "14 OUT3"), (360, "13 OUT4")):
    wire([(662, yy), (676, yy)], GREY, 1.0); txt(656, yy, nm, "right")

txt(268, 300, "15 A0   16 A1   17 A2   ->  GND", size=6.5, col=HexColor("#444444"))
txt(268, 288, "18 RESET  ->  VDD", size=6.8, col=WARN, bold=True)
txt(268, 276, "100nF across pins 9 and 10", size=6.5, col=HexColor("#444444"))
txt(268, 262, "1 GPB0  <-  hall OUT", size=6.5, col=GREEN)

# --- ESP32 -> MCP ---
wire([(188, 420), (248, 420)], ORANGE, 1.6)
wire([(210, 420), (210, Y33)], ORANGE, 1.6); dot(210, Y33, ORANGE); dot(210, 420, ORANGE)
wire([(188, 370), (248, 370)], BLUE, 1.6); tag(218, 378, "SDA", BLUE)
wire([(188, 350), (248, 350)], YELLOW, 1.6); tag(218, 342, "SCL", YELLOW)
for xx, yy, col in ((228, 370, BLUE), (240, 350, YELLOW)):
    dot(xx, yy, col, 1.9)
    wire([(xx, yy), (xx, 422)], col, 1.0)
    res(xx, 430)
    wire([(xx, 438), (xx, Y33)], col, 1.0); dot(xx, Y33, col, 1.9)
txt(250, 493, "2 x 4.7k pull-ups to 3.3 V - fit ONCE, beside the ESP32 only",
    size=6.4, col=HexColor("#444444"))

# ESP32 ground
wire([(100, 300), (100, YG)], BLACK, 1.6); dot(100, YG, BLACK)
txt(104, 265, "GND", size=6.5, col=BLACK)
# MCP ground
wire([(274, 240), (274, YG)], BLACK, 1.6); dot(274, YG, BLACK)
txt(278, 230, "10 VSS", size=6.5, col=BLACK)

# --- MCP -> ULN (straight, aligned) ---
for yy in (420, 400, 380, 360):
    wire([(446, yy), (508, yy)], SLATE, 1.5)
tag(477, 438, "GPA0-3  ->  IN1-4", SLATE)

# --- ULN -> motor ---
for ya, yb, col in ((420, 395, BLUE), (400, 375, PINK), (380, 355, YELLOW), (360, 335, ORANGE)):
    wire([(676, ya), (700, ya), (700, yb), (722, yb)], col, 1.6)
txt(676, 296, "BLUE  PINK  YELLOW  ORANGE", size=6.0, col=HexColor("#444444"))

# ULN COM up, GND down
wire([(580, 460), (580, Y5)], RED, 1.7); dot(580, Y5, RED)
tag(580, 487, "9 COM", RED)
wire([(620, 300), (620, YG)], BLACK, 1.7); dot(620, YG, BLACK)
txt(624, 150, "8 GND", size=6.5, col=BLACK)
# motor centre tap
wire([(772, 425), (772, Y5)], RED, 1.7); dot(772, Y5, RED)
tag(772, 487, "RED centre tap", RED)

# --- hall ---
wire([(400, 198), (400, 240)], GREEN, 1.6)
dot(400, 215, GREEN, 1.9)
wire([(400, 215), (452, 215), (452, Y33)], ORANGE, 1.1)
res(452, 300, "10k")
dot(452, Y33, ORANGE)
wire([(435, 168), (466, 168), (466, Y5)], RED, 1.4); dot(466, Y5, RED)
txt(438, 158, "VCC 5 V", size=6.2, col=RED)
wire([(330, 140), (330, YG)], BLACK, 1.5); dot(330, YG, BLACK)
txt(334, 110, "GND", size=6.2, col=BLACK)

# --- pogo ---
for i, (nm, col) in enumerate([("1  GND", BLACK), ("2  SCL", YELLOW), ("3  5 V", RED),
                               ("4  SDA", BLUE), ("5  GND or 3V3 - undecided", GREY)]):
    yy = 186 - i * 11
    dot(64, yy, col, 2.4); txt(74, yy, nm, size=6.4, col=col, bold=True)
txt(60, 124, "Joins the same four rails. Nothing to test until cell 2 exists.",
    size=5.9, col=HexColor("#666666"))

caution(48, 14, 380, "Pin 9 COM must reach 5 V, or the coil kickback destroys the driver.")
caution(442, 14, 352, "MCP pin 18 RESET must reach VDD, or the chip never answers.")
c.showPage()

# ========================= PAGE 2 =========================
def dip_card(cx, top, n, names, used, notes, label, pitch=15.2, bw=96):
    half = n // 2
    bh = (half - 1) * pitch + 28
    by = top - bh
    c.setFillColor(HexColor("#f6f7f9")); c.setStrokeColor(HexColor("#333333"))
    c.setLineWidth(1.3); c.rect(cx - bw / 2, by, bw, bh, fill=1, stroke=1)
    c.setFillColor(HexColor("#333333")); c.circle(cx - bw / 2 + 11, top - 13, 3.6, fill=1, stroke=0)
    c.setFillColor(HexColor("#777777")); c.setFont("Helvetica-Oblique", 6.2)
    c.drawCentredString(cx, by + 9, label)
    for i in range(half):
        yy = top - 15 - i * pitch
        for sx, num in ((-1, i + 1), (1, n - i)):
            on = num in used
            col = HexColor("#111111") if on else GREY
            x0 = cx + sx * bw / 2
            wire([(x0, yy), (x0 + sx * 12, yy)], col, 1.7 if on else 0.8)
            if on:
                dot(x0 + sx * 12, yy, col, 2.1)
            txt(x0 + sx * 16, yy, "%d %s" % (num, names[num]),
                "left" if sx > 0 else "right", 6.9, col, on)
            if on and num in notes:
                txt(x0 + sx * 70, yy, notes[num], "left" if sx > 0 else "right",
                    6.3, GREEN)


title("Pin 1, and the pins you actually wire",
      "Bold = wire it. Grey = leave it alone. The black dot marks pin 1 - note that pin 1 and the "
      "HIGHEST pin number sit at the same end, facing each other.")

mcp = {1: "GPB0", 2: "GPB1", 3: "GPB2", 4: "GPB3", 5: "GPB4", 6: "GPB5", 7: "GPB6", 8: "GPB7",
       9: "VDD", 10: "VSS", 11: "NC", 12: "SCL", 13: "SDA", 14: "NC", 15: "A0", 16: "A1",
       17: "A2", 18: "RESET", 19: "INTB", 20: "INTA", 21: "GPA0", 22: "GPA1", 23: "GPA2",
       24: "GPA3", 25: "GPA4", 26: "GPA5", 27: "GPA6", 28: "GPA7"}
dip_card(228, H - 86, 28, mcp,
         {1, 9, 10, 12, 13, 15, 16, 17, 18, 21, 22, 23, 24},
         {1: "hall OUT", 9: "3.3 V", 10: "GND", 12: "GPIO 22", 13: "GPIO 21",
          15: "GND", 16: "GND", 17: "GND", 18: "VDD", 21: "IN1", 22: "IN2",
          23: "IN3", 24: "IN4"},
         "MCP23017-E/SO    SOIC-28")

uln = {1: "IN1", 2: "IN2", 3: "IN3", 4: "IN4", 5: "IN5", 6: "IN6", 7: "IN7", 8: "GND",
       9: "COM", 10: "OUT7", 11: "OUT6", 12: "OUT5", 13: "OUT4", 14: "OUT3",
       15: "OUT2", 16: "OUT1"}
dip_card(600, H - 86, 16, uln, {1, 2, 3, 4, 8, 9, 13, 14, 15, 16},
         {1: "GPA0", 2: "GPA1", 3: "GPA2", 4: "GPA3", 8: "GND", 9: "5 V",
          13: "ORANGE", 14: "YELLOW", 15: "PINK", 16: "BLUE"},
         "ULN2003AN    DIP-16")

# voltage map
bx, by, bw2, bh2 = 440, 96, 362, 150
c.setFillColor(HexColor("#f4f8f4")); c.setStrokeColor(GREEN); c.setLineWidth(1.1)
c.rect(bx, by, bw2, bh2, fill=1, stroke=1)
c.setFillColor(GREEN); c.setFont("Helvetica-Bold", 9)
c.drawString(bx + 10, by + bh2 - 16, "Which part runs on which voltage")
rows = [("5 V", "motor, ULN2003 driver, A3144 hall sensor", RED),
        ("3.3 V", "ESP32, MCP23017 expander", ORANGE)]
yy = by + bh2 - 36
for v, who, col in rows:
    c.setFillColor(col); c.setFont("Helvetica-Bold", 8)
    c.drawString(bx + 12, yy, v)
    c.setFillColor(HexColor("#333333")); c.setFont("Helvetica", 7.2)
    c.drawString(bx + 52, yy, who)
    yy -= 15
c.setFillColor(HexColor("#333333")); c.setFont("Helvetica", 7)
for i, t in enumerate([
    "The adapter gives 5 V. The ESP32 board already contains a 3.3 V regulator,",
    "because it runs its own chip at 3.3 V. Its 3V3 pin is that regulator's output.",
    "So you do not buy or build anything: one wire from 3V3 feeds the expander.",
    "",
    "The expander would also run at 5 V. It is set to 3.3 V so that it matches the",
    "ESP32 on the two I2C wires they share. A chip reads a HIGH at 70 percent of",
    "its own supply: at 5 V that is 3.5 V, and the ESP32 can only ever send 3.3 V."]):
    c.drawString(bx + 12, yy - 6 - i * 10, t)

# A3144
c.setFillColor(HexColor("#333333")); c.setFont("Helvetica-Bold", 8.5)
c.drawString(440, 348, "A3144 hall sensor, TO-92")
c.setFont("Helvetica", 7)
c.setFillColor(HexColor("#444444"))
for i, t in enumerate(["Flat face toward you, legs pointing down:",
                       "left = VCC (5 V)      middle = GND      right = OUT",
                       "OUT also needs a 10k resistor up to 3.3 V.",
                       "Unipolar - it answers to one magnet pole only."]):
    c.drawString(440, 334 - i * 11, t)

caution(48, 42, 754,
        "The MCP23017 is glued PINS UP, so its printed text faces the board and the numbering "
        "runs the opposite way round. Mark pin 1 on the board with a pen before you glue it down.")
c.showPage()
c.save()
print("wrote", sys.argv[1])
