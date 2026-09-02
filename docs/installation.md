# Installation

PrusaSlicer 3.0 will eventually ship a plugin marketplace with one-click installs,
ratings and signature verification. Until then, plugins are installed by copying a bundle
directory into the slicer's data directory. This document covers that manual route.

## Requirements

PrusaSlicer 3.0.0-alpha11 or newer. The bundle's `manifest.json` declares
`min_slicer_version`, and the slicer refuses to load a bundle that requires a newer
version than the one running.

## Where plugins live

Bundles go into a `lua` subdirectory of the PrusaSlicer data directory:

| Platform | Path |
| --- | --- |
| Windows | `%APPDATA%\PrusaSlicer-alpha\lua` |
| macOS | `~/Library/Application Support/PrusaSlicer-alpha/lua` |
| Linux | `~/.config/PrusaSlicer-alpha/lua` |
| Linux (Flatpak) | `~/.var/app/com.prusa3d.PrusaSlicer/config/PrusaSlicer-alpha/lua` |

**On the directory name.** It follows the application key of the build you are running.
Prusa's official alpha builds use `PrusaSlicer-alpha`; beta builds use `PrusaSlicer-beta`,
and stable releases plain `PrusaSlicer`. A copy built from source uses `PrusaSlicer`
unless the build script overrides it. If you launch the slicer with `--datadir`, that path
replaces the table above.

If you are unsure which directory is live, open the folder containing `PrusaSlicer.ini`
and your saved presets — that is the data directory. Create `lua` yourself if it does not
exist.

## Installing a bundle

1. Close PrusaSlicer. Plugins are discovered once at startup.
2. Copy the whole bundle directory — for example `plugins/com.leotrax3d.calibration` — into
   the `lua` directory. Keep the directory name; it must match the `id` in
   `manifest.json`.
3. Start PrusaSlicer.

The result should look like this:

```
<data directory>/
└── lua/
    └── com.leotrax3d.calibration/
        ├── manifest.json
        ├── fan_tower.lua
        ├── labels.lua
        ├── speed_tower.lua
        └── tolerance_test.lua
```

Each plugin appears under the menu path given in its `menu` field. The bundle above adds
Fan Tower, Speed Tower and Tolerance Test under a `Calibration` submenu. Running one opens
a generated parameter dialog; confirming it builds the objects in the current project.

## Installing straight from a clone

```bash
git clone https://github.com/leotrax3d/PrsslcrPlugins.git
cd PrsslcrPlugins
cp -r plugins/com.leotrax3d.calibration "<data directory>/lua/"
```

Copy rather than symlink. Plugin file access is confined to the bundle's own directory,
and a symlinked bundle may not resolve inside that sandbox.

## Updating

Replace the bundle directory with the newer one and restart the slicer. Nothing is cached
outside the directory, so there is no separate cleanup step.

Note that plugins only generate projects — they do not modify existing ones after the
fact. Projects you already produced are unaffected by an update.

## Uninstalling

Delete the bundle directory from `lua` and restart. Projects created by a plugin are
ordinary PrusaSlicer projects and remain fully usable afterwards.

## Troubleshooting

**The menu entry does not appear.** Confirm you copied into the data directory that the
running build actually uses — the alpha's directory is separate from a stable install's,
which is the most common cause. Check that `manifest.json` sits directly inside the bundle
directory rather than in a nested folder, that the directory name matches the manifest
`id`, and that the slicer was fully restarted.

**A plugin errors when run.** The plugins in this repository have not been verified
against a live slicer. Please open an issue with the error text and your alpha version;
see [`api-notes.md`](api-notes.md) for the assumptions most likely to be wrong.

## A note on trust

Plugins run sandboxed: no network, no process execution, and no filesystem access outside
their own directory. That is a meaningful limit on what a malicious plugin could do, but
it is not a guarantee that a plugin does something sensible with your printer settings.
These plugins change print presets — layer height, speeds, infill — as part of generating
their calibration objects. Review the Lua source before installing anything, including
this bundle.
