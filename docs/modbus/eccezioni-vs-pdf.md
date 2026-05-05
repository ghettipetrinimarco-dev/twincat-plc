# Eccezioni rispetto alla Specifica Tecnica Ufficiale

## Documento di riferimento
"Specifica Tecnica Modbus TCP - Espansa (V2)"

---

## Eccezione 1: Trigger di Esecuzione (Registro 12338 / Indice [50])

**Cosa prevede la specifica:**
Un sistema di Handshake a due registri per il caricamento delle ricette:
- Registro `12338` (Indice `[50]`): Trigger di esecuzione
- Registro `12339` (Indice `[51]`): Numero Modello (ID ricetta)

Il flusso previsto è: SCADA scrive prima il modello target (`12339`), poi alza il trigger (`12338`). Il PLC esegue il caricamento e abbassa il trigger come ACK.

**Implementazione attuale (semplificata):**
Il PLC **non gestisce** il Trigger (`[50]`). La logica è:
- SCADA scrive solo il Numero Modello in `[51]`
- Se PLC riceve valore `> 0` su `[51]` → forza `CMD_LOAD := TRUE` + resetta `[51]` a 0
- Il registro `[50]` viene ignorato

**Motivazione della semplificazione:**
Accordo con lo sviluppatore del gestionale (Daniele). Il gestionale attuale non implementa il lato SCADA del Trigger.

**⚠️ Regola operativa:**
Non modificare questa logica senza accordo esplicito con Daniele (sviluppatore gestionale SCADA).
Qualsiasi cambio impatta il lato client e può bloccare il caricamento ricette in produzione.
