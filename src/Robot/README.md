# Robot layer draft

Questa cartella contiene una bozza collegata solo al passo encoder reale, ma non ancora aggiunta alle task TwinCAT.

Scopo:

- definire tipi e variabili per target robot
- costruire target da scan NIR
- creare target manuali di test con `Robot_TestInput`
- tracciare target con encoder
- generare campi comando numerici osservabili in watch
- generare `ROBOT_COMMAND_STRING` con `Robot_CommandStringBuilder` opzionale
- resettare coda e contatori con `ROBOT_RESET_REQUEST`
- simulare un robot ready/busy/picked

Non e' ancora integrata in `TASK_CONFIGURATION.EXP` e non va caricata in produzione senza import/compile in TwinCAT.

Prima di usarla su macchina reale servono:

- protocollo robot
- quote meccaniche
- GVL robot definitiva
- verifica compilazione TwinCAT 2
- test con `ROBOT_ENABLED := FALSE` e poi simulazione

Nota sul tracking:

- in simulazione `Robot_Queue` usa `ROBOT_SIM_TRACKING_STEP_IMP`
- su macchina reale `Gestione_Encoder` accumula gli impulsi in `ROBOT_ENCODER_PENDING_IMP`
- `Robot_Queue` consuma `ROBOT_ENCODER_PENDING_IMP` quando `ROBOT_ENCODER_STEP_VALID` e' TRUE
- non usare direttamente `PASSO_ENCODER` in un task lento senza impulso di validita', altrimenti si rischia di contare piu' volte lo stesso passo
