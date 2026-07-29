# 📖 Braillix — Assembly Bible & Wiring Guide

Follow this guide sequentially to build your first single-cell prototype.

---

## 🛑 SECTION 1: CRITICAL SAFETY CHECKS (DO THIS FIRST)

> [!CAUTION]
> **BARREL JACK POLARITY CHECK**
> The yellow screw-terminal adapter has no visible markings. If you wire 5V backwards, the ULN2003 chip will violently burn out.
> 1. Plug the 5V adapter into the wall.
> 2. Plug the barrel jack into the yellow screw terminal.
> 3. Turn on your Multimeter and set it to **DC Voltage (V DC)**.
> 4. Touch the RED probe to one screw terminal and the BLACK probe to the other.
> 5. If the screen reads **`5.0V`**, the terminal the RED probe is touching is the **POSITIVE (+)** side.
> 6. If the screen reads **`-5.0V`** (negative), the terminal the BLACK probe is touching is the **POSITIVE (+)** side.
> 7. MARK the positive side with a sharpie or tape immediately.

---

## ⚡ SECTION 2: WIRING DIAGRAM

We are wiring the **ESP32**, **ULN2003**, and **Hall Sensor** together.

```text
[5V/3A Adapter] 
      |
      +---> (+) ---> [BREADBOARD 5V RAIL] ---> ULN2003 (+) power pin
      |
      +---> (-) ---> [BREADBOARD GND RAIL] ---> ULN2003 (-) power pin

[ESP32 (Powered by USB)]
   GND  -------------------------> [BREADBOARD GND RAIL] (Crucial: Common Ground!)
   3V3  -------------------------> Hall Sensor VCC
   GND  -------------------------> Hall Sensor GND
   D34  <------------------------- Hall Sensor AO (Analog Out)
   D18  -------------------------> ULN2003 IN1
   D19  -------------------------> ULN2003 IN2
   D21  -------------------------> ULN2003 IN3
   D22  -------------------------> ULN2003 IN4

[ULN2003 Output]
   White JST Socket -------------> 28BYJ-48 Stepper Motor
```

### Kill-Shots to Avoid:
1. **Never** connect the 5V rail to the Hall Sensor VCC. ESP32 pins are not 5V tolerant. Use `3V3`.
2. **Never** connect the 5V adapter rail to the ESP32 `VIN` pin while the USB cable is plugged into your laptop. Power the motor from the adapter, and the ESP32 from USB. Only link their grounds.

---

## 🛠️ SECTION 3: STEP-BY-STEP ASSEMBLY SEQUENCE

### Phase A: Motor Prep
1. Take the **28BYJ-48 motor** and mount it to the `base_plate` using two M4x10mm bolts. 
   *(Note: The CAD assumes a specific shaft length. If the motor doesn't sit flush, we will need caliper measurements to update the CAD).*
2. Press the resin `braille_cam` disc onto the motor's D-shaft.
3. Seat the Hall sensor into its pocket on the base plate.

### Phase B: Electronics Fit
1. Snip off the female Dupont connectors on one end of your jumper wires. 
2. Strip 3mm of wire, tin the ends, and solder them **flat** (parallel to the board) onto the ULN2003 header pins. 
   *(Why? If you plug Dupont connectors in normally, they stand 20mm tall and won't fit in the 16mm printed electronics pocket).*
3. Lay the ULN2003 flat on the floor of the `outer_box` pocket.
4. Plug the motor's white JST connector into the ULN2003.

### Phase C: Mechanism Drop-In
1. Lower the mid-plate onto the z=20 ledge in the `outer_box`.
2. Lower the base_plate+motor assembly down into the box.
3. Take your 6 resin-printed `linkages`. Place the "foot" of each linkage onto its respective cam track.
4. The linkages should fan out naturally (60 degrees apart) so they don't hit each other.

### Phase D: Top Plate & Springs
1. Glue the resin `dot_insert` tile into the PETG `top_plate` pocket using superglue or epoxy. Let it cure.
2. Thread a 2mm micro compression spring onto the dome of each of the 6 linkages. Give it a slight twist to seat it.
3. Lower the `top_plate` carefully over the standoffs, guiding the 6 braille dots through the holes in the resin insert.
4. Secure the top plate with four M2.5x25mm bolts. 

**Verification:** Gently push down on each braille dot with your finger. It should spring back up smoothly without binding.

---

## 🚫 SECTION 4: BEGINNER SOLDERING MISTAKES
If you are doing the flat-soldering for the ULN2003:
- **Cold Joint:** Looks like a dull, grey blob that doesn't stick to the pad. *Fix: Apply a tiny bit of flux, heat the pin and wire simultaneously for 2 seconds, and reapply a dab of solder.*
- **Bridging:** Solder spills over and connects two pins (e.g., IN1 and IN2). This will break the motor steps. *Fix: Heat the bridge and swipe your iron away quickly, or use desoldering wick to soak up the excess.*
- **Melted Insulation:** Holding the iron on the wire too long melts the plastic jacket. *Fix: Tin the wire and pin separately first (apply solder to them individually), then just touch them together with the iron for 1 second to fuse them.*
