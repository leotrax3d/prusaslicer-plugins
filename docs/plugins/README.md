# Plugin reference

One page per plugin: what it builds, every parameter, how to read the result, and which
slicer settings it changes.

| Plugin | Bundle | Purpose |
| --- | --- | --- |
| [Fan Tower](fan-tower.md) | `com.leotrax3d.calibration` | Find the right part cooling |
| [Speed Tower](speed-tower.md) | `com.leotrax3d.calibration` | Find the highest usable print speed |
| [Tolerance Test](tolerance-test.md) | `com.leotrax3d.calibration` | Find the clearance parts need to fit |
| [Box Generator](box-generator.md) | `com.leotrax3d.utilities` | Storage boxes, drawer inserts and organiser trays |
| [Ambigram](ambigram.md) | `com.leotrax3d.utilities` | A word that stays readable turned around |

The calibration plugins change print or filament settings in the project they create and do
not restore them afterwards, so run those in a throwaway project. The generators in
`com.leotrax3d.utilities` change no settings at all.

See [`../installation.md`](../installation.md) to install, and
[`../../DEVINFO.md`](../../DEVINFO.md) for how the plugin system works underneath.
