# Verified non-defects and locked decisions

This file records findings that agents raised as defects and that inspection
proved to be correct behaviour. It also records decisions that are settled.

Read this file before you "fix" anything it names. Two agents have already spent
effort on items in the first section. The geometry was correct each time.

Extracted 2026-09-05 from `cad_audit_v6_2026-06-04.md`, whose other findings are
all closed and which is therefore deleted. Line references are historical and
may have moved.

## 1. ⚠️ FALSE ALARMS — DO NOT "FIX" THESE
Two agents raised "critical bugs" that are **wrong**. Verified against source:

1. **Magnet polarity is CORRECT (not a repulsion bug).**
   - Chain always docks a `+X` face to a `−X` face: `pod+X → cell−X`, `cell+X → cell−X`, …
   - `−X` faces are **N/S/N**, `+X` faces are **S/N/S** → opposite poles meet → **ATTRACT**.
   - Verified: `outer_box.scad:14,130`, `esp32_pod_shell.scad:49`, `esp32_pod_params.scad:63`.
   - The agent error assumed `+X` meets `+X`. It never does in a daisy-chain.
   - **NOTE:** OpenSCAD models magnets as identical cylindrical pockets anyway — polarity is an
     assembly-time decision documented in comments, not geometry. Nothing to change.

2. **`linkage.scad` reference table is only a STALE COMMENT, not broken geometry.**
   - The comment table near the bottom lists `arm_span`/`asm_ang` computed with the OLD
     `inner_radius=8`. The **live code computes these from functions at render time** with the
     current `inner_radius=12.0` (`linkage.scad:55`). Geometry is correct. (Optional: refresh
     the comment for tidiness; not functional.)

---

## 2. 🔴 REAL FINDINGS (verified)
| # | File / line | Issue | Severity | Disposition |
|---|---|---|---|---|
| A1 | `linkage_comb.scad:28` | `inner_radius=8.0` vs `12.0` elsewhere → slits miss feet ~4mm | Latent-critical | Comb was **scrapped** from print pipeline → **DELETE the file** (decision). |
| A2 | `top_plate.scad:23`, `linkage.scad:58` | `col_spacing=4.8mm` vs standard braille ~2.5mm | Product-level | **CLOSED by decision** — keep jumbo (see §3). |
| A3 | `base_plate.scad` hall pocket | magnet r=17.35 vs pocket y=20 → real gap **2.65mm**; comment says 1.8mm | Medium | Fix the comment; gap validated OK on breadboard (hall saturates within a few mm). Move pocket inward only if a bench test later fails. |
| A4 | `outer_box.scad` / `esp32_pod_shell.scad` side walls | pogo windows + magnet pockets are horizontal holes → FDM sag | Medium (PETG) | **Add printed-in bridges/chamfers** (these parts are PETG). |
| A5 | `outer_box.scad` floor gutters | 4mm gutters too narrow for real Dupont/JST bundles; cable hooks undersized | Medium | Widen gutters to 6–8mm; enlarge hooks. |
| A6 | `top_plate.scad:27` | hole 2.5mm vs nub 2.2mm = 0.15mm/side | Low | **No change** — top_plate is RESIN, tolerance fine. |
| A7 | `mid_plate.scad` collar | collar ID 29.5 on 29mm motor body = 0.25mm/side | Low | Measure real motor body before final print. |

---

## 3. ✅ LOCKED DECISIONS (Mridul, 2026-06-04)
- **Braille pitch: KEEP 4.8mm "jumbo" (Option B).** No top_plate/linkage pitch redesign. Framed
  as **large-format / braille-learner** device. Spring pockets unchanged.
- **Material split:**
  - **RESIN/SLA:** `braille_cam`, `top_plate`, `nav_cap` ×3 (precision/tactile).
  - **PETG/FDM:** `outer_box`, `mid_plate`, `base_plate`, `esp32_pod_shell`, `esp32_pod_lid`,
    `pogo_end_cap` (TPU).
- **Do NOT make FDM-tolerance edits to resin parts.** (No cam-gap widening, no top-plate hole
  reaming, no FDM cam variant.) Resin handles 0.1mm gaps + 2.5mm holes fine.
- **Bridges only where PETG needs them** (A4). That's the sole manufacturability edit.
- **Patent doc DEFERRED** to the very end of the polish pass — keep raw novelty notes only (§5).

---

