# Braillix simulator: open-source visitor review

Date: 2026-09-11. Scope: explanation, interaction and open-source discoverability. Review only; no simulator, CAD or firmware changes.

## Verdict

The simulator is a useful engineering demonstrator with a distinctive dark/amber identity. Its largest opportunity is to teach the mechanism in a deliberate sequence. A visitor currently gets controls, enclosure geometry and numerical encoding before seeing why the mechanism is interesting. Keep the interactive CAD as the centrepiece, but surround it with a short guided explanation and a route to reproduce or contribute to the project.

The desired outcome: within a minute, a visitor can explain how one motor sets six dots, distinguish the brain from the character cells, and find the relevant design files. They should also understand what the simulation demonstrates and what still requires physical testing.

## Evidence and limits

- Ran the current local site using `python sim/serve.py 8777` and reviewed it in the browser. The README links a public deployment, but deployment parity was not checked.
- Observed the assembled desktop view, animation, Pause, X-Ray, Electronics, adding a second cell and About. Checked the layout at 390 × 844 and 1280 × 800.
- The model loaded and the exercised controls responded. Captured console output contained a Three.js shader precision warning and no application error. This is a targeted interaction check, not an exhaustive browser or performance audit.
- Read `sim/3d/index.html`, relevant portions of `app.js` and `electronics.js`, the generated parameters, model documentation, README and compact-candidate notes.
- No USB/Bluetooth connection, physical motion, screen-reader session, frame-rate benchmark or complete mesh/CAD parity test was performed.
- Existing unrelated working-tree changes were preserved.

## Preserve these strengths

- Actual geometric mechanism and animated dot states, rather than a decorative rotating model.
- X-Ray, electronics, dimensions and multiple cells already provide useful exploration tools.
- The encoding readout links a character to dots, cam position and motor steps.
- Keyboard shortcuts, button callouts, a live text readout and reduced-motion handling provide an accessibility foundation.
- Generated CAD parameters provide a useful basis for traceable simulation. They do not by themselves prove geometry parity or loaded physical behaviour.

## Prioritized improvements

| Priority | Improvement | Evidence and visitor benefit | Acceptance criterion |
|---|---|---|---|
| P1 | Add a guided “How it works” sequence | The initial solid enclosure hides the mechanism; About explains it in paragraphs. | A visitor can follow text → pattern → motor → cam → follower → raised dot with Next/Back and replay. |
| P1 | Add an isolated mechanism view | X-Ray leaves translucent shells and multiple grey layers overlapping. | One action hides the enclosure and isolates a selected track, follower and dot; Reset restores the assembly. |
| P1 | Fix explanatory claims and show evidence status | About says “one moving part”; the linkage callout says it “pivots”; modularity sounds complete although the electronics contains an empty expander footprint. | Public copy distinguishes one actuator from moving components, sliding linkage motion, and intended versus physically demonstrated docking. |
| P1 | Add source/build/contribute navigation | The simulator HTML has no outbound source, build-guide or contribution links. | Visitors can reach the repository and relevant CAD/firmware/build documentation without manually searching. |
| P1 | Identify the displayed revision | About displays 68 × 68 × 46.5 mm; the separate 64 mm candidate is not a production release. | A visible model revision and source manifest identify the exact displayed assembly without mixing candidate specifications. |
| P2 | Explain the brain and muscle cells | The initial scene has two boxes while the control says “1 cell.” | Labels say “1 controller + 1 character cell”; adding a cell updates the explanatory count. |
| P2 | Show the full displayed character window | With two cells, the corner still provides one character readout; source ties the primary readout to unit 0. | A strip labels the character on every displayed cell, with the inspected cell visibly selected. |
| P2 | Make phone learning easier | At 390 × 844, an open rail uses a large lower region and requires internal scrolling; mechanism details are small. | Play/Step and lesson navigation remain reachable; the selected mechanism can fill the upper viewport. |
| P2 | Add a text and static-image explanation | The educational content depends heavily on successful 3D loading and small visual details. | The core explanation and source links remain usable without WebGL, with keyboard navigation and readable text. |
| P3 | Add reproducible share links | No URL-state implementation was found in the inspected app. | A link restores example text, cell count, lesson/view and selected part; it never reconnects hardware automatically. |

## Proposed one-minute demonstration

1. **What this is.** Show controller and one character cell, with the sentence: “Braillix explores a refreshable Braille mechanism that uses one motor to set six tactile dots.” Offer “See how it works” and “Explore freely.”
2. **Choose a simple letter.** Start with lowercase `a`, then `b`. Highlight the corresponding numbered dots and explain that up/down combinations encode symbols. Keep capital and number indicators for a later example; the existing `Braille 101` default produces 13 encoded cells from 11 characters and introduces extra concepts immediately.
3. **Follow one dot.** Hide the enclosure and other five linkages. Colour the selected track and its follower consistently. Slowly rotate the cam and show a vertical movement arrow. Explain the return spring and the comb's guiding role.
4. **Show all six.** Restore six tracks and linkages; show how one angular position selects the entire pattern. Make bit ordering and Gray indexing expandable technical details.
5. **Grow the display.** Add a second character cell. Label power and communication across the dock, the local drive electronics, and any currently unimplemented components. Explain the difference between displaying two characters simultaneously and stepping through a longer message.
6. **Explore or build.** Offer source files, build documentation and a dated progress/evidence page.

Each lesson should work while paused. Camera movement should respect reduced motion, and the instruction text should be available without animation. Use a replayable tour; the existing once-per-browser About card is useful but cannot carry this entire journey.

## Mechanical views that would help most

Add named views: Assembled, Mechanism, One dot, Electronics, Dock and Exploded. Use deterministic camera positions so the important part is immediately visible. The exploded view should be labelled illustrative, because separated parts are not operating geometry.

Keep X-Ray as a supplementary inspection tool. For teaching, hiding unnecessary geometry is clearer than adding more transparent layers. Increase separation between part colours and add a small matching legend. Keep the amber accent for the active mechanical path. The paused X-Ray scene reviewed here was sufficiently dark and layered that the track-to-follower relationship required prior knowledge.

Provide an always-available parts list in addition to hover-proximity callouts. Selecting “Cam disc” should focus it, explain its purpose, and link to the exact source file and revision. Add the comb, return spring and docking interface to the mechanical learning path; the current `MECH_INFO` list covers only cam, linkage and reading surface (`app.js`, around lines 489–497).

## Copy and credibility corrections

- Replace “One moving part instead of six” (`index.html`, About) with “One motor drives a cam disc that sets all six dots through six guided linkages.”
- Replace “the arm pivots” in the linkage callout with wording that describes vertical sliding, consistent with the mechanism's guide and README explanation.
- Replace the unconditional “What you are looking at is one cell” with a dynamic description of the controller and current character-cell count.
- Explain `11 chars → 13 cells` as “13 encoded Braille symbols,” separately from the number of installed/displayed character cells. Capital and number indicators deserve a visible explanation.
- Display “Cam index 40 of 0–63” or another unambiguous label. “40 / 63” sits awkwardly beside “64 positions.” Keep raw bit-to-dot mapping in an advanced section; first show numbered dots.
- Avoid the unsupported ownership claim “almost nobody owns one” and undated market-price comparisons. Cite dated evidence if those claims are retained; this review did not independently research market prices.
- Qualify the README assertion that a motion the printed cam cannot make cannot appear in the simulator. A nominal kinematic model does not establish friction, spring force, backlash, wiring, tolerances or loaded operation.
- Show a small “Simulation / CAD revision / Physical validation” panel. The empty I/O expander footprint is already represented in `electronics.js`; make that limitation discoverable without requiring someone to inspect a hidden callout.

## Open-source handoff and maintenance

The site should answer “How can I inspect, build or help?” Add links to the repository, assembly guide, BOM, known issues and a contribution guide. A parts inspector can connect rendered parts to editable SCAD, export files and material/process notes. Do not present experimental meshes as approved print files.

No project-level LICENSE was found in the checked tree; the license files discovered were dependency/model-specific. Resolve and document project reuse terms before describing the project as ready for reuse. This review does not choose a license or assess legal compatibility. Keep asset attribution easy to find: `MODELS.md` says all electronics are procedural, whereas the current app identifies a downloaded motor model with a credit. Bring the provenance document into agreement with the current assets.

Generate a release manifest containing source revision, parameter hash and model hashes alongside the site. Validate them together in the publishing workflow so a newer parameter JSON cannot silently describe an older GLB. Do not automatically switch the website to the separate compact candidate; its README explicitly marks it unreleased.

For public load failures, provide Retry, a static mechanism illustration and source links. The current parameter/model error messages direct visitors to `run.bat` or a Blender rebuild command (`app.js`, around lines 1368–1395), which helps maintainers but does not recover an ordinary visitor's experience.

## Suggested implementation order

1. Correct copy, add revision/status and repository navigation, clarify controller/character counts.
2. Implement the guided sequence and one-dot view, reusing existing animation and camera infrastructure.
3. Add labelled multi-cell readout, parts inspector and exploded/dock views.
4. Improve phone controls and static/text fallback; test keyboard-only navigation, focus return from dialogs, screen-reader output and reduced motion.
5. Add shareable state and publishing provenance checks.

Validate the redesign with a small comprehension test: can someone unfamiliar with Braillix explain the motor-to-dot chain, identify what an added cell does, find a source file, and describe what has actually been tested? These are more useful success criteria than adding further visual effects.
