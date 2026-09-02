# Installation

PrusaSlicer 3.0 will eventually ship a plugin marketplace with one-click installs,
ratings and signature verification. Until then, plugins are installed by hand: from a
release archive, or by copying a bundle directory into the slicer's data directory. This
document covers both.

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

## Installing from a release

The simplest route. Each [release](https://github.com/leotrax3d/prusaslicer-plugins/releases)
carries a ready-made ZIP per bundle, built and layout-checked by CI, so there is nothing to
package yourself.

1. Download `com.leotrax3d.calibration.zip` from the latest release.
2. Install it in PrusaSlicer, or unpack it into a directory named after the bundle id
   inside the `lua` directory described above.
3. Restart the slicer.

The sections below cover installing from a clone instead, which is what you want while
developing.

## Installing a bundle manually

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
git clone https://github.com/leotrax3d/prusaslicer-plugins.git
cd prusaslicer-plugins
cp -r plugins/com.leotrax3d.calibration "<data directory>/lua/"
```

Copy rather than symlink. Plugin file access is confined to the bundle's own directory,
and a symlinked bundle may not resolve inside that sandbox.

## Installing from a ZIP

PrusaSlicer can also install a bundle from a ZIP archive. This is the format the future
marketplace will distribute, and it is worth knowing one rule about it:

**The archive must contain the bundle's files at its root, not the bundle directory.**

The installer opens the archive and looks for the entry named exactly `manifest.json`. If
you compress the folder itself, that entry is called
`com.leotrax3d.calibration/manifest.json`, no match is found, and the install fails with
`cannot load manifest.json`.

Correct layout inside the archive:

```
manifest.json
fan_tower.lua
labels.lua
speed_tower.lua
tolerance_test.lua
```

To build one by hand, compress the *contents* of the bundle directory:

```bash
cd plugins/com.leotrax3d.calibration
zip ../../com.leotrax3d.calibration.zip manifest.json *.lua
```

On Windows, select the files inside the folder and use Send to → Compressed folder.
Selecting the folder produces the nested layout that fails.

Bundles are flat: subdirectories are not supported, and file names are restricted to
`[a-zA-Z0-9.-_ ]+`.

Signing is not required to install. A signed bundle additionally carries `manifest.txt`
(file checksums) and `manifest.sign`, both produced by `PrusaSlicer plugin sign`, which
also writes a correctly laid out ZIP for you — the reliable way to package for
distribution.

For local development, copying the directory as described above is simpler than
rebuilding an archive after every edit.

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

**`cannot load manifest.json` when installing a ZIP.** The archive wraps the bundle in a
directory. Compress the files inside the bundle, not the bundle folder — see
[Installing from a ZIP](#installing-from-a-zip).

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
