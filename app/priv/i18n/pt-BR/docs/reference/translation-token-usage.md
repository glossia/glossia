%{
  title: "Uso de tokens de tradução",
  summary:
    "Entenda a contabilidade de tokens e os detalhes de projeto, idioma e arquivos de origem.",
  category: "Referência",
  section: "translation",
  order: 12
}
---

## Painel

Acesse **Configurações → Modelos → Uso de tokens** para ver o uso relatado pelo provedor para traduções gerativas. O acesso requer permissão para ler as configurações do modelo.

O painel suporta os últimos 7, 30 ou 90 dias de calendário, incluindo hoje, em UTC. Os filtros de modelo, projeto e idioma são aplicados aos totais, ao gráfico diário e ao detalhamento. A busca se aplica apenas às linhas de detalhamento. O período selecionado, a dimensão, os filtros, a busca, a ordenação e a página são preservados no URL.

## Métricas

| Métrica | Significado |
| --- | --- |
| Tokens de entrada | Entrada processada pelo provedor, incluindo as leituras de cache e as escritas no cache relatadas. |
| Tokens de saída | Saída relatada pelo provedor, incluindo o raciocínio quando o provedor o inclui em sua contagem de saída. |
| Tokens de entrada em cache | Leituras de cache. Um subconjunto de tokens de entrada, que não é uma cobrança adicional no total. |
| Tokens totais | Tokens de entrada somados aos tokens de saída. |
| Respostas | Respostas com contagens de entrada e saída e um total de tokens positivo. Os valores de fallback de uso ausente zerados são ignorados. |

Os contadores de tokens não são custos monetários. Os provedores podem cobrar taxas diferentes para entrada, saída, entrada em cache e escritas no cache.

Cada resposta relatada é contabilizada, incluindo repetições de validação, repetições de correção de qualidade e respostas rejeitadas por atingir seu limite de saída. Arquivos ignorados e pontos de controle que não chamam um modelo não adicionam nenhum uso. Solicitações falhadas sem uso não podem ser contabilizadas.

## Dimensões

- **Projetos** agrupa o uso por projeto. Use o filtro de projeto para escopar todas as métricas para um único projeto.
- **Linguagens** agrupam por localização-alvo, como `es` ou `ja`, em todos os projetos no escopo atual.
- **Arquivos** agrupa por caminho da fonte e projeto. O mesmo arquivo de origem traduzido para múltiplos idiomas aparece uma vez; arquivos com o mesmo nome em projetos diferentes permanecem separados.

**Não atribuídos** mantém visíveis as solicitações sem metadados de projeto ou de caminho da fonte. Traduções de repositório fornecem ambos automaticamente. Solicitações de API de conteúdo único podem fornecer `project_id` e `source_path` para atribuição; um ID de projeto fora da conta autenticada é tratado como não atribuído. Metadados opcionais inválidos ou excessivamente grandes permanecem não atribuídos sem descartar os contadores de tokens.

## Cobertura

O uso é coletado das respostas da Chave API e OAuth do ReqLLM das conclusões do Together e das execuções Codex locais concluídas. Apenas os contadores relatados pelo provedor são persistidos. Sessões Pi locais e avaliações de modelo de decisão não são incluídas. Traduções históricas não são preenchidas retroativamente ou estimadas. Portanto, os totais descrevem o uso registrado, não uma fatura completa do provedor.

O registro armazena a conta, o projeto, o identificador e o nome do modelo, a localização-alvo, o caminho da fonte, os contadores e o timestamp. Ele não armazena prompts, conteúdo traduzido, credenciais ou respostas brutas do provedor. Falhas no registro de uso são registradas sem interromper a tradução.
