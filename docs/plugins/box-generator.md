# Box Generator

**Bundle:** `com.leotrax3d.utilities` · **Menu:** Generators → Parametric Box

Builds a storage box, drawer insert or organiser tray, optionally with a lid, compartment
dividers, a stacking groove and an engraved label. Pure geometry: it changes no slicer
settings and injects no G-code.

## Dimensions are the inside of the box

Every other box generator asks for outer dimensions and then eats into them with the wall
thickness, so you end up solving for what actually fits. This one asks for the cavity you
need — the drill bits, the batteries, the drawer it has to slide into minus clearance — and
adds walls and floor outside it. Raising the wall thickness makes the box bigger, never the
contents smaller.

For an insert that has to fit a known drawer, subtract the wall from the drawer size
yourself: a 100 mm drawer with 2 mm walls means an inner width of 96 mm.

## Parameters

| Parameter | Default | What it does |
| --- | --- | --- |
| Inner Width / Depth / Height | 80 / 60 / 40 mm | The usable cavity |
| Wall Thickness | 2.0 mm | Sides. A multiple of your nozzle width prints cleanest |
| Floor Thickness | 1.6 mm | Base. Must exceed the stacking groove depth if stacking |
| Corner Radius | 3.0 mm | Vertical corner rounding, outside and cavity alike. `0` gives square corners |
| Compartments Across / Deep | 1 / 1 | Divider grid. `3` across and `2` deep gives six compartments |
| Divider Thickness | 1.6 mm | |
| Divider Height | 100 % | Below 100 % the compartments stay connected at the top, so contents can be swept out in one go |
| Stacking Groove | off | A pocket in the underside that the walls of the box below sit in |
| Finger Notch | off | A half-round bite out of the top of the front wall |
| Generate Lid | off | Adds a slip-over lid as a second object |
| Lid Height | 8 mm | How far the lid comes down the sides |
| Fit Clearance | 0.25 mm | Play between lid and box, and in the stacking groove |
| Front Label | *(empty)* | Engraved into the front wall, and the lid's front if there is one |

## Printing

Vase mode is the wrong choice here — the dividers and the lid rim need real perimeters.
Otherwise the defaults are fine; the box is a rectangular prism with no overhangs.

The lid is generated **open side up**, which is the orientation it should print in. Don't
flip it: printing a lid closed side up puts its rim in mid-air.

Set the fit clearance from a Tolerance Test if you have run one, since it is the same
quantity. `0.25 mm` suits most printers for a lid you want to come off easily; drop to
`0.15` for a lid that stays put.

## Notes on the geometry

Rounded corners are built as two overlapping bars plus four corner cylinders, because the
API has no rounded-box primitive and no boolean intersection — only union (Solid volumes)
and difference (Negative volumes).

The stacking groove uses the same limitation the other way round. There is no ring
primitive, so the underside is cut as one full pocket and the middle is then restored as a
Solid volume placed *after* the cut. PrusaSlicer applies volumes in list order, which makes
"cut, then put part of it back" the closest thing to an intersection available.

Corner radii larger than half the box are clamped rather than rejected, so a large value
gives a stadium shape instead of an error.

## Verification status

The placement arithmetic — wall thickness around the cavity, lid clearance, groove island
inset, divider spacing, notch and label position — is checked against a mock of the slicer
API in this repository's tests. That confirms the maths, not the result: `api` exists only
inside PrusaSlicer, so the printed part is the real test. Report anything that comes out
wrong.
