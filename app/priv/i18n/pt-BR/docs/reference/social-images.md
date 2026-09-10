%{
  title: "Imagens sociais",
  summary:
    "Pré-visualizações diárias do painel, renderização do navegador, armazenamento e limites de tráfego.",
  category: "referência",
  order: 30
}
---
As páginas do painel anunciam uma imagem de 1200 × 630 através de [Open Graph](https://ogp.me/)
e metadados de imagem grande do Twitter. Projetos públicos incluem seu nome, seção,
e logotipo carregado. Contas públicas recebem uma prévia específica da seção. Contas
e configurações pessoais usam marca genérica da Glossia.

## Identidade e vida útil da imagem

O resumo da imagem inclui o conteúdo exibido, revisão do logotipo do projeto, modelo,
estilos, fontes, ativo de marca, arquivo de bloqueio de dependências e o dia atual em
[Tempo Universal Coordenado](https://www.timeanddate.com/time/aboututc.html).
Alterar qualquer um desses cria um novo endereço. Ordenar os atributos e assinar
à meia-noite mantém o endereço completo estável durante o dia.

A carga assinada não pode ser alterada por um visitante. Ela é válida por dois dias,
mas apenas a carga do dia atual pode gerar uma imagem ausente. de ontem
as imagens armazenadas permanecem legíveis. Parâmetros de consulta nunca se tornam chaves de armazenamento de objetos.

Imagens bem-sucedidas são persistidas sob `og/images/<digest>.jpg` no configurado
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-compatível bucket.
Apenas uma resposta explícita de objeto ausente inicia a geração. Falhas de armazenamento
retornam uma falha temporária não cacheável, sem iniciar o Chrome. Um upload deve
ter sucesso antes que uma imagem recém-renderizada seja servida.

## Renderização e limites

A renderização usa Carta com BrowseChrome, o mesmo stack que o renderizador de imagem do Tuist.
A piscina supervisionada conta com dois navegadores. Cada renderização tem um prazo de 15 segundos;
cada instância de aplicação permite no máximo doze renderizações novas por minuto.
Solicitações de imagem armazenada não consomem essa cota.

Cachex combina solicitações concorrentes para a mesma imagem e mantém até 100
imagens por cinco minutos. Uma trava advisory não bloqueante do PostgreSQL impede
diferentes réplicas de aplicação de renderizar a mesma imagem simultaneamente.
As outras réplicas recebem uma falha temporária e podem tentar novamente uma vez que o objeto exista.

O modelo emparelha um emblema da seção Noora com o fundo quente do Glossia, serif
cabeçalho, acento de gradiente e rodapé discreto. Source Serif 4 e Inter são
incorporados localmente para que as prévias não dependam de um serviço de fontes. Fontes e imagens raster
logos são incorporados. A política de segurança de conteúdo do documento bloqueia scripts e
recursos externos. Os logos são carregados apenas do armazenamento de avatar da aplicação
prefixo e são limitados a cinco milhões de bytes, correspondendo aos uploads do projeto.

## Comportamento de resposta

| Resultado | Status | Comportamento de cache |
|---|---|---|
| Imagem armazenada ou recém-persistida | 200 | Público, um dia, imutável |
| Assinatura inválida, expirada ou alterada | 404 | Sem armazenamento |
| Imagem de ontem ausente no armazenamento | 404 | Sem armazenamento |
| Navegador ocupado, falha de renderização ou armazenamento indisponível | 503 | Sem armazenamento; tente novamente após 60 segundos |
| Limite de requisições da origem excedido | 429 | Sem armazenamento; intervalo de retentativa na resposta |

A origem permite trinta solicitações por minuto por endereço do cliente, incluindo
solicitações inválidas.

## Cloudflare

O `social-images-rate-limit.yaml` recurso no repositório de infraestrutura
corresponde a `GET` e `HEAD` solicitações em `/og/`, incluindo rastreadores verificados. Ele
permite vinte solicitações por dez segundos por endereço do cliente e Cloudflare
localização. Exceder o limite bloqueia solicitações por dez segundos. O geral
as regras do desafio da página pública excluem este caminho, então os rastreadores de imagem nunca precisam
resolver um desafio do navegador.

da Cloudflare [comportamento de cache padrão](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
armazena em cache `.jpg` respostas e respeita os cabeçalhos de cache da origem. Mantenha a consulta assinada
string na chave de cache padrão. Não aplique uma duração de cache que
armazena em cache respostas de erro ou ignora `no-store`. A assinatura determinística evita
uma entrada de cache por requisição de página.

Implante o recurso de infraestrutura junto à aplicação. Garanta que a origem
é acessível apenas através do ingress de confiança, pois os endereços dos clientes encaminhados
são confiados pelo limitador de requisições existente. O pool de navegadores e o orçamento de renderização
também limitam falhas distribuídas e solicitações de origem direta.

## Configuração local

Definir `GLOSSIA_OG_IMAGES=true` para habilitar o pool de navegadores no desenvolvimento. Instale
Google Chrome ou Chromium, construa os ativos com `mix assets.build`, e configure
as variáveis de ambiente de armazenamento de objetos existentes:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Executar `mix ecto.setup` e `mix phx.server`. Com o armazenamento configurado, as sementes fornecem
o público `dev/glossia` o projeto um logotipo. Inspecione o `og:image` metadados em um
página do painel para obter o endereço da imagem assinada.