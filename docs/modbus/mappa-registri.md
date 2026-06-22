# Mappa Registri Modbus TCP — v5.0

> Aggiornato: 2026-06-08 (sessione 8 — nuovi registri SPEED/LINEE/NIR, fix PESO_TOTALE overflow, comandi scrittura ABIL_NIR e reset contatori)

## Regole Generali

| Parametro | Valore |
|---|---|
| Area PLC | `%MW0` |
| Dichiarazione | `Modbus_Area AT %MW0 : ARRAY [0..51] OF WORD` |
| Funzione Modbus | FC03 Read Holding Registers |
| Base indirizzo SCADA | **12288** (`0x3000`) |
| Formula | `Indirizzo SCADA = 12288 + Indice Array PLC` |
| Offset Daniele (SELECT) | **+1** su tutti gli indirizzi — es. nostro [39]=12327, Daniele chiama 12328 |

**Scala REAL → WORD:** moltiplicare per `10.0` → client divide per 10.
**PESO_TOTALE DWORD:** `peso_kg = Modbus_Area[5] × 65536 + Modbus_Area[41]` (senza decimali, precisione 1 kg).

---

## Mappa Completa

| Indice | SCADA | Dan. (+1) | Dir. | Variabile PLC | Scala | Significato |
|---|---|---|---|---|---|---|
| 0 | 12288 | 12289 | R | `CARICO_MIN` | ×10 | % carico macchina al minuto |
| 1 | 12289 | 12290 | R | `SPEED` | ×10 | Velocità nastro (m/s) |
| 2 | 12290 | 12291 | R | `Pressione_aria` | ×10 | Pressione aria ⚠️ 0 se sensore non installato |
| 3 | 12291 | 12292 | R | `Flussostato_aria` | ×10 | Flusso aria ⚠️ 0 se sensore non installato |
| 4 | 12292 | 12293 | R | `INTERVALLO_ORE_ISTANTANEO` | — | Ore utilizzo ⚠️ tronca a 65535 (~18h) |
| 5 | 12293 | 12294 | R | `PESO_TOTALE` HIGH | — | DWORD HIGH WORD (×65536) — **fix overflow** |
| 6..21 | 12294..12309 | 12295..12310 | R | `PERC_SELEZIONATI[0..15]` | ×10 | % materiali selezionati (16 di 101) |
| 22..37 | 12310..12325 | 12311..12326 | R | `PERC_CAMPIONATI[0..15]` | ×10 | % materiali campionati (16 di 101) |
| 38 | 12326 | 12327 | R | `DIAGNOSTICA_OK` | — | 1=OK, 0=allarme I/O |
| 39 | 12327 | 12328 | R | `SPEED>0.5 AND NIR_ATTIVO AND DIAGNOSTICA_OK` | — | **1=in lavorazione, 0=ferma** — fix sessione 7 |
| 40 | 12328 | 12329 | R | `KG_MINUTI` | ×10 | Kg/minuto ⚠️ 0 su .33/.34 (REAL precision esaurita) |
| 41 | 12329 | 12330 | R | `PESO_TOTALE` LOW | — | DWORD LOW WORD — **fix overflow** (era ×10) |
| 42 | 12330 | 12331 | R | `NUM_LOAD_ID` | — | Ricetta attiva (BYTE) |
| 43 | 12331 | 12332 | R | `LINEE` | — | Linee NIR al secondo (INT) |
| 44 | 12332 | 12333 | R | `ABIL_NIR` stato | — | 1=NIR online, 0=NIR offline |
| 45 | 12333 | 12334 | **W** | `ABIL_NIR` comando | — | Scrivere **1**=abilita, **2**=spegni. Auto-reset a 0. |
| 46 | 12334 | 12335 | **W** | Reset contatori | — | bit0=RESET_SELEZIONATI, bit1=RESET_CAMPIONATI |
| 47 | 12335 | 12336 | R | `ETH_LINK_OK` | — | 1=link sensore NIR ok, 0=link assente |
| 48..50 | 12336..12338 | 12337..12339 | — | — | — | Riservati |
| 51 | 12339 | 12340 | **W** | Cambio ricetta | — | Scrivere ID (1..255) → `CMD_LOAD:=TRUE`. Auto-reset a 0. ⚠️ non modificare senza accordo Daniele |

---

## Lettura PESO_TOTALE dal gestionale

```
peso_kg = Modbus_Area[5] × 65536 + Modbus_Area[41]
```

Esempio: [5]=2, [41]=405 → peso = 2×65536 + 405 = **131.477 kg**
Max rappresentabile: 65535×65536 + 65535 = **~4,3 miliardi kg**

---

## Comandi in scrittura — Riepilogo

| Registro (Daniele) | Azione | Come |
|---|---|---|
| 12334 | Abilita NIR + luci | Scrivere 1 |
| 12334 | Spegni NIR + luci | Scrivere 2 |
| 12335 | Reset % selezionati | Scrivere 1 (bit 0) |
| 12335 | Reset % campionati | Scrivere 2 (bit 1) |
| 12335 | Reset entrambi | Scrivere 3 (bit 0+1) |
| 12340 | Carica ricetta N | Scrivere N (1..255) |

---

## Warning Tecnici

### ⚠️ PESO_TOTALE su .33/.34 — REAL precision esaurita
`PESO_TOTALE` su .33 = 3.276.305 kg, su .34 simile. A queste grandezze la precisione REAL 32-bit
è ~0.4 kg → incrementi per minuto non registrabili → `KG_MINUTI = 0`.
`PESO_TOTALE` stesso viene trasmesso correttamente via DWORD (arrotondato a 1 kg).
Fix definitivo: REAL → LREAL (richiede rebuild offline).

### ⚠️ Pressione e Flussostato = 0 su .31/.32
Confermato live: `PRESSIONE = 0` raw in `Gestione_Espulsione`. I moduli analogici
(`ANALOG_IN_STATE=8`) funzionano ma i sensori fisici non sono installati/collegati su queste macchine.
Non è un problema di codice né di Modbus.

### ⚠️ CARICO_MIN mostra 0 nel gestionale Evergreen
Il valore è corretto nel PLC (22.81 confermato live). Daniele probabilmente legge il registro
sbagliato per questo campo. Da verificare con lui quale indirizzo usa per "Carico minimo".

### ⚠️ Offset Daniele +1
Daniele (SELECT Informatica) usa indirizzamento 1-based.
Nostro registro N → Daniele chiama N+1.
Verificato strumentalmente su registro 12327/12328 (sessione 7).

### ℹ️ Zeri su PERC_SELEZIONATI/PERC_CAMPIONATI
Valori zero fisiologici: nessun materiale di quel tipo transitato. Non intervenire lato rete.
