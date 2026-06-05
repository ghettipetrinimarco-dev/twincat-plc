# Sessione 6 — 2026-05-27 — Import TwinCAT 2

## Obiettivo
Importare il pacchetto .EXP del progetto robot in TwinCAT 2 PLC Control
e arrivare al primo build pulito (o con soli warning accettabili).

---

## Cosa abbiamo fatto

### Round 1 — Prima zip (v1/v2)
- Generati tutti i file .EXP: 6 POU + 4 TYPE + GVL + task/var/plc/alarm config + 5 lib stubs + workspace
- **Problema:** Tutti i PROGRAM .EXP mancavano di `END_PROGRAM`, FB_Segmentazione mancava di `END_FUNCTION_BLOCK`
- **Sintomo:** Error 3554 "Task entry 'MAIN' must be a program" — TC2 non riconosceva nessun POU come valido
- **Fix:** Aggiunto `END_PROGRAM` a tutti i PROGRAM .EXP, `END_FUNCTION_BLOCK` a FB_SEGMENTAZIONE.EXP

### Round 2 — Zip v2 (con END_PROGRAM)
- Import eseguito: errori 3403 (×5 per lib stubs + Workspace) e 3415 (alarm config)
- **Problema scoperto:** L'utente ha importato nel progetto ESISTENTE "exper.pro" invece di un progetto nuovo
- **Problema aggiuntivo:** I file STANDARD.LIB.EXP, TCBASE.LIB.EXP, ecc. hanno formato LIBRARY (binario), non importabili come oggetti progetto TC2. Causano Error 3403 con nome vuoto.
- **Sintomo:** Data types tab vuoto, Error 3554 ancora presente
- **Fix:** Rimossi i 6 file non importabili dalla zip (5 lib stubs + WORKSPACE.EXP). Istruzioni per progetto NUOVO vuoto.

### Round 3 — Zip v3 (file correnti)
- 16 file .EXP puliti (nessun lib stub, nessun workspace)
- Utente deve:
  1. Aprire TwinCAT PLC Control
  2. File → New → "PC or CX (x86)"
  3. Importare i 16 file (NON in exper.pro)
  4. Aggiungere le 5 librerie via Library Manager
  5. Build F11

**Stato al momento di scrivere queste note: l'utente non ha ancora confermato il risultato del Round 3.**

---

## Cosa NON siamo riusciti a fare (ancora)

| Blocco | Causa | Prossimo passo |
|---|---|---|
| Build F11 del progetto robot | Non ancora raggiunto — import in corso (v3) | Utente deve fare import corretto + build |
| Verifica compilazione ST | Impossibile senza TC2 installato su questa macchina | Solo l'utente può compilare |
| Test offline con SIM_Robot | Build non ancora riuscito | Dipende dal build |
| Configurazione System Manager | Richiede hardware fisico (encoder EtherCAT) | Fase successiva al build |

---

## File chiave

| File | Posizione | Stato |
|---|---|---|
| Zip import pronta | `robot/twincat_project_v3.zip` | ✅ 16 file, pronta |
| Procedura import | `robot/twincat_project/IMPORT_GUIDE.md` | ✅ Aggiornata |
| Tutti i POU sorgente | `robot/*.txt` | ✅ Verificati e corretti |
| Task configuration | `robot/twincat_project/TASK_CONFIGURATION.EXP` | ✅ 3 task, END_RESOURCE |
| GVL robot | `robot/twincat_project/GLOBAL_VARIABLES.EXP` | ✅ Completo |

---

## Bug corretti in questa sessione (su file sorgente)

Tutti i fix sono stati applicati ai file nella cartella `robot/twincat_project/`:

1. **END_PROGRAM mancante** in tutti i PROGRAM .EXP
2. **END_FUNCTION_BLOCK mancante** in FB_SEGMENTAZIONE.EXP
3. **SENSORE_NIR**: rimossi usi di variabili non dichiarate nel contesto robot (`cancella_espulsione`, `String_line_tmp`, `First_track`)
4. **GESTIONE_ENCODER_ROBOT**: rimosso gate `IF NOT ENABLE` (logica licenza non usata nel robot)
5. **GESTIONE_ROBOT**: `SystemTaskInfoArr[3]` → `[2]` (task 2 = Gestione_Robot_Task)
6. **GESTIONE_ROBOT**: stato ATTESA_ACK — errore ACK va a RUNNING, non a CHIUDI_RICONNETTI (ACK non bloccante)
7. **SIM_Robot**: `in_pausa := TRUE` mancante nel branch burst completion
8. **SIM_Robot**: `REAL_TO_TIME` non esiste in TC2 → `DWORD_TO_TIME(REAL_TO_DWORD(...))`
9. **SIM_Robot**: array init `[0,1,2,3]` → `(0, 1, 2, 3)` (IEC 61131-3)
10. **FB_Segmentazione**: `FOR t := 0 TO 5` → `FOR t := 0 TO MAX_BLOBS - 1`
11. **GVL**: aggiunto `matrix_data`, `matrix_data_bool`, `matrix_data_bool_inq` (usati da sensoreNIR)

---

## Prossima sessione

Priorità immediata: attendere conferma build F11 dall'utente e correggere eventuali errori di compilazione.

Poi:
- Configurare System Manager (encoder EtherCAT)
- Test offline con SIM_Robot (SIM_ATTIVA := TRUE)
- Accesso al controller ABB per IP/porta TCP e caricamento RAPID
