# ESO Quadro 2 Linea B - scheda prove CPU (per Marco e Simone)

Obiettivo: capire cosa fa riavviare la CPU nel quadro e leggere cosa c'e' dentro la CPU vecchia (6ES7214-1BE30-0XB0, IP previsto 192.168.0.4).
Regola d'oro: NON caricare niente nella CPU. Se TIA propone "Carica nel dispositivo", "Sincronizza" o simili: annulla.

Ogni prova: montare e smontare SEMPRE a tensione tolta (230 VAC). Foto prima di staccare. Per ogni prova annotare cosa e' montato, stato dei LED RUN/STOP, ERROR, MAINT (spento / fisso / lampeggiante, colore) e fare un video di 10 secondi.

## A. Prima di alimentare
1. Aprire lo sportellino in alto sulla CPU: c'e' una memory card? Fare foto. Non toglierla e non inserirne una.
2. Guardare CPU, signal board, CM 1241 e moduli: ossido, residui di schiuma, umidita' sui connettori. Se c'e' umido: asciugare 24-48 ore in ambiente caldo prima di alimentare.

## B. Lettura online (PC di Davide, TIA V13 SP2) - sola lettura
1. Cavo Ethernet dalla CPU allo stesso switch del PC di Davide (o direttamente al PC).
2. Rete del PC: NON cambiare l'indirizzo 192.168.1.17 (serve a TeamViewer).
   - Se il PC ha IP fisso: Proprieta' IPv4 > Avanzate > Aggiungi un secondo indirizzo 192.168.0.x, subnet 255.255.255.0. Scegliere un x non usato nel progetto (non .2, .3, .4) e verificare con un ping che non risponda nessuno.
   - Se il PC e' in DHCP: non toccare, chiamare Marco (si usa un adattatore USB-Ethernet).
3. In TIA V13 aprire una COPIA di `C:\LAVORO_ESO\controllo_plastica_2016_V12_SP1_Update_4_V13_SP1` (quella con la CPU originale 1BE30 V1.0). Non usare la copia "cambio_CPU" ne' il progetto di Picchio.
4. Online > Nodi accessibili: annotare IP, nome e firmware della CPU trovata.
5. Online e diagnostica della CPU > Buffer di diagnostica: foto o screenshot di tutte le voci, soprattutto le piu' recenti.
6. Confronto online/offline di PLC_2: screenshot dell'elenco blocchi (uguali / diversi).
7. Chiudere senza salvare.

## C. Al banco, un pezzo alla volta
Ordine: 1) signal board SB 1221, 2) CM 1241 RS485, 3) moduli uno alla volta: SM 1223 DI16/DQ16 a rele' (posto 2), SM 1231 AI4 (posto 3), SM 1223 DI8/DQ8 (posto 4).
- Dopo ogni pezzo: alimentare, aspettare 1 minuto, annotare i LED, video.
- Se torna il ciclo "tutti i LED accesi, poi tutti spenti": fermarsi. L'ultimo pezzo montato e' il sospetto. Toglierlo e continuare con gli altri per vedere se ce n'e' un secondo.
- LED DIAG rosso sui moduli senza 24 V esterno: al banco e' probabilmente normale, non e' il guasto che cerchiamo.
- Con il CM 1241 montato e il PC collegato: Online e diagnostica del CM > annotare la versione firmware.

## D. Nel quadro (solo se al banco va tutto bene con tutti i pezzi)
1. Quadro in sicurezza: potenza degli inverter e dei nastri sezionata. Con la CPU nel quadro, se va in RUN, Auto_start puo' avviare i nastri.
2. A CPU spenta, con il tester: resistenza tra 24P-00 e 24M-00 (24 V sensori) lato campo. Valore molto basso = corto: cercare il ramo prima di alimentare.
3. Togliere tutte le morsettiere estraibili, alimentare, poi rimetterle una alla volta (a tensione tolta) annotando i LED. Quella che fa tornare il riavvio indica il ramo in corto.

## E. Assistenza da remoto quando Simone e' in ESO
Si', Picchio o noi possiamo aiutarlo da remoto. Condizioni:
- Il portatile deve avere internet (Wi-Fi ESO o hotspot del telefono) e, insieme, il cavo Ethernet verso il PLC con IP fisso 192.168.0.x sulla scheda cablata. Le due cose funzionano in contemporanea.
- Strumento di controllo remoto installato e provato PRIMA di partire. Sul Dell TeamViewer si blocca all'avvio: va sistemato o sostituito con lo strumento che usa Picchio (chiedere quale).
- Versione TIA giusta: il Dell ha solo V15/V15.1 e funziona con la CPU di Picchio (1BG31 V3.0, progetto da aggiornare) o con una 1BG40. NON va online con la CPU vecchia FW V1.0: per quella serve TIA V13 (oggi solo sul PC di Davide, che e' fisso).
- Prova di collegamento remoto dall'azienda prima del giorno in ESO.
- Chi assiste da remoto non vede la linea: ogni comando che puo' muovere qualcosa (RUN, forzature, caricamento) solo con conferma di Simone sul posto e linea in sicurezza.
- Caricare solo su PLC_2 (Quadro 2 Linea B). MAI su PLC_1.
