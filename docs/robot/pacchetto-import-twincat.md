# Pacchetto import TwinCAT

Aggiornato: 2026-05-26

## Scopo

Elenco minimo dei file da portare nel progetto TwinCAT di test.

## File codice da importare

Importare in questo ordine:

```text
src/Robot/ROBOT_TARGET.EXP
src/Robot/ROBOT_STATE.EXP
src/Robot/ROBOT_GLOBALS.EXP
src/Robot/ROBOT_OBJECT_BUILDER.EXP
src/Robot/ROBOT_TEST_INPUT.EXP
src/Robot/ROBOT_QUEUE.EXP
src/Robot/GESTIONE_ROBOT.EXP
```

Poi integrare la modifica in:

```text
src/GESTIONE_ENCODER.EXP
```

## File da non importare subito

Non modificare subito:

```text
src/TASK_CONFIGURATION.EXP
src/SENSORE_NIR.EXP
src/PROCESSING.EXP
src/GESTIONE_ESPULSIONE.EXP
```

Motivo:

```text
prima serve capire se tipi, GVL e POU robot compilano da soli
```

## Prima modifica task

Solo dopo compile pulito, aggiungere temporaneamente in task lenta:

```text
Processing();
Robot_ObjectBuilder();
Robot_TestInput();
Robot_Queue();
Gestione_Robot();
```

## Watch minima da salvare

Salvare una watch TwinCAT con:

```text
ROBOT_ENABLED
ROBOT_SIMULATION
ROBOT_RESET_REQUEST
ROBOT_TEST_INPUT_ENABLED
ROBOT_TEST_CREATE_TARGET
ROBOT_TARGETS[0].Valid
ROBOT_TARGETS[0].Id
ROBOT_TARGETS[0].PositionImpulses
ROBOT_TARGETS[0].InWindow
ROBOT_CURRENT_TARGET.Id
ROBOT_COMMAND_ID
ROBOT_COMMAND_PICK_X
ROBOT_COMMAND_DROP_X
ROBOT_COMMAND_STRING
ROBOT_COMMAND_SENT
ROBOT_STATE_GLOBAL.Ready
ROBOT_STATE_GLOBAL.Busy
ROBOT_STATE_GLOBAL.Ack
ROBOT_STATE_GLOBAL.PickDone
ROBOT_TARGETS_DETECTED
ROBOT_TARGETS_SENT
ROBOT_TARGETS_PICKED
ROBOT_TARGETS_MISSED
```

## Parametri iniziali consigliati

```text
ROBOT_ENABLED := TRUE
ROBOT_SIMULATION := TRUE
ROBOT_TEST_INPUT_ENABLED := TRUE
ROBOT_SIM_TRACKING_STEP_IMP := 5
ROBOT_SIM_PICK_TIME := T#500MS
ROBOT_PICK_WINDOW_START_IMP := 180
ROBOT_PICK_WINDOW_END_IMP := 260
ROBOT_TEST_FIRST_TRACK := 50
ROBOT_TEST_LAST_TRACK := 55
ROBOT_TEST_BOX_INDEX := 1
X_BOX[1] := 100.0
Y_BOX[1] := 200.0
Z_BOX[1] := 300.0
```

## Primo test manuale

1. Forzare `ROBOT_RESET_REQUEST := TRUE`.
2. Aspettare che torni FALSE.
3. Forzare `ROBOT_TEST_CREATE_TARGET := TRUE`.
4. Verificare `ROBOT_TARGETS_DETECTED`.
5. Attendere ingresso in finestra.
6. Verificare `ROBOT_COMMAND_STRING`.
7. Verificare `ROBOT_TARGETS_PICKED` oppure `ROBOT_TARGETS_MISSED`.

## Cosa riportare se fallisce

Servono questi dati:

```text
errore TwinCAT completo
file e riga
fase del test
valori watch principali
se ROBOT_RESET_REQUEST torna FALSE
se ROBOT_COMMAND_STRING resta vuota
```

Con questi dati si puo' correggere in modo mirato senza tentativi casuali.
