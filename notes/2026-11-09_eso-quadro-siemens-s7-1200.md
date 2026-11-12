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

## Punti dubbi da verificare (lavoro del 2026-11-10)
1. Impostazioni CPU dopo i due cambi dispositivo (V1.0 -> V3.0 -> V4.3) non ricontrollate: avviamento dopo rete ON, merker di clock e di sistema, tempo di ciclo, HSC e generatori di impulsi. Confrontarle con il progetto V13 originale.
2. Touch WinCC flexible con CPU FW V4: da verificare che la versione di WinCC flexible usata supporti la S7-1200 V4 e che i DB letti dal touch siano ad accesso standard (non ottimizzato).
3. USS_Port_Scan viene richiamata da OB1 (FC1), come la vecchia USS_PORT. Siemens consiglia un OB ciclico a tempo fisso: se il ciclo e' lungo la comunicazione puo' dare errori. Invariato rispetto all'originale, ma da tenere d'occhio.
4. Istanza unica DB6 per i 4 USS_Drive_Control e PORT = ID 269: corretto secondo la libreria, da confermare in campo con gli inverter.
5. Vecchio DB1 "USS_DRV_DB": non controllato se e' rimasto nel progetto e se il touch lo legge.
6. Firmware: progetto V4.3, CPU nuova probabilmente V4.6 o piu': il caricamento dovrebbe funzionare, da verificare.
7. Diagnosi CPU non conclusiva: la prova al banco va ripetuta senza SB 1221 e senza memory card (dalla foto la SB era ancora montata). Se il guasto fosse nella SB, la CPU nuova con la SB vecchia farebbe lo stesso. Prima di ordinare: asciugatura 24-48 h in ambiente caldo e nuova prova.
8. Memory card: se nella CPU vecchia c'e' una card, puo' contenere il programma realmente caricato. Va letta prima di dare per buona la versione 2016.
9. Moduli in campo diversi dal progetto: in campo SM 1223 6ES7223-1PL32 e 6ES7223-1BH32, nel progetto 1PL30 e 1BH30. La CPU V1.0 li accettava; la V4 potrebbe segnalarli come diversi. Valutare di allineare la configurazione ai codici reali.
10. Segmenti USS vecchi 7, 11 e 15 eliminati senza scorrerli fino in fondo: se contenevano altro oltre a USS_DRV, e' andato perso. Verifica: stampare in PDF FC1 dalla V13 (PC Davide) e dalla V15.1 e confrontarli segmento per segmento.
11. Comunicazione PLC_1 <-> PLC_2 sulla rete PN/IE_3 non verificata (Vista di rete > Collegamenti e programma di PLC_1).
12. Azionamenti a sinistra (51A01, 75A01) forse G120 sostituiti dopo il 2016: se il programma non era stato adattato, USS puo' non funzionare a prescindere dal lavoro fatto.
13. In campo: collegare il Dell via cavo con IP 192.168.0.x (oggi e' su 192.168.1.x in Wi-Fi), caricare solo PLC_2 e mettere in RUN solo con la linea in sicurezza (Auto_start potrebbe avviare i nastri).
14. Prima di montare la CPU nuova asciugare e ispezionare il quadro (morsetti, 24 V sensori), altrimenti si rischia di danneggiare anche quella.
15. Licenza TIA V15.1 sul Dell non controllata.

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

## Revisione critica (2026-11-11, nuova sessione, solo lettura)
Nessuna modifica al progetto TIA. Fatta la copia di sicurezza e le verifiche possibili senza il PC di Davide.

### Copia di sicurezza
- Progetto chiuso in TIA (era gia' salvato) e copiato con robocopy in `conversione/controllo_plastica_2016_V13_SP1_cambio_CPU_V15.1` sul NAS: 47 file, 16 cartelle, 5,93 MB, 0 non riusciti. Conteggio ricontrollato dal Mac. Progetto poi riaperto.

### Verificato in TIA V15.1 (PLC_2)
- FC1 Comando_inv: 17 segmenti. USS nei segmenti 1, 2, 6, 10, 14; operandi dei 4 USS_Drive_Control letti a video e uguali alla tabella sopra (DRIVE 1-4, PZD_LEN 6/6/4/4, istanza unica DB6, OFF2/OFF3 con contatto NC). Segmento 1 come descritto (DB4, PORT 269, 19200, USS_DB di DB6).
- Punto dubbio 10 ridimensionato: i segmenti 7, 11, 15 attuali sono "Velocita' in Hz" (DIV) e la struttura e' completa: per ogni inverter USS + Hz + corrente + marcia indietro (5 + 12 = 17). Non manca nessun segmento. Resta da fare il confronto operando per operando con la V13.
- Punto dubbio 5 risolto: il vecchio DB1 "USS_DRV_DB" non e' piu' nel progetto. DB presenti: DB5 Velinrit, DB22 Outinv, DB4 e DB6 (USS), DB2 t1, DB3 C1, DB20/21/23/24/49 IEC_Timer_0/1/2/3/5, piu' i timer T_lav*, T_pausa*, t_start, Tfotsel1, Trot2 (numeri non letti), DB44 Livello_nastro. Cartelle `blocchidb` e `Contatori` vuote.
- Impostazioni CPU lette: avviamento a caldo "modo di funzionamento prima di RETE OFF"; "avvio della CPU anche in caso di divergenza"; tempo di parametrizzazione 60000 ms; controllo ciclo 150 ms, nessun ciclo minimo; merker di clock attivo su MB0, merker di sistema non attivo; accesso completo senza protezione; PUT/GET attivo.
- HSC1 attivo: frequenza, monofase, periodo 1,0 s, ingresso clock I32.0 (signal board), indirizzo ID1000. HSC2 non attivo. HSC3-6 e generatori di impulsi non aperti.
- Indirizzi I/O: CPU IB0-1 / QB0-1, AI CPU IW64-67, SB IB32, posto 2 (DI16/DO16) IB4-5 / QB2-3, posto 3 (AI4) IW112-119, posto 4 (DI8/DO8) IB6 / QB4.
- Rete: PLC_1 e PLC_2 sulla stessa sottorete PN/IE_3. In PLC_2 non ci sono blocchi di comunicazione verso altri PLC (solo Port_Config, Send/Receive_P2P, Send/Receive_Config per USS): PLC_2 non apre collegamenti verso PLC_1. Tabella collegamenti e programma di PLC_1 non guardati.

### Verificato dal Mac sui file del NAS
- Touch (`touch/Smistamento plastia new.hmi`, 2016): pannello MP277 10", driver "SIMATIC S7 300/400". Indirizzi usati: M, I, Q, DB5 (44 tag), DB22.DBW100 e DBW102, DB49.DBD18 (tipo Time), DB1.DBW0 (3 tag). Nessun tag su DB44.
  - DB1.DBW0 e' l'indirizzo predefinito dei tag nuovi in WinCC flexible: probabilmente 3 tag mai configurati (interpretazione, da confermare aprendo il progetto touch).
  - DB49 = IEC_Timer_5: il touch legge o scrive un tempo dentro il DB di un temporizzatore.
- `Parametrizzazione inverter/Parametri inverter M440 USS.txt` (2012): P2010=7 (19200 baud, coerente con BAUD), P2012=6 (PZD, coerente con PZD_LEN 6 degli inverter 1 e 2), P2013=4, P700=5, P1000=5, P2000=50.

### Cosa non convince o resta aperto
1. Licenza: in Automation License Manager "STEP 7 Basic" e "STEP 7 Professional" V15 hanno l'icona di licenza mancante (hanno la chiave solo WinCC Advanced combo e PID Professional). TIA quindi sta girando probabilmente in prova a tempo. Da confermare e da sapere la scadenza prima del caricamento in campo.
2. DB49.DBD18 dal touch: con la CPU V4 la struttura interna dei DB dei temporizzatori IEC potrebbe non avere piu' lo stesso dato allo stesso offset. Da controllare in TIA (offset di DB49 in V15.1 contro V13) e nel progetto touch quale tag e'.
3. Confronto con la V13 non fatto: FC1 operando per operando, impostazioni CPU (avviamento, merker), indirizzi I/O e HSC. Serve il PC di Davide.
4. Inverter 3 e 4 hanno PZD_LEN 4 mentre il file parametri dice P2012=6: se P2012 sull'inverter non e' 4, quel drive va in errore USS. Era cosi' anche nell'originale, da leggere sugli inverter.
5. Costante del segmento 9 (corrente nastro uscita 1) sembra diversa da quella dei segmenti 4, 12, 16 (0,00096125). Letta al 50% di zoom, non certa. Da confrontare con la V13.
6. PLC_1 resta 1BG31 V3.0 nel progetto: vale l'avviso gia' scritto, mai caricare su PLC_1.

### Note pratiche
- La stampa in PDF da TIA V15.1 di tutto PLC_2 o di tutti i blocchi non finisce in tempi utili (annullata dopo 15 minuti, file a 0 byte). Per il confronto conviene leggere a video (zoom editor 50%, tasto PagGiu) o stampare un blocco alla volta.
- In TIA la rotella sopra un campo a tendina delle proprieta' lo mette a fuoco: non scorrere con la rotella nelle pagine delle proprieta', usare le voci dell'albero.
- Windows App ha due connessioni salvate: "pc dell win10" e "davide pc" (senza credenziali salvate).

### Aggiornamento 2026-11-11 pomeriggio
- Punto 5 chiuso: nel file del progetto V13 sul NAS (blocchi interni decompressi dal Mac) esistono sia la costante 0,00096125 sia 0,00045. La costante diversa del segmento 9 e' quindi dell'originale, non un errore della conversione.
- Confronto V13 a video non fatto: il PC di Davide e' collegato via TeamViewer (non Windows App), ma lo strumento di controllo del Mac ha rifiutato tutti i clic ("Could not verify which document this window is editing") su Windows App e TeamViewer, anche dopo aver rilasciato e ripreso il controllo. L'immagine TeamViewer sembrava ferma (orologio remoto fisso alle 13:53).
- Leggere FC1 dal file V13 senza TIA non e' pratico: i segmenti sono salvati con riferimenti numerici agli operandi, non con gli indirizzi.

### Confronto V13 originale contro V15.1 (2026-11-11, ore 14:30, a video sui due PC)
V13 = `C:\LAVORO_ESO\controllo_plastica_2016_V12_SP1_Update_4_V13_SP1` sul PC Davide (CPU 1BE30 V1.0), aperto in TIA V13 senza salvare. Nessuna modifica su nessuno dei due PC.

- FC1 Comando_inv: letti tutti i 17 segmenti della V13 con indirizzi assoluti. Coincidono con la V15.1 operando per operando: i 4 USS_DRV (RUN, OFF2/OFF3 NC, F_ACK M200.0, DIR, DRIVE 1-4, PZD_LEN 6/6/4/4, SPEED_SP, tutte le uscite, STATUS1 e 3-8 su DB22, CTRL3-8 a 0), i DIV per -2.0, i CONV+MUL, le marce indietro (M501.0, .1, .3, .4). Punti dubbi 3 e 10 chiusi: nessun errore di battitura, niente perso.
- Costante corrente: segmento 9 usa 0,00045 anche nella V13, gli altri 0,00096125. E' dell'originale.
- Impostazioni CPU V13 uguali alla V15.1: avviamento a caldo "modo di funzionamento prima di RETE OFF", controllo ciclo 150 ms senza ciclo minimo, merker di clock su MB0, merker di sistema non attivo, senza protezione.
- Indirizzi di ingresso V13 uguali: CPU IB0-1, AI IW64-67, SB IB32, HSC1-6 ID1000-1020, posto 2 IB4-5, posto 3 IW112-119, posto 4 IB6. HSC1: frequenza, monofase, ingresso signal board. Indirizzi di uscita V13 non letti (la tabella era ordinata con gli ingressi in cima).
- Blocchi V13 sotto "Risorse del programma": USS_PORT FC1070, USS_DRV FB1071, PID_Compact, C1 DB3, IEC_Timer_0/1/2/3/5 (DB20/21/23/24/49), t1 DB2, T_lav_Liv_ap/ch... Stessi DB della V15.1 (elenco completo non confrontato riga per riga).

#### Trovato: i DB dei temporizzatori IEC cambiano struttura con la CPU V4
- DB49 IEC_Timer_5 nella V13 (FW V1.0): ST, PT, ET, RU, IN, Q.
- DB49 nella V15.1 (FW V4.3): solo PT, ET, IN, Q. ST e RU non ci sono piu' e l'editor non mostra offset.
- Il progetto touch ha un tag di tipo Time su DB49.DBD18. Se quel tag e' del collegamento verso PLC_2, con la CPU nuova non legge/scrive piu' il dato giusto (o da' errore). Vale per ogni tag del touch che punta dentro un DB di temporizzatore.
- Non ancora chiarito: il progetto touch contiene tag di piu' PLC (192.168.0.2/.3/.4) e dall'estrazione non si vede a quale collegamento appartiene DB49.DBD18; non ho verificato se DB49 nella V15.1 sia ad accesso ottimizzato ne' dove il programma usa IEC_Timer_5. Da fare: riferimenti incrociati di DB49 in TIA e apertura del progetto touch in WinCC flexible.
- Possibile rimedio (da decidere, tocca programma e touch): passare il tempo da una variabile in un DB normale o in un merker e far puntare li' il tag del touch.

#### Note pratiche
- PC Davide: TeamViewer dal Mac. NON chiudere il riquadro blu TeamViewer sul desktop remoto: termina la sessione.
- Dell: Windows App, connessione "192.168.1.9" con utente `.\Bmcr`.

### DB49 e tag del touch (2026-11-11, ore 14:45, TIA V15.1 sul Dell, sola lettura)
- Riferimenti incrociati di DB49 IEC_Timer_5 in PLC_2: un solo utilizzo, Main OB1 segmento 1 "Chiamata manuali". E' un TOF con IN = I4.4 "q_selmanuale", PT = costante T#100MS, ET non collegato, uscita Q che abilita la chiamata di FC2 "Manuale". Nello stesso segmento I4.5 "q_selautomatico" chiama FC3 Auto_start e FC5 Autostop.
- Quindi in PLC_2 il tempo di DB49 e' una costante del programma: un tag del touch su DB49.DBD18 non avrebbe effetto su PLC_2. Il cambio di struttura dei DB temporizzatori con la CPU V4 non tocca questo punto.
- DB5 "Velinrit" di PLC_2 in V15.1: accesso standard con offset (0.0 Speedinv1 ... 46.0 T_controllo Time, 52.0 Set_serranda, 54.0 Set_serranda_liv, 56.0 PLC_min, 58.0 Plc_max Int, fine a 59). I tag del touch DB5.DBW52, DBW54 e DBD46 (Time) combaciano con questo DB. I tag DB5.DBD58 (Time) e DB5.DBD66 (Time) invece NON esistono in PLC_2 (58 e' un Int, 66 e' oltre la fine): appartengono al DB5 di un altro PLC.
- Conclusione (deduzione, non letta nel progetto touch): il touch contiene tag di piu' PLC, e DB49.DBD18, DB5.DBD58/66 e probabilmente DB22.DBW100/102 sono dell'altro quadro (PLC_1), che non viene toccato. Conferma definitiva solo aprendo il progetto touch in WinCC flexible, oppure guardando DB49 e DB5 di PLC_1 in TIA.
- Resta valido in generale: con la CPU V4 il touch puo' leggere solo M, I, Q e DB ad accesso standard. DB5 lo e'. DB22 "Outinv" non controllato.

### Sera 2026-11-11
- Decisione Marco: eliminare il PID "Livello_nastro" DB44. NON ancora fatto: la sessione Desktop remoto verso il Dell risulta "Session Disconnected" e il controllo dello schermo del Mac non e' stato approvato (3 richieste scadute).
- Dubbi residui su DB44 dichiarati a Marco: non verificato se PLC_1 lo legge via rete, se il touch montato e' quello del 2016, se il programma nella CPU guasta coincide col progetto. Eliminazione reversibile (copia NAS del mattino e originale V13).
- Bozza Gmail (marco.bmcr) in risposta alla mail del 10/11 a sw@picchiosrl.com, cc progettazione@bmcitaly.it: richiesta di aggiornamento sull'apertura del progetto. Da inviare a cura di Marco.
- Prossimi passi sul Dell: eliminare DB44, compilare PLC_2 (hardware e software, completa), salvare, chiudere, nuova copia sul NAS in cartella separata con data.

### PID DB44 eliminato, PLC_2 compila pulito (2026-11-12, ore 08:10, TIA V15.1 sul Dell)
- Riferimenti incrociati di "Livello_nastro" [DB44] ricontrollati prima di eliminare: nessun punto di utilizzo.
- Eliminato l'oggetto tecnologico "Livello_nastro" [DB44] (PID_Compact V1.0) su decisione di Marco. La cartella Oggetti tecnologici di PLC_2 ora e' vuota.
- Compilazione PLC_2, software (compilazione completa): 0 errori, 0 avvisi.
- Compilazione PLC_2, hardware (compilazione completa): 0 errori, 2 avvisi gia' noti (nessun livello di protezione; I32.0 della signal board usato per operazioni High-Speed).
- Progetto salvato e chiuso. Nuova copia sul NAS: `conversione/controllo_plastica_2016_V15.1_senza_PID_2026-11-12` (52 file, 16 cartelle, 6,31 MB, 0 non riusciti). La copia del 11/11 con il PID (`controllo_plastica_2016_V13_SP1_cambio_CPU_V15.1`, 47 file) resta invariata come punto di ritorno.
- PLC_1 non compilato e non toccato: resta 1BG31 V3.0 solo per poter aprire il progetto. Mai caricare su PLC_1.
- Sul Dell e' aperta anche una finestra "Sistema di informazione" (guida di TIA), si puo' chiudere.

### RISCHIO APERTO: CM 1241 vecchio e nuove istruzioni USS (2026-11-12)
- Nota Siemens "S7-1200 firmware update CM 1241 V2.1.0" (support.industry.siemens.com, attachments/108587537): i moduli CM 1241 devono avere firmware V2.1.0 per essere compatibili con le nuove istruzioni punto a punto, Modbus RTU e USS; senza quell'aggiornamento supportano solo le versioni legacy.
- In campo e nel progetto il modulo e' il CM 1241 RS485 6ES7241-1CH30-0XB0 (prima serie, 2011). La sostituzione fatta in FC1 usa le istruzioni NUOVE (USS_Port_Scan, USS_Drive_Control, che si appoggiano a Port_Config / Send_P2P / Receive_P2P).
- Quindi il progetto compila ma la comunicazione con gli inverter potrebbe non funzionare con il CM vecchio. NON verificato: firmware reale del CM in campo, se il 1CH30 e' aggiornabile a V2.1, se TIA V15.1 offre per la CPU V4.3 una versione legacy della libreria USS.
- Due strade possibili: (a) tenere il CM vecchio e usare la versione legacy delle istruzioni USS, se disponibile per CPU V4; (b) sostituire anche il CM con un CM 1241 RS422/485 6ES7241-1CH32-0XB0 con firmware >= V2.1 e tenere il programma attuale.
- Da fare in TIA sul Dell: leggere versione firmware del CM nel catalogo/proprieta', e in Istruzioni > Comunicazione > Processore di comunicazione vedere le versioni selezionabili della libreria USS.

### Chiamata con Picchio (2026-11-12)
- Picchio ha aperto il progetto in V13 SP2, poi ha rifatto gli stessi passaggi nostri (Sostituisci dispositivo a 1BG31 V3.0, versione superiore, PID che non compila) e sta provando a caricarlo su un PLC fisico suo. Esito non ancora noto.
- Sua ipotesi sul guasto, dal lampeggio dei LED: corto nel quadro, non per forza CPU guasta. Consiglia di staccare le morsettiere estraibili ("basette") una alla volta per trovare il ramo in corto. Coerente con l'ipotesi gia' scritta il 10/11 (alimentazione interna che cade per corto o umidita' sul 24 V sensori o sul bus moduli).
- Da chiedergli: quale CM 1241 ha usato nella prova e se ha tenuto le USS legacy o messo quelle nuove (vedi rischio CM 1241 sopra).
