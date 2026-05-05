# Modbus TCP Server (TS6250)

## Installazione
- **Eseguibile:** `TS6250-Modbus-TCP-Server.exe`
- Eseguire **tassativamente come Amministratore**
- Richiede **riavvio del PC** dopo l'installazione

## Configurazione Servizio Windows (services.msc)
1. Aprire `services.msc`
2. Individuare `TwinCAT Modbus TCP Server`
3. Impostare **Tipo di avvio:** `Automatico`
4. Verificare stato: `In esecuzione` (Started)

Il servizio non parte automaticamente dopo l'installazione e potrebbe non avviarsi al riavvio del quadro elettrico se non configurato.

## Diagnostica — Test della Verità
Verificare che il server sia agganciato a TwinCAT e la porta sia aperta (indipendentemente dal firewall esterno):

```
netstat -an | find "502"
```

**Risultato atteso:**
```
TCP    0.0.0.0:502    0.0.0.0:0    LISTENING
```

Se non compare `LISTENING`:
- Il servizio non è avviato → aprire `services.msc` e avviarlo
- Il servizio è avviato ma non si aggancia → riavviare il PC (necessario post-installazione)
- La porta è bloccata dal firewall → vedere `docs/network/architettura-rete.md`

## Note
- Presente e configurato su tutte e 3 le macchine (`.31`, `.32`, `.34`)
- Espone l'area di memoria `%MW0` su porta TCP 502
- <!-- TODO: versione TS6250 installata, verificare se licenza attiva o trial -->
