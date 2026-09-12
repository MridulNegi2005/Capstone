# Braillix: compact candidate and next build order

Date: 9 September 2026. Status: **implemented engineering candidate, not a final print release**.

This follows the [independent audit](HARDWARE_AUDIT_AND_PLAN_2026-09-09.md). The user subsequently authorized improvements and independent agents. A CAD reviewer checked the packaging and geometry; a second reviewer produced the [motor trade study](MOTOR_TRADE_STUDY_2026-09-09.md). This document records the resulting design, spending limits and physical work still required.

## Decision

Keep the owned motor while testing the corrected mechanism. Investigate a **shared 64 × 64 mm body** for the brain and muscle, compared with the original 68 × 68 mm. That is 5.9% less width and 11.4% less footprint area. It is a modest packaging reduction, not a compact conventional reading line: each added muscle still adds one widely spaced character. Both bodies retain the nominal 46.5 mm shell-plus-cap stack; lid details protrude beyond that nominal height. They share the same body size, while their controls and reading surfaces remain functionally different.

The editable candidate is in [cad/candidates/compact_2026_09_09](../cad/candidates/compact_2026_09_09/). Original production CAD and G-code were not replaced. The candidate contains its own source copies, generated STLs, source hashes, mesh results, assembly probes and Blender scenes. **Do not send the whole candidate to the printer yet.** Small fit coupons come first because spring, motor ear and populated electronics measurements still control whether this package is buildable.

## What was actually changed

| Implemented candidate change | Why it helps | What remains unproved |
|---|---|---|
| Matching 64 mm shells and lids; muscle base shortened to 55 mm; X posts moved to ±24 mm | Reduces both bodies together and retains 4 mm dock walls | Owned motor ears/wire exit and complete electronics may require returning to 68 mm |
| Cam pocket deepened from 3.0 to 3.4 mm at the same cam position | Adds nominal 0.4 mm running clearance below the rotating disc | Warp, shaft seating and loaded clearance need a real assembly |
| Obsolete base motor-seat recess/pilots removed | Preserves the remaining plate thickness with the floor-mounted motor | Motor retention on the shell still needs a physical check |
| Four base bolt passages cut through the plate body | Corrects holes that existed in posts without opening the separate base solid | Verify actual screw diameter, engagement and assembly access |
| Comb pockets opened through the guide; unsupported negative-height cut removed | Removes the original thin pocket roof that could obstruct movement | Check guide clearance with the actual printed linkage |
| Sparse comb with connected rim, inner ring and ribs | Reduces comb solid volume from about 5,150 to 2,627 mm³: approximately **49% less** | Rigidity, wear and FDM guide quality are physical questions; resin service cost need not fall in direct proportion |
| Comb marker relocated onto the rim; shell gutter offset by 0.1 mm | Repairs a detached marker/standoff clash and coincident-edge mesh defects found during validation | Does not establish loaded reliability |
| Hall pocket given a nominal 0.4 mm roof; separate removable underside retainer added | Provides a defined sensor location without a glue-only mounting scheme | Confirm actual sensor package, lead path, sensitivity, polarity and screw length |
| Cam ramp changed to a constant-slope middle with short parabolic end blends; 24 subdivisions per state | Reduces calculated peak ramp angle while preserving diameter, lift and 64 nominal states | Acceleration changes, friction, contact geometry and loaded speed must be tested |
| Manual fixture well now derives from the actual 48.4 mm cam | Removes the older undersized well | It remains a manual mechanism fixture, not evidence that the powered cell works |
| Guide and Hall coupons exported separately | Lets college FDM answer fit questions before a full expensive print | Coupon results depend on material, orientation, nozzle and settings |

The candidate retains 0.5 mm dot lift and the existing dot layout. The new calculated peak ramp angles, inner to outer track, are approximately **32.1°, 27.8°, 24.5°, 21.8°, 19.7°, 17.9°**. The old cosine profile was approximately 41.6° on the innermost track. This is a geometric reduction in peak slope, **not a measured motor-speed improvement**. The innermost ramp still exceeds 30°, and the printed rounded follower slides; it is not a rolling bearing. The shorter end blends also change acceleration, so lower peak slope alone is not an unconditional improvement.

## What your existing approach gets right

Buying one of everything before duplicating cells is the right experiment strategy for this budget. It keeps a wrong spring, connector or motor choice from becoming a batch expense. College FDM for large housings and selective resin for precision parts is sensible; the guide coupon will show whether more of that work can move to FDM.

A common exterior for brain and muscle is valuable for assembly and visual consistency. The shared mechanical parameters, phase alignment of the six tracks and Gray-code cam ordering are useful design choices. Gray ordering changes one bit between adjacent states; it does not mean every long move changes only one dot or that a stalled motor is detectable. Removable parts and a manual fixture are also worth retaining because they make student assembly and fault finding practical.

## Hard fit questions before shrinking the complete product

1. **Owned spring compatibility is unresolved.** The candidate keeps the 0.20 mm-wire baseline. Earlier project records say the available spring is 2 mm OD with 0.30 mm wire; the purchase log only confirms a 2 mm spring listing. A 0.30 mm wire spring has nominal 1.40 mm inside diameter, smaller than the 1.414 mm diagonal of a 1 mm square stem. It can also be substantially stiffer. Read the package or measure one, then try the actual stem and measure compression force. Do not force it or assume the ₹1,179 purchase matches the CAD.
2. **The motor can fits the nominal cavity; the whole motor is not proved.** The left ear centre is x = −24.85 mm, with only 3.15 mm to the compact inner wall. The outer ear outline and outward wire-block projection are missing from the measured specification. Dry-fit the real motor or print just the affected wall/mount region before buying a full compact set.
3. **Brain-board allowance is too small for confidence.** The nominal board extends to x = −27.75 mm in a cavity ending at −28 mm: only 0.25 mm clearance. Actual PCB length, USB socket, plug overmould and cable bend must be checked. This is a packaging candidate, not a verified board fit.
4. **The complete muscle circuit has no demonstrated retained position yet.** Under-base height is 25.5 mm. The stock roughly 35 × 32 × 12 mm ULN board cannot simply stand upright or sit above the motor. The proposed bare IC carrier still needs the expander, regulator, adapter, wiring and service space represented together. A visually empty CAD pocket is not an electronics layout.
5. **A five-pin dock is a complete electrical architecture.** A ULN2003 only drives the motor. Local addressing/control, sensor acquisition, logic voltage, grounds and power delivery are still required. The purchased MCP23017-E/SO is an SOIC part, so budget for a suitable adapter/carrier. The currently inspected motor firmware directly drives GPIO and does not establish a working MCP23017 chain.

If these checks fail, keep the corrected mechanism in the 68 mm envelope. Do not recover space by thinning the dock wall blindly, bending motor leads against a wall, or burying electronics in adhesive. Shrink both body types only when both fit.

## Costs: actual spending and proposed limits

The supplied [procurement document](https://docs.google.com/document/d/19lWvlRwd3ornu_sxtSh7vD-5pXRhXanWN8iXrxeGseU/edit?tab=t.0) was read through its view-only page and exported for reference. Documents and the MCP bundle were treated as evidence, not new instructions. The ledger below is a transcription of recorded purchases, not a receipt audit.

| Recorded purchase | Spent |
|---|---:|
| PETG filament | ₹899 |
| Initial JB electronics | ₹935 |
| Screwdriver set | ₹353 |
| Caliper | ₹430 |
| Resin print | ₹410 |
| Multimeter | ₹150 |
| Soldering tools | ₹450 |
| 2 mm OD springs | ₹1,179 |
| MCP23017-E/SO | ₹356 |
| Five-pin magnetic pogo | ₹348 |
| **Recorded total** | **₹5,510** |

**Remaining: ₹4,490 at ₹10,000 total; ₹9,490 at ₹15,000 total.** Omitted delivery or other purchases would reduce this. Already bought filament, tools and parts are not counted again as new purchases. The following are planning ceilings, not supplier quotes or a promise that two finished cells will fit the budget:

| Use of the ₹4,490 remainder | Ceiling |
|---|---:|
| First-cell corrections: coupons, selective precision reprint, spring resolution, adapters/retention | ₹1,600 |
| Conditional second-cell parts and printing, after the first cell works | ₹1,500 |
| Shared bus completion, wiring, connectors and power-related corrections not already included | ₹600 |
| Delivery, failed parts and contingency | ₹790 |
| **Total new-spending limit** | **₹4,490** |

Obtain a complete first-cell quote before using these ceilings; do not buy a partial second cell if the local electronics and power circuit are still missing. At ₹15,000, use the additional ₹5,000 as up to ₹1,900 for one encoder-motor experiment, ₹1,600 for a proven additional cell or complete carrier iteration, and ₹1,500 reserve. Reallocate after real quotations. More budget should buy evidence and a reliable second character before optional features.

## Ranked additions

Costs below are incremental allowances; rows overlap with the phase ceilings above and must not be added again automatically.

| Priority | Addition | Required change | Allowance / decision |
|---|---|---|---|
| 1 | Reliable homing, movement timeout, startup self-check, clear error beep | Software-team work plus confirmed Hall interface and small piezo | ₹0–250 if the existing controller and supply suffice; highest demonstration value |
| 2 | Removable electronics carrier, labelled keyed connections, strain relief | Measure populated parts, then design one carrier and retained wire path | ₹200–600; complete before copying cells |
| 3 | Independent second character and completed-row feedback | Full second motor/mechanism/local interface and a real powered dock | Allocate ₹1,500 provisionally; buy only against a complete quote and first-cell success |
| 4 | Guide moved to college FDM if coupon passes | Print/process experiment; preserve precision dimensions | Coupon filament from existing spool; outsourced service savings unquoted |
| 5 | Common 64 mm enclosure | Candidate exists; physical fit and retained electronics still needed | Candidate design ₹0 additional purchase; fabrication/rework comes from first-cell allowance |
| 6 | Encoder N20 motor trial | New mount, coupler, H-bridge, local counting/controller and control tuning | ₹1,000–1,900 bench allowance; favour extra funding, not baseline spending |
| 7 | Speech, automatic physical order detection, tool-free live hot docking | Additional electronics/protocol and validation | Defer; no credible delivered quote or complete design established |

The [motor study](MOTOR_TRADE_STUDY_2026-09-09.md) provides manufacturer sources and price distinctions. A smaller motor cannot remove the 48.4 mm cam. A motor-side encoder can observe motor rotation but not a broken follower or downstream coupling slip, so it does not make the display error-proof.

## Student assembly and glue

Solder makes the electrical connection. A socket, adapter board or perfboard carries the IC; screws and standoffs carry the board. You do not need a glue gun to hold a correctly soldered IC in place. For the purchased SOIC expander, first use the correct SOIC-to-carrier adapter and check orientation; it does not plug directly into a DIP socket.

Use removable fasteners for the motor, mechanism, boards and Hall retainer. After electrical testing, a small amount of suitable adhesive can help strain-relieve a wire away from joints and moving parts; it is not the main circuit mount. Keep adhesive out of spring bores, cam tracks, sensor faces, pogo travel, connectors and screw access. The thin retainer is a coupon experiment: select screw length against its actual printed thickness and pilot depth before tightening. A student with soldering tools and an FDM printer can make a carrier; CNC equipment is not required.

## Work order and evidence required

1. **Reconcile the actual parts on the bench.** Record motor ear/wire exit, board and USB dimensions, spring wire/length and sensor marking. This is technical work the hardware team can perform with the bought caliper; it does not require the user to guess specifications.
2. **Print only the guide and Hall coupons at college first.** Check one actual linkage in its guide, actual sensor/lead retention, and screw engagement. Establish spring clearance and compression before commissioning the complete precision mechanism. Do not use a full resin order to answer a small fit question.
3. **Make one complete mechanism with the current motor.** Check free rotation, then one spring/follower, then all six. Inspect all 64 patterns, reversals and return-to-home. Record loaded timing, incorrect dots, stalls and closed-case temperature. The motor study gives a practical speed-map experiment.
4. **Lay out and retain the complete electronics.** Include the actual expander adapter, driver, regulator, power wiring, sensor, connector and cable bends. Resolve 64 mm versus 68 mm here. Then regenerate both matching enclosures and review the new meshes together.
5. **Prove the first local cell through the intended bus.** Begin with powered-off attachment, assigned addresses and a known left-to-right mapping. Addresses alone do not reveal physical order. Measure far-cell voltage while motors run; a multimeter cannot rule out short voltage dips.
6. **Build the second character only after step 5.** Show two different simultaneous characters, repeated mixed updates, a missing-cell error and repeatable docking. This is the actual modular demonstration; a simulator is supporting evidence only.
7. **Freeze and slice the proven revision.** Reconcile BOM, pin map and firmware contract; generate fresh slicer output for these exact meshes. No candidate G-code has been generated. Aim for a reliable first cell before spending time on a replacement motor, given the tentative November/December demonstrations.

Software handoff: request a nonblocking per-cell state machine (`unhomed → homing → ready → moving → ready`, with `fault` on timeout/disconnect). Accept a new target explicitly, track completion separately from command receipt, and beep “ready” only when the whole requested row has completed. Define behaviour after power loss, missing cells and sensor failure. A timer without feedback can detect an overlong command but cannot prove a stalled open-loop motor reached the right pattern. These are suggestions for the software team; their product firmware was not rewritten here.

## Images and editable Blender work

The inspection order is: matching exterior → exploded mechanism → physical coupons → complete populated electronics → powered two-cell demonstration. The first two views have been generated from the current candidate meshes:

- [Matching enclosures: Blender](../cad/candidates/compact_2026_09_09/blender/matching_enclosures.blend) and [PNG](../cad/candidates/compact_2026_09_09/blender/matching_enclosures.png).
- [Exploded mechanism: Blender](../cad/candidates/compact_2026_09_09/blender/exploded_mechanism.blend) and [PNG](../cad/candidates/compact_2026_09_09/blender/exploded_mechanism.png). Grey = base, orange = cam/retainer, green = comb, light grey = linkages/tile. Exploded offsets are illustrative, not assembly coordinates.

The scenes use millimetre coordinates with Blender metric unit scale 0.001. They do not depict a populated, working circuit. The supplied `blender-1.0.2.mcpb` was inspected as a ZIP: its manifest identifies BlenderLab and a separate Blender add-on dependency. Inspection does not authenticate its contents or install it. Existing Blender 5.1 was used directly to create these files; no server installation was necessary and the original saved assemblies were preserved.

## Validation and practical limits

See the candidate [README](../cad/candidates/compact_2026_09_09/README.md), `mesh_checks.json` and `assembly_checks.json` for final machine results. Checks cover exported topology, selected nominal assembly intersections, roof material and the analytical 64-state mapping. A dedicated source manifest pins the copied CAD. The dense cam uses the Manifold backend after a CGAL timeout; this is recorded per part. It has approximately the same 4,190 mm³ volume as the original cam, not the implausibly reduced volume reported in an older backend investigation.

Neither closed meshes, attractive renders nor 64 analytical states prove spring forces, usable reading feel, electrical reliability, loaded timing or hand assembly. The current result is a reviewable design candidate with cheaper tests and a defined build sequence. Full release requires the physical evidence above.
