# Specifica Robot_PickMasterDriver

Aggiornato: 2026-05-26

## Scopo

Definire il futuro driver reale per comunicare con ABB PickMaster/UserHook, usando come riferimento:

```text
robot/gestionerobot.txt
```

Questa e' una specifica offline.

Non e' ancora codice da importare.

## Nome POU

Usare un nome nuovo:

```text
Robot_PickMasterDriver
```

Non usare:

```text
Gestione_Robot
```

Motivo:

```text
Gestione_Robot e' gia' il simulatore/core nello scaffold
```

## Responsabilita'

Il driver deve:

1. Connettersi al socket PickMaster.
2. Inviare comando avvio progetto.
3. Connettersi al socket UserHook.
4. Attendere un comando robot valido.
5. Inviare il comando al UserHook.
6. Gestire timeout/errori di invio.
7. Chiudere UserHook.
8. Inviare comando stop progetto a PickMaster.
9. Chiudere PickMaster.

## Input dal core robot

Il driver non deve leggere direttamente `ROBOT_TARGETS`.

Deve leggere solo:

```text
ROBOT_COMMAND_READY
ROBOT_COMMAND_SENT
ROBOT_COMMAND_ID
ROBOT_COMMAND_PICK_X
ROBOT_COMMAND_PICK_Y
ROBOT_COMMAND_PICK_Z
ROBOT_COMMAND_PICK_ANGLE
ROBOT_COMMAND_WAIT_PICK_MS
ROBOT_COMMAND_DROP_X
ROBOT_COMMAND_DROP_Y
ROBOT_COMMAND_DROP_Z
ROBOT_COMMAND_WAIT_DROP_MS
ROBOT_COMMAND_STRING
```

Nota:

```text
ROBOT_COMMAND_STRING e' opzionale.
Se il protocollo reale puo' ricevere campi binari/numerici, meglio non dipendere dalla stringa.
```

## Variabili globali da proporre

Configurazione:

```text
ROBOT_PICKMASTER_ENABLED : BOOL := FALSE
ROBOT_PICKMASTER_IP : STRING(15)
ROBOT_PICKMASTER_PORT : UINT
ROBOT_USERHOOK_IP : STRING(15)
ROBOT_USERHOOK_PORT : UINT
ROBOT_PICKMASTER_TIMEOUT : TIME := T#10S
```

Stato:

```text
ROBOT_PICKMASTER_CONNECTED : BOOL
ROBOT_USERHOOK_CONNECTED : BOOL
ROBOT_PICKMASTER_RUNNING : BOOL
ROBOT_PICKMASTER_BUSY : BOOL
ROBOT_PICKMASTER_ERROR : BOOL
ROBOT_PICKMASTER_ERROR_CODE : UDINT
ROBOT_PICKMASTER_LAST_SENT_ID : INT
ROBOT_PICKMASTER_SEND_COUNT : UDINT
ROBOT_PICKMASTER_FAIL_COUNT : UDINT
```

## Stati proposti

| Stato | Nome | Azione |
|---|---|---|
| `0` | `IDLE` | Attesa enable |
| `10` | `CONNECT_PICKMASTER` | `FB_SocketConnect` verso PickMaster |
| `20` | `START_PROJECT` | invia `16#00,16#13` |
| `30` | `CONNECT_USERHOOK` | `FB_SocketConnect` verso UserHook |
| `40` | `READY` | attesa `ROBOT_COMMAND_SENT` |
| `50` | `SEND_COMMAND` | invia comando a UserHook |
| `60` | `WAIT_SEND_DONE` | attesa fine `FB_SocketSend` |
| `70` | `ERROR` | stato errore/diagnostica |
| `80` | `CLOSE_USERHOOK` | chiusura UserHook |
| `90` | `STOP_PROJECT` | invia `16#00,16#14` |
| `100` | `CLOSE_PICKMASTER` | chiusura PickMaster |

## Comandi PickMaster recuperati

Da `robot/gestionerobot.txt`:

```text
CMD_AVVIA_PROGETTO  = 16#00, 16#13
CMD_ARRESTA_PROGETTO = 16#00, 16#14
```

Da confermare con manuale o test.

## Invio UserHook

Il file storico invia:

```st
cbLen := SIZEOF(String_ToSend)
pSrc := ADR(String_ToSend)
```

Per il nuovo driver ci sono due opzioni.

### Opzione A - Stringa singolo target

Inviare:

```text
ROBOT_COMMAND_STRING
```

Pro:

- vicino al vecchio formato
- facile da leggere/debuggare

Contro:

- dipende da conversione stringa
- non sappiamo se UserHook voleva array/buffer

### Opzione B - Buffer compatibile vecchio

Ricostruire una struttura simile a:

```text
String_ToSend
```

Pro:

- piu' vicino al vecchio progetto

Contro:

- non sappiamo tipo/dimensione esatta
- rischia di riportare dentro il vecchio errore: target per scan/traccia invece di target per oggetto

## Strategia consigliata

Prima implementazione reale:

```text
un target alla volta
ROBOT_COMMAND_STRING come payload
send solo quando ROBOT_COMMAND_SENT TRUE
timeout su FB_SocketSend
nessun nuovo target se driver busy/error
```

Poi, se UserHook richiede buffer vecchio:

```text
adattatore ROBOT_COMMAND_* -> buffer compatibile String_ToSend
```

## Errori da gestire

| Errore | Reazione |
|---|---|
| PickMaster non si connette | `ROBOT_PICKMASTER_ERROR := TRUE` |
| Start progetto fallisce | chiudi PickMaster e segnala errore |
| UserHook non si connette | stop progetto, chiudi PickMaster, errore |
| Send comando fallisce | incrementa fail count, driver error |
| Driver busy e nuovo target | non inviare, lascia al core decidere missed/failed |
| Disable manuale | chiudi UserHook, stop progetto, chiudi PickMaster |

## Domande aperte

1. `IP_PICKMASTER` e `IP_USERHOOK` sono uguali o diversi?
2. Quali sono le porte TCP reali?
3. UserHook vuole stringa singola o array/buffer?
4. UserHook manda ACK?
5. PickMaster espone stato ready/busy/error?
6. I comandi `16#00,16#13` e `16#00,16#14` sono confermati dal manuale?
7. Il comando deve includere `@...#` o solo payload senza delimitatori?

## Regola di sicurezza

Il driver reale non deve partire di default.

Default:

```text
ROBOT_PICKMASTER_ENABLED := FALSE
```

Prima di abilitarlo servono:

- compile TwinCAT
- test core robot
- IP/porte confermati
- robot in stato sicuro
- consenso tecnico in macchina
