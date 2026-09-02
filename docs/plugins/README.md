# Plugin reference

One page per plugin: what it builds, every parameter, how to read the result, and which
slicer settings it changes.

| Plugin | Bundle | Purpose |
| --- | --- | --- |
| [Fan Tower](fan-tower.md) | `com.leotrax3d.calibration` | Find the right part cooling |
| [Speed Tower](speed-tower.md) | `com.leotrax3d.calibration` | Find the highest usable print speed |
| [Tolerance Test](tolerance-test.md) | `com.leotrax3d.calibration` | Find the clearance parts need to fit |

Every plugin changes print or filament settings in the project it creates and does not
restore them afterwards. Run them in a throwaway project.

See [`../installation.md`](../installation.md) to install, and
[`../../DEVINFO.md`](../../DEVINFO.md) for how the plugin system works underneath.
