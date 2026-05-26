# Analisi Gestione_Robot PickMaster/UserHook

Aggiornato: 2026-05-26

## Scopo

Allineare il nuovo contenuto di:

```text
robot/gestionerobot.txt
```

con lo scaffold robot in:

```text
src/Robot/
```

## Cosa contiene il file recuperato

`robot/gestionerobot.txt` non e' piu' vuoto.

Contiene una bozza di programma TwinCAT:

```text
PROGRAM Gestione_Robot
```

che gestisce due socket TCP:

1. PickMaster
2. UserHook

Usa funzioni gia' disponibili nel progetto:

```text
FB_SocketConnect
FB_SocketSend
FB_SocketReceive
FB_SocketClose
T_HSOCKET
```

Queste arrivano da:

```text
src/TCPIP.LIB.EXP
```

## Sequenza dedotta

La state machine usa questi stati:

| Stato | Nome | Significato |
|---|---|---|
| `0` | `CONNESSIONE_PICKMASTER` | Connessione TCP a PickMaster |
| `1` | `AVVIO_PROGETTO` | Invio comando start progetto |
| `2` | `CONNESSIONE_USERHOOK` | Connessione TCP a UserHook |
| `3` | `RUNNING` | Invio dati target su trigger |
| `4` | `CHIUDI_USERHOOK` | Chiusura socket UserHook |
| `5` | `ARRESTA_PROGETTO` | Invio comando stop progetto |
| `6` | `CHIUDI_PICKMASTER` | Chiusura socket PickMaster |

Comandi binari PickMaster:

```text
CMD_AVVIA_PROGETTO  = 16#00, 16#13
CMD_ARRESTA_PROGETTO = 16#00, 16#14
```

Timeout:

```text
PICKMASTER_TIMEOUT := T#10s
```

## Collegamento con il vecchio Sensore_NIR

In `RUNNING`, il programma:

```st
PE_Trig.CLK := Trig;
PE_Trig();
IF PE_Trig.Q THEN send_data := TRUE; END_IF;
```

Quando `send_data = TRUE`, invia via UserHook:

```st
String_ToSend
```

Questo spiega il flusso vecchio:

```text
Sensore_NIR costruisce String_ToSend e alza Trig
Gestione_Robot vede fronte di Trig
Gestione_Robot invia String_ToSend al UserHook
```

## Variabili mancanti nel progetto attuale

Il file recuperato usa variabili non presenti in `src/`:

```text
IP_PICKMASTER
PORT_PICKMASTER
IP_USERHOOK
PORT_USERHOOK
String_ToSend
Trig
```

`DEFAULT_ADS_TIMEOUT` invece esiste gia' nel progetto attuale, perche' viene usato da `Sensore_NIR` e `Processing`.

## Perche' non va importato pari pari

Non importare `robot/gestionerobot.txt` direttamente nel progetto attuale.

Motivi:

1. Usa lo stesso nome del nostro POU `src/Robot/GESTIONE_ROBOT.EXP`.
2. Il file recuperato non termina con `END_PROGRAM`.
3. Dipende da globali mancanti.
4. Invia `String_ToSend` in modalita' fire-and-forget.
5. Non legge o interpreta `ACK`, `DONE`, `FAIL`, `READY`, `BUSY`.
6. Non e' integrato con `ROBOT_TARGETS`, `ROBOT_CURRENT_TARGET` e `ROBOT_COMMAND_*`.

## Valore tecnico della scoperta

Questo file cambia una parte della diagnosi.

Prima:

```text
non sapevamo chi leggeva String_ToSend
```

Ora:

```text
probabilmente String_ToSend veniva inviato via TCP al UserHook di ABB PickMaster
```

Questo rende molto piu' concreta la Fase P3:

```text
core robot target/queue
-> campi comando numerici ROBOT_COMMAND_*
-> builder stringa opzionale
-> driver PickMaster/UserHook TCP
```

## Strategia di integrazione consigliata

### Fase 1

Continuare con lo scaffold attuale:

```text
Robot_ObjectBuilder
Robot_TestInput
Robot_Queue
Gestione_Robot simulato
```

Obiettivo:

```text
target manuale -> queue -> comando numerico -> picked/missed simulato
```

### Fase 2

Testare opzionalmente:

```text
Robot_CommandStringBuilder
```

Obiettivo:

```text
ROBOT_COMMAND_* -> ROBOT_COMMAND_STRING
```

### Fase 3

Creare un nuovo POU, con nome diverso da `Gestione_Robot`, ad esempio:

```text
Robot_PickMasterDriver
```

Responsabilita':

```text
connettere PickMaster
inviare start progetto
connettere UserHook
inviare ROBOT_COMMAND_STRING quando ROBOT_COMMAND_SENT
gestire errori/timeout
eventualmente leggere risposte
```

## Dati da recuperare ora

Servono dal vecchio progetto o dal robot:

```text
IP_PICKMASTER
PORT_PICKMASTER
IP_USERHOOK
PORT_USERHOOK
formato esatto di String_ToSend
se UserHook risponde con ACK o no
se PickMaster espone READY/BUSY
nome/progetto PickMaster da avviare
```

## Nota critica

Il file recuperato sembra pensato per inviare un buffer intero:

```st
cbLen := SIZEOF(String_ToSend)
pSrc := ADR(String_ToSend)
```

Bisogna capire se `String_ToSend` era:

- una singola stringa
- un array di stringhe
- un buffer byte/stringhe con piu' target

Nel vecchio `sensoreNIR.txt` sembra essere un array popolato da `String_Tmp[j]`.

Questa e' una differenza importante rispetto al nostro nuovo schema, dove conviene inviare un target alla volta.
