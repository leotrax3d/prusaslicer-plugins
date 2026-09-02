# Speed Tower

**Menu:** Calibration → Speed Tower · **Bundle:** `com.leotrax3d.calibration`

Finds the highest print speed a printer holds without visible quality loss.

## What it builds

A square tower divided into height bands. Each band carries a modifier volume that
overrides the speed settings for that region, and the speed is engraved into the front
face.

Unlike fan speed, print speed is not firmware state — it is a slicer setting, so it cannot
be stepped with custom G-code. Modifier volumes are the mechanism that works, and it is
the same one Prusa's own Flow Tower uses.

## Parameters

| Parameter | Default | Meaning |
| --- | --- | --- |
| Min Speed [mm/s] | 30 | Speed of the bottom band |
| Max Speed [mm/s] | 150 | Speed of the top band |
| Num Steps | 5 | Number of bands; minimum 2 |
| Step Height [mm] | 8 | Height of each band |
| Tower Size [mm] | 20 | Edge length of the square tower |
| Engrave Labels | on | Engrave each band's speed into the front face |

Each band sets `perimeter_speed`, `external_perimeter_speed`, `infill_speed` and
`solid_infill_speed` to the same value, so one number describes the whole band.

## How to read the result

Ringing and ghosting after corners, walls that bulge or thin out, layers that stop meeting
cleanly — these appear at the speed your machine's acceleration and extruder stop keeping
up. The useful answer is the band below the first one that shows them.

Bear in mind this measures *your machine*, not the filament: frame rigidity and
acceleration limits usually decide the outcome before the hot end does.

## Settings it changes

| Setting | Value | Why |
| --- | --- | --- |
| `fill_density` | 0% | An open interior, so speed decides the result |
| `perimeters` | 2 | As above |
| `top_solid_layers` / `bottom_solid_layers` | 0 / 3 | |
| `cooling` | 0 | See below |
| `fan_always_on` / `min_fan_speed` | 1 / 100 | Constant cooling, so it does not confound the comparison |
| `filament_max_volumetric_speed` | 0 | See below |

**Why two limiters are disabled.** Both would quietly defeat the test.

A 20 mm tower has very short layers, and PrusaSlicer's `CoolingBuffer` slows any layer
that would print faster than `slowdown_below_layer_time` — so without disabling auto
cooling, every band would print at roughly the same speed while claiming otherwise. The
volumetric limit does the same thing by a different route: with it in place the fast bands
are capped to the filament's maximum flow and print slower than their engraved label.

Removing both means the tower shows honestly where quality breaks down.

## Limitations

- With auto cooling off, cooling is fixed at 100%. That is deliberate for comparability
  but is not how you would print normally.
- Speeds are requested, not guaranteed: on short walls, acceleration limits mean the head
  may never reach the commanded speed. Larger `Tower Size` gives the machine more room to
  get there.
