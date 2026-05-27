# Import in TwinCAT 2 PLC Control — Progetto Robot

Cartella sorgente: tutti i `.EXP` qui dentro. Da importare in **un colpo solo** in un progetto nuovo.

## Procedura

### 1. Crea progetto nuovo
1. Apri **TwinCAT PLC Control** (NON System Manager)
2. **File → New**
3. Selezionare il runtime corrispondente alla macchina di test:
   - `BC via AMS` se BC-runtime
   - `CX (ARM)` o `CX (x86)` se Beckhoff CX
   - `PC or CX (x86)` per PC standard con TwinCAT 2 SoftPLC
4. Confermare. Si aprirà un progetto vuoto con MAIN/PLC_PRG di default.

### 2. Cancella MAIN/PLC_PRG di default
Nel pannello a sinistra, tab **POUs**:
- click destro su `MAIN` (o `PLC_PRG`) → **Delete object**

### 3. Importa tutti i file
1. **Project → Import...**
2. Selezionare TUTTI i file `.EXP` di questa cartella (Ctrl+A nel dialogo)
3. Confermare. TwinCAT processerà ogni file e creerà gli oggetti.

> ⚠️ Se vengono visualizzati conflitti su `Global_Variables` o oggetti già esistenti
> (perché il "nuovo progetto" li aveva di default), scegliere "Overwrite".

### 4. Verifica struttura
Dopo l'import dovresti vedere:

**Tab POUs:**
- `FB_Segmentazione` (Function Block)
- `Gestione_Encoder_Robot` (Program)
- `Gestione_Robot` (Program)
- `Processing_Robot` (Program)
- `Sensore_NIR` (Program)
- `SIM_Robot` (Program, opzionale)

**Tab Data Types:**
- `OBJ_PICK`
- `BLOB_TRACKER`
- `RX_NIR`
- `RX_NIR_ELAB`

**Tab Resources:**
- `Global_Variables` (popolato)
- `Task configuration` → 3 task (Input_Output, Gestione_Robot_Task, Elaboration)
- `Variable_Configuration` (vuoto)
- `PLC Configuration`
- `Alarm configuration`

**Tab Resources → Library Manager:**
- STANDARD.LIB, TCBASE.LIB, TCSYSTEM.LIB, TCUTILITIES.LIB, TCPIP.LIB

### 5. Salva il progetto
**File → Save as...** → `NIR_Robot_v1.pro` nella cartella `robot/`.
Da ora hai il `.pro` binario.

### 6. Build
**Project → Rebuild All** (F11).

Aspettati errori al primo build — soprattutto:
- Variabili AT %I*/%Q* non mappate (encoder) → normali finché non si configura System Manager
- Eventuali librerie mancanti → installare via Library Manager (le 5 .LIB sono standard Beckhoff TC2)

**Copia il primo blocco di errori e mandameli** — li sistemo uno per uno.

### 7. System Manager
Dopo che PLC Control compila pulito:
1. Salva e chiudi PLC Control
2. Apri **TwinCAT System Manager**
3. Importa il `.tpy` generato (in `robot/NIR_Robot_v1.tpy` se il path matcha)
4. Configura PLC project: link al `.pro`
5. Mappa l'encoder fisico (modulo EtherCAT EL5101 o equivalente) ai 3 AT %I* di Gestione_Encoder_Robot

## File inclusi

| File | Tipo | Origine |
|---|---|---|
| `STANDARD.LIB.EXP` | Library | Riusato da src/ (Beckhoff standard) |
| `TCBASE.LIB.EXP` | Library | Riusato da src/ |
| `TCSYSTEM.LIB.EXP` | Library | Riusato da src/ (per NT_GetTime, TC_CpuUsage) |
| `TCUTILITIES.LIB.EXP` | Library | Riusato da src/ |
| `TCPIP.LIB.EXP` | Library | Riusato da src/ (per FB_SocketConnect/Send/Receive/Close) |
| `WORKSPACE.EXP` | Visu settings | Riusato da src/ |
| `PLC_CONFIGURATION.EXP` | PLC config | Riusato da src/ |
| `ALARM_CONFIGURATION.EXP` | Alarm config | Riusato da src/ |
| `VARIABLE_CONFIGURATION.EXP` | Var config | Riusato da src/ (vuoto) |
| `TASK_CONFIGURATION.EXP` | Task config | **NUOVO** — 3 task robot (Input_Output, Gestione_Robot, Elaboration) |
| `TWINCAT_CONFIGURATION.EXP` | I/O mapping | **NUOVO** — solo encoder, no EV |
| `GLOBAL_VARIABLES.EXP` | GVL | Generato da `../GVL_COMPLETO_ROBOT.EXP` |
| `RX_NIR.EXP` | TYPE | Riusato da src/ |
| `RX_NIR_ELAB.EXP` | TYPE | Riusato da src/ |
| `OBJ_PICK.EXP` | TYPE | **NUOVO** — robot |
| `BLOB_TRACKER.EXP` | TYPE | **NUOVO** — robot |
| `FB_SEGMENTAZIONE.EXP` | Function Block | **NUOVO** — robot |
| `GESTIONE_ENCODER_ROBOT.EXP` | Program | Convertito da `../gestioneencoder_robot.txt` |
| `SENSORE_NIR.EXP` | Program | Convertito da `../sensoreNIR.txt` |
| `GESTIONE_ROBOT.EXP` | Program | Convertito da `../gestionerobot.txt` |
| `PROCESSING_ROBOT.EXP` | Program | Convertito da `../processing_robot.txt` |
| `SIM_ROBOT.EXP` | Program | Convertito da `../SIM_Robot.txt` (opzionale, test offline) |

## Note importanti

1. **Non ho potuto testare l'import** — non ho TwinCAT su questa macchina. Sono ragionevolmente confidente sulla struttura (replicata 1:1 dal progetto selezionatrice esistente), ma piccoli aggiustamenti potrebbero servire al primo build.

2. **Le librerie .LIB sono "snapshot di export"**, non le librerie binarie reali. Servono perché il progetto sappia che dipende da quelle librerie. Se TwinCAT chiede di installare le librerie reali, sono già presenti nell'installazione standard Beckhoff TC2.

3. **`SIM_Robot.txt`** può essere lasciato importato; resta inerte finché `SIM_ATTIVA = FALSE`. Per attivarlo durante test, decommentare la riga `SIM_Robot();` in `TASK_CONFIGURATION.EXP` (task Elaboration) e settare SIM_ATTIVA via watch.

4. **`Macchina_pronta AT %Q*` e `Errore_connessione_sensore AT %Q*`** sono dichiarati ma il loro mapping I/O (`%QX0.0`, `%QX0.1` nel TWINCAT_CONFIGURATION) è arbitrario — adattare ai moduli di output reali nel System Manager.
