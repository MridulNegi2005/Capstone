// =====================================================================
// Braillix mechanism simulator
//
// Loads braillix.glb (built from the real STLs by renders/export_glb.py) and
// drives it with the ACTUAL cam profile from the OpenSCAD source. Nothing here
// is hand-animated: if the printed cam could not produce a motion, this app
// cannot show it. That is the whole reason it is worth building.
//
// Units are MILLIMETRES throughout, matching braillix_params.json and the CAD.
// The GLB is exported Z-up (export_yup=False), so camera.up is set to +Z and
// every coordinate here reads the same as it does in the .scad files.
// =====================================================================
// vendor/ mirrors three/examples/jsm exactly (controls/, loaders/, utils/) so the
// addons' own relative imports — GLTFLoader does `../utils/BufferGeometryUtils.js` —
// resolve without patching a single line of vendored code.
import * as THREE from 'three';
import { initLearning, PARTS, fileLinks } from './learning.js';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';
import { buildBrainPod, buildCellElectronics, PART_INFO } from './electronics.js';
import { Cell, BleCell, supported as serialSupported, bleSupported } from './hardware.js';

// ---------------------------------------------------------------- braille
// Grade 1, mirrors firmware/braille_mapping.py
const LETTERS = {
  a:[1], b:[1,2], c:[1,4], d:[1,4,5], e:[1,5], f:[1,2,4], g:[1,2,4,5],
  h:[1,2,5], i:[2,4], j:[2,4,5], k:[1,3], l:[1,2,3], m:[1,3,4], n:[1,3,4,5],
  o:[1,3,5], p:[1,2,3,4], q:[1,2,3,4,5], r:[1,2,3,5], s:[2,3,4], t:[2,3,4,5],
  u:[1,3,6], v:[1,2,3,6], w:[2,4,5,6], x:[1,3,4,6], y:[1,3,4,5,6], z:[1,3,5,6],
  ' ':[],
};

// Indicators are CELLS IN THEIR OWN RIGHT — the mechanism displays them exactly
// like a letter, one full cam index each. "A1" is three cells, not two.
const SIGN = {
  number:  [3,4,5,6],   // digits follow, until a space or a letter sign
  capital: [6],         // the NEXT letter is upper case. Braille is lower case by default.
  letter:  [5,6],       // cancels number mode so a letter can follow a digit
};
// There is deliberately NO "lower case" sign: lower case is the default state, and a
// sign marking the absence of a change would cost a cell for nothing. Capitals are
// what need announcing — once per letter, or twice to capitalise a whole word.
// digits reuse a-j: 1->a ... 9->i, 0->j
const DIGIT = { '1':'a','2':'b','3':'c','4':'d','5':'e','6':'f','7':'g','8':'h','9':'i','0':'j' };
const PUNCT = {
  ',':[2], ';':[2,3], ':':[2,5], '.':[2,5,6], '?':[2,3,6],
  '!':[2,3,5], "'":[3], '-':[3,6],
};

let P, CAM, STACK, D2B, STATES, SLICE, PROFILE, PIN_LIFT, CAM_FLAT, Z_SIGN, STEPS_PER_POS;

// Must match use_gray_order in cad/scad/braille_cam.scad and USE_GRAY_ORDER in
// firmware/braille_cell/braille_cell.ino. All three or none.
const GRAY_ORDER = true;
const grayToBinary = g => { let b = g; while (g >>= 1) b ^= g; return b; };

// ---------------------------------------------------------------- cam maths
// Direct port of get_height_at_angle() in cad/scad/braille_cam.scad.
// v8.2: mirrors get_pattern_bit() in braille_cam.scad, which now carries the
// pattern gray(i) at slice i. This models the cam SURFACE; camAngleForState
// below does the inverse, turning a wanted pattern into the slice that holds it.
const bitOf = (v, b) => (v >> b) & 1;
const grayBit = (i, b) => bitOf(i, b) ^ bitOf(i, b + 1);
const patternBit = (slice, track) => {
  const b = CAM.dots - 1 - track;
  return GRAY_ORDER ? grayBit(slice, b) : bitOf(slice, b);
};
// TRAP: the cam's ramps are centred on SLICE BOUNDARIES. Aiming at pos*SLICE lands
// mid-ramp and every dot sits halfway up. Half a slice further along is the
// middle of the flat dwell.
// The cam carries pattern gray(i) at slice i, so a pattern's angle is the slice
// whose Gray value is that pattern - grayToBinary(pattern). Must match
// USE_GRAY_ORDER in the firmware; extract_params.py checks the printed cam.
const stateToSlice = pos => GRAY_ORDER ? grayToBinary(pos) : pos;
const camAngleForState = pos => Z_SIGN * (stateToSlice(pos) + 0.5) * SLICE;

// THE CAM IS THE PRINTED PART. The lift used to be a parametric model of the
// track carving - s-curve ramps sized per track - because the CAD described the
// cam that way. The cam is a frozen resin mesh now, and the profile in the
// params is ray-cast from it (tools/sim/cam_profile.npy), so this reads the real
// part. extract_params.py checks it against the Gray encoding at all 384 state
// centres before it will write the file, and the old model agreed with it at
// every one of them.
function linkageLift(dot, camDeg) {
  const row = PROFILE[CAM.dot_track[dot - 1]];
  const n = row.length;
  const a = (((CAM.dot_phase[dot - 1] - camDeg) % 360) + 360) % 360;
  const f = a / 360 * n;
  const i = Math.floor(f) % n;
  const t = f - Math.floor(f);
  return row[i] * (1 - t) + row[(i + 1) % n] * t;
}


const cellToPos = cell => cell.reduce((v, d) => v | (1 << D2B[d]), 0);

// ---------------------------------------------------------------- scene
const XRAY_PARTS = ['outer_box', 'top_plate', 'dot_insert', 'comb', 'finger_sheet'];
let renderer, scene, camera, controls, parts = {}, linkages = [];
let pod = null, cellElec = null, glbMotor = [], podShells = [];

// ---- MULTI-CELL ----------------------------------------------------------
// Stacking is the product's whole argument: a display is a ROW of these, each
// with its own motor, and adding one costs no extra wiring because only power
// and I2C cross the dock. So the simulator has to be able to show more than one.
//
// A unit is one physical brick. Object3D.clone() shares geometry AND materials
// by reference, which is exactly right here: X-ray and the finish palette then
// apply to every cell at once, while transforms (cam angle, linkage lift) stay
// independent, which is the only thing that must differ per cell.
const CELL_PITCH = 68;            // outer_box is 68mm; bricks butt face to face
const MAX_UNITS = 4;
let units = [];                   // [{root, elec, linkages, cam, deg, target, move}]
let selectedCell = 0;
let unitTemplate = null;          // the loaded GLB scene, cloned per unit
let running = true, xray = false, elec = false, speed = 1;
let cell = null, hwBusy = false;      // the real hardware, over Web Serial
let move = null;                      // the active trapezoid, or null when parked

// Straight from firmware/braille_cell/braille_cell.ino. The animation used to run
// at a flat 150 deg/s with no ramp, which is 1.7x the motor's top speed and gets
// short moves badly wrong: a one-state hop is only 64 steps, so it is ACCELERATION
// limited and never reaches vmax at all. Keep these in step with the sketch.
const FW = { vmax: 1000, accel: 2000, gapMs: 250 };   // half-steps/s, /s^2, ms
// The 28BYJ-48 itself stalls above ~1200 half-steps/s (see the sketch's own
// !speed warning) — the sim's speed slider goes to 3x, which is 3000. Screen
// speed and motor speed are DIFFERENT axes: the visual can run fast, the real
// coil can't, so whatever the slider asks for gets clamped before it ever
// reaches the hardware.
const HW_VMAX_CAP = 1100, HW_ACCEL_CAP = 3000;
const clampHw = (v, a) => [Math.min(v, HW_VMAX_CAP), Math.min(a, HW_ACCEL_CAP)];
const DEG_PER_STEP = 360 / 4096;
const VMAX_DEG  = FW.vmax  * DEG_PER_STEP;    // 87.9 deg/s
const ACCEL_DEG = FW.accel * DEG_PER_STEP;    // 175.8 deg/s^2

// AccelStepper's profile in closed form. Integrating it frame by frame instead
// ran 6-16% fast — worst on ONE-STATE moves, which are the common case — because
// forward Euler overshoots during the ramp and the stopping threshold clips the
// final crawl. Solving for position at time t has no such drift.
function planMove(from, to) {
  const d = Math.abs(to - from), dir = Math.sign(to - from);
  const dAcc = (VMAX_DEG * VMAX_DEG) / (2 * ACCEL_DEG);
  let tAcc, tCruise;
  if (d <= 2 * dAcc) { tAcc = Math.sqrt(d / ACCEL_DEG); tCruise = 0; }   // triangular
  else { tAcc = VMAX_DEG / ACCEL_DEG; tCruise = (d - 2 * dAcc) / VMAX_DEG; }
  return { from, dir, d, tAcc, tCruise, T: 2 * tAcc + tCruise, t: 0 };
}

function moveAt(m) {
  const { d, tAcc, tCruise, T, t } = m;
  if (t >= T) return d;
  if (t <= tAcc) return 0.5 * ACCEL_DEG * t * t;
  if (t <= tAcc + tCruise) return 0.5 * ACCEL_DEG * tAcc * tAcc + VMAX_DEG * (t - tAcc);
  const r = T - t;
  return d - 0.5 * ACCEL_DEG * r * r;
}
let word = 'Braille 101', idx = 0, camDeg = 0, targetDeg = 0, dwell = 0;
let homeCam = null, homeTarget = null;

// Read a colour straight out of the stylesheet so the palette has exactly one
// home. Color.set() treats a hex string as sRGB and converts to linear working
// space; scene.background is encoded back on output, so the canvas and the rail
// match numerically rather than approximately.
const cssColor = n => new THREE.Color(
  getComputedStyle(document.documentElement).getPropertyValue(n).trim());

// A soft occlusion blob. This is what makes an object look like it is SITTING on
// something; a cast shadow alone leaves it hovering. Canvas texture, no file.
function aoBlob() {
  const c = document.createElement('canvas');
  c.width = c.height = 256;
  const x = c.getContext('2d');
  const g = x.createRadialGradient(128, 128, 8, 128, 128, 128);
  g.addColorStop(0, 'rgba(0,0,0,.62)');
  g.addColorStop(0.45, 'rgba(0,0,0,.26)');
  g.addColorStop(1, 'rgba(0,0,0,0)');
  x.fillStyle = g;
  x.fillRect(0, 0, 256, 256);
  const m = new THREE.Mesh(
    new THREE.PlaneGeometry(185, 185),
    new THREE.MeshBasicMaterial({
      map: new THREE.CanvasTexture(c), transparent: true,
      depthWrite: false, color: 0x000000, fog: false,
    }));
  m.position.z = -0.32;
  m.renderOrder = -1;
  return m;
}

function resizeStage() {
  const st = document.getElementById('stage');
  const r = st.getBoundingClientRect();
  const w = Math.max(1, r.width), h = Math.max(1, r.height);
  camera.aspect = w / h;
  camera.updateProjectionMatrix();
  renderer.setSize(w, h);
  SB = { left: r.left, top: r.top, width: w, height: h };
  if (focusState) flyTo(focusState.root);
  else if (units.length && !camTween) frameRow();
}

function buildScene() {
  const stage = document.getElementById('stage');
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  const vp = () => {
    const r = stage.getBoundingClientRect();
    return [Math.max(1, r.width), Math.max(1, r.height)];
  };
  renderer.setSize(...vp());
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFShadowMap;   // PCFSoft is deprecated in r185
  renderer.outputColorSpace = THREE.SRGBColorSpace;   // r185 default; state it
  // AgX over ACES Filmic: ACES pushes bright neutrals toward orange, which
  // fights an amber accent and tints the white chrome highlights. AgX rolls
  // highlights off neutral and holds detail in a near-black background.
  renderer.toneMapping = THREE.AgXToneMapping;
  renderer.toneMappingExposure = 0.85;
  stage.appendChild(renderer.domElement);

  scene = new THREE.Scene();
  // ONE definition of the ground colour. This used to be 0x12131f hardcoded
  // twice here while --bg lived in the stylesheet, so a palette change had to be
  // made in two places or the canvas and the rail stopped matching.
  const BG = cssColor('--bg-0');
  scene.background = BG;
  scene.fog = new THREE.Fog(BG, 420, 1500);

  const [vw0, vh0] = vp();
  camera = new THREE.PerspectiveCamera(38, vw0 / vh0, 1, 2000);
  camera.up.set(0, 0, 1);                    // Z-up, matching the CAD
  camera.position.set(118, -132, 104);

  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.06;
  controls.target.set(0, 0, 30);
  controls.minDistance = 55;
  // 520 was fine for one brick. A row of four plus the pod needs ~900 to frame
  // in portrait, and the clamp was silently cropping the ends of the row.
  controls.maxDistance = 1400;
  controls.update();
  homeCam = camera.position.clone();
  homeTarget = controls.target.clone();

  // Lighting kept deliberately modest. The Blender pass blew every surface to pure
  // white because 220W lamps sat 200mm from a 68mm object; irradiance goes as
  // P/(4*pi*r^2), so at this scale small numbers are correct.
  const key = new THREE.DirectionalLight(0xfff6ea, 2.0);
  key.position.set(120, -90, 190);
  key.castShadow = true;
  key.shadow.mapSize.set(2048, 2048);
  const d = 85;    // the part is 68mm; a 240mm frustum spent 2/3 of the map on air
  Object.assign(key.shadow.camera, { left: -d, right: d, top: d, bottom: -d, near: 20, far: 460 });
  key.shadow.bias = -0.0012;
  key.shadow.normalBias = 0.15;   // FrontSide lets this come way down
  key.shadow.radius = 3;
  scene.add(key);

  // Near-neutral. A blue fill against an orange rim is the look of a gaming
  // keyboard, not a bench instrument, and it was tinting the white PETG.
  const fill = new THREE.DirectionalLight(0xd8dee8, 0.65);
  fill.position.set(-120, -140, 50);
  scene.add(fill);

  // Brighter and WHITE. Separating a dark object from a dark ground is the
  // single biggest thing a rim light does, and a tinted one cannot do it.
  const rim = new THREE.DirectionalLight(0xffffff, 0.9);
  rim.position.set(-30, 170, 140);
  scene.add(rim);

  scene.add(new THREE.HemisphereLight(0xc7ceda, 0x0a0b0c, 0.32));

  // catch shadows so the mechanism reads as a solid object in space
  const floor = new THREE.Mesh(
    new THREE.CircleGeometry(200, 64),
    new THREE.ShadowMaterial({ opacity: 0.55 }));
  floor.position.z = -0.4;
  floor.receiveShadow = true;
  scene.add(floor);

  // A GridHelper used to sit here. It is the single most recognisable "started
  // from a three.js example" element there is, and a wireframe floor is not what
  // a photographed object sits on. What actually sells contact is a soft
  // occlusion blob directly under the part, which costs one canvas texture.
  scene.add(aoBlob());

  makeEnvironment(renderer, scene);
}

// A tiny image-based environment. Without one, `metalness` near 1.0 reflects pure
// black plus whatever geometry happens to be nearby — which made every braille dot
// look like a dark chrome bead smeared with red (the cam) and blue (the fill light).
// Three soft emissive panels are enough to give metals something sane to reflect.
function makeEnvironment(renderer, scene) {
  const pmrem = new THREE.PMREMGenerator(renderer);
  const env = new THREE.Scene();
  const panel = (hex, gain, pos, size) => {
    const mat = new THREE.MeshBasicMaterial({ color: new THREE.Color(hex).multiplyScalar(gain) });
    const m = new THREE.Mesh(new THREE.BoxGeometry(...size), mat);
    m.position.set(...pos);
    env.add(m);
  };
  // A softbox, not three coloured slabs. The cool-left/warm-right pair was
  // tinting every neutral surface and giving the chrome a blue-orange split
  // that read as plastic.
  panel(0xffffff, 1.5, [0, 20, 80], [150, 90, 1]);    // overhead-front key
  panel(0xffffff, 0.55, [-80, 0, 20], [1, 140, 100]); // broad neutral left
  panel(0xe9edf4, 0.28, [80, 0, 20], [1, 140, 100]);  // dim neutral right
  panel(0x101113, 1.0, [0, 0, -75], [160, 160, 1]);   // floor bounce = --bg-1
  scene.environment = pmrem.fromScene(env, 0.035)   // >0.04 clips: three caps the sample count at 20.texture;
  pmrem.dispose();
}

// Every printed part gets an AUTHORED finish. Four of these meshes previously
// kept whatever colour the GLB happened to bake, so the enclosure had no design
// intent at all -- and the cam was painted 0xe94560, the literal UI accent,
// which is why the whole scene read as "one red thing on grey".
//
// The cam stays the hero by being the brightest and most specular part with the
// most geometric interest, not by being the only coloured one. Separation is by
// value and finish. A coloured hero part is the marketing move.
//
// One envMapIntensity for both subsystems: this file used 1.5 on the linkages
// while electronics.js used 0.42, a 3.5x mismatch that made the mechanism and
// the electronics look photographed in different rooms.
const ENV_INTENSITY = 1.0;

function applyMaterials(obj) {
  obj.traverse(o => {
    if (!o.isMesh) return;
    o.castShadow = true;
    o.receiveShadow = true;
    const n = o.name;
    const m = o.material;
    // FrontSide, not DoubleSide: back faces doubled fragment cost AND wrote
    // depth from the light's view, which is why the shadow bias had to be
    // dialled so hard. The CAD meshes are verified manifold.
    m.side = THREE.FrontSide;
    if (n.startsWith('linkage_')) {
      // Shiny chrome, as requested. This only looks right BECAUSE makeEnvironment()
      // gives it something to reflect — at metalness 0.92 with no environment map
      // the dots reflected pure black plus the red cam and blue fill light, which
      // is what made them read as dark smeared beads. Do not remove the env map.
      // No state tinting: a raised dot looks exactly like a lowered one, because
      // that is what the real part does. The braille cell in the corner is where
      // you read the state.
      // Brushed steel rather than mirror chrome. At 0.92/0.18 these reflected
      // only the four environment panels, so a bright streak dragged across
      // every dot as the camera moved and read as motion that was not there.
      m.metalness = 0.85;
      m.roughness = 0.26;
      m.color.set(0xd3d7dc);
      m.envMapIntensity = ENV_INTENSITY;
    } else if (n === 'cam') {
      m.metalness = 0.65; m.roughness = 0.28; m.color.set(0xb9bec4);
      m.envMapIntensity = ENV_INTENSITY;
    } else if (n.startsWith('motor')) {
      m.metalness = 0.55; m.roughness = 0.5; m.envMapIntensity = ENV_INTENSITY;
    } else if (n === 'base_plate' || n === 'mid_plate' || n === 'hall_retainer') {
      m.metalness = 0.10; m.roughness = 0.74; m.color.set(0x8e939a);
      m.envMapIntensity = ENV_INTENSITY;
    } else if (n === 'pod_shell' || n === 'pod_lid') {
      // the pod fell through every branch and kept its baked colour, which is
      // half of why the two enclosures never looked like the same product
      m.metalness = 0.0; m.roughness = 0.66; m.color.set(0x646b73);
      m.envMapIntensity = ENV_INTENSITY;
    } else if (XRAY_PARTS.includes(n)) {
      m.metalness = 0.0; m.roughness = 0.62; m.color.set(0x4a5057);
      m.envMapIntensity = ENV_INTENSITY;
      o.userData.opaque = { opacity: 1, transparent: false };
    }
    m.needsUpdate = true;
  });
}

// The pod docks on the cell's -X face: the pod's +X wall meets the cell's -X wall,
// so its centre sits a full brick away. The GLB's plain-cylinder motor is retired
// in favour of the real 28BYJ-48 shape (offset shaft, gearbox boss, connector).
// Every .glb here is a build artefact that gets regenerated whenever the CAD
// moves, and the browser will happily serve an old one for its heuristic cache
// lifetime. That is not cosmetic: a stale braillix.glb means old geometry drawn
// against freshly extracted params, which is precisely the desync this project
// keeps having. It cost a debugging session already — the page kept showing
// 400-triangle linkages after the 3228-triangle rebuild.
//
// GLTFLoader has no cache option, so fetch the bytes ourselves with
// cache: 'no-cache' (revalidate, do not refuse to store) and hand them to
// parse(). The '' path argument is fine because these files embed everything.
// Weighted so the bar is monotonic across all three assets rather than
// restarting at 0% twice.
const GLB_WEIGHT = { './braillix.glb': 0.90, './pod.glb': 0.06, './motor.glb': 0.04 };
let glbDone = 0;

function loadProgress(file, got, total) {
  const w = GLB_WEIGHT[file] ?? 0;
  const frac = total ? got / total : 0;
  const pct = Math.min(100, Math.round((glbDone + w * frac) * 100));
  const bar = $('loadbar');
  if (bar) bar.firstElementChild.style.width = pct + '%';
  const nm = $('loadname');
  if (nm) nm.textContent = file.replace('./', '');
  const pc = $('loadpct');
  if (pc) pc.textContent = pct + '%';
}

async function loadGlb(file) {
  const res = await fetch(file, { cache: 'no-cache' });
  if (!res.ok) throw new Error(`${file}: HTTP ${res.status}`);
  // Read the stream so the progress bar reports real bytes. Switching to
  // GLTFLoader.load() to get its onProgress would drop cache:'no-cache' and
  // silently bring back the stale-GLB desync described above.
  const total = +res.headers.get('content-length') || 0;
  const reader = res.body.getReader();
  const chunks = [];
  let got = 0;
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    chunks.push(value);
    got += value.length;
    loadProgress(file, got, total);
  }
  glbDone += GLB_WEIGHT[file] ?? 0;
  const buf = new Uint8Array(got);
  let off = 0;
  for (const c of chunks) { buf.set(c, off); off += c.length; }
  return new Promise((ok, no) =>
    new GLTFLoader().parse(buf.buffer, '', ok, no));
}

async function buildElectronics(glbScene) {
  const loadOptional = async (file, what) => {
    try {
      return (await loadGlb(file)).scene;
    } catch (e) {
      console.warn(`${file} missing — falling back to the built-in ${what}.`);
      return null;
    }
  };
  const printed = await loadOptional('./pod.glb', 'slab shell');
  if (printed) applyMaterials(printed);
  const realMotor = await loadOptional('./motor.glb', 'motor');

  pod = buildBrainPod(printed);
  pod.position.set(-68, 0, 0);
  podShells = ['pod_shell', 'pod_lid'].map(n => pod.getObjectByName(n)).filter(Boolean);
  scene.add(pod);

  cellElec = buildCellElectronics(realMotor);
  scene.add(cellElec);

  for (const n of ['motor_body', 'motor_shaft', 'motor_ear_l', 'motor_ear_r']) {
    const o = glbScene.getObjectByName(n);
    if (o) { o.visible = false; glbMotor.push(o); }
  }

  cellElec.visible = false;                 // the cell's innards start hidden
  pod.visible = true;                       // the pod itself never hides
  buildHotspots();
}

function setElectronics(on) {
  elec = on;
  // The pod is a brick sitting next to the cell, not something buried inside it,
  // so it stays on screen whatever this toggle says. Only the cell's own innards
  // are hidden behind it.
  units.forEach(u => { if (u.elec) u.elec.visible = on; });
  glbMotor.forEach(o => o.visible = false);       // never show the placeholder again
  $('btnElec').classList.toggle('on', on);
  $('btnElec').setAttribute('aria-pressed', String(on));
  // Deliberately does NOT force X-ray on. Two buttons reaching into each other
  // makes the state unpredictable — if you want to see through the walls, press
  // X-Ray yourself.
}

// ---------------------------------------------------------------- hotspots
// A dot pinned to each real part, instead of a wall of text on the right. It
// grows and brightens as the pointer approaches, and only opens on a click, so
// the model stays the thing you look at.
const SPOTS = [];
const MECH_INFO = [
  ['cam', 'THE CAM DISC',
   'The whole mechanism in one part. Six concentric tracks, 64 angular slices - one per possible dot pattern. Rotating it to an angle IS choosing a character. This is the resin part already printed; the motion here is measured from its mesh.'],
  ['linkage_1', 'LINKAGE (x6)',
   'One per dot. A foot rides the cam track; when it meets a raised section the guided linkage slides upward and pushes its dot up 0.5mm through the reading surface.'],
  ['finger_sheet', 'FINGER SHEET (PETG)',
   'The return spring, printed. A flat sheet under the top plate with one flexible tongue resting on each arm: the cam pushes an arm up, and its tongue pushes it back down. It replaced six coil springs that dragged on the turning cam like brake pads: they needed about 85 mN*m from a motor that gives about 30. The sheet needs about 11.'],
  ['hall_retainer', 'HALL RETAINER',
   'A small screw-on plate under the base plate that holds the Hall sensor in its pocket, facing the magnet in the cam above it.'],
  ['top_plate', 'READING SURFACE',
   'What the finger touches. Braille pitch is SQUARE - 2.6mm between rows AND between the two columns. A cell looks tall because it is 2 columns by 3 rows, not because the pitch is uneven.'],
];
const SPOT_MAX = 190;             // px: beyond this the dot is at its dimmest

// A 68mm dimension across the front of the first brick. Not LineBasicMaterial:
// `linewidth` is ignored on every platform but Firefox, so a Line renders as a
// 1px hairline at any distance and reads as a rendering bug. Thin cylinders
// scale correctly and catch the light like a drawn leader.
//
// The LABEL is an HTML element positioned by the same projection that places
// the hotspots, so it stays crisp mono text with tabular figures instead of a
// rasterised font texture that goes soft the moment you zoom.
let dimGroup = null;
let dimOn = false;                                  // OFF by default; it is a tool
let dimensionLabels = [];
function buildDimension() {
  const group = new THREE.Group(); group.renderOrder = 2;
  return group;
}
function rebuildDimensions() {
  if (!dimGroup || !units.length) return;
  for (const child of [...dimGroup.children]) {
    child.geometry.dispose(); child.material.dispose(); dimGroup.remove(child);
  }
  $('dim').replaceChildren(); dimensionLabels = [];
  units.forEach(u => u.root.updateWorldMatrix(true,true));
  const envelope = u => new THREE.Box3().setFromObject(u.root.getObjectByName('outer_box'))
    .union(new THREE.Box3().setFromObject(u.root.getObjectByName('top_plate')));
  const first = envelope(units[0]), last = envelope(units.at(-1));
  const line = (a,b) => {
    const geom = new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(...a),new THREE.Vector3(...b)]);
    dimGroup.add(new THREE.Line(geom,new THREE.LineBasicMaterial({color:cssColor('--acc'),depthTest:false})));
  };
  const measure = (a,b, label, anchor, axis) => {
    line(a,b);
    for (const p of [a,b]) {
      const q=[...p],r=[...p]; q[axis]-=2; r[axis]+=2; line(q,r);
    }
    const el=document.createElement('span'); el.className='dimension-label'; el.textContent=label; $('dim').append(el);
    dimensionLabels.push({el,anchor:new THREE.Vector3(...anchor)});
  };
  const {min:f,max:g}=first, {min:l,max:r}=last;
  measure([f.x,f.y-10,f.z],[g.x,f.y-10,f.z],`Cell length ${(g.x-f.x).toFixed(1)} mm`,[(f.x+g.x)/2,f.y-15,f.z],1);
  line([f.x,f.y,f.z],[f.x,f.y-12,f.z]); line([g.x,f.y,f.z],[g.x,f.y-12,f.z]);
  measure([r.x+12,l.y,l.z],[r.x+12,r.y,l.z],`Overall width ${(r.y-l.y).toFixed(1)} mm`,[r.x+18,(l.y+r.y)/2,l.z],0);
  line([r.x,l.y,l.z],[r.x+14,l.y,l.z]); line([r.x,r.y,l.z],[r.x+14,r.y,l.z]);
  measure([r.x+8,l.y-9,l.z],[r.x+8,l.y-9,r.z],`Height ${(r.z-l.z).toFixed(1)} mm`,[r.x+14,l.y-12,(l.z+r.z)/2],0);
  line([r.x,l.y,r.z],[r.x+10,l.y-9,r.z]);
}
function updateDimension() {
  if (!dimGroup) return;
  const on = dimOn && !focusState && !overviewMaterials.length && !document.body.classList.contains('learning');
  dimGroup.visible = on; $('dim').classList.toggle('on',on);
  if (!on) return;
  const placed = [];
  for (const {el,anchor} of dimensionLabels) {
    const v=anchor.clone().project(camera);
    el.hidden = v.z > 1 || v.z < -1;
    const x=SB.left+(v.x*.5+.5)*SB.width, y=SB.top+(-v.y*.5+.5)*SB.height;
    const w=el.offsetWidth,h=el.offsetHeight;
    const left=Math.max(SB.left+w/2+4,Math.min(SB.left+SB.width-w/2-4,x));
    let top=Math.max(SB.top+14,Math.min(SB.top+SB.height-14,y));
    for (const p of placed) if (Math.abs(left-p.x)<(w+p.w)/2+6 && Math.abs(top-p.y)<(h+p.h)/2+6)
      top=Math.max(SB.top+h/2+4,p.y-(h+p.h)/2-8);
    el.style.left=left+'px'; el.style.top=top+'px'; placed.push({x:left,y:top,w,h});
  }
}

function buildHotspots() {
  const layer = $('spots');
  for (const [name, title, body] of [...MECH_INFO, ...PART_INFO]) {
    const o = scene.getObjectByName(name);
    if (!o) continue;
    const anchor = new THREE.Box3().setFromObject(o).getCenter(new THREE.Vector3());
    const el = document.createElement('button');
    el.className = 'spot';
    el.title = title;
    el.setAttribute('aria-label', `${title} — show details`);
    el.setAttribute('aria-expanded', 'false');
    el.setAttribute('aria-controls', 'info');
    el.addEventListener('click', ev => { ev.stopPropagation(); openInfo(spot, ev); });
    layer.appendChild(el);
    const spot = { o, el, anchor, title, body };
    SPOTS.push(spot);
  }
}

let openSpot = null;
// ---------------------------------------------------------------- focus mode
// Clicking a callout isolates that part: everything else fades back and the
// camera flies to frame it. It is the difference between "here is a label on a
// dense machine" and "here is the part, on its own, at a readable size".
//
// THE TRAP IS SHARED MATERIALS. Object3D.clone() shares materials by reference
// so a second cell costs nothing, and electronics.js memoises one blackPlas for
// every black plastic part in the scene. So dimming "everything that is not
// this" by walking materials would dim the focused part too, and isolating the
// ULN2003 would leave every unrelated black component bright.
//
// So: collect the materials the focused part uses; any OTHER mesh sharing one
// gets a private clone before it is dimmed. Everything is recorded and put back
// on close, then the X-ray state is reasserted over the top, because both write
// the same opacity fields.
// Everything that is not the part gets HIDDEN, except the enclosure shells,
// which stay as a faint ghost so the part keeps its context.
//
// Dimming everything instead was the first attempt and it does not work: alpha
// accumulates, so 241 surfaces at 0.06 stacked ten deep read as solid again.
// Hiding is also cheaper and sidesteps the shared-material problem entirely --
// visibility is per mesh, not per material, and electronics.js memoises one
// blackPlas for every black part in the scene.
// Only the OUTER silhouette is ghosted, and faintly. Ghosting all four
// XRAY_PARTS buried the part: outer_box is a single mesh but a ray through it
// crosses the wall, the floor, the standoffs and the motor cup, so even 0.05
// stacks several layers deep and reads as solid dark. One shell, one layer.
const GHOST_OPACITY = 0.055;
const GHOST_NAMES = ['outer_box', 'pod_shell', 'pod_lid', 'top_plate'];
let focusState = null;
let camTween = null;
let overviewMaterials = [];

function clearOverview() {
  for (const [mesh, original] of overviewMaterials) {
    mesh.material.dispose(); mesh.material = original;
  }
  overviewMaterials = [];
  applyXray(xrayT);
}

function showOverview() {
  clearOverview(); setElectronics(true); applyXray(0);
  const shells = [...podShells, ...units.flatMap(u => u.xray)];
  for (const root of shells.filter(o => GHOST_NAMES.includes(o.name))) root.traverse(mesh => {
    if (!mesh.isMesh) return;
    const original = mesh.material; mesh.material = original.clone();
    mesh.visible = true; mesh.material.transparent = true;
    mesh.material.opacity = ['pod_lid','top_plate'].includes(root.name) ? 0.08 : 0.16;
    mesh.material.depthWrite = false; overviewMaterials.push([mesh, original]);
  });
  frameRow();
  const distance = camera.position.distanceTo(controls.target);
  startTween(controls.target.clone().addScaledVector(new THREE.Vector3(.55,-.7,.85).normalize(),distance),controls.target.clone());
}

function focusOn(o) {
  focusOff(true);
  const keep = new Set();
  o.traverse(c => { if (c.isMesh) keep.add(c); });
  const selected = [];
  for (const c of keep) {
    const original = c.material;
    const highlight = m => {
      const copy = m.clone(); copy.transparent = false; copy.opacity = 1; copy.depthWrite = true;
      if (copy.emissive) { copy.emissive.set(0xf0a02a); copy.emissiveIntensity = 0.10; }
      return copy;
    };
    c.material = Array.isArray(original) ? original.map(highlight) : highlight(original);
    selected.push({ mesh:c, original });
  }

  // one shell stays, faintly, so the part is somewhere rather than nowhere
  const ghostRoots = [];
  for (const u of units)
    for (const g of u.xray) if (GHOST_NAMES.includes(g.name)) ghostRoots.push(g);
  ghostRoots.push(...podShells.filter(o => GHOST_NAMES.includes(o.name)));
  const ghost = new Set();
  for (const g of ghostRoots)
    if (g) g.traverse(c => { if (c.isMesh && !keep.has(c)) ghost.add(c); });

  const hidden = [], mats = new Map();
  scene.traverse(c => {
    if (!c.isMesh || keep.has(c)) return;
    if (ghost.has(c)) {
      const m = c.material;
      if (!mats.has(m)) {
        mats.set(m, { transparent: m.transparent, opacity: m.opacity,
                      depthWrite: m.depthWrite });
        m.transparent = true;
        m.opacity = GHOST_OPACITY;
        m.depthWrite = false;
      }
      return;
    }
    if (c.visible) { hidden.push(c); c.visible = false; }
  });

  focusState = { hidden, mats, selected, root: o };
  flyTo(o);
}

function focusOff(silent) {
  if (!focusState) return;
  focusState.hidden.forEach(c => { c.visible = true; });
  for (const {mesh, original} of focusState.selected) {
    const copies = Array.isArray(mesh.material) ? mesh.material : [mesh.material];
    copies.forEach(m => m.dispose()); mesh.material = original;
  }
  for (const [m, v] of focusState.mats) Object.assign(m, v);
  focusState = null;
  // X-ray writes the same fields, so reassert it rather than trusting the
  // values just restored
  applyXray(xrayT);
  if (!silent) flyHome();
}

// Frame one object the way frameRow frames the whole row: bounding sphere
// against the tighter FOV axis, so it works in portrait too.
function flyTo(o) {
  const sph = new THREE.Box3().setFromObject(o).getBoundingSphere(new THREE.Sphere());
  const vFov = THREE.MathUtils.degToRad(camera.fov);
  const hFov = 2 * Math.atan(Math.tan(vFov / 2) * camera.aspect);
  const margin = matchMedia('(max-width:840px)').matches ? 1.3 : 1.7;
  const dist = Math.max(26, sph.radius / Math.sin(Math.min(vFov, hFov) / 2) * margin);
  const dir = camera.position.clone().sub(controls.target).normalize();
  // A flat part seen from a low camera is a line: the finger sheet is 58mm wide
  // and 2.8mm thick, and focusing it edge-on showed nothing at all. Keep the
  // heading but always look down on the part from at least 35 degrees.
  const minEl = Math.sin(THREE.MathUtils.degToRad(35));
  if (dir.z < minEl) {
    const k = Math.sqrt(1 - minEl * minEl) / (Math.hypot(dir.x, dir.y) || 1);
    dir.set(dir.x * k, dir.y * k, minEl);
  }
  startTween(sph.center.clone().addScaledVector(dir, dist), sph.center.clone());
}

function flyHome() { startTween(homeCam.clone(), homeTarget.clone()); }

function startTween(pos, target) {
  stopCameraMomentum();
  camTween = {
    p0: camera.position.clone(), p1: pos,
    t0: controls.target.clone(), t1: target,
    t: 0, T: 0.55,
  };
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) camTween.T = 0.001;
}

function stepTween(dt) {
  if (!camTween) return;
  camTween.t = Math.min(camTween.T, camTween.t + dt);
  const k = camTween.t / camTween.T;
  const e = k * k * (3 - 2 * k);                 // smoothstep
  camera.position.lerpVectors(camTween.p0, camTween.p1, e);
  controls.target.lerpVectors(camTween.t0, camTween.t1, e);
  if (camTween.t >= camTween.T) camTween = null;
}

function openInfo(spot, ev) {
  openSpot = spot;
  focusOn(spot.o);
  SPOTS.forEach(s => s.el.classList.toggle('open', s === spot));
  $('infoTitle').textContent = spot.title;
  $('infoBody').textContent = spot.body;
  fileLinks($('infoFiles'), PARTS.find(p => p.id === spot.o.name));
  const card = $('info');
  card.classList.add('on');
  // DOCKED, not beside the dot. Two reasons: the camera flies on open so the
  // dot it was anchored to is somewhere else a moment later, and the old clamp
  // measured against innerWidth -- which is 0 while the viewport is still
  // settling, and `innerWidth - w - 12` then goes NEGATIVE, so the clamp put
  // the card at -280,-327 and it vanished off screen entirely.
  //
  // Clamp against the CANVAS box, which is the thing it has to stay inside.
  const w = 268, h = card.offsetHeight || 160;
  const bx = SB.width > 1 ? SB : { left: 0, top: 0, width: innerWidth, height: innerHeight };
  const left = bx.left + 16;
  const top = Math.max(12, Math.min(bx.top + 16, bx.top + bx.height - h - 16));
  card.style.left = Math.max(12, Math.min(left, bx.left + bx.width - w - 16)) + 'px';
  card.style.top = top + 'px';
}
function closeInfo() {
  if (!openSpot) return;
  openSpot = null;
  SPOTS.forEach(s => s.el.classList.remove('open'));
  $('info').classList.remove('on');
  focusOff();
}

// visible only if the object and every parent above it is visible
const shown = o => { for (let n = o; n; n = n.parent) if (!n.visible) return false; return true; };

const ptr = { x: -1e4, y: -1e4 };
// cached canvas box; refreshed by resizeStage rather than measured every frame
let SB = { left: 0, top: 0, width: 1, height: 1 };

// A dot drawn over the wall that hides its own part is worse than no dot: you
// click something glowing and get a description of a thing you cannot see.
// Raycast anchor -> camera and hide the dot when anything OPAQUE is in the way.
//
// Two things make this cheap enough to keep: it runs at 8Hz rather than per
// frame, and it tests against a small list of shells rather than the ~600
// meshes in the scene. Transparency is the other half -- in X-ray the walls
// stop occluding, which is exactly what a viewer expects.
const OCCLUDE_HZ = 8;
let occludeAt = 0;
const rc = new THREE.Raycaster();
const rcDir = new THREE.Vector3();

function occluders() {
  const list = [];
  for (const u of units) list.push(...u.xray);
  return list.concat(podShells).filter(o => o && o.visible);
}

function refreshOcclusion() {
  const blockers = occluders().filter(o => {
    let solid = false;
    o.traverse(c => { if (c.isMesh && (!c.material.transparent || c.material.opacity > 0.5)) solid = true; });
    return solid;
  });
  for (const s of SPOTS) {
    if (!blockers.length) { s.hidden = false; continue; }
    rcDir.copy(s.anchor).sub(camera.position);
    const dist = rcDir.length();
    rc.set(camera.position, rcDir.normalize());
    rc.far = dist - 2.0;                    // stop short of the anchor itself
    const hit = rc.intersectObjects(blockers, true)
      .find(h => !isPartOf(h.object, s.o));
    s.hidden = !!hit;
  }
}

function isPartOf(mesh, root) {
  for (let p = mesh; p; p = p.parent) if (p === root) return true;
  return false;
}

function updateHotspots() {
  if (!SPOTS.length) return;
  const now = performance.now();
  if (now - occludeAt > 1000 / OCCLUDE_HZ) { occludeAt = now; refreshOcclusion(); }
  const v = new THREE.Vector3();
  for (const s of SPOTS) {
    if (!shown(s.o) || s.hidden || (focusState && s !== openSpot)) {
      s.el.style.display = 'none';
      s.el.setAttribute('aria-hidden', 'true');
      s.el.tabIndex = -1;
      continue;
    }
    s.el.removeAttribute('aria-hidden');
    s.el.tabIndex = 0;
    v.copy(s.anchor).project(camera);
    if (v.z > 1) { s.el.style.display = 'none'; continue; }   // behind the camera
    // The canvas is NOT the window: the rail insets it on desktop and the sheet
    // insets it on mobile. Projecting against innerWidth/innerHeight put every
    // dot at a fraction of its true offset, so they drifted off their parts and
    // pooled below the model. #spots is fixed to the window, so the canvas
    // origin has to be added back.
    const x = SB.left + (v.x * 0.5 + 0.5) * SB.width;
    const y = SB.top + (-v.y * 0.5 + 0.5) * SB.height;
    s.el.style.display = 'block';
    s.el.style.left = x + 'px';
    s.el.style.top = y + 'px';
    const d = Math.hypot(x - ptr.x, y - ptr.y);
    const p = s === openSpot ? 1 : Math.max(0, 1 - d / SPOT_MAX);
    s.el.style.setProperty('--p', (p * p).toFixed(3));        // squared: bites late, feels sharper
  }
}

// X-ray used to be a hard cut: one frame opaque, the next 20% glass, which
// reads as a glitch rather than a transition and loses the viewer's place
// inside the mechanism. It is a tween now, driven from tick().
//
// The shell has to be `transparent` for the WHOLE tween, not just at the end --
// flipping that flag mid-fade re-sorts the draw order and pops. depthWrite and
// castShadow switch once, at the point where the wall stops being solid enough
// to matter.
const XRAY_DUR = 0.34;             // seconds
let xrayT = 0;                     // 0 = solid, 1 = glass
let xrayFrom = 0, xrayTo = 0, xrayEl = XRAY_DUR;

function xrayTargets() {
  const t = [];
  for (const u of units) t.push(...u.xray);
  return t.concat(podShells);
}

function applyXray(k) {
  const ease = k * k * (3 - 2 * k);          // smoothstep
  xrayTargets().forEach(o => {
    if (!o) return;
    o.traverse(c => {
      if (!c.isMesh) return;
      const m = c.material;
      m.transparent = ease > 0.001;
      m.opacity = 1 - 0.86 * ease;           // 1.0 -> 0.14
      m.depthWrite = ease < 0.5;
      m.roughness = 0.62 - 0.55 * ease;      // matte print -> polycarbonate
      m.metalness = 0;
      m.envMapIntensity = 1 + 1.0 * ease;    // glassier as it thins
      c.castShadow = ease < 0.5;
      m.needsUpdate = true;
    });
  });
}

function stepXray(dt) {
  if (focusState || overviewMaterials.length) return;
  if (xrayEl >= XRAY_DUR) return;
  xrayEl = Math.min(XRAY_DUR, xrayEl + dt);
  xrayT = xrayFrom + (xrayTo - xrayFrom) * (xrayEl / XRAY_DUR);
  applyXray(xrayT);
}

function setXray(on) {
  xray = on;
  xrayFrom = xrayT;
  xrayTo = on ? 1 : 0;
  xrayEl = 0;
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
    xrayT = xrayTo; xrayEl = XRAY_DUR; applyXray(xrayT);
  }
  const b = document.getElementById('btnXray');
  b.classList.toggle('on', on);
  b.setAttribute('aria-pressed', String(on));
  b.textContent = on ? 'X-Ray: ON' : 'X-Ray Vision';
}

// ---------------------------------------------------------------- UI
const $ = id => document.getElementById(id);

// Expand a typed string into the cells a real display would show. Indicators cost
// a cell each, so "A1" -> capital, a, number, a  =  four cam positions.
function currentCells() {
  const out = [];
  let numeric = false;
  const push = (glyph, cell, kind, note) => out.push({ ch: glyph, cell, kind, note });
  const src = word || ' ';
  const isLetter = c => c && LETTERS[c.toLowerCase()] && c !== ' ';

  for (let i = 0; i < src.length; i++) {
    const raw = src[i];
    const ch = raw.toLowerCase();

    // ALL-CAPS run of 2+ letters: one capital WORD sign beats one sign per letter.
    // Only when the whole run is upper case, so no terminator is ever needed.
    if (isLetter(raw) && raw !== ch) {
      let j = i;
      while (j < src.length && isLetter(src[j])) j++;
      const run = src.slice(i, j);
      if (run.length > 1 && run === run.toUpperCase()) {
        if (numeric) { push('~', SIGN.letter, 'sign', 'ends the number'); numeric = false; }
        push('^^', SIGN.capital, 'sign', 'whole word is capital');
        push('^^', SIGN.capital, 'sign', 'second half of the pair');
        for (const c of run) push(c, LETTERS[c.toLowerCase()], 'letter', 'upper case');
        i = j - 1;
        continue;
      }
    }

    if (raw === ' ') {                       // space always drops numeric mode
      numeric = false;
      push(' ', [], 'space', 'word break');
    } else if (DIGIT[raw]) {
      if (!numeric) { push('#', SIGN.number, 'sign', 'digits follow'); numeric = true; }
      push(raw, LETTERS[DIGIT[raw]], 'digit', 'digit ' + raw + ' = letter ' + DIGIT[raw].toUpperCase());
    } else if (LETTERS[ch] && ch !== ' ') {
      if (numeric) { push('~', SIGN.letter, 'sign', 'ends the number'); numeric = false; }
      if (raw !== ch) push('^', SIGN.capital, 'sign', 'next letter is capital');
      push(raw, LETTERS[ch], 'letter', raw === ch ? 'lower case' : 'upper case');
    } else if (PUNCT[raw]) {
      // a . or , inside a number stays part of it (2.5, 1,000)
      if (numeric && raw !== '.' && raw !== ',') numeric = false;
      push(raw, PUNCT[raw], 'punct', 'punctuation');
    } else {
      numeric = false;
      push(raw, [], 'space', 'not in this chart');
    }
  }
  return out.length ? out : [{ ch: ' ', cell: [], kind: 'space', note: 'word break' }];
}

const KIND_LABEL = {
  sign:   { '#': 'NUMBER SIGN', '^': 'CAPITAL SIGN', '^^': 'CAPITAL WORD', '~': 'LETTER SIGN' },
  digit:  'NUMBER', letter: 'LETTER', punct: 'PUNCTUATION', space: 'SPACE',
};

function updateReadout(item, pos) {
  const { ch, cell, kind, note } = item;
  $('decode').querySelector('h2').textContent = units.length > 1 ? `Cell ${selectedCell + 1} encoding` : 'How this letter is encoded';
  const glyph = $('glyph');
  const isSign = kind === 'sign';
  const isSpace = kind === 'space';

  glyph.textContent = isSpace ? 'SPACE'
    : isSign ? { '#': '#', '^': '⇧', '^^': '⇪', '~': '↩' }[ch] : ch;
  glyph.classList.toggle('space', isSpace);
  glyph.classList.toggle('sign', isSign);

  const label = isSign ? KIND_LABEL.sign[ch] : KIND_LABEL[kind];
  $('cellmeta').textContent = label;
  $('cellmeta').classList.toggle('sign', isSign);
  $('cellnote').textContent = note || '';

  for (let d = 1; d <= 6; d++) $('d' + d).classList.toggle('up', cell.includes(d));

  $('e_char').textContent = isSpace ? '(space)' : isSign ? label.toLowerCase() : ch;
  $('e_dots').textContent = cell.length ? cell.join(' · ') : 'none';
  $('e_pos').textContent = pos + ' / 63';
  $('e_step').textContent = (stateToSlice(pos) * STEPS_PER_POS + STEPS_PER_POS / 2) + ' / 4096';
  $('e_ang').textContent = (Math.abs(camAngleForState(pos)) % 360).toFixed(2) + '°';
  $('bits').textContent = pos.toString(2).padStart(6, '0');

  // Unicode braille: U+2800 + a bitmask where dot n is bit n-1. NOTE this is
  // NOT the same bit order as D2B/DOT_TO_BIT, which is the cam's TRACK ordering.
  // They must not be merged; the cam would break silently.
  const uni = String.fromCodePoint(0x2800 + cell.reduce((v, d) => v | (1 << (d - 1)), 0));
  announce(`${isSpace ? 'space' : ch}, ${label.toLowerCase()}. ` +
           (cell.length ? `Dots ${cell.join(', ')}.` : 'No dots raised.') +
           ` Cam position ${pos} of 63. ${uni}`);
}

// The strip mirrors every physical character cell; selecting a card only inspects it.
function chooseReadout(k) {
  selectedCell=k;
  updateReadout(units[k].item, units[k].pos); updateRowReadout();
  $('encodingDetails').open = true;
  if (document.body.classList.contains('railoff')) $('railToggle').click();
  if (matchMedia('(max-width:840px)').matches) $('tabEnc').click();
}
function updateRowReadout() {
  const strip=$('rowReadout'); strip.hidden=units.length<2;
  document.body.classList.toggle('multiple-cells',units.length>1);
  // Reuse the buttons so keyboard focus survives animation updates.
  if (strip.children.length !== units.length) {
    strip.replaceChildren(); $('cellBadges').replaceChildren();
    units.forEach((u,k) => {
      const button=document.createElement('button'); button.addEventListener('click',()=>chooseReadout(k));
      const number=document.createElement('span'), glyph=document.createElement('strong'), dots=document.createElement('span');
      number.textContent=`Cell ${k+1}`; dots.className='row-dots'; button.append(number,glyph,dots); strip.append(button);
      const badge=document.createElement('span'); badge.textContent=String(k+1); $('cellBadges').append(badge);
    });
  }
  units.forEach((u,k) => {
    if (!u.item) return;
    const {ch,cell,kind}=u.item;
    const label=kind==='space'?'Space':kind==='sign'?KIND_LABEL.sign[ch]:ch;
    const button=strip.children[k];
    button.children[1].textContent=kind==='space'?'␣':kind==='sign'?({'#':'#','^':'⇧','^^':'⇪','~':'↩'}[ch]||ch):ch;
    button.title=`Inspect cell ${k+1}: ${label}`;
    button.children[2].textContent=String.fromCodePoint(0x2800+cell.reduce((v,d)=>v|(1<<(d-1)),0));
    button.setAttribute('aria-label',`Cell ${k+1}: ${label}. Dots ${cell.join(', ')||'none'}. Inspect encoding.`);
    button.setAttribute('aria-pressed',String(k===selectedCell));
  });
}
function updateCellBadges() {
  const on=units.length>1 && !focusState && !overviewMaterials.length && !document.body.classList.contains('learning');
  $('cellBadges').hidden=!on;
  if (!on) return;
  units.forEach((u,k) => {
    const el=$('cellBadges').children[k]; if (!el) return;
    const v=new THREE.Vector3(u.root.position.x,0,STACK.plate_top_z+9).project(camera);
    el.hidden=v.z>1||Math.abs(v.x)>1||Math.abs(v.y)>1;
    el.style.left=(SB.left+(v.x*.5+.5)*SB.width)+'px'; el.style.top=(SB.top+(-v.y*.5+.5)*SB.height)+'px';
    el.classList.toggle('selected',k===selectedCell);
  });
}

// One live region for the whole readout. The six dot divs are aria-hidden --
// announcing them individually is noise, and this sentence says the same thing
// better. Throttled: at the 250ms auto-advance an unthrottled region is unusable.
let annT = 0, annPending = null;
function announce(text) {
  annPending = text;
  clearTimeout(annT);
  annT = setTimeout(() => {
    const el = $('live');
    if (el && annPending) el.textContent = annPending;
  }, running ? 900 : 120);
}

function gotoIndex(i, sendHardware = true) {
  const seq = currentCells();
  if (!seq.length) return;
  idx = ((i % seq.length) + seq.length) % seq.length;

  // Unit k shows the character k places along, so a word spreads across the row
  // and then flows through it — which is the thing a photo of one cell can
  // never show and is the entire reason for the Add cell button.
  units.forEach((u, k) => {
    const item = seq[(idx + k) % seq.length];
    const pos = cellToPos(item.cell);
    // shortest path: wrap the wanted angle to the nearest equivalent of u.deg, so
    // the cam turns whichever way is closer. 63 -> 0 is 5.6deg back, not 354.4 forward.
    const want = camAngleForState(pos);
    u.target = u.deg + ((((want - u.deg) % 360) + 540) % 360) - 180;
    u.move = Math.abs(u.target - u.deg) > 1e-6 ? planMove(u.deg, u.target) : null;
    u.pos = pos;
    if (k === 0) { targetDeg = u.target; move = u.move; }
    u.item = item;
  });
  selectedCell = Math.min(selectedCell, units.length - 1);
  updateReadout(units[selectedCell].item, units[selectedCell].pos);
  updateRowReadout();

  // one real cell exists, so it follows unit 0
  if (sendHardware && cell && cell.connected) {
    hwBusy = true;
    cell.goToState(units[0].pos).finally(() => { hwBusy = false; });
  }
}

// Build one more brick. The clone shares geometry and materials with the first,
// so a second cell costs transforms and draw calls, not memory.
function addUnit() {
  if (!unitTemplate || units.length >= MAX_UNITS) return;
  const k = units.length;
  const root = k === 0 ? unitTemplate : unitTemplate.clone(true);
  root.position.x = k * CELL_PITCH;
  if (k) scene.add(root);

  const u = {
    root,
    linkages: [1, 2, 3, 4, 5, 6].map(d => root.getObjectByName('linkage_' + d)),
    cam: root.getObjectByName('cam'),
    xray: XRAY_PARTS.map(n => root.getObjectByName(n)).filter(Boolean),
    elec: null,
    deg: units.length ? units[0].deg : 0,
    target: 0, move: null, pos: 0,
  };
  if (k) {
    u.elec = cellElec.clone(true);
    u.elec.position.x = k * CELL_PITCH;
    u.elec.visible = elec;
    scene.add(u.elec);
    // the clone must match whatever X-ray state the page is already in
    root.traverse(c => { if (c.isMesh) c.castShadow = !xray; });
  } else {
    u.elec = cellElec;
  }
  units.push(u);
  syncUnitUI();
  gotoIndex(idx);
}

function removeUnit() {
  if (units.length <= 1) return;
  const u = units.pop();
  scene.remove(u.root);
  if (u.elec) scene.remove(u.elec);
  // Cloned cells share geometry with the original; keep those resources alive.
  syncUnitUI();
  gotoIndex(idx);
}

function syncUnitUI() {
  if (dimGroup) rebuildDimensions();
  const n = units.length;
  const lbl = $('unitcount');
  if (lbl) lbl.textContent = n + (n === 1 ? ' cell' : ' cells');
  const add = $('btnAddCell'), rm = $('btnDelCell');
  if (add) add.disabled = n >= MAX_UNITS;
  if (rm) rm.disabled = n <= 1;
  // Frame the whole row, not just the first brick, or adding a cell pushes it
  // off screen and looks like nothing happened.
  frameRow();
}

// Fit the camera to the ACTUAL bounds of everything on screen. A width estimate
// is not enough: the row is viewed on a diagonal, so its projected extent is not
// its length, and a phone is portrait while a row of bricks is wide. A bounding
// sphere is angle-independent, which is the only thing that survives both.
function frameRow() {
  if (!units.length) return;
  const box = new THREE.Box3();
  for (const u of units) box.expandByObject(u.root);
  if (pod) box.expandByObject(pod);
  const sph = box.getBoundingSphere(new THREE.Sphere());

  const vFov = THREE.MathUtils.degToRad(camera.fov);
  const hFov = 2 * Math.atan(Math.tan(vFov / 2) * camera.aspect);
  // fit whichever axis is tighter -- portrait makes the horizontal one bind
  const dist = sph.radius / Math.sin(Math.min(vFov, hFov) / 2);

  controls.target.copy(sph.center);
  const dir = camera.position.clone().sub(controls.target).normalize();
  if (!dir.lengthSq()) dir.set(0.62, -0.68, 0.39).normalize();
  camera.position.copy(controls.target).addScaledVector(
    dir, THREE.MathUtils.clamp(dist * 1.08, 80, 1300));
  controls.update();
  homeCam = camera.position.clone();
  homeTarget = controls.target.clone();
}


// ---------------------------------------------------------------- hardware
// The textbox already drives the animation; this makes it drive the real cell
// too. gotoIndex() sends the cam STATE and then holds the animation until the
// firmware answers, so what you watch on screen is what the motor has actually
// finished doing — not a guess running alongside it.
function wireHardware() {
  const btnUsb = $('btnHw'), btnBle = $('btnBle'), stat = $('hwstat');
  // One status line, not a scrolling log — the Arduino monitor owns the chatter.
  // But a failure has to be VISIBLE: the first version only did console.log, so a
  // busy COM port looked exactly like nothing happening.
  const say = (text, kind) => {
    stat.textContent = text;
    stat.className = text ? 'on ' + (kind || '') : '';
  };
  const line = t => console.log('[cell]', t);

  // Both transports expose the same goToState/setSpeed, so everything downstream
  // is identical whether the cell is on a cable or on its own access point.
  const onState = (usb) => (st) => {
    const on = st === 'connected';
    const btn = usb ? btnUsb : btnBle, other = usb ? btnBle : btnUsb;
    btn.textContent = on ? (usb ? 'USB: LIVE' : 'Bluetooth: LIVE')
                         : (usb ? 'Connect USB' : 'Connect Bluetooth');
    btn.classList.toggle('on', on);
    other.disabled = on;                 // one transport at a time
    if (!on) { hwBusy = false; say('disconnected'); }
  };

  async function attach(make, btn, usb) {
    if (cell && cell.connected) { await cell.disconnect(); cell = null; return; }
    btn.disabled = true;
    const was = btn.textContent;
    btn.textContent = 'Connecting…';
    say(usb ? 'waiting for the board to reset and home…'
            : 'pick Braillix-Cell in the Bluetooth chooser…');
    try {
      cell = make();
      await cell.connect();
      await cell.setSpeed(...clampHw(FW.vmax, FW.accel));
      say('live — the cam follows the text box', 'good');
      gotoIndex(idx);
    } catch (e) {
      cell = null;
      btn.textContent = was;
      btn.classList.remove('on');
      say(e.message, 'bad');
      line(e.message);
    } finally {
      btn.disabled = false;
    }
  }

  if (!serialSupported()) {
    // Android runs Chrome but has no Web Serial at all, so "needs Chrome" reads
    // as nonsense on a tablet. Name the real requirement: a desktop.
    btnUsb.textContent = 'USB: desktop only';
    btnUsb.disabled = true;
    say('USB needs a browser with Web Serial support. You can explore the simulator without connecting hardware.', 'bad');
  } else {
    // requestPort() must be reached straight from the click, not after an await
    btnUsb.addEventListener('click', () =>
      attach(() => new Cell(line, onState(true)), btnUsb, true));
  }

  if (!bleSupported()) {
    btnBle.textContent = 'Bluetooth: unsupported';
    btnBle.disabled = true;
  } else {
    btnBle.addEventListener('click', () =>
      attach(() => new BleCell(line, onState(false)), btnBle, false));
  }
}

function wireUI() {
  $('word').addEventListener('input', e => {
    word = e.target.value || ' ';   // case is meaningful now: it drives the capital sign
    idx = 0; gotoIndex(0);
    syncWordMeta();
  });
  addEventListener('pointermove', e => { ptr.x = e.clientX; ptr.y = e.clientY; });
  // click anywhere that is not a dot or the card itself
  addEventListener('pointerdown', e => {
    if (openSpot && !e.target.closest('#info') && !e.target.closest('.spot')) closeInfo();
  });
  addEventListener('keydown', e => {
    if (document.body.classList.contains('inspecting') ||
        (document.body.classList.contains('learning') && !document.body.classList.contains('lesson-controls'))) return;
    if (e.target.closest('#learningNav,.learn-card,#rowReadout')) return;
    // never steal keys from the text field, and never fight a browser shortcut
    if (e.target.matches('input,textarea,summary') ||
        e.metaKey || e.ctrlKey || e.altKey) {
      if (e.key === 'Escape') {
        if ($('help').classList.contains('on')) showHelp(false);
        else closeInfo();
      }
      return;
    }
    switch (e.key) {
      case ' ':          e.preventDefault(); running = !running; syncRun(); break;
      case 'ArrowRight': e.preventDefault(); running = false; syncRun(); gotoIndex(idx + 1); break;
      case 'ArrowLeft':  e.preventDefault(); running = false; syncRun(); gotoIndex(idx - 1); break;
      case 'x': case 'X': setXray(!xray); break;
      case 'e': case 'E': setElectronics(!elec); break;
      case 'r': case 'R': resetView(); break;
      case 'd': case 'D': setDim(!dimOn); break;
      case 'c': case 'C': $('railToggle').click(); break;
      case 'Escape':
        if ($('help').classList.contains('on')) showHelp(false);
        else closeInfo();
        break;
      case '?': showHelp(!$('help').classList.contains('on')); break;
    }
  });

  // the two panes are tabs only below 840px; above it they are both always on
  const tabs = [['tabCtl', 'paneCtl'], ['tabEnc', 'paneEnc']];
  for (const [t, pane] of tabs)
    $(t).addEventListener('click', () => {
      if (t === 'tabEnc') $('encodingDetails').open = true;
      for (const [t2, p2] of tabs) {
        const on = t2 === t;
        $(t2).setAttribute('aria-selected', String(on));
        $(p2).classList.toggle('on', on);
      }
    });
  $('info').querySelector('.x').addEventListener('click', closeInfo);

  // The "what is this" card. Shown once per visitor, then it lives behind the ?
  // so a demo is never interrupted by it. localStorage is wrapped because a
  // private window or blocked site-data makes the accessor itself throw.
  const help = $('help'), helpBtn = $('helpBtn');
  const showHelp = on => {
    help.classList.toggle('on', on);
    helpBtn.setAttribute('aria-expanded', String(on));
    if (on) help.focus();
    try { if (!on) localStorage.setItem('braillix.seen', '1'); } catch (e) { /* fine */ }
  };
  helpBtn.addEventListener('click', () => showHelp(!help.classList.contains('on')));
  help.querySelector('.x').addEventListener('click', () => showHelp(false));
  // The replayable guided tour now owns the first-visit invitation.

  $('btnDim').addEventListener('click', () => setDim(!dimOn));

  $('btnAddCell').addEventListener('click', addUnit);
  $('btnDelCell').addEventListener('click', removeUnit);

  // Collapsed by default on a phone, where 46dvh of chrome buries the model;
  // open by default on a desktop, where the rail is not in the model's way.
  const narrow = matchMedia('(max-width:840px)');
  const setRail = open => {
    document.body.classList.toggle('railoff', !open);
    const t = $('railToggle');
    t.setAttribute('aria-expanded', String(open));
    t.setAttribute('aria-label', open ? 'Hide controls' : 'Show controls');
    // the canvas box is observed, so nothing has to guess when the rail
    // transition has finished
  };
  setRail(!narrow.matches);
  $('railToggle').addEventListener('click',
    () => setRail(document.body.classList.contains('railoff')));

  $('btnXray').addEventListener('click', () => setXray(!xray));
  $('btnElec').addEventListener('click', () => setElectronics(!elec));
  wireHardware();
  $('btnStep').addEventListener('click', () => { running = false; syncRun(); gotoIndex(idx + 1); });
  $('btnView').addEventListener('click', resetView);
  $('btnRun').addEventListener('click', () => { running = !running; syncRun(); });
  $('speed').addEventListener('input', e => {
    speed = parseFloat(e.target.value);
    $('speedv').textContent = speed.toFixed(1) + '×';
    e.target.setAttribute('aria-valuetext', speed.toFixed(2) + ' times');
    syncSpeedFill();
    // The slider scales simulated TIME by k. Replaying a fixed distance k times
    // faster means velocity k and acceleration k^2, so push those to the motor or
    // the screen and the cam stop agreeing the moment the slider moves.
    if (cell && cell.connected)
      cell.setSpeed(...clampHw(Math.round(FW.vmax * speed), Math.round(FW.accel * speed * speed)));
  });
  // The stage is inset by the rail, so the window is the wrong box to measure.
  // Debounced through rAF because iOS fires resize on every URL-bar scroll pixel.
  let rz = 0;
  const onBox = () => { cancelAnimationFrame(rz); rz = requestAnimationFrame(resizeStage); };
  addEventListener('resize', onBox);
  // The rail collapsing changes the canvas box without firing `resize`, and a
  // setTimeout tuned to the CSS transition was landing a frame early -- the
  // canvas stayed 432px tall inside an 800px stage and the row sat high and
  // small. Observing the element removes the guess entirely.
  new ResizeObserver(onBox).observe(document.getElementById('stage'));
}

function syncRun() {
  const b = $('btnRun');
  b.classList.toggle('on', running);
  b.textContent = running ? 'Pause' : 'Simulate';
}

function setDim(on) {
  dimOn = on;
  const b = $('btnDim');
  b.classList.toggle('on', on);
  b.setAttribute('aria-pressed', String(on));
}

function stopCameraMomentum() {
  // A non-damped update consumes and clears the queued rotation/pan deltas.
  // Preserve the pose so draining momentum never creates a visible jump.
  const position = camera.position.clone(), target = controls.target.clone();
  const damping = controls.enableDamping;
  controls.enableDamping = false; controls.autoRotate = false; controls.update();
  camera.position.copy(position); controls.target.copy(target);
  controls.update(); controls.enableDamping = damping;
}

function resetView() {
  camTween = null;
  stopCameraMomentum();
  camera.position.copy(homeCam);
  controls.target.copy(homeTarget);
  controls.update();
}

function syncSpeedFill() {
  const el = $('speed');
  if (el) el.style.setProperty('--fill',
    (((speed - 0.25) / 2.75) * 100).toFixed(1) + '%');
}

// "11 chars -> 13 cells" under the input. Free, and it teaches the indicator-cell
// idea that currentCells() works hard to model -- capitals and digits cost a cell.
function syncWordMeta() {
  const el = $('wordmeta');
  if (!el) return;
  const n = $('word').value.length, c = currentCells().length;
  el.textContent = `${n} char${n === 1 ? '' : 's'} → ${c} cell${c === 1 ? '' : 's'}`;
}

// ---------------------------------------------------------------- loop
// SINGLE place that moves anything. tick() and the debug snapshot both call this,
// so a screenshot can never show a different mechanism state than the live view.
function updateMechanism() {
  for (const u of units) {
    if (u.cam) u.cam.rotation.z = THREE.MathUtils.degToRad(u.deg);
    u.linkages.forEach((o, i) => {
      o.position.z = CAM_FLAT + linkageLift(i + 1, u.deg);
    });
  }
}

// kept for the debug hooks, which drive a single angle by hand
function updateMechanismAt(deg) {
  if (parts.cam) parts.cam.rotation.z = THREE.MathUtils.degToRad(deg);
  // Position only. Nothing about a linkage's appearance changes with its state —
  // a raised dot looks exactly like a lowered one, just 0.8mm higher, because that
  // is what the real part does. Read the state off the braille cell in the corner.
  linkages.forEach((o, i) => {
    o.position.z = CAM_FLAT + linkageLift(i + 1, deg);
  });
}

let last = performance.now();
function tick(now) {
  requestAnimationFrame(tick);
  const dt = Math.min((now - last) / 1000, 0.05);
  last = now;

  // the cam always drives toward targetDeg, running or not — otherwise Step sets a
  // new target and nothing turns. Only the auto-advance is gated on `running`.
  // `speed` scales simulated TIME, so the profile shape stays identical to the
  // real motor's — at 1.0x the screen and the cam take the same milliseconds.
  const sdt = dt * speed;
  let busy = false;
  for (const u of units) {
    if (!u.move) { u.deg = u.target; continue; }
    u.move.t += sdt;
    u.deg = u.move.from + u.move.dir * moveAt(u.move);
    if (u.move.t >= u.move.T) { u.deg = u.target; u.move = null; }
    else busy = true;
  }
  // unit 0 is what the readout and the real hardware follow
  if (units.length) { camDeg = units[0].deg; move = units[0].move; }

  if (busy) dwell = 0;
  else if (running && !hwBusy) {
    // A real cell sets the pace: showState() blocks while the motor runs, so we
    // hold until it reports back rather than racing ahead of it.
    dwell += sdt;
    if (dwell > FW.gapMs / 1000) { dwell = 0; gotoIndex(idx + 1); }
  } else if (!running) dwell = 0;

  stepXray(dt);
  stepTween(dt);
  updateMechanism();
  updateHotspots();
  updateDimension();
  updateCellBadges();

  controls.update();
  renderer.render(scene, camera);
}

// ---------------------------------------------------------------- boot
async function main() {
  const err = m => {
    $('loaderr').innerHTML = m;
    $('loadbar').classList.add('err');
    $('loadname').textContent = 'failed';
    $('loadpct').textContent = '';
  };
  try {
    // no-cache, not no-store: the browser still keeps the file, it just has to
    // ask whether it changed. Without this a stale copy sticks around for the
    // heuristic lifetime — locally that showed the OLD ramp angles against
    // freshly rebuilt geometry, and on GitHub Pages it would outlive a deploy.
    P = await (await fetch('./braillix_params.json',
                           { cache: 'no-cache' })).json();
  } catch (e) {
    return err('Could not load <b>braillix_params.json</b>.<br>' +
      'This app must be served over http, not opened as a file.<br>' +
      'Double-click <b>run.bat</b>.');
  }
  CAM = P.cam; STACK = P.stack;
  STATES = CAM.states; SLICE = CAM.slice_angle;
  PROFILE = CAM.profile;
  PIN_LIFT = CAM.pin_lift; CAM_FLAT = STACK.cam_flat_z;
  Z_SIGN = P.motion.blender_z_sign; STEPS_PER_POS = P.motion.steps_per_position;
  D2B = Object.fromEntries(Object.entries(P.encoding.DOT_TO_BIT).map(([k, v]) => [+k, v]));

  buildScene();

  let gltf;
  try {
    gltf = await loadGlb('./braillix.glb');
  } catch (e) {
    return err('Could not load <b>braillix.glb</b>.<br>Rebuild it with:<br>' +
      '<code>blender --background --factory-startup --python renders/export_glb.py</code>');
  }

  scene.add(gltf.scene);
  unitTemplate = gltf.scene;
  gltf.scene.traverse(o => { if (o.isMesh || o.isObject3D) parts[o.name] = parts[o.name] || o; });
  applyMaterials(gltf.scene);

  linkages = [];
  for (let d = 1; d <= 6; d++) {
    const o = gltf.scene.getObjectByName('linkage_' + d);
    if (!o) return err(`GLB is missing <b>linkage_${d}</b>. Re-run renders/export_glb.py`);
    linkages.push(o);
  }
  parts.cam = gltf.scene.getObjectByName('cam');
  XRAY_PARTS.forEach(n => parts[n] = gltf.scene.getObjectByName(n));

  await buildElectronics(gltf.scene);
  addUnit();                       // unit 0 wraps the template already in the scene
  dimGroup = buildDimension();
  scene.add(dimGroup);
  rebuildDimensions();

  wireUI();
  syncRun();
  gotoIndex(0);
  camDeg = targetDeg;          // start settled on the first letter, not mid-travel

  // Respect reduced motion: do not auto-advance, and stop the camera drifting
  // after a drag. The cam's own trapezoid is content, not decoration, so Step
  // still animates -- a user who presses it is asking for exactly that.
  if (matchMedia('(prefers-reduced-motion: reduce)').matches) {
    running = false;
    controls.enableDamping = false;
  }
  syncRun();
  syncSpeedFill();
  syncWordMeta();
  initLearning({
    ready: () => { $('loading').classList.add('gone'); $('loading').setAttribute('aria-hidden','true'); },
    has: name => !!scene.getObjectByName(name),
    save: () => ({running, elec, xray, word, idx, rail: !document.body.classList.contains('railoff'),
      position: (camTween?.p1 || camera.position).clone(), target: (camTween?.t1 || controls.target).clone()}),
    pause: () => { running = false; syncRun(); },
    clear: () => { closeInfo(); focusOff(true); clearOverview(); },
    overview: showOverview,
    home: () => { camTween = null; frameRow(); },
    focus: (name, demo) => {
      setElectronics(true);
      const o = scene.getObjectByName(name);
      if (!o) return;
      focusOn(o);
      // A whole track beneath the linkage makes the motion understandable.
      if (demo && parts.cam) {
        parts.cam.traverse(c => { if (c.isMesh) c.visible = true; });
        word = 'ab'; $('word').value = word; syncWordMeta(); gotoIndex(0, false);
      }
    },
    demo: () => {
      word = 'ab'; $('word').value = word; syncWordMeta();
      running = false; syncRun(); gotoIndex(idx === 0 ? 1 : 0, false);
      return idx;
    },
    restore: state => {
      setElectronics(state.elec); setXray(state.xray);
      if (word !== state.word || idx !== state.idx) {
        word = state.word; $('word').value = word; gotoIndex(state.idx, false); syncWordMeta();
      }
      running = state.running; syncRun();
      if (document.body.classList.contains('railoff') === state.rail) $('railToggle').click();
      startTween(state.position, state.target);
    },
  });
  // Learning panels change the stage's usable rectangle without a window resize.
  new ResizeObserver(() => resizeStage()).observe($('stage'));

  // Verification hook. The plan requires checking that the dots raised in 3D match
  // the encoding table exactly, and that no dot ever rests at a partial height
  // (which is how a lost mid-dwell offset shows up). Cheap to keep, and it is the
  // only way to test the real scene rather than just the readout.
  window.__braillix = {
    scene: () => scene,
    look: (px, py, pz, tx, ty, tz) => {          // debug: park the camera precisely
      camera.position.set(px, py, pz);
      controls.target.set(tx, ty, tz);
      controls.update();
    },
    lift: (d, deg = camDeg) => linkageLift(d, deg),
    units: () => units.length,
    cam: () => camera,
    occl: () => ({
      blockers: (() => { const l=[]; for(const u of units) l.push(...u.xray);
        return l.concat(podShells).filter(o=>o&&o.visible).map(o=>o.name); })(),
      spots: SPOTS.map(s => ({ t: s.title.slice(0, 20), hidden: !!s.hidden })),
    }),
    unitState: () => units.map((u, k) => ({
      k, deg: +u.deg.toFixed(2), target: +u.target.toFixed(2),
      pos: u.pos, moving: !!u.move,
      camRot: +(u.cam.rotation.z * 180 / Math.PI).toFixed(2),
    })),
    addUnit, removeUnit,
    linkZ: () => linkages.map(o => +o.position.z.toFixed(4)),
    camDeg: () => camDeg,
    posFor: ch => cellToPos(LETTERS[ch.toLowerCase()] ?? []),
    settledLifts: ch => {
      const deg = camAngleForState(cellToPos(LETTERS[ch.toLowerCase()] ?? []));
      return [1, 2, 3, 4, 5, 6].map(d => +linkageLift(d, deg).toFixed(4));
    },
    parts: () => Object.keys(parts),
    bbox: name => {
      const o = scene.getObjectByName(name);
      if (!o) return null;
      const b = new THREE.Box3().setFromObject(o);
      return { z: [+b.min.z.toFixed(3), +b.max.z.toFixed(3)],
               x: [+b.min.x.toFixed(2), +b.max.x.toFixed(2)],
               y: [+b.min.y.toFixed(2), +b.max.y.toFixed(2)] };
    },
    mat: name => {
      const o = scene.getObjectByName(name);
      if (!o || !o.material) return null;
      const m = o.material;
      return { metalness: m.metalness, roughness: m.roughness,
               color: '#' + m.color.getHexString(), opacity: m.opacity,
               transparent: m.transparent };
    },
    // Force one frame and hand back a JPEG. requestAnimationFrame is paused when the
    // tab is not compositing, so without this there is no way to eyeball the render
    // from a headless check. preserveDrawingBuffer is off, so the capture MUST happen
    // in the same turn as the draw.
    snap: (w = 720, q = 0.55) => {
      updateMechanism(camDeg);
  updateHotspots();
      renderer.render(scene, camera);
      const src = renderer.domElement;
      const c = document.createElement('canvas');
      c.width = w; c.height = Math.round(w * src.height / src.width);
      c.getContext('2d').drawImage(src, 0, 0, c.width, c.height);
      return c.toDataURL('image/jpeg', q);
    },
    setAngleTo: ch => {
      camDeg = targetDeg = camAngleForState(cellToPos(LETTERS[ch.toLowerCase()] ?? []));
      return camDeg;
    },
  };

  requestAnimationFrame(tick);
}

main();
