# TwinCAT PLC — Selezionatrice Ottica NIR

Progetto PLC per selezionatrice ottica NIR con scarto pneumatico.  
**117 tracce** | **4 macchine** | **TwinCAT 2 SoftPLC** | **Windows 7 Embedded**

---

## Leggi prima di toccare qualsiasi cosa

→ **[CONTEXT.md](CONTEXT.md)** — fonte di verità del progetto. Contiene topologia macchine, architettura POU, variabili chiave, mappa Modbus, decisioni architetturali, bug noti, TODO aperti.

→ **[CLAUDE.md](CLAUDE.md)** — regole di lavoro per AI. Strict Mode: nessuna invenzione di variabili o indirizzi, nessuna modifica senza contesto confermato.

---

## Topologia

```
Linea Lavatrici:  192.168.1.31 (Beckhoff) → 192.168.1.33 (Elmak)
Linea R4:         192.168.1.32 (Beckhoff) → 192.168.1.34 (Elmak)
```

Ogni macchina = PLC indipendente, nastro proprio, 117 tracce NIR + 117 elettrovalvole pneumatiche.  
Sensore NIR su subnet separata `192.168.0.x` via UDP.  
SCADA (Daniele) su `192.168.1.x` via Modbus TCP (TS6250, base 12288).

---

## Struttura Repository

```
src/                           # Codice sorgente TwinCAT 2 (.EXP)
├── GLOBAL_VARIABLES.EXP       # Variabili globali e costanti
├── SENSORE_NIR.EXP            # UDP state machine → buffer MSI_data[]
├── GESTIONE_ENCODER.EXP       # Timing sparo EV da encoder
├── GESTIONE_ESPULSIONE.EXP    # Output fisici 117 EV + diagnostica
├── PROCESSING.EXP             # Percentuali, peso, Modbus TCP, licenza
├── RX_NIR.EXP                 # TYPE: struct pacchetto NIR raw
├── RX_NIR_ELAB.EXP            # TYPE: struct pacchetto elaborato
├── TWINCAT_CONFIGURATION.EXP  # Mapping I/O EtherCAT (Beckhoff only)
├── TASK_CONFIGURATION.EXP     # 3 task: 100µs / 200µs / 10ms
└── *.LIB.EXP                  # Indici librerie (non codice eseguibile)

docs/
└── modbus/
    ├── mappa-registri.md      # Mappa completa Modbus TCP
    └── eccezioni-vs-pdf.md    # Differenze vs spec originale Daniele
```

---

## Catena di Selezione (flusso dati)

```
[Sensore NIR UDP 121B]
        │
        ▼
  Sensore_NIR (200µs)
  • confronta codice traccia con CODICI_MATERIALI[]
  • se match AND MATERIALI_ATTIVI[i]: track_mat_select := TRUE
  • MSI_data[index].Position := 0  (entra nel buffer)
        │
        ▼
  Gestione_Encoder (100µs)
  • ogni impulso encoder: Position += PASSO_ENCODER
  • quando Position = DISTANZA_EV (200 impulsi = 524.8mm):
      Output_NIR[traccia] := TRUE
      NUM_SELEZIONATI[i]++
        │
        ▼
  Gestione_Espulsione (100µs)
  • Out_X := CMD_OP_EV[X] OR Output_NIR[X]
  • timer APERTURA_EV ms → Output_NIR[X] := FALSE
        │
        ▼
  Processing (10ms)
  • calcola PERC_SELEZIONATI/CAMPIONATI
  • scrive Modbus_Area[0..51] → TS6250 → SCADA
```

---

## Modbus TCP

Base SCADA: **12288** | Scala REAL: **×10** | Funzione: FC03

| Registro SCADA | Variabile | Note |
|---|---|---|
| 12288 | CARICO_MIN ×10 | |
| 12290 | Pressione_aria ×10 | |
| 12291 | Flussostato_aria ×10 | |
| 12292 | INTERVALLO_ORE_ISTANTANEO | ⚠️ tronca a 65535 (~18h) |
| 12294..12309 | PERC_SELEZIONATI[0..15] ×10 | |
| 12310..12325 | PERC_CAMPIONATI[0..15] ×10 | |
| 12326 | DIAGNOSTICA_OK | 1=OK |
| 12327 | ENABLE | ⚠️ 1=BLOCCATA (licenza scaduta) |
| 12328 | KG_MINUTI ×10 | |
| 12329 | PESO_TOTALE ×10 | |
| 12330 | NUM_LOAD_ID | ricetta attiva |
| 12339 | *(write)* | SCADA scrive ID ricetta → CMD_LOAD |

---

## Librerie TwinCAT utilizzate

| Libreria | Versione | Usata per |
|---|---|---|
| STANDARD.LIB | 5.6.98 | TON, R_TRIG, F_TRIG |
| TcSystem.lib | 7.6.16 | MEMSET |
| TcUtilities.lib | 3.2.16 | NT_GetTime, TC_CpuUsage, SYSTEMTIME_TO_DT |
| TcpIp.lib | 21.3.13 | FB_SocketUdpCreate/ReceiveFrom/SendTo/Close |

---

## Stato del Repository

| Elemento | Stato |
|---|---|
| Codice Beckhoff (.31/.32) | ✅ Completo |
| Codice Elmak (.33/.34) logica | ✅ Identico al Beckhoff |
| TWINCAT_CONFIGURATION Elmak | ⚠️ Mancante (hardware B&R diverso) |
| Modifica Modbus 4.0 | ✅ Applicata su tutte e 4 le macchine |

---

## Persone

| Persona | Ruolo |
|---|---|
| Davide | Autore codice originale |
| Marco | Modifica 4.0 (Modbus TCP), manutenzione |
| Daniele | SCADA / gestionale (client Modbus) |
