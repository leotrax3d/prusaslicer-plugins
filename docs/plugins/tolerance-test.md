# Tolerance Test

**Menu:** Calibration → Tolerance Test · **Bundle:** `com.leotrax3d.calibration`

Determines the clearance your parts need to fit together, for this printer and this
filament.

## What it builds

A solid plate with a row of holes, each a different amount larger than a test pin printed
alongside it. The clearance is engraved into the top surface in front of each hole.

Print it, then work along the row and find the first hole the pin seats in cleanly. That
clearance is what your own designs should use.

Pure geometry — no G-code tricks and no settings changing mid-print.

## Parameters

| Parameter | Default | Meaning |
| --- | --- | --- |
| Pin Diameter [mm] | 6 | Nominal diameter; the pin is printed at exactly this |
| Min Clearance [mm] | 0.0 | Added to the first hole |
| Max Clearance [mm] | 0.5 | Added to the last hole |
| Num Steps | 6 | Number of holes; minimum 2 |
| Plate Thickness [mm] | 6 | Also sets the pin length, at twice this |
| Engrave Labels | on | Engrave each clearance onto the top surface |

Hole diameter is `Pin Diameter + clearance`, stepped linearly across the row. The plate
sizes itself from these values, so there is no layout to get wrong.

## How to read the result

The first hole the pin enters without force is your clearance. Two things worth knowing:

- **It is not one number.** A press fit, a sliding fit and a free-running fit want
  different clearances. This finds the point where contact stops — add to it for anything
  that has to move.
- **It is filament-specific.** PETG and ABS behave differently from PLA, and a change of
  nozzle temperature moves the answer. Rerun it when you change material.

Clearance in the hole is only half of a real fit: the mating part has its own error. For a
peg you design yourself, expect to split the measured clearance between the two.

## Settings it changes

| Setting | Value | Why |
| --- | --- | --- |
| `fill_density` | 100% | A hole wall that flexes would measure infill density, not tolerance |
| `perimeters` | 3 | As above |

## Implementation note

Hole and pin are positioned from `Mesh:bounds()` rather than from an assumption about
where `make_cylinder` places its origin. This makes the placement correct whether the
primitive is centred in XY or anchored at a corner — the API does not document which, and
guessing wrong would put every hole in the wrong place.

## Limitations

- Holes are round and vertical, so this measures the easiest possible case. Slots,
  horizontal holes and bridged holes behave differently.
- The pin prints as a separate object beside the plate. On a small bed, reduce
  `Num Steps` if the pair does not fit.
