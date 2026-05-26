# Note integrazione scaffold ST robot

Aggiornato: 2026-05-26

## Cosa e' stato preparato

E' stata creata una bozza separata in:

```text
src/Robot/
```

File:

| File | Scopo |
|---|---|
| `ROBOT_TARGET.EXP` | Tipo target robot |
| `ROBOT_STATE.EXP` | Tipo stato robot |
| `ROBOT_GLOBALS.EXP` | GVL robot, parametri e contatori |
| `ROBOT_OBJECT_BUILDER.EXP` | Crea target da gruppi di tracce NIR |
| `ROBOT_TEST_INPUT.EXP` | Crea target manuali per test senza NIR |
| `ROBOT_QUEUE.EXP` | Avanza target e gestisce finestra presa |
| `GESTIONE_ROBOT.EXP` | Simulatore robot ready/busy/picked |
| `README.md` | Nota locale |

## Stato

Questa e' una bozza preliminare.

Non e':

- importata nel progetto TwinCAT
- collegata a `TASK_CONFIGURATION.EXP`
- compilata in TwinCAT 2
- pronta per produzione
- collegata al robot reale

## Come usarla in sicurezza

Prima regola:

```text
ROBOT_ENABLED := FALSE
```

Il layer robot deve restare disabilitato finche':

- i file compilano in TwinCAT
- i parametri sono caricati
- il simulatore e' verificato
- la macchina reale non e' coinvolta

## Integrazione proposta

Quando si passa alla Fase 1 reale:

1. Importare i TYPE:
   - `ROBOT_TARGET`
   - `ROBOT_STATE`

2. Importare la GVL:
   - `Robot_Globals`

3. Importare i PROGRAM:
   - `Robot_ObjectBuilder`
   - `Robot_TestInput`
   - `Robot_Queue`
   - `Gestione_Robot`

4. Aggiungere provvisoriamente alla task lenta:

```text
TASK Elaboration 10ms:
    Processing();
    Robot_ObjectBuilder();
    Robot_TestInput();
    Robot_Queue();
    Gestione_Robot();
```

5. Testare prima con:

```text
ROBOT_ENABLED := FALSE
ROBOT_SIMULATION := TRUE
```

6. Poi testare con:

```text
ROBOT_ENABLED := TRUE
ROBOT_SIMULATION := TRUE
```

## Punti da verificare in TwinCAT

### 1. Array con costanti globali

La bozza usa costanti globali:

```st
ROBOT_TARGETS : ARRAY [0..ROBOT_MAX_TARGETS] OF ROBOT_TARGET;
X_BOX : ARRAY [0..ROBOT_MAX_BOXES] OF REAL;
```

Se TwinCAT 2 non accetta costanti globali come limite array nella GVL, sostituire con valori letterali:

```st
ROBOT_TARGETS : ARRAY [0..49] OF ROBOT_TARGET;
X_BOX : ARRAY [0..20] OF REAL;
```

### 2. Tipi e conversioni UINT/INT

`INDEX_NIR` e' `UINT`, `BUFFER_SIZE` e' `INT`.

Se TwinCAT segnala conversioni implicite, sostituire:

```st
scan_index := BUFFER_SIZE;
```

con conversione esplicita accettata da TwinCAT 2.

## Scelte fatte nello scaffold

### Lettura ultimo scan NIR

`Sensore_NIR` incrementa `INDEX_NIR` dopo avere scritto lo scan.

Per questo `Robot_ObjectBuilder` legge:

```text
INDEX_NIR - 1
```

e se `INDEX_NIR = 0`, legge `BUFFER_SIZE`.

### Tracking simulato

Per evitare di contare piu' volte `PASSO_ENCODER` nella task lenta, `Robot_Queue` non usa direttamente `PASSO_ENCODER`.

Usa:

```st
ROBOT_SIM_TRACKING_STEP_IMP
```

quando `ROBOT_SIMULATION = TRUE`.

Su macchina reale bisognera' collegare:

```st
ROBOT_ENCODER_STEP_VALID
ROBOT_ENCODER_STEP_IMP
```

a un impulso prodotto da `Gestione_Encoder`.

### Robot reale non implementato

`GESTIONE_ROBOT.EXP` oggi implementa solo simulazione.

Il protocollo reale andra' implementato quando avremo:

- marca robot
- controller
- protocollo
- ACK
- ready/busy/error

## Test da fare appena importato

1. Compilare con `ROBOT_ENABLED := FALSE`.
2. Verificare che non cambi il comportamento della selezionatrice attuale.
3. Forzare manualmente un materiale attivo e un box.
4. Attivare `ROBOT_ENABLED := TRUE` in simulazione.
5. Verificare che `ROBOT_TARGETS_DETECTED` incrementi.
6. Verificare che un target entri in finestra.
7. Verificare che `GESTIONE_ROBOT` passi `Ready -> Busy -> Ready`.
8. Verificare `ROBOT_TARGETS_PICKED` o `ROBOT_TARGETS_MISSED`.

## Test manuale senza NIR

Per provare la coda robot senza aspettare il sensore:

```text
ROBOT_ENABLED := TRUE
ROBOT_SIMULATION := TRUE
ROBOT_TEST_INPUT_ENABLED := TRUE
ROBOT_TEST_FIRST_TRACK := 50
ROBOT_TEST_LAST_TRACK := 55
ROBOT_TEST_BOX_INDEX := 1
ROBOT_TEST_CREATE_TARGET := TRUE
```

Atteso:

```text
1. `Robot_TestInput` crea un target in `ROBOT_TARGETS[]`
2. `Robot_Queue` fa avanzare `PositionImpulses`
3. quando entra in finestra, `ROBOT_TARGET_REQUEST` va TRUE per un ciclo
4. `Gestione_Robot` passa `Ready -> Busy -> Ready`
5. `ROBOT_TARGETS_PICKED` incrementa
```

Se invece la finestra e' troppo corta o il robot simulato resta busy:

```text
ROBOT_TARGETS_MISSED incrementa
```
