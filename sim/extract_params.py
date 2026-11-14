#!/usr/bin/env python
"""
extract_params.py — pull the Braillix mechanism constants OUT of the CAD and
emit sim/braillix_params.json.

    python sim/extract_params.py

WHY THIS EXISTS
Duplicated constants drifting apart is the single biggest source of bugs in this
project (the homing magnet was declared in two files and had already drifted; the
lid boss position was hard-coded and silently desynced when the pod grew). The
simulation adds a JavaScript runtime and a Python/Blender runtime, which would
make three copies of the same numbers.

So: nothing here is typed by hand. Every value is parsed from
cad/scad/mech_layout.scad and cad/scad/braille_cam.scad. If the CAD changes,
re-run this and both the web simulation and the Blender animation follow.

The script also VERIFIES the encoding against the worked examples in
docs/SOFTWARE_TEAM_README.md before writing anything. If the CAD and the docs
ever disagree, this fails loudly instead of quietly animating the wrong thing.
"""
import json
import math
import os
import re
import sys

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MECH = os.path.join(ROOT, "cad", "scad", "mech_layout.scad")
BOX = os.path.join(ROOT, "cad", "scad", "outer_box.scad")
# The cam is a frozen resin mesh now (cad/assets/braille_cam.stl), and
# braille_cam.scad only imports it - the parametric constants that used to live
# there no longer exist anywhere in the CAD. The lift profile is ray-cast from
# that mesh by tools/sim/cam_torque.py, so it is the printed part, measured.
PROFILE = os.path.join(ROOT, "tools", "sim", "cam_profile.npy")
PROFILE_SAMPLES = 1024
# Two copies on purpose: sim/ is the canonical artefact, sim/3d/ is what the
# page actually fetches. Writing only the first left the browser reading a
# stale file — the same duplicated-constant drift this script exists to stop.
OUTS = [os.path.join(ROOT, "sim", "braillix_params.json"),
        os.path.join(ROOT, "sim", "3d", "braillix_params.json")]


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def _option_default(name):
    """Resolve a build option like `x = is_undef(x) ? 0 : x;` to its default."""
    try:
        with open(os.path.join(ROOT, "cad", "scad", "stack_options.scad"),
                  encoding="utf-8") as fh:
            opts = fh.read()
    except OSError:
        return None
    m = re.search(rf"^\s*{re.escape(name)}\s*=\s*is_undef\([^)]*\)\s*\?\s*"
                  rf"(-?[\d.]+)\s*:", opts, re.M)
    return float(m.group(1)) if m else None


def scalar(src, name, where):
    """Parse `name = <number>;`, ignoring anything inside comments.

    v8.2 made several stack values `45.0 + stack_repair_raise` — a -D build
    option. A bare-number regex silently stopped matching, which would have left
    braillix_params.json frozen at pre-repair values while the CAD moved on.
    That is precisely the drift this extractor exists to prevent, so resolve the
    option to its default instead of failing or guessing.
    """
    m = re.search(rf"^\s*{re.escape(name)}\s*=\s*(-?[\d.]+)\s*"
                  rf"(?:\+\s*([A-Za-z_]\w*)\s*)?;", src, re.M)
    if not m:
        sys.exit(f"FAIL: could not find scalar '{name}' in {where}")
    value = float(m.group(1))
    if m.group(2):
        extra = _option_default(m.group(2))
        if extra is None:
            sys.exit(f"FAIL: '{name}' depends on '{m.group(2)}', "
                     f"whose default is not declared in stack_options.scad")
        value += extra
    return value


def int_array(src, name, where):
    m = re.search(rf"^\s*{re.escape(name)}\s*=\s*\[([^\]]*)\]", src, re.M)
    if not m:
        sys.exit(f"FAIL: could not find array '{name}' in {where}")
    return [int(v) for v in re.findall(r"-?\d+", m.group(1))]


mech, box = read(MECH), read(BOX)

# --- geometry straight out of the CAD ---
col_spacing = scalar(mech, "col_spacing", MECH)
row_spacing = scalar(mech, "row_spacing", MECH)
inner_radius = scalar(mech, "inner_radius", MECH)
track_width = scalar(mech, "track_width", MECH)
track_gap = scalar(mech, "track_gap", MECH)
pin_lift = scalar(mech, "pin_lift", MECH)
cam_flat_z = scalar(mech, "cam_flat_z", MECH)
plate_under_z = scalar(mech, "plate_under_z", MECH)
plate_top_z = scalar(mech, "plate_top_z", MECH)
reading_surface_z = plate_top_z - scalar(mech, "finger_pad_depth", MECH)
link_total_h = reading_surface_z - cam_flat_z

dot_track = int_array(mech, "dot_track", MECH)
dot_phase = int_array(mech, "dot_phase", MECH)

prof = np.load(PROFILE)
dots = prof.shape[0]
states = 2 ** dots                       # every pattern six dots can make
if prof.shape[1] % PROFILE_SAMPLES:
    sys.exit(f"FAIL: profile has {prof.shape[1]} samples, not a multiple of {PROFILE_SAMPLES}")
profile = np.round(prof[:, ::prof.shape[1] // PROFILE_SAMPLES], 4)

# THE TALL BOX. mech_layout.scad still describes the 46.5mm stack - its
# stack_repair_raise option only allows 0 or 4 - while outer_box.scad is the
# 58mm box. Everything above the floor translated up together, and the top
# plate always closes the shell, so the shift is shell_height - plate_top_z.
# The finger sheet uses the same 11.5mm (`54 - plate_under_z` in make_viewer).
shell_height = scalar(box, "shell_height", BOX)
base_plate_z = scalar(box, "base_plate_z", BOX)
tall_raise = shell_height - plate_top_z
cam_flat_z += tall_raise
plate_under_z += tall_raise
plate_top_z += tall_raise
reading_surface_z += tall_raise

# --- derived ---
track_r = [inner_radius + t * (track_width + track_gap) + track_width / 2
           for t in range(dots)]


def dot_pos(d):
    """Standard braille numbering:  1 4 / 2 5 / 3 6  — mirrors mech_layout.scad"""
    x = -col_spacing / 2 if d <= 3 else col_spacing / 2
    y = row_spacing if d in (1, 4) else (0.0 if d in (2, 5) else -row_spacing)
    return [x, y]


# bit (5 - track) drives each dot; see get_pattern_bit() in braille_cam.scad
DOT_TO_BIT = {d: (dots - 1) - dot_track[d - 1] for d in range(1, 7)}

# ---------------------------------------------------------------- VERIFY
print("Verifying encoding against docs/SOFTWARE_TEAM_README.md ...")
expected = {1: 3, 2: 2, 3: 1, 4: 4, 5: 5, 6: 0}
if DOT_TO_BIT != expected:
    sys.exit(f"FAIL: DOT_TO_BIT from CAD = {DOT_TO_BIT}, docs say {expected}")
print(f"  DOT_TO_BIT {DOT_TO_BIT}  == 5 - dot_track   OK")


def cell_to_cam(cell):
    v = 0
    for d in cell:
        v |= 1 << DOT_TO_BIT[d]
    return v


for cell, want in [((), 0), ((1,), 8), ((1, 4), 24)]:
    got = cell_to_cam(cell)
    if got != want:
        sys.exit(f"FAIL: cell {cell} -> {got}, docs say {want}")
    print(f"  cell {str(cell):8} -> {got:2}   OK")

# every one of the 64 states must be reachable and unique
seen = {cell_to_cam(tuple(d for d in range(1, 7) if p >> DOT_TO_BIT[d] & 1))
        for p in range(states)}
if len(seen) != states:
    sys.exit(f"FAIL: encoding is not a bijection ({len(seen)}/{states})")
print(f"  all {states} states round-trip uniquely   OK")

# The printed cam must actually implement the encoding. At the centre of every
# state's flat dwell each track sits either fully up or fully down, and which one
# is the Gray-coded bit. Checked against the MEASURED mesh, so this is the part
# in hand, not the model of it.
def gray_bit(i, b):
    return ((i >> b) & 1) ^ ((i >> (b + 1)) & 1)


track_phase = [dot_phase[dot_track.index(t)] for t in range(dots)]
n = profile.shape[1]
bad = 0
for slc in range(states):
    centre = -(slc + 0.5) * 360.0 / states          # disc angle, blender_z_sign -1
    for d in range(1, 7):
        t = dot_track[d - 1]
        k = ((dot_phase[d - 1] - centre) % 360 + 360) % 360
        got = profile[t][int(round(k / 360 * n)) % n]
        want = pin_lift * gray_bit(slc, dots - 1 - t)
        if abs(got - want) > 0.02:
            bad += 1
if bad:
    sys.exit(f"FAIL: {bad}/{states * 6} state centres disagree with the Gray encoding")
lift_max = float(profile.max())
if abs(lift_max - pin_lift) > 0.01:
    sys.exit(f"FAIL: measured cam lift {lift_max:.3f} != pin_lift {pin_lift}")
print(f"  measured cam: all {states * 6} state centres match the Gray encoding   OK")
print(f"  measured lift {lift_max:.3f} == pin_lift {pin_lift}   OK")

steps_per_rev = 4096
params = {
    "_comment": "GENERATED by sim/extract_params.py — do not hand-edit. "
                "Re-run after any change to mech_layout.scad, outer_box.scad "
                "or tools/sim/cam_profile.npy.",
    "_source": ["cad/scad/mech_layout.scad", "cad/scad/outer_box.scad",
                "tools/sim/cam_profile.npy"],

    "cell": {"col_spacing": col_spacing, "row_spacing": row_spacing,
             "dot_pos": {str(d): dot_pos(d) for d in range(1, 7)}},

    "cam": {"states": states, "dots": dots,
            "slice_angle": 360.0 / states,
            "inner_radius": inner_radius, "track_width": track_width,
            "track_gap": track_gap, "track_r": track_r,
            "pin_lift": pin_lift,
            "dot_track": dot_track, "dot_phase": dot_phase,
            "track_phase": track_phase,
            # lift (mm) per TRACK, sampled evenly over one turn of the disc.
            # Index with (dot_phase - disc angle). Measured from the resin mesh.
            "profile": profile.tolist()},

    "stack": {"shell_height": shell_height, "tall_raise": tall_raise,
              "base_plate_z": base_plate_z,
              "cam_flat_z": cam_flat_z, "plate_under_z": plate_under_z,
              "plate_top_z": plate_top_z,
              "reading_surface_z": reading_surface_z,
              "link_total_h": link_total_h},

    "encoding": {"DOT_TO_BIT": {str(k): v for k, v in DOT_TO_BIT.items()},
                 "note": "bit = 5 - dot_track[dot-1]. Do NOT use 1 << (dot-1)."},

    "motion": {
        "steps_per_rev": steps_per_rev,
        "steps_per_position": steps_per_rev // states,
        # TRAP 1: the cam's ramps are centred on SLICE BOUNDARIES, so a target of
        # pos*64 lands mid-ramp and every dot sits halfway between state P-1 and
        # state P. At home that is all six dots at 0.4mm — half raised, unreadable.
        # Half a slice further along is the middle of the flat dwell.
        "dwell_offset_steps": steps_per_rev // states // 2,
        # TRAP 2: the repo never pins rotation direction down. The cam is carved in
        # disc-local coordinates, so to ADVANCE the state index under a fixed foot
        # the disc must turn CLOCKWISE (negative Z rotation in Blender's RH frame).
        "advance_direction": "clockwise",
        "blender_z_sign": -1,
    },
}

for _out in OUTS:
    os.makedirs(os.path.dirname(_out), exist_ok=True)
for _out in OUTS:
    with open(_out, "w", encoding="utf-8") as f:
        json.dump(params, f, indent=2)

print(f"\nstack    shell {shell_height}  raise {tall_raise}  cam_flat {cam_flat_z}  "
      f"base {base_plate_z}  plate_under {plate_under_z}")
print(f"profile  {profile.shape[0]} tracks x {profile.shape[1]} samples")
print("wrote    " + ", ".join(os.path.relpath(o, ROOT) for o in OUTS))
