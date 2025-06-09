param (
    [string]$JclFile
)

# Configurações
$NetcatPath = "D:\tk5\Customizadas_do_Buga\netcat\nc64.exe"
$MainframeIP = "localhost"
$MainframePort = 3505
$SYSOUT = "D:\tk5\prt\prt00e.txt"
$TimeoutSeconds = 15
$Inicia_Hercules_e_Mainframe = "mvs.bat"
$workingDir = "D:\tk5"
$diretorioAtual = Get-Location
$logPath = "D:\tk5\log\3033.log"

function Check-JobExecucao {
    param(
        [string]$JobName,
        [string]$OutputPath,
        [string]$HerculesLogPath
    )

    # Verifica no log do Hercules (3033.log) para mensagens IEF452I
    if (Test-Path $HerculesLogPath) {
        try {
            $logContent = Get-Content $HerculesLogPath -Tail 10 -ErrorAction Stop
            
            # Procura por mensagens de erro específicas no log do Hercules
            if ($logContent -match "JOB NOT RUN") {
                Write-Host "ERRO GRAVE: Job $JobName não executado - Erro de JCL detectado"
                
                return $true
            }
        } catch {
            Write-Host "Erro ao verificar log do Hercules: $_"
        }
    }
    
    return $false
}

# Função para aguardar a inicialização do sistema
function Wait-ForSystemStart {
    param(
        [int]$MaxAttempts = 40,
        [int]$DelaySeconds = 5
    )

    Write-Host "Aguardando inicialização completa do sistema..."
    
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        # Verifica no arquivo de log
        if (Test-Path $logPath) {
            try {
                $logContent = Get-Content $logPath -Tail 300 -ErrorAction Stop
                $matchingLine = $logContent | Select-String "MVS038J MVS 3.8j TK5 system initialization complete"
                
                if ($matchingLine) {
                    Write-Host "[LOG] Sistema pronto: $($matchingLine.Line)"
                    return $true
                }
            } catch {
                Write-Host "Erro ao ler o arquivo de log: $_"
            }
        }
        
        Write-Host "Tentativa $attempt/$MaxAttempts - Sistema ainda não está pronto..."
        Start-Sleep -Seconds $DelaySeconds
    }
    
    Write-Error "Timeout: Sistema não inicializou dentro do tempo esperado"
    return $false
}

# Verifica se o netcat está instalado
if (-not (Test-Path $NetcatPath)) {
    Write-Error "Erro: O netcat não foi encontrado em $NetcatPath"
    exit 1
}   

# Valida arquivo JCL (com suporte a caminho relativo)
$JclFullPath = if ([System.IO.Path]::IsPathRooted($JclFile)) {
    $JclFile
} else {
    Join-Path $diretorioAtual $JclFile
}

if (-not (Test-Path $JclFullPath)) {
    Write-Error "Erro: Arquivo JCL não encontrado em $JclFullPath"
    exit 1
}

# Extrai nome do job
$JobName = Get-Content $JclFullPath -First 1 | Select-String -Pattern '^//.{1,8}' | ForEach-Object { $_.Matches.Value.Substring(2) }
if (-not $JobName) {
    Write-Error "Erro: nome do JOB no JCL não esta no formato correto"
    exit 1
}

# Checa se Hercules tá rodando
Write-Host "Verificando mainframe (${MainframeIP}:${MainframePort})..."
$tcpClient = New-Object System.Net.Sockets.TcpClient
try {
    # Tentativa de conexão inicial
    $tcpClient.Connect($MainframeIP, $MainframePort)
    Write-Host "Mainframe ativo!"
} catch {
    Write-Host "Mainframe não está ativo. Iniciando o TK5 via Hercules..."
    
    # Verifica se o arquivo batch existe
    $batPath = Join-Path $workingDir $Inicia_Hercules_e_Mainframe
    if (-not (Test-Path $batPath)) {
        Write-Error "Erro: O script mvs.bat não foi encontrado em $workingDir"
        exit 1
    }
    
    # Inicia o Hercules
    Set-Location $workingDir
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList @(
            "-NoExit",
            "-Command",
            "cd '$workingDir'; .\$Inicia_Hercules_e_Mainframe"
        ) -Verb RunAs -WindowStyle Normal
        
        # Aguarda inicialização completa
        if (-not (Wait-ForSystemStart -MaxAttempts 40 -DelaySeconds 5)) {
            exit 1
        }
    } finally {
        Set-Location $diretorioAtual
    }
} finally {
    $tcpClient.Close()
}
##
# Submete JCL via netcat
##
Write-Host "Submetendo $JclFile ($JobName)..."
try {
    Get-Content $JclFullPath | & $NetcatPath -v -w 5 $MainframeIP $MainframePort
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Falha ao submeter JCL via netcat (código $LASTEXITCODE)"
        exit 1
    }
} catch {
    Write-Error "Erro ao executar netcat: $_"
    exit 1
}

# Logo depois de submeter o JCL, adicione:
Write-Host "Verificando status inicial do job..."

Start-Sleep -Seconds 2

if (Check-JobExecucao -JobName $JobName -OutputPath $OutputPath -HerculesLogPath $logPath) {
    Write-Error "Job $JobName não executado, verifique!"
    exit 1
}

# Aguarda job processar com timeout e verificação periódica
$maxAttempts = 10
$attempt = 0
$found = $false
$checkInterval = 5

Write-Host "Aguardando processamento do job..."

while ($attempt -lt $maxAttempts -and -not $found) {
    Write-Host "Tentativa $attempt/$MaxAttempts - Aguardando SYSOUT..."    
    $attempt++
    Start-Sleep -Seconds $checkInterval
    if (Test-Path $SYSOUT) {
        try {
            $content = Get-Content $SYSOUT -Raw
            # Padrão para encontrar o END JOB específico
            if ($content -match "\*{4}A\s+END\s+JOB\s+\d+\s+$JobName") {
                $found = $true
            }
        } catch {
            Write-Warning "Erro ao ler arquivo de saída na tentativa $attempt : $_"
        }
    }
}

# Filtra saída após encontrar o END JOB ou esgotar as tentativas
if ($found) {
    try {
        $content = Get-Content $SYSOUT -Raw
        # Padrão modificado para pegar a última ocorrência
        $pattern = "(?s).*(\*{4}A\s+START\s+JOB\s+\d+\s+$JobName.*?\*{4}A\s+END\s+JOB\s+\d+\s+$JobName.*?\*{4}).*"
        $output = [regex]::Match($content, $pattern).Groups[1].Value

        if ($output) {
            $output
        } else {
            Write-Warning "Intervalo completo do job $JobName não encontrado, apesar de END JOB existir."
            # Mostra as últimas linhas para ajudar no debug
            $lastLines = Get-Content $SYSOUT -Tail 20
            Write-Host "Últimas linhas do arquivo de saída:`n$lastLines"
        }
    } catch {
        Write-Error "Erro ao ler arquivo de saída: $_"
    }
} else {
    Write-Error "Job $JobName não finalizado após $TimeoutSeconds segundos. END JOB não encontrado no log."
    if (Test-Path $SYSOUT) {
        $lastLines = Get-Content $SYSOUT -Tail 20
        Write-Host "Últimas linhas do arquivo de saída:`n$lastLines"
    }
}