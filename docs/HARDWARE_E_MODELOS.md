# Computador e modelos

O Anonimizador em si é leve: qualquer computador que rode o Chrome ou o Edge abre o arquivo e aplica as regras. O que pede máquina é a **IA local** (a segunda passada que acha nomes). Ela é opcional, mas recomendada.

## Quanto de máquina

| Perfil | Configuração | O que esperar da IA local |
|---|---|---|
| **Só regras** | Qualquer PC com Chrome ou Edge | Sem IA: só regras e padrões |
| **IA no processador** | 16 GB de RAM, processador com AVX2 (praticamente todos dos últimos 10 anos) | Funciona, mas devagar: modelos pequenos (3 a 4 bilhões de parâmetros) são mais práticos |
| **Recomendado** | Placa NVIDIA com 6 a 8 GB de memória (ex.: RTX 3050, 3060, 4050, 4060) e 16 a 32 GB de RAM | Modelo de 8 bilhões de parâmetros rápido: poucos segundos por página |
| **Mac** | Apple Silicon (M1 a M4) com 16 GB ou mais | Modelos de 7 a 8 bilhões rodam bem pela memória unificada |

A memória da placa de vídeo é o principal limite: o modelo e o "contexto" (quanto texto ele lê de uma vez) precisam caber nela. Se não couberem, parte vai para a memória comum e fica bem mais lento.

## Medições reais

Computador de teste: notebook com **Intel Core 7 240H, 32 GB de RAM e NVIDIA GeForce RTX 4050 Laptop (6 GB)**, LM Studio 0.4.18, modelo **Meta Llama 3 8B Instruct Q4_K_M**, contexto de 8.192 tokens.

| Medida | Só processador | Com a placa NVIDIA |
|---|---|---|
| Velocidade de escrita | cerca de 8 tokens/s | 23 a 27 tokens/s |
| Tempo até começar a responder (pedido curto) | cerca de 2,7 s | cerca de 0,4 s |
| Ler um texto de cerca de 5 mil tokens (umas 6 páginas) | cerca de 4 minutos | cerca de 5 segundos |
| Memória da placa em uso | - | cerca de 5,8 GB de 6 GB |
| Achar os nomes de um parágrafo | 10,9 s | 1,9 s |

Na prática, com a placa, a IA do Anonimizador gasta poucos segundos por página. A primeira chamada depois de um tempo parado leva de 20 a 40 segundos a mais, para carregar o modelo.

## Qual modelo usar

Use modelos em formato **GGUF** com quantização **Q4_K_M**: é o melhor equilíbrio entre tamanho, velocidade e qualidade para esta tarefa.

**Testado neste projeto:**

| Modelo | Arquivo | Resultado |
|---|---|---|
| Meta Llama 3 8B Instruct, Q4_K_M | cerca de 4,6 GB | Achou 6 de 6 pessoas num termo de audiência de teste, sem confundir empresa, banco ou cidade com pessoa |

**Alternativas do mesmo porte (não testadas aqui):** modelos "Instruct" de 7 a 9 bilhões de parâmetros mais recentes, como as famílias Llama 3.1, Qwen 2.5 e Qwen 3, e Gemma, costumam ter português melhor e ler textos maiores de uma vez. Cabem em placas de 6 a 8 GB na quantização Q4_K_M.

**Para máquinas mais modestas (sem placa de vídeo ou com pouca RAM):** modelos de 3 a 4 bilhões de parâmetros (por exemplo, Llama 3.2 3B, Qwen 2.5 3B ou Gemma de 4B). São mais rápidos e leves, mas tendem a deixar passar mais nomes.

**Como escolher entre eles:** pegue dois ou três documentos seus típicos (ou versões fictícias), processe com cada modelo e compare a lista "Nomes achados pela IA". Fique com o que achar mais nomes sem marcar coisas que não são pessoas.

Para trocar de modelo, baixe-o no LM Studio e escolha-o na aba **Configurações** do Anonimizador.

## Sobre o tamanho dos trechos

A IA lê o documento em trechos (padrão: 3.500 caracteres, cerca de uma página). Na aba **Configurações** dá para mudar:

- **Trechos menores** deixam a IA mais atenta, mas o processamento demora mais.
- **Trechos maiores** deixam mais rápido, mas exigem um modelo que leia mais texto de uma vez (contexto maior) e podem fazê-la deixar passar nomes.

Com modelos de contexto de 8 mil tokens, mantenha os trechos até uns 12 mil caracteres.
