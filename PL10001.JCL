//PL10001 JOB 'COMPILA E LOAD DE PROGRAMA PL/1',
// NOTIFY=&SYSUID,REGION=0M
//STEP1 EXEC IBMZCPLG
//PLI.STEPLIB DD DSN=IEL520.SIBMZCMP,DISP=SHR
//SYSIN DD *
 Hello: procedure options (main);
     put skip list ('Hello World em PL/1 !');
 end Hello;
//*