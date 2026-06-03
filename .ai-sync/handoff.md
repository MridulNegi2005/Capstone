# Active Handoff
> Last updated by: Claude Code
> Timestamp: 2026-06-04T18:30:00+05:30

## Current Task
Pre-patent CAD polish pass (v6.0). Full audit done and persisted to
`.ai-sync/artifacts/cad_audit_v6_2026-06-04.md` — **read that first.**

## Locked Decisions (do not relitigate)
- Braille pitch stays **jumbo 4.8mm** (large-format/learner framing). No pitch redesign.
- RESIN parts = `braille_cam`, `top_plate`, `nav_cap` → **do NOT make FDM-tolerance edits** to
  their geometry. PETG parts = `outer_box`, `mid_plate`, `base_plate`, `esp32_pod_shell`,
  `esp32_pod_lid`, `pogo_end_cap`.
- Patent doc DEFERRED to end of polish pass.

## ⚠️ Do NOT re-"fix" (verified false alarms)
- Magnet polarity is CORRECT (+X S/N/S ↔ −X N/S/N = attract).
- `linkage.scad` reference table is a stale comment only; geometry is correct.

## Implementation checklist (this pass) — ALL DONE ✅
- [x] Persist findings to `.ai-sync/artifacts/cad_audit_v6_2026-06-04.md` + journal
- [x] Deleted scrapped `linkage_comb.scad` + STL; noted in CHANGES.md + print_small_parts comment
- [~] Anti-reversal dock keying — added then **REVERTED** per Mridul (bump looked bad). Residual
      risk = upside-down dock reverses pogo pins → 5V on I²C → can damage ESP32. To be solved at
      the CONNECTOR level later (polarized pogo / off-center pogo so flip = open circuit). Magnets
      already catch wrong-FACE docks (repel); only upside-down is unguarded.
- [x] PETG sacrificial bridges: pogo windows (`outer_box`), USB cutout (`esp32_pod_shell`)
- [x] Widened `outer_box` floor wire gutters 4→7mm (depth 2→2.5)
- [x] Pod ⠿ tactile ID marker + jack guard ring on `esp32_pod_lid`; P/S/N braille on pod front wall
- [x] Fixed stale hall-gap comment (→2.65mm real) in `base_plate.scad` (comment only)
- [x] End-of-chain tactile ridge on `pogo_end_cap`
- [x] Re-rendered all changed PETG STLs → **all Simple: yes**; print_batch + zip rebuilt (397KB)

## Resin parts NOT touched (frozen): braille_cam, top_plate, nav_cap geometry.

## Deferred (noted, not done): patent claims doc (end of polish); optional cell-position pips;
## moving hall sensor to y=17.35 (only if a bench test shows weak homing).

## Firmware (earlier this session, on hold)
breadboard_test.ino now uses AccelStepper + WiFi web monitor + OTA, STEPS_PER_REV=4096.
OTA blocked by Windows firewall (allow Arduino IDE through firewall to use it). USB COM14 works.
Motor + hall validated on breadboard (hall saturates 0/4095 — fine for edge-midpoint homing).

## Next agent
Continue the implementation checklist above in order. Verify each changed PETG STL renders
`Simple: yes`. Resin parts frozen.
