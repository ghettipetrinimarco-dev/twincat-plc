Riprendiamo il lavoro sul quadro Siemens guasto di ESO Recycling (Quadro 2 Linea B, ex Pianezze).

Prima di tutto leggi, nel progetto `plc-twincat`, branch `claude/eso-siemens-s7-upgrade-f90c6a` (non ancora unito a main):
- `CONTEXT.md`, sezione "Lavori collegati fuori TwinCAT"
- `notes/2026-11-09_eso-quadro-siemens-s7-1200.md`: hardware, percorsi, storia completa, tabella operandi USS e stato attuale

## Dove siamo (sera 2026-11-10)
- CPU guasta: S7-1200 1214C AC/DC/RLY 6ES7214-1BE30-0XB0 FW V1.0 (PLC_2 nel progetto TIA "controllo_plastica", versione del 05/09/2016). Al banco, da sola, si riavvia in loop (tutti i LED accesi e spenti insieme).
- Progetto aperto in TIA Portal V15.1 sul portatile Dell Win10 "Bmcr" (Wi-Fi 192.168.1.9): `C:\LAVORO_ESO\controllo_plastica_2016_V13_SP1_cambio_CPU_V15.1`.
- Percorso fatto: V13 SP1 (PC Davide) -> cambio CPU intermedio a 1BG31 V3.0 su PLC_1 e PLC_2 (V15.1 non apre CPU FW V1.0) -> upgrade a V15.1 sul Dell -> PLC_2 sostituita con 6ES7214-1BG40-0XB0 FW V4.3.
- ATTENZIONE: PLC_1 (l'altro quadro, funzionante) e' stato cambiato a 1BG31 solo per aprire il progetto. Questo progetto NON va mai caricato su PLC_1.
- FC1 Comando_inv: USS_PORT/USS_DRV sostituite con USS_Port_Scan (DB4, PORT "Local~RS485_1" = ID 269, 19200 baud) e 4 USS_Drive_Control (istanza unica DB6). Operandi identici agli originali. FC1 compila 0 errori.
- Verificati: IP 192.168.0.4 / 255.255.255.0 su PN/IE_3, PUT/GET attivo. Hardware PLC_2: 0 errori, 2 avvisi normali.
- Progetto salvato sul Dell. Copia finale sul NAS NON ancora fatta.

## Da fare
1. Decidere con Marco cosa fare del PID_Compact V1.0 "Livello_nastro" [DB44]: unico errore rimasto nella compilazione software completa. Non e' richiamato da nessuna parte (nessun OB ciclico). Proposta: eliminarlo, dopo aver controllato che il touch WinCC flexible non legga DB44.
2. Compilazione completa PLC_2 (hardware + software) a 0 errori.
3. Salvare/archiviare il progetto e copiarlo sul NAS in `Interscambio/X MARCO/eso siemens da pc davide/conversione/` (il Dell vede il NAS come `\\NAS\Condivisione`).
4. Aggiornare la nota, commit e push sul branch. Merge su main solo quando lo dice Marco.
5. In campo (dopo arrivo CPU nuova): caricare solo su PLC_2, verificare comunicazione USS con i 4 inverter e il touch.

## Note pratiche sul controllo remoto (Mac -> Dell)
- Connessione: Windows App (Desktop remoto) verso 192.168.1.9, utente `.\Bmcr`. TeamViewer sul Dell si blocca all'avvio.
- Serve il controllo schermo completo (lo approva Marco); in background i clic non arrivano.
- Impostare Connections > Keyboard Mode > Unicode, altrimenti la digitazione arriva come "aaaa".
- Canc: usare il tasto "ForwardDelete". F11 sul Mac apre la scrivania: per i riferimenti incrociati usare il menu tasto destro.
- I trascinamenti funzionano solo lenti (mouse down, movimenti con pause, mouse up).
- Nell'editor LAD, dopo ogni Invio TIA passa al campo successivo e la vista scorre: ricontrollare con uno zoom dopo ogni gruppo di modifiche.

Regole: lavora solo su copie, non toccare gli originali di Davide, non inventare indirizzi, registra tutto nella nota e fai commit e push.
