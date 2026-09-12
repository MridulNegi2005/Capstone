# Simulator onboarding and parts explorer

Implemented the user-approved tour and source/download navigation. Revision and physical-validation status UI was explicitly excluded by the user and was not added. The existing GitHub Pages deployment remains unchanged; this work is local and has not been pushed.

## Experience

- Optional first-visit invitation, replay button, eight guided steps, Back/Next/Skip and Escape.
- Camera focus on controller, motor, cam and linkage; selected components are solid with a subtle amber highlight, enclosing shells stay faint, and other internal layers are hidden to avoid accumulated transparency.
- A user-triggered a/b example demonstrates dot 2 moving. Example and restoration calls do not send commands to connected hardware.
- Lessons identify text/playback, view controls, added cells, mouse/touch navigation and file downloads. Phone lessons use the upper model area and a compact reading panel.
- Eight selectable parts have descriptions and editable CAD links; five printed parts also have direct STL links. Existing model callouts now offer source links too.
- GitHub, build guide and discussion links; expandable encoding details; brighter fill lighting.
- Closing restores text, playback, electronics/X-Ray and camera state. Cells explicitly added by the visitor remain added.

## Files

- `sim/3d/learning.js`: curated parts, file links and guided-tour state.
- `sim/3d/learning.css`: desktop reading panel, phone layout and control highlights.
- `sim/3d/index.html`: accessible panels/navigation and encoding disclosure.
- `sim/3d/app.js`: scene adapter, focus material restoration and simulation-only example.

## Validation

- Node syntax checks pass for both JavaScript modules; targeted diff whitespace check passes.
- All 13 referenced CAD/STL paths exist locally.
- GitHub cam-source, raw-STL and build-guide endpoints returned HTTP 200.
- Browser exercised all eight tour steps, a/b playback, text editing, adding a cell, completion, replay, parts selection and Escape with focus returned to the parts trigger.
- Visually checked desktop and 390 × 844 phone layouts, including motor focus, linkage motion, cam inspector and input highlighting. Camera framing was adjusted after inspection.
- Returning-visitor invitation suppression and source/download link targets were checked through the rendered page. No browser application errors observed.
- Reduced-motion handling reuses the existing instant camera tween and disables new layout transitions in CSS; not separately exercised with an emulated media preference. No physical hardware or real phone touch session tested.

## Scope boundaries

No CAD, firmware, model geometry or hosting changes. Existing unrelated edits, including motor GLB/exporter modifications, were preserved. Deployment will use the existing GitHub Pages workflow when these website changes are pushed.
