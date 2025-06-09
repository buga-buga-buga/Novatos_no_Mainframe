//JOB00000 JOB 'EXECUTA HELLO WORLD',                                 
//             NOTIFY=&SYSUID,MSGCLASS=H                              
//* Esse Job executa o programa cobol HELLO0000                       
//EXECUTA  EXEC PGM=HELLO000          *** COMENTARIO DIDATICO ***     
//SYSOUT   DD SYSOUT=A,HOLD=YES                                       
//    