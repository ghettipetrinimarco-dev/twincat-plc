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
