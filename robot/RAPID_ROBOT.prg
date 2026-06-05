%%VERSION:1
%%LANGUAGE:ENGLISH
%%%

!==============================================================================
! RAPID_ROBOT.prg — ABB Robot pick listener per progetto NIR  v2.1
! ==============================================================================
! Carica questo modulo sul controller ABB (IRC5 / OmniCore) via RobotStudio
! o USB. Assegna il task T_ROB1 e avvia in modalità automatica.
!
! Funzione:
!   Apre un server TCP sulla porta PORT_LISTEN.
!   Riceve stringhe di pick dal PLC TwinCAT nel formato:
!       @UiTag,X_mm,Y_mm,Z_mm,Rotazione,AttesaPresa,X_box,Y_box,Z_box,AttesaDeposito,#
!   Esegue il movimento di pick e deposito per ogni stringa ricevuta.
!   Invia ACK al PLC dopo ogni pick completato:
!       OK,UiTag,#
!
! IMPORTANTE — Valori da adattare al prototipo fisico:
!   - PORT_LISTEN: porta TCP (deve corrispondere a PORT_ROBOT nel PLC)
!   - WorkObject wobj_nastro: definire con calibrazione reale
!   - Tool tool_pinza: definire con calibrazione reale
!   - Velocità vPick, vDeposit: adattare alle velocità sicure del robot
!
! NOTA: Questo è uno skeleton funzionale. Richiede adattamento da un
! programmatore ABB con accesso fisico al robot.
!==============================================================================

MODULE NirPickModule

    !--- Costanti configurazione ---
    CONST num    PORT_LISTEN    := 10000;    ! Porta TCP — deve corrispondere a PORT_ROBOT nel PLC
    CONST string HOST_LOCAL     := "";       ! Stringa vuota = qualsiasi interfaccia
    CONST num    MAX_PICK_QUEUE := 16;       ! Dimensione coda interna pick
    CONST num    CONVEYOR_SPEED := 500;      ! mm/s velocità nastro — DA MISURARE

    !--- Velocità movimenti (da calibrare) ---
    CONST speeddata vAvvicina   := [1000, 300, 5000, 1000];  ! Avvicinamento rapido
    CONST speeddata vPick       := [300,  50,  5000, 1000];  ! Discesa lenta per presa
    CONST speeddata vDeposit    := [800,  200, 5000, 1000];  ! Verso box deposito
    CONST speeddata vHome       := [1500, 300, 5000, 1000];  ! Ritorno home

    !--- Zone di blending movimenti ---
    CONST zonedata zAvvicina    := [FALSE, 20, 30, 30, 0.5, 30, 0.5];
    CONST zonedata zFine        := [FALSE,  0,  0,  0, 0.0,  0, 0.0];  ! Stop preciso

    !--- Tool e WorkObject (CALIBRARE prima del primo test!) ---
    PERS tooldata   tool_pinza  := [TRUE, [[0,0,150],[1,0,0,0]], [1,[0,0.001,0.001],[1,0,0,0],0,0,0]];
    PERS wobjdata   wobj_nastro := [FALSE, TRUE, "", [[0,0,0],[1,0,0,0]], [[0,0,0],[1,0,0,0]]];

    !--- Posizione Home (da insegnare con jog) ---
    PERS robtarget pHome := [[500,0,400],[0,0,1,0],[0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];

    !--- Variabili TCP ---
    VAR socketdev    server_socket;
    VAR socketdev    client_socket;
    VAR string       raw_string;
    VAR bool         socket_ok := FALSE;

    !--- Dati pick ricevuti dal PLC ---
    VAR num  tag;
    VAR num  x_pick;
    VAR num  y_pick_received;   ! Posizione Y al momento della rilevazione NIR
    VAR num  y_pick_corrected;  ! Posizione Y corretta per avanzamento nastro
    VAR num  z_pick;
    VAR num  rotazione;
    VAR num  attesa_presa;
    VAR num  x_box;
    VAR num  y_box;
    VAR num  z_box;
    VAR num  attesa_deposit;

    !--- Target calcolati ---
    VAR robtarget pPickAvvicina;
    VAR robtarget pPickFine;
    VAR robtarget pBoxAvvicina;
    VAR robtarget pBoxFine;

    !--- Diagnostica ---
    VAR num  n_pick_eseguiti    := 0;
    VAR num  n_errori_parse     := 0;
    VAR num  n_errori_socket    := 0;

!------------------------------------------------------------------------------
! PROC main — Entry point, ciclo principale
!------------------------------------------------------------------------------
PROC main()
    TPWrite "NIR Pick Robot — avvio...";
    MoveJ pHome, vHome, zFine, tool_pinza\WObj:=wobj_nastro;

    WHILE TRUE DO
        ! Apri server e aspetta connessione PLC
        ConnectServer;

        ! Loop ricezione pick
        WHILE socket_ok DO
            IF ReceiviPick() THEN
                EseguiPick;
            ENDIF
        ENDWHILE

        TPWrite "Connessione persa. Riconnessione in 3s...";
        WaitTime 3;
    ENDWHILE
ENDPROC

!------------------------------------------------------------------------------
! PROC ConnectServer — Apre socket TCP server e aspetta PLC
!------------------------------------------------------------------------------
PROC ConnectServer()
    VAR string error_msg;

    TPWrite "In ascolto su porta " + NumToStr(PORT_LISTEN, 0) + "...";
    socket_ok := FALSE;

    SocketCreate server_socket;
    SocketBind server_socket, HOST_LOCAL, PORT_LISTEN;
    SocketListen server_socket;
    SocketAccept server_socket, client_socket \Time:=60;

    socket_ok := TRUE;
    n_errori_socket := 0;
    TPWrite "PLC connesso. Attendo comandi pick...";

    ERROR
        n_errori_socket := n_errori_socket + 1;
        TPWrite "Errore socket: " + NumToStr(ERRNO, 0);
        SocketClose client_socket;
        SocketClose server_socket;
        socket_ok := FALSE;
        TRYNEXT;
ENDPROC

!------------------------------------------------------------------------------
! FUNC ReceiviPick — Legge stringa dal PLC, parsa i campi
! Restituisce TRUE se il parse è riuscito, FALSE in caso di errore
!
! Formato atteso:
!   @UiTag,X_mm,Y_mm,Z_mm,Rot,AttPresa,Xb,Yb,Zb,AttDep,#
!------------------------------------------------------------------------------
FUNC bool ReceiviPick()
    VAR string  raw;
    VAR num     recv_bytes;
    VAR string  fields{11};
    VAR num     n_fields;
    VAR num     pos_at;
    VAR num     pos_hash;
    VAR string  content;

    ! Ricezione stringa (bloccante con timeout 30s)
    SocketReceive client_socket \Str:=raw \Time:=30;

    ! Estrai contenuto tra @ e #
    pos_at   := StrFind(raw, 1, "@");
    pos_hash := StrFind(raw, 1, "#");

    IF pos_at < 1 OR pos_hash < 1 OR pos_hash <= pos_at THEN
        n_errori_parse := n_errori_parse + 1;
        TPWrite "Formato stringa non valido: " + raw;
        RETURN FALSE;
    ENDIF

    content := StrPart(raw, pos_at+1, pos_hash-pos_at-1);

    ! Splitta per virgola
    n_fields := 0;
    SplitCampi content, fields, n_fields;

    IF n_fields < 10 THEN
        n_errori_parse := n_errori_parse + 1;
        TPWrite "Campi insufficienti: " + NumToStr(n_fields, 0);
        RETURN FALSE;
    ENDIF

    ! Assegna campi
    tag              := StrToVal(fields{1});   ! UiTag
    x_pick           := StrToVal(fields{2});   ! X traccia NIR → mm
    y_pick_received  := StrToVal(fields{3});   ! Y mm alla rilevazione
    z_pick           := StrToVal(fields{4});   ! Z mm
    rotazione        := StrToVal(fields{5});   ! gradi rotazione pinza
    attesa_presa     := StrToVal(fields{6});   ! secondi attesa presa
    x_box            := StrToVal(fields{7});   ! X deposito
    y_box            := StrToVal(fields{8});   ! Y deposito
    z_box            := StrToVal(fields{9});   ! Z deposito
    attesa_deposit   := StrToVal(fields{10});  ! secondi attesa deposito

    RETURN TRUE;

    ERROR
        n_errori_socket := n_errori_socket + 1;
        socket_ok := FALSE;
        TPWrite "Errore ricezione: " + NumToStr(ERRNO, 0);
        SocketClose client_socket;
        SocketClose server_socket;
        RETURN FALSE;
ENDFUNC

!------------------------------------------------------------------------------
! PROC EseguiPick — Esegue il ciclo pick + deposito
!
! NOTA sul conveyor tracking:
!   y_pick_received è la posizione Y quando il NIR ha rilevato l'oggetto.
!   Il nastro continua a muoversi tra la rilevazione e il momento del pick.
!   Correzione: y_pick_corrected = y_pick_received + DISTANZA_ROBOT_MM
!                                  + (tempo_ciclo_robot * CONVEYOR_SPEED)
!   Per ora usiamo y_pick_received + offset fisso (DA CALIBRARE).
!   Per conveyor tracking completo serve un encoder sul nastro collegato
!   all'asse conveyor del robot (funzione "Conveyor Tracking" RobotWare).
!------------------------------------------------------------------------------
PROC EseguiPick()
    ! ---- Correggi posizione Y per avanzamento nastro ----
    ! TODO: sostituire con conveyor tracking RobotWare se disponibile
    ! Per ora: offset fisso calibrato sperimentalmente
    y_pick_corrected := y_pick_received;    ! DA CALIBRARE

    ! ---- Costruisci target pick ----
    ! Avvicinamento: stessa XY del pick, ma Z alta (sicurezza)
    pPickAvvicina := [[x_pick, y_pick_corrected, z_pick + 100],
                      [0, 0, 1, 0],    ! Orientamento: pinza verso il basso — DA CALIBRARE
                      [0, 0, 0, 0],
                      [9E9, 9E9, 9E9, 9E9, 9E9, 9E9]];

    ! Target pick preciso
    pPickFine := [[x_pick, y_pick_corrected, z_pick],
                  [0, 0, 1, 0],
                  [0, 0, 0, 0],
                  [9E9, 9E9, 9E9, 9E9, 9E9, 9E9]];

    ! Target deposito: avvicinamento
    pBoxAvvicina := [[x_box, y_box, z_box + 100],
                     [0, 0, 1, 0],
                     [0, 0, 0, 0],
                     [9E9, 9E9, 9E9, 9E9, 9E9, 9E9]];

    ! Target deposito: fine
    pBoxFine := [[x_box, y_box, z_box],
                 [0, 0, 1, 0],
                 [0, 0, 0, 0],
                 [9E9, 9E9, 9E9, 9E9, 9E9, 9E9]];

    ! ---- Ciclo pick ----
    ! 1. Avvicinamento rapido alla zona pick
    MoveJ pPickAvvicina, vAvvicina, zAvvicina, tool_pinza\WObj:=wobj_nastro;

    ! 2. Discesa lenta al pezzo
    MoveL pPickFine, vPick, zFine, tool_pinza\WObj:=wobj_nastro;

    ! 3. Attiva pinza (DA ADATTARE al tipo di pinza: pneumatica/servomotore/ventosa)
    ! Set DO_PINZA, 1;          ! Ventosa/pinza ON
    WaitTime attesa_presa;      ! Attendi presa sicura

    ! 4. Risali con pezzo
    MoveL pPickAvvicina, vPick, zAvvicina, tool_pinza\WObj:=wobj_nastro;

    ! ---- Ciclo deposito ----
    ! 5. Movimento verso box
    MoveJ pBoxAvvicina, vDeposit, zAvvicina, tool_pinza\WObj:=wobj_nastro;

    ! 6. Discesa al box
    MoveL pBoxFine, vDeposit, zFine, tool_pinza\WObj:=wobj_nastro;

    ! 7. Rilascia pezzo
    ! Set DO_PINZA, 0;           ! Ventosa/pinza OFF
    WaitTime attesa_deposit;

    ! 8. Risali dal box
    MoveL pBoxAvvicina, vDeposit, zAvvicina, tool_pinza\WObj:=wobj_nastro;

    ! 9. Torna in posizione di attesa (opzionale — commentare se non necessario)
    ! MoveJ pHome, vHome, zAvvicina, tool_pinza\WObj:=wobj_nastro;

    n_pick_eseguiti := n_pick_eseguiti + 1;
    TPWrite "Pick #" + NumToStr(tag, 0) + " eseguito. Totale: " + NumToStr(n_pick_eseguiti, 0);

    ! ---- Invia ACK al PLC ----
    ! Il PLC (stato ATTESA_ACK) aspetta "OK,UiTag,#" per confermare il pick.
    ! Il timeout PLC è 3s — se il ciclo robot è più lungo, il PLC lo ignora
    ! e conteggia come ack_timeout (produzione non bloccata).
    SocketSend client_socket \Str:="OK," + NumToStr(tag, 0) + ",#";

    ERROR
        ! Errore invio ACK — non critico, il PLC ha il proprio timeout
        TPWrite "Errore ACK: " + NumToStr(ERRNO, 0);
        TRYNEXT;
ENDPROC

!------------------------------------------------------------------------------
! PROC SplitCampi — Splitta stringa per virgola
! Popola array fields{} e imposta n_fields
!------------------------------------------------------------------------------
PROC SplitCampi(string input, INOUT string fields{*}, INOUT num n_fields)
    VAR num pos     := 1;
    VAR num pos_sep := 0;
    VAR num len     := StrLen(input);

    n_fields := 0;
    WHILE pos <= len AND n_fields < 10 DO
        pos_sep := StrFind(input, pos, ",");
        IF pos_sep > len THEN pos_sep := len + 1; ENDIF
        n_fields := n_fields + 1;
        fields{n_fields} := StrPart(input, pos, pos_sep - pos);
        pos := pos_sep + 1;
    ENDWHILE
ENDPROC

!------------------------------------------------------------------------------
! FUNC StrToVal — Converte stringa in numero (helper)
!------------------------------------------------------------------------------
FUNC num StrToVal(string s)
    VAR num result := 0;
    VAR bool ok;
    ok := StrToVal(s, result);
    RETURN result;
ENDFUNC

ENDMODULE
