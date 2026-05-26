# Checklist prima compilazione TwinCAT

Aggiornato: 2026-05-26

## Scopo

Usare questa checklist durante il primo import dello scaffold robot in una copia TwinCAT.

Non usare sulla macchina in produzione.

## Preparazione

Prima di importare:

```text
creare copia progetto TwinCAT
robot reale scollegato o disabilitato
ROBOT_ENABLED := FALSE
ROBOT_SIMULATION := TRUE
```

## Ordine import obbligatorio

1. `src/Robot/ROBOT_TARGET.EXP`
2. `src/Robot/ROBOT_STATE.EXP`
3. `src/Robot/ROBOT_GLOBALS.EXP`
4. `src/Robot/ROBOT_OBJECT_BUILDER.EXP`
5. `src/Robot/ROBOT_TEST_INPUT.EXP`
6. `src/Robot/ROBOT_QUEUE.EXP`
7. `src/Robot/GESTIONE_ROBOT.EXP`

Poi importare/modificare:

```text
src/GESTIONE_ENCODER.EXP
```

## Primo compile

Prima compilazione consigliata:

```text
Robot POU importate
TASK_CONFIGURATION non modificata
ROBOT_ENABLED := FALSE
```

Obiettivo:

```text
verificare solo compatibilita' tipi, funzioni e riferimenti globali
```

## Errori probabili e correzione

| Errore TwinCAT probabile | Causa probabile | Correzione prevista |
|---|---|---|
| `Unknown type ROBOT_TARGET` | Import ordine sbagliato | Importare `ROBOT_TARGET.EXP` prima della GVL |
| `Unknown type ROBOT_STATE` | Import ordine sbagliato | Importare `ROBOT_STATE.EXP` prima della GVL |
| `Unknown identifier ROBOT_*` in `Gestione_Encoder` | GVL robot non importata | Importare `ROBOT_GLOBALS.EXP` prima di `GESTIONE_ENCODER.EXP` modificato |
| Target NIR letti dall'indice sbagliato | `ROBOT_NIR_LAST_INDEX` non allineato a `BUFFER_SIZE` | Impostare `ROBOT_NIR_LAST_INDEX` uguale a `BUFFER_SIZE` |
| Errore su `ROBOT_SIM_PICK_TIME : TIME := T#500MS` | Default `TIME` non accettato in GVL | Usare literal `T#500MS` direttamente nel `TON` |
| Errore su `ROBOT_TARGETS[slot_index]` | Indice o limite array non accettato | Verificare `slot_index : INT` e limiti `[0..49]` |
| Errore su `ROBOT_CURRENT_TARGET.BoxIndex` dentro `X_BOX[...]` | Indice array non accettato | Usare variabile intermedia `command_box_index`, gia' presente |

## Se compila

Non passare subito al robot reale.

Eseguire:

```text
docs/robot/piano-test-twincat-fase-1.md
```

Ordine:

1. Test 0: compilazione disabilitata.
2. Test 1: target manuale.
3. Test 1B: reset layer robot.
4. Test 2: avanzamento target.
5. Test 3: comando robot simulato.
6. Test 4: pick simulato.
7. Test 5: missed.
8. Test 6: NIR reale con robot simulato.

## Se non compila

Non fare modifiche casuali.

Segnare:

```text
file
riga
errore TwinCAT esatto
tipo variabile coinvolta
POU importata prima o dopo
```

Poi correggere una sola classe di errore alla volta.

## Gate per passare alla fase successiva

Fase P0 superata solo se:

```text
compila in copia TwinCAT
target manuale entra in queue
ROBOT_COMMAND_ID e coordinate numeriche si aggiornano
ROBOT_RESET_REQUEST funziona
pick simulato e missed funzionano
```

Solo dopo ha senso collegare NIR reale a target robot simulati.
