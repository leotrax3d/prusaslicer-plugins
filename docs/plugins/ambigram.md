# Ambigram

**Bundle:** `com.leotrax3d.utilities` · **Menu:** Generators → Ambigram

Builds a plate carrying a word that stays readable when you turn it around, by overlaying
both readings into one shape.

## What kind of ambigram this is

There are three things people mean by "3D printed ambigram". This plugin builds the first
and cannot build the other two, so it is worth being clear which is which.

**Overlay — what this does.** The word is embossed, a second copy is rotated 180° and laid
on top, and the two are unioned into a single solid. The result physically contains both
readings; turning the plate around makes the second one the obvious reading. This is a real
technique and it prints well, but it is a union, so the two readings sit on top of each
other rather than being cleverly disguised as one another.

**Dual-view sculpture — not possible.** Two different words extruded along perpendicular
axes and *intersected*, so each viewing direction shows one word and nothing else. This
needs boolean intersection. The plugin API has Solid and Negative volumes — union and
difference — and no way to read a mesh's geometry back, so the intersection can be neither
built nor approximated. If a future API adds intersection or mesh access, this becomes
possible.

**Hand-drawn ambigram — out of scope.** The kind where each glyph is redrawn so that it
reads as a different letter upside down. That is typography, not geometry; no generator can
do it from an arbitrary word.

## Parameters

| Parameter | Default | What it does |
| --- | --- | --- |
| Text | `Ambigram` | The first reading |
| Second Text | *(empty)* | The second reading. Empty means the same word, giving a symmetric plate |
| Mirror instead of Rotate | off | Overlays the mirror image rather than the 180° rotation, so it reads in a mirror |
| Font | *(empty)* | A font name as the slicer knows it. Unknown names fall back to the default rather than failing |
| Text Height | 20 mm | Cap height |
| Text Depth | 4 mm | How far the letters stand off the plate |
| Base Plate | on | A backing plate. Off gives free-standing letters, which need the readings to overlap enough to hold together |
| Plate Thickness | 2 mm | |
| Plate Margin | 6 mm | Border around the text |
| Keyring Hole | off | A 5 mm hole on a tab at the left. Needs the base plate |

## Choosing a word

Overlay ambigrams live or die on how much of the two readings coincide.

- **Short is better.** Four to six letters. Long words in a thin font become a tangle.
- **Heavy, wide fonts work best.** Thick strokes overlap where thin ones merely cross.
- **Symmetric letters are free:** `H N O S X Z` map onto themselves under 180° rotation, and
  `b/q`, `d/p`, `n/u`, `M/W` map onto each other. A word made largely of these needs almost
  no overlay at all.
- Try three or four fonts before judging a word. The dialog costs a few seconds.

With **Second Text** filled in you get a two-word piece — a pair of names is the usual
reason — but the same rule applies: the more strokes the two words share, the better it
reads.

## Printing

The plate prints flat with no overhangs. Two or three perimeters and light infill are
plenty. If you turn the base plate off, check in preview that the two readings actually
touch — free-standing letters that only meet at a hairline will come apart.

Colour changes make the effect much stronger: a colour change at the plate's top surface
puts the letters in a different colour from the backing. Insert it at the plate thickness
you set.

## Verification status

The placement arithmetic is checked against a mock of the slicer API in this repository's
tests, including the property that matters most: both readings are exactly concentric, so
rotating the finished plate about its centre maps one onto the other. Whether a given word
*reads* is a judgement call that only your eyes can make.
