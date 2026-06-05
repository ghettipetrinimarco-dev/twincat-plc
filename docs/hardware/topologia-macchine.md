# Topologia Macchine

## Le 3 Macchine della Linea

| IP | Hostname noto | Hardware fisico | Runtime PLC |
|---|---|---|---|
| 192.168.1.31 | — | Beckhoff nativo | TwinCAT SoftPLC |
| 192.168.1.32 | — | Beckhoff nativo | TwinCAT SoftPLC |
| 192.168.1.34 | HMIsemp (ex DHCP .113) | PC Industriale / Monitor Elmak | TwinCAT SoftPLC |

## La Scoperta della Macchina .34 (Elmak)
La macchina `.34` si presentava con hardware Elmak (monitor industriale) e moduli I/O di terze parti, che suggerivano l'uso di un software diverso (es. Automation Studio B&R).

**Verifica:** L'icona TwinCAT (ingranaggio verde) in RUN era visibile nella taskbar di Windows.

**Conclusione architettonica:** Il PC Elmak è usato esclusivamente come hardware fisico. Il runtime è **TwinCAT SoftPLC**, identico alle macchine Beckhoff. Questo significa:
- Stesso codice `Processing.st`
- Stessa logica e stessi nomi variabili
- Stesso driver Modbus `TS6250`
- Stessa procedura di manutenzione/aggiornamento

## Codice e Sincronizzazione
<!-- TODO: confermare se esiste un repository unico o 3 copie sincronizzate manualmente -->
<!-- RISCHIO: se 3 copie manuali, rischio di drift tra macchine nel tempo -->

## Licenze TwinCAT
<!-- TODO: versione TwinCAT (TC2/TC3 + build) su ciascuna macchina -->
<!-- TODO: licenza SoftPLC sulla .34 — regolare/perpetua o trial? -->
<!-- TODO: licenza TS6250 su tutte e 3 — verificare se attive -->
