Riprendiamo il lavoro sul quadro Siemens guasto di ESO Recycling (Quadro 2 Linea B, ex Pianezze).

Prima di tutto leggi, nel progetto `plc-twincat` su main:
- `CONTEXT.md`, sezione "Lavori collegati fuori TwinCAT"
- `notes/2026-11-09_eso-quadro-siemens-s7-1200.md`: hardware, percorsi, cosa è stato fatto e i prossimi passi

In breve:
- La CPU guasta è una S7-1200 1214C AC/DC/RLY 6ES7214-1BE30-0XB0 FW V1.0 (PLC_2 nel progetto TIA "controllo_plastica").
- La versione giusta è quella del 05/09/2016. È già convertita in V13 SP1 e copiata su NAS: `Interscambio/X MARCO/eso siemens da pc davide/conversione/controllo_plastica_2016_V13_SP1`.
- In V13 restano 2 errori, USS_BASE e USS_DRV (vecchia libreria USS legata al FW V1.0), più l'avviso PID_Compact obsoleto.

Obiettivo di oggi, sul PC aziendale Windows 10 (16 GB) che ti collego via TeamViewer:
1. Installare TIA Portal recente in prova (sito Siemens: l'accesso lo faccio io).
2. Aprire e aggiornare il progetto V13 SP1 dal NAS.
3. Sostituire la CPU di PLC_2 con la 6ES7214-1BG40-0XB0 (FW V4).
4. Sistemare le istruzioni USS (probabile passaggio a USS_Port_Scan / USS_Drive_Control) e il PID_Compact, senza cambiare la logica.
5. Attivare PUT/GET, tenere l'IP 192.168.0.4, compilare a 0 errori, salvare una copia sul NAS.

Regole: lavora solo su copie, non toccare gli originali di Davide, registra tutto nella nota e fai commit e push.
