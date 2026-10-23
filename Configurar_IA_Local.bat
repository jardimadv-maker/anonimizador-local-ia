<# : inicio em lote (cmd) - o restante do arquivo e PowerShell
@echo off
title Configurar IA local para o Anonimizador
powershell -NoProfile -ExecutionPolicy Bypass -Command "$env:CONFIG_IA_ARQ='%~f0'; Invoke-Expression ([System.IO.File]::ReadAllText('%~f0'))"
echo.
pause
exit /b
#>

# ================================================================
# Configurador da IA local (LM Studio) para o Anonimizador Local com IA
# - Confere se o LM Studio esta instalado
# - Usa a placa de video NVIDIA, se houver
# - Baixa um modelo adequado ao computador (so se ainda nao houver nenhum, e com confirmacao)
# - Liga o servidor local com configuracao segura: so neste computador (127.0.0.1),
#   CORS ligado e SEM gravar o conteudo das mensagens nos registros
# - Faz um teste rapido
# Nada e enviado a lugar nenhum alem do download do modelo (Hugging Face) quando voce confirmar.
# Textos sem acento de proposito: o Prompt de Comando do Windows nem sempre mostra acentos.
# ================================================================
# 'Continue': avisos que o lms escreve na saida de erro nao devem interromper o assistente
$ErrorActionPreference = 'Continue'
function Titulo($t) { Write-Host ''; Write-Host "== $t ==" -ForegroundColor Cyan }
function Ok($t) { Write-Host "  [OK] $t" -ForegroundColor Green }
function Aviso($t) { Write-Host "  [!] $t" -ForegroundColor Yellow }
function Erro($t) { Write-Host "  [X] $t" -ForegroundColor Red }

$MODELO_8B = 'https://huggingface.co/lmstudio-community/Meta-Llama-3-8B-Instruct-GGUF'
$MODELO_3B = 'https://huggingface.co/lmstudio-community/Llama-3.2-3B-Instruct-GGUF'
$lms = Join-Path $env:USERPROFILE '.lmstudio\bin\lms.exe'
$cfgServidor = Join-Path $env:USERPROFILE '.lmstudio\.internal\http-server-config.json'

Write-Host 'Configurador da IA local - Anonimizador Local com IA' -ForegroundColor White
Write-Host 'Este assistente prepara o LM Studio para o Anonimizador. Pode fechar a janela a qualquer momento.'

# ---------- 1. LM Studio ----------
Titulo '1. LM Studio'
if (-not (Test-Path $lms)) {
  Erro 'O LM Studio nao foi encontrado neste computador.'
  Write-Host '  1) Instale o LM Studio (gratuito) pelo site que vou abrir agora: https://lmstudio.ai'
  Write-Host '  2) Abra o LM Studio uma vez e espere a tela inicial carregar.'
  Write-Host '  3) Feche e rode este configurador de novo.'
  Start-Process 'https://lmstudio.ai'
  return
}
Ok 'LM Studio encontrado.'

# ---------- 2. Computador ----------
Titulo '2. Seu computador'
$ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$placas = @(Get-CimInstance Win32_VideoController | ForEach-Object { $_.Name })
$nvidia = $placas | Where-Object { $_ -match 'NVIDIA' } | Select-Object -First 1
$vramGB = 0
if ($nvidia) {
  try { $vramGB = [math]::Round(([int]((& nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits) | Select-Object -First 1)) / 1024) } catch { $vramGB = 0 }
}
Write-Host "  Memoria RAM: $ramGB GB"
Write-Host ('  Placa(s) de video: ' + ($placas -join ', '))
if ($nvidia) { Write-Host "  Memoria da placa NVIDIA: $(if ($vramGB) { "$vramGB GB" } else { 'nao identificada' })" }
if ($ramGB -lt 8) { Aviso 'Menos de 8 GB de RAM: a IA local tende a ficar muito lenta. O Anonimizador funciona sem ela, so com as regras.' }

# ---------- 3. Motor (placa de video) ----------
Titulo '3. Motor da IA'
$survey = (& $lms runtime survey 2>&1 | Out-String)
if ($survey -match 'NVIDIA|Apple|Radeon|AMD|Arc') {
  Ok 'O LM Studio ja esta usando a placa de video.'
} elseif ($nvidia) {
  $motores = (& $lms runtime ls 2>&1 | Out-String) -split "`r?`n" | ForEach-Object { ($_ -split '\s+')[0] } | Where-Object { $_ -match 'cuda' }
  $cuda = $motores | Sort-Object { [version](($_ -split '@')[1]) } -Descending | Select-Object -First 1
  if ($cuda) {
    & $lms runtime select $cuda | Out-Null
    Ok "Motor da placa NVIDIA selecionado ($cuda)."
  } else {
    Aviso 'Nao achei o motor CUDA (NVIDIA) instalado. No LM Studio, abra as configuracoes de Runtime e instale o "llama.cpp CUDA".'
  }
} else {
  Aviso 'Nenhuma placa de video compativel encontrada: a IA vai rodar no processador (mais devagar).'
}

# ---------- 4. Modelo ----------
Titulo '4. Modelo de IA'
$lista = (& $lms ls 2>&1 | Out-String)
$temLLM = $false
$secao = ''
foreach ($linha in ($lista -split "`r?`n")) {
  if ($linha -match '^\s*LLM\s') { $secao = 'llm'; continue }
  if ($linha -match '^\s*EMBEDDING\s') { $secao = 'emb'; continue }
  if ($secao -eq 'llm' -and $linha.Trim()) { $temLLM = $true }
}
if ($temLLM) {
  Ok 'Ja existe um modelo de linguagem baixado. Nada para baixar.'
} else {
  $grande = ($vramGB -ge 6) -or ($ramGB -ge 16)
  $url = if ($grande) { $MODELO_8B } else { $MODELO_3B }
  $nome = if ($grande) { 'Meta Llama 3 8B Instruct (cerca de 5 GB) - recomendado para o seu computador' } else { 'Llama 3.2 3B Instruct (cerca de 2 GB) - mais leve, adequado ao seu computador' }
  Write-Host "  Modelo sugerido: $nome"
  $resp = Read-Host '  Baixar agora? Pode levar varios minutos. (S/N)'
  if ($resp -notmatch '^[sSyY]') { Aviso 'Download nao feito. Rode este configurador de novo quando quiser.'; return }
  & $lms get $url -y
  if ($LASTEXITCODE -ne 0) { Erro 'O download nao terminou. Verifique a internet e rode de novo.'; return }
  Ok 'Modelo baixado.'
}

# ---------- 5. Servidor local seguro ----------
Titulo '5. Servidor local'
& $lms server start --port 1234 --bind 127.0.0.1 --cors 2>&1 | Out-Null
if (Test-Path $cfgServidor) {
  $cfg = Get-Content $cfgServidor -Raw | ConvertFrom-Json
  $mudou = $false
  foreach ($par in @(@('logSensitiveData', $false), @('cors', $true), @('networkInterface', '127.0.0.1'), @('justInTimeModelLoading', $true), @('autoStartOnLaunch', $true))) {
    $campo, $valor = $par
    if ($cfg.PSObject.Properties.Name -contains $campo) { if ($cfg.$campo -ne $valor) { $cfg.$campo = $valor; $mudou = $true } }
    else { $cfg | Add-Member -NotePropertyName $campo -NotePropertyValue $valor; $mudou = $true }
  }
  if ($mudou) {
    [System.IO.File]::WriteAllText($cfgServidor, ($cfg | ConvertTo-Json), (New-Object System.Text.UTF8Encoding($false)))
    & $lms server stop 2>&1 | Out-Null
    & $lms server start --port 1234 --bind 127.0.0.1 --cors 2>&1 | Out-Null
  }
  Ok 'Servidor configurado: so neste computador, CORS ligado, sem gravar o conteudo das mensagens.'
} else {
  Aviso 'Nao encontrei o arquivo de configuracao do servidor. No LM Studio, desligue a opcao de registrar o conteudo das mensagens (log sensitive data).'
}

# ---------- 6. Teste ----------
Titulo '6. Teste'
try {
  $modelo = ((Invoke-RestMethod 'http://127.0.0.1:1234/v1/models' -TimeoutSec 15).data | Where-Object { $_.id -notmatch 'embed' } | Select-Object -First 1).id
  Write-Host "  Testando com $modelo (na primeira vez o LM Studio leva de 20 a 60 segundos para carregar)..."
  $corpo = @{ model = $modelo; messages = @(@{ role = 'user'; content = 'Responda apenas: OK' }); max_tokens = 5; temperature = 0 } | ConvertTo-Json -Depth 4
  $t0 = Get-Date
  $r = Invoke-RestMethod 'http://127.0.0.1:1234/v1/chat/completions' -Method Post -ContentType 'application/json' -Body $corpo -TimeoutSec 300
  Ok ("A IA respondeu em {0:N0} segundos." -f ((Get-Date) - $t0).TotalSeconds)
  Write-Host ''
  Write-Host 'PRONTO. Abra o Anonimizador_IA.html: o selo no topo deve mostrar "IA local: conectada".' -ForegroundColor Green
  Write-Host 'Nas proximas vezes, basta abrir o LM Studio antes de usar o Anonimizador (ou rodar este configurador de novo).'
} catch {
  Erro ('O teste falhou: ' + $_.Exception.Message)
  Write-Host '  Abra o LM Studio, confira se o servidor local esta ligado e rode este configurador de novo.'
}
