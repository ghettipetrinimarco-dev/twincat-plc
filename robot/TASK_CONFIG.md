# Configurazione Task TwinCAT 2 — Progetto Robot

## Architettura a 3 Task

```
┌─────────────────────────────────────────────────────────────┐
│  TASK  Input_Output  (Priorità 0 — 100µs)                   │
│  ────────────────────────────────────────────────────────── │
│  POUs chiamati (in ordine):                                  │
│   1. Gestione_Encoder_Robot                                  │
│      - Legge Counter AT %I* (encoder HW)                     │
│      - Calcola SPEED, PASSO_ENCODER, ENCODER_OK              │
│      - Copia: ENCODER_COUNTER := Counter;                    │
│   2. Sensore_NIR                                             │
│      - Riceve UDP dal sensore LLA/MSI                        │
│      - Decodifica pacchetti 121 byte → track_mat_select[]    │
│      - Chiama FB_Segmentazione per ogni scan valida          │
│      - FB_Segmentazione scrive OBJ_queue[] → obj_head        │
│                                                              │
│  Variabili HW (AT %I*):                                      │
│   - Counter (Encoder_Robot): Gestione_Encoder_Robot          │
│   - Encoder_STATE (Encoder_Robot): Gestione_Encoder_Robot    │
│   - Macchina_pronta AT %Q*: scritta da Processing_Robot      │
│   - Errore_connessione_sensore AT %Q*: scritta da SensoreNIR │
└─────────────────────────────────────────────────────────────┘
         │
         │ GVL: OBJ_queue[], obj_head (scritto)
         │      ENCODER_COUNTER (scritto)
         │      blob_trackers[] (scritto)
         ▼
┌─────────────────────────────────────────────────────────────┐
│  TASK  Gestione_Robot  (Priorità 1 — 10ms)                   │
│  ────────────────────────────────────────────────────────── │
│  POUs chiamati:                                              │
│   1. Gestione_Robot                                          │
│      - Legge OBJ_queue[] → obj_tail                         │
│      - Stato 0: FB_SocketConnect → robot IP:PORT             │
│      - Stato 1: attende oggetti in coda                      │
│      - Stato 2: costruisce stringa, FB_SocketSend            │
│      - Stato 3: chiudi socket, pausa, riconnetti             │
│      - Stato 4: FB_SocketReceive (attesa ACK "OK,tag,#")     │
│                                                              │
│  Note:                                                       │
│   - Task separato da Camera per non ritardare acquisizione   │
│   - 10ms è sufficiente: la latenza robot >> 10ms             │
└─────────────────────────────────────────────────────────────┘
         │
         │ GVL: obj_tail (scritto), UiTag_robot (scritto)
         │      ROBOT_CONNESSO (scritto)
         ▼
┌─────────────────────────────────────────────────────────────┐
│  TASK  Elaboration  (Priorità 2 — 10ms)                      │
│  ────────────────────────────────────────────────────────── │
│  POUs chiamati:                                              │
│   1. Processing_Robot                                        │
│      - Timer 1s: SPEED_OLD, inc_sec                          │
│      - Timer 1min: PICK_AL_MINUTO, EFFICIENZA_PICK           │
│      - Calcola CODA_UTILIZZO, segnala ROBOT_CODA_PIENA       │
│      - Aggiorna percentuali materiali campionati/selezionati │
│      - Diagnostica CPU, gestione INFO_MSG                    │
│      - Macchina_pronta = SPEED>0.5 AND NIR_ATTIVO AND        │
│                         DIAGNOSTICA_OK AND NOT CODA_PIENA    │
└─────────────────────────────────────────────────────────────┘
```

## Setup in TwinCAT 2 System Manager

### Task Input_Output
- **Priority**: 0 (massima)
- **Cycle time**: 100µs (100000 ns)
- **Type**: Cyclic
- **POUs**: `Gestione_Encoder_Robot`, `Sensore_NIR`

### Task Gestione_Robot  
- **Priority**: 1
- **Cycle time**: 10ms (10000000 ns)
- **Type**: Cyclic
- **POUs**: `Gestione_Robot`

### Task Elaboration
- **Priority**: 2
- **Cycle time**: 10ms (10000000 ns)
- **Type**: Cyclic
- **POUs**: `Processing_Robot`

> ⚠️ In TC2 i task con la stessa priorità girano in round-robin.
> Se serve evitare conflitti tra Gestione_Robot e Elaboration,
> portare Elaboration a Priority 3.

## Mapping I/O Encoder

Nel System Manager → I/O Configuration:
```
Encoder_Robot (contatore HW) → Variabili in Gestione_Encoder_Robot:
  - Counter      AT %I* : UDINT   ← Encoder counter 32-bit
  - Encoder_STATE AT %I*: WORD    ← Status register encoder
  - Period       AT %I* : DWORD   ← Periodo (per calcolo velocità)
```

## GVL Globale

Tutti i file `.EXP` del progetto vanno importati in un unico GVL:
- `GVL_COMPLETO_ROBOT.EXP` — contiene tutto (usare come riferimento)
- Oppure: importare separatamente `GVL_ROBOT.EXP` nel GVL esistente

## Ordine di Import POUs

1. `OBJ_PICK.EXP` — TYPE struct (prima di tutto)
2. `BLOB_TRACKER.EXP` — TYPE struct
3. `GVL_COMPLETO_ROBOT.EXP` — variabili globali
4. `FB_SEGMENTAZIONE.EXP` — function block
5. `Gestione_Encoder_Robot.EXP` (o `.txt`)
6. `sensoreNIR.txt`
7. `gestionerobot.txt`
8. `processing_robot.txt`

## Note Compilazione TC2

- `MAX_BLOBS`, `MAX_OBJ_QUEUE`, `N_BOX` **devono** stare in `VAR_GLOBAL CONSTANT`
  (non `VAR_GLOBAL`) per essere usati in dichiarazioni di array
- Verificare che `FB_SocketConnect`, `FB_SocketSend`, `FB_SocketReceive`,
  `FB_SocketClose` siano disponibili (libreria `TcSockets.lib`)
- `NT_GetTime` richiede `TcSystem.lib`
- `TC_CpuUsage` richiede `TcSystemCPU.lib`
