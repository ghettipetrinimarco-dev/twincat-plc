# ESO Recycling - guasto quadro Siemens S7-1200 (linea ex Pianezze)

Data: 2026-11-09. Fuori dal perimetro TwinCAT: e' il quadro Siemens che comanda gli inverter della linea, non le selezionatrici Beckhoff.

## Guasto
- Dopo la pulizia annuale a schiuma il quadro non riparte.
- Con alimentato solo il PLC, i LED fanno on/off ciclico (riavvio in loop). Sospetto CPU danneggiata, non ancora confermato con prova a carichi scollegati.
- Le valvole sono gestite da un altro quadro (prima linea), non coinvolto.

## Hardware (da foto e confermato dal progetto TIA)
| Componente | Codice |
|---|---|
| CPU 1214C AC/DC/RLY (1a generazione, alimentazione 230 VAC) | 6ES7214-1BE30-0XB0 |
| Signal board SB 1221 DI 4x24VDC 200 kHz | 6ES7221-3BD30-0XB0 |
| Modulo comunicazione CM 1241 RS485 (verso inverter) | 6ES7241-1CH30-0XB0 |
| Moduli I/O a destra (da progetto) | 6ES7223-1PL30, 6ES7221-1BH30, 6ES7231-4HD30, 6ES7223-1BH30, 6ES7222-1BH30 |
| Inverter | Siemens MICROMASTER 440 (2 acquistati nel 2013, ordine 1616-2013 Comet) |
| HMI | Siemens Multipanel touch con logo BMCR |

Ricambio CPU proposto: 6ES7214-1BG40-0XB0 (1214C AC/DC/RLY, FW V4). Evitare la nuova serie S7-1200 G2 finche' non e' verificata la compatibilita' di SB e CM.

## Dove sta il programma
- Originale: PC di Davide (192.168.1.17, Win7 32 bit, TIA Portal V12), `C:\Users\Davide\Documents\Eso_Recycling\Quadro Gestione impianto`.
- Copia: condivisione `Interscambio/X MARCO/eso siemens da pc davide/Quadro Gestione impianto` (563 MB).
- Progetto TIA `controllo_plastica`, versioni: V10.5 (originale), V12 SP1 Update 4, V13 SP1 (ultima modifica 13/05/2019).
- Nella stessa cartella: schemi elettrici (Quadro_1, Quadro_2, scansione con correzioni a mano), parametrizzazione inverter, foto quadro, manuale gestione serranda.
- Schema elettrico selezionatrice 1500 (SAEG commessa 12003): `...\Eso_Recycling\Selezionatrice_1 - ex linea Pianezze\Schema elettrico` sul PC di Davide.

## Verifica sul campo (foto e video di Simone, 2026-11-09)
- Targhetta porta: "QUADRO 2 LINEA B". Costruttore quadro: C.N. Impianti srl (Montebello Vicentino), armadio CEB data code 10-2011.
- Schema `Schema elettrico/Quadro_2.pdf`: "Quadro automazione gestione rulliere smistamento plastica", committente PIANEZZE, commessa 1206, disegno 1108/1206-0CN01, gen-mar 2012, comandi 110 Vac, segnali 24 Vdc.
- Corrispondenze schema-quadro: fili 24P-00 / 24M-00 sulla CPU, interruttori 54QF01-05, 50QF01, 74QF01, contattori 202KMxx / 212KMxx con bobina 110 V.
- Moduli visti sulla barra: CM 1241 RS485 (6ES7241-1CH30), CPU 1214C (6ES7214-1BE30) + SB 1221, SM 1223 DC/RLY (6ES7223-1PL32), SM 1231 AI (6ES7231-4HD30), SM 1223 DC/DC (6ES7223-1BH32, prodotto 2014).
- Il SM 1223 DC/DC del 2014 compare nelle versioni V12/V13 del progetto e non nella V10.5 originale: la versione attiva e' una delle due recenti. Da confermare in TIA che la configurazione hardware sia esattamente questa.
- Inverter: 2 MICROMASTER 440 (destra) + 2 azionamenti a sinistra (51A01, 75A01) che sembrano SINAMICS G120: da verificare se sostituiti di recente e se il programma e' stato adattato.

## Verifica in TIA Portal (sera 2026-11-09, via TeamViewer sul PC di Davide)
- Sul PC di Davide c'e' solo TIA Portal V12 SP1 Update 4 (STEP 7 Professional + WinCC Basic). Niente V13: la conversione alla CPU 1BG40 va fatta con un TIA piu' recente su altro PC.
- Il progetto contiene DUE PLC: PLC_1 e PLC_2, entrambi CPU 1214C AC/DC/RLY 1BE30 FW V1.0, collegati in rete (PN/IE_3).
- PLC_2 = Quadro 2 Linea B. Rack: 101 CM 1241 RS485, 1 CPU + SB 1221 (3BD30), 2 SM 1223 DI16/DQ16 relay (1PL30), 3 SM 1231 AI4 (4HD30), 4 SM 1223 DI8/DQ8 (1BH30). Identico alle foto. IP 192.168.0.4 /24.
- PLC_1 ha almeno 6 moduli (DI16, DI16/DQ, AI4, DQ16...): e' l'altro quadro.
- Date file dati (PEData.plf): V12 SP1 22/10/2015, V13 SP1 06/11/2015, versione V10.5 originale 05/09/2016 11:52 (stessa ora del touch). Le date 2018/2019 sono solo un file da 4 byte. La versione da usare e' quindi `controllo_plastica` V10.5 del 05/09/2016.
- Copie di lavoro sul PC di Davide in `C:\LAVORO_ESO\` (originali intatti). La V10.5 aggiornata a V12 e salvata in `C:\LAVORO_ESO\controllo_plastica_2016_V12_SP1_Update_4`.
- Compilazione PLC_2 (versione 2016) in V12: 0 errori, 2 avvisi (PID_Compact versione obsoleta). Blocchi: Main OB1, Comando_inv FC1, Auto_start FC3, Allarmi FC4, Autostop FC5.
- Da ricordare in conversione: aggiornare PID_Compact e ricontrollarne i parametri.

## Confronto versioni PLC_2 (2015 V12 vs 2016 V10.5), memoria di lavoro in byte
| Blocco | 2015 | 2016 |
|---|---|---|
| Main OB1 | 1185 | 1185 |
| Comando_inv FC1 | 1341 | 1341 |
| Manuale FC2 | 470 | 453 (cambiato) |
| Auto_start FC3 | 568 | 568 |
| Allarmi FC4 | 370 | 373 (cambiato) |
| Autostop FC5 | 154 | 154 |
| USS_PORT FC1070, USS_DRV FB1071, PID_Compact FB1130, DB | uguali | uguali |
- Totali: 2015 load 228419 / work 11221; 2016 load 227895 / work 11207. Piccole differenze di load memory su altri blocchi (probabili commenti).
- Inverter comandati via protocollo USS su CM 1241 RS485 (USS_PORT/USS_DRV).
- Upgrade path (Siemens): da V14 in su si aprono solo progetti >= V13 SP1; Project Upgrader (richiede V17+) aggiorna progetti >= V13 SP1.
- Piano consigliato: convertire con TIA recente la V13 SP1 (2015) e riportare a mano le modifiche di FC2 e FC4 dalla versione 2016.

## TIA V13 SP2 (sera 2026-11-09)
- Scaricato STEP 7 Basic V13 SP2 Upd4 TRIAL (Siemens ID 109745155) con account Marco: 12 file, MD5 verificati.
- File in `C:\LAVORO_ESO\setup_V13SP2`, estratti in `C:\LAVORO_ESO\setup_V13SP2\estratto`.
- PC Davide: Win7 Pro 32 bit SP1, KB3033929 non risulta installato.
- Dopo il riavvio il setup Basic si e' rifiutato: sul PC c'era GIA' installato TIA Portal V13 SP2 Upd2 (STEP 7 Professional, WinCC Professional, SINAMICS Startdrive). Setup annullato, nulla installato. I file di setup in `setup_V13SP2` non servono piu'.
- Versione 2016 convertita in V13 SP1: `C:\LAVORO_ESO\controllo_plastica_2016_V12_SP1_Update_4_V13_SP1`, copia su condivisione `Interscambio/X MARCO/eso siemens da pc davide/conversione/controllo_plastica_2016_V13_SP1`.
- Compilazione PLC_2 in V13: 2 errori (istruzioni USS_BASE e USS_DRV da aggiornare a versione piu' recente nella task card Istruzioni), 2 avvisi (PID_Compact obsoleto). Da sistemare nel TIA finale.
- Causa errori USS: FC1 Comando_inv usa la libreria legacy "USS" (USS_PORT V1.0, USS_DRV V1.0, cartella USS V1.1) legata alla CPU FW V1.0. In V13 esiste anche "USS Communication" V2.3 (USS_Port_Scan/USS_Drive_Control) per CPU FW piu' recenti. Con la CPU 1BG40 FW V4 probabilmente le chiamate USS vanno sostituite con le nuove istruzioni e ricollegati i parametri (DA VERIFICARE nel TIA recente). Non corretto in V13: inutile sulla CPU vecchia.
- Il catalogo V13 SP2 non contiene la CPU 1214C 1BG40 (solo 1BE30 e 1BG31): il cambio CPU va fatto con TIA V14 o successivo.
- Prossimo passo (PC Win10): TIA recente in prova, aprire/aggiornare il progetto V13 SP1, sostituire CPU con 6ES7214-1BG40-0XB0, aggiornare USS_BASE/USS_DRV/PID_Compact, PUT/GET, IP 192.168.0.4, compilare.

## Video LED in azienda (2026-11-10, quadro ancora cablato)
- Ciclo continuo di circa 1-1,5 s: si accendono TUTTI insieme (RUN/STOP, ERROR, MAINT, tutti i LED DI della CPU e della SB, DIAG di CM 1241 e moduli), poi tutto spento, poi di nuovo.
- Tutti i LED accesi insieme = test LED dell'avvio: la CPU non supera l'avvio e si riavvia. Coerente con alimentazione interna che cade (corto o assorbimento eccessivo sul 24 V uscita sensori o sul bus dei moduli, probabile umidita' da schiuma) oppure con CPU guasta. Da distinguere con la prova a sola CPU.
- CPU smontata dal quadro e portata al banco (MAC 00-1C-06-08-A9-AF, 214-1BE30-0XB0, SB 1221 ancora montata).
- Trovato in azienda un portatile Dell Win10 con TIA Portal V15 e V15.1, PLCSIM V15.1, TIA Updater, Automation License Manager (probabile lavoro di Davide). Si prova prima con V15.1 invece di installare un TIA in prova: apre progetti da V13 SP1 e ha la 1214C 1BG40 FW V4.x.

## Invio a Picchio srl (2026-11-10, richiesta di Gabriele Canestrini)
- Picchio vuole verificare che il loro TIA apra il programma e che non ci siano password.
- Pacchetto in `Interscambio/X MARCO/eso siemens da pc davide/invio_picchio_2026-11-10`: zip del progetto V13 SP1 (versione 2016, 5 MB, senza `tmp`), schema `Schema elettrico/Quadro_2.pdf` (2012) e `quadro_2.pdf` (scansione con correzioni, 2013).
- Bozza Gmail (account marco.bmcr) a sw@picchiosrl.com; allegati da aggiungere a mano e invio fatto da Marco.
- NAS sul Mac: `smb://AMMINISTRATORE@192.168.1.6/Condivisione`, montato come `/Volumes/Condivisione`.
- PC di lavoro: portatile Dell Win10 "Bmcr", Wi-Fi 192.168.1.9, raggiunto con Desktop remoto (TeamViewer bloccato all'avvio).

## Conversione verso TIA V15.1 (2026-11-10)
- TIA V15.1 sul Dell rifiuta il progetto: "Le CPU S7-1200 con firmware V1.0 non vengono piu' supportate". Riguarda PLC_1 e PLC_2.
- Passaggio intermedio in TIA V13 SP2 sul PC Davide, su nuova copia `C:\LAVORO_ESO\controllo_plastica_2016_V13_SP1_cambio_CPU` (Salva con nome dalla conversione del 09/11, che resta intatta).
- Sostituisci dispositivo: PLC_2 e PLC_1 da 6ES7214-1BE30-0XB0 V1.0 a 6ES7214-1BG31-0XB0 V3.0 (unica alternativa nel catalogo V13 insieme alla 1BE30). Compatibilita': solo creazione dei generatori di impulsi PTO/PWM aggiuntivi. TIA ha riaperto Comando_inv per modifica della libreria.
- ATTENZIONE: PLC_1 e' stato cambiato solo per poter aprire il progetto in V15.1. Questo progetto NON va caricato su PLC_1 (l'altro quadro funziona con la CPU originale).
- Copia sul NAS: `conversione/controllo_plastica_2016_V13_SP1_cambio_CPU` (19 file, 13,96 MB). Copia locale sul Dell in `C:\LAVORO_ESO\`.
- Il Dell vede il NAS come `\\NAS\Condivisione` dopo che Marco ha inserito le credenziali.
- Desktop remoto da Mac: la digitazione diretta arriva come "aaaa"; funziona incollare (appunti scritti mentre un'altra app e' in primo piano, poi Ctrl+V nel Dell).

## TIA V15.1 sul Dell (2026-11-10, pomeriggio)
- Progetto aggiornato da V15.1: `C:\LAVORO_ESO\controllo_plastica_2016_V13_SP1_cambio_CPU_V15.1` (la cartella V13 resta invariata).
- PLC_2: Sostituisci dispositivo da 1BG31 V3.0 a 6ES7214-1BG40-0XB0 V4.3 (massimo FW in V15.1). TIA: "accesso PUT/GET consentito per coerenza con S7-1200 V3.0"; non si torna a FW < V4. Progetto salvato.
- Compilazione PLC_2: 3 errori, cioe' "L'elemento della biblioteca USS_BASE utilizzato e' errato" e lo stesso per USS_DRV. Avvisi 3 (PID_Compact da verificare).
- FC1 Comando_inv (LAD): segmento 1 USS_PORT (PORT 16#000B, BAUD 19200, USS_DB "USS_DRV_DB" DB1, ERROR M2.0 "Erruss", STATUS MW6 "Stapot_1"); segmento 2 USS_DRV "Selezionatrice 1" con contatti su RUN/OFF2/OFF3/F_ACK/DIR e ~15 uscite; seguono altri segmenti per gli altri inverter (non ancora contati).
- Le nuove istruzioni sono in Istruzioni > Comunicazione > Processore di comunicazione > USS Communication: USS_Port_Scan, USS_Drive_Control, USS_Read_Param, USS_Write_Param. Stessi nomi di parametro delle vecchie, ma non si possono scambiare: il nome della box non e' modificabile e il trascinamento via Desktop remoto non funziona. Vanno inserite nuove box e ricollegati a mano tutti gli operandi.
- Da verificare: il PORT 16#000B era l'ID hardware del CM 1241 nella CPU vecchia; con FW V4 va preso l'ID hardware attuale della porta del CM (costanti di sistema).
- Desktop remoto: con Connections > Keyboard Mode > Unicode la digitazione funziona.

### Operandi USS in FC1 Comando_inv (letti in TIA V15.1, indirizzi assoluti)
FC1 ha 17 segmenti. USS solo nei segmenti 1, 2, 6, 10, 14; gli altri sono DIV/CONV/MUL per Hz e corrente e stato marcia indietro.

Segmento 1, USS_PORT -> USS_Port_Scan: PORT 16#000B, BAUD 19200, USS_DB DB1 "USS_DRV_DB", ERROR M2.0, STATUS MW6.

USS_DRV -> USS_Drive_Control, istanza DB1 "USS_DRV_DB" per tutti. RUN contatto NA, OFF2 e OFF3 contatto NC sullo stesso bit, F_ACK contatto NA M200.0, DIR contatto NA. CTRL3..CTRL8 = 16#0 in tutti.

| Parametro | Seg 2 Selezionatrice 1 | Seg 6 Nastro uscita 1 | Seg 10 Nastro metal detector | Seg 14 Vibro nastro rulli |
|---|---|---|---|---|
| RUN (NA) | M100.0 | M120.0 | M140.0 | M160.0 |
| OFF2 / OFF3 (NC) | M100.1 | M120.1 | M140.1 | M160.1 |
| F_ACK (NA) | M200.0 | M200.0 | M200.0 | M200.0 |
| DIR (NA) | M100.2 | M120.2 | M140.2 | M160.2 |
| DRIVE | 1 | 2 | 3 | 4 |
| PZD_LEN | 6 | 6 | 4 | 4 |
| SPEED_SP | DB5.DBD0 | DB5.DBD4 | DB5.DBD12 | DB5.DBD16 |
| NDR | M100.3 | M120.3 | M140.3 | M160.3 |
| ERROR | M100.4 | M120.4 | M140.4 | M160.4 |
| STATUS | MW106 | MW126 | MW146 | MW166 |
| RUN_EN | M100.7 | M120.7 | M140.7 | M160.7 |
| D_DIR | M114.0 | M114.1 | M114.2 | M114.3 |
| INHIBIT | M100.5 | M120.5 | M140.5 | M160.5 |
| FAULT | M100.6 | M120.6 | M140.6 | M160.6 |
| SPEED | MD108 | MD128 | MD148 | MD168 |
| STATUS1 | DB22.DBW0 | DB22.DBW16 | DB22.DBW32 | DB22.DBW48 |
| STATUS3 | DB22.DBW4 | DB22.DBW20 | DB22.DBW36 | DB22.DBW52 |
| STATUS4 | DB22.DBW6 | DB22.DBW22 | DB22.DBW38 | DB22.DBW54 |
| STATUS5 | DB22.DBW8 | DB22.DBW24 | DB22.DBW40 | DB22.DBW56 |
| STATUS6 | DB22.DBW10 | DB22.DBW26 | DB22.DBW42 | DB22.DBW58 |
| STATUS7 | DB22.DBW12 | DB22.DBW28 | DB22.DBW44 | DB22.DBW60 |
| STATUS8 | DB22.DBW14 | DB22.DBW30 | DB22.DBW46 | DB22.DBW62 |

### Sostituzione USS fatta (2026-11-10, TIA V15.1 sul Dell)
- Segmento 1: USS_Port_Scan, istanza DB4 "USS_Port_Scan_DB". PORT = "Local~RS485_1" (ID hardware 269: il vecchio 16#000B non vale piu' con la CPU V4), BAUD 19200, USS_DB = "USS_Drive_Control_DB".USS_DB, ERROR M2.0, STATUS MW6.
- Segmenti 2, 6, 10, 14: USS_Drive_Control, una sola istanza DB6 "USS_Drive_Control_DB" per tutti e 4 (come nel vecchio con DB1). Operandi identici alla tabella sopra, contatti NC su OFF2/OFF3 ricreati, CTRL3..8 = 16#0. Vecchie USS_PORT/USS_DRV e segmenti vecchi eliminati.
- Metodo: segmento 2 rifatto a mano, poi copiato e incollato e rinominato con Trova/Sostituisci limitato al segmento (inv1 -> inv2/inv3/inv4: i simboli hanno il numero dell'inverter e puntano agli indirizzi giusti). DRIVE e PZD_LEN corretti a mano. Ogni segmento ricontrollato a vista contro la tabella.
- Compilazione FC1: 0 errori, 0 avvisi. Hardware PLC_2 (completa): 0 errori, 2 avvisi normali (nessun livello di protezione; I32.0 della SB usato come HSC).
- Verificato in proprieta' CPU: IP 192.168.0.4 / 255.255.255.0, PN/IE_3, nessun router; PUT/GET attivo.
- Software PLC_2 (completa): 1 errore, oggetto tecnologico "Livello_nastro" [DB44] PID_Compact V1.0 non presente in biblioteca. Riferimenti incrociati: nessun punto di utilizzo, e non c'e' nessun OB a interrupt ciclico; il PID non e' richiamato dal programma. Decisione su cosa farne in sospeso (Marco).
- Da verificare in campo: ID hardware 269 e funzionamento USS su inverter reali; il touch WinCC flexible potrebbe leggere DB44 (da controllare prima di toccarlo).

Istanza DB1 del segmento 6 non letta (fuori schermo), probabile DB1 come gli altri. Nota: PZD_LEN 6 sui primi due, 4 sugli altri due (coerente con MM440 + G120?, da verificare).

## Touch
- Il quadro PLC non ha un touch proprio. Il touch e' un progetto WinCC flexible separato (`touch/Smistamento plastia new.Pannello operatore_1`, ultima compilazione 26/08/2016), collegato via Ethernet.
- IP presenti nel progetto: 192.168.0.2, 192.168.0.3, 192.168.0.4 (quale sia la CPU da verificare in TIA).
- Ipotesi Marco: il touch del quadro generale potrebbe essere stato modificato per gestire anche questo PLC. Da chiarire con Simone chi e quando, e se e' cambiato anche il programma PLC.
- Con la CPU nuova (FW V4): stesso IP, attivare "Consenti accesso PUT/GET" nelle proprieta' CPU, altrimenti il touch WinCC flexible non comunica.

## Da fare
1. Prova CPU a carichi scollegati (solo L1/N, staccati SB, CM, morsettiere, 24V sensori).
2. Confermare con Simone che non ci sono modifiche al programma dopo il 2019.
3. Ordinare CPU 6ES7214-1BG40-0XB0.
4. Aprire `controllo_plastica_V13_SP1` con TIA Portal recente (Win10/11), cambio dispositivo CPU, compilare, caricare. Da verificare se serve un passaggio di versione intermedio.
5. Prova in campo: comunicazione inverter via CM 1241 e collegamento HMI.
