# Mappa Registri Modbus TCP

## Regole Generali

| Parametro | Valore |
|---|---|
| Area PLC | `%MW0` |
| Dichiarazione | `Modbus_Area AT %MW0 : ARRAY [0..51] OF WORD` |
| Funzione Modbus | FC03 Read Holding Registers (da confermare) |
| Base indirizzo SCADA | **12288** (`0x3000`) |
| Formula | `Indirizzo SCADA = 12288 + Indice Array PLC` |
| Notazione client | Base 0 — PDU address (da confermare con Daniele) |

**Conversione REAL → WORD:** moltiplicare per `10.0` e convertire con `REAL_TO_WORD`.
Il client SCADA divide per 10 per ottenere il valore reale.
Esempio: `100.0%` → valore Modbus `1000`.

**Logica allarme:** `1 = OK (Marcia)`, `0 = Allarme` (logica invertita).

## Mappa Completa

| Indice Array | Indirizzo SCADA | Variabile PLC | Tipo PLC | Scala | Significato |
|---|---|---|---|---|---|
| 0 | 12288 | `carico_min` | REAL | ×10 | Carico minimo rilevato |
| 1 | 12289 | — | — | — | **TODO: riservato o mancante?** |
| 2 | 12290 | `Pressione_aria` | REAL | ×10 | Pressione aria compressa |
| 3 | 12291 | `Flussostato_aria` | REAL | ×10 | Portata aria compressa |
| 4 | 12292 | `intervallo_ore_istantaneo` | UDINT→WORD | — | Intervallo ore istantaneo ⚠️ |
| 5 | 12293 | — | — | — | **TODO: riservato o mancante?** |
| 6..21 | 12294..12309 | `PERC_SELEZIONATI[0..15]` | REAL | ×10 | Percentuali materiali selezionati |
| 22..37 | 12310..12325 | `PERC_CAMPIONATI[0..15]` | REAL | ×10 | Percentuali materiali campionati |
| 38 | 12326 | `DIAGNOSTICA_OK` | BOOL | 1=OK / 0=Allarme | Diagnostica generale |
| 39 | 12327 | `ENABLE` | BOOL | 1=ON / 0=OFF | Abilitazione macchina (⚠️ verificare se logica invertita) |
| 40 | 12328 | `KG_MINUTI` | REAL | ×10 | Kg/minuto |
| 41 | 12329 | `PESO_TOTALE` | REAL | ×10 | Peso totale ciclo |
| 42 | 12330 | `NUM_LOAD_ID` | BYTE→WORD | — | ID ricetta attiva (lettura) |
| 43..49 | 12331..12337 | — | — | — | **TODO: ignoti, non ancora documentati** |
| 50 | 12338 | *(Trigger)* | — | — | **NON GESTITO** dal PLC (vedi `eccezioni-vs-pdf.md`) |
| 51 | 12339 | *(Numero Modello)* | WORD | — | **Scrittura SCADA:** ID ricetta. Se >0 → `CMD_LOAD:=TRUE` + auto-reset |

## Warning Tecnici

### ⚠️ Indice 4 — UDINT troncato a WORD
`intervallo_ore_istantaneo` è UDINT (32 bit) ma viene assegnato a una WORD (16 bit) con `UDINT_TO_WORD`.
Se il valore supera **65535** (~18 ore), il registro wrapperà a 0 silenziosamente.
**Da chiarire:** comportamento voluto (valore non supera mai 65535) o bug latente?

### ⚠️ Indici 1 e 5 — Non scritti
Questi indici non compaiono nel codice ST ricevuto. Potrebbero essere riservati per usi futuri o dimenticati.
**Da chiarire prima di usarli.**

### ⚠️ Offset Base 0 / Base 1
Se lo SCADA legge i dati sfasati di 1, correggere l'offset del client (±1).
La notazione in uso con Daniele è da confermare strumentalmente su una lettura nota.

### ℹ️ Zeri su PERC_SELEZIONATI / PERC_CAMPIONATI
Valori a zero sono fisiologici: indicano che nessun materiale di quel tipo è transitato nel ciclo corrente.
**Non sono errori di rete.** Verificare il transito reale sotto i sensori NIR prima di qualsiasi intervento.
