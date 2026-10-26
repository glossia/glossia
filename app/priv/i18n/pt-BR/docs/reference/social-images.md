%{
  title: "Imagens sociais",
  summary:
    "Pré-visualizações de links do painel, identidade do projeto, atualizações de imagem e disponibilidade.",
  category: "referência",
  section: "analytics",
  order: 30
}
---

O Glossia gera imagens sociais para links do painel em seu serviço hospedado.

## Previsualizações de link

As páginas do painel anunciam uma imagem de 1200 × 630 por meio de metadados do [Open Graph](https://ogp.me/) e Twitter para imagens grandes. Compartilhar um link em um serviço que lê esses metadados pode exibir a prévia. O serviço de compartilhamento decide quando buscá-la ou atualizá-la.

Projetos públicos incluem seu nome, seção e logotipo carregado. Contas públicas recebem uma prévia específica da seção. Contas privadas e configurações pessoais usam uma marca genérica do Glossia.

## Marca do projeto

Carregue ou substitua o logotipo do projeto no Glossia para alterar a marca usada em sua prévia pública. Logotipos são limitados a cinco milhões de bytes, compatível com os carregamentos de projeto.

Informações privadas do projeto não são incluídas em uma prévia de imagem social pública. Uma prévia não concede acesso à página do painel vinculada.

## Atualizações de imagem

Os endereços de imagem mudam quando o conteúdo exibido, o logotipo do projeto, a versão diária de imagem ou a implementação de renderização do Glossia mudar. Uma imagem bem-sucedida pode ser armazenada em cache por um dia. Serviços de compartilhamento podem reter sua própria prévia em cache; portanto, substituir um logotipo não garante uma atualização imediata em todos os lugares.

O Glossia gerencia a geração de imagem, armazenamento, fontes e cache.

## Disponibilidade

| Resultado | Resposta |
|---|---|
| Imagem disponível | 200 |
| Endereço de imagem inválido ou expirado | 404 |
| Imagem temporariamente indisponível | 503, com um atraso de 60 segundos para nova tentativa |
| Limite de requisições excedido | 429, com um atraso de nova tentativa na resposta |

Se a prévia estiver ausente, abra a página do painel e compartilhe o link atual. Para uma falha temporária, tente novamente após o atraso indicado. Se o problema persistir, entre em contato com o suporte do Glossia.
