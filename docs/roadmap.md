# Roadmap

Everything here is provisional. The Lua API is experimental, so what is impossible today
may become possible with the next alpha — and what works today may break.

## The governing constraint

There is exactly one plugin type, `project.plugin`, and it always follows the same flow:

> user clicks a menu entry → dialog of `string`/`float`/`int`/`bool` values → plugin
> creates objects and settings in the project

No network, no general filesystem access, no events, no G-code post-processing. Every idea
has to fit through that opening.

## Phase 0 — Map the API — done

Completed, though not as planned. Rather than probing a running slicer, the API was
reconstructed from `ProjectApi.cpp` and `PluginDialog.cpp` in the PrusaSlicer source. The
registration code carries full LuaLS annotations and is more complete than the prose
documentation.

The headline finding: the API is considerably more capable than `Plugin_API.md` suggests —
eleven procedural primitives, negative and modifier volumes, and per-layer custom G-code.
Results are in [`DEVINFO.md`](../DEVINFO.md).

A handful of questions cannot be settled from source alone (rotation pivot, primitive
origins, which setting keys are valid per volume). Those need a running slicer.

## Phase 1 — Complete the calibration set — in progress

PrusaSlicer ships a Flow Tower and a Temperature Tower. The `com.leotrax3d.calibration`
bundle adds:

| Plugin | Mechanism | Status |
| --- | --- | --- |
| Fan Tower | `M106` per height band via custom G-code | built, untested |
| Speed Tower | modifier volumes with speed overrides | built, untested |
| Tolerance Test | pure geometry, negative cylinders | built, untested |
| Retraction Tower | — | dropped, see [`DEVINFO.md`](../DEVINFO.md#ideas-ruled-out-and-why) |

Next: verify the three against a running slicer and close out the open geometry questions,
then add bridging and overhang tests.

## Phase 2 — Fit and tolerances

Building on the Tolerance Test: thread gauges, print-in-place hinge tests, press-fit
samples. Depends on the geometry semantics that Phase 1 testing will confirm.

## Phase 3 — Parametric utility objects

Boxes and inserts, cable clips, wall mounts, spool holders. Eleven primitives plus
negative volumes make genuine parametric modelling viable.

On Gridfinity specifically: the original is licensed CC BY-NC-SA. The non-commercial
clause needs clarifying before investing effort there.

## Phase 4 — Print aids

Purge and prime blocks, draft shields, sacrificial towers, preconfigured support blockers.
`VolumeType.SupportBlocker` and `SupportEnforcer` exist, which is the piece this depends
on.

## Phase 5 — Filament database — blocked

Requested, but not buildable against the current API. Four independent blockers, any one
of which is sufficient on its own:

1. **No persistence.** `os` and `io` are absent and file access is confined to the
   plugin's own directory. Since bundles are distributed signed, writing there would
   invalidate the signature. There is no sanctioned place for plugin state to survive a
   restart.
2. **No events.** A plugin runs only when clicked. There is no post-slice hook, so
   material used cannot be deducted automatically — which is the core of the feature.
3. **No network.** No online database, no sync, no Spoolman integration.
4. **Wrong category.** `project.plugin` creates objects in a project. A data manager is a
   different kind of thing; this is not a missing feature so much as a missing plugin
   type.

A fifth blocker has already fallen away: the dialog does support `string` parameters,
contrary to the prose documentation. That is still not enough, as there are no list or
table controls.

**What would unblock it:** a persistent key-value store for plugins, a post-slice hook,
and list or enum parameters in the dialog. The first two are the hard requirements; it is
worth revisiting once they exist.

Realistically not in this alpha. Anyone who needs spool management today is better served
by [Spoolman](https://github.com/Donkie/Spoolman), which would also be the more sensible
integration target than a from-scratch reimplementation once the API allows it.
