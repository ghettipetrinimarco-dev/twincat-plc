# Analisi preliminare progetto robot picker NIR

Aggiornato: 2026-05-26

## Materiale ricevuto

Cartella analizzata: `robot/`

File presenti:

| File | Stato | Nota |
|---|---|---|
| `robot/sensoreNIR.txt` | Structured Text, 760 righe | Versione modificata di `Sensore_NIR` con primo tentativo di generare stringhe target robot |
| `robot/gestioneencoder.txt` | Structured Text, 115 righe | Versione ridotta/vecchia di `Gestione_Encoder` |
| `robot/processing.txt` | Structured Text, 212 righe | Versione ridotta di `Processing`, senza Modbus 4.0 e senza logica licenza completa |
| `robot/gestionerobot.txt` | Vuoto | Manca il programma robot vero |

## Sintesi veloce

Il materiale nella cartella `robot` non contiene un progetto robot completo.

Contiene un tentativo parziale dentro `sensoreNIR.txt`:

- quando una traccia NIR corrisponde a un materiale attivo, costruisce una stringa testuale per il robot
- la stringa contiene dati tipo `id`, `x`, `y`, `z`, rotazione, attesa presa, coordinate deposito, attesa deposito
- alla fine del giro del buffer NIR copia `String_Tmp[]` in `String_ToSend[]`
- alza un trigger globale `Trig`
- pilota `Out_1 := Trig`

Questa e' una traccia utile, ma non e' ancora una "mente" robotica.

## Vecchio tentativo trovato

Blocco principale in `robot/sensoreNIR.txt`, righe circa 355-383:

```st
IF MATERIALI_ATTIVI[i] THEN
    indice_box := MATERIALI_ATTIVI_BOX[i];
    MSI_data[index_nir].track_mat_select[indice]:=TRUE;
    MSI_elab[index_nir].track_mat_select[indice]:=TRUE;

    concat_1:=CONCAT(START_CHAR,INT_TO_STRING(UiTag));
    concat_2 := CONCAT(SEP,INT_TO_STRING(indice));
    concat_3 := CONCAT(SEP, REAL_TO_STRING(index_nir*SCAN_DISTANCE+DISTANCE_OFFSET));
    concat_4 := CONCAT(SEP,REAL_TO_STRING(ALTEZZA));
    concat_5 := CONCAT(SEP, REAL_TO_STRING(GRADI_ROTAZIONE));
    concat_6:=CONCAT(SEP, REAL_TO_STRING(ATTESA_PRESA));
    concat_7:= CONCAT(SEP, REAL_TO_STRING(X_BOX[indice_box]));
    concat_8 :=CONCAT(SEP, REAL_TO_STRING(Y_BOX[indice_box]));
    concat_9 :=CONCAT(SEP, REAL_TO_STRING(Z_BOX[indice_box]));
    concat_10 := CONCAT(SEP, REAL_TO_STRING(ATTESA_DEPOSITO));
    concat_11 := CONCAT(SEP, END_CHAR);

    String_line_tmp := CONCAT(...);
    UiTag:=UiTag+1;
END_IF
```

Poi, quando `index_nir` supera `BUFFER_SIZE`, circa righe 436-443:

```st
index_nir:=index_nir+1;
IF index_nir >BUFFER_SIZE THEN
    index_nir:=0;
    FOR j:=0 TO BUFFER_SIZE DO
        String_ToSend[j]:=String_Tmp[j];
    END_FOR
    Trig:=TRUE;
END_IF
```

Alla fine del programma, circa righe 749-756:

```st
IF EK1100_STATE<>8 OR OUT_1_STATE<>8 THEN DIAGNOSTICA_OK:=FALSE; ELSE DIAGNOSTICA_OK:=TRUE; END_IF
Out_1:=Trig;
Ritardo_Trig.IN:=Trig;
Ritardo_Trig.PT:=INT_TO_TIME(TRIG_DELAY_RESET);
Ritardo_Trig();
IF Ritardo_Trig.Q THEN Trig:=FALSE; END_IF;
```

## Problemi tecnici del vecchio tentativo

### 1. `gestionerobot.txt` e' vuoto

Manca il programma che dovrebbe:

- leggere `String_ToSend[]`
- comunicare con robot o PC robot
- gestire stato robot pronto/occupato/errore
- gestire ACK ricezione comando
- gestire pick riuscito/fallito
- evitare doppio invio dello stesso target

### 2. Variabili globali mancanti

Nel repo attuale non sono definite queste variabili usate da `robot/sensoreNIR.txt`:

| Variabile | Uso probabile |
|---|---|
| `MATERIALI_ATTIVI_BOX` | Mappa materiale selezionato -> box/contenitore di deposito |
| `SCAN_DISTANCE` | Distanza fisica tra due scan NIR consecutivi |
| `DISTANCE_OFFSET` | Offset tra NIR e riferimento robot |
| `ALTEZZA` | Quota Z presa |
| `GRADI_ROTAZIONE` | Rotazione utensile robot |
| `ATTESA_PRESA` | Tempo attesa presa |
| `X_BOX` | Coordinate X deposito per box |
| `Y_BOX` | Coordinate Y deposito per box |
| `Z_BOX` | Coordinate Z deposito per box |
| `ATTESA_DEPOSITO` | Tempo attesa deposito |
| `String_ToSend` | Buffer stringhe da inviare al robot |
| `Trig` | Trigger di invio verso robot o sistema esterno |
| `TRIG_DELAY_RESET` | Tempo dopo cui resettare `Trig` |

Senza una GVL robot o dichiarazioni equivalenti, questo codice non puo' compilare.

### 3. Non esiste un vero target oggetto

Il codice crea una stringa per una singola traccia NIR (`indice`).

Questo significa:

```text
traccia NIR attiva -> stringa robot
```

Ma un robot deve prendere un pezzo fisico, non una singola traccia.

Serve invece:

```text
piu' tracce contigue + piu' scan consecutivi -> oggetto -> target robot
```

### 4. Se ci sono piu' tracce attive nella stessa scansione, si perde informazione

`String_line_tmp` viene sovrascritta dentro il ciclo `FOR indice:=1 TO NUM_TRACKS_NIR`.

Se nella stessa riga NIR ci sono piu' materiali attivi, resta solo l'ultima stringa costruita.

### 5. Il tempo/posizione non usa l'encoder nel modo giusto

La Y mandata al robot viene calcolata cosi':

```st
index_nir*SCAN_DISTANCE+DISTANCE_OFFSET
```

Questo dipende dall'indice circolare del buffer NIR, non dalla posizione encoder reale del conveyor.

Per una macchina reale serve legare il target alla posizione encoder:

```text
encoder_position_seen
current_position = encoder_position_seen + delta_encoder
```

Il progetto attuale NIR/EV ha gia' il concetto giusto con `Position += PASSO_ENCODER`, ma il tentativo robot non lo usa per creare un target persistente.

### 6. Non c'e' finestra di presa robot

Manca una logica tipo:

```text
target troppo presto -> resta in coda
target nella zona robot -> invia pick
target troppo tardi -> missed
```

### 7. Non c'e' handshake

Alzare `Trig` e copiarlo su `Out_1` non basta.

Serve almeno:

```text
PLC -> robot: target disponibile
robot -> PLC: target ricevuto
robot -> PLC: robot busy
robot -> PLC: pick completato
robot -> PLC: pick fallito
PLC -> robot: ack/reset
```

### 8. `Processing` nella cartella robot e' vecchio/ridotto

`robot/processing.txt` non contiene la mappa Modbus 4.0 presente nel progetto attuale.

Quindi non va preso come base principale senza integrare le modifiche successive del repo.

### 9. `Gestione_Encoder` nella cartella robot e' meno robusto del sorgente attuale

`robot/gestioneencoder.txt` non ha alcune logiche presenti nel sorgente attuale, ad esempio `Counter_aux` e `Trig_option`.

Quindi la base migliore per il futuro e' il sorgente attuale in `src/`, non i file ridotti in `robot/`, salvo recuperare dal `robot/sensoreNIR.txt` l'idea della stringa target.

## Cosa si puo' riutilizzare

Dal progetto attuale `src/`:

- comunicazione UDP col sensore LLA
- lettura 117 tracce NIR
- codici materiali e nomi materiali
- `MATERIALI_ATTIVI`
- buffer circolare `MSI_data`
- tracking con encoder in `Gestione_Encoder`
- task veloci/lenti
- diagnostica base
- Modbus/SCADA 4.0

Dal vecchio tentativo `robot/sensoreNIR.txt`:

- idea di protocollo stringa `@...#`
- idea di mappa materiale -> box deposito
- idea di trigger verso un sistema esterno
- coordinate deposito `X_BOX/Y_BOX/Z_BOX`

## Cosa manca per arrivare a una macchina funzionante

### A. Specifiche robot

Servono dati certi:

- marca e modello robot
- controller robot
- protocollo disponibile: TCP/IP, UDP, seriale, digital I/O, EtherCAT, Profinet, Modbus TCP, altro
- formato comando richiesto dal robot
- formato risposta robot
- coordinate accettate dal robot
- unita' di misura
- velocita' e accelerazioni
- stato robot disponibile: ready, busy, error, emergency

### B. Specifiche meccaniche

Servono:

- distanza fisica NIR -> centro zona presa robot
- larghezza utile conveyor
- scala traccia NIR -> coordinata laterale robot
- verso positivo X/Y robot rispetto al nastro
- quota Z di presa
- quota Z di sicurezza
- quota deposito
- posizione box/contenitori
- tempo ciclo medio presa/deposito
- velocita' nastro reale

### C. Modello target oggetto

Serve una struttura dati nuova, non solo stringhe.

Esempio:

```st
TYPE Robot_Target :
STRUCT
    id: UDINT;
    material_index: INT;
    material_code: BYTE;
    box_index: INT;
    x_pick: REAL;
    y_pick: REAL;
    z_pick: REAL;
    angle_pick: REAL;
    encoder_seen: UDINT;
    position: UDINT;
    width_tracks: INT;
    length_scans: INT;
    valid: BOOL;
    assigned: BOOL;
    sent: BOOL;
    picked: BOOL;
    missed: BOOL;
END_STRUCT
END_TYPE
```

### D. Object builder

Serve una logica che trasformi i dati NIR in pezzi fisici.

Minimo fattibile:

```text
1. per ogni scan NIR, trova gruppi di tracce contigue con materiale target
2. crea/aggiorna oggetti in corso
3. quando l'oggetto finisce, calcola centro laterale e lunghezza
4. assegna materiale dominante
5. crea `Robot_Target`
```

### E. Coda target robot

Serve una coda:

```text
detected -> queued -> in_pick_window -> sent -> picked/failed/missed
```

### F. Comunicazione robot

Serve un programma dedicato, ad esempio `Gestione_Robot`, che faccia solo:

- gestione socket o I/O robot
- invio target
- ricezione ACK/stati
- timeout
- errori
- reset

Non va mischiato dentro `Sensore_NIR`, altrimenti diventa ingestibile.

## Architettura consigliata

Non modificare direttamente il cuore NIR per comandare il robot.

Separare in POU:

```text
Sensore_NIR
  -> legge NIR e popola buffer scan

Object_Builder
  -> trasforma scan NIR in oggetti fisici

Robot_Queue
  -> mantiene target, finestra presa, priorita', missed

Gestione_Robot
  -> comunica col robot

Processing
  -> statistiche, Modbus, configurazione, diagnostica
```

## Priorita' operative

1. Recuperare o ricostruire la GVL robot mancante
   - variabili `X_BOX`, `String_ToSend`, `Trig`, ecc.

2. Capire protocollo robot reale
   - senza questo non si puo' scrivere `Gestione_Robot`

3. Creare modello dati `Robot_Target`

4. Fare simulazione PLC senza robot
   - generare target da NIR
   - visualizzare coda
   - verificare timing con encoder

5. Integrare robot con handshake minimo

6. Solo dopo ottimizzare segmentazione e multi-target

## Valutazione finale

Il progetto e' fattibile, ma i file nella cartella `robot` non sono ancora una base funzionante.

Il vecchio tentativo ha intuito il bisogno di mandare coordinate al robot, ma lo fa troppo presto e nel punto sbagliato:

- direttamente dentro `Sensore_NIR`
- per singola traccia/pixel
- senza costruire oggetti
- senza usare correttamente encoder e finestra di presa
- senza handshake robot
- senza POU robot

La base corretta e' il progetto attuale in `src/`, piu' un nuovo layer robot composto da:

```text
NIR scans -> oggetti -> coda target -> tracking encoder -> comando robot -> feedback
```

