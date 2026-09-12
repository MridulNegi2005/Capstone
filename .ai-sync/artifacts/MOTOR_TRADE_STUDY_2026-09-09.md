# Braillix motor decision and affordable experiment

Date: 2026-09-09. Research and proposed tests; no replacement motor ordered, installed or validated. This supplements the hardware audit and the isolated compact CAD candidate. Prices are page observations or explicitly labelled allowances, not a shopping cart.

## Recommendation

Keep the owned 28BYJ-48 for the first corrected, loaded mechanism and the initial two-character demonstration. Reducing rubbing, spring preload and ramp load is more valuable now than buying a stronger motor to overcome a binding mechanism. Trial an N20 encoder motor only if measured refresh time or missed motion remains unacceptable after those corrections. Do not redesign every cell around an untested replacement.

The user owns one motor and one of each initial component, has college FDM access with filament costs, and expects a possible November demonstration and likely December final demonstration. These dates are tentative. The immediate target is independent simultaneous Braille characters as cells are added, with matching brain and muscle exteriors.

The 48.4 mm cam remains the main footprint constraint. A 10 × 12 mm motor does not imply a 12 mm cell: the cam, six tracks, guides, supports, connector retention and brain electronics still have to fit. Axial motor length, encoder and shaft can also make a nominally smaller motor produce a taller stack. A shared 64 mm exterior is a packaging investigation independent of buying another motor.

## Budget reality

The project lead read the supplied [cost document](https://docs.google.com/document/d/19lWvlRwd3ornu_sxtSh7vD-5pXRhXanWN8iXrxeGseU/edit?tab=t.0) in this review. The provided ledger is: filament ₹899, initial electronics ₹935, screwdrivers ₹353, caliper ₹430, resin ₹410, multimeter ₹150, soldering tools ₹450, springs ₹1,179, MCP23017-E/SO ₹356, five-pin pogo ₹348. Sum: **₹5,510**. Subject to receipts and omitted delivery costs, this leaves **₹4,490 at ₹10,000 total**, or **₹9,490 at ₹15,000 total**. Do not count these purchases again as future spending.

At the baseline budget, reserve the remaining money for corrected precision parts, a second working character, complete local electronics, connectors and rework. An experimental motor package costing ₹1,000–1,900 would consume roughly 22–42% of the current baseline remainder. Its inexpensive motor price alone hides its controller, driver and mechanical revision costs.

## Ranked choices

| Rank / choice | Size and performance consequence | Electronics and accuracy consequence | Incremental cost and decision |
|---|---|---|---|
| 1. Existing 28BYJ-48 + ULN2003 | Preserves present shaft/mount; slow geared output. Corrected mechanics may improve reliable speed, but this needs measurement. | Retain Hall homing; calibrate actual gearing and reversal error. Open-loop commands cannot prove the dots moved. | Existing motor ₹0 additional. [FlyRobo kit](https://www.flyrobo.in/28byj-48-5v-stepper-motor-with-uln2003-driver-board) displayed **₹139 including GST, in stock**, checked today, excluding delivery. Board fit still differs from bare-IC carrier. Best baseline. |
| 2. N20 encoder gearmotor, approximately 70–150 RPM class | Faster candidate; small cross-section frees local space, not the cam footprint. Needs new motor cradle and 3 mm shaft interface; full encoder/wire envelope must be measured. | H-bridge, local edge counting, feedback tuning and homing required. Motor-side encoder misses gearbox backlash and cam/coupler slip. | **₹1,000–1,900 bench allowance**, detailed below; not a quote. Best optional experiment after baseline tests. |
| 3. Small direct-drive bipolar stepper | Less gearbox backlash, potentially faster; small body width can conceal greater body/shaft height. Available torque may be lower than current geared motor. | Current-controlled bipolar driver and new supply/thermal review; microsteps improve command resolution but do not guarantee position under load. | Representative SOYO/Pololu NEMA 8 lists **US$41.32 motor only**, excluding delivery/import costs. No Indian delivered quote verified. Poor baseline value. |
| 4. Smaller geared stepper or six independent latching dots | Could permit a genuinely different mechanism and denser characters. Requires a sourced actuator plus a new cam or dot architecture, not just a smaller case. | New force, holding, wear and control validation. Six-actuator approaches multiply channels and assembly. | Unquoted research branch. Do not allocate baseline money before an independently demonstrated mechanism exists. |

## What the specifications actually mean

### Existing motor: establish its loaded envelope

The [ELEGOO 28BYJ-48 reference](https://wiki.elegoo.com/oshw-parts-&-accessories/Stepper-Motor) lists in-traction torque above 34.3 mN·m at 120 Hz. This is a supplier reference for a motor family, not proof of the owned motor's torque at 1,000 half-steps/s. Phase sequence, drive voltage, gearing variant and frequency convention matter. Do not transfer that number to the fastest firmware setting or use stall/holding torque as continuous running torque.

The inspected `firmware/braille_cell/braille_cell.ino` uses nominal 4,096 half-steps/revolution, 1,000 half-steps/s and 2,000 half-steps/s². A 2,048-step move with a symmetric trapezoidal profile takes approximately `2048/1000 + 1000/2000 = 2.548 seconds`; a 64-step move takes `2*sqrt(64/2000) = 0.358 seconds`. These exclude settling, communication, reversal approach and homing. They assume the motor follows every commanded step. Increasing only top speed does little for short, acceleration-limited moves.

### N20: promising speed, additional control work

As a documented engineering reference, [Pololu's 100:1 HP 6 V family](https://www.pololu.com/product/1101) has a 10 × 12 mm gearbox cross-section and a 3 mm D shaft; the referenced winding is specified at 310 RPM unloaded and 1.7 kg·cm extrapolated stall torque. Its [manufacturer performance data](https://www.pololu.com/file/0J1487/pololu-micro-metal-gearmotors-rev-6-2.pdf) warns against operating near stall. These figures must **not** be assigned to a generic ₹500 N20 just because its case looks similar.

A 100 RPM output would traverse 180° in 0.30 seconds at steady speed. That arithmetic is a lower bound for a rated-speed move, not a Braillix refresh promise: acceleration, load, braking and settling add time. The relevant result is time to settle in the correct cam dwell under six real followers, including reversals.

The [Robu N20 6 V 100 RPM page](https://robu.in/product/n20-6v-100rpm-micro-metal-gear-motor-with-encoder/) did not expose a current price in the fetched live page. An older indexed staging page showed ₹469, but that is **not a verified current quotation**. Budget ₹500–800 for a candidate motor only until checkout price and the exact encoder definition are confirmed. Do not trust ambiguous PPR/CPR wording: manually rotate and measure counts in the actual decoding mode. At 12 counts per motor revolution and 100:1 gearing, a 100 RPM output produces about 2,000 counted edges/s; counts and ratios must be measured for the actual unit.

The [MCP23017](https://www.microchip.com/en-us/product/mcp23017) is an I²C GPIO expander. Its interrupt capture records port state, not a queue or quadrature position count. Reading it over a shared chain cannot be presumed to capture every fast encoder transition. Use a local MCU with appropriate interrupt/hardware counting and PWM, then exchange target/ready/error messages with the brain. This is a separate software-team task and a carrier redesign. Existing MCP23017 purchases can remain useful for other I/O, but they do not replace this controller.

A suitable H-bridge board, for example one using [TI DRV8833](https://www.ti.com/product/DRV8833), can reverse and brake a DC motor. The IC operates over 2.7–10.8 V; continuous current depends on package and board cooling, so a board advertised as “2 A” is not automatically a 2 A continuous board. Confirm current limiting and real motor starting/jam current. Reusing the 5 V bus for a nominal 6 V motor requires testing at 5 V; it will not retain its 6 V published speed/torque curve. Do not raise the shared bus to 6 V without reviewing every connected component.

Planning allowance for one bench experiment: motor ₹500–800; driver board ₹100–200; small local controller ₹150–350; mount, coupler, decoupling and wiring ₹100–250; delivery/contingency ₹150–300. **Total ₹1,000–1,900**, excluding another resin mechanism or power-supply replacement. Motor-side feedback detects many motor-motion failures, but not a broken follower, wrong dot, or slipping downstream shaft. Keep output homing and visible loaded-state inspection.

### NEMA 8: smaller width is not enough

The [SOYO SY20STH30-0604A sold by Pololu](https://www.pololu.com/product/1204/specs) has a 20 mm square × 30 mm body, 4 mm shaft, 600 mA/phase and 180 g·cm holding torque, approximately **17.7 mN·m**. The [dimensioned product description](https://www.pololu.com/product/1204) lists a 15 mm shaft. It is therefore not an automatic height reduction or torque upgrade. Holding torque is not its torque while turning. At full 0.6 A in both 6.5 Ω windings, copper loss alone is about `2*(0.6^2)*6.5 = 4.68 W`; actual driver waveform/idle-current settings change that. Thermal testing inside the plastic enclosure matters. Its 1.8° full-step pitch also does not divide the cam's 5.625° state pitch exactly; microstepping and loaded settling need verification.

## The experiment to do first

**Use the existing motor to map reliable loaded speed before buying a replacement.** This separates a mechanism fault from an actuator limitation and creates a fair N20 comparison if needed.

1. Build one corrected mechanism with the actual purchased springs. First establish free cam rotation, then test with one follower and all six. Use a removable mount; do not cut the motor shaft or glue over it.
2. Run the existing bare-motor test only after wiring and sensor identity are checked. Start below its current maximum; compare 400, 600, 800 and 1,000 half-steps/s with controlled acceleration. Stop increasing at the first error. These are test points, not guaranteed safe loaded operating speeds.
3. At each usable setting, inspect all 64 settled patterns, then mixed long moves and reversals. Record elapsed time, incorrect dots, audible stalls, home return and supply voltage during motion. A smartphone video and the existing multimeter are sufficient for initial screening; the multimeter will not capture brief supply dips reliably.
4. Pick a setting with margin below failure and run at least 500 mixed transitions plus 20 homes. Record temperature during a representative 20–30-minute closed-case trial. A passing test is evidence for this prototype, not an error-proof guarantee.
5. If it remains too slow for a deliberate character-change demo, trial one encoder N20 on the same corrected mechanism with a removable adapter. Compare **settled correct state**, not unloaded shaft speed. Require a clear measured improvement, repeatable reversals and no increased jam damage before duplicating it.

With a possible November demonstration, prioritize one reliable cell in September and the independently controlled two-cell chain in October; treat this as a suggested work sequence, not a confirmed event schedule. “Smarter” first means dependable homing, timeouts, missing-cell reporting, completed-row feedback and an honest fault state. None of these requires claiming the mechanism is error-proof.
