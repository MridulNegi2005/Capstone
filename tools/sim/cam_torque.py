"""Motor torque needed to turn the real cam against six return springs.

Cam heights come from the frozen resin mesh (cad/assets/braille_cam.stl),
sampled by vertical ray casting at each track's centre radius.
"""
import numpy as np, trimesh, json

cam = trimesh.load("D:/TIET/Capstone/cad/assets/braille_cam.stl")
TRI = cam.triangles
FACE = 8.5                                   # cam face, dot DOWN
R = [14.8 + 1.7 * t for t in range(6)]       # track centre radii
DOT_TRACK = [2, 3, 4, 1, 0, 5]
DOT_PHASE = [120, 180, 240, 60, 0, 300]

def top_z(px, py):
    a, b, c = TRI[:, 0], TRI[:, 1], TRI[:, 2]
    den = (b[:, 1] - c[:, 1]) * (a[:, 0] - c[:, 0]) + (c[:, 0] - b[:, 0]) * (a[:, 1] - c[:, 1])
    ok = np.abs(den) > 1e-12
    l1 = np.where(ok, ((b[:, 1] - c[:, 1]) * (px - c[:, 0]) + (c[:, 0] - b[:, 0]) * (py - c[:, 1])) / np.where(ok, den, 1), -1)
    l2 = np.where(ok, ((c[:, 1] - a[:, 1]) * (px - c[:, 0]) + (a[:, 0] - c[:, 0]) * (py - c[:, 1])) / np.where(ok, den, 1), -1)
    l3 = 1 - l1 - l2
    m = (l1 >= -1e-9) & (l2 >= -1e-9) & (l3 >= -1e-9)
    return (l1 * a[:, 2] + l2 * b[:, 2] + l3 * c[:, 2])[m].max()

N = 2048                                     # samples per revolution
ang = np.arange(N) * 360 / N
prof = np.array([[top_z(r * np.cos(np.radians(t)), r * np.sin(np.radians(t))) - FACE
                  for t in ang] for r in R])  # lift (mm) per track per angle
np.save("cam_profile.npy", prof)
print("lift range per track:", [(round(p.min(), 3), round(p.max(), 3)) for p in prof])

def torque(k, pre, mu):
    """Peak cam torque (N*m) over a revolution, either direction."""
    worst = 0
    ds = np.radians(360 / N)
    for sign in (1, -1):
        T = np.zeros(N)
        for d in range(6):
            t, ph = DOT_TRACK[d], DOT_PHASE[d]
            idx = (np.round((ph - ang) / (360 / N)).astype(int)) % N   # cam angle -> foot sample
            h = prof[t][idx]
            dh = (np.roll(prof[t], -sign) - prof[t])[idx] * 1.0      # rise per step in motion dir
            slope = np.arctan(dh / (R[t] * ds))
            F = k * (pre + h)                                         # spring push, N
            Nn = F / np.maximum(np.cos(slope) - mu * np.sin(slope), 0.2)
            T += R[t] / 1000 * Nn * (np.sin(slope) + mu * np.cos(slope))
        worst = max(worst, T.max())
    return worst
json.dump({"R": R}, open("torque_meta.json", "w"))
