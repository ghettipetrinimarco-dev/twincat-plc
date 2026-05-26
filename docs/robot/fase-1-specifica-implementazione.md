# Fase 1 - Specifica implementazione preliminare

Aggiornato: 2026-05-26

## Obiettivo fase

Costruire il primo layer PLC robot senza comandare ancora il robot reale.

La fase e' completata quando:

```text
1. il PLC puo' rappresentare target robot in strutture dati dedicate
2. il PLC puo' popolare una coda target da input simulato o NIR
3. i target avanzano con encoder/PASSO_ENCODER
4. i target entrano/escono da una finestra di presa
5. un robot simulato puo' prendere un target
6. sono disponibili contatori e stati diagnostici
```

Questa fase non deve toccare la logica di scarto pneumatico esistente.

## Principio guida

Il vecchio codice in `robot/sensoreNIR.txt` genera stringhe troppo presto.

La Fase 1 deve prima creare un modello dati stabile:

```text
materiale rilevato -> target PLC -> coda -> finestra presa -> robot/simulatore
```

Solo dopo si converte un target in stringa o comando robot.

## File/POU da creare

Proposta sotto `src/Robot/`.

| File | Tipo | Responsabilita' |
|---|---|---|
| `ROBOT_TARGET.EXP` | TYPE | Definisce struttura target |
| `ROBOT_STATE.EXP` | TYPE | Definisce stato robot |
| `ROBOT_GLOBALS.EXP` | GVL | Parametri, coda, contatori |
| `ROBOT_OBJECT_BUILDER.EXP` | PROGRAM | Crea target da scan/gruppi |
| `ROBOT_QUEUE.EXP` | PROGRAM | Tracking target e finestra presa |
| `GESTIONE_ROBOT.EXP` | PROGRAM | Robot simulato e, poi, reale |

Nota: per TwinCAT 2 si puo' iniziare con file `.st` leggibili e poi esportare `.EXP`.

## Dati minimi

### `ROBOT_TARGET`

Campi minimi:

| Campo | Tipo | Uso |
|---|---|---|
| `Id` | `UDINT` | Identificativo target |
| `MaterialIndex` | `INT` | Indice in `CODICI_MATERIALI` |
| `MaterialCode` | `BYTE` | Codice letto dal NIR |
| `BoxIndex` | `INT` | Box deposito |
| `FirstTrack` | `INT` | Prima traccia gruppo |
| `LastTrack` | `INT` | Ultima traccia gruppo |
| `CenterTrack` | `REAL` | Centro laterale in tracce |
| `PickX` | `REAL` | Coordinata laterale robot |
| `PickY` | `REAL` | Coordinata longitudinale robot |
| `PickZ` | `REAL` | Quota presa |
| `PickAngle` | `REAL` | Rotazione utensile |
| `PositionImpulses` | `UDINT` | Avanzamento da NIR |
| `Valid` | `BOOL` | Slot valido |
| `InWindow` | `BOOL` | Target nella finestra |
| `Sent` | `BOOL` | Target inviato |
| `Picked` | `BOOL` | Preso |
| `Failed` | `BOOL` | Fallito |
| `Missed` | `BOOL` | Uscito da finestra |

### `ROBOT_GLOBALS`

Variabili minime:

| Variabile | Tipo | Default | Nota |
|---|---|---|---|
| `ROBOT_ENABLED` | `BOOL` | `FALSE` | Abilita layer robot |
| `ROBOT_SIMULATION` | `BOOL` | `TRUE` | Usa robot simulato |
| `ROBOT_READY` | `BOOL` | `FALSE` | Stato robot |
| `ROBOT_BUSY` | `BOOL` | `FALSE` | Stato robot |
| `ROBOT_ERROR` | `BOOL` | `FALSE` | Stato robot |
| `ROBOT_TARGETS` | `ARRAY [0..49] OF ROBOT_TARGET` | - | Coda target |
| `ROBOT_CURRENT_TARGET` | `ROBOT_TARGET` | - | Target in esecuzione |
| `ROBOT_NEXT_ID` | `INT` | `1` | Progressivo ID |
| `ROBOT_TARGETS_DETECTED` | `UDINT` | `0` | Contatore |
| `ROBOT_TARGETS_SENT` | `UDINT` | `0` | Contatore |
| `ROBOT_TARGETS_PICKED` | `UDINT` | `0` | Contatore |
| `ROBOT_TARGETS_FAILED` | `UDINT` | `0` | Contatore |
| `ROBOT_TARGETS_MISSED` | `UDINT` | `0` | Contatore |
| `ROBOT_QUEUE_FULL_COUNT` | `UDINT` | `0` | Contatore |

Parametri persistent minimi:

| Variabile | Tipo | Nota |
|---|---|---|
| `ROBOT_TRACK_PITCH_MM` | `REAL` | mm per traccia NIR |
| `ROBOT_X_ORIGIN_MM` | `REAL` | origine laterale |
| `ROBOT_PICK_Y_MM` | `REAL` | coordinata longitudinale provvisoria |
| `ROBOT_PICK_Z_MM` | `REAL` | quota presa |
| `ROBOT_PICK_ANGLE_DEG` | `REAL` | rotazione default |
| `ROBOT_PICK_WINDOW_START_IMP` | `UDINT` | inizio finestra in impulsi |
| `ROBOT_PICK_WINDOW_END_IMP` | `UDINT` | fine finestra in impulsi |
| `ROBOT_MIN_WIDTH_TRACKS` | `INT` | filtro minimo |
| `ROBOT_MAX_WIDTH_TRACKS` | `INT` | filtro massimo |
| `MATERIALI_ATTIVI_BOX` | `ARRAY [0..100] OF INT` | materiale -> box |
| `X_BOX` | `ARRAY [0..20] OF REAL` | deposito |
| `Y_BOX` | `ARRAY [0..20] OF REAL` | deposito |
| `Z_BOX` | `ARRAY [0..20] OF REAL` | deposito |

## POU 1 - `ROBOT_OBJECT_BUILDER`

### Responsabilita'

Trovare gruppi di tracce target e creare target.

### Input

- `ROBOT_ENABLED`
- `MSI_data[INDEX_NIR]` o ultimo scan confermato
- `CODICI_MATERIALI[]`
- `MATERIALI_ATTIVI[]`
- `MATERIALI_ATTIVI_BOX[]`
- parametri `ROBOT_*`

### Output

- nuovo slot in `ROBOT_TARGETS[]`
- incremento `ROBOT_TARGETS_DETECTED`
- incremento `ROBOT_QUEUE_FULL_COUNT` se non c'e' spazio

### Algoritmo iniziale

Per Fase 1 basta una versione semplice:

```text
per indice = 1..NUM_TRACKS_NIR:
    material_index := trova indice codice per MSI_data[scan].track[indice]
    is_target := material_index valido AND MATERIALI_ATTIVI[material_index]

    se is_target e non gruppo_aperto:
        apri gruppo
        salva first_track, material_index, material_code

    se is_target:
        aggiorna last_track

    se non is_target e gruppo_aperto:
        chiudi gruppo
        se gruppo valido: crea target
```

Limite accettato in Fase 1:

- se dentro lo stesso gruppo ci sono materiali diversi, usare il primo materiale target trovato
- nella Fase 2 si puo' calcolare materiale dominante

## POU 2 - `ROBOT_QUEUE`

### Responsabilita'

Seguire target con encoder e decidere quando sono prendibili.

### Input

- `PASSO_ENCODER`
- `ROBOT_TARGETS[]`
- `ROBOT_PICK_WINDOW_START_IMP`
- `ROBOT_PICK_WINDOW_END_IMP`
- stato robot

### Output

- `InWindow`
- `Missed`
- target pronto per `GESTIONE_ROBOT`

### Algoritmo

```text
per ogni target valido non concluso:
    se target non picked/failed/missed:
        target.PositionImpulses += PASSO_ENCODER

    se PositionImpulses dentro finestra:
        target.InWindow := TRUE

    se PositionImpulses > fine finestra e non Sent/Picked:
        target.Missed := TRUE
        ROBOT_TARGETS_MISSED++

    se robot ready e target in_window e non sent:
        ROBOT_CURRENT_TARGET := target
        target.Sent := TRUE
        ROBOT_TARGETS_SENT++
```

Nota importante:

`PASSO_ENCODER` oggi viene calcolato in `Gestione_Encoder`. Bisogna evitare che `ROBOT_QUEUE` venga eseguito piu' volte per lo stesso passo encoder. Una soluzione semplice e' creare un impulso tipo `ENCODER_STEP_VALID` nella Fase 1 o eseguire tracking solo quando `PASSO_ENCODER > 0` e viene aggiornato.

## POU 3 - `GESTIONE_ROBOT`

### Responsabilita' Fase 1

Simulare robot.

### Stati minimi

```text
DISABLED
READY
BUSY
DONE
ERROR
```

### Algoritmo simulato

```text
se ROBOT_ENABLED = FALSE:
    ready := FALSE
    busy := FALSE
    esci

se ROBOT_SIMULATION = TRUE:
    se ready e target corrente valido:
        busy := TRUE
        ready := FALSE
        avvia timer

    se timer finito:
        marca target picked
        busy := FALSE
        ready := TRUE
```

## Integrazione task

Proposta prudente:

```text
TASK Elaboration 10ms:
    Processing();
    ROBOT_OBJECT_BUILDER();
    ROBOT_QUEUE();
    GESTIONE_ROBOT();
```

Ma va verificato per evitare duplicazione target:

- `ROBOT_OBJECT_BUILDER` non deve rileggere lo stesso scan NIR molte volte
- serve memorizzare `LAST_PROCESSED_NIR_INDEX`
- crea target solo quando `INDEX_NIR` cambia

## Criteri di verifica Fase 1

### Test 1 - Robot disabilitato

Dato:

```text
ROBOT_ENABLED = FALSE
```

Atteso:

```text
nessun target creato
nessun comando robot
comportamento NIR/EV invariato
```

### Test 2 - Target simulato da traccia singola

Dato:

```text
scan con traccia 50 target
ROBOT_ENABLED = TRUE
ROBOT_SIMULATION = TRUE
```

Atteso:

```text
crea un target
FirstTrack = 50
LastTrack = 50
BoxIndex coerente
target avanza con encoder
```

### Test 3 - Gruppo contiguo

Dato:

```text
scan con tracce 40..45 target
```

Atteso:

```text
crea un solo target
FirstTrack = 40
LastTrack = 45
CenterTrack = 42.5
```

### Test 4 - Finestra presa

Dato:

```text
target con PositionImpulses che supera ROBOT_PICK_WINDOW_START_IMP
```

Atteso:

```text
InWindow = TRUE
se robot ready -> Sent = TRUE
```

### Test 5 - Missed

Dato:

```text
robot busy o disabled
target supera ROBOT_PICK_WINDOW_END_IMP
```

Atteso:

```text
Missed = TRUE
ROBOT_TARGETS_MISSED incrementa
```

### Test 6 - Robot simulato picked

Dato:

```text
robot ready
target in_window
```

Atteso:

```text
robot passa busy
dopo timer torna ready
target picked
ROBOT_TARGETS_PICKED incrementa
```

## Dipendenze da chiarire prima del robot reale

La Fase 1 puo' essere sviluppata senza questi dati, ma la Fase 2 no:

- protocollo robot reale
- ACK robot
- coordinate robot effettive
- quote meccaniche precise
- area lavoro robot
- safety e segnali di emergenza

## Output atteso a fine Fase 1

Un progetto PLC con layer robot disabilitabile, ancora in simulazione, che dimostra:

```text
il NIR puo' generare target robot tracciati da encoder
```

Questo e' il primo passaggio concreto verso una macchina reale.
