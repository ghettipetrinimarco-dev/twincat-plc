# Handoff per Claude - robot picker NIR

Aggiornato: 2026-05-26

## Obiettivo di Marco

Marco vuole arrivare entro qualche settimana a un programma TwinCAT che possa mandare in funzione un macchinario robotizzato per prelevare da conveyor materiali riconosciuti da sensore NIR LLA.

Caso d'uso:

```text
cliente seleziona polimero/materiale
NIR riconosce il materiale
PLC crea target robot
robot prende il materiale
robot deposita nel box corretto
```

## Repo

Percorso:

```text
/Users/marco/Desktop/dev/twincat
```

Branch:

```text
session/2026-05-16_15-21
```

## Materiale ricevuto

Marco ha aggiunto:

```text
robot/
  gestioneencoder.txt
  gestionerobot.txt
  processing.txt
  sensoreNIR.txt
```

Analisi:

- `gestionerobot.txt` ora contiene una bozza PickMaster/UserHook TCP recuperata da Claude
- `sensoreNIR.txt` contiene un tentativo parziale di generare stringhe target robot
- `gestioneencoder.txt` e `processing.txt` sono versioni ridotte/vecchie rispetto a `src/`

Il vecchio tentativo costruisce stringhe tipo:

```text
@id,x_pick,y_pick,z_pick,angle,wait_pick,x_drop,y_drop,z_drop,wait_drop,#
```

ma lo fa per singola traccia NIR, non per oggetto fisico.

`gestionerobot.txt` spiega chi leggeva/inviava `String_ToSend`:

```text
PLC -> PickMaster TCP: start progetto
PLC -> UserHook TCP: invio String_ToSend su fronte Trig
PLC -> PickMaster TCP: stop progetto
```

Non va importato pari pari perche':

- usa lo stesso nome `PROGRAM Gestione_Robot`
- manca `END_PROGRAM`
- usa globali mancanti `IP_PICKMASTER`, `PORT_PICKMASTER`, `IP_USERHOOK`, `PORT_USERHOOK`, `String_ToSend`, `Trig`
- non gestisce ACK/DONE/FAIL

## Diagnosi Codex

Il problema non e' leggere il NIR: il progetto attuale sa gia' farlo.

Il problema e':

```text
trasformare scan/tracce NIR in oggetti fisici prendibili
```

La logica corretta e':

```text
NIR scan
-> gruppi di tracce contigue
-> oggetto fisico
-> target robot
-> coda
-> tracking encoder
-> finestra presa
-> comando robot
-> feedback
```

Il vecchio codice saltava troppi passaggi:

```text
traccia NIR -> stringa robot
```

## Documenti prodotti

Leggere in questo ordine:

1. `docs/robot/sintesi-operativa.md`
2. `docs/robot/analisi-preliminare.md`
3. `docs/robot/analisi-gestionerobot-pickmaster.md`
4. `docs/robot/mvp-tecnico.md`
5. `docs/robot/fase-1-specifica-implementazione.md`
6. `docs/robot/scaffold-st-note-integrazione.md`
7. `docs/robot/verifica-statica-scaffold.md`
8. `docs/robot/comando-robot-da-target.md`
9. `docs/robot/checklist-prima-compilazione.md`
10. `docs/robot/pacchetto-import-twincat.md`

Per dati mancanti:

- `docs/robot/checklist-dati-mancanti.md`
- `docs/robot/protocollo-robot-provvisorio.md`

## Scaffold prodotto

Cartella:

```text
src/Robot/
```

File:

| File | Scopo |
|---|---|
| `ROBOT_TARGET.EXP` | Tipo target robot |
| `ROBOT_STATE.EXP` | Tipo stato robot |
| `ROBOT_GLOBALS.EXP` | GVL robot |
| `ROBOT_OBJECT_BUILDER.EXP` | Crea target da gruppi di tracce NIR |
| `ROBOT_QUEUE.EXP` | Tracking target e finestra presa |
| `GESTIONE_ROBOT.EXP` | Simulatore robot |
| `ROBOT_COMMAND_STRING_BUILDER.EXP` | Builder opzionale stringa `@...#` |
| `ROBOT_TEST_INPUT.EXP` | Generatore target manuale senza NIR |

Stato:

```text
bozza separata
non collegata a TASK_CONFIGURATION.EXP
non compilata in TwinCAT
non pronta per produzione
utile per Fase 1 simulata
```

## Cosa chiedere a Claude

Chiedere una review critica su:

1. Lo scaffold `src/Robot/` ha senso per TwinCAT 2?
2. I nomi e i tipi sono compatibili con lo stile del progetto?
3. `Robot_ObjectBuilder` rischia di generare troppi target duplicati?
4. La gestione `INDEX_NIR - 1` e' corretta rispetto a `Sensore_NIR`?
5. `Robot_Queue` dovrebbe girare in task 10 ms o serve task piu' veloce?
6. La simulazione con `ROBOT_TEST_INPUT` e' sufficiente per Fase 1?
7. L'accumulo `ROBOT_ENCODER_PENDING_IMP` tra `Gestione_Encoder` e `Robot_Queue` e' sufficiente o serve una strategia diversa tra task a 0.100 ms e task a 10 ms?
8. Ci sono incompatibilita' TwinCAT 2 evidenti nei file `.EXP` nuovi?
9. Meglio tenere object builder in PLC o spostarlo su PC esterno?
10. Quali test minimi fare in TwinCAT prima di toccare macchina reale?

## Bloccanti per robot reale

Servono ancora:

- marca/modello robot
- controller robot
- protocollo comunicazione reale
- formato ACK
- segnali ready/busy/error
- quote meccaniche NIR -> finestra presa
- mappa materiale -> box
- safety/I/O
- eventuale GVL robot originale
- eventuale `GestioneRobot` originale

## Prossima mossa consigliata

Non andare subito sul robot reale.

Prima fare:

```text
import scaffold in copia TwinCAT
ROBOT_ENABLED := FALSE
compilazione
ROBOT_ENABLED := TRUE
ROBOT_SIMULATION := TRUE
test Robot_TestInput
```

Poi:

```text
collegare Robot_ObjectBuilder al NIR reale
verificare target reali
```

Solo dopo:

```text
implementare protocollo robot reale
```
