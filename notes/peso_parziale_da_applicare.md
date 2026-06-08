# Peso parziale resettabile + comandi scrittura SCADA — DA APPLICARE (rebuild offline)

⚠️ Richiede REBUILD OFFLINE (nuove variabili globali). NON applicabile con Online Change.
Pianificare al prossimo fermo macchina. Applicare su tutte e 4 le macchine (.31/.32/.33/.34).

---

## 1. GLOBAL_VARIABLES.EXP — sezione VAR_GLOBAL PERSISTENT

Aggiungere dopo `PESO_TOTALE:REAL;`:

```pascal
PESO_PARZIALE:REAL;          (*Peso parziale resettabile da SCADA / commessa*)
RESET_PESO_PARZIALE:BOOL;    (*Comando reset peso parziale*)
```

---

## 2. PROCESSING.EXP — accumulo peso (righe 120-122 attuali)

SOSTITUIRE il blocco:
```pascal
IF SPEED > 0.5 AND PESO_MATERIALE>0 AND Linee>0 AND Totale_perc_selezionato>parziale AND NIR_ATTIVO THEN
	PESO_TOTALE:=PESO_TOTALE+((Totale_perc_selezionato-parziale)*((UDINT_TO_REAL(PESO_MATERIALE)/90000)*(6*SPEED*1000/Linee))/1000); parziale:=Totale_perc_selezionato;
END_IF
```

CON (calcola l'incremento una volta sola e lo somma a entrambi):
```pascal
IF SPEED > 0.5 AND PESO_MATERIALE>0 AND Linee>0 AND Totale_perc_selezionato>parziale AND NIR_ATTIVO THEN
	incremento_peso:=(Totale_perc_selezionato-parziale)*((UDINT_TO_REAL(PESO_MATERIALE)/90000)*(6*SPEED*1000/Linee))/1000;
	PESO_TOTALE:=PESO_TOTALE+incremento_peso;
	PESO_PARZIALE:=PESO_PARZIALE+incremento_peso;
	parziale:=Totale_perc_selezionato;
END_IF
```

Dichiarare nella VAR di Processing: `incremento_peso: REAL;`

---

## 3. PROCESSING.EXP — reset peso parziale

Aggiungere vicino al blocco `IF Reset_Peso THEN ... END_IF` (riga 124):
```pascal
IF RESET_PESO_PARZIALE THEN
	PESO_PARZIALE:=0;
	RESET_PESO_PARZIALE:=FALSE;
END_IF
```

---

## 4. PROCESSING.EXP — mappatura Modbus

### Lettura (Fase 1, dopo riga 298):
```pascal
Modbus_Area[43] := REAL_TO_WORD(PESO_PARZIALE * 10.0);
```

### Scrittura (Fase 3, nuova sezione dopo riga 309):
```pascal
(* --- FASE 3: COMANDI IN SCRITTURA DA SCADA --- *)
(* Reset peso parziale: SCADA scrive 1 → PLC azzera e rimette 0 *)
IF Modbus_Area[44] = 1 THEN
	RESET_PESO_PARZIALE := TRUE;
	Modbus_Area[44] := 0;
END_IF
```

---

## Mappa registri nuovi

| Modbus_Area | Reg. SCADA (Beckhoff) | Daniele (+1) | Direzione | Variabile |
|---|---|---|---|---|
| [43] | 12331 | 12332 | lettura | PESO_PARZIALE ×10 |
| [44] | 12332 | 12333 | scrittura | reset peso parziale (1=reset) |

⚠️ LIMITE WORD: PESO_PARZIALE ×10 va in overflow oltre 6553,5 kg.
Va bene per un parziale resettato regolarmente (turno/commessa).
Se serve gestire parziali più grandi → usare 2 registri (DWORD) — da concordare con Daniele.

⚠️ NUM_LOAD_ID / ricetta (12339) e Trigger (12338): NON toccare senza accordo Daniele.

---

## Da concordare con Daniele prima di applicare
- Conferma che vuole il campo "peso parziale" + pulsante reset a interfaccia
- Conferma indirizzi 12332/12333 liberi lato suo (no conflitti con altre macchine/registri)
- Cambio ricetta: logica 12339/CMD_LOAD GIÀ presente nel PLC, serve solo che lui aggiunga il campo scrivibile
