# CURRENT CAD — one muscle cell, 3 x 1.5 mm cam magnets

## Upload this ONE file once
`stl/print_resin_1_muscle_cell.stl`: 9 separate bodies = 1 cam + 6 different arms + 1 tile + 1 screw-retained R2 comb. No sprues, no button caps. Quantity ONE batch, not two batches. Millimetres, 100% scale. Supplier chooses resin orientation/supports; this layout is not a resin machine build file. Tough/ABS-like resin as previously specified; actual feature capability must be confirmed by supplier.

## Magnet installation — important
3 mm diameter x 1.5 mm thick. Pocket diameter 3.2 mm, depth 1.6 mm. The resin roof above the pocket is 0.4 mm under the lowest track. The magnet sits 0.1 mm below the cam underside. Use a thin layer of glue to make it flush. Nothing projects. Keep glue away from rotating surfaces. Turn the cam by hand through a complete revolution before you apply power. Check the Hall switching and the magnet polarity BEFORE the glue sets. CAD checks do not verify magnetic switching, resin shrinkage or wear.

Cam is based on exact previously printed track mesh in assets/braille_cam.stl. Only the underside magnet pocket is filled and recut. This is intentionally a mesh-backed SCAD, preserving original cam phase, ramps, bore and hub. It is not a newly substituted parametric track generator.

## Which SCAD to open
`scad/print_resin_1_muscle_cell.scad` — entire resin batch.
`scad/braille_cam.scad` — changed cam.
`scad/base_plate.scad` — matched base without obsolete motor seat/ear pilots.
`scad/outer_box.scad` — 68x68x58 nominal tall candidate, open PCB end brackets.
The scad/ and stl/ folders in this directory are the only current CAD.

FDM base/lid/retainer and resin comb are matched as checked. Keep the screw-held Hall retainer for now. The unfinished shell-mounted Hall slider is NOT included in this release; its archived concept still lacks complete retention/wiring/print qualification. Driver dimensions, electronics fit and wiring in tall shell remain conditional on actual hardware. Brain geometry is not newly verified here.

## Verification
19 selected intersection checks including new magnet full swept annulus against base and comb; three arm heights. Threshold0.001 mm3 permits numerical seating residue. Combined9-body STL mesh integrity checked. These checks are not a load test, magnetic test or a guarantee of print success. Results in verification/results.json. No G-code supplied for changed geometry.

## Rebuild
From project root: python tools/build_current_muscle.py; python tools/check_current_muscle.py; Blender CLI tools/render_current_muscle.py. Older candidate builders are historical and may require restoring archived inputs. Use current builder only.

## Cleanup
Superseded CAD directories and dated old audit/print reports moved into D:/TIET/Capstone_archive. Archive is recovery/history only, not a print source. See its manifest. Existing printing packages are historical; they have not been silently regenerated. This current combined resin STL is the new upload source.
