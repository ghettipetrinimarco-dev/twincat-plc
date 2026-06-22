# Sessione 8 — 2026-06-08 — Modbus v5.0 + diagnostica dati gestionale

## Attività principali

### Fix TeamViewer Beckhoff
- .31 e .32 non avevano internet sul Beckhoff → TeamViewer mostrava solo IP locali
- Risolto configurando gateway sulla scheda di rete 192.168.1.x
- Ora raggiungibili da remoto

### Fix registro 12328 su .31 e .32
- Stessa modifica di sessione 7 (ENABLE → SPEED>0.5 AND NIR_ATTIVO AND DIAGNOSTICA_OK)
- Applicata via Online Change su entrambe le Beckhoff
- Confermato: tutte e 4 le macchine in "In lavoro" nel gestionale Evergreen

### Diagnosi dati gestionale Evergreen
Analisi live via TwinCAT PLC Control su .31:

| Campo gestionale | Valore mostrato | Causa |
|---|---|---|
| Stato attuale | "In lavoro" | ✅ Corretto dopo fix |
| Peso totale | ~393 kg | ❌ OVERFLOW: 131477×10 > WORD max |
| Carico minimo | 0 | ❌ Daniele legge registro sbagliato (PLC ha 22.81) |
| Pressione aria | 0 | ✅ Corretto: sensori fisici non installati su .31/.32 |
| Flussostato aria | 0 | ✅ Corretto: stessa causa |
| Perc. selezionato 2 | 7.9% | ✅ Corretto |
| Perc. campionato 2 | 12.2% | ✅ Corretto |

### Modbus v5.0 — nuovi registri

Tutti Online Change (nessuna nuova variabile, solo scrittura in slot Modbus_Area già esistenti).

**Registri aggiunti (lettura):**
- `[1]` = SPEED × 10 → velocità nastro (sostituisce slot vuoto)
- `[5]` = PESO_TOTALE HIGH WORD → fix overflow DWORD
- `[43]` = LINEE → linee NIR/s (salute sensore)
- `[44]` = ABIL_NIR stato → 1=NIR online

**Registri aggiunti (scrittura SCADA→PLC):**
- `[45]` = ABIL_NIR comando → 1=abilita, 2=spegni, auto-reset a 0
- `[46]` = Reset contatori → bit0=RESET_SELEZIONATI, bit1=RESET_CAMPIONATI

**Fix esistenti:**
- `[39]` = fix ENABLE→condizione lavorazione (nel repo, già in produzione da sessione 7)
- `[41]` = PESO_TOTALE LOW WORD (era ×10 → overflow)

**ETH_LINK_OK:**
- `[47]` = ETH_LINK_OK → 1=link sensore NIR presente

### Problema ricetta da Mago
- Mago scrive 2 su registro 12339 → NUM_LOAD_ID diventa 2 nel PLC ✅
- Ma il panel PC mostra ancora ricetta 3
- Causa probabile: CMD_LOAD cancellato silenziosamente da Sensore_NIR
  (condizione: `IF CMD_LOAD AND ABIL_NIR AND (Stato=2 OR calib_ok) THEN ... ELSE CMD_LOAD:=FALSE`)
- Da verificare: All_load, Stato, ABIL_NIR al momento del comando
- In sospeso (attesa accesso macchina)

## File modificati
- `src/PROCESSING.EXP` — Modbus v5.0 completo
- `docs/modbus/mappa-registri.md` — aggiornata con tutti i nuovi registri
- `notes/peso_parziale_da_applicare.md` — preparato codice PESO_PARZIALE (rebuild offline)
- `CONTEXT.md` — aggiornato

## Da fare prossima sessione
1. Applicare Modbus v5.0 via Online Change su tutte e 4 le macchine
2. Comunicare a Daniele nuovi registri + schema lettura PESO DWORD
3. Chiedere a Daniele quale registro legge per "Carico minimo" (sospetto indirizzo sbagliato)
4. Verificare CMD_LOAD su .31 con Mago → diagnosticare problema ricetta (All_load, Stato)
5. Pianificare rebuild offline per PESO_PARZIALE (vedi notes/peso_parziale_da_applicare.md)
