# Protocollo robot provvisorio

Aggiornato: 2026-05-26

## Scopo

Documentare il protocollo deducibile dal vecchio tentativo in `robot/sensoreNIR.txt` e proporre una versione minima per simulatore/robot.

Questo documento non certifica che il robot reale usi davvero questo protocollo.

## Evidenza trovata nel codice

In `robot/sensoreNIR.txt` sono presenti:

```st
SEP:STRING:=',';
START_CHAR:STRING := '@';
END_CHAR: STRING:= '#';
```

Quando una traccia contiene un materiale attivo, il codice costruisce una stringa con:

```st
concat_1 := START_CHAR + UiTag
concat_2 := SEP + indice
concat_3 := SEP + index_nir*SCAN_DISTANCE+DISTANCE_OFFSET
concat_4 := SEP + ALTEZZA
concat_5 := SEP + GRADI_ROTAZIONE
concat_6 := SEP + ATTESA_PRESA
concat_7 := SEP + X_BOX[indice_box]
concat_8 := SEP + Y_BOX[indice_box]
concat_9 := SEP + Z_BOX[indice_box]
concat_10 := SEP + ATTESA_DEPOSITO
concat_11 := SEP + END_CHAR
```

Commento presente nel codice:

```text
Expected output:: @0;10;10;10;0;0;32;34;43;0;#
```

Nota: il commento usa `;`, ma il codice usa `,`.

## Formato dedotto

Dal codice si deduce questo formato:

```text
@id,x_pick,y_pick,z_pick,angle,wait_pick,x_drop,y_drop,z_drop,wait_drop,#
```

Tabella campi:

| Campo | Origine nel codice | Significato probabile | Stato |
|---|---|---|---|
| `id` | `UiTag` | ID target | Da confermare |
| `x_pick` | `indice` | Traccia NIR o coordinata laterale | Critico da confermare |
| `y_pick` | `index_nir*SCAN_DISTANCE+DISTANCE_OFFSET` | Posizione longitudinale | Formula debole |
| `z_pick` | `ALTEZZA` | Quota presa | Da confermare |
| `angle` | `GRADI_ROTAZIONE` | Rotazione utensile | Da confermare |
| `wait_pick` | `ATTESA_PRESA` | Tempo attesa presa | Da confermare |
| `x_drop` | `X_BOX[indice_box]` | X deposito | Da confermare |
| `y_drop` | `Y_BOX[indice_box]` | Y deposito | Da confermare |
| `z_drop` | `Z_BOX[indice_box]` | Z deposito | Da confermare |
| `wait_drop` | `ATTESA_DEPOSITO` | Tempo attesa deposito | Da confermare |
| end | `#` | Fine messaggio | Da confermare |

## Problemi del formato vecchio

### Separatore incoerente

Codice:

```text
,
```

Commento:

```text
;
```

Serve sapere quale separatore accetta il robot/controller.

### X non e' una coordinata fisica

Il vecchio codice manda `indice`, cioe' la traccia NIR.

Per il robot serve una coordinata fisica:

```text
x_pick_mm = ROBOT_X_ORIGIN_MM + CenterTrack * ROBOT_TRACK_PITCH_MM
```

### Y non dovrebbe dipendere da `index_nir`

`index_nir` e' un indice circolare del buffer, non una posizione fisica assoluta.

Per un robot reale serve:

```text
position_impulses = target.PositionImpulses
y_pick_mm = funzione(position_impulses)
```

Oppure, se il robot fa conveyor tracking internamente, serve inviare posizione encoder o timestamp.

### Manca ACK

Il vecchio codice alza `Trig`, ma non documenta:

- chi legge `String_ToSend[]`
- quando il robot conferma ricezione
- quando il PLC puo' cancellare il target
- cosa succede se il robot e' occupato

### Manca gestione busy/error

Un protocollo solo "fire and forget" non basta per produzione.

## Protocollo minimo consigliato per simulatore

Per il primo simulatore, usare messaggi testuali simili al vecchio formato, ma con campi dichiarati.

### Messaggio PLC -> robot

```text
@PICK,id,x_pick_mm,y_pick_mm,z_pick_mm,angle_deg,wait_pick_ms,x_drop_mm,y_drop_mm,z_drop_mm,wait_drop_ms#
```

Esempio:

```text
@PICK,12,385.0,0.0,120.0,0.0,50,1000.0,250.0,180.0,50#
```

### Messaggio robot -> PLC

ACK ricezione:

```text
@ACK,id#
```

Pick riuscito:

```text
@DONE,id#
```

Pick fallito:

```text
@FAIL,id,error_code#
```

Robot pronto:

```text
@READY#
```

Robot occupato:

```text
@BUSY,id#
```

Errore robot:

```text
@ERROR,error_code#
```

## Handshake minimo

Sequenza consigliata:

```text
1. Robot -> PLC: READY
2. PLC seleziona target in_window
3. PLC -> Robot: PICK
4. Robot -> PLC: ACK
5. PLC marca target sent/accepted
6. Robot -> PLC: DONE oppure FAIL
7. PLC marca target picked/failed
8. Robot torna READY
```

Timeout:

| Timeout | Azione PLC |
|---|---|
| Nessun `ACK` | robot comm error, target non confermato |
| Nessun `DONE/FAIL` | robot timeout, target failed o stato da verificare |
| Robot non `READY` e target esce finestra | target missed |

## Variante I/O digitale minima

Se il robot non puo' usare socket/stringhe, si puo' fare una prima versione con I/O:

PLC -> robot:

| Segnale | Significato |
|---|---|
| `Robot_TargetValid` | target disponibile |
| `Robot_TargetId` | ID su word/int |
| `Robot_X` | coordinata X via word/real mapping |
| `Robot_Y` | coordinata Y via word/real mapping |
| `Robot_Z` | coordinata Z via word/real mapping |
| `Robot_Box` | box deposito |

Robot -> PLC:

| Segnale | Significato |
|---|---|
| `Robot_Ready` | pronto |
| `Robot_Busy` | occupato |
| `Robot_Ack` | target ricevuto |
| `Robot_Done` | presa completata |
| `Robot_Fail` | presa fallita |
| `Robot_Error` | errore |

Questa variante e' meno elegante ma puo' essere piu' semplice se il controller robot ha gia' I/O digitali o fieldbus.

## Cosa chiedere per confermare il protocollo

1. Il robot/controller accetta messaggi che iniziano con `@` e finiscono con `#`?
2. Il separatore corretto e' `,` o `;`?
3. I campi sono nell'ordine dedotto?
4. Le coordinate sono in millimetri?
5. La prima coordinata e' X laterale o numero traccia?
6. Il robot calcola da solo il movimento sul conveyor o riceve una posizione statica?
7. Il robot ha conveyor tracking interno?
8. Esiste ACK?
9. Esiste segnale ready/busy?
10. Dove veniva letto `String_ToSend[]`?

## Raccomandazione

Per Fase 1 usare questo protocollo solo come formato di debug/simulazione.

Non collegarlo al robot reale finche' non abbiamo conferma del controller.

