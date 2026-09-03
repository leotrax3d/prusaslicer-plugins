# prusaslicer-plugins-unofficial

[![Latest release](https://img.shields.io/github/v/release/leotrax3d/prusaslicer-plugins-unofficial?label=release)](https://github.com/leotrax3d/prusaslicer-plugins-unofficial/releases/latest)
[![Release workflow](https://img.shields.io/github/actions/workflow/status/leotrax3d/prusaslicer-plugins-unofficial/release.yml?label=build)](https://github.com/leotrax3d/prusaslicer-plugins-unofficial/actions/workflows/release.yml)
[![PrusaSlicer 3.0.0-alpha11](https://img.shields.io/badge/PrusaSlicer-3.0.0--alpha11-orange)](https://github.com/prusa3d/PrusaSlicer/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

An unofficial collection of Lua plugins for
[PrusaSlicer 3.0](https://github.com/prusa3d/PrusaSlicer) and the plugin system it
introduced.

PrusaSlicer ships a Flow Tower and a Temperature Tower. This repository fills in the
calibration prints it does not, and adds parametric generators for parts you would otherwise
open CAD for.

## Plugins

Each page covers what the plugin builds, every parameter, how to read the printed result,
and which slicer settings it changes.

| Plugin | Purpose | Menu |
| --- | --- | --- |
| **[Fan Tower](docs/plugins/fan-tower.md)** | Steps part cooling per height band. A slender pillar beside the tower forces a travel move every layer, so it barely cools between passes and shows insufficient cooling first. | Calibration → Fan Tower |
| **[Speed Tower](docs/plugins/speed-tower.md)** | Steps print speed per height band using modifier volumes, with the slicer's own slowdown and volumetric limits disabled so the bands print at the speeds they claim. | Calibration → Speed Tower |
| **[Tolerance Test](docs/plugins/tolerance-test.md)** | A plate of holes with increasing clearance plus a matching test pin, to find the fit allowance your printer and filament actually need. | Calibration → Tolerance Test |
| **[Box Generator](docs/plugins/box-generator.md)** | Storage boxes, drawer inserts and organiser trays, specified by the space you need *inside* them. Lid, compartment dividers, stacking groove, finger notch and engraved label. | Generators → Parametric Box |
| **[Ambigram](docs/plugins/ambigram.md)** | A word overlaid with its own 180° rotation, or with a second word, so the plate reads both ways round. | Generators → Ambigram |

Two bundles. The three calibration plugins in `com.leotrax3d.calibration` change print or
filament settings in the project they create and do not restore them, so run those in a
throwaway project. The generators in `com.leotrax3d.utilities` are pure geometry and change
nothing.

## Installation

Download the bundles from the
[latest release](https://github.com/leotrax3d/prusaslicer-plugins-unofficial/releases/latest)
and unpack each into your PrusaSlicer data directory under `lua/<bundle-id>/` — so
`lua/com.leotrax3d.calibration/` and `lua/com.leotrax3d.utilities/` — then restart the
slicer. Install only the bundles you want; they are independent.

Do not use the slicer's ZIP import — the archives are unsigned, and that path additionally
requires the author's public key on your machine. Unpacking has no such requirement.
[`docs/installation.md`](docs/installation.md) has the per-platform paths, the data
directory naming that catches people out, and troubleshooting.

## Status

Confirmed working in PrusaSlicer 3.0.0-alpha11 on Windows: the plugins load, the dialogs
generate, and the objects and engraved labels come out as intended.

The API is experimental and Prusa expects breaking changes, so treat compatibility with
any given alpha as unproven until tested. Open questions are tracked in
[`DEVINFO.md`](DEVINFO.md#unverified-assumptions).

## Documentation

| Document | Contents |
| --- | --- |
| [`docs/plugins/`](docs/plugins/README.md) | Per-plugin reference |
| [`docs/installation.md`](docs/installation.md) | Install paths, updating, troubleshooting |
| [`DEVINFO.md`](DEVINFO.md) | How the plugin system works: API reference, findings, and what it cannot do |
| [`docs/roadmap.md`](docs/roadmap.md) | Planned work and what is currently blocked |

## Writing your own

A plugin is a Lua file exposing a global `info` table and a global `execute(opts)`
function. PrusaSlicer scans its `lua` directory at startup, builds menu entries from
`info.menu`, generates a dialog from `info.params`, and calls `execute` with the values
entered.

```lua
info = {
    id = "hello",
    type = "project.plugin",
    title = "Hello world",
    menu = "Tutorial/Hello world",
    params = {
        {name = "text", label = "Text", type = "string", default = "Hello world"}
    }
}

function execute(opts)
    api.project:add_object{
        mesh = api.emboss_text{
            font = api.get_default_font(),
            text = opts.text,
            depth = 1
        },
        object_params = {fill_density = "0%"}
    }
end
```

Available: eleven procedural mesh primitives plus STL, SVG and text embossing; negative and
modifier volumes; support blockers and enforcers; per-object and per-volume setting
overrides; read and write access to print, printer and material presets; and custom G-code
injected at a given Z height.

Not available: G-code post-processing, network access, filesystem access outside the
plugin's own directory, persistence across restarts, event hooks, viewport gizmos, and any
dialog control beyond the four parameter types `string`, `float`, `int` and `bool`.

[`DEVINFO.md`](DEVINFO.md) has the full reference with signatures, the traps that cost this
project time, and the ideas that turned out to be impossible.

Scaffold a bundle with the slicer's own wizard:

```bash
<installation_path>/PrusaSlicer plugin init com.example.my-plugin
```

## Repository layout

```
plugins/<bundle-id>/   plugin bundle: manifest.json plus Lua scripts
docs/plugins/          per-plugin reference
docs/                  installation and roadmap
tools/                 checks and geometry tests
DEVINFO.md             how the plugin system works
```

A bundle groups related plugins under one `manifest.json`. Each `.lua` file that defines
`info` becomes a menu entry; files returning a module instead are shared helpers loaded
with `require('name')` — **inside `execute()`**, never at file level, for reasons
[`DEVINFO.md`](DEVINFO.md#the-two-lua-environments--verified-and-the-subtlest-trap-here)
explains.

## Testing

```bash
luac -p plugins/*/*.lua      # syntax
./tools/check-plugins.sh     # simulates the slicer's plugin scan
./tools/run-tests.sh         # geometry arithmetic against a mock API
```

All three run in CI before a release is published, along with a check that each built
archive is flat and carries a root `manifest.json`.

The tests go only as far as arithmetic. `api`, `VolumeType` and the preset system exist
only inside PrusaSlicer, so the mock can confirm that a lid clears the box it was generated
for, but not that either comes out of the printer right. Everything beyond that is
exercised by hand.

## Contributing

Issues and pull requests welcome. Since the API is still moving, always state which alpha
version you tested against, and whether a change is verified in the slicer or inferred from
the source.

## License

MIT. See [LICENSE](LICENSE).

The plugins are original work written against PrusaSlicer's public Lua API. They contain no
PrusaSlicer source code, so the slicer's AGPL licensing does not extend to them.

## Trademarks

"Prusa", "PrusaSlicer" and "Original Prusa" are trademarks of Prusa Research s.r.o. This is
an independent, unofficial project. It is not affiliated with, endorsed by, or supported by
Prusa Research, and the name is used only to identify the software these plugins are
written for. For support with PrusaSlicer itself, contact Prusa Research; for problems with
these plugins, open an issue here.
