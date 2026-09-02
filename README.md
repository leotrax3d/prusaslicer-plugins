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
- **Sandbox.** Plugins haben keinen Zugriff auf das Dateisystem, kein Netzwerk und können
  keine anderen Prozesse starten. Sie sehen nur das geladene Projekt. Rechte werden pro
  Plugin auf das Nötige beschränkt.
- **Discovery über den Plugin-Ordner.** PrusaSlicer scannt beim Start einen Plugin-Ordner
  und baut die Menüeinträge dynamisch daraus auf.
- **Deklarative Parameter-Dialoge.** Ein Plugin deklariert seine Eingabewerte; PrusaSlicer
  generiert daraus automatisch den Eingabedialog und übergibt die Werte beim Ausführen.
- **Aktueller Plugin-Typ: Objekte programmatisch erzeugen.** Die mitgelieferten
  Kalibrier-Plugins (*Flow Tower*, *Temperature Tower*) legen ein komplettes Projekt mit
  passenden Einstellungen und generierter Geometrie an. Die Architektur ist laut Prusa auf
  weitere Plugin-Typen ausgelegt, diese sind aber noch nicht verfügbar.
- **Marketplace in Arbeit.** Geplant sind Ein-Klick-Installation, Bewertungen, kryptografische
  Signaturen und Listen vertrauenswürdiger Autoren. Von Prusa eingereichte Plugins werden
  geprüft.

### Was (noch) nicht geht

Wichtig für die Roadmap — folgendes ist mit dem heutigen Stand **nicht** möglich:

- Kein Post-Processing von G-Code über die Plugin-API (dafür weiterhin externe
  Post-Processing-Skripte).
- Kein Netzwerkzugriff, also keine Cloud-Anbindung, kein Upload, keine Online-Datenbank.
- Kein Dateisystemzugriff, also kein Import/Export eigener Dateiformate.
- Keine eigenen Zeichenwerkzeuge oder Gizmos in der 3D-Ansicht.

Die exakten API-Signaturen sind bislang nicht offiziell dokumentiert. Referenz sind die
mitgelieferten Kalibrier-Plugins im PrusaSlicer-Installationsverzeichnis — wir halten unsere
Erkenntnisse in [`docs/api-notes.md`](docs/api-notes.md) fest, sobald wir sie verifiziert haben.

---

## Repository-Aufbau

```
plugins/<plugin-name>/     ein Plugin, installierbar durch Kopieren in den Plugin-Ordner
docs/                      API-Notizen und Entwickler-Doku
```

Aktuell enthält das Repo noch keine Plugins — wir stehen ganz am Anfang.

## Installation

1. PrusaSlicer 3.0 Alpha installieren.
2. Den gewünschten Ordner aus `plugins/` in den Plugin-Ordner von PrusaSlicer kopieren.
3. PrusaSlicer neu starten — das Plugin erscheint im Menü.

Der genaue Pfad des Plugin-Ordners unterscheidet sich je nach Betriebssystem und wird hier
ergänzt, sobald wir ihn auf allen drei Plattformen verifiziert haben.

## Mitmachen

Ideen, Bugreports und Pull Requests sind willkommen. Da die API sich bewegt, bitte immer
angeben, mit welcher Alpha-Version getestet wurde.

## Lizenz

Siehe [LICENSE](LICENSE).

## Quellen

- [PrusaSlicer 3.0.0-alpha11 Release Notes](https://github.com/prusa3d/PrusaSlicer/releases/tag/version_3.0.0-alpha11)
- [PrusaSlicer 3.0 Preview – Built for the Future of 3D Printing (Prusa Blog)](https://blog.prusa3d.com/prusaslicer-3-0-preview-built-for-the-future-of-3d-printing_137672/)
