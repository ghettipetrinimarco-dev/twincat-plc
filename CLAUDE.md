# CLAUDE.md — TwinCAT PLC

## Prima di ogni sessione
1. Leggi CONTEXT.md — è la fonte di verità sullo stato del progetto.
2. Leggi notes/ per appunti recenti.
3. Se l'utente fornisce nuovo materiale, proponi dove archiviarlo prima di agire.

## Convenzioni file
- src/ — codice ST (.TcPOU, .TcGVL, .st, .txt)
- docs/ — specifiche, schemi, manuali
- notes/ — appunti di sessione, dump grezzi

## Regole di lavoro
- Mai modificare codice ST senza aver confermato il contesto in CONTEXT.md.
- Ogni modifica significativa → aggiorna "Storico decisioni" e "Modifiche in corso".
- Non inventare nomi di variabili/FB/indirizzi I/O — chiedi se mancano.

## Regole di interazione AI (Strict Mode)
- **Regola Zero:** Se mancano informazioni (file non leggibili, indirizzi sconosciuti, logica hardware non chiara) → fermati e chiedi. Non procedere con supposizioni.
- **Nessuna allucinazione tecnica:** Nomi variabili, indirizzi Modbus, parametri I/O devono provenire esclusivamente dai file di contesto o da conferma esplicita dell'utente. Se non ci sono, chiedi un test strumentale sul PLC (es. forzatura variabile per verificare offset).
- **No people-pleasing:** Non dare una risposta a tutti i costi. "Non lo so, verifica X" è una risposta valida e preferibile a una risposta inventata.
- **Codice compilabile:** Ogni snippet ST suggerito deve essere verificabile concettualmente e coerente con il contesto dichiarato.
- **Registro Modbus 12338 (Trigger) e 12339 (Numero Modello):** Non modificare la logica di gestione ricette senza accordo esplicito con lo sviluppatore del gestionale SCADA (Daniele).
- **Zeri su PERC_SELEZIONATI/PERC_CAMPIONATI:** Non suggerire modifiche di rete per risolvere valori a zero. Chiedere prima di verificare il transito materiale reale sotto i sensori NIR.

<!-- COMPANY_BRAIN_POINTER_START -->
## Company Brain

Questo progetto fa parte del Company Brain Obsidian in `/Users/marco/Developer/brain`.

Prima di lavorare qui:
1. Leggi `/Users/marco/Developer/brain/llms.txt`.
2. Leggi `/Users/marco/Developer/brain/08_Data/project-context-map.json`.
3. Leggi `/Users/marco/Developer/brain/03_Projects/twincat.md`.
4. Usa `/Users/marco/Developer/brain/06_Docs/AI Context Retrieval.md` e `/Users/marco/Developer/brain/06_Docs/AI Skill Routing.md` per scegliere contesto e skill senza scandire tutto il workspace.

Non leggere cartelle intere se la mappa compatta indica gia' i file chiave.
<!-- COMPANY_BRAIN_POINTER_END -->
