@echo off
setlocal enabledelayedexpansion

echo ================================
echo Iniciando o job de Log Rotation...
echo ================================
echo.

:: Obtem data e hora do sistema
set dt=%DATE:~-4%%DATE:~3,2%%DATE:~0,2%
set tm=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%%TIME:~9,2%
set timestamp=%dt%_%tm%

:: Diretórios e arquivos
set logdir=D:\tk5\log
set prtdir=D:\tk5\prt

:: Processa os arquivos
call :RotateFile "%logdir%\3033.log"
call :RotateFile "%logdir%\hardcopy.log"
call :RotateFile "%logdir%\hercules.log"
call :RotateFile "%prtdir%\prt002.txt"
call :RotateFile "%prtdir%\prt00e.txt"
call :RotateFile "%prtdir%\prt00f.txt"

echo.
echo ================================
echo Job de Log Rotation finalizado!
echo ================================
echo.
exit /b

:RotateFile
set "file=%~nx1"
set "status="

<nul set /p "=Rotacionando !file!... "

if not exist "%1" (
    echo [AVISO] Arquivo nao encontrado.
    goto :EOF
)

ren "%1" "%~nx1_%timestamp%" 2>nul

if !errorlevel! neq 0 (
    echo [ERRO] Falha ao renomear - Return Code: !errorlevel!
    echo   Tentando identificando a origem do erro...

    set "bloqueador_exe="
    set "bloqueador_pid="
    set "bloqueador_user="

    for /f "tokens=1-8 delims= " %%A in (
        'handle.exe "%1" -accepteula -u 2^>nul ^| findstr /i "%~nx1"'
    ) do (
        set "bloqueador_exe=%%A"
        set "bloqueador_pid=%%C"
        
        if "%%F"=="type:" (
            set "bloqueador_user=%%G %%H"
        ) else (
            set "bloqueador_user=%%E %%F"
        )
    )

    if defined bloqueador_exe (
        echo   Existe bloqueio por: !bloqueador_exe! - PID: !bloqueador_pid! - Usuario: !bloqueador_user!
    ) else (
        echo   Bloqueio parece que nao era, sem mais ideias, boa sorte!
    )
) else (
    type nul > "%1"
    echo [SUCESSO] ^> %~nx1_%timestamp%
)
goto :EOF