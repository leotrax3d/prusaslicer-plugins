# Lua-API — Notizen

Sammelstelle für alles, was wir über die PrusaSlicer-3.0-Plugin-API herausfinden.
Primärquellen: [`doc/Plugin_API.md`](https://github.com/prusa3d/PrusaSlicer/blob/version_3.0.0-alpha11/doc/Plugin_API.md)
und die [API-Referenz](https://prusa.io/ps-plugins/). Alles hier gilt für Alpha 11, sofern
nicht anders vermerkt.

## Gesichert aus der offiziellen Doku (Alpha 11)

- Plugin-Typ: `project.plugin`, `required_apis: {"project.plugin": "1.0.0"}`
- Ein Plugin besteht aus einer globalen Tabelle `info` (`id`, `type`, `title`, `menu`,
  `params`) und einer Funktion `execute(params)`.
- Parameter-Typen: `float`, `int`, `bool`.
- Manifest-Pflichtfelder: `id`, `name`, `license`, `version`, `author`,
  `min_slicer_version`, `required_apis`. Optional: `description`, `category`, `web`, `repo`.
- Sandbox: `os` und `io` fehlen; Dateizugriff nur im eigenen Plugin-Verzeichnis.
- Bekannte API-Funktionen: `load_stl`, `emboss_svg`, `require`.
- Plugin-Ordner: `(datadir)/lua` bzw. `(configdir)/lua`.

## Offene Fragen

- Welche Geometrie-Funktionen gibt es über `load_stl` / `emboss_svg` hinaus? Lassen sich
  Meshes prozedural aus Vertices/Faces bauen, oder nur fertige STLs laden und transformieren?
- Wie setzt ein Plugin Druckeinstellungen im erzeugten Projekt (Flow/Temp Tower tun das)?
- Gibt es Modifier-Meshes, Höhenbereich-Modifikatoren oder Per-Objekt-Settings?
- Wie werden Objekte platziert, skaliert und rotiert?
- Was macht `params` über `float`/`int`/`bool` hinaus — Enums, Strings, Bedingungen?
- Wohin geht die Ausgabe von `print()`, und wie debuggt man sinnvoll?
- Exakte Pfade von `datadir`/`configdir` unter Windows, macOS und Linux.

## Verifizierte Erkenntnisse aus eigenen Tests

_(noch keine — hier bitte immer die getestete Alpha-Version dazuschreiben)_
