# Analisi Progetto Robot — Sessione 2026-05-26

## Stato del progetto

Il progetto robot è **parzialmente scritto ma non funzionante**. Il precedente programmatore
aveva impostato l'architettura corretta ma si è bloccato su un problema di implementazione
nel codice NIR. Il problema non era hardware ma software.

---

## Architettura prevista (corretta concettualmente)

```
[LLA NIR 1.7 — UDP 192.168.0.10:1803]
        ↓
  Sensore_NIR (Task Camera, 200µs)
  - riceve pacchetti 121 byte
  - per ogni traccia attiva → costruisce stringa pick
  - accumula in String_Tmp[index_nir]
  - a BUFFER_SIZE pieno → copia in String_ToSend[] + Trig:=TRUE
  - Out_1:=Trig (uscita fisica)
        ↓
  Gestione_Robot (Task Elaboration, 10ms)
  - R_TRIG su Trig → send_data:=TRUE
  - apre TCP verso IP_PICKMASTER:PORT_PICKMASTER
  - manda CMD_AVVIA_PROGETTO (0x00 0x13)
  - apre TCP verso IP_USERHOOK:PORT_USERHOOK
  - manda String_ToSend quando Trig sale
        ↓
  ABB PickMaster (PC separato — NON CONFERMATO PRESENTE)
        ↓
  ABB Robot (braccio multi-asse dall'alto)
```

---

## Variabili globali robot (mancanti dal GVL — da ricreare)

| Variabile | Tipo | Descrizione |
|---|---|---|
| `IP_PICKMASTER` | STRING | IP del PC PickMaster |
| `PORT_PICKMASTER` | UINT | Porta TCP PickMaster (standard: 1700) |
| `IP_USERHOOK` | STRING | IP UserHook PickMaster |
| `PORT_USERHOOK` | UINT | Porta UserHook |
| `SCAN_DISTANCE` | REAL | Distanza fisica tra scansioni NIR (mm) |
| `DISTANCE_OFFSET` | REAL | Offset posizione Y iniziale (mm) |
| `ALTEZZA` | REAL | Quota Z di presa (mm) |
| `GRADI_ROTAZIONE` | REAL | Orientamento pinza (gradi) |
| `ATTESA_PRESA` | REAL | Tempo attesa dopo discesa (s) |
| `ATTESA_DEPOSITO` | REAL | Tempo attesa al deposito (s) |
| `X_BOX[n]` | ARRAY OF REAL | Coordinate X box deposito per materiale |
| `Y_BOX[n]` | ARRAY OF REAL | Coordinate Y box deposito per materiale |
| `Z_BOX[n]` | ARRAY OF REAL | Coordinate Z box deposito per materiale |
| `MATERIALI_ATTIVI_BOX[n]` | ARRAY OF INT | Indice box per ogni materiale attivo |

---

## Formato stringa pick (già implementato in sensoreNIR)

```
@UiTag,X,Y,Z,Rotazione,AttesaPresa,X_Box,Y_Box,Z_Box,AttesaDeposito,#
```

**Esempio:** `@0,10,152.4,200.0,0.0,0.5,320.0,340.0,430.0,0.3,#`

- `UiTag` — contatore progressivo pick (INT, incrementato ogni pick)
- `X` — numero traccia NIR (1..NUM_TRACKS_NIR = posizione laterale)
- `Y` — `index_nir × SCAN_DISTANCE + DISTANCE_OFFSET` (posizione longitudinale)
- `Z` — costante `ALTEZZA`
- `Rotazione` — costante `GRADI_ROTAZIONE`
- `AttesaPresa` — costante `ATTESA_PRESA`
- `X/Y/Z_Box` — coordinate box di deposito (dipende da `MATERIALI_ATTIVI_BOX[materiale]`)
- `AttesaDeposito` — costante `ATTESA_DEPOSITO`

---

## Bug identificati (perché non funziona)

### Bug 1 — Sovrascrittura tracce (CRITICO)
Nel loop tracce di `sensoreNIR`, `String_line_tmp` viene sovrascritto ad ogni traccia attiva.
Solo l'ultima traccia attiva per scan sopravvive in `String_Tmp[index_nir]`.
Oggetti che coprono più tracce generano un solo comando invece di N.

```pascal
(* PROBLEMA: questo sovrascrive ad ogni iterazione *)
String_line_tmp := CONCAT(concat_1, CONCAT(concat_2, ...));
...
String_Tmp[index_nir] := String_line_tmp; (* solo l'ultima traccia *)
```

**Fix necessario:** accumulare le stringhe per tutte le tracce attive della stessa scan,
oppure usare segmentazione oggetti (vedi Bug 2).

### Bug 2 — Nessuna segmentazione oggetti (CRITICO)
Un oggetto fisico che copre 20 tracce per 30 scan genererebbe fino a 600 comandi pick.
Il robot non può gestirlo.

Il codice embrionale di segmentazione (`pezzo_presente`, `matrix_data[25,117]`,
`indice_start`, `indice_stop`) esiste ma **non è mai collegato** alla generazione stringhe.
Si trova nella seconda metà del loop tracce in `sensoreNIR` ma opera solo su `indice<=25`
e non produce output utile.

**Fix necessario:** completare la segmentazione oggetti per produrre
1 comando pick con centroide X,Y per ogni oggetto fisico distinto.

### Bug 3 — Invio array grezzo (MINORE)
`Gestione_Robot` invia `SIZEOF(String_ToSend)` che è l'intero array di stringhe
come dump di memoria (151 × 82 byte = ~12.400 byte).
Il destinatario deve poter parsare questo formato.

---

## Situazione infrastruttura (INCERTA)

- **PickMaster PC**: non confermato presente sul prototipo. Al momento risultano
  presenti solo i PLC. Se non c'è un PC con PickMaster installato, tutta la logica
  `Gestione_Robot` va riprogettata per parlare direttamente col controller robot (TCP).
- **LLA NIR versione**: il commento originale diceva "manca funzione LLA 1.7".
  Probabilmente si riferiva alla segmentazione oggetti (Bug 2), non a hardware mancante.
- **Programma RAPID robot**: sconosciuto. Da verificare sul controller ABB.

---

## Priorità per completare il progetto

1. **Verificare infrastruttura fisica** — c'è un PC con PickMaster? Che versione di
   controller ha il robot? C'è già un programma RAPID caricato?

2. **Implementare segmentazione oggetti** — lavoro PLC puro, fattibile ora.
   Input: `matrix_data[scan, traccia]` già popolato.
   Output: lista oggetti con centroide X, Y, materiale dominante.

3. **Correggere generazione stringhe** — una stringa per oggetto, non per traccia.

4. **Decidere protocollo robot** — PickMaster UserHook vs TCP diretto al controller.

5. **Testare con robot fisico**.

---

## File in questa cartella

| File | Descrizione | Stato |
|---|---|---|
| `sensoreNIR.txt` | Gestione UDP NIR + generazione stringhe pick | Scritto, bug critici |
| `gestioneencoder.txt` | Encoder + conveyor tracking + firing Output_NIR | Scritto, funzionante |
| `processing.txt` | Statistiche materiali, percentuali, peso | Scritto, funzionante |
| `gestionerobot.txt` | TCP verso PickMaster + UserHook | Scritto, da migliorare |

