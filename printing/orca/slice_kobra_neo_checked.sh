#!/usr/bin/env bash
# Generate Kobra Neo-safe PETG G-code. Output stays separate from the legacy files.
# The Kobra Neo's stock Marlin firmware has ARC_SUPPORT disabled, so this profile
# explicitly disables Orca's G2/G3 arc fitting.
set -euo pipefail

ORCA="/c/Program Files/OrcaSlicer/orca-slicer.exe"
SYS="C:/Program Files/OrcaSlicer/resources/profiles"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WREPO="$(cygpath -m "$REPO")"
MACHINE="$SYS/Anycubic/machine/Anycubic Kobra Neo 0.4 nozzle.json"
PROCESS="$WREPO/printing/orca/braillix_0.20mm_petg_kobra_neo_safe.json"
FILAMENT="$WREPO/printing/orca/numakers_petg_hs.json"
OUTDIR="$REPO/printing/gcode_kobra_neo_checked"
PARTS=(outer_box mid_plate base_plate top_plate esp32_pod_shell esp32_pod_lid)
[ $# -gt 0 ] && PARTS=("$@")

mkdir -p "$OUTDIR"
for part in "${PARTS[@]}"; do
  stl="$REPO/cad/stl/$part.stl"
  [ -f "$stl" ] || { echo "Missing: $stl" >&2; exit 1; }
  tmp=$(mktemp -d)
  "$ORCA" --load-settings "$MACHINE;$PROCESS" --load-filaments "$FILAMENT" \
    --slice 0 --outputdir "$(cygpath -w "$tmp")" "$(cygpath -w "$stl")" >/dev/null
  mv "$tmp/plate_1.gcode" "$OUTDIR/$part.gcode"
  rm -rf "$tmp"
  g="$OUTDIR/$part.gcode"
  grep -q '^; filament_type = PETG$' "$g"
  grep -q '^; first_layer_bed_temperature = 80$' "$g"
  ! grep -qE '^[Gg][23]( |$)' "$g"
  echo "OK  $part  (PETG, 80C bed, no G2/G3 arcs)"
done
