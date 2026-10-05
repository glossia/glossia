%{
  title: "Uso de tokens de tradução",
  summary:
    "Entenda a contabilidade de tokens e o detalhamento por projeto, idioma e arquivo de origem.",
  category: "reference",
  section: "translation",
  order: 12
}
---
## Painel

Abrir **Configurações → Modelos → Uso de tokens** para visualizar o uso reportado pelo provedor para traduções gerativas. O acesso requer permissão para ler as configurações do modelo.

O painel suporta os últimos 7, 30 ou 90 dias do calendário, incluindo hoje, em UTC. Filtros de modelo, projeto e idioma se aplicam aos totais, ao gráfico diário e ao detalhamento. A pesquisa se aplica apenas às linhas de detalhamento. O período selecionado, dimensão, filtros, pesquisa, ordenação e página são preservados na URL.

## Métricas

| Métrica | Significado |
| --- | --- |
| Tokens de entrada | Tokens processados pelo provedor, incluindo leituras de cache e escritas de cache relatadas. |
| Tokens de saída | Saída relatada pelo provedor, incluindo raciocínio quando o provedor o inclui na sua contagem de saída. |
| Tokens de entrada em cache | Leituras de cache. Um subconjunto de tokens de entrada, sem cobrança adicional no total. |
| Tokens totais | Tokens de entrada mais tokens de saída. |
| Respostas | Respostas com contagens de entrada e saída e total de tokens positivo. Substituições de uso ausente zeradas são ignoradas. |

As contagens de tokens não são custos monetários. Provedores podem cobrar taxas diferentes para entrada, saída, entrada em cache e escritas de cache.

Cada resposta relatada é contabilizada, incluindo tentativas de revalidação, tentativas de correção de qualidade e respostas rejeitadas por atingirem seu limite de saída. Arquivos pulados e hits de checkpoint que não invocam um modelo não adicionam nenhum uso. Requisições falhas sem uso não podem ser contabilizadas.

## Dimensões

- **Projetos** Agrupa o uso por projeto. Use o filtro de projeto para restringir todas as métricas a um único projeto.
- **Idiomas** Agrupa por localidade de destino, como `es` ou `ja`em todos os projetos no escopo atual.
- **Arquivos** Agrupa por caminho de origem e projeto. O mesmo arquivo de origem traduzido para vários idiomas aparece uma vez; arquivos com nome idêntico em projetos diferentes permanecem separados.

**Não atribuído** mantém as requisições sem metadados de projeto ou source-path visíveis. As traduções de repositório fornecem ambos automaticamente. As requisições de API de conteúdo único podem fornecer `project_id` e `source_path` para atribuição; um ID de projeto fora da conta autenticada é tratado como não atribuído. Metadados opcionais inválidos ou excessivamente grandes são classificados como não atribuídos sem descartar as contagens de tokens.

## Cobertura

O uso é coletado das respostas de API-key ReqLLM e OAuth, conclusões Together e turnos de Codex locais finalizados. Apenas as contagens relatadas pelos provedores são persistidas. As sessões locais Pi e as avaliações de modelos de decisão não estão incluídas. Traduções históricas não são preenchidas retroativamente ou estimadas. Portanto, os totais descrevem o uso registrado, não uma fatura completa do provedor.

O registro armazena a conta, o projeto, o identificador e handle do modelo, a localização-alvo, o source path, as contagens e o timestamp. Ele não armazena prompts, conteúdo traduzido, credenciais ou respostas brutas do provedor. Falhas de registro de uso são logadas sem interromper a tradução.