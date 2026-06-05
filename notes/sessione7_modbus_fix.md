# Sessione 7 — 2026-05-28 / 2026-06-05 — Fix Modbus "Macchina in lavorazione"

## Problema iniziale
Il tecnico segnalava che dal gestionale SCADA le macchine risultavano spente o mostravano dati identici tra loro.

## Diagnosi

### Dati identici tra macchine — FALSO ALLARME
Verificato con ModMaster direttamente su .31 e .33:
- .31: peso=1703.1 kg, ore=2461, ricetta=1
- .33: peso=6058.1 kg (overflow valore reale), ore=17719, ricetta=3
I dati sono diversi. Il tecnico confrontava valori del gestionale che usava un criterio di rilevamento sbagliato.

### Bug registro 12327/12328 — CONFERMATO
Codice originale in PROCESSING (tutte le macchine):
```pascal
IF ENABLE THEN Modbus_Area[39] := 1; ELSE Modbus_Area[39] := 0; END_IF;
```
- ENABLE = FALSE in funzionamento normale (= non bloccata da licenza)
- Scriveva 0 quando la macchina lavorava
- Il gestionale interpretava 0 come "non pronta" → macchine sembravano spente

### Offset +1 Daniele
Daniele (SELECT Informatica) usa indirizzamento 1-based. Aggiunge +1 a tutti i nostri indirizzi.
- Nostro Modbus_Area[39] = registro 12327 (Beckhoff) = registro **12328** (Daniele)
- Daniele usava KG_MINUTI (12329) come criterio principale → fragile su macchine anziane

## Fix applicato (.33 e .34)
```pascal
IF (SPEED > 0.5 AND NIR_ATTIVO AND DIAGNOSTICA_OK) THEN Modbus_Area[39] := 1; ELSE Modbus_Area[39] := 0; END_IF;
```
- Applicato via Online Change (macchina non fermata)
- Boot project salvato su entrambe
- Verificato con ModMaster: 412328 = 1 mentre macchina lavora ✅

## Coordinamento con Daniele
- Marco ha comunicato a Daniele il significato del registro 12328 (1=in lavorazione, 0=ferma)
- Daniele ha aggiornato il gestionale: verifica 12328 come criterio primario, fallback su KG/min
- **Risultato: tutte e 4 le macchine risultano in lavoro nel gestionale** ✅ (confermato via email 2026-06-04)

## Problemi identificati ma non risolti

### KG_MINUTI = 0 su .33 (e probabilmente .34)
- PESO_TOTALE = 3.276.305 kg (anni di accumulo)
- REAL 32-bit a quella grandezza ha precisione ~0.4 kg
- Incrementi per minuto < 0.4 kg → non registrati → KG_MINUTI resta 0
- Modbus_Area[41] (PESO_TOTALE*10) va in overflow WORD → valore garbage nel gestionale
- Soluzione definitiva: REAL → LREAL (richiede rebuild offline)
- Non urgente: il registro 12328 risolve il rilevamento indipendentemente da KG_MINUTI

### Fix da applicare su .31 e .32
Stessa modifica, stessa procedura. Attualmente funzionano con fallback KG/min.

## File sorgente .33 analizzato
Caricato dall'utente in sessione:
- `processing33.txt` — Processing completo .33
- `gestione_encoder.txt` — Gestione encoder
- `gestione_espulsione.txt` — Gestione espulsione + diagnostica I/O
- `sensorenir.txt` — Sensore NIR completo
