# ==========================================================
#  REPARO MATRIX - Ferramenta de reparo do Windows (TI)
#  DISM + SFC + CHKDSK com visual estilo Matrix
# ==========================================================

# ---------- 1. Auto-elevacao (abre o UAC: usuario/senha de admin) ----------
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Solicitando privilegios de administrador..." -ForegroundColor Green
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    } catch {
        Write-Host "Acesso negado ou cancelado." -ForegroundColor Red
        Start-Sleep 2
    }
    exit
}

# ---------- 2. Configuracao ----------
$Host.UI.RawUI.WindowTitle = "0x4D4154524958  ::  SYS.REPAIR"
$Host.UI.RawUI.BackgroundColor = "Black"
Clear-Host

$Drive   = $env:SystemDrive
$LogDir  = Join-Path $env:ProgramData "ReparoTI\logs"
if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }
$LogFile = Join-Path $LogDir ("reparo_{0}_{1}.log" -f $env:COMPUTERNAME, (Get-Date -Format "yyyyMMdd_HHmmss"))

# Resposta S/N do chkdsk depende do idioma do Windows
$SimKey = if ((Get-UICulture).Name -like "pt*") { "S" } else { "Y" }

# ---------- 3. Efeitos visuais ----------
function Get-Largura {
    try { return [Math]::Max(40, $Host.UI.RawUI.WindowSize.Width - 1) } catch { return 80 }
}

function Show-Matrix([int]$ms = 1200) {
    $w   = Get-Largura
    $fim = (Get-Date).AddMilliseconds($ms)
    while ((Get-Date) -lt $fim) {
        $linha = -join (1..$w | ForEach-Object {
            if ((Get-Random -Maximum 5) -eq 0) { " " } else { [string](Get-Random -Maximum 2) }
        })
        $cor = @("Green", "DarkGreen", "Green")[(Get-Random -Maximum 3)]
        Write-Host $linha -ForegroundColor $cor
        Start-Sleep -Milliseconds 20
    }
}

# Mantem a chuva de binarios rolando + um cronometro MM:SS ate a chamada assincrona terminar
function Show-MatrixWhile([System.IAsyncResult]$handle, [datetime]$inicio) {
    $w = Get-Largura
    while (-not $handle.IsCompleted) {
        $decorrido = [int]((Get-Date) - $inicio).TotalSeconds
        $sufixo = " [{0:D2}:{1:D2}]" -f [int]($decorrido / 60), ($decorrido % 60)
        $tam = [Math]::Max(10, $w - $sufixo.Length)
        $linha = -join (1..$tam | ForEach-Object {
            if ((Get-Random -Maximum 5) -eq 0) { " " } else { [string](Get-Random -Maximum 2) }
        })
        $cor = @("Green", "DarkGreen", "Green")[(Get-Random -Maximum 3)]
        Write-Host $linha -ForegroundColor $cor -NoNewline
        Write-Host $sufixo -ForegroundColor Cyan
        Start-Sleep -Milliseconds 150
    }
}

function ConvertTo-Bin([string]$texto) {
    ($texto.ToCharArray() | Select-Object -First 4 | ForEach-Object {
        [Convert]::ToString([int][char]$_, 2).PadLeft(8, "0")
    }) -join " "
}

function Write-Type([string]$texto, [string]$cor = "Green") {
    foreach ($c in $texto.ToCharArray()) {
        Write-Host $c -NoNewline -ForegroundColor $cor
        Start-Sleep -Milliseconds 8
    }
    Write-Host ""
}

function Write-Log([string]$msg) {
    $linha = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
    Add-Content -Path $LogFile -Value $linha
}

function Show-Banner {
    Clear-Host
    Show-Matrix 700
    Write-Host ""
    Write-Host "  01010010 01000101 01010000 01000001 01010010 01001111" -ForegroundColor DarkGreen
    Write-Host "   ____  _____ ____   _    ____   ___    __  __    _  _____ ____  ___ __  __" -ForegroundColor Green
    Write-Host "  |  _ \| ____|  _ \ / \  |  _ \ / _ \  |  \/  |  / \|_   _|  _ \|_ _|\ \/ /" -ForegroundColor Green
    Write-Host "  | |_) |  _| | |_) / _ \ | |_) | | | | | |\/| | / _ \ | | | |_) || |  \  / " -ForegroundColor Green
    Write-Host "  |  _ <| |___|  __/ ___ \|  _ <| |_| | | |  | |/ ___ \| | |  _ < | |  /  \ " -ForegroundColor Green
    Write-Host "  |_| \_\_____|_| /_/   \_\_| \_\\___/  |_|  |_/_/   \_\_| |_| \_\___|/_/\_\" -ForegroundColor Green
    Write-Host ""
    Write-Host ("  HOST: {0}   USER: {1}   {2}" -f $env:COMPUTERNAME, $env:USERNAME, (Get-Date -Format "dd/MM/yyyy HH:mm")) -ForegroundColor DarkGreen
    Write-Host ("  " + ("=" * 70)) -ForegroundColor DarkGreen
}

# ---------- 4. Execucao de comandos ----------
function Invoke-Etapa([string]$nome, [string]$exe, [string[]]$argumentos) {
    Write-Host ""
    Show-Matrix 500
    Write-Host ("  [{0}]" -f (ConvertTo-Bin $nome)) -ForegroundColor DarkGreen
    Write-Type ("  >> EXECUTANDO: {0}" -f $nome)
    Write-Host ("  >> $exe $($argumentos -join ' ')") -ForegroundColor DarkGreen
    Write-Host "  >> (saida completa do comando vai pro log; aguarde...)" -ForegroundColor DarkGreen
    Write-Host ""
    Write-Log "INICIO  $nome  ($exe $($argumentos -join ' '))"

    $saidaLog = Join-Path $LogDir ("saida_{0}_{1}.log" -f ($nome -replace '[^A-Za-z0-9]+', '_'), (Get-Date -Format "HHmmss"))
    $inicio = Get-Date
    $ps = [System.Management.Automation.PowerShell]::Create()
    [void]$ps.AddScript({
        param($exe, $argumentos, $saidaLog)
        & $exe $argumentos *> $saidaLog
        $LASTEXITCODE
    }).AddArgument($exe).AddArgument($argumentos).AddArgument($saidaLog)
    $handle = $ps.BeginInvoke()

    Show-MatrixWhile $handle $inicio
    $codigo = $ps.EndInvoke($handle)[0]
    $ps.Dispose()
    $tempo  = [int]((Get-Date) - $inicio).TotalSeconds

    if ($codigo -eq 0) {
        Write-Type ("  [OK] {0} concluido em {1}s" -f $nome, $tempo) "Green"
    } else {
        Write-Type ("  [!!] {0} terminou com codigo {1} ({2}s)" -f $nome, $codigo, $tempo) "Yellow"
    }
    Write-Log "FIM     $nome  codigo=$codigo  tempo=${tempo}s  saida=$saidaLog"
    return $codigo
}

function Invoke-DISM {
    Invoke-Etapa "DISM CHECKHEALTH"   "DISM.exe" @("/Online", "/Cleanup-Image", "/CheckHealth")   | Out-Null
    Invoke-Etapa "DISM SCANHEALTH"    "DISM.exe" @("/Online", "/Cleanup-Image", "/ScanHealth")    | Out-Null
    Invoke-Etapa "DISM RESTOREHEALTH" "DISM.exe" @("/Online", "/Cleanup-Image", "/RestoreHealth") | Out-Null
}

function Invoke-SFC {
    Invoke-Etapa "SFC SCANNOW" "sfc.exe" @("/scannow") | Out-Null
}

function Invoke-ReparoCompleto {
    Write-Log "=== REPARO COMPLETO ==="
    Invoke-DISM                    # DISM antes
    Invoke-SFC                     # SFC
    Invoke-Etapa "DISM CHECKHEALTH (POS-SFC)" "DISM.exe" @("/Online", "/Cleanup-Image", "/CheckHealth") | Out-Null  # DISM depois
    Write-Host ""
    Write-Type "  >> REPARO DO SISTEMA FINALIZADO. Recomenda-se reiniciar." "Cyan"
}

function Invoke-Disco {
    Write-Log "=== VERIFICACAO DE DISCO ($Drive) ==="
    $codigo = Invoke-Etapa "CHKDSK SCAN" "chkdsk.exe" @("$Drive", "/scan")

    if ($codigo -eq 0) {
        Write-Type ("  >> Nenhum erro encontrado no disco {0}" -f $Drive) "Green"
        return
    }

    Write-Host ""
    Write-Type ("  >> ERROS DETECTADOS NO DISCO {0}" -f $Drive) "Red"
    $r = Read-Host "  Executar reparo (chkdsk /f)? [S/N]"
    if ($r -notmatch "^[sSyY]") { Write-Log "chkdsk /f cancelado pelo usuario"; return }

    Write-Log "INICIO  CHKDSK /F (agendado com resposta $SimKey)"
    Show-Matrix 500
    Write-Type ("  >> EXECUTANDO: CHKDSK {0} /F" -f $Drive)
    # Disco em uso: responde Sim automaticamente para agendar na proxima inicializacao
    cmd.exe /c "echo $SimKey| chkdsk $Drive /f"
    Write-Log "FIM     CHKDSK /F  codigo=$LASTEXITCODE"

    Write-Host ""
    Write-Type "  >> Reparo agendado para a proxima inicializacao." "Yellow"
    $r2 = Read-Host "  Reiniciar o computador agora? (salve o trabalho aberto) [S/N]"
    if ($r2 -match "^[sSyY]") {
        Write-Log "Reinicio solicitado"
        shutdown.exe /r /t 15 /c "Reinicio para reparo de disco (TI)"
        Write-Type "  >> Reiniciando em 15 segundos... (cancelar: shutdown /a)" "Red"
        Start-Sleep 3
        exit
    }
}

# ---------- 5. Menu ----------
do {
    Show-Banner
    Write-Host ""
    Write-Host "  [1] 00000001  Reparo completo   (DISM > SFC > DISM)" -ForegroundColor Green
    Write-Host "  [2] 00000010  Somente DISM      (Check / Scan / Restore)" -ForegroundColor Green
    Write-Host "  [3] 00000011  Somente SFC       (sfc /scannow)" -ForegroundColor Green
    Write-Host "  [4] 00000100  Verificar disco   (chkdsk /scan > /f)" -ForegroundColor Green
    Write-Host "  [5] 00000101  Abrir pasta de logs" -ForegroundColor Green
    Write-Host "  [0] 00000000  Sair" -ForegroundColor DarkGreen
    Write-Host ""
    $op = Read-Host "  root@matrix:~#"

    try {
        switch ($op) {
            "1" { Invoke-ReparoCompleto }
            "2" { Invoke-DISM }
            "3" { Invoke-SFC }
            "4" { Invoke-Disco }
            "5" { Start-Process explorer.exe $LogDir }
            "0" { Show-Matrix 600; Write-Type "  >> DESCONECTADO."; Start-Sleep 1; exit }
            default { Write-Host "  Opcao invalida." -ForegroundColor Red }
        }
    } catch {
        Write-Log "ERRO NAO TRATADO: $_"
        Write-Host ""
        Write-Type ("  [!!] ERRO INESPERADO: {0}" -f $_.Exception.Message) "Red"
    }

    if ($op -in "1", "2", "3", "4") {
        Write-Host ""
        Write-Host "  Log salvo em: $LogFile" -ForegroundColor DarkGreen
        Read-Host "  Pressione ENTER para voltar ao menu"
    } elseif ($op -ne "5") {
        Start-Sleep 1
    }
} while ($true)
