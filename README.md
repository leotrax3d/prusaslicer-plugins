# PrsslcrPlugins

Eine Sammlung von Lua-Plugins für **PrusaSlicer 3.0** (aktuell frühe Alpha).

Mit PrusaSlicer 3.0 hat Prusa erstmals ein offizielles Plugin-System vorgestellt. Dieses
Repository ist der Ort, an dem wir eigene Plugins dafür entwickeln, testen und
veröffentlichen.

> ⚠️ **Status: experimentell.** PrusaSlicer 3.0 ist Alpha, und die Lua-API ist von Prusa
> ausdrücklich als *experimentell* markiert — Breaking Changes sind angekündigt und werden
> laut Prusa auch längerfristig vorkommen. Alles hier kann mit jedem Alpha-Release brechen.

---

## Was das Plugin-System kann (Stand Alpha 11)

Was wir aus den öffentlichen Ankündigungen und Release Notes sicher wissen:

- **Sprache: Lua.** Prusa hat Lua gewählt, weil es sich sauber sandboxen lässt.
- **Sandbox.** Die Module `os` und `io` stehen nicht zur Verfügung; Dateizugriff ist auf das
  eigene Plugin-Verzeichnis beschränkt. Kein Netzwerk, keine fremden Prozesse.
- **Ein Plugin-Typ: `project.plugin`.** Er erzeugt neue Objekte im Slicer-Projekt. Die
  mitgelieferten Kalibrier-Plugins (*Flow Tower*, *Temperature Tower*) legen so ein komplettes
  Projekt mit Einstellungen und Geometrie an. Weitere Typen sind laut Prusa vorgesehen, aber
  noch nicht verfügbar.
- **Bundles mit Manifest.** Mehrere Plugins liegen zusammen in einem Bundle-Verzeichnis mit
  einer `manifest.json`. Pflichtfelder: `id` (Reverse-DNS), `name`, `license`, `version`,
  `author`, `min_slicer_version`, `required_apis`. Optional: `description`, `category`,
  `web`, `repo`.
- **Deklarative Parameter-Dialoge.** Ein Plugin deklariert in `info.params` seine Eingaben
  (Typen: `float`, `int`, `bool`); PrusaSlicer baut daraus automatisch den Dialog und übergibt
  die Werte an `execute(params)`.
- **Signierte Distribution.** Bundles werden als ZIP mit einem RSA-Schlüsselpaar signiert.
- **Marketplace in Arbeit.** Geplant sind Ein-Klick-Installation, Bewertungen und Listen
  vertrauenswürdiger Autoren. Von Prusa eingereichte Plugins werden geprüft.

### Ein minimales Plugin

```lua
info = {
    id = "com.prusa3d.slicer.hello_world",
    type = "project.plugin",
    title = "Hello world",
    menu = "Minimal/Hello world",
    params = {{name = "num", label = "Your lucky number", type = "int", default = 42}}
}

function execute(params)
    print("Hello no " .. params.num .. "!")
end
```

### Was (noch) nicht geht

Wichtig für die Roadmap — folgendes ist mit dem heutigen Stand **nicht** möglich:

- Kein Post-Processing von G-Code über die Plugin-API (dafür weiterhin externe
  Post-Processing-Skripte).
- Kein Netzwerkzugriff, also keine Cloud-Anbindung, kein Upload, keine Online-Datenbank.
- Kein Zugriff auf beliebige Dateien, also kein Import/Export eigener Formate.
- Keine eigenen Zeichenwerkzeuge oder Gizmos in der 3D-Ansicht.
- Keine Reaktion auf Ereignisse — ein Plugin läuft nur, wenn der Nutzer den Menüeintrag klickt.

Der Umfang der Geometrie-Funktionen ist der große offene Punkt. Bekannt sind bisher
`load_stl` und `emboss_svg`; die vollständige Referenz steht unter
<https://prusa.io/ps-plugins/>. Was wir davon selbst verifiziert haben, sammeln wir in
[`docs/api-notes.md`](docs/api-notes.md).

---

## Repository-Aufbau

```
plugins/<bundle-id>/       ein Plugin-Bundle mit manifest.json und Lua-Skripten
docs/                      API-Notizen und Entwickler-Doku
```

Aktuell enthält das Repo noch keine Plugins — wir stehen ganz am Anfang.

## Entwicklung

Neues Bundle anlegen (interaktiver Assistent, erzeugt Dateien und `manifest.json`):

```bash
<installation_path>/PrusaSlicer plugin init com.example.my-plugin
```

Zum Testen kommt das Bundle nach `(datadir)/lua` bzw. `(configdir)/lua`; danach
PrusaSlicer neu starten, damit der Menüeintrag erscheint.

Signieren für die Verteilung:

```bash
# einmalig ein Schlüsselpaar erzeugen
<installation_path>/PrusaSlicer plugin keygen -P the.author.private.pem -p the.author.public.pem

# Bundle signieren
<installation_path>/PrusaSlicer plugin sign -P the.author.private.pem com.example.my-plugin
```

> Private Schlüssel gehören **nicht** in dieses Repository.

## Mitmachen

Ideen, Bugreports und Pull Requests sind willkommen. Da die API sich bewegt, bitte immer
angeben, mit welcher Alpha-Version getestet wurde.

## Lizenz

Siehe [LICENSE](LICENSE).

## Quellen

- [PrusaSlicer 3.0.0-alpha11 Release Notes](https://github.com/prusa3d/PrusaSlicer/releases/tag/version_3.0.0-alpha11)
- [PrusaSlicer 3.0 Preview – Built for the Future of 3D Printing (Prusa Blog)](https://blog.prusa3d.com/prusaslicer-3-0-preview-built-for-the-future-of-3d-printing_137672/)
- [Plugin_API.md im PrusaSlicer-Repository](https://github.com/prusa3d/PrusaSlicer/blob/version_3.0.0-alpha11/doc/Plugin_API.md)
- [Plugin-API-Referenz](https://prusa.io/ps-plugins/)
