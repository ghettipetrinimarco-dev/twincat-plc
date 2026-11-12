Riprendiamo il lavoro sul quadro Siemens di ESO Recycling (Quadro 2 Linea B, ex Pianezze, PLC_2 nel progetto TIA "controllo_plastica").

Prima leggi, nel progetto `plc-twincat`, branch `claude/eso-siemens-s7-upgrade-f90c6a` (non unito a main, niente merge senza il mio ok):
- `notes/2026-11-09_eso-quadro-siemens-s7-1200.md`: storia completa. Le sezioni che contano sono quelle dal 2026-11-11 in poi (revisione critica, confronto V13/V15.1, DB49, PID eliminato, rischio CM 1241, chiamata Picchio, CPU al banco in STOP).

## Stato al 2026-11-12 sera

### La diagnosi e' cambiata
- La CPU vecchia (6ES7214-1BE30-0XB0 FW V1.0) al banco, da sola, senza signal board e senza morsettiere: RUN/STOP giallo FISSO, ERROR e MAINT lampeggianti. Non si riavvia: e' viva, in STOP, con configurazione non corrispondente all'hardware (mancano i moduli). Lettura dei LED citata a memoria dal manuale, non riverificata su fonte Siemens.
- Nel quadro invece faceva "tutti i LED accesi, tutti spenti" in ciclo (riavvio). Quindi il guasto e' probabilmente FUORI dalla CPU: corto nel cablaggio, signal board SB 1221, CM 1241 o un modulo di espansione. E' anche l'ipotesi di Picchio.
- La CPU vecchia potrebbe essere riutilizzabile. Non ordinare/montare nulla prima delle prove sotto.

### Picchio (ing. Marco Tittarelli, marco.tittarelli@picchiosrl.com)
- Mail del 12/11 ore 16:00 (conversazione "ESO Recycling - Quadro 2 Linea B...", account Gmail marco.bmcr): allegato `Controllo_plastica_V13_SP2_.zap13` (archivio TIA V13 SP2, circa 6,9 MB), convertito per CPU 1214C AC/DC/RLY 6ES7214-1BG31-0XB0 (FW V3.0). Scrive "per la CPU che ti mando": sta spedendo una CPU 1BG31 fisica.
- In chiamata ha detto di aver fatto i nostri stessi passaggi (Sostituisci dispositivo, PID che non compila). Al suo banco la CPU non andava in RUN perche' non ha la signal board (HSC1 usa I32.0 che sta sulla SB).
- NON so ancora: cosa ha fatto del PID DB44, se ha tenuto le USS legacy (USS_PORT/USS_DRV) o messo quelle nuove, se a lui compila a 0 errori.
- L'allegato non e' ancora stato scaricato ne' aperto. Il PC di Davide ha TIA V13 SP2 Upd2: e' il posto giusto per aprirlo (Progetto > Disarchivia).

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

## Prossimi passi, in ordine
1. Collegare la CPU vecchia (cosi' com'e' al banco) via Ethernet al PC di Davide, scheda di rete in 192.168.0.x (CPU 192.168.0.4). Da TIA V13: Accessi online, buffer di diagnostica, confronto online/offline con il progetto del 2016 e, se possibile, caricamento del programma dalla CPU in un progetto nuovo. Sola lettura: non scaricare nulla nella CPU.
2. Al banco, a tensione tolta ogni volta, rimontare un pezzo alla volta (signal board, CM 1241, moduli) e vedere quale fa tornare il riavvio. Poi nel quadro: morsettiere estraibili una alla volta. Preparare istruzioni chiare per me e Simone.
3. Scaricare l'allegato di Picchio, metterlo sul NAS in una cartella sua, disarchiviarlo sul PC di Davide (su una copia, non toccare gli originali) e confrontarlo con il nostro: CPU, FC1 (USS vecchie o nuove), PID, compilazione. Dirmi le differenze prima di usare l'uno o l'altro.
4. Decidere con me quale CPU e quale progetto vanno nel quadro (CPU vecchia se sana, 1BG31 di Picchio, o 1BG40 con il nostro V15.1) e chiarire con Picchio il punto CM 1241 / USS.
5. Caricamento solo su PLC_2, con linea in sicurezza (Auto_start puo' avviare i nastri), poi prova USS sui 4 azionamenti e prova touch.

## Controllo remoto dal Mac
- Dell Win10 "Bmcr" (TIA V15.1): Windows App, connessione "192.168.1.9", utente `.\Bmcr`. Keyboard Mode Unicode.
- PC Davide (192.168.1.17, Win7, TIA V12 e V13 SP2): TeamViewer, "DAVIDE-PC", password salvata nell'elenco Dispositivi. NON chiudere il riquadro blu TeamViewer sul desktop remoto: termina la sessione.
- Serve il controllo schermo completo (lo approvo io, restare davanti al Mac: la richiesta scade). Se i clic vengono rifiutati con "Could not verify which document this window is editing": chiudere e riaprire l'app Claude.
- In TIA: riferimenti incrociati dal menu tasto destro (F11 sul Mac apre la scrivania). Non usare la rotella sopra i campi delle proprieta'. La stampa PDF di tutto il PLC non finisce: leggere a video (zoom 50%, PagGiu).
- Copie verso il NAS: `robocopy "origine" "destinazione" /E /R:1 /W:1 /NFL /NDL` dal Prompt dei comandi, poi ricontare i file dal Mac.

Regole: lavora solo su copie, non toccare gli originali di Davide, non inventare indirizzi, dimmi cosa vuoi cambiare prima di cambiarlo, registra tutto nella nota e fai commit e push sul branch.
