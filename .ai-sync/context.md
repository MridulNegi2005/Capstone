# AI Agent Context Log
> This file is shared between Claude Code, Codex, and Antigravity.
> Each agent appends entries below when syncing. Read this to understand what other agents did.

---

## [2026-06-04 18:30] — Claude Code
**Task:** Pre-patent CAD forensic audit (all SCAD files) + start polish pass (v6.0)
**Changes:** Created `.ai-sync/artifacts/cad_audit_v6_2026-06-04.md` (single source of truth).
Updated breadboard firmware earlier (AccelStepper + WiFi web monitor + OTA; STEPS_PER_REV→4096;
cam Double-D bore + deeper hub re-rendered).
**Status:** completed (v6.0 polish implemented — all changed PETG STLs Simple: yes, print_batch rebuilt)
**Notes:** ⚠️ TWO FALSE ALARMS confirmed — do NOT re-fix: (1) magnet polarity is CORRECT
(+X S/N/S docks to −X N/S/N = attract; agents wrongly assumed +X meets +X); (2) linkage.scad
reference table is a stale COMMENT only, live geometry is correct. REAL fixes this pass:
delete scrapped `linkage_comb.scad` (stale inner_radius=8); add anti-reversal dock keying;
PETG bridges over side-wall holes; widen wire gutters; pod ⠿ tactile marker + nav-cap braille;
fix stale hall-gap comment (real gap 2.65mm); power-jack guard ring. LOCKED DECISIONS: braille
pitch stays **jumbo 4.8mm** (framed as large-format/learner); RESIN = cam/top_plate/nav_cap (do
NOT make FDM-tolerance edits to these); PETG = box/plates/pod/end-cap; patent doc deferred to end.
Architectural truth for patent: 28BYJ-48 (28mm) can't fit one-motor-per-char at 6.1mm pitch →
Braillix is a modular teaching/single-char display, not a compact reader.

---

## [2026-05-21 22:07] — System
**Task:** Initialized cross-agent sync
**Changes:** Created .ai-sync/ directory structure and bridge files
**Status:** completed
**Notes:** Project is now ready for multi-agent collaboration.

---

## [2026-05-21 22:10] — Claude Code
**Task:** Re-established project context after chat loss; initialized cross-agent sync
**Changes:** Created `.ai-sync/` directory, `CLAUDE.md`, `AGENTS.md`, `GEMINI.md` bridge files
**Status:** completed
**Notes:** Previous chat was lost after an update. Project memory (MEMORY.md) retained key context: Braillix is an affordable indexed-cam refreshable Braille display (28BYJ-48 steppers, 3D-printed resin cam discs, laser-cut metal linkages, ESP32 per cell, UART daisy-chain via pogo pins). CAD files are in `renders/` using OpenSCAD. Key fixes from May 2nd session: cam pocket diameter fix (35→37mm), top plate standoff alignment, rectangular linkage slots, Hall sensor pocket, magnet pocket, pogo connector slots, and a new parametric linkage file. There's also a `pcb/` directory that appeared since the last session — not yet explored.

---

## [2026-05-30 23:36] — Antigravity
**Task:** Hardware audit pre-print fixes for CAD files
**Changes:** Fixed standoffs to extreme corners (`26`, `21`) in `base_plate.scad`, `linkage_comb.scad`, `mid_plate.scad`, `outer_box.scad`, `top_plate.scad`. Corrected top plate dimensions to 60x60 and changed braille hole to rectangular slot. Implemented `vertical_pcb_rails()` for ESP32 in `esp32_pod_shell.scad`.
**Status:** completed
**Notes:** Next agent should explore `pcb/` directory or proceed with firmware development as CAD fixes for this audit are completed.

---

## [2026-05-31 00:00] — Claude Code
**Task:** Pre-print physical assembly audit of all CAD parts (Mridul wants to 3D-print now)
**Changes:** Created `.ai-sync/artifacts/assembly_audit_v4.1_2026-05-30.md` — full part-by-part
"in-hand" audit. Found 2 SHOWSTOPPERS (F1: top-plate dot slot is 1.4mm but linkage nub is 2.2mm
→ dots can't rise; F2: top plate 60mm in a 60mm cavity → won't seat), 3 CRITICAL (F3: cam D-bore
only 2mm vs ~10mm shaft; F4: base-plate→box fastening undefined/just rests on bosses; F5: ESP32
pod is internally contradictory across 3 files + is a 38mm stub vs 68mm cell), plus gaps F6–F10
(no wire rails/clips, no pogo carrier, no muscle-board mount, no pod switch holder, dead params).
**Status:** completed — REVIEW ROUND OPEN. No CAD changed yet (by design).
**Notes:** Confirmed w/ Mridul: ESP32 = 30-pin DOIT DevKit V1; pod must look like a matching brick;
buttons must use easy/no-extra-PCB mounting (recommend printed switch pockets). **Codex & Antigravity:
add your findings/votes in the artifact's "AGENT INPUT" section before we edit any SCAD.** Open forks:
ESP32 mount style (horizontal sockets vs vertical cartridge), base-plate fastening method, exact pogo
part dims, measured 28BYJ-48 shaft length.

---

## [2026-05-31 01:00] — Claude Code
**Task:** Implement all pre-print fixes from the 3-agent audit (F1–F14) + wire management + pod redesign
**Changes:**
- B1: `top_plate.scad` — plate 60→59mm, slots→2.5mm round holes (F1+F2)
- B2: `linkage.scad` — nub centred on dot origin (F12)
- B3: `braille_cam2.scad` — D-bore deepened to 4mm through disc floor (F3); `base_plate.scad` shaft clearance 7→10mm
- B4: `outer_box.scad` — boss_height 38→37 (F13); boss tap 2.6→2.1 (M2.5 pilot); `base_plate.scad` standoff tap→2.9mm clearance thru-bore (F4)
- C1: `esp32_pod_*.scad` — complete rewrite: 64×68×58 matching brick, horizontal DevKit V1 on female header sockets, lid screw bosses added (F5+F14), dead params removed (F10)
- C2: Pod switch pockets added in shell front wall (F8)
- C3: `outer_box.scad` — pogo carrier pockets, floor wire gutters, C-clip cable saddles, vertical wire guides, muscle-board M2 bosses (F6+F7); `mid_plate.scad` — ±X and +Y wire pass-through notches
- C5: `linkage_comb.scad` — body enlarged from 38×38 to 56×46 to reach standoffs at (±26,±21) (F11)
- All 11 STLs re-rendered and verified: **all Simple: yes** (manifold).
- Outer box boss diameter reduced 8→7.8mm to avoid coplanar face at cavity boundary (26+4=30=wall).
**Status:** completed
**Notes:** All showstoppers (F1–F4) and structural issues (F5–F14) are resolved in CAD. Pod is now a
matching 64×68×58 brick. DevKit V1 mounts horizontally on female sockets. Wire hooks, gutters,
muscle-board bosses, switch pockets, and pogo carrier pockets added. Ready for print.

---

## [2026-06-03 12:00] — Claude Code
**Task:** Breadboard bring-up plan (solderless) + cam resize (v5.1) + print/shopping docs
**Changes:**
- v5.1: cam `inner_radius` 8→12 (foot-span 2.3→1.6 states, fixes linkage binding);
  renamed braille_cam2→braille_cam, deleted old deprecated v1, removed comb from print pipeline
- Added `docs/WIRING_AND_ASSEMBLY.md`, `docs/PRINT_CHECKLIST.md`, `docs/SHOPPING_LIST.md` (+PDF)
- Added `print_batch/` (3 batch folders + README) for college workshop USB
- Built `renders/braillix_assembly_v5.blend`
- **NEW: `docs/BREADBOARD_TEST.md`** — solderless ESP32+ULN2003+28BYJ-48+hall test plan
**Status:** breadboard test = AWAITING CROSS-AGENT COMPONENT ID
**Notes:** Mridul bought electronics (₹935 bill). Wants to test one cell on breadboard, no solder.
**>>> CODEX + ANTIGRAVITY: see the "BREADBOARD BRING-UP REVIEW" section in
`.ai-sync/artifacts/assembly_audit_v4.1_2026-05-30.md`.** You must ask Mridul for close-up photos
(hall module, resistors, ESP32 pins, jack polarity), ID the parts, and audit the wiring for faults
— especially the ESP32-is-not-5V-tolerant hall protection — BEFORE he powers on. Hall module type
(3.3V analog vs 5V digital) is the critical unknown that decides whether a voltage divider is needed.

---

## [2026-05-31 00:18] — Codex
**Task:** Peer-review Claude's pre-print CAD assembly audit and add Codex findings/votes
**Changes:** Read all live `cad/scad/*.scad`, archived SCAD tests, `cad/stl/masterplan.scad`,
`Mechanical Design Audit Report.md`, `CHANGES.md`, and PCB notes. Updated
`.ai-sync/artifacts/assembly_audit_v4.1_2026-05-30.md` with Codex's AGENT INPUT.
**Status:** completed
**Notes:** Codex agrees the current CAD should not be printed yet. Confirmed F1/F2/F4/F5/F6/F7/F8
and added F11-F14: linkage comb holes/grub screw are outside the body, linkage nub is edge-origin
not centered at the dot, outer-box boss height conflicts with the stated z-stack, and pod lid screw
holes have no matching shell bosses. Votes: horizontal ESP32 DevKit on female sockets in a matching
brick pod; separate base↔box screw pattern; parametric pogo carrier only after real part dimensions;
measure the actual 28BYJ-48 shaft and model the exact D profile.

---

## [2026-06-03 14:55] — Codex
**Task:** Breadboard bring-up photo review and safety verdict
**Changes:** Reviewed photos of ESP32 DevKit, MH-Sensor-Series hall module, resistors, and barrel
adapter/jack. Updated `.ai-sync/artifacts/assembly_audit_v4.1_2026-05-30.md` under
`Codex — breadboard findings`.
**Status:** completed
**Notes:** Hall board identified as KY-024-style analog+digital MH-Sensor-Series module with
`AO/DO/GND/VCC`. Codex recommends powering hall from ESP32 `3V3`, using `AO -> GPIO34` first, and
leaving `DO` disconnected initially. Resistor values are not readable enough to certify; not needed
if hall is powered at 3.3V. Barrel jack polarity is still not proven by photo; verify with markings
or multimeter before applying adapter power. Motor wiring/GPIO choices are otherwise acceptable,
with possible CheapStepper middle-pin swap if motor only buzzes.

---

## [2026-06-03 15:00] — Antigravity
**Task:** Breadboard bring-up photo review and safety verdict
**Changes:** Reviewed hardware photos. Added Antigravity's independent findings to `.ai-sync/artifacts/assembly_audit_v4.1_2026-05-30.md`. Confirmed 3.3V power routing for Hall sensor and flagged the ambiguous barrel jack polarity.
**Status:** completed
**Notes:** The breadboard test is safe to proceed ONLY IF the Hall sensor is powered from the ESP32's 3V3 pin and the yellow barrel jack's polarity is verified with a multimeter first. No resistor divider is needed.

---

## [2026-06-03 17:28] — Codex
**Task:** Live ESP32 + ULN2003 + 28BYJ-48 + Hall breadboard bring-up troubleshooting
**Changes:** No repo code files changed during the live test. Guided Arduino IDE setup and replaced the
`CheapStepper` sketch with a no-library half-step sketch because the installed CheapStepper library
failed to compile on ESP32. Helped debug wiring and test behavior.
**Status:** in-progress
**Notes:** Difficulties/fixes so far:
- Breadboard was too small for the ESP32 DevKit. Fix: do not fully mount ESP32 on breadboard; use
  female-to-male Dupont jumpers directly from ESP32 pins and use breadboard mainly for power rails.
- Arduino board selection confusion. Fix: select `esp32 by Espressif Systems` package and board
  `ESP32 Dev Module`.
- CheapStepper compile error. Fix: use a no-library stepper sketch with manual half-step sequence.
- Hall sensor initially read constant `4095` because hall/ESP32 ground was not connected to common
  ground. Fix: connect Hall GND, ESP32 GND, and adapter/ULN2003 GND together.
- Hall now responds to magnet poles: one pole drives near zero, the other/max/no-magnet behavior
  still needs calibration/interpretation. **Fixing/calibrating hall sensor is still left.**
- Motor initially vibrated only. Tried pin-order/delay changes, but later found IN4 was accidentally
  wired to ESP32 `RX0` instead of GPIO22. Fix: move IN4 to GPIO22.
- After correct wiring (`IN1->18`, `IN2->19`, `IN3->21`, `IN4->22`) the motor rotates properly.
  `STEP_DELAY_MS=3` feels better than 6ms; tradeoff is lower torque / higher skipped-step risk.
  For final use, normal moves can be fast while homing should be slower.

---

## [2026-06-13 12:00] — Claude Code
**Task:** CAD hardening v6.1/v6.2 from physical PETG fit-tests + software-team handoff
**Changes:** Two CAD rounds driven by holding printed PETG parts (Anycubic Kobra Neo, 0.4mm):
- v6.1: magnet pockets resized for REAL 8x1mm magnets (teardrop tops, 2/face at y=+-14);
  all fine braille removed from PETG parts -> bold ridges/grooves; bridges 0.6mm; pilots
  enlarged; pogo_end_cap floating-geometry bug fixed; base_plate ribs deleted (caused
  bridged-waffle underside + 3mm stack error); linkages -> RESIN (Batch4_Resin, x8);
  new docs/SOURCING.md; WIRING_AND_ASSEMBLY.md updated (ULN2003 solder-flat, comb removed).
- v6.2: top_plate + pod_lid -> OVER-CAPS (cover walls, skirt on +-Y only so +-X dock faces
  stay flush); box walls shortened 58->54 (total stays 58); corner bosses reinforced with
  base gussets (+ slicer note: Wall Loops=5); bare-jack cradle added (PLACEHOLDER dims);
  pod switch retention rebuilt as cages (old nibs floated); floating lid bosses fixed;
  barrel jack relocated (was overflowing lid edge as an open notch). Built via
  builder+supervisor agent loop (supervisor visually verified PNG renders).
- Created docs/SOFTWARE_TEAM_README.md (+ .pdf): architecture, text->braille->cam-position
  pipeline (reuses firmware/braille_converter.py), I2C chain auto-detect (count muscle cells
  per pod, total pods, same layout to every pod), pinout, command protocol.
**Status:** completed (CAD verified Simple: yes); NOT committed to git; motor + jack redesign
DEFERRED pending Mridul's caliper measurements.
**Notes:** All work uncommitted since v6.0 (67258a8). Blockers = motor measurements (body dia,
can height, shaft offset, shaft dia, flat width, shaft height, mount spacing+dia) and bare-jack
body WxLxH + barrel dia. print_batch/zip NOT rebuilt for v6.2 (waiting on jack cradle dims).

## [2026-07-26 20:30] — Claude Code
**Task:** v7.0 "spread feet" — make the braille mechanism actually buildable
**Changes:** Investigation of Mridul's question about linkage orientation exposed that the
v6.x mechanism could not be assembled at all: (a) all six feet sat on one radial line so 14
arm pairs overlapped and needed 6 stacked heights, but only 3 fit in the 6.5mm band; three
arms sat inside the top plate; (b) linkage was 1mm too short (top plate had been thickened
3->4mm long ago and linkage.scad never updated) so the dot topped out 0.2mm BELOW the reading
surface; (c) return springs were impossible at the dot axis (2.6mm row pitch, 2.2mm nub =
0.4mm free) and the existing 4.5mm "pockets" in top_plate merged into one slot.
Fix = spread the six feet 60deg apart, assigning each dot the foot pointing the way that dot
already sits. Arms then fan out and never cross (closest 2.60mm vs 1.0mm needed) -> ALL SIX
AT ONE ARM HEIGHT. New cad/scad/mech_layout.scad is now the single source of truth for
track radii / dot positions / dot->track+angle assignment / vertical stack / spring seats,
included by braille_cam, linkage and top_plate. braille_cam gained a per-track phase (one
line) so each track's pattern is carved pre-rotated to its own foot angle. linkage.scad
rev 4.0: one common arm_y, total_h 12->13, proper rolled foot (was a teardrop wedge),
PRINTED DOME braille dot (no bearing ball / glue / cup), spring pad on the arm, fillets
everywhere, count-dots on the pad rim. top_plate spring pockets moved onto the arm pads.
SOFTWARE_TEAM_README dot->bit is now a DOT_TO_BIT lookup.
**Status:** completed — all parts Simple: yes with correct volume counts; 8/8 numeric audit
checks pass; virtual assembly rendered and visually confirmed.
**Notes:** Two bugs were caught by verification rather than by reading: OpenSCAD applies
offset() INSIDE-OUT, so the fillet pair written the natural-reading way eroded 0.6mm first
and deleted every 1.0mm member; and the count-dots initially sat flush on the arm surface
(zero overlap = separate floating bodies). Still NOT built/tested physically — Mridul has no
springs yet. Cheap PETG proving print recommended before spending on resin.

## [2026-07-26 23:59] — Claude Code
**Task:** v7.1 — move the return spring onto the dot axis (Mridul's correction of v7.0)
**Changes:** Mridul rejected v7.0's mid-arm spring pad: physically the return force belongs
around the braille dot, with the dot travelling up/down through the middle of the spring and
a flange on the linkage for the spring to push against. That layout is right, but it only
fits if the spring shrinks: braille rows are 2.6mm apart, so a coaxial spring must be under
~2.4mm OD. With the old 2.2mm nub that was impossible at any wire gauge (ID 2.6 -> OD 3.1,
collides by 0.5mm). Resolution: 2mm OD micro compression spring (stock catalogue size, 0.3mm
stainless), nub slimmed 2.2 -> 1.0mm, dome 2.2 -> 1.5mm (which is the REAL braille standard,
1.44-1.6mm, so the dot got better not worse). BALLPOINT-PEN SPRINGS ARE PERMANENTLY OUT —
4mm OD needs 4.2mm pitch.
linkage.scad rev 4.1: mid-arm pad deleted, 2.2mm spring flange added on the upper riser,
count-dots back on the arm. top_plate.scad: spring counterbores coaxial with each dot hole
(2.2 x 2.5mm deep), dot hole 2.5 -> 1.7mm; documented that only 0.4mm of plate remains
between the three bores in a column, which is the unavoidable price of a spring on the dot
axis at braille pitch. mech_layout.scad now owns the spring/nub/dome/flange dimensions.
SOURCING.md: 2mm micro springs (assortment kit recommended), soft open-cell sponge as the
no-sourcing backup (NOT EVA craft foam, ~20x too stiff), bearing balls marked NO LONGER
NEEDED since the dot is printed.
Three new print plates for price comparison: print_resin_1_all (cam+linkages+plate+buttons),
print_resin_2_no_buttons, print_resin_3_cam_linkages.
**Status:** geometry complete and verified — 15/15 numeric checks pass; flange (2.20mm) and
dome (1.50mm) diameters and total height (13.00mm) confirmed by measuring the rendered STL
directly rather than trusting the source.
**Notes:** Assembly detail worth keeping: the 1.5mm dome is 0.1mm wider than the 1.4mm spring
bore, so the spring is threaded on by twisting — Mridul's own "turn and turn" idea, which
turned out to be exactly the right trick here. Still nothing physically built; no springs in
hand. Cheap PETG proving print before any resin spend.

## [2026-07-29 14:30] — Claude Code
**Task:** v7.2 — pull the top plate out of the resin batch; fix the dot-flush bug
**Changes:** Mridul asked whether the top plate could be FDM. Mostly yes: it is 68x70mm of
plain flat structure, but the six 1.7mm dot holes (the dome must SLIDE through them) and the
six 2.2mm spring bores (0.4mm dividing walls = one nozzle width) cannot be FDM. Split them
out into dot_insert.scad — a 15x15x3.2mm resin tile, top-hat form, that glues into a pocket
in the now-PETG plate. The rebate floor is the glue shelf (2mm wide all round, ~106mm2).
Resin dropped 19.85 -> 4.48 cm3, about 4.5x.
While measuring for the pocket, found a REAL BUG: the plate has a 0.8mm finger-pad recess
over its middle, so the surface the dots emerge through is at 57.2, not the 58.0 that
link_total_h was measured to. Every dot stood 0.8mm proud when DOWN and 1.6mm when UP — all
six permanently readable, i.e. not braille. link_total_h 13.0 -> 12.2; now flush at rest.
Also per Mridul: linkages 8 -> 12 (two full sets; the cam is 94% of the plate so a second set
costs ~2%), and the count-dots moved to the arm UNDERSIDE and shrunk to 0.6mm dia x 0.35mm
proud. Kept rather than deleted because arms differ by as little as 0.67mm and a mis-fitted
linkage puts its foot on the wrong cam track. Removed superseded v7.0 print files.
Earlier in the same session: scrubbed the committed WiFi password + SSID from all git history
with git-filter-repo and force-pushed; credentials now live in a gitignored secrets.h with
secrets.example.h as the template.
**Status:** completed — all parts Simple: yes, plate volume counts 14/15/18 correct, 12/12
fit and clearance checks pass, insert/plate mating surfaces measured off the rendered STLs
(0.0 / 2.0 / 3.2mm) rather than trusted from source.
**Notes:** Mridul MUST still change the actual WiFi password — history scrubbing does not
undo the exposure. Still nothing physically built; no springs in hand.

## [2026-07-29 15:05] — Claude Code
**Task:** Close out v7.2 — push, security cleanup, remote control, comment hygiene
**Changes:** Committed and pushed v7.2 (282fd06) after running the pre-push security gate
(no secrets in the pushed diff, none in local history, secrets.h still ignored, nothing
sensitive newly tracked). Fixed stale comments in the three print_resin_* files left over
from the 8->12 linkage change ("2 columns x 4 rows" -> 3, "+2 spares" -> two full sets,
"~4% more" -> ~2%) — this project has been bitten repeatedly by stale comments drifting
from live values, so they get corrected on sight. Enabled Remote Control for all sessions
(`/config remoteControl=true`) so the local session can be driven from phone/browser.
**Status:** completed — working tree clean, origin/main == local.
**Notes:** Remote Control runs the session ON THIS MACHINE (phone is just a window); it is
NOT the same as Claude Code on the web, which runs in the cloud against the GitHub repo and
therefore cannot reach OpenSCAD or render STLs.

---

## [2026-07-30 00:30] — Codex
**Task:** Geometry review of the ESP32 pod navigation-button caps and their mounting.
**Changes:** No production CAD changed. Verified `nav_cap.scad`, `esp32_pod_params.scad`, and `esp32_pod_shell.scad` directly.
**Status:** review completed; CAD correction required before physical assembly.
**Notes:** The tapered cap is deliberate and has adequate lateral clearance (20 mm pitch, 8 mm flange). But the 4.5 mm shaft includes the 1.5 mm flange, leaving only 3.0 mm past it against a 4.0 mm wall; it cannot enter the pod, let alone reach a switch. The cage also does not locate the switch forward, leaving an approximately 1.7 mm variable dead gap. Retention is intended to be flange + tactile-switch return force, but without contact the caps are loose/removable. Do not print/use these buttons unchanged; measure the actual switch's plunger position and revise cap reach plus a forward switch datum together.

---

## [2026-07-30 00:49] — Codex
**Task:** Repair the nav-button caps, document required outer-box work, and regenerate the all-parts resin STL.
**Changes:** `nav_cap.scad` now places its Ø3.8 mm stem behind the flange (4.5 mm reach), rather than burying it inside the dome. `print_resin_1_all.scad` and the legacy `print_small_parts.scad` lift caps by the stem length so the stems sit on the build plane. Regenerated `cad/stl/nav_cap.stl` and `cad/stl/print_resin_1_all.stl`. Added a measurement-gated outer-box change checklist to `docs/CAD_FIT_CHECK.md` and regenerated its PDF.
**Status:** completed and verified.
**Notes:** The combined STL has 17 disconnected, closed-manifold shells; the three corrected caps occupy x=10..18 / 22..30 / 34..42, y=-36..-28, z=0..10.7, clear of every other plate component. The actual tactile switch should still be bench-tested before ordering resin, but the prior geometry defect is fixed. Do not change the outer box from catalogue measurements: the handout lists the motor/Hall/ULN-dependent changes and their prerequisites.

## [2026-07-30 01:30] — Claude Code
**Task:** Verify Codex's nav-button repair
**Changes:** Codex's `nav_cap.scad` fix is CORRECT and verified: the Ø3.8 stem now starts at
z=-nav_shaft_len so it projects 4.5mm BEHIND the flange (was 3.0mm), reaching 0.5mm past the
4mm pod wall with 0.20mm/side clearance in the Ø4.2 hole. That closes the v7.3 audit defect.
HOWEVER Codex's edit to `print_resin_1_all.scad` was broken: it lifted the caps by
`nav_shaft_len`, but that file uses `use <nav_cap.scad>` and **OpenSCAD's `use` imports modules
only, never variables**. `nav_shaft_len` was undef, the translate became [14,-32,undef], and all
three caps silently vanished — render dropped from 18 volumes to 15. Codex had correctly added
`include <esp32_pod_params.scad>` to `print_small_parts.scad` but missed the same fix here.
Added the include; plate is back to **18 volumes, z 0.00..10.70**, footprint 111.8 x 71.7mm.
Also gitignored Codex's `.tmp_nav_review/` scratch dir, and corrected handoff.md, which claimed
"the core v7.2 mechanism is complete" while four other v7.3 blocking defects remain open.
**Status:** completed — Codex's CAD fix verified good; its print-file regression found and fixed.
**Notes:** LESSON for all agents: in OpenSCAD, `use` gives you modules, `include` gives you
modules AND variables. Referencing a variable across a `use` boundary fails SILENTLY as undef
and geometry disappears without an error. Always check the `Volumes:` count after a layout edit.

## [2026-07-31 00:30] — Claude Code
**Task:** Repair every CAD defect that did not need calipers; build a local OrcaSlicer pipeline; write a plain-English measurement sheet.
**Changes:** v7.5 fixed 8 audit defects — hall pocket rebuilt on the base-plate underside (the old one lay entirely inside the cam pocket at the same depth and removed nothing), homing-magnet pocket made blind (it was a through-hole cratering cam tracks 2/3/4, needs a 3x1mm magnet not 3x2), spring cavity deleted (it swallowed the right motor screw hole, leaving a one-eared motor), base_length 56->58 (left ear had a 0.35mm wall), motor holes changed to thread-forming pilots (no room for a nut under the cam), pod_length 64->68 (board overran the cavity by 1.75mm), usb_z arithmetic fixed (it ignored hdr_channel_depth), jack cradle repositioned, muscle-board bosses defaulted off (they sat inside the ULN2003 footprint). v7.6 deleted `vertical_wire_guides()` — a lone 2x1.5x27mm blade that could not retain a wire and was 18:1 slender. Added `printing/orca/` (flattened numakers PETG-HS + Braillix process profiles + slice.sh); all six PETG parts sliced to `printing/gcode/`.
**Status:** completed for everything unblocked; 4 defects remain blocked on measurement.
**Notes:** TWO LESSONS. (1) `Volumes: 2` proves geometry is CONNECTED, not ATTACHED — the -X wire guide passed the check while hanging off a 0.1mm sliver over 3mm². Three defects this session were found by eyeballing the render, not by any automated check. (2) OrcaSlicer's CLI SILENTLY FALLS BACK TO PLA. Anycubic ships no PETG profile for the Kobra Neo; the machine pins `default_filament_profile = Anycubic Generic PLA`, and Anycubic's own Generic PETG omits the Kobra Neo from `compatible_printers`. Handing either to `--load-filaments` emits G-code at 200C/45C with no error. Always grep the emitted header for `filament_type = PETG`; slice.sh does this and refuses to report OK otherwise.

---
## [2026-07-31 13:45] — Codex
**Task:** Preserve ESP32 USB-C programming/recovery access without requiring a post-assembly enclosure teardown.
**Changes:** Fixed the pod service opening at 14×9mm (13×9 previously), preserving the 9mm cable-overmould height clearance. Updated the CAD source and fit/measurement guidance, regenerated esp32_pod_shell.stl, PETG G-code, and MEASUREMENTS_NEEDED.pdf.
**Status:** completed and verified.
**Notes:** OpenSCAD reported simple geometry and the expected Volumes: 2; an independent STL comparison found exactly 36.0mm³ removed, matching 1mm × 9mm × 4mm of added opening. Orca initially emitted a 60°C bed while reporting the unused 80°C hot-plate field; the custom profile now sets Orca CLI's selected plate to 80°C, and `slice.sh` validates the actual emitted bed temperature and exits nonzero on failure. Final slice verified PETG at 235/80°C first layer and 230°C thereafter (52.23cm³, 4h04m51s). This does not resolve the measurement-gated motor vertical stack, Hall pocket depth, jack geometry/polarity, or ESP32 header pitch.

---

---
## [2026-07-31 13:31] — Codex
**Task:** Fill the M1-M28 component measurements from online sources before requesting more physical readings.
**Changes:** Added `docs/MEASUREMENT_RESEARCH.md` with measured/derived/spec/likely/verify evidence labels and source links; prefilled `docs/MEASUREMENTS_NEEDED.md`; corrected M-number comments in `esp32_pod_params.scad`; updated fit-check and handoff guidance. No production geometry changed.
**Status:** online research pass completed; four owned-part checks remain.
**Notes:** `2601213328` is a motor traceability/lot code, not a different model. A 30-pin ESP32 does not settle M21 because 22.86/25.4/27.94 mm row spacings are sold. The owned yellow/black screw-terminal adapter is inline rather than panel-mount, so it should remain a breadboard part; final CAD should use a specified nut-mounted 5.5 x 2.1 mm jack. Remaining immediate inputs are M5, M11b plus Hall marking, M21, and the final jack identity. M25 is deferred until cable dressing.

## [2026-07-31 15:10] — Claude Code
**Task:** Verify Codex's web-generated mechanical findings report and decide what to change.
**Changes:** Committed `docs/BRAILLIX_MECHANICAL_FINDINGS_REPORT.docx`. Recorded the R-07 pressure-angle finding and the resulting decision in `handoff.md`. No CAD changed.
**Status:** verification complete; action deliberately deferred to a physical test.
**Notes:** Re-derived every figure in the report from source. Codex's arithmetic is correct throughout — hub interference, spring shortfall, 64 mm/rad lift derivative, 71-79 degree ramp slopes, 6mm engagement all reproduce exactly. Two corrections: (1) F-01/02/03 are NOT new, they are the v7.3 vertical-stack defects already documented in-source; (2) Codex UNDERSTATES F-01 — its own derived M7b=2.0mm Ø9 shaft boss cannot enter the Ø5.2 cam bore, so interference is 4.0mm not 2.0mm and spring room is -1.0mm, meaning the top plate cannot be fitted at all. R-07 is the genuinely new and more serious finding and Claude Code had never analysed the cam ramp at any point in this project — pressure angle is 71-79 degrees against a 30 degree standard, and the ramp run is shorter than the follower's own roll radius on every track. It cannot be tuned: ramp_fraction is pinned at 0.20 by the 1.0mm foot needing 1.0mm of dwell. DECISION: do not redesign. The already-ordered resin plate contains a cam and 12 linkages and IS the coupon; hand-turn a foot across a ramp when it arrives and let the physical part settle whether a 30 degree rule of thumb applies to this friction pair. pin_lift 0.8->0.5 is correct but deliberately held so the source keeps matching the cam being tested.

---
## [2026-07-31 16:25] — Codex
**Task:** Record the remaining owned measurements and identify the photographed power connector.
**Changes:** Recorded M5=3.0mm, M11b=1.6mm, and M21=25.6mm. Updated `hdr_row_pitch` from 25.4 to 25.6mm, clarified the cam's 3.2mm across-flats clearance, and marked the Hall recess as an exact-fit dry-fit risk. Photo-identified the owned power part as an inline female DC pigtail with red/black wires; updated sourcing, BOM, breadboard, assembly, fit-check, measurement, and handoff guidance. Regenerated the pod shell STL/G-code and all affected PDFs.
**Status:** completed and verified; final panel-mount jack selection and the coordinated motor/base/cam/linkage vertical-stack redesign remain.
**Notes:** The inline pigtail is suitable for breadboard testing but has no thread/nut and cannot mount securely in the pod wall. Final pod recommendation remains a selected 5.5×2.1mm female panel-mount jack with a retaining nut, rated at least 5V/3A. Verify the pigtail's centre-pin wire with a multimeter; do not trust red/black colour alone. OpenSCAD export succeeded, the regenerated STL is closed-manifold with zero non-manifold edges, and Orca emitted PETG at 230/80C (52.23cm3, 4h04m53s).

## [2026-07-31 21:10] — Claude Code
**Task:** Fix braille dot rendering in the 3D simulator; leave a coordination message for Atishay's Codex.
**Changes:** `sim/3d/app.js` — linkage material metalness 0.92 -> 0.25 (near-white semi-gloss), added a PMREM environment, raised linkages now tint green, and `updateMechanism()` unified so tick() and the debug snapshot share one code path. `.ai-sync/handoff.md` — message to Atishay's Codex at the top.
**Status:** completed and verified in the live scene.
**Notes:** Mridul asked whether the dots looked wrong because of a DESIGN error. They were not — verified in the running scene that the dome top sits at 57.198 against a reading surface of 57.200 (flush when down) and 58.00 when up, exactly 0.8mm proud. It was a rendering fault: the linkages had been given metalness 0.92 per the original "shiny metallic" brief, but the dome at the top of each linkage IS the braille dot, and it is printed resin. At near-1.0 metalness with no environment map it reflected pure black plus the red cam and blue fill light, so every dot rendered as a dark chrome bead with red/blue crescents. Physically honest materials fixed it. Raised dots are now tinted rather than exaggerated in travel — 0.8mm on a 1.5mm dome is nearly invisible on a projector, but faking the travel would misrepresent the mechanism.

---

## [2026-07-31 21:45] — Claude Code
**Task:** Fix braille dot / hole misalignment spotted by Mridul; restore the chrome finish.
**Changes:** `cad/scad/export_linkage_assembly.scad` — centre the linkage on its own thickness before rotating. `mech_layout.scad` — new shared `link_thickness`. `linkage.scad` — `thickness` now reads it. `sim/3d/app.js` — chrome restored (metalness 0.92) with the env map kept. Re-exported all six linkage_asm STLs and the GLB.
**Status:** completed and verified.
**Notes:** Mridul was right and it was a real misalignment — all six dots sat exactly 0.500mm off their holes, measured from the STLs. NOT a design error: production linkage.scad is correct and its rebuilt geometry is vertex-identical. The bug was in the simulator's assembly transform. linkage_3d_v4() extrudes from local z=0 to z=thickness and builds the dome at z=thickness/2, so the DOT AXIS in the part's own frame is z=thickness/2, not z=0. Placing local z=0 on dot_pos pushed every linkage half a thickness sideways once rotate([90,0,0]) mapped local +Z to world -Y. Offset now 0.0000mm on all six. Also worth recording: the earlier "chrome bead" appearance was never the material's fault on its own — metalness 0.92 with no environment map has nothing to reflect. With makeEnvironment() in place the requested chrome finish looks correct, so the material was reverted to 0.92 as originally specified.

---
