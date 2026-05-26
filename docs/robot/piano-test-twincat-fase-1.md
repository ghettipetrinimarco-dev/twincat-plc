# Piano test TwinCAT - Fase 1 robot picker NIR

Aggiornato: 2026-05-26

## Scopo

Verificare lo scaffold robot in una copia di test TwinCAT prima di collegarlo a NIR reale o robot reale.

## Regola di sicurezza

Non fare questi test sulla macchina in produzione.

Usare:

```text
copia progetto
robot reale scollegato o disabilitato
ROBOT_SIMULATION := TRUE
```

## Import ordine corretto

1. `src/Robot/ROBOT_TARGET.EXP`
2. `src/Robot/ROBOT_STATE.EXP`
3. `src/Robot/ROBOT_GLOBALS.EXP`
4. `src/Robot/ROBOT_OBJECT_BUILDER.EXP`
5. `src/Robot/ROBOT_TEST_INPUT.EXP`
6. `src/Robot/ROBOT_QUEUE.EXP`
7. `src/Robot/GESTIONE_ROBOT.EXP`

## Task di test

In copia di test, aggiungere temporaneamente nella task lenta:

```text
TASK Elaboration 10ms:
    Processing();
    Robot_ObjectBuilder();
    Robot_TestInput();
    Robot_Queue();
    Gestione_Robot();
```

Se vuoi testare solo il target manuale senza NIR, puoi lasciare `Robot_ObjectBuilder()` importato ma non usarlo ancora.

## Watch list minima

Mettere in watch:

```text
ROBOT_ENABLED
ROBOT_SIMULATION
ROBOT_TEST_INPUT_ENABLED
ROBOT_TEST_CREATE_TARGET
ROBOT_TEST_FIRST_TRACK
ROBOT_TEST_LAST_TRACK
ROBOT_TEST_BOX_INDEX
ROBOT_TARGETS[0].Valid
ROBOT_TARGETS[0].Id
ROBOT_TARGETS[0].FirstTrack
ROBOT_TARGETS[0].LastTrack
ROBOT_TARGETS[0].CenterTrack
ROBOT_TARGETS[0].PickX
ROBOT_TARGETS[0].PositionImpulses
ROBOT_TARGETS[0].InWindow
ROBOT_TARGETS[0].Sent
ROBOT_TARGETS[0].Picked
ROBOT_TARGETS[0].Missed
ROBOT_ENCODER_STEP_VALID
ROBOT_ENCODER_STEP_IMP
ROBOT_ENCODER_PENDING_IMP
ROBOT_COMMAND_STRING
ROBOT_COMMAND_READY
ROBOT_COMMAND_SENT
ROBOT_WAIT_PICK_MS
ROBOT_WAIT_DROP_MS
ROBOT_STATE_GLOBAL.Ready
ROBOT_STATE_GLOBAL.Busy
ROBOT_STATE_GLOBAL.Ack
ROBOT_STATE_GLOBAL.PickDone
ROBOT_CURRENT_TARGET.Id
ROBOT_CURRENT_TARGET.BoxIndex
ROBOT_TARGETS_DETECTED
ROBOT_TARGETS_SENT
ROBOT_TARGETS_PICKED
ROBOT_TARGETS_MISSED
ROBOT_QUEUE_FULL_COUNT
```

## Test 0 - Compilazione disabilitata

Parametri:

```text
ROBOT_ENABLED := FALSE
ROBOT_SIMULATION := TRUE
```

Atteso:

```text
progetto compila
nessun target viene creato
robot non ready
nessun comportamento macchina esistente cambia
```

Se fallisce:

- correggere prima errori di compilazione
- non proseguire ai test runtime

## Test 1 - Creazione target manuale

Parametri:

```text
ROBOT_ENABLED := TRUE
ROBOT_SIMULATION := TRUE
ROBOT_TEST_INPUT_ENABLED := TRUE
ROBOT_TEST_FIRST_TRACK := 50
ROBOT_TEST_LAST_TRACK := 55
ROBOT_TEST_BOX_INDEX := 1
ROBOT_TEST_CREATE_TARGET := TRUE
```

Atteso entro pochi cicli:

```text
ROBOT_TEST_CREATE_TARGET torna FALSE
ROBOT_TARGETS_DETECTED incrementa
ROBOT_TARGETS[0].Valid = TRUE
ROBOT_TARGETS[0].FirstTrack = 50
ROBOT_TARGETS[0].LastTrack = 55
ROBOT_TARGETS[0].CenterTrack = 52.5
```

Se fallisce:

- verificare che `Robot_TestInput()` sia nella task
- verificare `ROBOT_TEST_INPUT_ENABLED`
- verificare che la coda non sia piena

## Test 2 - Avanzamento target

Parametri:

```text
ROBOT_SIM_TRACKING_STEP_IMP := 5
ROBOT_PICK_WINDOW_START_IMP := 180
ROBOT_PICK_WINDOW_END_IMP := 260
```

Atteso:

```text
ROBOT_TARGETS[0].PositionImpulses aumenta di 5 ogni ciclo task
quando supera 180, InWindow diventa TRUE
```

Se fallisce:

- verificare `Robot_Queue()` nella task
- verificare `ROBOT_SIMULATION = TRUE`
- verificare `ROBOT_SIM_TRACKING_STEP_IMP > 0`

## Test 3 - Invio al robot simulato

Condizione:

```text
target in finestra
ROBOT_STATE_GLOBAL.Ready = TRUE
```

Atteso:

```text
ROBOT_TARGET_REQUEST TRUE per un ciclo
ROBOT_TARGETS_SENT incrementa
ROBOT_TARGETS[0].Sent = TRUE
ROBOT_CURRENT_TARGET.Id = ROBOT_TARGETS[0].Id
ROBOT_COMMAND_SENT TRUE per un ciclo
ROBOT_COMMAND_STRING contiene formato @...#
```

Se fallisce:

- verificare ordine task: `Robot_Queue()` prima di `Gestione_Robot()`
- verificare che `ROBOT_STATE_GLOBAL.Ready` sia TRUE
- verificare che il target non sia gia' `Sent`
- se manca la stringa, verificare conversioni `INT_TO_STRING` e `REAL_TO_STRING`

## Test 4 - Pick simulato

Parametri:

```text
ROBOT_SIM_PICK_TIME_MS := 500
```

Atteso:

```text
ROBOT_STATE_GLOBAL.Busy TRUE durante timer
dopo timer, Busy FALSE
ROBOT_STATE_GLOBAL.Ready TRUE
ROBOT_STATE_GLOBAL.PickDone TRUE per controllo
ROBOT_TARGETS_PICKED incrementa
ROBOT_TARGETS[0].Valid torna FALSE
```

Se fallisce:

- verificare `Gestione_Robot()` nella task
- verificare `INT_TO_TIME(ROBOT_SIM_PICK_TIME_MS)`
- se `PickDone` resta TRUE troppo a lungo, valutare reset esplicito nella prossima revisione

## Test 5 - Missed

Impostare robot non pronto oppure finestra troppo corta:

```text
ROBOT_PICK_WINDOW_START_IMP := 10
ROBOT_PICK_WINDOW_END_IMP := 20
```

Atteso:

```text
target supera finestra
ROBOT_TARGETS[0].Missed = TRUE
ROBOT_TARGETS_MISSED incrementa
```

Se fallisce:

- verificare confronto `PositionImpulses > ROBOT_PICK_WINDOW_END_IMP`
- verificare che il target non sia gia' `Sent`

## Test 6 - NIR reale con robot simulato

Solo dopo i test manuali.

Preparazione:

```text
ROBOT_ENABLED := TRUE
ROBOT_SIMULATION := TRUE
ROBOT_TEST_INPUT_ENABLED := FALSE
```

Configurare:

```text
MATERIALI_ATTIVI[index] := TRUE
MATERIALI_ATTIVI_BOX[index] := 1
ROBOT_TRACK_PITCH_MM := valore provvisorio
```

Atteso:

```text
passaggio materiale target sotto NIR
ROBOT_TARGETS_DETECTED incrementa
target contiene FirstTrack/LastTrack coerenti
```

Se crea troppi target:

```text
serve Fase P2: object builder multi-scan anti-duplicati
```

## Criterio di uscita Fase 1

Fase 1 superata se:

```text
test manuale crea target
queue lo porta in finestra
robot simulato lo marca picked
missed funziona
NIR reale crea almeno target coerenti in simulazione
```

Non serve ancora:

```text
robot reale
protocollo reale
presa fisica
produzione automatica
```
