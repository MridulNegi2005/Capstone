// Focused regressions for the reported UI bugs; no browser or GPU required.
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import * as THREE from '../sim/3d/vendor/three.module.min.js';
import { PARTS } from '../sim/3d/learning.js';

const app = readFileSync(new URL('../sim/3d/app.js', import.meta.url), 'utf8');
const threeURL = new URL('../sim/3d/vendor/three.module.min.js', import.meta.url).href;
const orbitSource = readFileSync(new URL('../sim/3d/vendor/controls/OrbitControls.js', import.meta.url),'utf8')
  .replace("from 'three'", `from '${threeURL}'`);
const { OrbitControls } = await import('data:text/javascript;base64,' + Buffer.from(orbitSource).toString('base64'));
const camera = new THREE.PerspectiveCamera(45,1.5,.1,2000);
camera.position.set(120,-130,105); camera.up.set(0,0,1);
const controls = new OrbitControls(camera,null);
controls.enableDamping = true; controls.target.set(0,0,30); controls.update();
const homeCam = camera.position.clone(), homeTarget = controls.target.clone();
const resetSource = app.slice(app.indexOf('function stopCameraMomentum()'), app.indexOf('function syncSpeedFill()'));
const reset = new Function('camera','controls','homeCam','homeTarget',
  `let camTween={pending:true}; ${resetSource}; return {resetView, tween:()=>camTween};`)(camera,controls,homeCam,homeTarget);
for (const damping of [true,false]) {
  controls.enableDamping = damping;
  // Seed the same pending rotation/pan/zoom state produced by pointer input.
  controls._sphericalDelta.theta = .8; controls._sphericalDelta.phi = .2;
  controls._panOffset.set(12,-4,8); controls._scale=.8;
  reset.resetView();
  for(let i=0;i<120;i++) controls.update();
  assert.ok(camera.position.distanceTo(homeCam)<1e-8,'Reset must remain at home after subsequent frames');
  assert.ok(controls.target.distanceTo(homeTarget)<1e-8,'Pan momentum must be cleared');
  assert.equal(controls.enableDamping,damping); assert.equal(reset.tween(),null);
}

const makeUnit = x => {
  const root=new THREE.Group(); root.position.x=x;
  const shell=new THREE.Mesh(new THREE.BoxGeometry(68,69.4,42.5)); shell.name='outer_box'; shell.position.z=21.25;
  const lid=new THREE.Mesh(new THREE.BoxGeometry(68,68,4)); lid.name='top_plate'; lid.position.z=44.5;
  root.add(shell,lid); return {root};
};
const units=[makeUnit(0),makeUnit(68),makeUnit(136),makeUnit(204)];
const container={replaceChildren(){},append(){}};
const doc={createElement:()=>({})};
const dimensionsSource=app.slice(app.indexOf('let dimensionLabels ='),app.indexOf('function buildHotspots'));
const dimensions=new Function('THREE','units','document','$','cssColor',
  `${dimensionsSource}; let dimGroup=buildDimension(); return ()=>{ rebuildDimensions(); return dimensionLabels; };`)(THREE,units,doc,()=>container,()=>0xf0a02a);
let labels=dimensions();
assert.equal(labels.length,3);
assert.equal(labels[2].el.textContent,'Height 46.5 mm','Height must include lid');
assert.equal(labels[1].anchor.x,256,'Width guide must be beyond the fourth cell');
units.pop(); labels=dimensions();
assert.equal(labels[1].anchor.x,188,'Width guide must follow last cell after removal');
assert.equal(labels[0].anchor.x,0,'Cell-length guide remains at first character cell');
assert.equal(new Set(PARTS.map(p=>p.id)).size,PARTS.length);
for (const part of PARTS) for (const path of [part.source,part.mesh].filter(Boolean))
  assert.ok(existsSync(fileURLToPath(new URL('../'+path,import.meta.url))),`Missing download/source: ${path}`);
console.log(`PASS: reset momentum, assembled height, last-cell dimensions, ${PARTS.length} unique parts and source/download paths.`);
