%{
  title: "Imagens de redes sociais",
  summary:
    "Pré-visualizações de links no painel, marca do projeto, atualizações de imagem e disponibilidade.",
  category: "Referência",
  section: "analytics",
  order: 30
}
---

Glossia gera imagens sociais para links do dashboard em seu serviço hospedado.

## Pré-visualizações de link

As páginas do dashboard anunciam uma imagem de 1200 × 630 por meio do [Open Graph](https://ogp.me/) e dos metadados de imagem grande do Twitter. Compartilhar um link em um serviço que lê esses metadados pode exibir a pré-visualização. O serviço de compartilhamento decide quando buscar ou atualizá-la.

Projetos públicos incluem seu nome, seção e logotipo carregado. Contas públicas recebem uma pré-visualização específica da seção. Contas privadas e configurações pessoais usam marcação genérica do Glossia.

## Marcação do projeto

Carregue ou substitua o logotipo do projeto no Glossia para alterar a marcação usada em sua pré-visualização pública. Os logotipos são limitados a cinco milhões de bytes, igual ao limite dos uploads do projeto.

Informações do projeto privado não estão incluídas em uma pré-visualização social pública. Uma pré-visualização não concede acesso à página do dashboard vinculada.

## Atualizações de imagem

Os endereços das imagens mudam quando o conteúdo exibido, logotipo do projeto, versão diária da imagem ou implementação de renderização do Glossia muda. Uma imagem bem-sucedida pode ser armazenada em cache por um dia. Serviços de compartilhamento podem reter sua própria pré-visualização em cache, então substituir um logotipo não garante uma atualização imediata em toda parte.

O Glossia gerencia a geração de imagens, armazenamento, fontes e cache.

## Disponibilidade

| Resultado | Resposta |
|---|---|
| Imagem disponível | 200 |
| Endereço de imagem inválido ou expirado | 404 |
| Imagem temporariamente indisponível | 503, com um atraso de nova tentativa de 60 segundos |
| Limite de solicitações excedido | 429, com um atraso de nova tentativa na resposta |

Se uma pré-visualização estiver faltando, abra a página do dashboard e compartilhe o link atual dela. Para uma falha temporária, tente novamente após o atraso indicado. Se o problema persistir, entre em contato com o suporte do Glossia.
