# MVP tecnico - programma robot picker NIR

Aggiornato: 2026-05-26

## Scopo

Definire il primo programma realistico da costruire nelle prossime settimane.

Obiettivo del primo MVP:

```text
Dato un materiale attivo,
quando il NIR lo rileva sul conveyor,
il PLC crea un target unico,
lo segue con encoder,
lo manda in finestra di presa,
e lo rende disponibile a un robot o simulatore robot.
```

Questo MVP non deve ancora risolvere tutti i casi difficili. Deve dimostrare che la "mente" esiste.

## Cosa non fare nel primo MVP

- Non controllare traiettorie robot complesse dentro `Sensore_NIR`.
- Non generare una stringa per ogni singola traccia NIR.
- Non mescolare comunicazione robot e lettura NIR nello stesso POU.
- Non dipendere subito da robot reale per testare tutta la logica.
- Non sostituire il progetto attuale con i file vecchi in `robot/`.

## Requisiti funzionali MVP

### RF-1 - Materiale target

Il PLC deve usare `MATERIALI_ATTIVI[]` come sorgente per decidere quali materiali sono target.

Estensione necessaria:

```st
MATERIALI_ATTIVI_BOX : ARRAY [0..100] OF INT;
```

Serve per sapere in quale box depositare ogni materiale attivo.

### RF-2 - Rilevamento gruppi di tracce

Per ogni scan NIR, il PLC deve trovare gruppi contigui di tracce target.

Esempio:

```text
tracce 40,41,42 target -> gruppo unico
traccia 70 target -> altro gruppo
```

Ogni gruppo puo' diventare un candidato oggetto.

### RF-3 - Centro laterale

Per ogni gruppo, calcolare il centro laterale:

```text
center_track = (first_track + last_track) / 2
x_pick_mm = track_to_mm(center_track)
```

La conversione minima e':

```text
track_pitch_mm = larghezza_nir_mm / NUM_TRACKS_NIR
x_pick_mm = x_origin_mm + (center_track - 0.5) * track_pitch_mm
```

Il segno e l'origine vanno confermati sulla macchina.

### RF-4 - Creazione target

Creare un `Robot_Target` quando un gruppo e' valido.

Filtri minimi:

- larghezza gruppo >= `MIN_TARGET_WIDTH_TRACKS`
- larghezza gruppo <= `MAX_TARGET_WIDTH_TRACKS`
- materiale attivo
- box valido

Nel primo MVP si puo' creare un target per gruppo per scan.

Nel secondo step va migliorato unendo lo stesso pezzo su piu' scan consecutivi.

### RF-5 - Tracking con encoder

Ogni target deve avanzare usando `PASSO_ENCODER`, non `index_nir`.

Logica:

```st
IF target.valid AND NOT target.done THEN
    target.position_impulses := target.position_impulses + PASSO_ENCODER;
END_IF
```

### RF-6 - Finestra di presa

Ogni target deve avere stati:

```text
queued -> in_window -> sent/picked oppure missed
```

Regole:

```text
position < PICK_WINDOW_START -> queued
PICK_WINDOW_START <= position <= PICK_WINDOW_END -> in_window
position > PICK_WINDOW_END -> missed
```

### RF-7 - Robot simulato

Prima del robot reale, serve un simulatore logico:

```text
Robot ready = TRUE
quando riceve target -> busy TRUE
dopo tempo simulato -> picked TRUE
torna ready
```

Questo permette di testare:

- coda target
- doppio invio
- missed
- saturazione robot

### RF-8 - Diagnostica minima

Contatori:

```st
ROBOT_TARGETS_DETECTED : UDINT;
ROBOT_TARGETS_SENT : UDINT;
ROBOT_TARGETS_PICKED : UDINT;
ROBOT_TARGETS_FAILED : UDINT;
ROBOT_TARGETS_MISSED : UDINT;
ROBOT_QUEUE_FULL_COUNT : UDINT;
```

Stati:

```st
ROBOT_ENABLED : BOOL;
ROBOT_SIMULATION : BOOL;
ROBOT_READY : BOOL;
ROBOT_BUSY : BOOL;
ROBOT_ERROR : BOOL;
```

## Requisiti non funzionali

### RNF-1 - Separazione POU

Il codice robot deve stare in POU separati:

```text
Robot_ObjectBuilder
Robot_Queue
Gestione_Robot
```

`Sensore_NIR` deve restare responsabile della lettura sensore.

### RNF-2 - Non rompere selezionatrice esistente

Il layer robot deve poter essere disabilitato con:

```st
ROBOT_ENABLED := FALSE;
```

Quando disabilitato, il comportamento attuale NIR/EV non deve cambiare.

### RNF-3 - Niente target senza dati certi

Se mancano quote meccaniche, usare parametri configurabili ma marcati come provvisori.

Non hardcodare misure non confermate.

### RNF-4 - Debug visibile

Le strutture target devono essere ispezionabili da TwinCAT/HMI:

- ultimi target creati
- target corrente inviato
- stato robot
- motivi di scarto/missed

## Design dati proposto

### Tipo target

```st
TYPE ROBOT_TARGET :
STRUCT
    Id : INT;
    MaterialIndex : INT;
    MaterialCode : BYTE;
    BoxIndex : INT;
    FirstTrack : INT;
    LastTrack : INT;
    CenterTrack : REAL;
    PickX : REAL;
    PickY : REAL;
    PickZ : REAL;
    PickAngle : REAL;
    PositionImpulses : UDINT;
    Valid : BOOL;
    InWindow : BOOL;
    Sent : BOOL;
    Picked : BOOL;
    Failed : BOOL;
    Missed : BOOL;
END_STRUCT
END_TYPE
```

### Globali robot minime

```st
VAR_GLOBAL
    ROBOT_ENABLED : BOOL;
    ROBOT_SIMULATION : BOOL := TRUE;
    ROBOT_TARGETS : ARRAY [0..49] OF ROBOT_TARGET;
    ROBOT_NEXT_ID : INT;
    ROBOT_READY : BOOL;
    ROBOT_BUSY : BOOL;
    ROBOT_ERROR : BOOL;
    ROBOT_CURRENT_TARGET : ROBOT_TARGET;
END_VAR
```

### Parametri persistent minimi

```st
VAR_GLOBAL PERSISTENT
    ROBOT_TRACK_PITCH_MM : REAL;
    ROBOT_X_ORIGIN_MM : REAL;
    ROBOT_PICK_Z_MM : REAL;
    ROBOT_PICK_ANGLE_DEG : REAL;
    ROBOT_PICK_WINDOW_START_IMP : UDINT;
    ROBOT_PICK_WINDOW_END_IMP : UDINT;
    ROBOT_MIN_WIDTH_TRACKS : INT := 1;
    ROBOT_MAX_WIDTH_TRACKS : INT := 20;
    MATERIALI_ATTIVI_BOX : ARRAY [0..100] OF INT;
    X_BOX : ARRAY [0..20] OF REAL;
    Y_BOX : ARRAY [0..20] OF REAL;
    Z_BOX : ARRAY [0..20] OF REAL;
END_VAR
```

## Algoritmo MVP

### Robot_ObjectBuilder

Input:

- ultimo scan NIR decodificato
- `CODICI_MATERIALI`
- `MATERIALI_ATTIVI`
- `MATERIALI_ATTIVI_BOX`

Output:

- nuovi `ROBOT_TARGETS[]`

Pseudo-logica:

```text
per ogni traccia 1..117:
    se traccia contiene materiale target:
        se non sono dentro un gruppo:
            apri gruppo
        aggiorna last_track
    altrimenti:
        se gruppo aperto:
            chiudi gruppo
            se gruppo valido:
                crea target
```

### Robot_Queue

Input:

- `PASSO_ENCODER`
- `ROBOT_TARGETS[]`
- stato robot

Output:

- prossimo target da inviare

Pseudo-logica:

```text
per ogni target valido non concluso:
    target.position += PASSO_ENCODER

    se position dentro finestra:
        target.in_window := TRUE

    se robot ready e target in_window e non sent:
        invia target
        target.sent := TRUE

    se position oltre finestra e non picked:
        target.missed := TRUE
```

### Gestione_Robot simulata

Input:

- target da inviare

Output:

- `ROBOT_READY`
- `ROBOT_BUSY`
- `ROBOT_PICKED`

Pseudo-logica:

```text
se simulation e ready e target disponibile:
    busy := TRUE
    ready := FALSE
    avvia timer pick

quando timer finisce:
    picked := TRUE
    busy := FALSE
    ready := TRUE
```

## Integrazione minima con progetto attuale

Serve aggiungere task/POU, senza sostituire quelli esistenti.

Opzione prudente:

```text
Task Elaboration 10 ms:
    Processing()
    Robot_ObjectBuilder()
    Robot_Queue()
    Gestione_Robot()
```

Da verificare:

- se `Robot_ObjectBuilder` deve girare a 10 ms basta per il primo MVP
- se serve leggere ogni scan a 200 us, allora va agganciato con attenzione a `Sensore_NIR`

Per il primo MVP, meglio non appesantire task `Camera` a 200 us.

## Rischi noti

| Rischio | Impatto | Mitigazione |
|---|---|---|
| Troppi target per scan | Coda piena | Filtri dimensione e priorita' |
| Target duplicati su scan consecutivi | Robot prova a prendere lo stesso pezzo piu' volte | Step 2: unione scan in oggetto |
| Coordinate laterali invertite | Robot prende nel punto sbagliato | Test a nastro fermo con pezzo noto |
| Finestra presa sbagliata | Target sempre missed o troppo presto | Parametri persistent regolabili |
| Robot senza ACK | Doppi comandi o perdita target | Handshake obbligatorio prima del reale |
| Structured Text troppo pesante per object builder avanzato | Prestazioni | Tenere MVP semplice, poi valutare PC esterno |

## Prossimo passo consigliato

Creare una prima bozza di:

```text
ROBOT_TYPES
ROBOT_GLOBALS
ROBOT_OBJECT_BUILDER
ROBOT_QUEUE
GESTIONE_ROBOT_SIM
```

ma senza collegarla subito alla macchina reale.

Prima validazione:

```text
NIR vede materiale attivo -> target appare in ROBOT_TARGETS -> target entra in_window -> simulatore lo marca picked oppure missed
```
