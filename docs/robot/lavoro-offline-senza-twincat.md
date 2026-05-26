# Lavoro offline senza TwinCAT e senza macchina

Aggiornato: 2026-05-26

## Situazione

Per ora non abbiamo accesso a:

```text
TwinCAT
macchina reale
robot reale
controller PickMaster
```

Quindi non possiamo verificare:

- compilazione TwinCAT
- task reali
- comunicazione socket
- coordinate fisiche
- safety
- presa reale

Possiamo pero' preparare molto lavoro utile dentro le cartelle.

## Obiettivo offline

Arrivare con un pacchetto pronto per quando avremo TwinCAT:

```text
documentazione allineata
scaffold robot ridotto nei rischi
ordine import chiaro
test plan chiaro
specifica driver PickMaster pronta
domande tecniche pronte per azienda/tecnico
```

## Cosa fare ora

### 1. Congelare il core simulato

Non aumentare ancora la complessita' di:

```text
src/Robot/GESTIONE_ROBOT.EXP
src/Robot/ROBOT_QUEUE.EXP
src/Robot/ROBOT_OBJECT_BUILDER.EXP
```

Motivo:

```text
il primo obiettivo e' far compilare e testare target -> queue -> comando numerico -> picked/missed
```

### 2. Preparare il driver PickMaster solo come specifica

Non scrivere ancora un POU reale `Robot_PickMasterDriver.EXP` da importare.

Prima scrivere:

```text
docs/robot/specifica-pickmaster-driver.md
```

Deve definire:

- stati
- variabili globali necessarie
- input da `ROBOT_COMMAND_*`
- output ready/busy/error
- timeout
- cosa fare se UserHook non risponde
- cosa fare se PickMaster non parte

### 3. Preparare una GVL proposta per PickMaster

Non aggiungerla ancora al core.

Preparare solo una proposta documentata:

```text
IP_PICKMASTER
PORT_PICKMASTER
IP_USERHOOK
PORT_USERHOOK
ROBOT_PICKMASTER_ENABLED
ROBOT_PICKMASTER_CONNECTED
ROBOT_USERHOOK_CONNECTED
ROBOT_PICKMASTER_ERROR
ROBOT_PICKMASTER_ERROR_CODE
```

### 4. Fare audit statico dei file robot

Controllare:

- POU chiuse con `END_PROGRAM`
- TYPE chiusi con `END_TYPE`
- GVL chiusa con `@OBJECT_END`
- riferimenti globali mancanti
- nomi duplicati
- file opzionali separati dal primo import

### 5. Preparare handoff definitivo per Claude/Codex

Aggiornare:

```text
docs/robot/handoff-claude.md
```

con:

- scoperta PickMaster/UserHook
- cosa non importare
- cosa fare appena disponibile TwinCAT

## Cosa non fare ora

### Non importare mentalmente `robot/gestionerobot.txt`

E' materiale storico, non codice pronto.

### Non sostituire il simulatore

Il nostro:

```text
src/Robot/GESTIONE_ROBOT.EXP
```

resta simulatore/core.

Il futuro driver reale deve avere nome diverso:

```text
Robot_PickMasterDriver
```

### Non implementare safety

Senza macchina e schema elettrico non si puo' validare safety.

Si puo' solo documentare cosa manca.

## Priorita' offline consigliata

1. Scrivere specifica `Robot_PickMasterDriver`.
2. Aggiornare checklist dati mancanti con IP/porte PickMaster/UserHook.
3. Fare audit statico dello scaffold robot.
4. Preparare pacchetto import aggiornato.
5. Fermarsi prima di aggiungere altro codice runtime non compilabile.

## Gate per passare oltre

Non considerare completata la fase preliminare finche' non abbiamo almeno:

```text
core robot pronto per import
specifica PickMaster pronta
checklist dati mancanti aggiornata
primo test plan TwinCAT pronto
```

Il programma reale richiedera' comunque:

```text
compilazione TwinCAT
test con target manuale
test con NIR reale
test con PickMaster/UserHook
test macchina e safety
```
