# Robot picker NIR - indice operativo

Aggiornato: 2026-05-26

Questa cartella raccoglie l'analisi preliminare per trasformare la selezionatrice NIR in una macchina con robot picker.

## Lettura consigliata

Per farsi un quadro rapido:

1. `sintesi-operativa.md`
2. `analisi-preliminare.md`
3. `analisi-gestionerobot-pickmaster.md`
4. `mvp-tecnico.md`
5. `fase-1-specifica-implementazione.md`
6. `scaffold-st-note-integrazione.md`

Per andare in azienda e recuperare dati:

1. `checklist-dati-mancanti.md`
2. `protocollo-robot-provvisorio.md`

Per lavorare sul codice:

1. `lavoro-offline-senza-twincat.md`
2. `specifica-pickmaster-driver.md`
3. `verifica-statica-scaffold.md`
4. `scaffold-st-note-integrazione.md`
5. `checklist-prima-compilazione.md`
6. `pacchetto-import-twincat.md`
7. `piano-test-twincat-fase-1.md`
8. `comando-robot-da-target.md`
9. `src/Robot/README.md`

Per confrontarsi con Claude o riprendere il lavoro:

1. `handoff-claude.md`
2. `backlog-operativo.md`

## Documenti

| Documento | Quando leggerlo | Contenuto |
|---|---|---|
| `sintesi-operativa.md` | Subito | Riassunto decisionale: cosa c'e', cosa manca, cosa fare |
| `analisi-preliminare.md` | Subito dopo | Analisi dei file ricevuti in `robot/` |
| `analisi-gestionerobot-pickmaster.md` | Dopo aggiornamento Claude | Analisi PickMaster/UserHook e come si collega al nuovo scaffold |
| `roadmap-implementazione.md` | Pianificazione | Roadmap completa verso macchina reale |
| `checklist-dati-mancanti.md` | In officina/azienda | Dati da recuperare su robot, quote, protocolli, safety |
| `mvp-tecnico.md` | Prima di scrivere codice | Requisiti del primo MVP |
| `fase-1-specifica-implementazione.md` | Durante implementazione | POU, dati, algoritmi e test Fase 1 |
| `protocollo-robot-provvisorio.md` | Quando si parla col robot | Formato `@...#` dedotto e protocollo consigliato |
| `comando-robot-da-target.md` | Prima di implementare invio robot | Mappa campi numerici e stringa opzionale da target PLC a comando robot |
| `lavoro-offline-senza-twincat.md` | Quando non abbiamo TwinCAT/macchina | Cosa si puo' fare solo lavorando sulle cartelle |
| `specifica-pickmaster-driver.md` | Prima di scrivere driver reale | Specifica stati/variabili per futuro `Robot_PickMasterDriver` |
| `scaffold-st-note-integrazione.md` | Prima dell'import TwinCAT | Come importare/testare lo scaffold senza rompere l'esistente |
| `verifica-statica-scaffold.md` | Prima della compilazione | Controlli fatti e rischi residui TwinCAT |
| `checklist-prima-compilazione.md` | Durante primo compile | Errori probabili TwinCAT e correzioni rapide |
| `pacchetto-import-twincat.md` | Prima di aprire TwinCAT | File esatti, watch minima e primo test |
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
