Riprendiamo il lavoro sul quadro Siemens di ESO Recycling (Quadro 2 Linea B, ex Pianezze, PLC_2 nel progetto TIA "controllo_plastica").

Prima leggi, nel progetto `plc-twincat`, branch `claude/eso-siemens-s7-upgrade-f90c6a` (fare `git fetch` e usare origin: la copia locale puo' essere vecchia; non unito a main, niente merge senza il mio ok):
- `notes/2026-11-09_eso-quadro-siemens-s7-1200.md`: storia completa. Conta soprattutto dalla sezione "In campo con Simone (2026-11-16 pomeriggio)" in poi.
- `notes/2026-11-12_scheda_prove_banco_eso.md`: istruzioni per Simone (banco, quadro, assistenza remota).

## Stato al 2026-11-16 ore 18:07 (Simone in ESO col Dell collegato al quadro)

### Cosa c'e' nel quadro
- Montata la CPU di Picchio: 1214C AC/DC/RLY 6ES7214-1BG31-0XB0, FW V3.0.2, IP 192.168.0.4, MAC 00-1C-06-1A-3F-38. In RUN.
- Programma = progetto di Picchio `Controllo_plastica_V13_SP2_.zap13` (USS legacy, PID eliminato). Confronto offline/online: uguale.
- Picchio (ing. Tittarelli, collegato al Dell con Supremo) ha fatto 2 caricamenti: 17:54 (STOP/avviamento da PC) e 18:00 (solo software, "Arresta tutto", poi "Avvia tutto", 0 errori). Non so cosa abbia cambiato: da chiedergli.
- CPU: "OK, errori nella componente subordinata"; moduli in TIA con stato "?"/"Sconosciuto"; all'avvio 2 eventi "componente hardware rimosso o errato" (HW_ID 15). Pero' il modulo SM 1223 DC/RLY al posto 2 ha DIAG verde e i suoi LED corrispondono ai valori online: funziona.

### Diagnosi a oggi
- Uscite: il programma comanda QB2=16#27 (Q2.0, 2.1, 2.2, 2.5) e QB3=16#47 (Q3.0, 3.1, 3.2, 3.6); Simone conferma i LED accesi uguali. 110 V presente sul comune 1L.
- Ingressi: IB4=16#1F (I4.4 selettore manuale = 1), IB5=16#82, IB6=16#06.
- PUNTO CHIAVE: I5.0 "q_Emer" = 0 (Main OB1 segmento 2). Con emergenza a 0 restano spente le abilitazioni inverter Q0.0, Q0.6, Q0.5, Q1.1 e viene resettata Q3.3 "ok_sucessivi" (consenso verso quadro vecchio). Da verificare con Simone: pulsanti di emergenza e riarmi, LED DI b .0 del modulo posto 2 deve accendersi.
- Lamentela iniziale di Simone: dal pannello i comandi manuali non attivano i teleruttori. Non ancora chiaro quali teleruttori non attaccano (attesi eccitati con le uscite attive: 212KM01, 212KM02, 212KM03, 212KM06, 213KM01, 213KM02, 213KM03).
- Pannello MP277: messaggio "chiave di licenza non disponibile Sm@rtService" (opzione pannello, non blocca). Il pannello e' sull'altra rete: con il Dell al posto del cavo grigio (va all'altro quadro) il pannello potrebbe non parlare col PLC_2.

### Schema elettrico (`Quadro Gestione impianto/Schema elettrico/Quadro_2.pdf`, NAS)
- Foglio 202 (pag. PDF 23): uscite CPU Q0.x/Q1.x -> 202KM01..11. Foglio 212 (pag. 27): DQ a modulo posto 2, comuni 1L (Q2.0-2.3) e 2L (Q2.4-2.7) su 110L-01, fili A2.x -> bobine 212KM01..08, ritorno 110N-00. Foglio 213 (pag. 28): DQ b, comuni 3L/4L, Q3.0-3.2 -> 213KM01..03, Q3.3 consenso vaglio verso quadro vecchio, Q3.6/3.7 non collegate. Origine di 110L-01 non trovata.

### Il Dell (portatile per il campo)
- TIA V15.1 + STEP 7 Basic V13 SP2 Upd4 (trial, installato oggi). Per la CPU di Picchio usare la V13: progetto disarchiviato in `C:\LAVORO_ESO\Controllo_plastica_V13_SP2_20261113`, interfaccia PN/IE Intel I219-LM "direttamente nel posto connettore 1 X1". TIA aggiunge IP 192.168.0.241 alla scheda cablata (sparisce al riavvio, va riconfermato).
- Accesso remoto: TeamViewer funziona se aperto sul Dell stesso (ID 1 183 595 362, password la detta Simone, non digitarla tu). AnyDesk installato (ID 623 085 995), accettazione da provare.
- Copie sul Dell: setup V13 in `C:\LAVORO_ESO\setup_V13SP2_estratto`, progetto 2016 per CPU vecchia in `C:\LAVORO_ESO\controllo_plastica_2016_V13_SP1_per_CPU_vecchia`, backup registro `C:\LAVORO_ESO\session_manager_backup.reg`.

### Altre strade (riserva)
- CPU vecchia 1BE30 FW V1.0 (in azienda, viva, in STOP al banco, senza memory card): richiede TIA V13 (PC Davide o ora anche Dell).
- Nostro progetto V15.1 per CPU 1BG40 (NAS `conversione/controllo_plastica_2016_V15.1_senza_PID_2026-11-12`): usa USS nuove, rischio CM 1241 vecchio (serve FW V2.1).
- PLC_1 (altro quadro) nei progetti convertiti e' 1BG31 solo per aprirli: MAI caricare su PLC_1.

## Prossimi passi
1. Esito emergenza: se I5.0 torna a 1, verificare che gli inverter si abilitino e che i teleruttori attacchino.
2. Chiedere a Picchio cosa ha modificato e caricato alle 17:54 e 18:00; fare una copia (archivio) del progetto attuale sul Dell e sul NAS.
3. Se i teleruttori non attaccano con uscite e 110 V presenti: misure su uscita (filo A2.x) e bobina A1-A2 (vedi scheda).
4. Rimettere il cavo grigio e verificare comunicazione pannello / PLC_1.
5. Registrare tutto nella nota, commit e push sul branch.

## Regole
- Sul PLC solo lettura: niente caricamenti, forzature o RUN/STOP senza mio ok esplicito; se c'e' Picchio collegato, solo osservare (screenshot in background, nessun clic).
- Modifiche di sistema su Windows (IP, registro, impostazioni di sicurezza), password e licenze: le fa Marco.
- Lavora solo su copie, non toccare gli originali di Davide, non inventare indirizzi, registra tutto nella nota, commit e push sul branch `claude/eso-siemens-s7-upgrade-f90c6a`.

## Controllo remoto dal Mac
- Dell: oggi via TeamViewer (finestra "Gabriele (1)" sul Mac). In LAN anche Windows App "192.168.1.9" utente `.\Bmcr`, Keyboard Mode Unicode.
- PC Davide (192.168.1.17, Win7, TIA V12 e V13 SP2): TeamViewer "DAVIDE-PC". Non chiudere il riquadro blu TeamViewer remoto.
- Serve il controllo schermo completo (lo approvo io). Per solo osservare bastano gli screenshot in background (app_screenshot).
