# Checklist dati mancanti - robot picker NIR

Aggiornato: 2026-05-26

Questa checklist serve per trasformare il prototipo attuale in un programma realmente avviabile.

## Priorita' 1 - Dati senza cui non si puo' comandare il robot

| Dato | Stato | Perche' serve | Come recuperarlo |
|---|---|---|---|
| Marca e modello robot | Mancante | Capire area lavoro, protocolli e limiti | Targhetta robot/controller, manuale, foto quadro |
| Controller robot | Mancante | Sapere chi esegue cinematica e traiettorie | Foto controller, software usato, manuale |
| Protocollo comunicazione | Mancante | Scrivere `Gestione_Robot` | Manuale controller o progetto vecchio |
| Formato comando pick | Mancante | Costruire messaggio target corretto | Esempio funzionante o documentazione |
| Formato risposta/ACK | Mancante | Evitare doppi invii e target persi | Log, manuale o test con robot |
| Segnali ready/busy/error | Mancante | Non inviare target quando robot non puo' prenderli | I/O mapping, protocollo o HMI robot |
| Segnale pick riuscito/fallito | Mancante | Chiudere il ciclo target | I/O mapping o protocollo |
| Limiti area di presa | Mancante | Filtrare target non raggiungibili | Disegno meccanico o test manuale |

## Priorita' 2 - Quote meccaniche

| Dato | Stato | Perche' serve | Note |
|---|---|---|---|
| Distanza NIR -> inizio finestra presa | Mancante | Sapere quando un target diventa prendibile | In mm o impulsi encoder |
| Distanza NIR -> centro presa robot | Mancante | Calcolare tempo/posizione comando | Fondamentale per tracking |
| Fine finestra presa robot | Mancante | Marcare target `missed` | Serve per evitare comandi impossibili |
| Larghezza utile conveyor | Mancante | Convertire traccia NIR -> coordinata laterale | Da misurare fisicamente |
| Larghezza coperta dal NIR | Mancante | Calcolare pitch traccia | `track_pitch_mm = larghezza / 117` se tutto coperto |
| Verso positivo coordinate robot | Mancante | Evitare target specchiati | Serve disegno o test |
| Quota Z presa | Mancante | Comando robot | Dipende da altezza nastro e utensile |
| Quota Z sicurezza | Mancante | Movimento sicuro | Dipende dal robot |
| Coordinate box deposito | Parzialmente ipotizzate | Nel vecchio codice esistono `X_BOX/Y_BOX/Z_BOX`, ma manca GVL | Recuperare GVL o misurare |
| Tempo ciclo presa/deposito | Mancante | Capire throughput reale | Cronometrare robot |

## Priorita' 3 - NIR e materiali

| Dato | Stato | Perche' serve |
|---|---|---|
| Codici polimeri reali del sensore | Nel PLC, ma da validare | Mappare PET/PP/PE/PVC/ecc. |
| Materiali selezionabili dal cliente | Mancante | Configurazione HMI/SCADA |
| Materiale -> box deposito | Mancante | Serve `MATERIALI_ATTIVI_BOX` |
| Dimensione minima pezzo prendibile | Mancante | Filtrare rumore e frammenti |
| Dimensione massima pezzo prendibile | Mancante | Evitare target non gestibili |
| Pezzi sovrapposti ammessi? | Mancante | Decide complessita' object builder |
| Polimero dominante o singola traccia? | Mancante | Decide come classificare un oggetto |

## Priorita' 4 - Architettura elettrica e safety

| Dato | Stato | Perche' serve |
|---|---|---|
| Schema I/O robot | Mancante | Collegare ready/busy/error/ack |
| Schema emergenze | Mancante | Safety macchina |
| Presenza TwinSAFE o safety esterna | Mancante | Responsabilita' arresto robot |
| Stato aria/ventosa/gripper | Mancante | Validare presa |
| Sensore vuoto ventosa o presa pezzo | Mancante | Pick riuscito/fallito |
| Modalita' manuale/automatica | Mancante | Avviamento e debug |

## Priorita' 5 - File/progetti da recuperare

| File/progetto | Perche' serve |
|---|---|
| GVL robot del vecchio prototipo | Contiene variabili mancanti come `X_BOX`, `Trig`, `String_ToSend` |
| Programma `GestioneRobot` originale | Il file attuale e' vuoto |
| Progetto robot/controller | Capire protocollo e formato target |
| Manuale controller robot | Implementare comunicazione corretta |
| Backup TwinCAT completo del prototipo | Verificare mapping I/O e task |
| Foto HMI robot/prototipo | Capire parametri gia' previsti |
| Video del prototipo in funzione/non funzione | Capire failure mode reale |

## Test minimi da fare in azienda

1. Forzare un target singolo e vedere se il robot riceve qualcosa.
2. Verificare se `Out_1 := Trig` era collegato a un ingresso robot.
3. Cercare sul robot/controller log o messaggi ricevuti dal PLC.
4. Verificare se esiste un cavo Ethernet PLC -> robot o solo I/O digitali.
5. Misurare distanza NIR -> area presa.
6. Misurare larghezza conveyor e posizione laterale tracce.
7. Fare passare un solo pezzo target sotto NIR e salvare comportamento.
8. Fare passare due pezzi vicini e vedere se il vecchio tentativo genera target sensati.

## Domande secche da fare al tecnico/produttore

1. Il robot riceve comandi via stringa `@...#`?
2. Se si', su quale canale: TCP, UDP, seriale, file, altro?
3. Il robot manda un ACK?
4. Cosa significano i campi della stringa vecchia?
5. Le coordinate sono in mm?
6. `indice` nel vecchio codice era davvero X laterale o solo numero traccia?
7. `index_nir*SCAN_DISTANCE+DISTANCE_OFFSET` era temporaneo o usato in macchina?
8. Che cosa doveva fare `Trig`?
9. `String_ToSend[]` chi lo leggeva?
10. Perche' `GestioneRobot.txt` e' vuoto?

