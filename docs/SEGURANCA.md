# Segurança

O Anonimizador foi desenhado para o advogado que trabalha sozinho e precisa proteger o sigilo dos clientes sem depender de servidores, contas ou equipe de TI. Este documento explica o que ele protege, como, e o que continua sendo responsabilidade de quem usa.

## Princípios

1. **Os documentos não saem do computador.** Leitura, conversão, anonimização e reidentificação rodam no navegador.
2. **Sem internet.** O arquivo funciona offline; as bibliotecas de leitura estão embutidas.
3. **IA só local.** A única comunicação de rede é com o LM Studio em `127.0.0.1` (a própria máquina).
4. **O usuário guarda a chave.** O vínculo entre rótulos e dados reais nunca vai junto com o texto anonimizado.
5. **Revisão humana obrigatória.** A ferramenta reduz o risco, mas não o elimina.

## O que fica onde

| Dado | Onde fica | Observação |
|---|---|---|
| Documento original | No seu disco | A página lê o arquivo, não o copia para lugar nenhum |
| Texto anonimizado | Na memória da página e no arquivo que você baixar | É este o texto pensado para compartilhar |
| Chave (rótulo → dado real) | Na memória da página e no `.json` que você baixar | Some ao fechar a página. Guarde o `.json` em local seguro |
| Configuração da IA (endereço e nome do modelo) | No armazenamento do navegador | Não contém dados de clientes |
| Trechos enviados à IA local | No LM Studio, em `127.0.0.1` | Desligue o registro de conteúdo (veja abaixo) |

## Integridade das bibliotecas embutidas

Os leitores de PDF ([pdf.js](https://github.com/mozilla/pdf.js) 3.11.174) e de Word ([mammoth](https://github.com/mwilliamson/mammoth.js) 1.8.0) são cópias oficiais, embutidas no HTML em base64, sem modificação.

Antes de executar cada um, o Anonimizador calcula o **SHA-512** do conteúdo embutido e compara com o valor publicado pelo cdnjs (o mesmo usado no atributo SRI). Se houver qualquer diferença, a biblioteca **não é executada** e aparece um aviso.

| Biblioteca | SHA-512 esperado (base64) |
|---|---|
| pdf.js 3.11.174 (`pdf.min.js`) | `q+4liFwdPC/bNdhUpZx6aXDx/h77yEQtn4I1slHydcbZK34nLaR3cAeYSJshoxIOq3mjEf7xJE8YWIUHMn+oCQ==` |
| pdf.js 3.11.174 (`pdf.worker.min.js`) | `BbrZ76UNZq5BhH7LL7pn9A4TKQpQeNCHOo65/akfelcIBbcVvYWOFQKPXIrykE3qZxYjmDX573oa4Ywsc7rpTw==` |
| mammoth 1.8.0 (`mammoth.browser.min.js`) | `wuWo/cLB9W5BsZeyTYLuiTwr+FDlvjQC7C6atr+To7Jk92XHWI7WsImJZiruw7C9bnc8Zg7N0ncQI2Q/B4PQYw==` |

O pdf.js é executado com `isEvalSupported: false`, o que fecha a falha conhecida como CVE-2024-4367 (código malicioso escondido em fontes de PDF).

## A IA local

- A IA **só pode acrescentar nomes** à lista de ocultação. Ela não remove nem altera o que as regras encontram.
- Um nome sugerido pela IA só é aceito se **aparecer de fato no trecho** lido, o que impede que ela invente.
- A resposta da IA é obrigada a vir num formato JSON fixo (recurso de saída estruturada do LM Studio).
- Termos jurídicos comuns, órgãos públicos e palavras curtas são descartados.
- A lista de nomes achados pela IA aparece para revisão, e você pode desmarcar qualquer um.

### Configuração segura do LM Studio

- **Escutar só em `127.0.0.1`.** Nunca habilite o servidor para a rede local neste uso.
- **Desligar `logSensitiveData`.** Por padrão, o LM Studio pode gravar o texto das mensagens em `.lmstudio/server-logs`, sem criptografia. Passo a passo em [LM_STUDIO.md](LM_STUDIO.md#5-desligar-a-gravação-do-conteúdo-nos-registros).
- **Apagar os registros antigos** depois de desligar a gravação.

## Modelo de ameaça

**O que o Anonimizador ajuda a evitar:**
- Exposição de dados de clientes a serviços de IA na nuvem e aos seus registros, treinamentos e vazamentos.
- Envio acidental de nome, CPF ou endereço ao pedir ajuda numa minuta.
- Execução de uma biblioteca adulterada dentro da página (pela conferência de integridade).

**O que ele não resolve:**
- **Identificação pelo contexto.** Um fato muito específico (acidente numa data e local exatos, valor incomum, empresa pequena e conhecida) pode identificar a pessoa mesmo sem o nome.
- **Computador comprometido.** Se a máquina tiver vírus ou acesso remoto indevido, nada que roda nela está protegido.
- **Escape de dados atípicos.** Apelidos raros, sobrenomes sozinhos fora de contexto, números em formatos incomuns e PDFs digitalizados (sem texto) podem passar.
- **Guarda da chave.** Quem tiver o `.json` da chave e o texto anonimizado consegue reverter tudo.

## Boas práticas para o advogado

1. **Revise a prévia inteira** antes de enviar qualquer texto para fora do computador.
2. **Use "Outros nomes para ocultar"** para partes, testemunhas e terceiros que você já conhece.
3. **Marque "Número do processo"** quando o número, somado a outros dados públicos, puder identificar o cliente.
4. **Guarde as chaves fora da pasta sincronizada** com nuvens públicas, ou num local com criptografia, e apague-as quando o caso terminar.
5. **Nunca envie a chave junto com o texto anonimizado.**
6. **Confira as configurações da IA na nuvem** que você usar (por exemplo, se os dados podem ser usados para treinar modelos).
7. **Registre o fluxo** na política de privacidade e de tratamento de dados do escritório (LGPD).

## Natureza jurídica

Como o usuário guarda a chave, o resultado é **pseudonimização** (LGPD, art. 13, § 4º), e não anonimização em sentido estrito: para o escritório, os dados continuam pessoais. Para quem recebe apenas o texto, sem a chave, a reversão não é possível pelos meios da ferramenta.

## Relatar um problema de segurança

Se você encontrar uma falha (um tipo de dado que escapa, um comportamento inesperado da página), abra uma *issue* no repositório **sem incluir dados reais**: substitua nomes e números por equivalentes fictícios no mesmo formato.
