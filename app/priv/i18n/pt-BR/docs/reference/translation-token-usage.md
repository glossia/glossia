%{
  title: "Uso de tokens de tradução",
  summary: "Entenda a contagem de tokens e os detalhamentos de projeto, idioma e arquivo-fonte.",
  category: "referência",
  section: "translation",
  order: 12
}
---

## Painel de controle

Abra **Configurações → Modelos → Uso de tokens** para ver o uso relatado pelo provedor para traduções generativas. O acesso requer permissão para ler configurações de modelo.

O painel suporta os últimos 7, 30 ou 90 dias corridos, incluindo hoje, em UTC. Os filtros de modelo, projeto e idioma aplicam-se aos totais, gráfico diário e detalhamento. A pesquisa aplica-se apenas às linhas de detalhamento. O período selecionado, dimensão, filtros, pesquisa, ordenação e página são preservados na URL.

## Métricas

| Métrica | Significado |
| --- | --- |
| Tokens de entrada | Entrada processada pelo provedor, incluindo leituras de cache e gravações reportadas. |
| Tokens de saída | Saída relatada pelo provedor, incluindo raciocínio quando o provedor o inclui em sua contagem de saída. |
| Tokens de entrada em cache | Leituras de cache. Um subconjunto de tokens de entrada, sem cobrança adicional no total. |
| Tokens totais | Tokens de entrada mais tokens de saída. |
| Respostas | Respostas com contagens de entrada e saída e um total de tokens positivo. Fallbacks de uso ausente zerados são ignorados. |

As contagens de tokens não são custos monetários. Provedores podem cobrar taxas diferentes para entrada, saída, entrada em cache e gravações de cache.

Cada resposta relatada é contada, incluindo tentativas de validação, tentativas de correção de qualidade e respostas rejeitadas por atingir seu limite de saída. Arquivos pulados e acertos de checkpoint que não chamam um modelo não adicionam uso. Solicitações falhas sem uso não podem ser contadas.

## Dimensões

- **Projetos** agrupa uso por projeto. Use o filtro de projeto para escopar todas as métricas a um único projeto.
- **Idiomas** agrupa por idioma-alvo, como `es` ou `ja`, ao longo de projetos no escopo atual.
- **Arquivos** agrupa por caminho de origem e projeto. O mesmo arquivo de origem traduzido para múltiplos idiomas aparece uma vez; arquivos com o mesmo nome em projetos diferentes permanecem separados.

**Não atribuídos** mantém visíveis solicitações sem metadados de projeto ou caminho de origem. Traduções de repositório fornecem ambos automaticamente. Solicitações de API de conteúdo único podem fornecer `project_id` e `source_path` para atribuição; um ID de projeto fora da conta autenticada é tratado como não atribuído. Metadados opcionais inválidos ou excessivamente grandes são não atribuídos sem descartar as contagens de tokens.

## Cobertura

O uso é coletado de respostas de API-chave e OAuth do ReqLLM, conclusões do Together, e giros locais Codex concluídos. Apenas contagens relatadas pelo provedor são persistidas. Sessões Pi locais e avaliações de modelos de decisão não são incluídas. Traduções históricas não são retroalimentadas ou estimadas. Totais descrevem, portanto, o uso registrado, não uma fatura completa do provedor.

O ledger armazena conta, projeto, identificador e handle do modelo, idioma-alvo, caminho de origem, contagens e timestamp. Ele não armazena prompts, conteúdo traduzido, credenciais ou respostas originais do provedor. Falhas de gravação de uso são logadas sem interromper a tradução.
