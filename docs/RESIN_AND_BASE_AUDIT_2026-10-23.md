# Base and original resin audit — 23 October 2026

## Screenshot / base revision
The pictured offset circular recess, two small holes flanking the shaft and edge wire channel match cad/scad/base_plate.scad motor_features() and Hall pocket geometry. Screenshot identity is inferred from geometry, not a supplied source filename.
- Central large hole: motor shaft/collar clearance; keep.
- Two small holes: legacy motor-ear screw pilots at X=-24.85 and +9.85, Y=0, diameter3.3mm. These are not arbitrary lightening holes.
- Offset circular shallow recess: old motor-body seat, nominal1.5mm deep, centreX=-7.5.
- Rectangular recess and narrow edge channel: Hall body and its wires.
The newer two_board_2026_10_20 candidate motor_features() retains only the shaft hole: old motor recess and ear pilots were already removed. Motor locates in shell cup instead. Do not re-export the stale canonical base as a replacement for the delivered candidate.

Blind recesses are not inherently unprintable. Down-facing roofs bridge over empty space; orientation, span, first layers and slicing matter. The Hall pocket cannot simply become a through-cut without rechecking the cam running surface. Canonical hall_interface also differs from candidate: canonical default depth4.6mm versus candidate1.2mm with0.4mm roof under a3.4mm cam pocket. This is a substantive source-version mismatch.

## Original combined resin STL
Checked cad/stl/print_resin_1_all.stl, SHA256 8e1fae0fe21ffe824783dc5498cd7d013699a2318213efdf92d53d8692d6f0d8.
17 connected watertight components, consistent winding: cam1, arms12(two of each), tile1, buttoncaps3. All17 existing selected assembly probes rerun successfully using tools/check_owned_resin_assembly.py. These are geometric interface checks, not physical function tests or a new full motion simulation. Track precision, spring fit/force, print shrinkage and motor load remain unverified.

Two cells require two cams and two tiles; original batch supplies only one each. Twelve arms supply two sets, leaving no spare set. Comb absent from original batch; current muscle print package supplied it separately. Braincaps present once as required for one brain.

R2 combined file print_resin_1_all_R2_2026-10-05.stl contains15 watertight components: cam1,tile1,comb1,arms12; no caps. This is a different revised batch, not simply the original file with a new name. No blanket substitution approved.

## New cam magnet: diameter3 x thickness1.5mm (user confirmed)
Original mesh has pocket diameter8.2mm, bottomZ6.5, roofZ7.7: depth1.2mm. Cam floor spansZ6.5..8.5, thickness2mm, leaving0.8mm above old pocket. Sensor/magnet nominal centre X0 Y17.35.
New magnet does NOT fit the old pocket as a properly located flush insert: it is5.2mm smaller than the hole diameter and0.3mm thicker than the pocket depth, before glue allowance.
Naively setting3.2mm diameter and1.7mm depth leaves only0.3mm cam floor. Current cam source explicitly guards against leaving0.5mm or less. Do not bypass this assertion or cut through a running track.
A revised cam/magnet-seat design is required before ordering this new magnet version. Preserve tracks, shaft bore and Hall XY alignment; verify final roof thickness, magnet projection/glue allowance, base running clearance and Hall switching with the smaller magnet. No physical magnetic switching performance is implied by CAD checks.

## Outcome
No production geometry or combined STL changed during this audit. Original old-magnet assembly passes selected geometry probes; new3x1.5mm magnet version is not ready to order. Hall wall-carrier remains a separate unfinished concept. Raw mesh results: cad/candidates/resin_audit_2026_10_23/mesh_audit.json; rerun interface evidence: cad/candidates/owned_resin_2026_10_09/assembly_verification.json.
