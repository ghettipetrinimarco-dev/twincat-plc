# Robot picker NIR - indice operativo

Aggiornato: 2026-05-26

Questa cartella raccoglie l'analisi preliminare per trasformare la selezionatrice NIR in una macchina con robot picker.

## Lettura consigliata

Per farsi un quadro rapido:

1. `sintesi-operativa.md`
2. `analisi-preliminare.md`
3. `mvp-tecnico.md`
4. `fase-1-specifica-implementazione.md`
5. `scaffold-st-note-integrazione.md`

Per andare in azienda e recuperare dati:

1. `checklist-dati-mancanti.md`
2. `protocollo-robot-provvisorio.md`

Per lavorare sul codice:

1. `verifica-statica-scaffold.md`
2. `scaffold-st-note-integrazione.md`
3. `piano-test-twincat-fase-1.md`
4. `src/Robot/README.md`

Per confrontarsi con Claude o riprendere il lavoro:

1. `handoff-claude.md`
2. `backlog-operativo.md`

## Documenti

| Documento | Quando leggerlo | Contenuto |
|---|---|---|
| `sintesi-operativa.md` | Subito | Riassunto decisionale: cosa c'e', cosa manca, cosa fare |
| `analisi-preliminare.md` | Subito dopo | Analisi dei file ricevuti in `robot/` |
| `roadmap-implementazione.md` | Pianificazione | Roadmap completa verso macchina reale |
| `checklist-dati-mancanti.md` | In officina/azienda | Dati da recuperare su robot, quote, protocolli, safety |
| `mvp-tecnico.md` | Prima di scrivere codice | Requisiti del primo MVP |
| `fase-1-specifica-implementazione.md` | Durante implementazione | POU, dati, algoritmi e test Fase 1 |
| `protocollo-robot-provvisorio.md` | Quando si parla col robot | Formato `@...#` dedotto e protocollo consigliato |
| `scaffold-st-note-integrazione.md` | Prima dell'import TwinCAT | Come importare/testare lo scaffold senza rompere l'esistente |
| `verifica-statica-scaffold.md` | Prima della compilazione | Controlli fatti e rischi residui TwinCAT |
| `piano-test-twincat-fase-1.md` | Durante test TwinCAT | Watch list, passi e risultati attesi |
| `handoff-claude.md` | Confronto con Claude | Contesto, diagnosi e domande per review |
| `backlog-operativo.md` | Prossime sessioni | Task ordinati P0-P4 |

## Stato tecnico

Lo scaffold e' in:

```text
src/Robot/
```

Stato:

```text
bozza separata
non collegata ai task TwinCAT
non compilata in TwinCAT
non pronta per produzione
utile per Fase 1 simulata
```

## Prossima azione consigliata

Importare lo scaffold in una copia di test TwinCAT e provare:

```text
ROBOT_ENABLED := TRUE
ROBOT_SIMULATION := TRUE
ROBOT_TEST_INPUT_ENABLED := TRUE
ROBOT_TEST_CREATE_TARGET := TRUE
```

Obiettivo:

```text
target manuale -> coda -> finestra presa -> robot simulato -> picked/missed
```
