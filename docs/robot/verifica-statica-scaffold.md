# Verifica statica scaffold robot

Aggiornato: 2026-05-26

## Scopo

Ridurre il rischio del primo import in TwinCAT 2 controllando lo scaffold robot con gli strumenti disponibili nel repo.

Questa non e' una compilazione TwinCAT.

## Verifiche fatte

### Stato repository

Branch:

```text
session/2026-05-16_15-21
```

Prima della verifica il repo era pulito.

### File scaffold presenti

```text
src/Robot/GESTIONE_ROBOT.EXP
src/Robot/README.md
src/Robot/ROBOT_GLOBALS.EXP
src/Robot/ROBOT_OBJECT_BUILDER.EXP
src/Robot/ROBOT_QUEUE.EXP
src/Robot/ROBOT_STATE.EXP
src/Robot/ROBOT_TARGET.EXP
src/Robot/ROBOT_TEST_INPUT.EXP
```

### Chiusura POU/TYPE

Controllato che i file principali terminino con:

- `END_PROGRAM` per i PROGRAM
- `END_TYPE` / `@END_DECLARATION` per i TYPE
- `@OBJECT_END` per la GVL

### Riferimenti principali

Riferimenti robot usati solo nello scaffold e nei documenti:

- `ROBOT_TARGETS`
- `ROBOT_STATE_GLOBAL`
- `ROBOT_CURRENT_TARGET`
- `ROBOT_TARGET_REQUEST`
- `ROBOT_SIM_PICK_DONE`
- `ROBOT_TEST_*`
- `ROBOT_ENCODER_PENDING_IMP`
- `MATERIALI_ATTIVI_BOX`
- `X_BOX/Y_BOX/Z_BOX`

Riferimenti al progetto esistente usati dallo scaffold:

- `INDEX_NIR`
- `MSI_data`
- `NUM_TRACKS_NIR`
- `NUM_CODICI`
- `CODICI_MATERIALI`
- `MATERIALI_ATTIVI`

Questi esistono nel progetto attuale.

### Aggancio encoder reale

`Gestione_Encoder` ora alimenta il layer robot quando:

```st
ROBOT_ENABLED AND NOT ROBOT_SIMULATION
```

Ogni nuovo `PASSO_ENCODER` viene:

- scritto in `ROBOT_ENCODER_STEP_IMP` come ultimo passo osservato
- sommato in `ROBOT_ENCODER_PENDING_IMP`
- segnalato con `ROBOT_ENCODER_STEP_VALID := TRUE`

`Robot_Queue` consuma `ROBOT_ENCODER_PENDING_IMP` e poi azzera:

```st
ROBOT_ENCODER_STEP_IMP
ROBOT_ENCODER_PENDING_IMP
ROBOT_ENCODER_STEP_VALID
```

Motivo:

```text
Gestione_Encoder gira a 0.100 ms, Robot_Queue e' prevista nella task a 10 ms.
Con un solo valore istantaneo si rischia di perdere impulsi tra due cicli della queue.
```

### Comando robot osservabile

`Gestione_Robot` genera `ROBOT_COMMAND_STRING` quando accetta un `ROBOT_TARGET_REQUEST`.

Formato:

```text
@id,x_pick,y_pick,z_pick,angle,wait_pick,x_drop,y_drop,z_drop,wait_drop,#
```

Il comando usa:

- `ROBOT_CURRENT_TARGET` per coordinate di presa
- `X_BOX/Y_BOX/Z_BOX` per coordinate deposito
- `ROBOT_WAIT_PICK_MS` e `ROBOT_WAIT_DROP_MS` per le attese

`ROBOT_COMMAND_SENT` e' un impulso di un ciclo.

`ROBOT_COMMAND_READY` segnala che la stringa del ciclo corrente e' valida.

Oltre alla stringa, `Gestione_Robot` popola campi comando numerici:

```text
ROBOT_COMMAND_ID
ROBOT_COMMAND_PICK_X/Y/Z
ROBOT_COMMAND_DROP_X/Y/Z
```

Motivo:

```text
se REAL_TO_STRING crea problemi al compile, i campi numerici restano verificabili in watch
```

### Reset operativo

`Robot_Queue` gestisce `ROBOT_RESET_REQUEST`.

Quando il bit e' TRUE:

- svuota `ROBOT_TARGETS`
- azzera `ROBOT_CURRENT_TARGET.Id`
- riporta `ROBOT_NEXT_ID` a `1`
- azzera contatori target e contatori queue
- azzera accumulo encoder robot
- svuota `ROBOT_COMMAND_STRING`
- riporta `ROBOT_RESET_REQUEST` a FALSE

Serve per ripetere i test TwinCAT senza riavviare il progetto.

## Correzioni fatte dopo verifica

### Array con limiti letterali

Per ridurre rischi con TwinCAT 2, la GVL robot ora usa limiti letterali:

```st
ROBOT_TARGETS : ARRAY [0..49] OF ROBOT_TARGET;
X_BOX : ARRAY [0..20] OF REAL;
Y_BOX : ARRAY [0..20] OF REAL;
Z_BOX : ARRAY [0..20] OF REAL;
```

Le costanti:

```st
ROBOT_MAX_TARGETS : INT := 49;
ROBOT_MAX_BOXES : INT := 20;
```

restano utili nei cicli `FOR`, ma non sono piu' usate come bound di array.

### Lettura ultimo scan NIR

`Robot_ObjectBuilder` non legge direttamente `INDEX_NIR`.

Legge l'ultimo scan completato:

```st
IF INDEX_NIR = 0 THEN
    scan_index := ROBOT_NIR_LAST_INDEX;
ELSE
    scan_index := INDEX_NIR - 1;
END_IF
```

Motivo:

```text
Sensore_NIR incrementa INDEX_NIR dopo avere scritto lo scan
```

## Rischi ridotti nello scaffold

### Tipo `scan_index`

`scan_index` e `ROBOT_LAST_PROCESSED_NIR_INDEX` sono `UINT`, come `INDEX_NIR`.

```st
ROBOT_NIR_LAST_INDEX : UINT := 150
```

Motivo:

```text
evitare conversioni implicite tra INDEX_NIR, ultimo indice buffer e scan_index
```

Nota:

```text
ROBOT_NIR_LAST_INDEX deve restare allineato a BUFFER_SIZE.
Oggi BUFFER_SIZE = 150.
```

### Timer simulazione

`GESTIONE_ROBOT` usa:

```st
ROBOT_SIM_PICK_TIME : TIME := T#500MS
```

e passa direttamente questo valore al `TON`.

`ROBOT_SIM_PICK_TIME` e' in `VAR_GLOBAL`, non in `VAR_GLOBAL PERSISTENT`.

Motivo:

```text
evitare conversione `INT_TO_TIME` nella prima compilazione
```

### Stringa comando

`ROBOT_COMMAND_STRING` e `command_tail` usano:

```st
STRING(150)
```

Motivo:

```text
il progetto esistente usa gia' STRING(150) per path file
```

### Copia target corrente

`Robot_Queue` copia `ROBOT_CURRENT_TARGET` campo per campo.

Motivo:

```text
evitare dipendenza dalla copia struttura completa `ROBOT_CURRENT_TARGET := ROBOT_TARGETS[slot_index]`
```

## Rischi residui da verificare in TwinCAT

### Ordine import

Importare prima i TYPE:

```text
ROBOT_TARGET
ROBOT_STATE
```

Poi GVL:

```text
Robot_Globals
```

Poi PROGRAM:

```text
Robot_ObjectBuilder
Robot_TestInput
Robot_Queue
Gestione_Robot
```

### Ordine esecuzione task

Nella task lenta, ordine consigliato:

```text
Robot_ObjectBuilder();
Robot_TestInput();
Robot_Queue();
Gestione_Robot();
```

Nota: se si vuole che il simulatore reagisca nello stesso ciclo al target richiesto, potrebbe servire eseguire `Gestione_Robot()` prima e dopo la queue o introdurre un ciclo di latenza. Per Fase 1 una latenza di un ciclo e' accettabile.

## Stato finale verifica

Lo scaffold e':

```text
pronto per primo import controllato in TwinCAT
non collegato ai task nel repo
non verificato dal compilatore TwinCAT
non pronto per produzione
```
