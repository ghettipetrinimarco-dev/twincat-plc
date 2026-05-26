# Comando robot da target

Aggiornato: 2026-05-26

## Scopo

Definire come trasformare un `ROBOT_TARGET` in un comando robot osservabile e poi inviabile.

Questo documento deriva dal tentativo storico in:

```text
robot/sensoreNIR.txt
```

## Formato storico dedotto

Il vecchio codice costruiva una stringa:

```text
@id,x_pick,y_pick,z_pick,angle,wait_pick,x_drop,y_drop,z_drop,wait_drop,#
```

Esempio commentato nel file storico:

```text
@0,10,10,10,0,0,32,34,43,0,#
```

Nel vecchio codice la stringa veniva costruita dentro `Sensore_NIR`, mentre il nuovo layer deve costruirla dopo avere creato un target fisico.

## Mappa campi

| Campo comando | Origine storica | Origine nuova proposta | Stato |
|---|---|---|---|
| `id` | `UiTag` | `ROBOT_CURRENT_TARGET.Id` | disponibile |
| `x_pick` | `indice` | `ROBOT_CURRENT_TARGET.PickX` | disponibile |
| `y_pick` | `index_nir * SCAN_DISTANCE + DISTANCE_OFFSET` | `ROBOT_CURRENT_TARGET.PickY` oppure tracking robot reale | da validare |
| `z_pick` | `ALTEZZA` | `ROBOT_CURRENT_TARGET.PickZ` | disponibile |
| `angle` | `GRADI_ROTAZIONE` | `ROBOT_CURRENT_TARGET.PickAngle` | disponibile |
| `wait_pick` | `ATTESA_PRESA` | nuovo parametro robot | manca |
| `x_drop` | `X_BOX[indice_box]` | `X_BOX[ROBOT_CURRENT_TARGET.BoxIndex]` | disponibile |
| `y_drop` | `Y_BOX[indice_box]` | `Y_BOX[ROBOT_CURRENT_TARGET.BoxIndex]` | disponibile |
| `z_drop` | `Z_BOX[indice_box]` | `Z_BOX[ROBOT_CURRENT_TARGET.BoxIndex]` | disponibile |
| `wait_drop` | `ATTESA_DEPOSITO` | nuovo parametro robot | manca |
| `#` | terminatore | terminatore | disponibile |

## Differenza importante

Il vecchio codice usava:

```text
x_pick = indice traccia NIR
y_pick = index_nir * SCAN_DISTANCE + DISTANCE_OFFSET
```

Questo non e' ancora una coordinata robot affidabile.

Nel nuovo schema:

```text
PickX = posizione laterale calcolata dalla traccia centrale
PickY = posizione longitudinale/finestra presa da tarare
PickZ = quota presa da parametro
```

Il robot reale potrebbe pero' volere una logica diversa:

- coordinate statiche quando il target entra in finestra
- coordinate con conveyor tracking interno al controller robot
- timestamp/encoder invece di `y_pick`

Questa decisione dipende dal robot e dal suo controller.

## Parametri ancora da aggiungere

Servono almeno:

```text
ROBOT_WAIT_PICK_MS
ROBOT_WAIT_DROP_MS
ROBOT_COMMAND_STRING
ROBOT_COMMAND_READY
ROBOT_COMMAND_SENT
```

Da valutare dopo compilazione TwinCAT:

```text
UDINT_TO_STRING
REAL_TO_STRING
CONCAT annidati lunghi
lunghezza massima STRING
```

## Strategia consigliata

### Fase 1

Non inviare nulla al robot reale.

Generare solo target, coda e simulazione.

### Fase 2

Aggiungere una stringa comando osservabile in watch:

```text
ROBOT_COMMAND_STRING
```

La stringa deve aggiornarsi quando `Robot_Queue` mette un target in `ROBOT_CURRENT_TARGET`.

### Fase 3

Sostituire o affiancare la stringa con il protocollo reale del robot:

- TCP
- UDP
- seriale
- fieldbus
- I/O handshake

## Rischio principale

Non bisogna tornare alla logica:

```text
singola traccia NIR -> comando robot
```

La logica corretta resta:

```text
scan NIR -> oggetto fisico -> target -> coda -> finestra presa -> comando robot
```
