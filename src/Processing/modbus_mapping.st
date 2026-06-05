(* ==================================================== *)
(* --- MODBUS TCP SERVER: MAPPA 4.0 LOGICA DIRETTA  --- *)
(* ==================================================== *)
(* Area: Modbus_Area AT %MW0 : ARRAY [0..51] OF WORD   *)
(* Base SCADA: 12288 | Formula: SCADA = 12288 + Indice *)
(* Scala REAL: valore * 10.0 -> WORD (client divide /10)*)
(* Logica allarme: 1=OK, 0=Allarme                     *)
(* ==================================================== *)

(* --- INDICE 0: Carico minimo --- *)
Modbus_Area[0] := REAL_TO_WORD(carico_min * 10.0);

(* --- INDICE 1: TODO - riservato o mancante? Verificare con sviluppatore --- *)

(* --- INDICE 2: Pressione aria compressa --- *)
Modbus_Area[2] := REAL_TO_WORD(Pressione_aria * 10.0);

(* --- INDICE 3: Flussostato aria compressa --- *)
Modbus_Area[3] := REAL_TO_WORD(Flussostato_aria * 10.0);

(* --- INDICE 4: Intervallo ore istantaneo ---                               *)
(* WARNING: UDINT_TO_WORD tronca a 16 bit. Se valore > 65535 wrappa a 0.    *)
(* Verificare se comportamento voluto o bug latente.                         *)
Modbus_Area[4] := UDINT_TO_WORD(intervallo_ore_istantaneo);

(* --- INDICE 5: TODO - riservato o mancante? Verificare con sviluppatore --- *)

(* --- INDICI 6-21: Percentuali materiali SELEZIONATI [0..15] --- *)
(* --- INDICI 22-37: Percentuali materiali CAMPIONATI  [0..15] --- *)
(* Zeri fisiologici se nessun materiale di quel tipo e' transitato nel ciclo *)
FOR idx_mb := 0 TO 15 DO
	Modbus_Area[6  + idx_mb] := REAL_TO_WORD(PERC_SELEZIONATI[idx_mb] * 10.0);
	Modbus_Area[22 + idx_mb] := REAL_TO_WORD(PERC_CAMPIONATI[idx_mb]  * 10.0);
END_FOR

(* --- INDICE 38: Diagnostica generale (1=OK / 0=Allarme) --- *)
IF DIAGNOSTICA_OK THEN Modbus_Area[38] := 1; ELSE Modbus_Area[38] := 0; END_IF;

(* --- INDICE 39: Enable macchina --- *)
(* TODO: confermare se logica invertita (1=ON / 0=OFF) o diretta            *)
IF ENABLE THEN Modbus_Area[39] := 1; ELSE Modbus_Area[39] := 0; END_IF;

(* --- INDICE 40: Kg/minuto --- *)
Modbus_Area[40] := REAL_TO_WORD(KG_MINUTI * 10.0);

(* --- INDICE 41: Peso totale ciclo --- *)
Modbus_Area[41] := REAL_TO_WORD(PESO_TOTALE * 10.0);

(* --- INDICE 42: ID ricetta attiva (lettura) --- *)
Modbus_Area[42] := BYTE_TO_WORD(NUM_LOAD_ID);

(* --- INDICI 43-49: TODO - non documentati, verificare con sviluppatore --- *)

(* --- INDICE 50: Trigger esecuzione ricetta ---                              *)
(* NON GESTITO dal PLC. Previsto dalla spec V2 ma non implementato.          *)
(* Non modificare senza accordo con Daniele (gestionale SCADA).              *)
(* Modbus_Area[50] := ...; *)

(* --- INDICE 51: Numero Modello / Scrittura ricetta da SCADA ---            *)
(* Il PLC gestisce la lettura di questo registro nel blocco CMD_LOAD.        *)
(* Quando SCADA scrive ID > 0: PLC forza CMD_LOAD := TRUE e resetta a 0.    *)
(* La scrittura avviene altrove nel codice (blocco gestione comandi).        *)
