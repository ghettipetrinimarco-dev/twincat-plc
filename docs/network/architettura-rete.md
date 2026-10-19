# Architettura di Rete e Sicurezza

## Indirizzamento IP Statico

| IP | Macchina | Note |
|---|---|---|
| 192.168.1.1 | Gateway aziendale | — |
| 192.168.1.31 | Beckhoff .31 | IP statico |
| 192.168.1.32 | Beckhoff .32 | IP statico |
| 192.168.1.34 | Elmak SoftPLC | IP statico (ex DHCP .113 / hostname HMIsemp) |

**DNS aziendali (obbligatori per TeamViewer/AnyDesk):**
- Preferito: `85.159.176.161`
- Alternativo: `85.159.176.162`

I DNS pubblici (es. `8.8.8.8`) vengono bloccati in uscita dal firewall aziendale.

## Procedura Cambio da DHCP a IP Statico
1. Con la macchina ancora in DHCP, eseguire `ipconfig /all` e annotare DNS esatti forniti dal router
2. Assegnare IP statico replicando i DNS rilevati (non usare DNS pubblici)
3. Impostare gateway `192.168.1.1`

## Problema Windows Firewall
Passando da DHCP a IP statico, Windows classifica la connessione come "Rete non identificata" o "Pubblica", alzando il firewall e bloccando le richieste in ingresso sulla **porta 502 (Modbus TCP)**.

**Soluzioni (in ordine di preferenza):**
1. *(Consigliata)* Convertire la connessione in "Rete Aziendale/Privata" dal Centro Connessioni di Rete di Windows
2. *(Attualmente in uso)* Disattivare Windows Firewall per le reti pubbliche

<!-- TODO: verificare e uniformare la soluzione su tutte e 3 le macchine -->

## Teleassistenza
- Software: TeamViewer / AnyDesk
- Dipende dai DNS aziendali corretti. Con IP statico e DNS pubblici, TeamViewer cade.
- La rete è isolata ma con accesso internet per la teleassistenza.

<!-- TODO: confermare se la rete 192.168.1.x è condivisa con uffici/PC aziendali (impatta sul rischio sicurezza del firewall disattivato) -->

## Intervento 2026-10-19 - Cambio rete aziendale su .34 (Elmak R4)
Un elettricista ha introdotto un nuovo router `192.168.11.1` (rete `192.168.11.0/24`) e ha messo le schede del panel .34 in DHCP. Effetto: NIR fermo (Hz=0), programma bloccato su "Inizializzazione sistema in corso".

Configurazione ripristinata sul panel .34 (hostname HMISEMP):

| Scheda Windows | Configurazione | Collegata a |
|---|---|---|
| NIR (nome fuorviante) | Statico `192.168.11.34` + `192.168.1.34` /24, GW `192.168.11.1`, DNS `85.159.176.161/.162` | Rete aziendale (switch) |
| LAN 4 | Statico `192.168.0.1` /24, nessun gateway | PC NIR `192.168.0.10` (cavo diretto, hostname SYS1570411) |
| LAN 3 | DHCP (169.254) | Sconosciuto, 100 Mbit, nessun traffico |
| Twincat | DHCP (169.254) | Moduli I/O, non toccare |

Note:
- `.31`, `.32`, `.33` e `.4` sono ancora su `192.168.1.x`: il secondo IP `192.168.1.34` mantiene la comunicazione con loro e con lo SCADA.
- Quando migreranno anche le altre macchine a `11.x`, va aggiornato lo SCADA (Daniele) e serve l'IP fisso `192.168.0.1` sulla scheda verso il PC NIR.
- TwinCAT apre la UDP verso il NIR solo all'avvio: dopo modifiche di rete riavviare il panel.
- Chiedere all'elettricista di escludere `.34` dal DHCP del nuovo router.
