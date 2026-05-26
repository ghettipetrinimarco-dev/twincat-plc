# Backlog operativo - robot picker NIR

Aggiornato: 2026-05-26

## P0 - Prima di mettere mano alla macchina reale

### P0.1 - Import TwinCAT in copia di test

Obiettivo:

```text
verificare che lo scaffold compili in TwinCAT 2 senza toccare la macchina reale
```

Passi:

1. Creare copia progetto TwinCAT.
2. Importare `ROBOT_TARGET.EXP`.
3. Importare `ROBOT_STATE.EXP`.
4. Importare `ROBOT_GLOBALS.EXP`.
5. Importare i PROGRAM robot.
6. Compilare con `ROBOT_ENABLED := FALSE`.

Esito atteso:

```text
compila oppure lista errori TwinCAT da correggere
```

### P0.2 - Test simulato senza NIR

Obiettivo:

```text
verificare coda target e robot simulato senza sensore e senza robot reale
```

Parametri:

```text
ROBOT_ENABLED := TRUE
ROBOT_SIMULATION := TRUE
ROBOT_TEST_INPUT_ENABLED := TRUE
ROBOT_TEST_CREATE_TARGET := TRUE
```

Esito atteso:

```text
target -> in_window -> sent -> picked
```

### P0.3 - Correzione incompatibilita' TwinCAT

Correggere eventuali errori su:

- conversione `BUFFER_SIZE` verso `UINT`
- `INT_TO_TIME`
- limiti array
- ordine import TYPE/GVL/PROGRAM
- nome POU duplicato/non valido

## P1 - Collegare NIR reale a target robot simulati

### P1.1 - Parametri minimi robot

Impostare provvisoriamente:

- `ROBOT_TRACK_PITCH_MM`
- `ROBOT_X_ORIGIN_MM`
- `ROBOT_PICK_Y_MM`
- `ROBOT_PICK_Z_MM`
- `ROBOT_PICK_WINDOW_START_IMP`
- `ROBOT_PICK_WINDOW_END_IMP`
- `ROBOT_MIN_WIDTH_TRACKS`
- `ROBOT_MAX_WIDTH_TRACKS`

### P1.2 - Materiale -> box

Configurare:

```text
MATERIALI_ATTIVI_BOX[index_materiale] := box
```

Per ogni materiale target.

### P1.3 - Test con un pezzo singolo

Obiettivo:

```text
un pezzo target sotto NIR crea un target in ROBOT_TARGETS
```

Da osservare:

- `ROBOT_TARGETS_DETECTED`
- `FirstTrack`
- `LastTrack`
- `CenterTrack`
- `PickX`
- `BoxIndex`

### P1.4 - Test duplicati

Passare lo stesso pezzo lentamente sotto NIR.

Domanda:

```text
crea un target solo o molti target duplicati?
```

Se crea duplicati, passare a Fase P2 object builder.

## P2 - Migliorare object builder

### P2.1 - Unire scan consecutivi

Obiettivo:

```text
piu' scan dello stesso pezzo -> un solo target
```

Serve aggiungere:

- oggetti "in costruzione"
- timeout fine pezzo
- centroide su piu' scan
- lunghezza pezzo

### P2.2 - Materiale dominante

Obiettivo:

```text
se un pezzo ha piu' tracce/codici, scegliere il materiale dominante
```

Utile per:

- plastiche sporche
- oggetti misti
- falsi positivi

### P2.3 - Filtri dimensione

Filtrare:

- pezzi troppo piccoli
- pezzi troppo larghi
- rumore isolato
- target fuori area robot

## P3 - Protocollo robot reale

### P3.1 - Recuperare protocollo

Servono:

- manuale robot/controller
- canale comunicazione
- formato comando
- formato ACK
- stati ready/busy/error

### P3.2 - Implementare `Gestione_Robot` reale

Sostituire simulazione con:

```text
target disponibile -> invio comando -> ACK -> DONE/FAIL
```

### P3.3 - Timeout e sicurezza logica

Gestire:

- nessun ACK
- robot busy troppo a lungo
- robot error
- target uscito da finestra
- reset manuale

## P4 - Test macchina

### P4.1 - Nastro fermo

Testare coordinate con target statico.

### P4.2 - Nastro lento

Testare un target alla volta.

### P4.3 - Nastro reale

Testare flusso reale e saturazione robot.

### P4.4 - Produzione controllata

Solo dopo:

- safety validata
- quote validate
- protocollo stabile
- fallback manuale

## Decisioni aperte

| Decisione | Opzioni |
|---|---|
| Object builder in PLC o PC esterno? | PLC semplice, PC esterno se serve visione/AI/blob avanzato |
| Comunicazione robot | Stringa `@...#`, TCP, UDP, I/O, fieldbus |
| Coordinate robot | Statiche, conveyor tracking interno, timestamp/encoder |
| Gestione duplicati | Filtro semplice o object builder multi-scan |
| Safety | TwinSAFE, safety controller robot, I/O esterno |

