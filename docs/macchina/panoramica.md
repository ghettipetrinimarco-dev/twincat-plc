# Panoramica Macchina

## Tipologia di Impianto
Sistemi di **selezione e scarto automatizzato dei materiali** tramite analisi ottica NIR (Near Infrared).

Ciclo base:
1. Materiale transita sotto i sensori NIR
2. NIR identifica la natura del materiale
3. TwinCAT elabora la logica (`Processing`) e decide se scartare
4. Elettrovalvole pneumatiche "sparano" aria compressa per deviare il materiale

**Nota:** Valori a zero su `PERC_SELEZIONATI`/`PERC_CAMPIONATI` sono fisiologici se nessun materiale di quel tipo è transitato nel ciclo corrente. Non è un errore di rete.

## Composizione Linea
3 macchine indipendenti sulla stessa rete `192.168.1.0/24`:

| IP | Hardware | Runtime |
|---|---|---|
| 192.168.1.31 | Beckhoff nativo | TwinCAT SoftPLC |
| 192.168.1.32 | Beckhoff nativo | TwinCAT SoftPLC |
| 192.168.1.34 | PC Industriale Elmak | TwinCAT SoftPLC |

Tutte e 3 eseguono lo stesso POU `Processing` con la stessa mappa Modbus.

<!-- TODO: confermare se le 3 macchine sono in serie (cascata) o in parallelo -->
<!-- TODO: confermare tipo materiale trattato (plastica, vetro, RAEE...) -->

## Componenti Fisici per Macchina

### Unità di Calcolo (Cervello)
- Beckhoff IPC (`.31`, `.32`) o PC Elmak (`.34`) con TwinCAT come SoftPLC su Windows

### Sistema di Acquisizione (Input)
- **Sensori NIR:** rilevano il tipo di materiale in transito
- **Sensori di Pressione:** controllano la presenza dell'aria compressa (`Pressione_aria`)
- **Flussostati:** controllano la portata aria (`Flussostato_aria`)
- **Sensori di Carico:** monitorano peso/flusso materiale in ingresso (`carico_min`)

<!-- TODO: numero canali NIR per macchina, numero lane di scarto -->
<!-- TODO: pressione nominale e soglia allarme flussostato -->

### Sistema di Attuazione (Output)
- Batterie di elettrovalvole pneumatiche per lo scarto fisico del materiale

### Moduli I/O (Interfaccia)
- Terminali ("fettine") digitali e analogici che interfacciano sensori/valvole con il SoftPLC
- Bus di campo interno: EtherCAT (da confermare)

## Architettura di Comunicazione

### Livello Campo (Real-Time, interno)
```
Sensore → Modulo I/O → Bus EtherCAT → TwinCAT (Processing.st) → Modulo I/O → Elettrovalvola
```

### Livello Supervisione (Gestione Dati, esterno)
```
TwinCAT → Modbus_Area[0..51] → TS6250 (porta 502) → LAN Ethernet → SCADA/Gestionale
```
