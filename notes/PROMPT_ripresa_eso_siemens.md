Riprendiamo il lavoro sul quadro Siemens guasto di ESO Recycling (Quadro 2 Linea B, ex Pianezze).

Il lavoro fin qui l'ha fatto un'altra sessione, in una chat molto lunga e via Desktop remoto. Il tuo compito, in quest'ordine:
1. valutare criticamente il lavoro fatto e dirmi cosa ti convince e cosa no;
2. correggere gli errori che trovi (dopo avermi detto cosa vuoi cambiare);
3. andare avanti verso la CPU nuova pronta da caricare.

Prima di tutto leggi, nel progetto `plc-twincat`, branch `claude/eso-siemens-s7-upgrade-f90c6a` (non ancora unito a main, non fare merge senza il mio ok):
- `CONTEXT.md`, sezione "Lavori collegati fuori TwinCAT"
- `notes/2026-11-09_eso-quadro-siemens-s7-1200.md`: hardware, percorsi, storia completa, tabella operandi USS, sezione "Punti dubbi da verificare" (15 punti)

## Stato (sera 2026-11-10)
- CPU guasta: S7-1200 1214C AC/DC/RLY 6ES7214-1BE30-0XB0 FW V1.0 (PLC_2 nel progetto TIA "controllo_plastica", versione del 05/09/2016). Al banco si riavvia in loop (tutti i LED accesi e spenti insieme). Prova fatta con la SB 1221 ancora montata: diagnosi non conclusiva.
- Progetto in TIA Portal V15.1 sul portatile Dell Win10 "Bmcr" (Wi-Fi 192.168.1.9): `C:\LAVORO_ESO\controllo_plastica_2016_V13_SP1_cambio_CPU_V15.1`. Esiste SOLO li': copia sul NAS non ancora fatta.
- Percorso: V13 SP1 (PC Davide) -> cambio CPU intermedio a 1BG31 V3.0 su PLC_1 e PLC_2 (V15.1 non apre CPU FW V1.0) -> upgrade a V15.1 sul Dell -> PLC_2 sostituita con 6ES7214-1BG40-0XB0 FW V4.3.
- ATTENZIONE: PLC_1 (l'altro quadro, funzionante) e' stato cambiato a 1BG31 solo per aprire il progetto. Questo progetto NON va mai caricato su PLC_1.
- FC1 Comando_inv: USS_PORT/USS_DRV sostituite con USS_Port_Scan (DB4, PORT "Local~RS485_1" = ID 269, 19200 baud, USS_DB = "USS_Drive_Control_DB".USS_DB) e 4 USS_Drive_Control (istanza unica DB6). FC1 compila 0 errori.
- IP 192.168.0.4 / 255.255.255.0 su PN/IE_3 e PUT/GET attivo, letti nelle proprieta' CPU. Hardware PLC_2: 0 errori, 2 avvisi normali.
- Unico errore rimasto (software completo): PID_Compact V1.0 "Livello_nastro" [DB44], mai richiamato (nessun OB ciclico). Decisione mia in sospeso: proposta eliminarlo dopo aver verificato che il touch non legga DB44.

## Fase 1 - Prima di tutto
- Copia di sicurezza: salvare e chiudere il progetto in TIA, copiarlo sul NAS in `\\NAS\Condivisione\Interscambio\X MARCO\eso siemens da pc davide\conversione\`, verificare il numero di file.

## Fase 2 - Verifiche sul lavoro fatto (le piu' importanti)
- Confronto FC1 vecchio/nuovo: stampare in PDF FC1 dalla V13 (`C:\LAVORO_ESO\controllo_plastica_2016_V12_SP1_Update_4_V13_SP1` sul PC Davide, via TeamViewer) e dalla V15.1 sul Dell, poi confrontarli segmento per segmento. Serve a scoprire errori di battitura e cose perse: i segmenti USS vecchi 7, 11, 15 sono stati eliminati senza scorrerli fino in fondo.
- Impostazioni CPU di PLC_2 dopo i due cambi dispositivo (avviamento dopo rete ON, merker di clock e di sistema, tempo di ciclo, HSC, generatori di impulsi) confrontate con la V13.
- Moduli: in campo SM 1223 1PL32 e 1BH32, nel progetto 1PL30 e 1BH30. Valutare se allineare.
- Vecchio DB1 "USS_DRV_DB": ancora nel progetto? Il touch lo legge?
- Collegamenti PLC_1 <-> PLC_2 su PN/IE_3.
- Licenza TIA V15.1 sul Dell.

## Fase 3 - Andare avanti
- Decisione PID DB44 con me, poi compilazione completa PLC_2 a 0 errori, nuova copia sul NAS.
- Da fare in azienda/campo (preparare istruzioni chiare per me e Simone): prova al banco della CPU vecchia senza SB 1221 e senza memory card, asciugatura 24-48 h; lettura della memory card se presente; verifica touch WinCC flexible con CPU V4; caricamento solo su PLC_2 con il Dell via cavo in 192.168.0.x e linea in sicurezza (Auto_start puo' avviare i nastri); prova USS sui 4 azionamenti (2 forse G120 sostituiti dopo il 2016).

## Note pratiche sul controllo remoto (Mac -> Dell)
- Connessione: Windows App (Desktop remoto) verso 192.168.1.9, utente `.\Bmcr`. TeamViewer sul Dell si blocca all'avvio. Il PC di Davide (192.168.1.17) si raggiunge con TeamViewer.
- Serve il controllo schermo completo (lo approvo io); in background i clic non arrivano.
- Impostare Connections > Keyboard Mode > Unicode, altrimenti la digitazione arriva come "aaaa".
- Canc: usare il tasto "ForwardDelete". F11 sul Mac apre la scrivania: per i riferimenti incrociati usare il menu tasto destro.
- Trascinamenti e ridimensionamento pannelli funzionano solo lenti (mouse down, movimenti con pause, mouse up).
- Nell'editor LAD, dopo ogni Invio TIA passa al campo successivo e la vista scorre: ricontrollare con uno zoom dopo ogni gruppo di modifiche.
- Per copiare file dal Mac al Dell: incollare il testo con Ctrl+V nel Dell, oppure usare il NAS.

Regole: lavora solo su copie, non toccare gli originali di Davide, non inventare indirizzi, registra tutto nella nota e fai commit e push sul branch.
