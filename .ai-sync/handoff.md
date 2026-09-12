# Active Handoff
> Last updated by: Codex
> Timestamp: 2026-09-12T22:59:31.4671700+05:30

## Current Task
Improve the Braillix CAD simulator as an open-source explanation for people who cannot see the physical hardware. The approved implementation and subsequent user-reported fixes are complete locally. User invoked sync-handoff to switch agents.

## Completed
- Optional nine-step camera-guided tour with Back/Next/Skip/replay, selected-part focus, a/b dot-2 example and hardware-link lesson.
- First-visit splash and centered native welcome dialog with background blur. localStorage key `braillix.tour.seen` prevents automatic repetition. Returning visitors use Take a tour; replay does not show the splash again.
- Both lids remain transparent in the first overview so brain and muscle interiors can be seen. Temporary materials restore on exit.
- Reset view clears camera tween and OrbitControls rotation/pan/zoom momentum.
- Explore parts has Muscle pod / Brain pod selectors and scrollable lists: 20 muscle and 8 brain components, including all six linkages. CAD links and appropriate STL links lead to existing GitHub files.
- Three-axis dimensions derive from shell/lid mesh envelopes, including raised exterior features. Width/height guides follow the final cell after additions/removals; projected label collisions are separated. Mesh-envelope dimensions can differ from nominal 68 x 68 x 46.5.
- Every displayed cell has a numbered character/dot readout and matching model badge. Selecting a card opens that cell's encoding; real hardware still follows cell 1.
- Hardware description and full-width wrapping connection buttons; hardware and encoding disclosures scroll without overlap. Tour saves/closes/restores disclosure state.
- Latest fix: `body.learning #railToggle{display:none}` in learning.css hides the stray controls handle throughout every tour step and viewport. Browser verified hidden during tour and visible after Skip.

## In Progress
No implementation intentionally left incomplete. All work remains uncommitted and unpushed; GitHub Pages has not been deployed by this session. Further user review may produce additional fixes.

## Next Steps
1. Read docs/SIMULATOR_FEEDBACK_FIXES_2026-09-12.md for implementation and validation details.
2. Continue review at http://127.0.0.1:8777/. If the server stopped, run `python sim/serve.py 8777` from the project root. Existing open tabs need a refresh to load edits.
3. Run `node tools/test_simulator_ui.mjs` when changing reset, dimensions or parts. Use browser checks for UI/layout changes.
4. If publishing is requested, stage only relevant changes after inspecting the working tree. Existing deployment is GitHub Pages via .github/workflows/deploy-sim.yml (sim/3d on main/master). Do not move hosting to Sites.

## User Decisions / Scope
- Preserve the dark/amber identity and make the mechanism understandable through camera-led onboarding.
- Source/download navigation is approved.
- User explicitly rejected the earlier proposed revision/testing-status UI (point 5). Do not reintroduce it from the old review report.
- No CAD, firmware or physical-hardware work was authorized/performed as part of these website edits. The tour's built-in example/restoration does not send commands to a connected device.

## Verification
- Node regression passed: actual vendored OrbitControls reset with momentum seeded, damping on/off and 120 subsequent updates; assembled height; last-cell dimension relocation; 28 unique component entries and all source/download paths.
- JS syntax and targeted whitespace checks passed.
- Browser tested fresh/returning visitor behavior, modal blur/focus, transparent overview, pod lists, hardware lesson and disclosures, multi-cell readouts and selected encoding.
- Desktop and 390 x 844 phone viewport inspected; number/capital indicators fit in four-cell readouts. No application errors observed.
- Actual USB/Bluetooth connection, real touchscreen and full screen-reader audit were not performed. Reduced-motion branches were source-reviewed, not separately emulated.

## Key Files Modified
- sim/3d/app.js
- sim/3d/index.html
- sim/3d/learning.js (new)
- sim/3d/learning.css (new)
- sim/3d/electronics.js (names/groups existing header/magnet meshes for selection; no placement changes)
- tools/test_simulator_ui.mjs (new)
- docs/SIMULATOR_OPEN_SOURCE_REVIEW_2026-09-11.md
- docs/SIMULATOR_ONBOARDING_IMPLEMENTATION_2026-09-11.md
- docs/SIMULATOR_FEEDBACK_FIXES_2026-09-12.md
- Corresponding .ai-sync/artifacts copies, context.md and handoff.md

## Preserve Unrelated Work
The working tree already contained changes to docs/Braillix_Cost_Analysis.docx, renders/export_motor_glb.py, sim/3d/motor.glb, compact CAD candidate/tools and other hardware/audit documents. These were not created by this simulator UI implementation; do not accidentally revert or bundle them into a website commit. Original production CAD/G-code remains separate from the unreleased compact candidate.

Older handoff contents were archived to .ai-sync/artifacts/handoff_before_simulator_session_close.md before this concise replacement. Full rolling history remains in .ai-sync/context.md.
