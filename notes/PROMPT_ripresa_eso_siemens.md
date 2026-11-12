Riprendiamo il lavoro sul quadro Siemens di ESO Recycling (Quadro 2 Linea B, ex Pianezze, PLC_2 nel progetto TIA "controllo_plastica").

Prima leggi, nel progetto `plc-twincat`, branch `claude/eso-siemens-s7-upgrade-f90c6a` (non unito a main, niente merge senza il mio ok):
- `notes/2026-11-09_eso-quadro-siemens-s7-1200.md`: storia completa. Le sezioni che contano sono quelle dal 2026-11-11 in poi (revisione critica, confronto V13/V15.1, DB49, PID eliminato, rischio CM 1241, chiamata Picchio, CPU al banco in STOP).

## Stato al 2026-11-12 sera

### La diagnosi e' cambiata
- La CPU vecchia (6ES7214-1BE30-0XB0 FW V1.0) al banco, da sola, senza signal board e senza morsettiere: RUN/STOP giallo FISSO, ERROR e MAINT lampeggianti. Non si riavvia: e' viva e in STOP.
- PERCHE' sia in STOP non e' dimostrato. "Mancano i moduli" non basta: nel progetto c'e' "avvio della CPU anche in caso di divergenza" e avviamento "modo prima di RETE OFF" (se era in STOP o in errore prima dello spegnimento, riparte in STOP). ERROR + MAINT lampeggianti nel manuale potrebbero indicare configurazione incompatibile o un problema di memory card (ricordo, non verificato su fonte Siemens). Decide il buffer di diagnostica.
- Memory card: non si sa se nella CPU vecchia c'e'. Va guardato prima di tutto (sportellino superiore, a tensione tolta).
- Nel quadro invece faceva "tutti i LED accesi, tutti spenti" in ciclo (riavvio). Quindi il guasto e' probabilmente FUORI dalla CPU: corto nel cablaggio, signal board SB 1221, CM 1241 o un modulo di espansione. E' anche l'ipotesi di Picchio.
- La CPU vecchia potrebbe essere riutilizzabile. Non ordinare/montare nulla prima delle prove sotto.

### Picchio (ing. Marco Tittarelli, marco.tittarelli@picchiosrl.com)
- Mail del 12/11 ore 16:00 (conversazione "ESO Recycling - Quadro 2 Linea B...", account Gmail marco.bmcr): allegato `Controllo_plastica_V13_SP2_.zap13` (archivio TIA V13 SP2, circa 6,9 MB), convertito per CPU 1214C AC/DC/RLY 6ES7214-1BG31-0XB0 (FW V3.0). Scrive "per la CPU che ti mando": sta spedendo una CPU 1BG31 fisica.
- In chiamata ha detto di aver fatto i nostri stessi passaggi (Sostituisci dispositivo, PID che non compila). Al suo banco la CPU non andava in RUN perche' non ha la signal board (HSC1 usa I32.0 che sta sulla SB).
- Allegato scaricato (5,0 MB) e copiato sul NAS in `conversione/picchio_2026-11-12/Controllo_plastica_V13_SP2_.zap13` (SHA-256 uguale all'originale, d0e9f3c6...). Una copia resta in `~/Downloads` sul Mac. NON ancora aperto in TIA.
- Indicazione dal contenuto del file (conteggio di stringhe, non definitivo): Picchio ha tenuto le USS legacy (USS_PORT/USS_DRV, nessuna USS_Port_Scan/USS_Drive_Control) e "Livello_nastro" non compare piu' (PID probabilmente eliminato). Se confermato, la sua strada evita il rischio CM 1241. NON so se a lui compila a 0 errori: nella nostra V13 le USS legacy davano 2 errori.
- Da aprire sul PC di Davide (TIA V13 SP2 Upd2), Progetto > Disarchivia, in una cartella nuova in `C:\LAVORO_ESO\`.

### Il nostro progetto V15.1 (strada alternativa, CPU 1BG40 FW V4.3)
- Sul Dell: `C:\LAVORO_ESO\controllo_plastica_2016_V13_SP1_cambio_CPU_V15.1`, salvato e chiuso. PLC_2 compila: software 0 errori 0 avvisi, hardware 0 errori 2 avvisi noti. PID DB44 eliminato (decisione mia).
- Copie NAS in `\\NAS\Condivisione\Interscambio\X MARCO\eso siemens da pc davide\conversione\`: `controllo_plastica_2016_V15.1_senza_PID_2026-11-12` (52 file, attuale) e `controllo_plastica_2016_V13_SP1_cambio_CPU_V15.1` (47 file, con PID, punto di ritorno). Sul Mac il NAS e' `/Volumes/Condivisione`.
- FC1 confrontato a video con la V13 originale: 17 segmenti identici operando per operando. Impostazioni CPU, ingressi e HSC1 uguali.
- Mai caricato su una CPU, nemmeno in PLCSIM.
- RISCHIO APERTO: in campo c'e' il CM 1241 RS485 vecchio (6ES7241-1CH30-0XB0). Nota Siemens: per le istruzioni USS nuove (USS_Port_Scan / USS_Drive_Control, usate nel nostro V15.1) il CM deve avere firmware V2.1.0. Non verificato il firmware reale del CM ne' se TIA V15.1 offre le USS legacy per CPU V4.
- Se si usa la CPU 1BG31 di Picchio con il suo progetto V13 SP2, questo progetto V15.1 diventa la riserva.

### Altri punti aperti
- Programma di partenza: e' la versione del 05/09/2016, la piu' probabile ma mai confrontata con la CPU reale. Ora che la CPU vecchia risulta viva si puo' confrontare online.
- Touch MP277 (WinCC flexible, driver S7 300/400): con CPU V3 o V4 serve PUT/GET attivo. Tag su DB5 e DB22; DB49.DBD18 probabilmente di PLC_1 (deduzione).
- PZD_LEN 4 sugli inverter 3 e 4 contro P2012=6 nel file parametri: era cosi' nell'originale, da leggere sugli inverter.
- Licenza STEP 7 V15 sul Dell: in Automation License Manager senza chiave (probabile prova a tempo), scadenza non nota.
- PLC_1 (altro quadro, funzionante): nei progetti convertiti e' stato cambiato a 1BG31 solo per poterli aprire. MAI caricare su PLC_1.
- Bozza Gmail a sw@picchiosrl.com con "abbiamo il progetto V15.1": NON inviarla, superata dalla chiamata.
- Indirizzi di USCITA della V13 mai confrontati con la V15.1 (gli ingressi si').
- Il Dell ha solo TIA V15/V15.1: non va online con la CPU vecchia FW V1.0. Se in campo torna la CPU vecchia serve TIA V13 (oggi solo sul PC di Davide).
- TeamViewer sul Dell si blocca all'avvio: per l'assistenza da remoto in ESO va sistemato prima (o installato un altro strumento concordato con Picchio).

## Prossimi passi, in ordine
Le istruzioni operative per Marco e Simone (banco, online, quadro, assistenza remota) sono in `notes/2026-11-12_scheda_prove_banco_eso.md`.
1. Memory card: guardare se c'e' nella CPU vecchia (tensione tolta), foto, non toglierla.
2. CPU vecchia al banco via Ethernet al PC di Davide. Non cambiare l'IP principale del PC (192.168.1.17, serve a TeamViewer): aggiungere un secondo IP 192.168.0.x, o usare un adattatore USB-Ethernet se il PC e' in DHCP. In TIA V13 aprire una COPIA del progetto con CPU originale 1BE30 V1.0 (`controllo_plastica_2016_V12_SP1_Update_4_V13_SP1`), non quella cambiata a 1BG31 ne' quella di Picchio. Accessi online, buffer di diagnostica, confronto online/offline. Sola lettura: non scaricare nulla nella CPU.
3. Al banco, a tensione tolta ogni volta, rimontare un pezzo alla volta (SB 1221, CM 1241, moduli) e vedere quale fa tornare il riavvio. Con il CM montato leggere online il suo firmware (chiude il rischio USS). Poi nel quadro: misura del 24 V sensori a vuoto e morsettiere estraibili una alla volta.
4. Disarchiviare il progetto di Picchio sul PC di Davide (cartella nuova) e confrontarlo con il nostro: CPU, FC1 (USS vecchie o nuove), PID, compilazione. Dirmi le differenze prima di usare l'uno o l'altro.
5. Decidere con me quale CPU e quale progetto vanno nel quadro (CPU vecchia se sana, 1BG31 di Picchio, o 1BG40 con il nostro V15.1) e chiarire con Picchio il punto CM 1241 / USS.
6. Caricamento solo su PLC_2, con linea in sicurezza (Auto_start puo' avviare i nastri), poi prova USS sui 4 azionamenti e prova touch.

## Controllo remoto dal Mac
- Dell Win10 "Bmcr" (TIA V15.1): Windows App, connessione "192.168.1.9", utente `.\Bmcr`. Keyboard Mode Unicode.
- PC Davide (192.168.1.17, Win7, TIA V12 e V13 SP2): TeamViewer, "DAVIDE-PC", password salvata nell'elenco Dispositivi. NON chiudere il riquadro blu TeamViewer sul desktop remoto: termina la sessione.
- Serve il controllo schermo completo (lo approvo io, restare davanti al Mac: la richiesta scade). Se i clic vengono rifiutati con "Could not verify which document this window is editing": chiudere e riaprire l'app Claude.
- In TIA: riferimenti incrociati dal menu tasto destro (F11 sul Mac apre la scrivania). Non usare la rotella sopra i campi delle proprieta'. La stampa PDF di tutto il PLC non finisce: leggere a video (zoom 50%, PagGiu).
- Copie verso il NAS: `robocopy "origine" "destinazione" /E /R:1 /W:1 /NFL /NDL` dal Prompt dei comandi, poi ricontare i file dal Mac.

Regole: lavora solo su copie, non toccare gli originali di Davide, non inventare indirizzi, dimmi cosa vuoi cambiare prima di cambiarlo, registra tutto nella nota e fai commit e push sul branch.
