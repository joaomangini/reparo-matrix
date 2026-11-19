# 🟢 Reparo Matrix

Script de PowerShell para reparo rápido do Windows (DISM + SFC + CHKDSK), com menu interativo e visual estilo *Matrix*. Feito para uso em TI, quando você precisa rodar os reparos clássicos do Windows sem digitar comando por comando.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white)
![Platform](https://img.shields.io/badge/platform-Windows-0078D6?logo=windows)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Funcionalidades

- **Reparo completo**: `DISM CheckHealth` → `ScanHealth` → `RestoreHealth` → `SFC /scannow` → `DISM CheckHealth` novamente.
- **Somente DISM** ou **somente SFC**, rodando isolados.
- **Verificação de disco** com `chkdsk /scan` e, se encontrar erro, oferece agendar `chkdsk /f` na próxima reinicialização (com opção de reiniciar na hora).
- **Auto-elevação**: se não estiver rodando como admin, já abre o UAC pedindo permissão.
- **Log de cada execução** em `%ProgramData%\ReparoTI\logs`, com saída completa de cada comando salva em arquivo separado.
- Interface no terminal com efeito de "chuva de binário" e cronômetro enquanto o comando roda em segundo plano.

## 🚀 Como usar

1. Baixe o repositório (ou só os arquivos `ReparoMatrix.ps1` e `Abrir Reparo Matrix.bat`).
2. Dê duplo clique em **`Abrir Reparo Matrix.bat`**.
3. Aceite o prompt do UAC (o script precisa de administrador para rodar DISM/SFC/CHKDSK).
4. Escolha uma opção no menu:

```
  [1] Reparo completo   (DISM > SFC > DISM)
  [2] Somente DISM      (Check / Scan / Restore)
  [3] Somente SFC       (sfc /scannow)
  [4] Verificar disco   (chkdsk /scan > /f)
  [5] Abrir pasta de logs
  [0] Sair
```

Também é possível rodar direto via PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\ReparoMatrix.ps1"
```

## 📋 Requisitos

- Windows 10/11
- PowerShell 5.1 ou superior (já vem instalado por padrão)
- Privilégios de administrador

## 📁 Logs

Cada execução gera um log principal e, por etapa, um arquivo com a saída completa do comando:

```
%ProgramData%\ReparoTI\logs\
├── reparo_<HOST>_<DATA_HORA>.log         # resumo (início/fim/código de cada etapa)
└── saida_<ETAPA>_<HORA>.log              # saída bruta do DISM/SFC/CHKDSK
```

Use a opção **[5]** do menu para abrir essa pasta direto.

## ⚠️ Avisos

- O `chkdsk /f` no disco de sistema (`C:`) só pode ser aplicado via reinicialização — o script agenda isso automaticamente e pergunta se você quer reiniciar na hora.
- Rodar os reparos pode levar vários minutos (principalmente o `DISM /RestoreHealth` e o `SFC /scannow`), dependendo do estado do Windows.
- Use em máquinas que você tem autorização para administrar.

## 📄 Licença

MIT — use, modifique e distribua livremente.
