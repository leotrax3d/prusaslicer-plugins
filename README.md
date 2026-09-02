# PrsslcrPlugins

Eine Sammlung von Lua-Plugins für **PrusaSlicer 3.0** (aktuell frühe Alpha).

Mit PrusaSlicer 3.0 hat Prusa erstmals ein offizielles Plugin-System vorgestellt. Dieses
Repository ist der Ort, an dem wir eigene Plugins dafür entwickeln, testen und
veröffentlichen.

> ⚠️ **Status: experimentell.** PrusaSlicer 3.0 ist Alpha, und die Lua-API ist von Prusa
> ausdrücklich als *experimentell* markiert — Breaking Changes sind angekündigt. Alles hier
> kann mit jedem Alpha-Release brechen.
>
> Die Plugins in diesem Repo sind bislang **nicht am laufenden Slicer getestet**. Siehe
> [Testing](#testing).

---

## Plugins

### `com.prsslcr.calibration` — Calibration Extras

Ergänzt Prusas mitgelieferte Kalibrier-Plugins (Flow Tower, Temperature Tower):

| Plugin | Menü | Was es tut |
|---|---|---|
| **Fan Tower** | Calibration/Fan Tower | Turm mit dünner Nebensäule; schaltet die Lüfterdrehzahl pro Höhenband per `M106`. Die Säule kühlt zwischen den Schichten kaum ab und zeigt schlechte Kühlung zuerst. |
| **Speed Tower** | Calibration/Speed Tower | Turm, dessen Druckgeschwindigkeit pro Höhenband über Modifier-Volumes überschrieben wird. |
| **Tolerance Test** | Calibration/Tolerance Test | Platte mit einer Lochreihe steigenden Spiels plus passendem Prüfstift — ermittelt das nötige Spiel für Passungen. |

Ein Retraction Tower war geplant und wurde bewusst verworfen; die Begründung steht in
[`docs/api-notes.md`](docs/api-notes.md#warum-es-keinen-retraction-tower-gibt).

Die weitere Planung — inklusive der blockierten Filament-Datenbank — steht in
[`docs/roadmap.md`](docs/roadmap.md).

---

## Was das Plugin-System kann

Zusammengefasst; die belastbare Referenz mit allen Signaturen ist
[`docs/api-notes.md`](docs/api-notes.md).

- **Sprache: Lua**, in einer Sandbox ohne `os`, `io` und Netzwerk. Dateizugriff nur im
  eigenen Plugin-Verzeichnis.
- **Ein Plugin-Typ: `project.plugin`.** Er erzeugt Objekte im Slicer-Projekt. Weitere Typen
  sind laut Prusa vorgesehen, aber noch nicht verfügbar.
- **Bundles mit Manifest.** Mehrere Plugins liegen zusammen in einem Verzeichnis mit einer
  `manifest.json`. Pflichtfelder: `id` (Reverse-DNS), `name`, `license`, `version`,
  `author`, `min_slicer_version`, `required_apis`.
- **Deklarative Dialoge.** Ein Plugin deklariert in `info.params` seine Eingaben; PrusaSlicer
  baut daraus den Dialog. Vier Typen: `string`, `float`, `int`, `bool`.
- **Prozedurale Geometrie.** Elf Primitive (`make_cube`, `make_cylinder`, `make_torus`,
  `make_snap`, …) sowie `load_stl`, `emboss_svg` und `emboss_text`.
- **Negative- und Modifier-Volumes.** Boolesche Abzüge und ortsabhängige Einstellungen,
  dazu `SupportBlocker` und `SupportEnforcer`.
- **Custom G-Code pro Schicht** via `insert_layer_custom_gcode` — der Hebel für alles, was
  Firmware-Zustand ist (Temperatur, Lüfter).
- **Signierte Distribution** als ZIP mit RSA-Schlüsselpaar. Ein Marketplace ist in Arbeit.

### Was nicht geht

- Kein Post-Processing von G-Code (dafür weiterhin externe Skripte).
- Kein Netzwerk, kein Zugriff auf beliebige Dateien, keine Persistenz über Neustarts hinweg.
- Keine Events — ein Plugin läuft nur, wenn der Nutzer den Menüeintrag klickt.
- Keine eigenen Gizmos in der 3D-Ansicht.
- Im Dialog keine Listen, Enums oder Min/Max-Grenzen.

---

## Ein minimales Plugin

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

## Repository-Aufbau

```
plugins/<bundle-id>/    ein Plugin-Bundle mit manifest.json und Lua-Skripten
docs/api-notes.md       rekonstruierte API-Referenz und offene Fragen
docs/roadmap.md         Planung
```

## Installation

Bundle-Ordner aus `plugins/` nach `(datadir)/lua` bzw. `(configdir)/lua` kopieren und
PrusaSlicer neu starten. Die Menüeinträge werden beim Start aus dem Ordner aufgebaut.

Die konkreten Pfade pro Betriebssystem tragen wir nach, sobald sie verifiziert sind.

## Entwicklung

Neues Bundle anlegen (interaktiver Assistent):

```bash
<installation_path>/PrusaSlicer plugin init com.example.my-plugin
```

Signieren für die Verteilung:

```bash
# einmalig ein Schlüsselpaar erzeugen
<installation_path>/PrusaSlicer plugin keygen -P the.author.private.pem -p the.author.public.pem

# Bundle signieren
<installation_path>/PrusaSlicer plugin sign -P the.author.private.pem com.example.my-plugin
```

> Private Schlüssel gehören **nicht** in dieses Repository.

## Testing

Syntaxprüfung aller Plugins:

```bash
luac -p plugins/*/*.lua
```

Das ist derzeit alles, was sich automatisiert prüfen lässt. Die Lua-Umgebung des Slicers
(`api`, `VolumeType`, das Preset-System) existiert außerhalb von PrusaSlicer nicht, also
muss jedes Plugin von Hand im Slicer geprüft werden. Bitte bei Rückmeldungen immer die
getestete Alpha-Version angeben.

## Lizenz

Siehe [LICENSE](LICENSE).

## Quellen

- [Plugin_API.md im PrusaSlicer-Repository](https://github.com/prusa3d/PrusaSlicer/blob/version_3.0.0-alpha11/doc/Plugin_API.md)
- [ProjectApi.cpp — die eigentliche API-Referenz](https://github.com/prusa3d/PrusaSlicer/blob/version_3.0.0-alpha11/src/slic3r-shared/src/Slic3r/App/Lua/ProjectApi.cpp)
- [PrusaSlicer 3.0.0-alpha11 Release Notes](https://github.com/prusa3d/PrusaSlicer/releases/tag/version_3.0.0-alpha11)
- [Plugin-API-Referenz](https://prusa.io/ps-plugins/)
