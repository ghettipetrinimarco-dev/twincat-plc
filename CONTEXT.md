# CONTEXT — Progetto TwinCAT PLC (Selezionatrice + Robot)
Ultimo aggiornamento: 2026-06-05

---

## REGOLE OPERATIVE (leggere prima di tutto)

- **Regola Zero:** Se mancano informazioni → fermati e chiedi. Non procedere con supposizioni.
- **Nessuna allucinazione tecnica:** Nomi variabili, indirizzi Modbus, parametri I/O devono provenire dai file di contesto o da conferma esplicita.
- **No people-pleasing:** Non dare una risposta a tutti i costi.
- **Registro 12338 (Trigger) e 12339 (Numero Modello):** Non modificare senza accordo esplicito con Daniele Goffi (gestionale SCADA).

---

## PROGETTO 1 — SELEZIONATRICE (4 macchine in rete)

### Architettura
- 4 macchine Beckhoff TwinCAT 2 SoftPLC: IP .31 / .32 / .33 / .34 (subnet 192.168.1.x)
- Ogni macchina ha il proprio progetto `.pro` (versione base: `Sort_Selection_v_1_6.pro`)
- Modbus TCP tramite TcModbusSrv (Windows service, porta 502)
- Area Modbus: `Modbus_Area AT %MW0 : ARRAY[0..51] OF WORD`
- Base registro Beckhoff: 0x3000 = 12288 decimale
- **Offset Daniele:** il gestionale SCADA (Daniele Goffi, SELECT Informatica) usa indirizzamento 1-based → aggiunge sempre +1 agli indirizzi della nostra tabella

### Mappa registri Modbus (indirizzamento Beckhoff 0-based)

| Modbus_Area | Reg. Beckhoff | Reg. Daniele (+1) | Variabile | Note |
|---|---|---|---|---|
| [0] | 12288 | 12289 | carico_min * 10 | |
| [2] | 12290 | 12291 | Pressione_aria * 10 | |
| [3] | 12291 | 12292 | Flussostato_aria * 10 | |
| [4] | 12292 | 12293 | intervallo_ore_istantaneo | UDINT→WORD, wrappa se >65535 |
| [6..21] | 12294..12309 | 12295..12310 | PERC_SELEZIONATI[0..15] * 10 | |
| [22..37] | 12310..12325 | 12311..12326 | PERC_CAMPIONATI[0..15] * 10 | |
| [38] | 12326 | 12327 | DIAGNOSTICA_OK (1=OK) | |
| [39] | 12327 | **12328** | **Macchina in lavorazione** (1=sì) | Fix sessione 7 |
| [40] | 12328 | 12329 | KG_MINUTI * 10 | Aggiornato ogni 60s |
| [41] | 12329 | 12330 | PESO_TOTALE * 10 | Overflow WORD su macchine anziane |
| [42] | 12330 | 12331 | NUM_LOAD_ID (ricetta attiva) | |
| [51] | 12339 | 12340 | Cambio ricetta da SCADA | ⚠️ NON toccare senza Daniele |

### Variabili chiave (globali, presenti su tutte le macchine)
- `ENABLE : BOOL` — TRUE = macchina BLOCCATA da licenza (semantica invertita)
- `SPEED : REAL` — velocità nastro in m/s
- `NIR_ATTIVO : BOOL` — sensore NIR attivo e in ricezione dati
- `DIAGNOSTICA_OK : BOOL` — tutti i moduli I/O EtherCAT OK
- `PERC_CAMPIONATI[0..100] : REAL` — % per categoria materiale (101 categorie)
- `PERC_SELEZIONATI[0..100] : REAL` — % materiale selezionato (espulso)
- `PESO_TOTALE : REAL` — peso cumulativo lifetime (REAL 32-bit, va in overflow su macchine anziane)
- `KG_MINUTI : REAL` — delta peso nell'ultimo minuto

---

## STATO FIX MODBUS — Registro 12328 "Macchina in lavorazione"

### Bug originale (tutte le macchine)
```pascal
IF ENABLE THEN Modbus_Area[39] := 1; ELSE Modbus_Area[39] := 0; END_IF;
```
`ENABLE=FALSE` in funzionamento normale → scriveva 0 → gestionale vedeva macchine come spente.

### Fix applicato
```pascal
IF (SPEED > 0.5 AND NIR_ATTIVO AND DIAGNOSTICA_OK) THEN Modbus_Area[39] := 1; ELSE Modbus_Area[39] := 0; END_IF;
```

### Stato per macchina

| Macchina | Fix applicato | Boot project salvato | Verificato ModMaster |
|---|---|---|---|
| .31 | ⏳ da fare | — | — |
| .32 | ⏳ da fare | — | — |
| .33 | ✅ 2026-05-28 | ✅ | ✅ 412328=1 |
| .34 | ✅ 2026-05-28 | ✅ | da verificare |

### Criterio gestionale Daniele (aggiornato 2026-06-04)
Daniele legge **prima** il registro 12328: se = 1 → macchina in lavoro. Altrimenti verifica KG/min come fallback.
Tutte e 4 risultano ora in lavoro nel gestionale ✅

---

## PROBLEMI APERTI — Selezionatrice

### 1. Fix registro 12328 su .31 e .32
**Priorità: alta.** Attualmente usano il fallback KG/min (funziona per ora). Applicare lo stesso fix per rendere il sistema robusto.
Procedura: Backup → Logout → Replace (ENABLE → SPEED>0.5 AND NIR_ATTIVO AND DIAGNOSTICA_OK) → F11 → Online Change → verifica 412328=1.

### 2. PESO_TOTALE overflow su .33 e .34
**Priorità: bassa** (non blocca il funzionamento rilevato).
- Causa: PESO_TOTALE accumulato per anni (>3 milioni kg) → REAL 32-bit perde precisione sui piccoli incrementi → KG_MINUTI resta 0 → registro Modbus [41] è garbage (overflow WORD).
- Soluzione definitiva: cambiare PESO_TOTALE e kg_partial_min da REAL a LREAL (richiede rebuild offline, non Online Change).
- Alternativa immediata: reset PESO_TOTALE (perde storico).

### 3. PERC_CAMPIONATI — verifica coerenza con HMI
Non ancora completata. Somma dei 16 valori trasmessi supera 100% su .33 (anomalia da investigare con accesso al codice completo e ai CODICI_MATERIALI).

---

## PROGETTO 2 — ROBOT PICKER (TwinCAT 2 import)

### Stato import (ultima sessione: 2026-05-27)
- Zip v3 pronta: `robot/twincat_project_v3.zip` (16 file .EXP)
- Procedura: File→New (PC/CX x86) → import 16 file → elimina PLC_PRG → aggiungi 5 lib via Library Manager → F11
- **Build F11 non ancora confermato dall'utente**

### Bug corretti nei file sorgente robot
1. END_PROGRAM mancante in tutti i PROGRAM .EXP
2. END_FUNCTION_BLOCK mancante in FB_SEGMENTAZIONE.EXP
3. SENSORE_NIR: rimossi usi di variabili non dichiarate
4. GESTIONE_ENCODER_ROBOT: rimosso gate IF NOT ENABLE
5. GESTIONE_ROBOT: SystemTaskInfoArr[3]→[2]
6. GESTIONE_ROBOT: stato ATTESA_ACK — errore ACK va a RUNNING
7. SIM_Robot: in_pausa:=TRUE mancante nel branch burst completion
8. SIM_Robot: REAL_TO_TIME → DWORD_TO_TIME(REAL_TO_DWORD(...))
9. SIM_Robot: array init [0,1,2,3] → (0, 1, 2, 3)
10. FB_Segmentazione: FOR t:=0 TO 5 → TO MAX_BLOBS-1
11. GVL: aggiunti matrix_data, matrix_data_bool, matrix_data_bool_inq

---

## STORICO SESSIONI

| # | Data | Argomento | Esito |
|---|---|---|---|
| 1-5 | 2026-05 | Sviluppo codice Modbus selezionatrice + robot | Completato |
| 6 | 2026-05-27 | Import TwinCAT 2 robot (v3 zip) | In attesa build F11 |
| 7 | 2026-05-28 / 06-05 | Debug Modbus .33/.34, fix registro 12328, coordinamento Daniele | Fix .33/.34 ✅, .31/.32 da fare |
