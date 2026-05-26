# Sintesi operativa - robot picker NIR

Aggiornato: 2026-05-26

## Situazione

Il progetto attuale e' una selezionatrice NIR con scarto pneumatico.

La cartella `robot/` aggiunta contiene un tentativo vecchio/parziale:

- `sensoreNIR.txt` prova a costruire stringhe target per robot
- `gestioneencoder.txt` e `processing.txt` sono versioni ridotte/vecchie dei POU esistenti
- `gestionerobot.txt` e' vuoto

Conclusione:

```text
non esiste ancora un programma robot funzionante nel materiale ricevuto
```

Pero' il progetto attuale contiene gia' la parte piu' importante da riusare:

```text
NIR LLA -> classificazione materiali -> encoder conveyor -> ritardo attuatore
```

## Cosa aveva provato a fare il vecchio tentativo

Dentro `robot/sensoreNIR.txt` viene costruita una stringa:

```text
@id,x_pick,y_pick,z_pick,angle,wait_pick,x_drop,y_drop,z_drop,wait_drop,#
```

Il senso sembra essere:

```text
materiale attivo -> coordinate presa -> coordinate deposito -> trigger robot
```

Ma il tentativo ha problemi strutturali:

- genera coordinate per singola traccia NIR, non per oggetto fisico
- non costruisce una coda target
- non usa l'encoder in modo robusto per il robot
- non gestisce finestra di presa
- non gestisce ready/busy/ack/done/fail del robot
- non contiene il programma `Gestione_Robot`
- usa variabili non presenti nel repo attuale (`X_BOX`, `String_ToSend`, `Trig`, ecc.)

## Direzione corretta

La "mente" del macchinario deve essere:

```text
scan NIR
-> gruppi di tracce/materiali
-> oggetti fisici
-> target robot
-> coda target
-> tracking con encoder
-> finestra di presa
-> comando robot
-> feedback robot
```

Non:

```text
traccia NIR singola -> stringa robot immediata
```

## Cosa e' stato preparato

### Documentazione

| Documento | Scopo |
|---|---|
| `analisi-preliminare.md` | Analisi del materiale in `robot/` |
| `roadmap-implementazione.md` | Roadmap completa verso programma reale |
| `checklist-dati-mancanti.md` | Dati da recuperare in azienda |
| `mvp-tecnico.md` | Primo MVP tecnico |
| `fase-1-specifica-implementazione.md` | Specifica implementabile della Fase 1 |
| `protocollo-robot-provvisorio.md` | Protocollo dedotto/proposto |
| `scaffold-st-note-integrazione.md` | Come importare/testare lo scaffold |

### Scaffold codice

Cartella:

```text
src/Robot/
```

File:

| File | Scopo |
|---|---|
| `ROBOT_TARGET.EXP` | Tipo target |
| `ROBOT_STATE.EXP` | Tipo stato robot |
| `ROBOT_GLOBALS.EXP` | GVL robot |
| `ROBOT_OBJECT_BUILDER.EXP` | Crea target da NIR |
| `ROBOT_QUEUE.EXP` | Avanza target e finestra presa |
| `GESTIONE_ROBOT.EXP` | Simulatore robot |
| `ROBOT_TEST_INPUT.EXP` | Crea target manuale senza NIR |

Stato scaffold:

```text
bozza non collegata ai task TwinCAT
non compilata in TwinCAT
non pronta per produzione
utile come base Fase 1
```

## Cosa possiamo fare subito

### 1. Test offline in TwinCAT con robot simulato

Importare lo scaffold e testare:

```text
ROBOT_ENABLED := TRUE
ROBOT_SIMULATION := TRUE
ROBOT_TEST_INPUT_ENABLED := TRUE
ROBOT_TEST_CREATE_TARGET := TRUE
```

Obiettivo:

```text
target creato -> entra in finestra -> robot simulato busy -> picked
```

Questo test non richiede NIR reale e non richiede robot reale.

### 2. Test con NIR reale ma robot simulato

Abilitare `Robot_ObjectBuilder`.

Obiettivo:

```text
materiale attivo visto dal NIR -> target in ROBOT_TARGETS[]
```

Serve impostare:

- `MATERIALI_ATTIVI[]`
- `MATERIALI_ATTIVI_BOX[]`
- `ROBOT_TRACK_PITCH_MM`
- finestra presa provvisoria

### 3. Test robot reale solo quando abbiamo protocollo

Prima di comandare il robot reale servono:

- protocollo controller
- ACK
- ready/busy/error
- quote robot
- safety

## Cosa manca davvero

### Bloccante per robot reale

| Mancanza | Impatto |
|---|---|
| `GestioneRobot` originale | Non sappiamo come parlava col robot |
| protocollo robot | Non possiamo inviare comandi reali |
| ACK/stati robot | Rischio doppi comandi o comandi persi |
| quote meccaniche | Coordinate pick non affidabili |
| safety/I/O | Non si puo' andare in automatico |

### Non bloccante per Fase 1

Queste cose si possono simulare:

- robot reale
- ACK reale
- coordinate definitive
- box definitivi
- finestra presa definitiva

## Ordine operativo consigliato

1. Importare scaffold in TwinCAT in copia di test.
2. Compilare con `ROBOT_ENABLED := FALSE`.
3. Correggere eventuali incompatibilita' TwinCAT 2.
4. Attivare robot simulato.
5. Provare `Robot_TestInput`.
6. Collegare `Robot_ObjectBuilder` al NIR.
7. Verificare target reali generati dal sensore.
8. Solo dopo implementare protocollo robot reale.

## Rischio principale

Il rischio non e' "TwinCAT non ce la fa".

Il rischio principale e':

```text
confondere una traccia NIR con un pezzo prendibile
```

Per un robot serve un oggetto fisico affidabile.

Quindi il cuore del progetto e':

```text
object builder + queue + tracking + handshake
```

## Decisione tecnica consigliata

Procedere con Fase 1:

```text
simulazione target e robot dentro PLC
```

Poi Fase 2:

```text
NIR reale -> target reali
```

Poi Fase 3:

```text
protocollo robot reale
```

Questo riduce il rischio e permette di capire presto se la logica target funziona.

