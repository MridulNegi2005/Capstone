"""Arm on the real cam, exact Coulomb stick-slip. Units mm, g, ms (force in N).
The cam is a rigid floor that only pushes up; the sheet spring and gravity pull down;
comb friction resists motion and holds the arm still when the net force is below it."""
import numpy as np
prof = np.load("cam_profile.npy"); N = prof.shape[1]
TRACK = [2, 3, 4, 1, 0, 5]; PHASE = [120, 180, 240, 60, 0, 300]
MASS = [0.067, 0.079, 0.079, 0.062, 0.062, 0.086]
def sim(k, pre, fric, sps, revs=1.0, dt=0.002):
    omega = sps / 4076 * 360.0 / 1000.0                       # deg per ms
    n = int(revs * 360 / omega / dt); worst = np.zeros(6); dwell = np.zeros(6)
    for d in range(6):
        idx = lambda a: int(round(((PHASE[d] + a) % 360) / 360 * N)) % N
        x = v = 0.0; m = MASS[d]
        for i in range(n):
            a = omega * i * dt; h = prof[TRACK[d]][idx(a)]
            F = -k * (x + pre) - m * 9.81e-3                     # spring + gravity, N
            if abs(v) < 1e-9 and abs(F) <= fric: v = 0.0
            else:
                F -= np.sign(v if abs(v) > 1e-9 else F) * fric
                v_new = v + F / m * dt
                if v != 0 and np.sign(v_new) != np.sign(v) and abs(F) > 0: v_new = 0.0
                v = v_new; x += v * dt
            if x <= h: x, v = h, max(v, 0.0)
            g = x - h; worst[d] = max(worst[d], g)
            if (a % 5.625) > 2.0 and (a % 5.625) < 3.6: dwell[d] = max(dwell[d], g)
    return worst, dwell
if __name__ == "__main__":
    E, w, L = 2000.0, 3.0, 14.0
    print("control (friction 0.2 N, stronger than the spring), quarter turn:")
    print("  worst gap per arm", sim(0.373, 0.3, 0.2, 1000, revs=0.25)[0].round(3), " expected about 0.236 where a dot drops")
    for t, lab, f in [(0.88, "0.88 new", 1.0), (0.88, "0.88 relaxed 30%", 0.7), (0.72, "0.72 soft", 1.0)]:
        k = 3 * E * (w * t**3 / 12) / L**3 * f
        for fric in (0.0, 0.03, 0.06, 0.1):
            for sps in (1000, 2000):
                wst, dw = sim(k, 0.3, fric, sps)
                print(f"{lab:17} spring {k*0.3:.3f} N at rest | comb friction {fric:.2f} N | {sps} steps/s | worst gap {wst.max():.3f} mm | gap while a letter shows {dw.max():.3f} mm", flush=True)
