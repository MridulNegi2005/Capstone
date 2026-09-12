# Braillix hardware audit and build plan

> **Later update, 9 September:** The user subsequently authorized implementation. See [the compact candidate and build order](COMPACT_CANDIDATE_AND_BUILD_ORDER_2026-09-09.md) for the implemented isolated CAD, regenerated Blender scenes, actual ₹5,510 spending ledger and revised remaining-budget plan. This original report records the earlier audit phase; its prospective budget is superseded by that update.

**Date:** 9 September 2026  
**Phase:** Audit and planning only. No production CAD, Blender scene, firmware, or print file changed.  
**Recommendation:** Aim first for **one brain pod plus two independently controlled muscle cells**, with matching outer dimensions. Make the mechanism reliable before spending on a smaller enclosure or additional functions.

## 1. Your requirements and the practical verdict

You confirmed that adding a cell should add another simultaneously displayed Braille character. The budget is **₹10,000 total**, with a possible increase to **₹15,000**. College FDM printing is available for the cost of filament; precision UV/resin printing must be bought online. You can solder, but the design must be assembled with ordinary student tools. The brain pod must remain visually consistent with the muscle cells; any size reduction must apply to both.

I have treated “pins” as the existing five-contact pogo connector documented in the CAD. This is a planning interpretation, not a new connector selection. If you meant rigid header pins, their carrier, alignment and mating-force design will need a separate check.

**The concept is worth continuing, but a functioning multi-cell mechanism is not yet demonstrated by the available evidence.** There are fixable assembly defects, an unresolved return-spring load, and no implemented bus-driven muscle-cell control in the checked firmware. These matter more than additional features.

Two muscle cells are the proposed minimum convincing demonstration, not a cell count you already specified. They demonstrate that different characters remain visible together and that adding a module increases capacity. One motor cycling through letters cannot demonstrate that requirement.

There is also a product distinction to make honestly: the current approximately 68 mm character spacing is suitable for a modular teaching/proof-of-concept device, but very different from a conventional continuous Braille line. The BANA reference for paper Braille gives approximately 6.2 mm between corresponding dots in adjacent cells. This is a useful comparison, not certification criteria for this refreshable device. [BANA dimensions](https://www.brailleauthority.org/size-and-spacing-braille-characters)

## 2. What I checked, and what these checks establish

Reviewed the project handoff/history, repository inventory, current shared mechanical dimensions, cam, comb, linkage, insert, base/Hall interface, docking interface, pod parameters, electronics envelope, main motor firmware, BOM/build/sourcing records, architecture study and recent audits. Opened **both saved `.blend` files in background Blender** and measured their mesh objects and scene units. Re-ran the repository print validator and separately checked the comb mesh.

“Database” here means the project repository and engineering records. The file search did not identify a standalone database or spreadsheet inventory. This is a hardware-focused review of the principal sources, not a claim that every PDF, presentation, binary attachment and software function was exhaustively audited. Existing PDF exports were not separately treated as authoritative over their Markdown sources.

Evidence labels below:

- **Verified:** directly observed in current source, Blender data, or the checks run today.
- **Calculated:** derived from stated dimensions and explicitly identified assumptions.
- **Unproven:** needs an owned-part measurement, assembly, supplier quote or reader trial.

### Current dimensions

| Item | Current source/mesh result | Interpretation |
|---|---|---|
| Muscle enclosure | Nominal 68 × 68 × 46.5 mm assembled envelope | Body STL is 42.5 mm high; the cap completes the nominal stack |
| Brain pod | Nominal 68 × 68 × 46.5 mm | Matching main envelope is already present in current CAD |
| Muscle body STL extent | 68 × 69.414 × 42.5 mm | Some geometry extends beyond nominal Y; packaging must use actual bounds |
| Cam | Ø48.4 mm; 9 mm total Z extent including hub | Cannot be shrunk independently of ramps, tracks and motor fit |
| Base plate | 58 × 56 mm; 13 mm including posts | The support structure is wider than the cam |
| Guide comb | 54 × 54 mm | Required anti-rotation function; current geometry has an assembly defect |
| Dot tile | 15 × 15 × 3.2 mm | Small precision part inside an FDM top plate |
| Braille dots | 1.5 mm dome; 0.5 mm nominal lift; 2.6 mm pitch both directions | Nominal geometry, not a tactile-readability test |
| Bare driver carrier | 28 × 18 mm board, about 11 mm total thickness with socket | Stands on edge; this is not a complete multi-cell electronics assembly |

Sources: `cad/scad/mech_layout.scad`, `outer_box.scad`, `esp32_pod_params.scad`, `electronics_spec.scad`; committed mesh measurements. Values above use default `stack_repair_raise=0`. The old optional +4 mm stack must not be enabled as a shortcut: it contains historical assumptions needing a fresh coordinated check.

## 3. Separate Blender/CAD audit

### B1 — Both saved Blender assemblies are obsolete — verified

| File | Measured examples | Problem |
|---|---|---|
| `renders/braillix_assembly_v5.blend` | Cam about Ø36.4; outer box 68 × 68 × 58; pod shell 64 × 68 × 55 | Does not represent current 48.4 mm cam or matching current enclosures |
| `renders/braillix_assembly.blend` | Cam about Ø36.4; pod shell 74 × 38 × 55 | Much older pod architecture |

The v5 file also uses metric scale 1.0 while its enclosure spans 68 scene units. The earlier file uses scale 0.001. The v5 ghost motor and its exploded counterpart differ by a factor of 1,000; some ghost PCB dimensions are half the documented board envelope. These scenes are unsuitable for clearance decisions or direct manufacturing export as they stand.

**Proposed action:** keep OpenSCAD as the manufacturing source. After mechanical corrections, rebuild one clearly versioned Blender assembly from matching exports, normalize units, and model actual electronics envelopes. Preserve the old scenes as historical references. Blender is useful for sections, assembly order and visual inspection; a render cannot establish torque, surface finish or print tolerance.

### C1 — Comb openings have a roof — verified blocker

In `linkage_comb.scad`, `comb_top=3.3`, `comb_h=2.3`, and `clear_z=0.85`. The pocket subtraction starts at 0.75 and has height 2.5, ending at **3.25 mm**. This leaves **0.05 mm of material** across its top.

**Effect:** the nominal drop-in path is closed. A slicer might omit this thin skin, but manufacturing should not depend on that accident.

**Proposed action:** define each cut by its required lower and upper limits, with overcut above the comb. Verify all six insertion paths and full travel. The underside relief also requests a negative height (-0.05 mm); resolve its intended support/clearance geometry rather than trusting the comment about a centering spigot.

### C2 — Cam-to-base running clearance is zero — verified blocker

The default cam underside is **z=31.5 mm**. The base is at 29.5; its thickness is 5 and pocket depth 3, so the pocket floor is also **31.5 mm**.

**Effect:** nominally coincident surfaces can rub once tolerances and warping are included. A closed mesh does not detect this.

**Proposed action:** provide a deliberate running gap, initially explore 0.3–0.5 mm, and recheck the remaining base thickness, Hall mounting and support surfaces together. Do not merely lower the whole base: that also moves the comb and top-plate supports. Preserve the motor shaft and derive the entire stack from its seating surfaces.

### C3 — Hall pocket removes its intended roof — verified blocker

For the default stack, `hall_pocket_height(0,5)=4.6 mm`, while only **2 mm** of base material remains below the cam pocket. The underside cut therefore opens into that pocket; the claimed 0.4 mm roof is absent.

**Proposed action:** design a retained sensor pocket using actual material remaining beneath the rotating disc. Include lead bends and removal access. Check that neither the sensor nor glue can protrude into the cam. Establish Hall switching reliability with the actual magnet gap after this geometry is corrected.

### C4 — Return springs remain a fit and torque risk — calculated, physical test required

The current CAD assumes **2 mm OD, 0.20 mm wire, 4 mm free length**. The handoff records that only **0.30 mm wire** springs were available to you; current possession and force have not been reconfirmed. Several shopping documents still specify 0.30.

- At 0.30 mm wire, nominal spring ID is 1.40 mm. A 1 × 1 mm square nub has a 1.414 mm diagonal: no nominal sliding clearance. The 1.5 mm dome also cannot simply slide through that ID.
- At 0.20 mm wire, nominal ID is 1.60 mm. This improves fit but still requires testing of printed corners, coil variation and assembly.
- Current installed spring lengths are approximately **3.0 mm down and 2.5 mm up**, so a 4 mm free spring has 1.0–1.5 mm compression. Older 2.2 mm-up comments describe a previous lift.

For illustration, using steel shear modulus 77,000 N/mm² and **five active coils**, the usual compression-spring estimate `k=G*d^4/(8*D^3*n)` gives about **0.53 N/mm** for 0.20 wire and **3.17 N/mm** for 0.30 wire at the same 2 mm OD. Six springs would preload the cam by roughly **3.2 N versus 19 N** before lifting a dot. These are estimates: active coil count, end form and actual dimensions are unknown.

**Proposed action:** measure force at both installed lengths before ordering a full precision set. Do not assume that shortening a spring makes it softer: removing active coils increases stiffness, although it can reduce preload. If 0.30 wire is unavoidable, explore a coordinated round/slimmer spring stem and lower-preload seat on a small test part. Neither change alone proves acceptable torque. Moving the return mechanism away from the dot axis is a larger fallback requiring a redesign, not the baseline plan.

### C5 — Cam ramps are steeper than their comments suggest — calculated

The current profile uses a cosine transition. Its peak slope is π/2 times its mean slope. Recomputed peak angles for tracks 0–5 are **41.59°, 36.75°, 32.80°, 29.54°, 26.83°, 24.55°**. Thus three tracks exceed the design's own 30° target.

This is a side-load and friction risk, not proof that the motor will always stall. The rounded printed foot is a **sliding follower, not a freely rotating bearing**. Gray ordering reduces simultaneous lifting but does not remove friction from the other preloaded feet.

**Proposed action:** evaluate a blended, gentler-peak profile against the actual spring load while preserving flat stopping regions. Increase the current four subdivisions per state and verify convergence of the exported surface; twelve is a candidate starting point, not automatic proof. Check follower contact against the actual mesh. Shrinking the disc now reduces available ramp travel and worsens this tradeoff.

### C6 — The mechanism test fixture is undersized — verified

`cam_linkage_test_fixture.scad` still declares **44.4 mm cam / 45.0 mm well**. The current cam is **48.4 mm**. This fixture needs updating before it is used to judge the new mechanism. The prior report's blanket statement that all coupons were suitable is too broad.

### C7 — Retention and service access are incomplete — verified/unproven

`electronics_spec.scad` explicitly says `elec_retainer_modelled=false`. Its upright layout reserves about 11 mm in a 12.35 mm-wide band, leaving only **1.35 mm total nominal spare width**. That is not a budget for arbitrary extra boards, insulation and wire exits. Motor seating locates the can but does not establish positive retention for handling or inversion.

**Proposed action:** add a removable FDM board carrier and a motor strap/clip or suitable screw retention. Prove screwdriver access, wire clearance and extraction order. Do not rely on wire stiffness to hold a board. Keep fastener tips out of the moving volume.

## 4. What is good and should be preserved

These are defensible design choices; “works perfectly” would need bench evidence.

| Choice | Why it is strong | Remaining check |
|---|---|---|
| One indexed cam for all six dots | Reduces actuator and driver count per character | Torque, positioning and wear |
| Gray ordering | Neighboring indexed states change one bit | Intermediate characters are still felt if touched during motion |
| Feet distributed around the disc | Allows the arms to fan outward instead of stacking six layers | Full insertion and motion clearances |
| Thicker arms vertically, narrow spring stems | Uses the useful bending direction without widening every feature | Resin toughness and dot deflection under touch |
| Small precision dot tile in an FDM plate | Concentrates expensive manufacturing in the fine features | Smooth seam and repeatable sliding fit |
| Matching brain/muscle outer envelope | Meets your modular visual goal | Actual protrusions and docking alignment |
| Shared docking parameters | Prevents pod and cell interfaces drifting apart | One canonical assembly orientation and pin map |
| Connector flange fitted from inside | Outward pull can bear against the wall rather than only small screw threads | Inward pogo load still needs retention; wall strength needs testing |
| Keeping the motor shaft intact | Avoids repeated student machining and irreversible damage | Correct hub and running clearances |
| Replaceable socketed electronics | Makes failed parts repairable without destroying an enclosure | The whole assembled carrier must fit |

The recessed reading surface is **not itself a defect**. Current nominal down-dot height equals that surface; the up-dot is 0.5 mm above it. Raising every linkage to reach the outer rim would also raise the supposedly lowered dots. The tile seam and finger path need a real reader trial.

## 5. Multi-cell electronics: the missing system

### The five pins are a bus, not five direct motor controls

The current firmware drives four motor inputs directly and reads Hall on GPIO34. This cannot independently control an expanding row through the five pogo contacts. **Even the first muscle cell needs a local interface if it is to use this bus-only dock.** The old instruction “add an expander only at cell three” applies to a separate direct-wire demonstration.

Recommended continuation of the existing architecture:

```text
Brain: ESP32 + buttons + buzzer + protected 5 V power entry
    |
    | GND / SCL / 5 V / SDA / GND
    |
Cell 1: 3.3 V regulator + addressed I/O expander + motor driver + Hall + motor
    |
Cell 2: same electronics and mechanism, different address
```

Each cell passes the bus onward. Start with **one MCP23017 per muscle cell**, externally set addresses and sequential motion. This follows the project's existing architecture and avoids a new custom processor board. It still needs a real wiring design and complete physical envelope. The expander is GPIO, not a motor controller or ADC; the ESP32 must generate coil sequences and read a digital Hall indication. Three address bits provide eight addresses on one bus, not eight guaranteed mechanically/electrically reliable cells. [Microchip MCP23017](https://www.microchip.com/en-us/product/mcp23017)

**Address is not physical order.** Plugging in cells with different addresses allows discovery, but a simple parallel I²C bus does not reveal left-to-right placement. For the first demo, label cells and fix their address order; allow the software team to configure that order. Arbitrary rearrangement with automatic position discovery is a separate feature. Duplicate addresses need a setup check and a clear error, not silent incorrect characters.

### Sensor identity must be settled before its wiring

The repository alternates between SS49E-style analog Hall sensing and A3144 digital sensing. These are different circuits. A genuine SS49E supports low-voltage operation; the A3144 datasheet specifies 4.5–24 V and an open-collector output. An A3144 path can use 5 V supply and an external pull-up to 3.3 V; an analog path needs a suitable threshold/comparator or ADC before an MCP23017. Do not move an unidentified module from 3.3 V to 5 V and assume its output is safe. [Honeywell SS49E](https://automation.honeywell.com/us/en/products/sensing-solutions/sensors/magnetic-sensors/ss39et-ss49e-ss59et-linear-hall-effect-sensor-ic), [Allegro A3144 datasheet](https://www.allegromicro.com/~/media/Files/Datasheets/A3141-2-3-4-Datasheet.ashx?la=en)

Use a fully identified digital Hall part for the expander build if practical. The team should handle identifying the existing component; you should not need to choose from transistor specifications yourself.

### Driver, power and docking requirements

- For a bare ULN2003A, connect **pin 8 to ground and COM pin 9 to motor +5 V** so its internal inductive clamps have the intended return path. It is a sink driver; the motor common also receives +5 V. Check selected expander output drive and actual coil current against the driver requirements, including voltage lost in the Darlington stage. [TI ULN2003A datasheet](https://www.ti.com/lit/ds/symlink/uln2003a.pdf)
- Include local logic decoupling, motor-rail bulk capacitance, defined startup outputs and defined expander reset/address pins. The old “no resistors or capacitors needed” advice does not apply to this new local electronics assembly.
- Preserve the documented contact sequence **GND–SCL–5V–SDA–GND**, with drawings explicitly naming mating-face view. Ring out the assembled male/female pair with a meter. Reversing this sequence swaps SDA and SCL while preserving the power positions; it still fails communication.
- Add cable strain relief, insulation and appropriately rated power-entry protection. Choose protection after measuring startup/running current, so it tolerates operation while protecting the selected wiring and connector.
- Do not equate a 3 A adapter with a 3 A dock. One positive contact carries the aggregate downstream motor current. Connector ratings, contact resistance and mating force need the actual part's data or measurement.
- Use a mechanical alignment/key feature or a small printed base rail. Magnetic polarity helps orientation but is not a physical barrier against wrong mating or shear.
- **First demo: power off before adding/removing cells, then enumerate and home on startup.** Live powered insertion needs bus recovery, contact sequencing and transient analysis; do not imply it already exists.

For scale, using illustrative contact resistances of 0.10 Ω for the positive and 0.05 Ω for the two grounds in parallel, and 0.25 A per moving cell, far-end loop drop is:

`ΔV = 0.25 × 0.15 × n(n+1)/2`

This is about **0.113 V at two cells**, **0.375 V at four**, and **1.35 V at eight**, excluding wiring resistance. Ground shift alone at eight is 0.45 V. With only the farthest motor moving, the eight-joint loop example drops to 0.30 V, plus idle electronics current. These are scenario calculations, not measurements or an approved chain length. Sequential refresh improves the situation but does not remove electrical limits.

## 6. Software suggestions for the other team

No firmware was edited or flashed. These are hardware integration requirements, in priority order:

1. **Implement the addressed cell bus**, coil sequencing and digital Hall input. Move any retained direct motor outputs away from GPIO21/22 before using them for I²C. Do not stack the driver and expander pin maps from different documents.
2. **Calibrate each motor's output revolution and home-to-state offset.** The code assumes 4096 half-steps. Do not blindly replace that with 4076 based on the generic motor name: measure the owned gearbox. Compute each target from calibrated revolution length with rounding/fractional error handling; simply changing an integer constant can leave the per-state division wrong.
3. **Home repeatably:** leave the magnet region if necessary, approach the selected edge slowly from a fixed direction, apply hysteresis/debounce, then apply a measured offset to a flat state. A wide magnet does not make its center mathematically meaningless; saturation and the current minimum-search method make it unreliable. The present `tryHome()` scans `analogRead()` for a minimum and allows ordinary motion after failed homing.
4. **Do not report valid Braille after failed homing.** Provide an error cue and a deliberate bench-only override. Track state validity per cell.
5. **Control backlash:** characterize reversals and use a consistent final approach where needed. Current shortest-path movement has no compensation. Measure repeatability rather than assuming an exact backlash angle.
6. **Queue motion without blocking communication.** Current `runToTarget()` busy-waits. Schedule one cell at a time initially, remain responsive to stop commands, and report completion only when the whole requested row is ready.
7. **Beep before motion and after the complete row settles.** This tells the reader when to lift their finger. Six-dot cams pass through intermediate patterns; Gray code does not make a refresh readable while moving.
8. **Test powered-off holding.** Current code releases coils after a move. Keep that power-saving behavior only if dots remain stable under touch; do not assume the geared motor guarantees holding in every state.
9. **Keep Braille translation on the phone/computer initially.** Send explicit six-bit cells plus order to the device, with test vectors for capitals, numbers and punctuation. A text character can require multiple Braille cells. The brain pod adds no display character unless it is also given a mechanism.
10. **Update simulation assets with the CAD release.** A visual demonstration must show the same mechanism and dimensions as the print set.

### Refresh speed is another hardware limitation

The main sketch sets 1,000 half-steps/s and acceleration 2,000 half-steps/s². A nominal half-revolution move of 2,048 steps takes about **2.55 seconds** with acceleration and deceleration, before communication and settling overhead. Two such moves scheduled sequentially take about **5.1 seconds**; four take about **10.2 seconds**. Actual pattern sequences may be faster, while backlash approach, homing, a slower loaded motor and I²C scheduling can make them slower. These are calculated examples, not measured refresh times. Plan the demonstration around deliberate page/character advances rather than promising fast scrolling. Measure bus-driven step timing under communication load before choosing the production speed.

## 7. How you can assemble it without large machines

### Soldering and glue: the direct answer

**You do not need a glue gun to hold an IC electrically in place.** Solder the DIP socket to perfboard, then insert the IC in the correct orientation. Solder provides the electrical joints. A printed carrier, clips or screws support the board. Heat-shrink insulates exposed wire joints; anchor the insulated wires a short distance from the joint so handling does not bend the soldered boundary.

Hot glue is optional for light wire anchoring after testing. Keep it out of sockets, connectors, spring seats and moving parts; do not bury the driver under glue or use it to correct bad fits. Keep boards removable. Mount magnets and the fixed dot tile with small controlled amounts of a suitable adhesive after dry fitting; keep squeeze-out away from the six holes. Do not glue a detachable dock together.

A through-hole driver is a reasonable student soldering task. A SOIC expander on a measured adapter is also a possible route, but the adapter plus regulator, headers and wires must fit; a chip body alone is not an assembly envelope. A ready-made small module may be easier than soldering a bare fine-pitch IC. Do not buy an oversized DIP expander just because it is easier to solder.

### Manufacturing split

| Part | Baseline process | Why / student handling |
|---|---|---|
| Both shells, base, top plate, pod lid | College FDM, PETG candidate | Main structural bulk; confirm printer/material settings locally |
| Carriers, alignment rail, retention clips and fit coupons | FDM | Cheap to iterate and replace |
| Cam and linkages | Outsourced tough/ABS-like resin initially | Fine moving surfaces; request cured parts and support-free functional surfaces |
| Dot insert | Outsourced precision resin | Small holes and thin webs; do not assume any resin/process gives the nominal clearance |
| Comb | Resin baseline; test FDM alternative early | Small guide pockets need a coupon before committing the full part |
| Button caps/end cap | Try FDM where fit permits | Low consequence compared with the cam; use a rigid clearance-fit cap if TPU is unavailable |

No shaft cutting, CNC milling, metal laser cutting or home resin-processing setup is required by this plan. Hand tools are for normal assembly and deburring, not for manually recovering six inaccurate precision guides. Large flat parts, horizontal openings, thin walls, screw access and wire bends should be inspected on small FDM coupons first.

Suggested assembly order after corrections: bench-wire and test electronics → dry-fit dock carriers → retain motor → fit base/Hall and route wires → fit cam and prove free rotation → fit corrected guide/linkages/springs → fit top plate and tile → verify motion open → close the shell → join two cells and test the complete row. Confirm spring/dome insertion order on one spare linkage before attempting six at once.

## 8. Where the printing money actually goes

Measured committed mesh volumes:

| Precision part | Solid volume |
|---|---:|
| Cam | 4.190 cm³ |
| Six linkages | 0.378 cm³ |
| Dot insert | 0.448 cm³ |
| Subtotal often described as the mechanism resin | **5.015 cm³** |
| Current comb, separately checked | **5.150 cm³** |
| Combined precision set if comb is resin | **10.165 cm³ per muscle cell** |

The comb **approximately doubles** that core resin volume. It is also absent from the normal validator/render manifest. This makes it an unusually valuable cost-reduction target. Supplier cost will also include minimum order, supports, orientation, handling, shipping and failed parts; volume alone is not a quote. The defective comb's final corrected volume will differ slightly.

**First cost experiment:** print a small FDM guide coupon in the final orientation, test a real resin follower for smooth travel and lateral restraint, and only then try a full FDM comb. If it binds or wears, retain resin guide pockets in a smaller skeleton/insert arrangement supported by FDM. Do not remove the guide function to save money.

Order precision parts in stages: one corrected mechanism with spare fragile arms, test it, then order the second cell and additional spares. Ask the supplier for both one-set and two-set delivered prices before choosing the order size. Existing old resin orders need dimension checks; paid-for parts are not necessarily compatible with the current cam.

## 9. Reducing size while keeping the pod and muscle identical

**Do not use Blender's scale tool on the assembled device.** It would shrink motor bores, screw holes, spring seats, connector pitch and tactile dots together.

The current 68 mm width is driven by several constraints: the 48.4 mm cam, 58 × 56 mm base, corner supports and 4 mm enclosure walls; the pod must also accept the approximately 51.5 mm board plus sockets/cable access. The dock has locally thinned walls and screw pilots, so a blanket wall reduction can break it.

| Rank | Proposal | Plausible result | Change / cost consequence |
|---|---|---|---|
| 1 | Reduce resin use, add removable carriers; retain outer size initially | Better cost and assembly without reworking every interface | Low–medium; best first return |
| 2 | Investigate **64 × 64 × 46.5 mm for both units** | 11.4% smaller nominal envelope volume; only 5.9% less chain length per unit | Medium–high: redesign base edges, corner supports and selected walls; not yet proven to fit |
| 3 | Investigate a shared 2–3 mm height reduction after mechanism proof | About 4–6% additional volume reduction at unchanged footprint | Medium–high: shaft, hub, guide, spring and cap clearances all interact |
| 4 | New smaller actuator/cam architecture | Potentially substantial reduction | High redesign and test cost; no reliable dimensional target yet |
| 5 | Conventional close-spaced line using remote/latching actuation | Addresses character spacing rather than just box size | Separate research project; keep outside the ₹10,000 baseline |

The 64 mm option is an **exploration target**, not an engineering release. Keep the same radius, color, side-face geometry and height on both units. Different internal carriers and necessary top controls are compatible with a matching exterior; the exact “identical” appearance should be reviewed together before export.

A three-unit chain (brain plus two cells) is nominally **204 mm** long at 68 mm, before connector gaps. At 64 mm it is 192 mm. This is useful packaging progress, but it does not turn the display into standard-spaced Braille. The earlier claim that only piezo can ever solve compact Braille is too absolute; alternative architectures exist, but none is established by this design review.

## 10. Budget plan: total spending, not an extra ₹10,000

The old BOM records **₹935 already spent**. It also omits or inconsistently records later tools, connectors and resin orders. The amount is a historical ledger entry, not a complete current total. Let **S be all spending so far**: available money is `₹10,000 − S`, or `₹15,000 − S` if the increase is approved. Count existing purchases once, and do not buy “needed” items again merely because an old checklist says so.

The following is a **spending-cap allocation**, not a supplier quotation or guarantee of a two-cell build. It assumes the original electronics remain usable and reserves money for unrecorded purchases. Replace those two rows with actual receipts before ordering.

| Allocation for brain + two muscle cells | ₹10,000 total plan |
|---|---:|
| Original recorded purchase | 935 |
| Allowance for later purchases already made; reconcile receipts | 1,065 |
| One shared filament spool and FDM iterations | 1,000 |
| Missing soldering tools/consumables; borrow college tools where possible | 1,100 |
| Additional motor/driver and local cell logic/regulators/passives | 1,000 |
| Remaining dock contacts/carriers/magnets allowance | 650 |
| Springs, fasteners, insulation, clips, adhesive | 650 |
| Finished/cured precision-part work, shipping budgeted separately | 2,000 |
| Shipping and taxes not included by sellers | 600 |
| Contingency: failed parts and replacements | 1,000 |
| **Total cap** | **10,000** |

The ₹2,000 resin cap is the largest uncertainty, especially with two full resin combs. If quotes exceed it, first test reducing comb resin and borrowing tools. If the remaining money still does not cover two working cells, request the increase before commissioning them. Do not represent a one-cell fallback as satisfying your multi-cell objective.

As a current price anchor, Robu's PETG listings showed a 1 kg option around **₹859** and another around **₹1,068** when checked. The ₹1,000 line is a planning allowance; color, shipping and checkout price can change. Component and resin allowances above are estimates, not verified shopping-cart totals. [Robu PETG listings](https://robu.in/product-category/pro-range-petg-pro/)

### If ₹15,000 is approved

| Use of additional ₹5,000 | Allocation |
|---|---:|
| Higher resin quote / necessary second mechanical iteration | 2,000 |
| Third muscle-cell target, only after repeatable two-cell success | 1,800 |
| Tactile/assembly improvements, spares and test aids | 700 |
| Additional contingency | 500 |
| **Total increase** | **5,000** |

Redirect the third-cell money to making the first two reliable if needed. The strongest funding case is **repeatable multi-character output, affordable precision parts and repairability**, supported by quotes and test evidence. An extra ₹5,000 does not justify promising an eight-cell product.

## 11. New functions ranked by value, changes and budget

Costs below are approximate incremental hardware allowances, not cumulative additions to the budget table. Effort describes new work after a stable two-cell baseline; it is not a delivery promise.

| Rank | Function | Hardware change | Software effort | Added ₹ estimate | Decision |
|---|---|---|---|---:|---|
| 1 | Ready/busy/error beeps and working previous/next/select buttons | Small buzzer mount/driver as needed; reuse planned buttons | Low–medium | 50–200 | Include in baseline |
| 2 | Detect configured cells at startup; show clear missing-cell error | Address jumpers/labels, already part of bus plan | Medium | 0–100 | Essential to demonstrate modularity |
| 3 | Practice mode with reveal/advance | Usually no extra hardware | Medium | 0–100 | High demo value; quiz needs a real answer/reveal interaction |
| 4 | Resume reading position | None | Low | 0 | Save periodically, not on every motor step |
| 5 | Offline pretranslated lessons using internal flash | None | Medium | 0 | Prefer before an SD reader |
| 6 | Add third character cell | Full additional mechanism, logic and docks | Low–medium after bus works | 1,200–2,500 | ₹15,000 stretch; quote resin first |
| 7 | Removable SD lesson files | Socket/module plus protected access | Medium | 200–450 including card allowance | Only if lesson updates require it |
| 8 | Optional spoken letter/word hints | Amp, speaker and mount; storage decision | Medium–high | 300–700 | Phone audio can trial the value first |
| 9 | Portable supply | Suitable finished power bank/cable first; test low-load behavior | Low–medium | 800–1,500 | After current/holding tests; keep internal cell pack out of baseline |
| 10 | Powered hot-plug and automatic recovery | Protection and connector sequencing review | High | 300–1,000+ | Defer; restart-after-docking is simpler |
| 11 | Automatic left-to-right order after arbitrary rearrangement | Additional identification/topology mechanism | High | Unquoted | Research separately; I²C scanning alone cannot do it |

The **64 mm matching enclosure** is a medium–high mechanical redesign, not a cheap new software function. It should compete for the same prototype/reprint money as the features above.

## 12. Proposed order of work, with review images

This is what I would work on next. It is a plan; these changes have not been made.

| Order | Work | Review image/view to produce | Exit evidence |
|---|---|---|---|
| 1 | Reconcile actual parts, spending and one electrical pin map | Labeled brain-to-two-cell block diagram | Complete bus architecture and an affordable purchase list |
| 2 | Correct comb cut-through, cam gap, Hall retention and fixture sizing | Section through motor–cam–base–Hall; close-up of open guide pockets | Positive clearances and unobstructed insertion paths |
| 3 | Test available spring, nub and follower; compare ramp choices | One-dot test assembly with spring installed lengths | Smooth return and repeatable motor-driven lift under load |
| 4 | Place all local electronics, wires and retainers in both envelopes | Open-top layout with real carrier and wire-bend volumes | Boards and connectors fit and can be removed |
| 5 | Establish complete FDM/resin split, especially the comb | Color-coded manufacturing layout | Passing guide coupon; supplier quote includes every precision part |
| 6 | Rebuild current Blender assembly and export provenance | Exploded assembly with numbered insertion order | One coherent CAD/STL/Blender version and correct units |
| 7 | Build and integrate one muscle cell | Dot down/up sections and loaded motion record | All 64 patterns, homing and repeated motion pass |
| 8 | Add the second muscle cell and complete user controls | Matching brain + two-cell view; dock cross-section | Independent simultaneous characters; no reset or dropouts |
| 9 | Explore a shared 64 mm envelope | Current versus candidate dimensioned comparison | Complete fit and assembly proof for both units |
| 10 | Add selected lesson/practice features or third cell | Final demonstration view | Changes fit the remaining budget and pass regression checks |

Produce each view from the actual revision being reviewed. Do not spend on polished marketing renders before the sections and assembly paths are correct. Batch precise parts only after the one-cell mechanism evidence exists.

## 13. Student-friendly acceptance tests

These are proposed engineering acceptance checks, not results already obtained and not a formal product certification.

| Test | What you do | What must be recorded |
|---|---|---|
| One-dot fit | Fit one spring/linkage into a coupon; move it through full travel | No forced twisting of a fragile dome, sticking or spring bind |
| Cam freedom | Turn fitted cam with no linkages, then with one and six | No disc/base rubbing; repeatable motion with actual spring load |
| All 64 states | Command each pattern and inspect raised/lowered dots | No partial-height or incorrect dot at settled positions |
| Homing repeatability | Restart/home at least 20 times from different angles | Same known flat pattern every time; failed sensing produces an error |
| Touch/holding | Apply a small known load to a raised dot; compare coils on/off | Initial screen around 10 g (~0.10 N), then characterize deflection across representative touch loads; agree final criterion with reader feedback |
| Endurance | Run at least 500 mixed transitions including reversals | Missed states, stalls and wear logged; no false “ready” event |
| Two-cell row | Display different patterns, then swap them repeatedly | Both remain independently correct; whole-row completion cue |
| Electrical chain | Measure far-cell supply during motion | Voltage remains within selected component limits; no resets or bus errors |
| Heat in the closed enclosure | Run representative refresh/idle cycles for 20–30 minutes | Measured motor/driver/logic temperatures remain inside component and material limits; no softening or resets |
| Dock durability | Power off, mate/unmate at least 50 times | No loosening, wire strain, intermittent continuity or cracked carrier |
| Serviceability | Remove and replace one failed-prone part | Ordinary tools; no destructive glue removal from electronics |
| Reader trial | Ask a willing Braille reader/teacher to try stable patterns | Confusions, spacing comfort, dot feel and cue usefulness; no assumed readability from appearance |

## 14. Corrections to older audit claims

- **Today's normal validator passes.** `python tools/validate_print_assets.py` passed committed topology plus G-code/profile/STL-hash checks for its listed **22 STL assets and 11 G-code files**. The blanket stale-G-code warning in the earlier audit is no longer current for that checked set.
- **This is not a fresh-export release check.** I did not regenerate every OpenSCAD source or validate the optional +4 mm candidate. The main manifest omits the comb, and the fixture's outdated size is not detected by matching its own G-code hash.
- **Comb checked separately:** 2,408 triangles, one closed component, no boundary/nonmanifold edges, volume about 5,150 mm³. Its closed roof demonstrates why a watertight mesh can still be functionally wrong.
- **`docs/KNOWN_GOOD.md` contains historical decisions**, including removed-comb and 4.8 mm pitch guidance, which disagree with current live CAD. Do not apply them blindly.
- **4076 steps and “failure after 13 characters” are not measured facts for the owned motor.** Error depends on actual gearing, target positions, rotation history, missed steps and backlash.
- **An A3144 voltage warning is conditional on identification.** The repository also documents an analog SS49E-family sensor. One supply instruction cannot serve both paths.
- **The complete muscle electronics do not yet have a proved fit.** The 34 mm board-length assertion is for the driver carrier. It does not independently prove that every possible expander arrangement is impossible, or that a bare SOIC chip makes the whole assembly fit.
- **A conventional line is not achieved by modest shell shrinking.** Present the current goal as modular simultaneous Braille characters and measure readability honestly.

## 15. Remaining information needed before purchases or implementation

You have already answered the goal, total-budget and printing-access questions. The next review only needs a simple list of what has arrived and the total spent, plus any deadline. The team should establish the technical details from the actual parts: spring force, sensor identity, connector dimensions/rating, complete carrier dimensions and motor calibration. No new hardware was ordered, no device was flashed, and no production design was modified during this audit.
