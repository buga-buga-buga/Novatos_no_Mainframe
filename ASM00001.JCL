//ASM00001 JOB 'COMPILA E LOAD DE PROGRAMA HLASM',
// CLASS=A,NOTIFY=&SYSUID
//STEP1 EXEC ASMACLG
//SYSIN DD *
          HELLO CSECT
          USING ,15
          WTO 'HELLO WORLD' BR 14
          END
//