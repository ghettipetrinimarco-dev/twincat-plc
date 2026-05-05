# CONTEXT.md — Fonte di Verità del Progetto

> Aggiornato: 2026-05-05
> Leggere sempre prima di toccare qualunque file.

---

## Descrizione Progetto
Sistemi di **selezione e scarto automatizzato materiali via NIR** con attuazione pneumatica.
Linea composta da 3 macchine indipendenti, tutte con TwinCAT SoftPLC su Windows.
Comunicazione esterna tramite **Modbus TCP** verso gestionale SCADA (Daniele).

---

## Macchine

| IP | Hardware | PLC | Stato |
|---|---|---|---|
| 192.168.1.31 | Beckhoff nativo | TwinCAT SoftPLC | In produzione |
| 192.168.1.32 | Beckhoff nativo | TwinCAT SoftPLC | In produzione |
| 192.168.1.34 | PC Elmak (SoftPLC) | TwinCAT SoftPLC | In produzione |

- Gateway: `192.168.1.1`
- DNS aziendali: `85.159.176.161` / `85.159.176.162` (obbligatori con IP statico)
- Teleassistenza: TeamViewer / AnyDesk

---

## Architettura Software

### POU Principale
- **`Processing`** — programma ST ciclico, uguale su tutte e 3 le macchine
- Gestisce: logica NIR, calcolo percentuali, allarmi, comunicazione Modbus

### Comunicazione Esterna
- Protocollo: **Modbus TCP** (TS6250), porta 502
- Area dati: `Modbus_Area AT %MW0 : ARRAY [0..51] OF WORD`
- Base SCADA: `12288` → `Indirizzo SCADA = 12288 + Indice Array`
- Scala REAL: `valore × 10.0 → WORD` (client divide /10)
- Logica allarme: `1 = OK`, `0 = Allarme`

### File Principali

| File | Descrizione |
|---|---|
| `src/Processing/modbus_mapping.st` | Codice ST mappatura Modbus (parziale, vedi TODO) |
| `docs/modbus/mappa-registri.md` | Tabella completa registri Modbus |
| `docs/modbus/integrazione-scada.md` | Linee guida per Daniele (SCADA) |
| `docs/modbus/eccezioni-vs-pdf.md` | Diff rispetto alla spec ufficiale V2 |
| `docs/network/architettura-rete.md` | IP, DNS, firewall |
| `docs/network/modbus-tcp-server.md` | Installazione e diagnostica TS6250 |
| `docs/hardware/topologia-macchine.md` | Descrizione 3 macchine |
| `docs/macchina/panoramica.md` | Panoramica funzionale impianto |

---

## Variabili Chiave

| Variabile | Tipo | Significato |
|---|---|---|
| `carico_min` | REAL | Carico minimo rilevato |
| `Pressione_aria` | REAL | Pressione aria compressa |
| `Flussostato_aria` | REAL | Portata aria compressa |
| `intervallo_ore_istantaneo` | UDINT | Intervallo ore (⚠️ troncato a WORD) |
| `PERC_SELEZIONATI[0..15]` | ARRAY OF REAL | % materiali selezionati |
| `PERC_CAMPIONATI[0..15]` | ARRAY OF REAL | % materiali campionati |
| `DIAGNOSTICA_OK` | BOOL | Diagnostica generale (1=OK) |
| `ENABLE` | BOOL | Abilitazione macchina |
| `KG_MINUTI` | REAL | Kg/minuto |
| `PESO_TOTALE` | REAL | Peso totale ciclo |
| `NUM_LOAD_ID` | BYTE | ID ricetta attiva (lettura) |
| `CMD_LOAD` | BOOL | Comando caricamento ricetta |
| `NUM_SELEZIONATI[i]` | UDINT | Contatore materiali selezionati per tipo |
| `idx_mb` | INT | Indice loop FOR mappatura Modbus |

---

## Decisioni Architetturali

| Data | Decisione | Motivo |
|---|---|---|
| 2026-05-05 | Trigger Modbus (reg. 12338/indice 50) non implementato | Accordo con Daniele: gestionale non usa il Trigger, sufficiente scrittura su indice 51 |
| 2026-05-05 | Scala ×10 per tutti i REAL | Compatibilità con gestionale SCADA che legge WORD |
| 2026-05-05 | Block Read da ~100 registri | Evita instabilità con letture singole su TS6250 |
| 2026-05-05 | PC Elmak (.34) usa TwinCAT SoftPLC | Stesso codice e logica delle Beckhoff native |

---

## TODO / Buchi Aperti

### Critici (bloccanti per lavori futuri)
- [ ] **Indici Modbus 43–49**: non documentati. Chiedere all'utente prima di qualunque modifica all'array.
- [ ] **Indici 1 e 5**: non scritti nel codice. Riservati o dimenticati?
- [ ] **UDINT→WORD indice 4** (`intervallo_ore_istantaneo`): voluto o bug latente? Se >65535 wrappa a 0.
- [ ] **Logica ENABLE (indice 39)**: invertita (1=ON/0=OFF) o diretta? Da confermare.
- [ ] **Notazione SCADA**: Daniele usa Base 0 o Base 1? Verificare strumentalmente su valore noto.
- [ ] **`PERC_SELEZIONATI`/`PERC_CAMPIONATI`**: dichiarate in GVL o localmente nel POU `Processing`?

### Informativi (non bloccanti)
- [ ] Versione TwinCAT (TC2/TC3 + build) su ciascuna macchina
- [ ] Licenza TS6250 e SoftPLC sulla .34 (regolare o trial?)
- [ ] Repository unico o 3 copie sincronizzate manualmente? (rischio drift)
- [ ] Funzione Modbus: FC03 o FC04?
- [ ] Frequenza polling SCADA (1s, 5s, on-change?)
- [ ] Materiale trattato (plastica, vetro, RAEE, alimentare?)
- [ ] Numero canali NIR per macchina, numero lane di scarto
- [ ] Le 3 macchine lavorano in serie (cascata) o in parallelo?
- [ ] La rete 192.168.1.x è condivisa con uffici/PC aziendali?
- [ ] Soluzione firewall uniformata su tutte e 3 le macchine?

---

## Modifiche in Corso
*(nessuna — progetto in fase di documentazione iniziale)*

---

## Storico Sessioni
| Data | Attività |
|---|---|
| 2026-05-05 | Prima sessione: raccolta contesto, creazione struttura repo, archiviazione documentazione iniziale |
