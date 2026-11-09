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
