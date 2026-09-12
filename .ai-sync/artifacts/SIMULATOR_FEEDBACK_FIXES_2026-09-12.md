# Simulator feedback fixes — 2026-09-12

Implemented the user's reported onboarding, navigation, parts, dimensions and multi-cell UI fixes. Local only; no commit, push, deployment, CAD or firmware changes. The previously excluded revision/testing-status panel remains excluded.

## Changes

- First-visit branded splash followed by a centered native dialog with a blurred backdrop. The dialog traps keyboard focus using native modal behavior. Browser localStorage remembers the visit; refresh does not replay either introduction. Take a tour remains available explicitly. Ordinary asset-loading progress still appears as needed on subsequent visits.
- The first lesson shows both pod interiors. Both lids remain in the scene as transparent geometry; shells retain context. Temporary materials are restored when the lesson changes or closes.
- Reset clears the camera tween and OrbitControls rotation, pan and zoom momentum. The next animation frames remain at the reset pose.
- Explore parts uses Muscle pod / Brain pod selectors and scrollable component lists. There are 20 muscle and 8 brain entries, including all six linkages, base, insert, lid, electronics, headers, wiring and magnets. Small constituent geometry stays grouped with its component assembly. Existing placeholder motor geometry remains replaced by the detailed motor, as before.
- Dimensions show cell length, overall width and assembled height. Width and height attach outside the last muscle cell and move when cells are added/removed. Measurements derive from the displayed shell/lid mesh envelopes, including raised exterior details; they are not hard-coded nominal dimensions. Label collision avoidance separates nearby projected annotations.
- Hardware link gains a plain-language description and a ninth-step tour's dedicated hardware lesson (step 7). The lesson does not trigger a device chooser. Both connection labels fit without truncation. Expanded controls and encoding scroll within separate flex regions. Starting the tour closes unrelated disclosures and restores their prior open state afterward.
- A numbered readout strip shows each displayed cell's character and Braille dots. Matching numbers appear above the model. Selecting a card opens that cell's encoding. Number/capital indicators use compact glyphs with descriptive accessible labels. Hardware continues to follow cell 1, regardless of which readout is selected.
- Removed disposal of shared geometry on cell removal; remaining cells still use those resources.

## Verification

- `node tools/test_simulator_ui.mjs`: passes actual vendored OrbitControls regression for seeded rotation/pan/zoom with damping both on and off; verifies reset over 120 subsequent frames. Also verifies assembled-height measurement, dimension relocation after removing a cell, and all 28 unique catalog entries and file paths.
- JavaScript syntax checks and targeted whitespace checks pass.
- Browser: fresh local origin showed splash then centered/blurred modal. Refresh after dismissal showed neither first-visit feature. Native modal accessibility tree contained only the welcome choices.
- Browser: viewed transparent lids in the overview; inspected both component lists and an ESP32 selection; exercised the hardware lesson with prior disclosures open.
- Desktop: added up to four cells, checked length/width/height placement, selected a later cell and verified its encoding updated.
- Phone viewport 390 × 844: hardware lesson and full connection labels fit; all four character/indicator readouts remained visible, including capital and number signs.
- No application errors observed in the tested browser. Physical USB/Bluetooth connection and a real touchscreen were not tested.

## Files

`sim/3d/app.js`, `learning.js`, `learning.css`, `index.html`, `electronics.js`; `tools/test_simulator_ui.mjs`. The electronics edits name/group existing header and magnet geometry for selection; they do not change its placement. Unrelated preexisting motor GLB/exporter and hardware work remains untouched.
