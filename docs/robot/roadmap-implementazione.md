# Roadmap implementazione robot picker NIR

Aggiornato: 2026-05-26

## Obiettivo

Arrivare a un programma TwinCAT che permetta a un macchinario robotizzato di prelevare da un conveyor i materiali selezionati dal sensore NIR LLA.

Il caso base e':

```text
cliente seleziona polimero/materiale target
NIR riconosce il materiale sul nastro
PLC costruisce un target prendibile
robot prende il pezzo
robot deposita nel box corretto
PLC registra esito e diagnostica
```

## Strategia consigliata

Non partire dal robot fisico come primo passo.

La parte critica e' costruire target affidabili:

```text
scan NIR -> oggetto fisico -> target robot -> comando robot
```

Se la coda target e' sbagliata, anche il robot migliore sembrera' non funzionare.

## MVP realistico

### MVP 1 - Simulazione target senza robot reale

Scopo: dimostrare che il PLC sa trasformare il NIR in target.

Funzioni:

- leggere NIR come oggi
- riconoscere materiali attivi
- raggruppare tracce contigue in un "pezzo"
- calcolare coordinata laterale presa
- associare box deposito
- mettere target in coda
- avanzare target con encoder
- dichiarare target `in_window` quando entra nella zona presa
- dichiarare target `missed` quando esce dalla zona presa

Output:

- array `Robot_Targets[]`
- contatori `targets_detected`, `targets_sent`, `targets_missed`
- diagnostica visibile da HMI/SCADA

Questo MVP si puo' sviluppare anche senza robot fisico, se conosciamo dimensioni e distanze di massima.

### MVP 2 - Handshake robot simulato

Scopo: provare la logica di assegnazione.

Funzioni:

- stato robot simulato: `ready`, `busy`, `error`
- invio target quando entra nella finestra
- tempo ciclo simulato
- esito simulato `picked` o `failed`

Output:

- si vede se la coda regge velocita' nastro e flusso pezzi
- si capisce se un robot basta o se servono priorita'/salti

### MVP 3 - Comunicazione robot reale

Scopo: sostituire il robot simulato con il controller reale.

Funzioni:

- invio target al robot
- ricezione ACK
- ricezione `busy/ready/error`
- timeout
- retry controllato
- gestione `picked/failed`

Blocco: serve il protocollo reale del robot.

### MVP 4 - Ottimizzazione presa

Scopo: migliorare affidabilita'.

Funzioni:

- scegliere centroide pezzo invece della prima traccia
- filtrare falsi positivi
- ignorare pezzi troppo piccoli/grandi
- gestire pezzi sovrapposti
- scegliere priorita' se passano troppi target

## Architettura POU proposta

### `Sensore_NIR`

Responsabilita':

- comunicazione UDP LLA/MSI
- lettura scan NIR
- popolamento `MSI_data` / `MSI_elab`
- classificazione materiali per traccia

Da evitare:

- inviare stringhe al robot
- gestire handshake robot
- decidere code robot

### `Robot_ObjectBuilder`

Nuovo POU.

Responsabilita':

- leggere scan NIR gia' decodificati
- trovare gruppi di tracce contigue
- costruire oggetti fisici
- stimare centro laterale
- stimare lunghezza
- assegnare materiale dominante
- creare target robot

### `Robot_Queue`

Nuovo POU.

Responsabilita':

- mantenere lista target
- aggiornare posizione con encoder
- calcolare finestra presa
- scegliere prossimo target inviabile
- marcare target mancati

### `Gestione_Robot`

Nuovo POU.

Responsabilita':

- comunicare col robot o col PC robot
- inviare target
- leggere stato robot
- gestire ACK, timeout, errori

### `Processing`

Responsabilita':

- parametri configurabili
- statistiche
- Modbus/SCADA
- diagnostica

## Strutture dati proposte

### Target robot

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
    position_impulses: UDINT;
    width_tracks: INT;
    length_scans: INT;
    confidence: REAL;
    valid: BOOL;
    in_window: BOOL;
    assigned: BOOL;
    sent: BOOL;
    picked: BOOL;
    failed: BOOL;
    missed: BOOL;
END_STRUCT
END_TYPE
```

### Stato robot

```st
TYPE Robot_State :
STRUCT
    enabled: BOOL;
    ready: BOOL;
    busy: BOOL;
    error: BOOL;
    ack: BOOL;
    pick_done: BOOL;
    pick_failed: BOOL;
    current_target_id: UDINT;
    error_code: UINT;
END_STRUCT
END_TYPE
```

### Parametri robot

```st
TYPE Robot_Config :
STRUCT
    track_pitch_mm: REAL;
    nir_to_pick_distance_mm: REAL;
    pick_window_start_mm: REAL;
    pick_window_end_mm: REAL;
    z_pick_mm: REAL;
    angle_default_deg: REAL;
    max_targets: INT;
    min_width_tracks: INT;
    max_width_tracks: INT;
    min_length_scans: INT;
    max_length_scans: INT;
END_STRUCT
END_TYPE
```

## Parametri mancanti

### Dati meccanici

Da recuperare:

| Dato | Perche' serve |
|---|---|
| Distanza NIR -> centro zona presa robot | Calcolo quando inviare target |
| Larghezza conveyor utile | Conversione traccia -> mm |
| Larghezza coperta dal NIR | Conversione traccia -> mm |
| Numero tracce effettive usate | Validazione coordinate |
| Verso nastro rispetto al robot | Segno X/Y |
| Quota Z presa | Movimento robot |
| Quote box deposito | Deposito |
| Velocita' nastro tipica e massima | Dimensionamento finestra presa |
| Tempo ciclo robot | Capire quanti pezzi puo' prendere |

### Dati robot

Da recuperare:

| Dato | Perche' serve |
|---|---|
| Marca/modello robot | Capire protocolli e limiti |
| Controller robot | Dove gira la cinematica |
| Protocollo comando | Implementare `Gestione_Robot` |
| Formato comando pick | Generare messaggi corretti |
| Formato risposta | Handshake |
| Coordinate richieste | Trasformazione coordinate |
| Stato ready/busy/error | Evitare invii a robot non pronto |
| Limiti area lavoro | Filtrare target non prendibili |

### Dati NIR/materiali

Da recuperare:

| Dato | Perche' serve |
|---|---|
| Codici polimeri reali | Mappa materiale |
| Quali materiali vanno in quali box | `MATERIALI_ATTIVI_BOX` |
| Se target e' singolo polimero o multi-materiale | Priorita' |
| Falsi positivi accettabili | Filtri |
| Dimensioni minime pezzo prendibile | Object builder |

## Decisioni tecniche da prendere

### Dove costruire gli oggetti

Opzione A: tutto in TwinCAT ST

Pro:

- meno componenti esterni
- piu' vicino al controllo macchina
- debug PLC diretto

Contro:

- Structured Text non e' ideale per algoritmi complessi su matrici/blob
- rischio carico CPU su task veloci
- meno flessibile per algoritmi futuri

Opzione B: TwinCAT fa tracking e handshake, PC esterno fa object builder

Pro:

- algoritmo oggetti piu' facile in Python/C#/C++
- possibile visualizzazione/debug migliore
- piu' facile evolvere con AI/visione

Contro:

- piu' comunicazione
- piu' punti di guasto
- serve protocollo robusto tra PC e PLC

Scelta consigliata per MVP:

- object builder semplice in TwinCAT, se i pezzi sono separati e le regole sono facili
- se i pezzi sono sovrapposti o irregolari, valutare PC esterno

### Come comunicare col robot

Opzione A: stringa `@...#` come vecchio tentativo

Pro:

- semplice
- leggibile
- probabilmente gia' pensata per qualcosa

Contro:

- serve sapere chi la riceve
- serve ACK
- con stringhe in TC2 bisogna stare attenti a lunghezze e buffer

Opzione B: segnali digitali + area dati

Pro:

- robusto e semplice
- buono per primo test

Contro:

- pochi dati
- coordinate complesse scomode

Opzione C: TCP/IP strutturato

Pro:

- adatto a target con coordinate
- espandibile

Contro:

- serve implementazione socket robusta

## Piano operativo consigliato

### Fase 0 - Recupero informazioni

Durata stimata: 1-2 giorni se i dati sono disponibili.

Output:

- modello robot
- protocollo robot
- quote meccaniche
- schema I/O o rete
- foto/screenshot HMI/progetto robot esistente
- eventuale GVL robot mancante

### Fase 1 - Mettere ordine al progetto

Durata stimata: 1 giorno.

Output:

- archiviare i file `robot/` come riferimento storico
- non usarli come sorgente principale
- creare cartella `src/Robot/` o file `.EXP` nuovi
- creare tipi `Robot_Target`, `Robot_State`, `Robot_Config`

### Fase 2 - Simulatore target

Durata stimata: 2-4 giorni.

Output:

- target generati da dati NIR simulati o reali
- coda target visibile
- conteggio detected/missed
- nessun robot reale richiesto

### Fase 3 - Object builder base

Durata stimata: 3-7 giorni.

Output:

- raggruppamento tracce contigue
- calcolo centro pick
- filtro dimensioni minime
- target materiale -> box

### Fase 4 - Tracking e finestra presa

Durata stimata: 2-5 giorni.

Output:

- target avanza con encoder
- pick window funzionante
- scarto target fuori finestra

### Fase 5 - Comunicazione robot

Durata stimata: dipende dal protocollo.

Output:

- handshake
- invio target reale
- ACK
- timeout/errori

### Fase 6 - Test su macchina

Durata stimata: iterativa.

Output:

- test a nastro lento
- test target singolo
- test target multipli
- regolazione offset e quote
- verifica sicurezza

## Prima implementazione consigliata

Creare un layer robot separato, senza toccare ancora la selezionatrice pneumatica:

```text
src/Robot/
  ROBOT_TYPES.EXP
  ROBOT_GLOBALS.EXP
  ROBOT_OBJECT_BUILDER.EXP
  ROBOT_QUEUE.EXP
  GESTIONE_ROBOT.EXP
```

In TwinCAT 2 si puo' anche partire con `.txt`/`.st` e poi esportare in `.EXP`.

## Criterio di successo del primo programma

Prima di comandare il robot reale, il PLC deve dimostrare:

```text
Dato un materiale attivo,
quando il NIR lo vede sul nastro,
il PLC crea un target unico,
lo segue con encoder,
lo marca prendibile nella finestra corretta,
e lo marca perso se non viene preso.
```

Solo dopo ha senso agganciare il robot reale.

