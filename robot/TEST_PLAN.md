# Test Plan — Primo test prototipo robot NIR

> Seguire nell'ordine. Non saltare passi. Se un passo fallisce → stop e analisi prima di procedere.

---

## Fase 0 — Prima di accendere qualsiasi cosa (30 min)

### 0.1 Raccolta dati fisici (metro + foglio carta)

- [ ] **IP controller robot** — leggere dal pannello del controller (teach pendant o schermata About)
- [ ] **Porta TCP robot** — verificare programma RAPID presente, o caricare `RAPID_ROBOT.prg`
- [ ] **Distanza NIR → punto di presa** — misurare con metro la distanza fisica (in mm) dal sensore NIR alla zona dove il robot prende il pezzo. Scrivere qui: `DISTANZA_ROBOT_MM = _____ mm`
- [ ] **Altezza di presa** — misurare Z del nastro rispetto alla base robot. Scrivere: `ALTEZZA = _____ mm`
- [ ] **Posizioni box deposito** — misurare XYZ di ogni box. Scrivere su foglio separato
- [ ] **Velocità nastro** — misurare con tachimetro o contare impulsi/s encoder. Scrivere: `SPEED_NASTRO ≈ _____ m/s`
- [ ] **Linee NIR al secondo** — aprire TwinCAT, leggere variabile `Linee` a nastro fermo e in moto. Scrivere: `Linee ≈ _____ scans/s`
- [ ] Calcola `SCAN_DISTANCE = (SPEED_NASTRO × 1000) / Linee` = _____ mm/scan

### 0.2 Configurazione GVL_ROBOT (nel progetto TwinCAT)

Aprire `GVL_ROBOT` e compilare con i valori misurati:

```
IP_ROBOT            := '___.___.___.___ ';   (IP controller robot)
PORT_ROBOT          := _____;               (porta TCP)
DISTANZA_ROBOT_MM   := _____;               (mm)
ALTEZZA             := _____;               (mm)
SCAN_DISTANCE       := _____;               (mm/scan)
X_BOX[0]            := _____;  Y_BOX[0] := _____;  Z_BOX[0] := _____;
(ripetere per ogni box)
MATERIALI_ATTIVI_BOX[indice_materiale] := indice_box;
```

---

## Fase 1 — Test connessione TCP (senza movimento robot, 15 min)

**Obiettivo:** verificare che PLC e robot si vedano in rete e la stringa arrivi corretta.

### 1.1 Test ping
- [ ] Dal PLC (TwinCAT → ADS → ping) verificare raggiungibilità `IP_ROBOT`
- [ ] Dal controller robot verificare raggiungibilità PLC (`192.168.1.3x`)

### 1.2 Carica programma robot
- [ ] Caricare `RAPID_ROBOT.prg` sul controller ABB via RobotStudio o USB
- [ ] Avviare il task in modalità **manuale T1** (velocità ridotta, operatore in zona)
- [ ] Verificare sul teach pendant: "In ascolto su porta 10000..."

### 1.3 Test connessione dal PLC
- [ ] In TwinCAT: impostare `ABIL_ROBOT := TRUE`
- [ ] Verificare su teach pendant: "PLC connesso. Attendo comandi pick..."
- [ ] Verificare su TwinCAT: `Gestione_Robot.Stato = 1` (RUNNING)

### 1.4 Test stringa senza NIR (forzatura manuale)
- [ ] In TwinCAT, scrivere manualmente un OBJ_PICK di test nel GVL:
  ```
  OBJ_queue[0].X          := 58.0;
  OBJ_queue[0].Y          := 0;       (* encoder start *)
  OBJ_queue[0].materiale  := 0;
  OBJ_queue[0].indice_box := 0;
  OBJ_queue[0].valido     := TRUE;
  OBJ_queue[0].inviato    := FALSE;
  obj_head := 1;
  obj_tail := 0;
  ```
- [ ] Verificare sul teach pendant che arriva la stringa con valori ragionevoli
- [ ] Verificare `n_pick_inviati = 1` in TwinCAT

---

## Fase 2 — Test movimento robot (zona sicura, senza nastro, 30 min)

**Prerequisiti:** Fase 1 completata. Operatore fuori dalla zona robot.

### 2.1 Calibrazione tool e workobject
- [ ] Con RobotStudio o teach pendant, calibrare `tool_pinza` (TCP)
- [ ] Definire `wobj_nastro` con 3 punti sul piano del nastro

### 2.2 Test pick in posizione nota
- [ ] Posizionare un pezzo di test sul nastro (fermo) in una posizione nota
- [ ] Calcolare manualmente X, Y, Z del pezzo
- [ ] Scrivere OBJ_PICK con quei valori
- [ ] Avviare in **modalità manuale T1** (max 250mm/s)
- [ ] Verificare che il robot si avvicini correttamente
- [ ] Calibrare `DISTANZA_ROBOT_MM` se la posizione Y è sfasata

### 2.3 Test deposito
- [ ] Dopo presa corretta, verificare movimento verso `X_BOX[0]`, `Y_BOX[0]`, `Z_BOX[0]`
- [ ] Calibrare Z_BOX se il deposito non è preciso

---

## Fase 3 — Test con NIR attivo (nastro fermo, 20 min)

**Obiettivo:** verificare che FB_Segmentazione produca oggetti sensati.

### 3.1 Verifica segmentazione
- [ ] Mettere un pezzo di materiale noto sul nastro (fermo)
- [ ] Attivare NIR (`ABIL_NIR := TRUE`)
- [ ] Verificare in TwinCAT che `OBJ_queue` si riempia con oggetti
- [ ] Controllare che `X` corrisponda alla posizione laterale del pezzo (traccia NIR)
- [ ] Controllare che `materiale` corrisponda al polimero del pezzo

### 3.2 Calibrazione OBJ_GAP_ENCODER
- [ ] Mettere due pezzi vicini sul nastro
- [ ] Se generano un solo oggetto: aumentare `OBJ_GAP_ENCODER`
- [ ] Se un pezzo genera due oggetti: diminuire `OBJ_GAP_ENCODER`

### 3.3 Calibrazione OBJ_TRACK_TOLERANCE
- [ ] Se oggetti larghi vengono spezzati in due: aumentare `OBJ_TRACK_TOLERANCE`
- [ ] Default (3 tracce) è conservativo e solitamente sufficiente

---

## Fase 4 — Test integrato con nastro in moto (lento, 30 min)

**Prerequisiti:** Fasi 1-3 OK. Robot in modalità automatica, operatore fuori zona.

### 4.1 Velocità nastro bassa (50% del normale)
- [ ] Avviare nastro a velocità ridotta
- [ ] Verificare che gli oggetti vengano rilevati e pickati
- [ ] Osservare se la posizione Y pick è corretta o sfasata
- [ ] Correggere `DISTANZA_ROBOT_MM` se necessario

### 4.2 Verifica throughput
- [ ] Contare pezzi pickati al minuto
- [ ] Verificare che `n_pick_inviati` corrisponda ai pick visivi
- [ ] Verificare che `n_errori_tcp = 0` e `n_errori_parse = 0`

### 4.3 Velocità nastro normale
- [ ] Portare il nastro a velocità operativa
- [ ] Se il robot non riesce a stare al passo → considerare:
  - Ridurre velocità nastro
  - Aumentare velocità robot (con supervisione tecnico ABB)
  - Implementare conveyor tracking RobotWare (tracking dinamico)

---

## Fase 5 — Segnalazioni problemi comuni

| Sintomo | Causa probabile | Fix |
|---|---|---|
| `Stato = 0` e non avanza | IP/porta robot errati, robot non in ascolto | Verificare RAPID_ROBOT.prg caricato e running |
| `n_errori_tcp` cresce | Disconnessioni TCP | Verificare rete, ridurre carico loop PLC |
| `OBJ_queue` sempre vuoto | sensoreNIR non modificato | Seguire INTEGRAZIONE_SENSORE_NIR.md |
| Oggetti con X errata | Conversione traccia→mm sbagliata | Verificare `SCAN_DISTANCE` |
| Robot manca il pezzo in Y | `DISTANZA_ROBOT_MM` non calibrato | Misurare e correggere |
| Tanti oggetti per un pezzo | `OBJ_GAP_ENCODER` troppo piccolo | Aumentare valore |
| Oggetti uniti che sono separati | `OBJ_TRACK_TOLERANCE` troppo grande | Diminuire valore |
| Robot troppo lento | Velocità nastro > ciclo robot | Ridurre nastro o aumentare vRobot |

---

## Checklist finale pre-produzione

- [ ] Test a velocità piena per 10 minuti senza errori
- [ ] `n_errori_tcp = 0` per tutta la durata
- [ ] Efficienza pick > X% (definire target con il cliente)
- [ ] Nessun falso pick (oggetti sbagliati pickati)
- [ ] Reconnect TCP testato (staccare cavo rete e ricollegare)
- [ ] Backup completo configurazione robot (RAPID + tooldata + wobjdata)
- [ ] CONTEXT.md aggiornato con tutti i valori calibrati

