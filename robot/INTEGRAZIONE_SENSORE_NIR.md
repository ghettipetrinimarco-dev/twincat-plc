# Come integrare FB_Segmentazione in Sensore_NIR

## 1. Aggiungere istanza FB nel VAR di Sensore_NIR

```pascal
VAR
    ...
    segmentazione : FB_Segmentazione;   (* <-- aggiungere *)
    ...
END_VAR
```

## 2. Rimuovere la generazione stringa per-traccia (il bug)

Nel loop `FOR indice:=1 TO NUM_TRACKS_NIR DO` dentro lo stato 2,
**rimuovere** tutto il blocco che costruisce `concat_1..concat_11` e `String_line_tmp`.

Il blocco da rimuovere inizia con:
```pascal
(* START CHAR and UITAG *)
concat_1:=CONCAT(START_CHAR,INT_TO_STRING(UiTag));
```
e finisce con:
```pascal
String_line_tmp := CONCAT(concat_1, CONCAT(...));
IF First_track THEN First_track:=FALSE; END_IF
UiTag:=UiTag+1;
```

**Tenere** tutto il resto del loop: track_mat_select, indice_codice_mat,
NUM_CAMPIONATI, matrix_data, storico, ecc.

## 3. Chiamare FB_Segmentazione dopo il loop tracce

Subito dopo `END_FOR` (fine loop tracce), prima di `String_Tmp[index_nir]:=...`,
**aggiungere**:

```pascal
(* Segmentazione oggetti — chiamata una volta per scan *)
segmentazione(
    track_mat_select  := MSI_data[index_nir].track_mat_select,
    indice_codice_mat := MSI_data[index_nir].indice_codice_mat,
    encoder_pos       := MSI_data[index_nir].Position,
    enable            := NIR_ATTIVO
);
```

## 4. Rimuovere la logica Trig/String_ToSend da Sensore_NIR

Le righe da rimuovere:
```pascal
(* --- DA RIMUOVERE --- *)
FOR j:=0 TO BUFFER_SIZE DO
    String_ToSend[j]:=String_Tmp[j];
END_FOR
Trig:=TRUE;
```

`Trig` e `String_ToSend` saranno ora gestiti da Gestione_Robot
direttamente leggendo OBJ_queue.

## 5. Modificare Gestione_Robot per leggere OBJ_queue

Invece di aspettare `Trig` e inviare `String_ToSend`,
leggere dalla coda e formare la stringa per ogni oggetto:

```pascal
(* Stato RUNNING — leggi coda oggetti e invia al robot *)
3:
IF obj_tail <> obj_head THEN   (* coda non vuota *)
    IF OBJ_queue[obj_tail].valido AND NOT OBJ_queue[obj_tail].inviato THEN

        (* Costruisci stringa per questo oggetto *)
        String_Pick := CONCAT('@', INT_TO_STRING(UiTag_robot));
        String_Pick := CONCAT(String_Pick, CONCAT(',', REAL_TO_STRING(OBJ_queue[obj_tail].X)));
        (* Y fisico = encoder_start / IMPULSI_ENCODER * SVILUPPO_ESTERNO + DISTANZA_ROBOT_MM *)
        String_Pick := CONCAT(String_Pick, CONCAT(',', REAL_TO_STRING(
            UDINT_TO_REAL(OBJ_queue[obj_tail].Y) / IMPULSI_ENCODER * SVILUPPO_ESTERNO
            + DISTANZA_ROBOT_MM)));
        String_Pick := CONCAT(String_Pick, CONCAT(',', REAL_TO_STRING(ALTEZZA)));
        String_Pick := CONCAT(String_Pick, CONCAT(',', REAL_TO_STRING(GRADI_ROTAZIONE)));
        String_Pick := CONCAT(String_Pick, CONCAT(',', REAL_TO_STRING(ATTESA_PRESA)));
        String_Pick := CONCAT(String_Pick, CONCAT(',', REAL_TO_STRING(
            X_BOX[OBJ_queue[obj_tail].indice_box])));
        String_Pick := CONCAT(String_Pick, CONCAT(',', REAL_TO_STRING(
            Y_BOX[OBJ_queue[obj_tail].indice_box])));
        String_Pick := CONCAT(String_Pick, CONCAT(',', REAL_TO_STRING(
            Z_BOX[OBJ_queue[obj_tail].indice_box])));
        String_Pick := CONCAT(String_Pick, CONCAT(',', REAL_TO_STRING(ATTESA_DEPOSITO)));
        String_Pick := CONCAT(String_Pick, ',#');

        UiTag_robot := UiTag_robot + 1;

        (* Invia String_Pick via TCP *)
        send_data := TRUE;
    END_IF
END_IF
```

## Schema flusso dati aggiornato

```
Sensore_NIR (200µs)
  └─ riceve scan UDP
  └─ loop tracce → popola track_mat_select[], indice_codice_mat[]
  └─ chiama FB_Segmentazione()
        └─ trova blob nella scan
        └─ matcha a tracker esistenti
        └─ se tracker inattivo da OBJ_GAP_ENCODER → push in OBJ_queue[]

Gestione_Robot (10ms)
  └─ legge OBJ_queue[obj_tail]
  └─ costruisce stringa @X,Y,Z,...,#
  └─ invia via TCP al robot
  └─ avanza obj_tail
```

## Parametri da calibrare prima del test

| Parametro | Dove | Valore default | Note |
|---|---|---|---|
| `SCAN_DISTANCE` | GVL_ROBOT | 3.5 mm | Misurare velocità nastro / linee NIR/s |
| `DISTANZA_ROBOT_MM` | GVL_ROBOT | 0.0 | Distanza fisica NIR → punto di presa |
| `OBJ_GAP_ENCODER` | GVL_ROBOT | 50 impulsi | ~131mm gap tra oggetti |
| `OBJ_TRACK_TOLERANCE` | GVL_ROBOT | 3 tracce | Margine laterale per stesso oggetto |
| `ALTEZZA` | GVL_ROBOT | 200.0 mm | Quota Z di presa — misurare |
| `X_BOX[]`, `Y_BOX[]`, `Z_BOX[]` | GVL_ROBOT | 0.0 | Posizioni box deposito — misurare |
| `IP_ROBOT`, `PORT_ROBOT` | GVL_ROBOT | placeholder | Da configurare sul prototipo |

