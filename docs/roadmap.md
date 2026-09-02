# Roadmap

Alles hier steht unter dem Vorbehalt einer experimentellen API. Was heute unmöglich ist,
kann mit dem nächsten Alpha-Release möglich werden — und umgekehrt.

## Die Randbedingung

Es gibt genau einen Plugin-Typ, `project.plugin`, und der folgt immer demselben Ablauf:

> Nutzer klickt Menüeintrag → Dialog aus `string`/`float`/`int`/`bool` → Plugin erzeugt
> Objekte und Einstellungen im Projekt.

Kein Netzwerk, kein freier Dateizugriff, keine Events, kein G-Code-Post-Processing. Jede
Idee muss durch dieses Nadelöhr passen.

## Phase 0 — API kartieren ✅

Erledigt, allerdings anders als geplant: statt Blackbox-Tests am laufenden Slicer haben wir
die API direkt aus `ProjectApi.cpp` und `PluginDialog.cpp` rekonstruiert. Ergebnis in
[`api-notes.md`](api-notes.md). Wichtigste Erkenntnis: die API kann deutlich mehr als die
Prosa-Doku andeutet — elf prozedurale Primitive, Negative- und Modifier-Volumes und
Custom-G-Code pro Schicht.

Offen bleibt eine Handvoll Punkte, die sich nur am laufenden Slicer klären lassen
(Rotations-Pivot, Ursprung der Primitive, gültige Settings-Keys).

## Phase 1 — Kalibrierung vervollständigen 🟡

Prusa liefert Flow Tower und Temperature Tower mit. Wir ergänzen das Bundle
`com.prsslcr.calibration`:

| Plugin | Verfahren | Status |
|---|---|---|
| Fan Tower | `M106` pro Höhenband via Custom-G-Code | ungetestet gebaut |
| Speed Tower | Modifier-Volumes mit Speed-Overrides | ungetestet gebaut |
| Tolerance Test | reine Geometrie, Negative-Zylinder | ungetestet gebaut |
| Retraction Tower | — | **verworfen**, Begründung in [`api-notes.md`](api-notes.md) |

Als Nächstes: am echten Slicer testen, dann Bridging- und Overhang-Test ergänzen.

## Phase 2 — Passform und Toleranzen

Aufbauend auf dem Tolerance Test: Gewinde-Testschrauben, Print-in-Place-Scharnier-Test,
Presspassungen. Braucht vor allem verifizierte Geometrie-Semantik aus Phase 1.

## Phase 3 — Parametrische Nutzobjekte

Boxen und Einsätze, Kabelclips, Wandhalter, Spulenhalter. Mit elf Primitiven plus
Negative-Volumes ist echte parametrische Konstruktion möglich.

> Zu Gridfinity: das Original steht unter CC BY-NC-SA. Die NC-Klausel klären, bevor dort
> Arbeit hineinfließt.

## Phase 4 — Druckhilfen

Purge- und Prime-Blöcke, Draft Shields, Opfertürme, vorkonfigurierte Support-Blocker.
`VolumeType.SupportBlocker` und `SupportEnforcer` existieren, das trägt.

## Phase 5 — Filament-Datenbank ⛔ blockiert

Gewünscht, aber mit dem aktuellen API-Stand nicht baubar. Vier unabhängige Blocker, von
denen jeder einzelne reicht:

1. **Keine Persistenz.** `os` und `io` fehlen; Dateizugriff nur im eigenen
   Plugin-Verzeichnis. Und da Bundles signiert verteilt werden, würde Schreiben dort die
   Signatur brechen. Es gibt keinen vorgesehenen Ort für Plugin-Zustand über Neustarts
   hinweg.
2. **Keine Events.** Ein Plugin läuft nur auf Klick. Kein Hook nach dem Slicen, also kein
   automatisches Abziehen des verbrauchten Materials — das Herzstück fehlt.
3. **Kein Netzwerk.** Keine Online-Datenbank, kein Sync, keine Spoolman-Anbindung.
4. **Falsche Kategorie.** `project.plugin` erzeugt Objekte im Projekt. Ein Datenmanager
   ist konzeptionell etwas anderes; hier fehlt kein Feature, hier fehlt ein Plugin-Typ.

Ein fünfter Blocker ist inzwischen weggefallen: die UI kann `string`-Parameter, entgegen
der Prosa-Doku. Für eine Datenbank reicht das trotzdem nicht — es gibt weiterhin keine
Listen und keine Tabellen.

**Woran wir erkennen, dass es losgehen kann:** ein persistenter Key-Value-Store für
Plugins, ein Hook nach dem Slicen, und Listen-/Enum-Parameter im Dialog. Erst wenn
mindestens die ersten beiden da sind, lohnt ein neuer Anlauf.

Realistisch nicht in dieser Alpha. Wer heute eine Spulenverwaltung braucht, ist mit
**Spoolman** besser bedient — das wäre auch nach einer API-Erweiterung eher der Partner
für ein Plugin als etwas, das wir nachbauen.
