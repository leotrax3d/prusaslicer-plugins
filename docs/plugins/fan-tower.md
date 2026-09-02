# Fan Tower

**Menu:** Calibration → Fan Tower · **Bundle:** `com.leotrax3d.calibration`

Finds the right amount of part cooling for a filament by printing every fan speed in one
object.

## What it builds

A square tower divided into height bands, each printed at a different fan speed, with the
speed engraved into the front face of its band. A slender pillar stands beside it.

The pillar is the part that matters. The head has to travel between tower and pillar on
every layer, so the pillar gets almost no time to cool between passes — it fails first
when cooling is insufficient. Comparing bands on the pillar tells you far more than the
tower alone.

## Parameters

| Parameter | Default | Meaning |
| --- | --- | --- |
| Min Fan Speed [%] | 0 | Fan speed of the bottom band |
| Max Fan Speed [%] | 100 | Fan speed of the top band |
| Num Steps | 5 | Number of bands; minimum 2 |
| Step Height [mm] | 8 | Height of each band |
| Tower Size [mm] | 20 | Edge length of the square tower |
| Engrave Labels | on | Engrave each band's fan speed into the front face |

## How to read the result

Look at the pillar first, from the bottom up. Overhangs sagging, corners bulging and
layers fusing into each other mean too little cooling. Then look for where it stops
improving — past that point more cooling only costs layer adhesion. On PLA the answer is
usually the top of the range; PETG and ABS typically want much less.

Take the lowest speed that still looks clean, not the highest speed that works.

## Settings it changes

Applied to the current bed's presets when the plugin runs:

| Setting | Value | Why |
| --- | --- | --- |
| `fill_density` | 10% | Cooling should drive the result, not wall mass |
| `perimeters` | 2 | As above |
| `top_solid_layers` / `bottom_solid_layers` | 3 / 3 | |
| `brim_type` / `brim_width` | `outer_only` / 5 mm | A slender pillar this tall will not hold without one |
| `cooling` | 0 | See below |
| `fan_always_on` | 0 | See below |
| `full_fan_speed_layer` | 0 | Disables the fan ramp-up, which would fight the bands |
| `disable_fan_first_layers` | 1 | Keeps the fan off for the first layer only |

**Why auto cooling is turned off.** Fan speed is firmware state, so the plugin steps it
with `M106` injected at each band boundary. But PrusaSlicer's `CoolingBuffer` recomputes a
fan speed for *every* layer and emits its own `M106` whenever that value changes — which
would silently overwrite the bands. Short layers are especially prone to it, since the
buffer forces full throttle when a layer prints faster than `slowdown_below_layer_time`.
With auto cooling off and `fan_always_on` off, its computed speed stays 0 for every layer,
so it emits one `M107` at the start and then stays quiet, leaving the injected commands
authoritative.

## Limitations

- The first band's fan command may land one layer later than its boundary, because
  `disable_fan_first_layers` holds the fan off through layer 1.
- The tower changes filament cooling settings for the project it creates. It does not
  restore them afterwards — use a throwaway project.
