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

:: Processa os arquivos de log
call :RotateFile "%logdir%\3033.log"
call :RotateFile "%logdir%\hardcopy.log"

:: Processa os arquivos de prt
call :RotateFile "%prtdir%\prt002.txt"
call :RotateFile "%prtdir%\prt00e.txt"
call :RotateFile "%prtdir%\prt00f.txt"

call :RotateFile "%logdir%\erro3033.log"

echo.
echo ================================
echo Job de Log Rotation finalizado!
echo ================================
echo.

exit /b


:: Função para rotacionar arquivos
:RotateFile
echo Rotacionando arquivo %1 ...

:: Verifica se o arquivo existe
if not exist "%1" (
    echo [AVISO] Arquivo %1 nao encontrado.
    goto :EOF
)

:: Tenta renomear o arquivo
ren "%1" "%~nx1_%timestamp%" 2>nul
if %errorlevel% neq 0 (
	echo [ERRO] Falha ao renomear - Return Code: %errorlevel%
    echo Identificando o processo bloqueador...
    handle.exe "%1" -accepteula | findstr /i "pid:"
	echo. 
) else (
	type nul > "%1"
	echo [SUCESSO] rotacionado para %~nx1_%timestamp%
)
goto :EOF
