"""MuJoCo: does each arm follow the real cam down? Arm = slider with its real mass,
finger-sheet spring + preload, comb friction. The cam surface under each foot is a
kinematic platform driven by the measured cam lift for that dot's track."""
import numpy as np, mujoco, sys
prof = np.load("cam_profile.npy") / 1000.0           # m
N = prof.shape[1]
TRACK = [2, 3, 4, 1, 0, 5]; PHASE = [120, 180, 240, 60, 0, 300]
MASS = [0.067e-3, 0.079e-3, 0.079e-3, 0.062e-3, 0.062e-3, 0.086e-3]
def model(k, pre, fric):
    b = ""
    for d in range(6):
        x = d * 0.01; bit = 1 << d
        b += f'''<body mocap="true" name="cam{d}" pos="{x} 0 0"><geom type="box" size=".002 .002 .001" pos="0 0 -.001" contype="{bit}" conaffinity="{bit}" solref=".0004 1" solimp=".99 .999 .00001"/></body>
<body name="arm{d}" pos="{x} 0 0"><joint name="j{d}" type="slide" axis="0 0 1" stiffness="{k}" springref="{-pre}" frictionloss="{fric}" damping="0.002" solreffriction=".0004 1" solimpfriction=".99 .999 .00001"/>
<geom type="sphere" size=".0005" pos="0 0 .0005" mass="{MASS[d]}" contype="{bit}" conaffinity="{bit}" solref=".0004 1" solimp=".99 .999 .00001"/></body>'''
    return mujoco.MjModel.from_xml_string(f'<mujoco><option timestep="1e-5" gravity="0 0 -9.81"/><worldbody>{b}</worldbody></mujoco>')
def run(k, pre, fric, sps, revs=1.0):
    m = model(k, pre, fric); dat = mujoco.MjData(m)
    omega = sps / 4076 * 360.0                          # deg/s
    T = revs * 360 / omega; n = int(T / m.opt.timestep)
    gap = np.zeros(6); stuck = np.zeros(6)
    for i in range(n):
        a = omega * i * m.opt.timestep
        for d in range(6):
            dat.mocap_pos[d][2] = prof[TRACK[d]][int(round(((PHASE[d] + a) % 360) / 360 * N)) % N]
        mujoco.mj_step(m, dat)
        if i % 20 == 0:
            for d in range(6):
                g = dat.qpos[d] - dat.mocap_pos[d][2]
                gap[d] = max(gap[d], g)
    return gap * 1000
E, w, L = 2000e6, 3e-3, 14e-3
for t, label in [(0.88e-3, "0.88 sheet, new"), (0.88e-3, "0.88 sheet, after relaxing 30%"), (0.72e-3, "0.72 sheet (soft)")]:
    k = 3 * E * (w * t**3 / 12) / L**3 * (0.7 if "relax" in label else 1.0)
    for fric in (0.0, 0.03, 0.06):
        for sps in (1000, 2000):
            g = run(k, 0.3e-3, fric, sps)
            print(f"{label:32} k={k/1000:.3f} N/mm  comb friction {fric:.2f} N  {sps} steps/s:  worst gap foot-to-cam {g.max():.3f} mm", flush=True)
