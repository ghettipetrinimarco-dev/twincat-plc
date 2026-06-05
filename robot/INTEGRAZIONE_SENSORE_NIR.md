# Modifiche applicate a sensoreNIR.txt — v2.0

> Le modifiche sono già state applicate al file `sensoreNIR.txt` in questa cartella.
> Questo documento descrive cosa è cambiato e perché, per riferimento futuro.

---

## Cosa è cambiato

### 1. VAR — Rimosse variabili stringa, aggiunta istanza FB

**Rimosse:**
- `String_Tmp[0..BUFFER_SIZE] OF STRING` — array di stringhe per-scan (bug sovrascrittura)
- `String_line_tmp`, `First_track` — variabili di supporto generazione stringa
- `concat_1..concat_11` — 11 variabili STRING per concatenazione
- `UiTag : INT` — contatore tag (spostato in GVL_ROBOT come `UiTag_robot`)

**Aggiunta:**
```pascal
segmentazione : FB_Segmentazione;
```

### 2. Loop tracce — Rimosso blocco concat, tenuta sola flag

**Rimosso** (era il Bug 1 — sovrascrittura):
```pascal
indice_box := MATERIALI_ATTIVI_BOX[i];
concat_1 := CONCAT(START_CHAR, INT_TO_STRING(UiTag));
concat_2 := CONCAT(SEP, INT_TO_STRING(indice));
... (9 righe di concat)
String_line_tmp := CONCAT(concat_1, CONCAT(...));
UiTag := UiTag + 1;
```

**Tenuto:**
```pascal
MSI_data[index_nir].track_mat_select[indice] := TRUE;
MSI_elab[index_nir].track_mat_select[indice] := TRUE;
```
Queste due righe alimentano FB_Segmentazione nella scan successiva.

### 3. Dopo END_FOR — Aggiunta chiamata FB_Segmentazione

**Rimosso:**
```pascal
String_Tmp[index_nir] := String_line_tmp;
```

**Aggiunto:**
```pascal
segmentazione(
    track_mat_select  := MSI_data[index_nir].track_mat_select,
    indice_codice_mat := MSI_data[index_nir].indice_codice_mat,
    encoder_pos       := Counter,
    enable            := NIR_ATTIVO
);
```

`Counter` è la variabile encoder `AT %I*:UDINT` già presente in `Gestione_Encoder`.
Viene passata direttamente per avere la posizione encoder al momento della scan.

### 4. Buffer flip — Rimossa copia String_ToSend e Trig

**Rimosso:**
```pascal
FOR j:=0 TO BUFFER_SIZE DO
    String_ToSend[j] := String_Tmp[j];
END_FOR
Trig := TRUE;
```

**Tenuto:**
```pascal
index_nir := 0;
```

La coda pick è ora gestita continuamente da FB_Segmentazione, non a buffer pieno.

### 5. Bottom — Rimossa logica Out_1/Trig

**Rimosso:**
```pascal
Out_1 := Trig;
Ritardo_Trig.IN := Trig;
Ritardo_Trig.PT := INT_TO_TIME(TRIG_DELAY_RESET);
Ritardo_Trig();
IF Ritardo_Trig.Q THEN Trig := FALSE; END_IF
```

`Out_1` era l'uscita fisica di trigger verso PickMaster. Non più necessaria.

---

## Nota su `Counter` come encoder_pos

`Counter AT %I*:UDINT` è dichiarato in `Gestione_Encoder`, non in `Sensore_NIR`.
In TwinCAT 2, le variabili `AT %I*` sono globali al task se il task è condiviso.

Se `Counter` non è visibile da `Sensore_NIR`, alternative:
1. Aggiungere `Counter` al GVL (rinominare come `ENCODER_COUNTER : UDINT`)
   e mappare `%I*` lì invece che in `Gestione_Encoder`
2. Usare `MSI_data[index_nir].Position` — viene popolato a 0 all'arrivo e poi
   incrementato dal task encoder, quindi al momento della chiamata FB vale 0.
   **In questo caso usare posizione assoluta dal GVL encoder invece.**

**Soluzione raccomandata:** aggiungere in GVL:
```pascal
ENCODER_COUNTER AT %I* : UDINT;   (* mappa stessa variabile HW di Counter in Gestione_Encoder *)
```
e passare `ENCODER_COUNTER` come `encoder_pos` alla FB.

