%{
  title: "Imagens sociais",
  summary:
    "Pré-visualizações de links do painel, marca do projeto, atualizações de imagens e disponibilidade.",
  category: "Referências",
  section: "analytics",
  order: 30
}
---
A Glossia gera imagens sociais para links do painel no serviço hospedado.

## Previsualizações de link

As páginas do painel anunciam uma imagem de 1200 × 630 por meio de [Open Graph](https://ogp.me/) e metadados de imagem grande do Twitter. Compartilhar um link em um serviço que lê esses metadados pode exibir a pré-visualização. O serviço de compartilhamento decide quando buscar ou atualizá-la.

Projetos públicos incluem seu nome, seção e logotipo carregado. Contas públicas recebem uma pré-visualização específica da seção. Contas privadas e configurações pessoais usam a marca padrão da Glossia.

## Marca do projeto

Carregue ou substitua o logotipo do projeto na Glossia para alterar a marca utilizada em sua pré-visualização pública. Os logotipos têm limite de cinco milhões de bytes, igual aos uploads do projeto.

Informações privadas do projeto não estão incluídas em uma prévia pública de imagem social. Uma prévia não concede acesso à página do dashboard vinculada.

## Atualizações de imagem

Os endereços da imagem mudam quando o conteúdo exibido, o logotipo do projeto, a versão diária da imagem ou a implementação de renderização do Glossia muda. Imagens bem-sucedidas podem ser armazenadas em cache por um dia. Serviços de compartilhamento podem reter sua própria prévia armazenada em cache, portanto, substituir um logotipo não garante uma atualização imediata em todos os lugares.

O Glossia gerencia a geração de imagens, o armazenamento, as fontes e o cache.

## Disponibilidade

| Resultado | Resposta |
|---|---|
| Imagem disponível | 200 |
| Endereço da imagem inválido ou expirado | 404 |
| Imagem temporariamente indisponível | 503, com um atraso de reintento de 60 segundos |
| Limite de requisições excedido | 429, com um atraso de reintento na resposta |

Se a pré-visualização estiver ausente, abra o painel e compartilhe o link atual. Em caso de falha temporária, reintente após o atraso indicado. Se o problema persistir, entre em contato com o suporte da Glossia.