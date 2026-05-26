# Mappa Variabili HMI — Robot NIR Picker

> Variabili da esporre sulla visualizzazione TwinCAT (o SCADA se disponibile).
> Tutte le variabili sono in GVL_COMPLETO_ROBOT.EXP a meno che indicato diversamente.

---

## Stato Macchina (riquadro principale)

| Variabile | Tipo | Accesso | Descrizione | Range / Unità |
|---|---|---|---|---|
| `Macchina_pronta` | BOOL | R | Verde = pronta, Rosso = ferma | — |
| `NIR_ATTIVO` | BOOL | R | Sensore NIR connesso e acquisendo | — |
| `ROBOT_CONNESSO` | BOOL | R | Socket TCP robot aperta | — |
| `ENCODER_OK` | BOOL | R | Encoder in stato OP | — |
| `DIAGNOSTICA_OK` | BOOL | R | Moduli EtherCAT tutti OK | — |
| `SPEED` | REAL | R | Velocità nastro | m/s |
| `ABIL_ROBOT` | BOOL | R/W | Abilita/disabilita robot picker | — |

---

## Statistiche Robot (riquadro numeri)

| Variabile | Tipo | Accesso | Descrizione | Range / Unità |
|---|---|---|---|---|
| `UiTag_robot` | INT | R | Numero progressivo ultimo pick inviato | 0..30000 |
| `PICK_AL_MINUTO` | INT | R | Pick inviati nell'ultimo minuto | pick/min |
| `EFFICIENZA_PICK` | REAL | R | % oggetti rilevati che vengono pickati | 0..100 % |
| `CODA_UTILIZZO` | REAL | R | % slot coda OBJ_queue occupati | 0..100 % |
| `ROBOT_CODA_PIENA` | BOOL | R | Allarme: coda satura, oggetti persi | — |
| `TEMPO_ORA` | UINT | R | Ore di funzionamento | ore |

---

## Percentuali Materiali (tabella)

| Variabile | Tipo | Accesso | Descrizione |
|---|---|---|---|
| `PERC_CAMPIONATI[0..N]` | REAL[] | R | % materiale rilevato dal NIR per tipo |
| `PERC_SELEZIONATI[0..N]` | REAL[] | R | % materiale pickato per tipo |
| `NUM_CAMPIONATI[0..N]` | UDINT[] | R | Contatore assoluto oggetti rilevati |
| `NUM_SELEZIONATI[0..N]` | UDINT[] | R | Contatore assoluto pick eseguiti |
| `NOMI_MATERIALI[0..N]` | BYTE[,] | R | Nome materiale (28 char) |

**Reset contatori:**
| Variabile | Tipo | Accesso | Effetto |
|---|---|---|---|
| `RESET_SELEZIONATI` | BOOL | W | Azzera NUM_SELEZIONATI[] |
| `RESET_CAMPIONATI` | BOOL | W | Azzera NUM_CAMPIONATI[] |

---

## Diagnostica / Allarmi

| Variabile | Tipo | Accesso | Descrizione |
|---|---|---|---|
| `INFO_MSG[0..50]` | INT[] | R | Coda messaggi info (codici) |
| `INDICE_MSG_INF` | UINT | R | Indice prossima scrittura in INFO_MSG |
| `CANCELLA_INFO` | BOOL | W | Svuota INFO_MSG |
| `All_encoder` (in Gestione_Encoder_Robot) | BOOL | R | Allarme encoder (stato ≠ 8 per >3s) |
| `Errore_connessione_sensore` | BOOL | R | Socket NIR in errore |
| `CPU_USAGE` | UDINT | R | Utilizzo CPU % |
| `DATA_ORA` | TIMESTRUCT | R | Data/ora sistema |

**Codici INFO_MSG:**
| Codice | Significato |
|---|---|
| 10 | Coda pick satura — oggetti persi |

---

## Configurazione Robot (pagina parametri — accesso tecnico)

### Comunicazione
| Variabile | Tipo | Accesso | Default | Descrizione |
|---|---|---|---|---|
| `IP_ROBOT` | STRING | R/W | '192.168.1.100' | IP controller robot — **CONFIGURARE** |
| `PORT_ROBOT` | UINT | R/W | 10000 | Porta TCP robot — **CONFIGURARE** |

### Geometria nastro/robot (PERSISTENT — sopravvive a download)
| Variabile | Tipo | Accesso | Default | Descrizione |
|---|---|---|---|---|
| `DISTANZA_ROBOT_MM` | REAL | R/W | 0.0 | Distanza NIR→punto di presa [mm] — **MISURARE** |
| `ALTEZZA` | REAL | R/W | 200.0 | Quota Z di presa [mm] — **MISURARE** |
| `GRADI_ROTAZIONE` | REAL | R/W | 0.0 | Orientamento pinza [gradi] |
| `ATTESA_PRESA` | REAL | R/W | 0.5 | Attesa dopo discesa [s] |
| `ATTESA_DEPOSITO` | REAL | R/W | 0.3 | Attesa al box [s] |
| `TEMPO_CICLO_ROBOT` | REAL | R/W | 1.0 | Ciclo pick stimato [s] — **CALIBRARE** |
| `SCAN_DISTANCE` | REAL | R/W | 3.5 | mm per scan NIR — vel_nastro_mm_s / linee_nir_s |

### Box di deposito (array — una riga per box)
| Variabile | Tipo | Accesso | Descrizione |
|---|---|---|---|
| `X_BOX[0..7]` | REAL[] | R/W | X coordinata box [mm] |
| `Y_BOX[0..7]` | REAL[] | R/W | Y coordinata box [mm] |
| `Z_BOX[0..7]` | REAL[] | R/W | Z coordinata box [mm] |
| `MATERIALI_ATTIVI_BOX[0..15]` | INT[] | R/W | Box destinazione per ogni materiale (0..7) |

### Segmentazione (calibrabili online)
| Variabile | Tipo | Accesso | Default | Descrizione |
|---|---|---|---|---|
| `OBJ_TRACK_TOLERANCE` | INT | R/W | 3 | Tracce margine laterale blob |
| `OBJ_GAP_ENCODER` | UDINT | R/W | 50 | Impulsi encoder gap = fine oggetto |

---

## Simulatore (pagina test — solo durante commissioning)

| Variabile | Tipo | Accesso | Descrizione |
|---|---|---|---|
| `SIM_ATTIVA` (in SIM_Robot) | BOOL | R/W | Attiva iniezione oggetti fittizi |
| `SIM_MODO` | INT | R/W | 0=steady, 1=round-robin mat, 2=burst |
| `SIM_INTERVALLO_S` | REAL | R/W | Secondi tra un oggetto e il prossimo |
| `SIM_MAT_FISSO` | INT | R/W | Materiale da simulare (modo 0) |

---

## Note HMI

- **`ABIL_ROBOT`**: interlock operatore. Quando FALSE → `Gestione_Robot` va in stato 99 (IDLE), la connessione TCP è chiusa e UiTag non avanza.
- **`ROBOT_CODA_PIENA`**: se appare, il robot è più lento della produzione NIR. Aumentare `TEMPO_CICLO_ROBOT` per migliorare la compensazione, o rallentare il nastro.
- **`EFFICIENZA_PICK`**: in teoria 100% se ogni oggetto rilevato viene pickato. Scende se la coda va in overflow o se il robot salta pick.
- **`CODA_UTILIZZO`**: in condizioni normali deve essere < 50%. Se sale verso 100%, il robot è in ritardo.
