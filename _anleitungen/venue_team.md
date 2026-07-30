# Hyper-Irrealismus III — Anleitung für das Venue Team

---

## Geräteübersicht

| Gerät | Beschreibung | Wichtig |
|-------|-------------|---------|
| **WLAN-Router** | Verbindet alle Geräte miteinander | Muss **als erstes** an sein |
| **Server-PC** | Läuft die Ausstellungssoftware | Startet nach dem Router |
| **HTC Vive Focus Vision** | VR-Brillen | Über Nacht an Ladekabel! |

---

## Morgens starten — immer in dieser Reihenfolge

### 1. WLAN-Router einschalten
- Stecker einstecken oder Knopf drücken
- Warten bis die LED **grün und konstant** leuchtet (ca. 1 Minute)

### 2. Server-PC einschalten
- Power-Knopf drücken, Windows hochfahren lassen
- Warten bis der Desktop vollständig geladen ist

### 3. Server-Software starten
- Auf dem Desktop: **`start_server.bat`** doppelklicken
- Ein Fenster öffnet sich → Klick auf **„Als Server starten"**
- Oben rechts erscheint ein kleines Feld mit Szenen-Name und Timer

✅ **Server läuft** wenn oben rechts ein Szenen-Name sichtbar ist.

### 4. VR-Brillen einschalten
- Jede Brille: Power-Knopf seitlich **3 Sekunden** gedrückt halten
- Brille startet, erkennt den Raum automatisch
- Nach ca. 30 Sekunden ist die erste Ausstellungsszene sichtbar
- Andere Brillen erscheinen als farbige Figuren im Raum

> Brillen nacheinander einschalten und je ca. 20 Sekunden warten.

---

## Abends herunterfahren

### 1. Brillen ausschalten und laden
- Power-Knopf seitlich gedrückt halten bis Display erlischt
- USB-C Ladekabel anstecken

### 2. Server-Software schließen
- Fenster mit **X** oben rechts schließen

### 3. PC ausschalten
- Windows-Start → **Herunterfahren**

### 4. Router (falls gewünscht)
- Stecker ziehen

---

## Szene manuell wechseln

Wenn du früher zur nächsten Szene möchtest oder der Timer nicht weiterläuft:

→ Im Server-Fenster: **„Nächste Szene [N]"** klicken
→ Oder Taste **N** auf der Tastatur

Alle Brillen wechseln gleichzeitig.

---

## PC-Client (optional — für Monitoring oder Demo)

Läuft ein Desktop-PC als FPS-Client (zweites Fenster oder zweiter Rechner), kann dieser Szenen navigieren ohne das Server-Fenster anzufassen:

| Taste | Funktion |
|-------|---------|
| **Q** | Vorherige Szene (+ Standalone-Modus aktivieren) |
| **E** | Nächste Szene (+ Standalone-Modus aktivieren) |
| WASD / Pfeiltasten | Bewegen |
| Maus | Umsehen |
| ESC | Maus freigeben |

> Q und E aktivieren automatisch Standalone — der PC-Client läuft dann unabhängig vom Server.

---

## Brille ohne Server betreiben (Standalone-Modus)

Die Brillen können auch **ohne Server-PC** laufen — nützlich für Tests oder wenn der Server nicht verfügbar ist.

**Standalone aktivieren:**
1. Brille einschalten, App starten
2. Orange Board erscheint: „Keine Verbindung"
3. **Beliebigen Controller-Button drücken** → Board verschwindet, Standalone-Modus ist aktiv
4. Szenen wechseln jetzt automatisch nach dem eingestellten Timer

**Manuell zur nächsten Szene springen:**
→ **B-Taste** (rechter Controller) oder **Y-Taste** (linker Controller) drücken

> Im Standalone-Modus sehen die Brillen keine anderen Spieler — jede läuft für sich allein.
> Für die Ausstellung mit mehreren Besuchern immer den Server verwenden.

---

## Troubleshooting

### Brille zeigt keine anderen Spieler / ist allein in der Szene
```
Prüfen:
  → Router an? LED grün und konstant?
  → Server-Fenster offen? Szenen-Name oben rechts sichtbar?

Lösung:
  → Brille ausschalten, 10 Sekunden warten, wieder einschalten
```

### Brille zeigt oranges Board „Keine Verbindung"
```
Bedeutet: Brille hat keinen Server gefunden.
Lösung A (mit Server):
  → Server prüfen (läuft start_server.bat? Szene sichtbar?)
  → Warten — Brille versucht alle 5 Sekunden neu zu verbinden
  → Bei Erfolg: Board verschwindet automatisch

Lösung B (ohne Server, Demo-Betrieb):
  → Beliebigen Controller-Button drücken → Standalone-Modus startet
```

### Eine Brille hängt in einer falschen Szene
```
Lösung:
  → Im Server-Fenster „Nächste Szene" klicken (ggf. mehrmals)
  ODER:
  → Brille aus- und einschalten → landet automatisch in der aktuellen Szene
```

### Server-Fenster reagiert nicht
```
Lösung:
  1. Strg+Shift+Esc → Task-Manager → „hyper3_server" beenden
  2. start_server.bat erneut doppelklicken → „Als Server starten"
  3. Alle Brillen neu starten (verbinden sich automatisch)
```

### Alle Brillen verlieren gleichzeitig die Verbindung
```
Ursache: WLAN-Problem oder Server abgestürzt
Lösung:
  1. Router aus → 30 Sekunden warten → wieder an
  2. Server neu starten (siehe oben)
  3. Brillen einzeln neu starten
```

### App nicht auf der Brille sichtbar
```
Lösung:
  → Menü-Taste → Apps → Alle Apps → „Unbekannte Quellen"
  → „Hyper-Irrealismus III" antippen
  Falls nicht vorhanden: Dev Team kontaktieren
```

---

## Notfallkontakt

| Person | Wofür |
|--------|-------|
| **Dev Team (Pablo)** | App-Probleme, Abstürze, Brille findet App nicht |

---

## Spickzettel

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
MORGENS:
  1. Router an → grüne LED abwarten
  2. PC an → Desktop abwarten
  3. start_server.bat → „Als Server starten"
  4. Brillen einzeln einschalten

ABENDS:
  1. Brillen aus + laden
  2. Server-Fenster schließen (X)
  3. PC herunterfahren

SZENE WECHSELN:
  → „Nächste Szene" im Server-Fenster  oder  Taste N

BRILLE HÄNGT:
  → Aus- und einschalten → landet automatisch richtig

KEIN SERVER (Standalone):
  → Beliebigen Button drücken → läuft alleine durch
  → B / Y drücken → nächste Szene überspringen
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
