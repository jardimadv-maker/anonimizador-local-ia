# IA local com o LM Studio

O Anonimizador usa um modelo de linguagem rodando **no seu computador**, servido pelo [LM Studio](https://lmstudio.ai), um programa gratuito para Windows, macOS e Linux. Nada é enviado para fora: a página conversa com o LM Studio pelo endereço `http://127.0.0.1:1234`, que é a própria máquina.

> **No Windows, existe um atalho:** depois de instalar e abrir o LM Studio uma vez, dê dois cliques no [Configurar_IA_Local.bat](https://github.com/jardimadv-maker/anonimizador-local-ia/releases/latest/download/Configurar_IA_Local.bat). Ele faz automaticamente os passos 2 a 6 deste guia (motor da placa de vídeo, modelo, servidor seguro e teste). Este guia continua útil para Mac, Linux e para conferir ou ajustar à mão.

Este guia foi escrito e testado com o **LM Studio 0.4.18 no Windows 11**. Em outras versões os nomes de menus podem mudar um pouco; os comandos `lms` (linha de comando que acompanha o LM Studio) costumam ser os mesmos.

## 1. Instalar

1. Baixe o LM Studio em [lmstudio.ai](https://lmstudio.ai) e instale.
2. Abra o programa uma vez, para ele terminar a configuração inicial.

## 2. Usar a placa de vídeo (o ajuste que mais faz diferença)

O LM Studio roda os modelos por um "motor" (runtime). Se ele estiver usando só o processador numa máquina que tem placa de vídeo, tudo fica muito mais lento.

| Sua máquina | Motor a escolher |
|---|---|
| Placa NVIDIA (GeForce RTX, por exemplo) | `llama.cpp` **CUDA** (CUDA 12) |
| Placa AMD ou Intel Arc | `llama.cpp` **Vulkan** |
| Mac com Apple Silicon (M1 a M4) | Metal / MLX (padrão no Mac) |
| Sem placa de vídeo dedicada | `llama.cpp` CPU (AVX2) |

**Pela linha de comando (Windows, PowerShell):**

```powershell
# lista os motores instalados e mostra qual está selecionado
& "$env:USERPROFILE\.lmstudio\bin\lms.exe" runtime ls

# confere se a placa foi detectada pelo motor selecionado
& "$env:USERPROFILE\.lmstudio\bin\lms.exe" runtime survey
```

Se o `survey` disser **"No GPUs detected"** e você tem placa NVIDIA, selecione o motor CUDA (use o nome exato que aparece no `runtime ls`):

```powershell
& "$env:USERPROFILE\.lmstudio\bin\lms.exe" runtime select "llama.cpp-win-x86_64-nvidia-cuda12-avx2@<versao>"
```

Também dá para escolher pela tela do LM Studio, na área de configurações de **Runtime**.

> **Atenção:** atualizações automáticas do LM Studio já trocaram o motor de volta para "só processador". Se a IA ficar lenta de repente (uma resposta curta levando uns 20 segundos), confira o motor de novo.

## 3. Baixar um modelo

O Anonimizador foi testado com o **Meta Llama 3 8B Instruct, quantização Q4_K_M** (arquivo de cerca de 4,6 GB). Para escolher outro conforme o seu computador, veja [HARDWARE_E_MODELOS.md](HARDWARE_E_MODELOS.md).

- **Pela tela:** abra a busca de modelos do LM Studio (lupa / "Discover"), procure por `Meta-Llama-3-8B-Instruct`, escolha a versão **GGUF Q4_K_M** e baixe.
- **Pela linha de comando:** `lms get` permite buscar e baixar modelos.

## 4. Ligar o servidor local

O Anonimizador precisa do servidor do LM Studio ligado, com estas configurações:

| Configuração | Valor | Por quê |
|---|---|---|
| Porta | `1234` | É o endereço padrão que o Anonimizador procura (dá para mudar na aba Configurações dele) |
| Escutar na rede local | **desligado** (só `127.0.0.1`) | Ninguém da rede consegue usar a sua IA nem ver o que passa por ela |
| CORS | **ligado** | Permite que a página aberta no navegador converse com o servidor |
| Carregamento automático de modelo (Just-in-Time) | ligado | O modelo é carregado quando a página pede e descarregado depois de um tempo parado |
| Registrar conteúdo das mensagens (log sensitive data) | **desligado** | Veja o item 5 |

**Pela tela:** na área de desenvolvedor / servidor local do LM Studio, ligue o servidor e ajuste as opções acima. Se existir a opção de iniciar o servidor junto com o programa, ligue-a.

**Pela linha de comando:**

```powershell
& "$env:USERPROFILE\.lmstudio\bin\lms.exe" server start --port 1234 --bind 127.0.0.1 --cors
& "$env:USERPROFILE\.lmstudio\bin\lms.exe" server status
```

Nunca use `--bind 0.0.0.0` neste uso: isso abriria a IA (e o conteúdo dos documentos) para a rede.

## 5. Desligar a gravação do conteúdo nos registros

O LM Studio pode gravar o **texto completo das mensagens** nos registros do servidor, em arquivos comuns, sem criptografia (no Windows, em `%USERPROFILE%\.lmstudio\server-logs`). Para um advogado, isso significa trechos de processos guardados fora de qualquer controle.

Para desligar:

1. Feche o LM Studio.
2. Abra o arquivo `%USERPROFILE%\.lmstudio\.internal\http-server-config.json` num editor de texto.
3. Mude `"logSensitiveData": true` para `"logSensitiveData": false` e salve.
4. Abra o LM Studio de novo (ou reinicie o servidor com `lms server stop` e `lms server start ...`).

Se o seu LM Studio tiver essa opção na tela de configurações do servidor, pode desligar por lá.

**Os registros antigos continuam lá.** Apague as pastas de meses dentro de `server-logs` quando quiser. O LM Studio cria arquivos novos, já sem o conteúdo das mensagens.

**Como conferir:** envie pelo Anonimizador um texto fictício com uma palavra única (por exemplo `TESTE918273`) e procure essa palavra nos arquivos de `server-logs`. Ela não deve aparecer.

## 6. Conferir no Anonimizador

1. Abra o `Anonimizador_IA.html`.
2. O selo no topo deve mostrar **"IA local: conectada (nome-do-modelo)"**.
3. Na aba **Configurações**, clique em **Testar conexão**. Na primeira vez, o LM Studio leva de 20 a 40 segundos para carregar o modelo; depois, a resposta vem em poucos segundos.

## Problemas comuns

| Sintoma | Causa provável | O que fazer |
|---|---|---|
| "IA local: desligada" | Servidor desligado ou porta diferente | Ligue o servidor (item 4) ou ajuste o endereço na aba Configurações |
| Selo desligado mesmo com o servidor ligado | CORS desligado | Ligue o CORS (item 4) |
| IA muito lenta | Motor de processador numa máquina com placa | Selecione o motor da placa (item 2) |
| Primeira resposta demora uns 30 s | Modelo sendo carregado | Normal: só acontece depois de um tempo sem uso |
| Erro de memória ao carregar | Modelo grande demais para a placa | Use um modelo menor ou com contexto menor (veja [HARDWARE_E_MODELOS.md](HARDWARE_E_MODELOS.md)) |
| Download do modelo falha com "429" ou "Too Many Requests" | O Hugging Face limita muitos downloads seguidos da mesma rede (comum quando várias pessoas baixam juntas na mesma rede) | Espere de 10 a 30 minutos e rode o configurador de novo, ou baixe de outra rede |
