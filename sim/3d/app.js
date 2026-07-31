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
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { GLTFLoader } from 'three/addons/loaders/GLTFLoader.js';

// ---------------------------------------------------------------- braille
// Grade 1, mirrors firmware/braille_mapping.py
const LETTERS = {
  a:[1], b:[1,2], c:[1,4], d:[1,4,5], e:[1,5], f:[1,2,4], g:[1,2,4,5],
  h:[1,2,5], i:[2,4], j:[2,4,5], k:[1,3], l:[1,2,3], m:[1,3,4], n:[1,3,4,5],
  o:[1,3,5], p:[1,2,3,4], q:[1,2,3,4,5], r:[1,2,3,5], s:[2,3,4], t:[2,3,4,5],
  u:[1,3,6], v:[1,2,3,6], w:[2,4,5,6], x:[1,3,4,6], y:[1,3,4,5,6], z:[1,3,5,6],
  ' ':[],
};

let P, CAM, STACK, D2B, STATES, SLICE, RAMP, PIN_LIFT, CAM_FLAT, Z_SIGN, STEPS_PER_POS;

// ---------------------------------------------------------------- cam maths
// Direct port of get_height_at_angle() in cad/scad/braille_cam.scad.
const patternBit = (state, track) => (state >> (CAM.dots - 1 - track)) & 1;
const sCurve = t => (1 - Math.cos(t * Math.PI)) / 2;

function heightFactor(aEff, track) {
  aEff = ((aEff % 360) + 360) % 360;
  const k = Math.floor(aEff / SLICE);
  const ais = aEff - k * SLICE;
  const vc = patternBit(k, track);
  const vp = patternBit((k - 1 + STATES) % STATES, track);
  const vn = patternBit((k + 1) % STATES, track);
  const hr = RAMP / 2;
  if (ais < hr)             { const b = sCurve((ais + hr) / RAMP);            return (1 - b) * vp + b * vc; }
  if (ais > SLICE - hr)     { const b = sCurve((ais - (SLICE - hr)) / RAMP);  return (1 - b) * vc + b * vn; }
  return vc;
}

// TRAP: the cam's ramps are centred on SLICE BOUNDARIES. Aiming at pos*SLICE lands
// mid-ramp and every dot sits halfway up — at state 0 all six read exactly 0.5.
// The firmware has this bug today (breadboard_test.ino targets pos*4096/64 with no
// +32). Half a slice further along is the middle of the flat dwell.
const camAngleForState = pos => Z_SIGN * (pos + 0.5) * SLICE;

// A foot fixed at world angle dot_phase sits over disc-local (phase - rotation);
// the carving already bakes in track_phase, so a_eff collapses to -rotation.
function linkageLift(dot, camDeg) {
  const track = CAM.dot_track[dot - 1];
  const aEff = (CAM.dot_phase[dot - 1] - camDeg) - CAM.track_phase[track];
  return heightFactor(aEff, track) * PIN_LIFT;
}

const cellToPos = cell => cell.reduce((v, d) => v | (1 << D2B[d]), 0);

// ---------------------------------------------------------------- scene
const XRAY_PARTS = ['outer_box', 'top_plate', 'dot_insert'];
let renderer, scene, camera, controls, parts = {}, linkages = [];
let running = true, xray = false, speed = 1;
let word = 'BRAILLE', idx = 0, camDeg = 0, targetDeg = 0, dwell = 0;
let homeCam = null, homeTarget = null;

function buildScene() {
  const stage = document.getElementById('stage');
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
  renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
  renderer.setSize(innerWidth, innerHeight);
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.05;
  stage.appendChild(renderer.domElement);

  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x12131f);
  scene.fog = new THREE.Fog(0x12131f, 260, 640);

  camera = new THREE.PerspectiveCamera(38, innerWidth / innerHeight, 1, 2000);
  camera.up.set(0, 0, 1);                    // Z-up, matching the CAD
  camera.position.set(118, -132, 104);

  controls = new OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.06;
  controls.target.set(0, 0, 30);
  controls.minDistance = 55;
  controls.maxDistance = 520;
  controls.update();
  homeCam = camera.position.clone();
  homeTarget = controls.target.clone();

  // Lighting kept deliberately modest. The Blender pass blew every surface to pure
  // white because 220W lamps sat 200mm from a 68mm object; irradiance goes as
  // P/(4*pi*r^2), so at this scale small numbers are correct.
  const key = new THREE.DirectionalLight(0xffffff, 2.1);
  key.position.set(120, -90, 190);
  key.castShadow = true;
  key.shadow.mapSize.set(2048, 2048);
  const d = 120;
  Object.assign(key.shadow.camera, { left: -d, right: d, top: d, bottom: -d, near: 20, far: 460 });
  key.shadow.bias = -0.0012;
  key.shadow.normalBias = 0.6;
  scene.add(key);

  const fill = new THREE.DirectionalLight(0x9fc4ff, 0.55);
  fill.position.set(-140, -70, 60);
  scene.add(fill);

  const rim = new THREE.DirectionalLight(0xffd9c2, 0.7);
  rim.position.set(-40, 150, 90);
  scene.add(rim);

  scene.add(new THREE.HemisphereLight(0x9aa6d0, 0x141420, 0.5));

  // catch shadows so the mechanism reads as a solid object in space
  const floor = new THREE.Mesh(
    new THREE.CircleGeometry(300, 64),
    new THREE.ShadowMaterial({ opacity: 0.42 }));
  floor.position.z = -0.4;
  floor.receiveShadow = true;
  scene.add(floor);

  const grid = new THREE.GridHelper(560, 28, 0x2b2f4d, 0x1d2036);
  grid.rotation.x = Math.PI / 2;
  grid.position.z = -0.3;
  scene.add(grid);

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
  panel(0xffffff, 2.6, [0, 0, 70], [120, 120, 1]);    // soft overhead
  panel(0x9fc4ff, 1.0, [-70, 0, 10], [1, 120, 90]);   // cool side
  panel(0xffd9c2, 0.9, [70, 0, 10], [1, 120, 90]);    // warm side
  panel(0x1a1d2e, 1.0, [0, 0, -70], [140, 140, 1]);   // dark floor bounce
  scene.environment = pmrem.fromScene(env, 0.05).texture;
  pmrem.dispose();
}

function applyMaterials(obj) {
  obj.traverse(o => {
    if (!o.isMesh) return;
    o.castShadow = true;
    o.receiveShadow = true;
    const n = o.name;
    const m = o.material;
    m.side = THREE.DoubleSide;
    if (n.startsWith('linkage_')) {
      // Shiny chrome, as requested. This only looks right BECAUSE makeEnvironment()
      // gives it something to reflect — at metalness 0.92 with no environment map
      // the dots reflected pure black plus the red cam and blue fill light, which
      // is what made them read as dark smeared beads. Do not remove the env map.
      // No state tinting: a raised dot looks exactly like a lowered one, because
      // that is what the real part does. The braille cell in the corner is where
      // you read the state.
      m.metalness = 0.92;
      m.roughness = 0.18;
      m.color.set(0xc9ced6);
      m.envMapIntensity = 1.5;
    } else if (n === 'cam') {
      m.metalness = 0.35; m.roughness = 0.34; m.color.set(0xe94560);
    } else if (n.startsWith('motor')) {
      m.metalness = 0.85; m.roughness = 0.3;
    } else if (n === 'base_plate' || n === 'mid_plate') {
      m.metalness = 0.05; m.roughness = 0.88; // matte grey
    } else if (XRAY_PARTS.includes(n)) {
      m.metalness = 0.05; m.roughness = 0.6;
      o.userData.opaque = { opacity: 1, transparent: false };
    }
    m.needsUpdate = true;
  });
}

function setXray(on) {
  xray = on;
  XRAY_PARTS.forEach(n => {
    const o = parts[n];
    if (!o) return;
    o.traverse(c => {
      if (!c.isMesh) return;
      const m = c.material;
      m.transparent = on;
      m.opacity = on ? 0.2 : 1.0;      // 20% transparent glass
      m.depthWrite = !on;
      m.roughness = on ? 0.12 : 0.6;   // polycarbonate read
      m.metalness = on ? 0.0 : 0.05;
      c.castShadow = !on;
      m.needsUpdate = true;
    });
  });
  const b = document.getElementById('btnXray');
  b.classList.toggle('on', on);
  b.textContent = on ? 'X-Ray: ON' : 'X-Ray Vision';
}

// ---------------------------------------------------------------- UI
const $ = id => document.getElementById(id);

function currentCells() {
  const w = (word || ' ').toLowerCase();
  return [...w].map(ch => ({ ch, cell: LETTERS[ch] ?? [] }));
}

function updateReadout(ch, cell, pos) {
  const glyph = $('glyph');
  const isSpace = ch === ' ';
  glyph.textContent = isSpace ? 'SPACE' : ch.toUpperCase();
  glyph.classList.toggle('space', isSpace);

  for (let d = 1; d <= 6; d++) $('d' + d).classList.toggle('up', cell.includes(d));

  $('e_char').textContent = isSpace ? '(space)' : ch.toUpperCase();
  $('e_dots').textContent = cell.length ? cell.join(' · ') : 'none';
  $('e_pos').textContent = pos + ' / 63';
  $('e_step').textContent = (pos * STEPS_PER_POS + STEPS_PER_POS / 2) + ' / 4096';
  $('e_ang').textContent = (Math.abs(camAngleForState(pos)) % 360).toFixed(2) + '°';
  $('bits').textContent = pos.toString(2).padStart(6, '0');
}

function gotoIndex(i) {
  const cells = currentCells();
  if (!cells.length) return;
  idx = ((i % cells.length) + cells.length) % cells.length;
  const { ch, cell } = cells[idx];
  const pos = cellToPos(cell);
  targetDeg = camAngleForState(pos);
  // always advance the same way a real indexing cam would, never shortest-path
  while (targetDeg > camDeg) targetDeg -= 360;
  updateReadout(ch, cell, pos);
}

function wireUI() {
  $('word').addEventListener('input', e => {
    word = e.target.value.toUpperCase() || ' ';
    idx = 0; gotoIndex(0);
  });
  $('btnXray').addEventListener('click', () => setXray(!xray));
  $('btnStep').addEventListener('click', () => { running = false; syncRun(); gotoIndex(idx + 1); });
  $('btnView').addEventListener('click', () => {
    camera.position.copy(homeCam); controls.target.copy(homeTarget); controls.update();
  });
  $('btnRun').addEventListener('click', () => { running = !running; syncRun(); });
  $('speed').addEventListener('input', e => {
    speed = parseFloat(e.target.value);
    $('speedv').textContent = speed.toFixed(1) + '×';
  });
  addEventListener('resize', () => {
    camera.aspect = innerWidth / innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(innerWidth, innerHeight);
  });
}

function syncRun() {
  const b = $('btnRun');
  b.classList.toggle('on', running);
  b.textContent = running ? 'Pause' : 'Simulate';
}

// ---------------------------------------------------------------- loop
// SINGLE place that moves anything. tick() and the debug snapshot both call this,
// so a screenshot can never show a different mechanism state than the live view.
function updateMechanism(deg) {
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

  if (running) {
    const diff = targetDeg - camDeg;
    if (Math.abs(diff) > 0.05) {
      camDeg += Math.sign(diff) * Math.min(Math.abs(diff), 150 * speed * dt);
      dwell = 0;
    } else {
      camDeg = targetDeg;
      dwell += dt;
      if (dwell > 0.85 / speed) { dwell = 0; gotoIndex(idx + 1); }
    }
  }

  updateMechanism(camDeg);

  controls.update();
  renderer.render(scene, camera);
}

// ---------------------------------------------------------------- boot
async function main() {
  const err = m => {
    $('loaderr').innerHTML = m;
    document.querySelector('.spin').style.display = 'none';
  };
  try {
    P = await (await fetch('./braillix_params.json')).json();
  } catch (e) {
    return err('Could not load <b>braillix_params.json</b>.<br>' +
      'This app must be served over http, not opened as a file.<br>' +
      'Double-click <b>run.bat</b>.');
  }
  CAM = P.cam; STACK = P.stack;
  STATES = CAM.states; SLICE = CAM.slice_angle; RAMP = CAM.ramp_angle;
  PIN_LIFT = CAM.pin_lift; CAM_FLAT = STACK.cam_flat_z;
  Z_SIGN = P.motion.blender_z_sign; STEPS_PER_POS = P.motion.steps_per_position;
  D2B = Object.fromEntries(Object.entries(P.encoding.DOT_TO_BIT).map(([k, v]) => [+k, v]));

  buildScene();

  let gltf;
  try {
    gltf = await new GLTFLoader().loadAsync('./braillix.glb');
  } catch (e) {
    return err('Could not load <b>braillix.glb</b>.<br>Rebuild it with:<br>' +
      '<code>blender --background --factory-startup --python renders/export_glb.py</code>');
  }

  scene.add(gltf.scene);
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

  wireUI();
  syncRun();
  gotoIndex(0);
  camDeg = targetDeg;          // start settled on the first letter, not mid-travel

  $('loading').classList.add('gone');

  // Verification hook. The plan requires checking that the dots raised in 3D match
  // the encoding table exactly, and that no dot ever rests at a partial height
  // (which is how a lost mid-dwell offset shows up). Cheap to keep, and it is the
  // only way to test the real scene rather than just the readout.
  window.__braillix = {
    lift: (d, deg = camDeg) => linkageLift(d, deg),
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
