# Linee Guida Integrazione SCADA (Daniele)

## 1. Lettura Ottimizzata (Block Read)
**Problema storico:** Letture singole instabili, perdita di pacchetti con TS6250.

**Soluzione:** Il client Modbus deve usare la **lettura multipla** richiedendo un blocco di ~100 registri a partire dall'indirizzo base (`12288`), acquisendo l'intero `Modbus_Area` in un singolo ciclo di rete.

- Non usare letture registro per registro
- Un solo Block Read per ciclo di polling evita il sovraccarico del servizio TS6250

<!-- TODO: confermare frequenza di polling attuale (1s, 5s, on-change?) -->

## 2. Allineamento Indirizzi e Offset
La formula di mappatura è:

```
Indirizzo SCADA = 12288 + Indice Array PLC
```

Esempio: `PESO_TOTALE` (Array `[41]`) → Indirizzo SCADA `12329`.

**Offset Base 0 / Base 1:** Se lo SCADA legge dati sfasati di 1 posizione, correggere l'offset del client (±1). Questo indica che il client usa Base 1 (notazione Modicon classica) anziché Base 0 (PDU Modbus).
<!-- TODO: confermare quale notazione usa Daniele, verificare strumentalmente su un valore noto -->

## 3. Zeri Logici su Percentuali Materiali
I valori `0` su alcune percentuali materiali **non sono errori di rete**.

Formula usata nel PLC:
```
UDINT_TO_REAL(NUM_SELEZIONATI[i]) * 100 / Totale_perc_selezionato
```

Se un materiale non è stato scartato nel ciclo corrente, la formula produce `0` correttamente.
I dati "vivi" si spostano dinamicamente sugli indici in base al materiale presente.

**Non modificare la configurazione di rete per risolvere i "valori a zero".** Verificare prima l'effettivo transito di materiale sotto i sensori NIR.

## 4. Scrittura Ricette (Numero Modello)
Il SCADA può scrivere l'ID della nuova ricetta nel registro `12339` (Indice Array `[51]`).

Comportamento PLC:
1. PLC riceve un valore `> 0` all'indice `[51]`
2. Forza internamente `CMD_LOAD := TRUE`
3. Resetta il registro a `0`

**Attenzione:** La specifica tecnica ufficiale prevede anche un Trigger di esecuzione (registro `12338` / Indice `[50]`). Questo **non è attualmente implementato** nel PLC. Vedere `docs/modbus/eccezioni-vs-pdf.md`.
