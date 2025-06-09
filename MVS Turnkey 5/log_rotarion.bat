@echo off
echo ================================
echo Iniciando o job de Log Rotation...
echo ================================
echo.
:: Obtem data e hora do sistema
set dt=%DATE:~-4%%DATE:~3,2%%DATE:~0,2%
set tm=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%%TIME:~9,2%

:: Concatena pra criar timestamp
set timestamp=%dt%_%tm%

:: Diretórios e arquivos
set logdir=D:\tk5\log
set prtdir=D:\tk5\prt

:: Renomeando e criando novos arquivos zerados
for %%F in (%logdir%\3033.log %logdir%\hardcopy.log) do (
	echo Rotacionando arquivo %%F
    ren "%%F" "%%~nxF_%timestamp%"
    type nul > "%%F"	
)

for %%F in (%prtdir%\prt002.txt %prtdir%\prt00e.txt %prtdir%\prt00f.txt) do (
	echo Rotacionando arquivo %%F
    ren "%%F" "%%~nxF_%timestamp%"
    type nul > "%%F"
)

echo.
echo ================================
echo Job de Log Rotation finalizado!
echo ================================
echo.

exit /b