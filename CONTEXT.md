# CONTEXT.md — Fonte di Verità del Progetto

> Aggiornato: 2026-06-08 (sessione 8 — Modbus v5.0: nuovi registri SPEED/LINEE/NIR/ETH, fix PESO_TOTALE overflow DWORD, comandi scrittura ABIL_NIR e reset contatori, fix [39] aggiornato nel repo)
> Leggere sempre prima di toccare qualsiasi file.

---

## Descrizione Progetto
Selezionatrice ottica NIR con scarto pneumatico — 117 tracce, nastro trasportatore.
Il sensore LLA (MSI) rileva il materiale via UDP, TwinCAT elabora e comanda 117 elettrovalvole pneumatiche.
3 macchine identiche in produzione, tutte TwinCAT 2 SoftPLC su Windows.

---

## Macchine

4 macchine totali, organizzate in 2 linee. Ogni linea = 2 nastri in sequenza (materiale passa dalla prima alla seconda).

| IP | Hardware | Linea | Posizione | Runtime |
|---|---|---|---|---|
| 192.168.1.31 | Beckhoff nativo | Lavatrici (dispari) | 1° nastro | TwinCAT 2 SoftPLC |
| 192.168.1.33 | PC Elmak | Lavatrici (dispari) | 2° nastro | TwinCAT 2 SoftPLC |
| 192.168.1.32 | Beckhoff nativo | R4 (pari) | 1° nastro | TwinCAT 2 SoftPLC |
| 192.168.1.34 | PC Elmak | R4 (pari) | 2° nastro | TwinCAT 2 SoftPLC |

Flusso materiale linea lavatrici: ingresso → .31 → .33 → uscita
Flusso materiale linea R4: ingresso → .32 → .34 → uscita

Ogni macchina è un PLC indipendente (nastro proprio, NIR proprio, 117 EV proprie). Nessuna comunicazione diretta PLC↔PLC — coordinazione solo fisica (nastro).

- Gateway: `192.168.1.1` | DNS: `85.159.176.161` / `.162`
- Teleassistenza: TeamViewer / AnyDesk
- Progetto attivo: `Sort_Selection_v1_6.pro` (v1.5 tenuta come backup)

---

## Reti

| Rete | Scopo | Dispositivi |
|---|---|---|
| `192.168.1.x` | Supervisione / Modbus TCP | PLC, SCADA (Daniele) |
| `192.168.0.x` | Campo / NIR (UDP) | TwinCAT (`192.168.0.1`), Sensore LLA (`192.168.0.10`) |

Il sensore NIR è su una subnet separata rispetto alla rete Modbus.

---

## Architettura POU

| POU | Task | Ciclo | Priorità | Funzione |
|---|---|---|---|---|
| `Gestione_Encoder` | Input_Output | **100 µs** | 0 (max) | Legge encoder, scorre posizioni buffer, attiva Output_NIR e incrementa NUM_SELEZIONATI |
| `Gestione_Espulsione` | Input_Output | **100 µs** | 0 (max) | Pilota Out_1..117 (EV fisiche), diagnostica I/O EtherCAT, pressione |
| `Sensore_NIR` | Camera | **200 µs** | 1 | Comunicazione UDP col sensore, riempie buffer MSI_data/MSI_elab, setta track_mat_select |
| `Processing` | Elaboration | **10 ms** | 2 (min) | Calcola percentuali, peso, Modbus, gestione licenza, cmd ricetta |

---

## Catena di Selezione Completa

```
[Sensore NIR LLA] --(UDP 121 byte)--> Sensore_NIR
  → per ogni traccia: confronta codice con CODICI_MATERIALI[]
  → se match E MATERIALI_ATTIVI[i]: track_mat_select[traccia] := TRUE
  → NUM_CAMPIONATI[i]++
  → MSI_data[index_nir].Position := 0  (pacchetto entra nel buffer)

[Encoder EtherCAT] --> Gestione_Encoder
  → ogni impulso: Position += PASSO_ENCODER per ogni pacchetto nel buffer
  → quando Position = DISTANZA_EV:
      se track_mat_select[traccia]: Output_NIR[traccia] := TRUE
      NUM_SELEZIONATI[i]++

Gestione_Espulsione (ogni ciclo):
  → Out_X := CMD_OP_EV[X] OR Output_NIR[X]  (uscita digitale 24V)
  → timer APERTURA_EV ms → Output_NIR[X] := FALSE (reset)

Processing (ogni minuto):
  → PERC_SELEZIONATI[i] = NUM_SELEZIONATI[i] / Totale * 100
  → PERC_CAMPIONATI[i]  = NUM_CAMPIONATI[i]  / Totale * 100
  → Modbus_Area[6..21]  = PERC_SELEZIONATI[0..15] * 10
  → Modbus_Area[22..37] = PERC_CAMPIONATI[0..15]  * 10
```

---

## Variabili Chiave

| Variabile | Tipo | Dove | Significato |
|---|---|---|---|
| `CODICI_MATERIALI[0..100]` | BYTE | PERSISTENT | Codici materiali dal sensore NIR |
| `NOMI_MATERIALI[0..100,1..28]` | BYTE | PERSISTENT | Nomi materiali |
| `MATERIALI_ATTIVI[0..100]` | BOOL | PERSISTENT | Quali materiali vanno scartati |
| `NUM_SELEZIONATI[0..100]` | UDINT | PERSISTENT | Contatore pezzi scartati per tipo |
| `NUM_CAMPIONATI[0..100]` | UDINT | PERSISTENT | Contatore pezzi rilevati per tipo |
| `PERC_SELEZIONATI[0..100]` | REAL | PERSISTENT | % scartati (calc in Processing) |
| `PERC_CAMPIONATI[0..100]` | REAL | PERSISTENT | % campionati (calc in Processing) |
| `Output_NIR[1..117]` | BOOL | Global | Comando espulsione per traccia |
| `MSI_data[0..150]` | RX_NIR | Global | Buffer circolare pacchetti NIR raw |
| `MSI_elab[0..150]` | RX_NIR_ELAB | Global | Buffer elaborato (filtro inquinamento) |
| `INDEX_NIR` | UINT | Global | Puntatore scrittura buffer (= index_nir in Sensore_NIR) |
| `DISTANZA` | UINT | PERSISTENT | Ritardo sparo EV (default 200) ⚠️ unità da chiarire |
| `DISTANZA_EV` | UDINT | Global | = DISTANZA (assegnato in Processing) |
| `APERTURA_EV` | INT | PERSISTENT | Durata apertura EV in ms (default 15) |
| `ENABLE` | BOOL | PERSISTENT | TRUE = macchina BLOCCATA da licenza scaduta |
| `ABIL_NIR` | BOOL | PERSISTENT | Abilita connessione sensore NIR |
| `NIR_ATTIVO` | BOOL | Global | Stato=2 AND MSI_ok AND ENCODER_OK AND ABIL_NIR |
| `DIAGNOSTICA_OK` | BOOL | Global | Tutti moduli EtherCAT in stato OP (=8) |
| `Macchina_pronta` | BOOL (%Q*) | Global | SPEED>0.5 AND NIR_ATTIVO AND DIAGNOSTICA_OK |
| `SKIP_EV` | INT | PERSISTENT | Numero tracce iniziali da ignorare |
| `NUM_CODICI` | INT | PERSISTENT | Numero codici attivi (default 68) |
| `STEP` | UINT | PERSISTENT | Modalità filtro inquinamento (1-4, 91-94, 99) |
| `PROCESSING_DATA` | BOOL | PERSISTENT | Abilita filtro elaborazione dati |
| `NUM_LOAD_ID` | BYTE | PERSISTENT | ID ricetta attiva |
| `CMD_LOAD` | BOOL | Global | Trigger caricamento ricetta sul sensore |
| `PESO_TOTALE` | REAL | PERSISTENT | Peso totale materiale scartato (kg) |
| `KG_MINUTI` | REAL | Global | Kg/minuto (calcolato ogni 60s) |
| `CARICO_MIN` | REAL | Global | % carico macchina al minuto |
| `SPEED` | REAL | Global | Velocità nastro (m/s) |
| `INTERVALLO_ORE_ISTANTANEO` | UDINT | PERSISTENT | Ore di utilizzo accumulate |

---

## Mappa Modbus TCP

**Base SCADA:** `12288` | Formula: `Indirizzo = 12288 + Indice Array`
**Funzione:** FC03 Read Holding Registers (da confermare)
**Scala REAL:** `valore × 10 → WORD` (client divide /10)

Mappa completa → `docs/modbus/mappa-registri.md`

| Indice | SCADA | Dan(+1) | Dir | Variabile | Scala | Note |
|---|---|---|---|---|---|---|
| 0 | 12288 | 12289 | R | `CARICO_MIN` | ×10 | |
| 1 | 12289 | 12290 | R | `SPEED` | ×10 | **v5.0** |
| 2 | 12290 | 12291 | R | `Pressione_aria` | ×10 | 0 se sensore non installato |
| 3 | 12291 | 12292 | R | `Flussostato_aria` | ×10 | 0 se sensore non installato |
| 4 | 12292 | 12293 | R | `INTERVALLO_ORE_ISTANTANEO` | — | ⚠️ tronca a 65535 |
| 5 | 12293 | 12294 | R | `PESO_TOTALE` HIGH | — | **v5.0** DWORD fix overflow |
| 6..21 | 12294..12309 | +1 | R | `PERC_SELEZIONATI[0..15]` | ×10 | |
| 22..37 | 12310..12325 | +1 | R | `PERC_CAMPIONATI[0..15]` | ×10 | |
| 38 | 12326 | 12327 | R | `DIAGNOSTICA_OK` | — | 1=OK |
| 39 | 12327 | 12328 | R | `SPEED>0.5 AND NIR_ATTIVO AND DIAG_OK` | — | **Fix s7** 1=lavora |
| 40 | 12328 | 12329 | R | `KG_MINUTI` | ×10 | 0 su .33/.34 (precision) |
| 41 | 12329 | 12330 | R | `PESO_TOTALE` LOW | — | **v5.0** DWORD fix (era ×10) |
| 42 | 12330 | 12331 | R | `NUM_LOAD_ID` | — | Ricetta attiva |
| 43 | 12331 | 12332 | R | `LINEE` | — | **v5.0** linee NIR/s |
| 44 | 12332 | 12333 | R | `ABIL_NIR` stato | — | **v5.0** 1=NIR online |
| 45 | 12333 | 12334 | W | `ABIL_NIR` cmd | — | **v5.0** 1=abilita 2=spegni |
| 46 | 12334 | 12335 | W | Reset contatori | — | **v5.0** bit0=sel bit1=camp |
| 47 | 12335 | 12336 | R | `ETH_LINK_OK` | — | **v5.0** 1=link NIR ok |
| 51 | 12339 | 12340 | W | Cambio ricetta | — | ⚠️ non modificare senza Daniele |

**PESO_TOTALE DWORD:** `peso_kg = [5]×65536 + [41]`

---

## Sistema di Licenza

`ENABLE := TRUE` viene settato da Processing quando:
- Le ore accumulate (`INTERVALLO_ORE_ISTANTANEO`) superano la soglia configurata, OPPURE
- La data di sistema supera una delle date di scadenza (`data1..6_scadenza`)

Quando `ENABLE=TRUE`, `Gestione_Encoder` è bloccato (`IF NOT ENABLE`) → nessuna espulsione.
Il livello di scadenza attivo dipende da `NUM_PW` (0..5).
Per sbloccare: inserire password dall'HMI → `NUM_PW` sale → `ENABLE:=FALSE`.

---

## Parametri Fisici Chiave

| Parametro | Valore | Significato |
|---|---|---|
| `NUM_TRACKS_NIR` | 117 | Tracce NIR (e EV) |
| `IMPULSI_ENCODER` | 250 | Impulsi/giro encoder |
| `SVILUPPO_ESTERNO` | 656 mm | Circonferenza rullo encoder |
| `BUFFER_SIZE` | 150 | Pacchetti NIR in volo contemporaneamente |
| `APERTURA_EV` | 15 ms | Durata apertura elettrovalvola |
| `DISTANZA` | 200 | Ritardo sparo in **impulsi encoder** (NON mm). 200 × (656/250) = **524,8 mm** distanza fisica sensore→EV |
| `PESO_MATERIALE` | 240 | Peso specifico materiale (g?) |
| `Machine_name` | NIR_1500.117 | 1500mm larghezza, 117 tracce |

---

## Protocollo UDP Sensore NIR (LLA/MSI)

Indirizzo: `192.168.0.10:1803` | Locale: `192.168.0.1:1803`
Pacchetto dati: 121 byte (`RX_NUM_NIR=121` = 117 tracce + 5 header - 1)

| Comando (hex) | Significato |
|---|---|
| `34 F0` | Online — richiedi dati |
| `3F F0` | Offline |
| `35 F0` | Calibrazione bianco |
| `3A F0` | Calibrazione nero |
| `36 [N] F0` | Carica ricetta N |
| `3B F0` | Spegni sensore |
| `32 01 F0` | Get types (leggi codici materiali) |

---

## Decisioni Architetturali

| Data | Decisione | Motivo |
|---|---|---|
| 2026-05-05 | Trigger Modbus [50] non implementato | Accordo con Daniele: gestionale usa solo scrittura su [51] |
| 2026-05-05 | Scala ×10 per tutti i REAL | Compatibilità SCADA |
| 2026-05-05 | Block Read ~100 registri | Evita instabilità letture singole TS6250 |
| 2026-05-05 | Task Input_Output a 100µs (Encoder+Espulsione), Camera a 200µs (NIR), Elaboration a 10ms (Processing) | Latenza encoder critica: 100µs garantisce granularità sub-mm a velocità tipiche |
| 2026-05-05 | ENABLE=TRUE = blocco licenza (non "abilitazione") | Naming controintuitivo, logica confermata da Processing |

---

## Bug / Anomalie Noti

| File | Descrizione | Gravità |
|---|---|---|
| `PROCESSING` | `SystemTaskInfoArr[3]` confrontato ma `[4]` salvato in `max_time_task` | Bassa (dato errato, non blocca) |
| `GESTIONE_ESPULSIONE` | `Out_11` ha doppio `;;` | Irrilevante (TC2 lo ignora) |
| `PROCESSING` | `UDINT_TO_WORD` su `INTERVALLO_ORE_ISTANTANEO` tronca a 65535 (~18h) | Media (dato Modbus wrappa silenziosamente) |

---

## TODO / Buchi Aperti

### Critici
- [x] **Unità DISTANZA**: **RISOLTO** — impulsi encoder. 200 × (656mm/250) = 524,8mm distanza fisica. Il commento nel codice che diceva "mm" era errato.
- [x] **Indici Modbus 43..50**: **v5.0** — [43]=LINEE, [44]=ABIL_NIR stato, [45]=ABIL_NIR cmd, [46]=reset cmd, [47]=ETH_LINK_OK. [48..50] riservati.
- [x] **Indici 1 e 5**: **v5.0** — [1]=SPEED×10, [5]=PESO_TOTALE HIGH WORD
- [x] **Notazione SCADA Daniele**: **RISOLTO** — usa Base 1 (+1). Confermato email 2026-06-04.
- [x] **Registro 39 lato SCADA**: **RISOLTO** — fix sessione 7+8. Applicato su tutte e 4 le macchine.
- [x] **Fix registro 12328 su .31 e .32**: **APPLICATO** sessione 8.
- [ ] **Modbus v5.0 da applicare in produzione**: codice pronto nel repo, applicare Online Change su tutte e 4
- [ ] **CARICO_MIN = 0 nel gestionale**: Daniele legge registro sbagliato — verificare con lui
- [ ] **PESO_TOTALE DWORD**: comunicare a Daniele nuova formula [5]×65536+[41]
- [ ] **Problema cambio ricetta da Mago**: CMD_LOAD cancellato silenziosamente — diagnosticare All_load e Stato
- [ ] **PESO_PARZIALE** (rebuild offline): codice pronto in notes/peso_parziale_da_applicare.md

### Informativi
- [ ] Versione TwinCAT 2 (build esatta)
- [ ] Licenza TS6250 — attiva o trial su ciascuna macchina?
- [ ] Repo unico o 3 copie sincronizzate? (rischio drift)
- [ ] FC03 o FC04 per Modbus?
- [ ] Frequenza polling SCADA
- [ ] `DISTANZA` valore attuale in produzione su .31, .32, .34
- [ ] `APERTURA_EV` valore attuale (15ms è il default, potrebbe essere stato modificato)

---

## Stato Repository vs Macchine Reali

| File | Fonte | Validità |
|---|---|---|
| Tutto tranne TWINCAT_CONFIGURATION | Beckhoff (.31 o .32) | Logica identica su tutte e 4 le macchine |
| `TWINCAT_CONFIGURATION.EXP` | Beckhoff (.31 o .32) | ⚠️ Valido solo per .31/.32 — Elmak (.33/.34) ha hardware diverso, mapping I/O probabilmente differente |

**⚠️ Da fare:** Esportare `TWINCAT_CONFIGURATION.EXP` da una Elmak (.33 o .34) e archiviarla come `TWINCAT_CONFIGURATION_ELMAK.EXP`. Finché non è acquisita, il repo non rappresenta fedelmente le macchine Elmak.

---

## Progetto Robot (secondario — prototipo fisico in azienda)

### Descrizione
Robot picker su nastro trasportatore: sensore NIR LLA rileva il polimero,
braccio robot multi-asse (ABB, modello da confermare) preleva i pezzi classificati.
Il prototipo fisico esiste ma non ha mai avuto una logica PLC funzionante.

### Architettura implementata (codice in `robot/`)

```
NIR UDP → Sensore_NIR → FB_Segmentazione → OBJ_queue[] → Gestione_Robot → TCP → Robot
```

**Flusso dettagliato:**
1. `Sensore_NIR` riceve pacchetti UDP dal NIR, popola `track_mat_select[]`
2. `FB_Segmentazione` (chiamata una volta per scan) raggruppa tracce adiacenti
   in blob, traccia blob tra scan consecutive, chiude oggetti per gap encoder
3. `OBJ_queue[0..16]` (coda circolare) accumula oggetti completati
4. `Gestione_Robot` legge la coda, costruisce stringa pick, invia via TCP

**Formato stringa pick:**
```
@UiTag,X_traccia,Y_mm,Z_mm,Rotazione,AttesaPresa,X_box,Y_box,Z_box,AttesaDeposito,#
Esempio: @42,58.5,1834.6,200.0,0.0,0.5,320.0,340.0,50.0,0.3,#
```

### File robot/

| File | Stato |
|---|---|
| `OBJ_PICK.EXP` | ✅ completo |
| `BLOB_TRACKER.EXP` | ✅ completo |
| `FB_SEGMENTAZIONE.EXP` | ✅ completo — include protezione ROBOT_CODA_PIENA |
| `GVL_ROBOT.EXP` | ✅ completo — incluse statistiche PICK_AL_MINUTO, EFFICIENZA_PICK, CODA_UTILIZZO, ROBOT_CODA_PIENA |
| `GVL_COMPLETO_ROBOT.EXP` | ✅ GVL unificato robot (sostituisce Global_Variables della selezionatrice) |
| `gestionerobot.txt` | ✅ v2.1 — TCP diretto robot, no PickMaster, stato ATTESA_ACK con FB_SocketReceive |
| `gestioneencoder_robot.txt` | ✅ Encoder semplificato (no EV), copia ENCODER_COUNTER ogni ciclo |
| `processing_robot.txt` | ✅ Statistics PICK_AL_MINUTO, EFFICIENZA_PICK, CODA_UTILIZZO, allarme coda piena |
| `sensoreNIR.txt` | ⚠️ Modificato — chiama FB_Segmentazione al posto del vecchio concat per tracce |
| `RAPID_ROBOT.prg` | ✅ v2.1 — server TCP ABB RAPID, parsa stringa pick, ciclo pick+deposito, invia ACK "OK,tag,#" |
| `TEST_PLAN.md` | ✅ Piano test 5 fasi (dal fisico all'integrazione) |
| `TASK_CONFIG.md` | ✅ Configurazione 3 task TwinCAT 2, mapping I/O, ordine import POUs |
| `INTEGRAZIONE_SENSORE_NIR.md` | ✅ Guida passo-passo modifiche sensoreNIR |
| `ANALISI.md` | ✅ Analisi completa bug progetto precedente |

### Decisioni robot

| Data | Decisione | Motivo |
|---|---|---|
| 2026-05-26 | Rimosso PickMaster — TCP diretto al robot | Nessun PC PickMaster confermato sul prototipo |
| 2026-05-26 | Segmentazione per gap encoder, non per scan count | Robusta al wrap del ring buffer (BUFFER_SIZE=150) |
| 2026-05-26 | MAX_BLOBS=6, MAX_OBJ_QUEUE=16 | Sufficienti per nastro recycling tipico |
| 2026-05-26 | ACK TCP robot→PLC non bloccante (timeout 3s) | Produzione non bloccata se robot lento; n_ack_timeout conta i miss |
| 2026-05-26 | ROBOT_CODA_PIENA in FB_Segmentazione (set) e Processing_Robot (reset) | Allarme coda saturata visibile sull'HMI, non perde oggetti in modo silenzioso |

### Variabili robot da configurare (placeholder in GVL_ROBOT.EXP)

| Variabile | Default | Da fare |
|---|---|---|
| `IP_ROBOT` | '192.168.1.100' | Leggere dal controller robot |
| `PORT_ROBOT` | 10000 | Leggere dal controller robot |
| `DISTANZA_ROBOT_MM` | 0.0 | Misurare: distanza fisica NIR → punto di presa |
| `ALTEZZA` | 200.0 | Misurare: quota Z di presa |
| `SCAN_DISTANCE` | 3.5 | Calcolare: velocità nastro / linee NIR al secondo |
| `X_BOX[]`, `Y_BOX[]`, `Z_BOX[]` | 0.0 | Misurare: coordinate box deposito |
| `OBJ_GAP_ENCODER` | 50 | Calibrare: impulsi encoder tra oggetti diversi |

### Stato import TwinCAT 2 (aggiornato 2026-05-27)

| Step | Stato | Note |
|---|---|---|
| File .EXP generati (16 file v3) | ✅ Pronti | `robot/twincat_project_v3.zip` — senza library stubs |
| Formato POU .EXP (headers + END_PROGRAM) | ✅ Verificato identico a src/ funzionante |
| Formato TYPE .EXP (OBJ_PICK, BLOB_TRACKER) | ✅ Struttura corretta con @END_DECLARATION |
| TASK_CONFIGURATION.EXP | ✅ Ha END_RESOURCE, 3 task corretti |
| Import in progetto nuovo vuoto | ⚠️ **In corso** — utente deve usare File→New, NON aprire exper.pro |
| Librerie (.LIB) da aggiungere a mano | ⚠️ Non importabili come .EXP — aggiungere via Library Manager |
| Build F11 con errori | ❌ Non ancora raggiunto |

**Errori visti finora e significato:**
- `Error 3554 Task entry 'MAIN'` → task config importata in progetto ESISTENTE (exper.pro) che aveva già un MAIN. Soluzione: progetto nuovo.
- `Error 3403 Could not import ''` (×5) → file STANDARD.LIB.EXP ecc. non importabili — normale. Rimossi dalla v3.
- `Error 3403 Could not import 'Workspace'` → WORKSPACE.EXP non importabile — normale. Rimosso dalla v3.
- `Error 3415 alarmconfiguration` → formato alarm config non compatibile — innocuo.

**Procedura corretta (v3):**
1. File → New → "PC or CX (x86)" → OK
2. NON cancellare PLC_PRG subito
3. Project → Import... → tutti e 16 i .EXP della v3
4. Overwrite se chiesto
5. Cancella PLC_PRG default dal tab POUs
6. Library Manager → aggiungi 5 .LIB a mano
7. File → Save as → NIR_Robot_v1.pro
8. F11 → mandare log errori

### TODO robot

**Codice PLC pronto per il test — da fare fisicamente sul prototipo:**
- [ ] Accedere al controller robot fisico: leggere IP, porta, confermare tipo ABB
- [ ] Caricare sul robot il programma RAPID listener TCP (`robot/RAPID_ROBOT.prg`)
- [ ] Configurare: `IP_ROBOT`, `PORT_ROBOT` in `GVL_ROBOT.EXP`
- [ ] Misurare `DISTANZA_ROBOT_MM` (NIR → punto di presa) e `ALTEZZA` (Z presa)
- [ ] Calcolare `SCAN_DISTANCE` (vel nastro mm/s ÷ linee NIR/s)
- [ ] Calibrare `TEMPO_CICLO_ROBOT` (misurare pick-to-pick reale con nastro fermo)
- [ ] Configurare `X_BOX[]`, `Y_BOX[]`, `Z_BOX[]` per le posizioni di deposito
- [ ] Calibrare tool `tool_pinza` e workobject `wobj_nastro` in RobotStudio
- [ ] Eseguire test in sequenza secondo `TEST_PLAN.md`

---

## Storico Sessioni

| Data | Attività |
|---|---|
| 2026-05-05 | Prima sessione: raccolta contesto, struttura repo, documentazione iniziale |
| 2026-05-05 | Seconda sessione: acquisizione codice sorgente completo (4 POU + GVL), analisi architettura |
| 2026-05-05 | Terza sessione: acquisizione TWINCAT_CONFIGURATION.EXP e TASK_CONFIGURATION.EXP, risoluzione DISTANZA (impulsi encoder, 524,8mm fisici) |
| 2026-05-26 | Quarta sessione: analisi progetto robot (branch session/2026-05-16), identificati bug (sovrascrittura tracce, no segmentazione), rimosso PickMaster, scritti FB_Segmentazione + OBJ_PICK + BLOB_TRACKER + GVL_ROBOT + Gestione_Robot v2.0 |
| 2026-05-26 | Quinta sessione: completamento progetto robot — ACK TCP (stato 4 ATTESA_ACK), statistiche GVL (PICK_AL_MINUTO/EFFICIENZA/CODA_UTILIZZO/ROBOT_CODA_PIENA), processing_robot.txt, RAPID v2.1 con ACK, TASK_CONFIG.md, GVL_COMPLETO_ROBOT.EXP aggiornato |
| 2026-05-27 | Sesta sessione: import TwinCAT 2 — diagnostica e fix iterativo errori .EXP. Vedi `notes/sessione6_import.md` per dettaglio |
| 2026-05-28 / 2026-06-05 | Settima sessione: debug Modbus selezionatrice — identificato bug ENABLE invertito su registro 12328, fix applicato su .33 e .34 via Online Change, coordinamento con Daniele per aggiornamento criterio gestionale. Tutte e 4 le macchine ora visibili. Vedi `notes/sessione7_modbus_fix.md` |
| 2026-06-08 | Ottava sessione: fix TeamViewer Beckhoff (gateway rete), fix [39] su .31/.32, diagnosi dati gestionale (overflow PESO_TOTALE, pressioni = 0 hardware, CARICO_MIN Daniele sbagliato), sviluppo Modbus v5.0: nuovi registri SPEED/LINEE/ETH/NIR, fix DWORD PESO_TOTALE, comandi scrittura ABIL_NIR + reset contatori. Vedi `notes/sessione8_modbus_v5.md` |
