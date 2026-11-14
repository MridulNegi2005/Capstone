// Public learning layer. The scene adapter keeps camera/material ownership in app.js.
const REPO = 'https://github.com/MridulNegi2005/Capstone';
const cad = (id, title, text, file, mesh = file, pod = 'muscle') => ({id, title, text, pod,
  source: `cad/scad/${file}.scad`, ...(mesh ? {mesh:`cad/stl/${mesh}.stl`} : {})});
export const PARTS = [
  cad('outer_box','Enclosure','The shell holds the character cell and its docking interfaces.','outer_box'),
  cad('top_plate','Top plate / lid','The top plate surrounds the recessed six-dot reading surface.','top_plate'),
  cad('dot_insert','Reading insert','The insert guides the six tactile dots at the reading surface.','dot_insert'),
  cad('base_plate','Base plate','Supports the mechanism above the motor and locates the Hall sensor.','base_plate'),
  cad('cam','Cam disc','Six tracks select the six-dot pattern at each of 64 angular positions.','braille_cam'),
  cad('comb','Linkage guide','The comb keeps the followers aligned while allowing vertical motion.','linkage_comb'),
  ...Array.from({length:6}, (_,i) => cad(`linkage_${i+1}`,`Dot ${i+1} arm`,'A foot follows its cam track; the guided arm slides vertically to raise and lower this dot.',`arm_${i+1}`)),
  cad('finger_sheet','Finger sheet','A printed PETG sheet under the top plate. One flexible tongue presses on each arm and returns its dot down. It replaces six coil springs.','finger_sheet'),
  cad('hall_retainer','Hall sensor retainer','Two screws hold this plate under the base plate. It keeps the Hall sensor in its pocket.','hall_retainer'),
  cad('stepper','Stepper motor','One motor rotates the cam to choose the complete dot pattern.','motor_spec',null),
  cad('uln2003','Motor driver and carrier','The socketed ULN2003AN switches current to the motor coils. Its carrier sits beside the motor.','electronics_spec',null),
  cad('hall','Hall sensor','The sensor detects the cam magnet to establish a reference position.','hall_interface',null),
  cad('mcp23017','I/O expander','The MCP23017 board changes the two-wire bus from the dock into the four motor coil signals. It also reads the Hall sensor.','electronics_envelopes',null),
  cad('pogo_pads','Input dock connector','Flat contacts receive power and communication from the preceding box.','dock_interface',null),
  cad('pogo_out','Output dock connector','Spring contacts connect this cell to the next one in the row.','dock_interface',null),
  cad('cell_magnets','Dock magnets','Two magnets beside the connector help retain the docked joint.','dock_interface',null),
  {id:'cell_wiring',title:'Cell wiring',text:'The wiring connects the dock interface, driver, motor and Hall sensor.',pod:'muscle',source:'sim/3d/electronics.js'},
  cad('pod_shell','Enclosure','The brain pod houses the controller and power input.','esp32_pod_shell','esp32_pod_shell','brain'),
  cad('pod_lid','Top lid','The removable lid closes the controller pod.','esp32_pod_lid','esp32_pod_lid','brain'),
  cad('esp32','ESP32 controller','The controller translates text into commands for the Braille mechanism.','esp32_pod_params',null,'brain'),
  cad('pod_headers','Controller headers','Two socket strips support the removable controller board.','esp32_pod_params',null,'brain'),
  cad('dc_jack','Power inlet','The barrel jack brings power into the controller pod.','esp32_pod_params',null,'brain'),
  cad('pogo_pins','Dock connector','This connector meets the first muscle pod.','dock_interface',null,'brain'),
  cad('pod_magnets','Dock magnets','Magnets help hold the controller and first muscle pod together.','dock_interface',null,'brain'),
  {id:'pod_wiring',title:'Controller wiring',text:'The wiring connects the controller, power inlet and dock.',pod:'brain',source:'sim/3d/electronics.js'},
];

export function fileLinks(container, part) {
  container.replaceChildren();
  const add = (label, href) => {
    const a = document.createElement('a'); a.textContent = label;
    a.href = href; a.target = '_blank'; a.rel = 'noopener noreferrer'; container.append(a);
  };
  if (part?.source) add('View editable CAD', `${REPO}/blob/main/${part.source}`);
  if (part?.mesh) add('Download STL', `${REPO}/raw/refs/heads/main/${part.mesh}`);
  if (!part?.source) add('Browse source files', `${REPO}/tree/main/cad`);
}

const LESSONS = [
  {title:'Two boxes, different jobs', text:'The controller pod is on the left. Each character cell beside it uses six tactile dots to display one Braille symbol. Let’s look inside.', overview:true},
  {title:'One motor turns the disc', text:'The stepper motor sits under the mechanism. Its output shaft turns the shaped disc above it to choose a dot pattern.', part:'stepper'},
  {title:'Six tracks choose six dots', text:'Every track has high and low sections. Rotating the disc changes which followers stand high. Together, the six tracks select a complete Braille pattern.', part:'cam'},
  {title:'Follow one dot', text:'This linkage slides up and down as its foot follows a track. Change between a and b to see dot 2 move. The other dots keep their pattern.', part:'linkage_2', demo:true},
  {title:'Try your own text', text:'Enter text here. Simulate plays through it; Step advances one encoded symbol. Capitals and numbers can add Braille indicator symbols.', target:'word', control:true},
  {title:'Look inside, or add a cell', text:'X-Ray fades the enclosure. Electronics reveals the boards and motor. Dimensions adds a size guide. Use + under Cells to extend the displayed row.', target:'btnXray', control:true},
  {title:'Connect real hardware, if you have it', text:'Hardware link is optional. USB or Bluetooth asks you to choose a physical cell running the matching firmware. Once connected, cell 1 follows your text and playback. You can use the whole simulator without connecting anything.', target:'hwdisc', control:true, hardware:true},
  {title:'Make the view yours', text:'Drag to rotate, scroll to zoom, and right-drag to pan. On a touchscreen, drag with one finger to rotate; use two fingers to zoom or pan. Reset view brings the whole assembly back.', target:'btnView', control:true},
  {title:'Explore a part. Make it your own.', text:'Open Explore parts to focus any component. View editable CAD opens its OpenSCAD source on GitHub; Download STL saves its printable mesh. The build guide explains assembly.', target:'exploreParts'},
];

export function initLearning(api) {
  const $ = id => document.getElementById(id);
  let step = -1, saved = null, returnFocus = null, highlighted = null, activePod = 'muscle', disclosures = null;
  const panel = $('learnPanel'), welcome = $('learnWelcome'), inspector = $('partsPanel');
  const closeWelcome = () => { if (welcome.open) welcome.close(); welcome.hidden = true; };
  const closeDisclosures = () => { $('hwdisc').open = false; $('encodingDetails').open = false; };
  const clearHighlight = () => { highlighted?.classList.remove('lesson-target'); highlighted = null; };
  const showControls = on => {
    if (document.body.classList.contains('railoff') === on) $('railToggle').click();
    if (on) $('tabCtl').click();
  };
  function end() {
    clearHighlight(); panel.hidden = true; closeWelcome();
    if (disclosures) { $('hwdisc').open = disclosures.hardware; $('encodingDetails').open = disclosures.encoding; disclosures = null; }
    document.body.classList.remove('learning','lesson-controls'); $('rail').inert = false; step = -1;
    api.clear();
    if (saved) { api.restore(saved); saved = null; }
    try { localStorage.setItem('braillix.tour.seen', '1'); } catch { /* optional */ }
    returnFocus?.focus();
  }
  function render() {
    clearHighlight(); api.clear(); closeDisclosures();
    const lesson = LESSONS[step];
    $('learnProgress').textContent = `${step + 1} / ${LESSONS.length}`;
    $('learnTitle').textContent = lesson.title; $('learnText').textContent = lesson.text;
    $('learnBack').disabled = step === 0;
    $('learnNext').textContent = step === LESSONS.length - 1 ? 'Finish tour' : 'Next';
    $('learnDemo').hidden = !lesson.demo;
    $('learnDemo').textContent = 'Watch a → b';
    if (lesson.overview) api.overview();
    else if (lesson.part) api.focus(lesson.part, lesson.demo);
    else api.home();
    // On phones the card replaces the rail during part lessons. Control lessons
    // keep the existing rail available; a compact card sits above the model.
    document.body.classList.toggle('lesson-controls', !!lesson.control);
    $('rail').inert = !lesson.control;
    if (matchMedia('(max-width:840px)').matches) showControls(!!lesson.control);
    else if (lesson.control) showControls(true);
    if (lesson.hardware) $('hwdisc').open = true;
    if (lesson.target) {
      highlighted = $(lesson.target); highlighted.classList.add('lesson-target');
      highlighted.scrollIntoView({block:'nearest'});
    }
    $('learnTitle').focus({preventScroll:true});
  }
  function start() {
    if (step >= 0) return;
    returnFocus = document.activeElement; closeParts();
    saved = api.save(); api.pause(); closeWelcome();
    disclosures = {hardware:$('hwdisc').open, encoding:$('encodingDetails').open}; closeDisclosures();
    document.body.classList.add('learning'); panel.hidden = false; step = 0; render();
  }
  function closeParts() {
    if (inspector.hidden) return;
    inspector.hidden = true; $('exploreParts').setAttribute('aria-expanded','false');
    api.clear(); if (saved) { api.restore(saved); saved = null; }
    document.body.classList.remove('inspecting');
    $('rail').inert = false;
  }
  function selectPart(part) {
    api.clear(); api.focus(part.id);
    $('partTitle').textContent = part.title; $('partText').textContent = part.text;
    fileLinks($('partFiles'), part);
    for (const b of $('partList').querySelectorAll('button')) b.setAttribute('aria-pressed', String(b.dataset.part === part.id));
  }
  function renderParts() {
    $('partList').replaceChildren();
    const list = PARTS.filter(p => p.pod === activePod && api.has(p.id));
    for (const part of list) {
      const li = document.createElement('li'), b = document.createElement('button');
      b.textContent = part.title; b.dataset.part = part.id; b.setAttribute('aria-pressed','false');
      b.addEventListener('click', () => selectPart(part)); li.append(b); $('partList').append(li);
    }
    for (const b of $('partPod').querySelectorAll('button')) b.setAttribute('aria-pressed', String(b.dataset.pod === activePod));
    if (list.length) selectPart(list[0]);
  }
  for (const b of $('partPod').querySelectorAll('button')) b.addEventListener('click', () => { activePod = b.dataset.pod; renderParts(); });
  $('exploreParts').addEventListener('click', () => {
    if (!inspector.hidden) { closeParts(); return; }
    if (step >= 0) end(); closeWelcome();
    saved = api.save(); api.pause(); inspector.hidden = false;
    document.body.classList.add('inspecting');
    $('rail').inert = true;
    $('exploreParts').setAttribute('aria-expanded','true');
    renderParts(); $('partsTitle').focus({preventScroll:true});
  });
  $('partsClose').addEventListener('click', () => { closeParts(); $('exploreParts').focus(); });
  $('startTour').addEventListener('click', start); $('replayTour').addEventListener('click', start);
  $('skipWelcome').addEventListener('click', () => { returnFocus = $('replayTour'); end(); });
  $('learnSkip').addEventListener('click', end);
  $('learnBack').addEventListener('click', () => { if (step > 0) { step--; render(); } });
  $('learnNext').addEventListener('click', () => { if (++step === LESSONS.length) end(); else render(); });
  $('learnDemo').addEventListener('click', () => {
    $('learnDemo').textContent = api.demo() === 1 ? 'Watch b → a' : 'Watch a → b';
  });
  document.addEventListener('keydown', e => {
    if (e.key !== 'Escape' || (step < 0 && inspector.hidden && welcome.hidden)) return;
    e.preventDefault(); e.stopImmediatePropagation();
    if (!inspector.hidden) { closeParts(); $('exploreParts').focus(); } else end();
  }, true);
  // Exploration changes must restore isolated materials before the scene changes.
  for (const id of ['btnXray','btnElec','btnView','btnAddCell','btnDelCell']) {
    $(id).addEventListener('click', () => { if (!inspector.hidden) closeParts(); }, true);
  }
  let seen = false;
  try { seen = localStorage.getItem('braillix.tour.seen') === '1'; } catch { /* show invitation */ }
  const ready = () => {
    api.ready();
    if (!seen) {
      welcome.hidden = false; api.pause(); welcome.showModal(); $('startTour').focus();
      try { localStorage.setItem('braillix.tour.seen', '1'); } catch { /* optional browser storage */ }
    }
    $('replayTour').disabled = false; $('exploreParts').disabled = false;
  };
  if (!seen) setTimeout(ready, matchMedia('(prefers-reduced-motion: reduce)').matches ? 0 : 900);
  else ready();
}

