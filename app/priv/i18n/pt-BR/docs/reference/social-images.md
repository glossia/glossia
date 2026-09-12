%{
  title: "Imagens sociais",
  summary:
    "Pré-visualizações do painel diário, renderização do navegador, armazenamento e limites de tráfego.",
  category: "Referência",
  order: 30
}
---
As páginas do Dashboard exibem uma imagem de 1200 × 630 através de [Open Graph](https://ogp.me/)
e metadados de imagem grande do Twitter. Projetos públicos incluem seu nome, seção,
e logo enviado. Contas públicas recebem uma pré-visualização específica da seção. Privadas
contas e configurações pessoais usam a marca genérica do Glossia.

## Identidade e tempo de vida da imagem

O resumo da imagem inclui o conteúdo exibido, revisão do logotipo do projeto, modelo,
estilos, fontes, ativo de marca, arquivo de bloqueio de dependências e dia atual em
[Tempo Universal Coordenado](https://www.timeanddate.com/time/aboututc.html).
Alterar qualquer um desses cria um novo endereço. Ordenar os atributos e assinar
à meia-noite mantém o endereço completo estável durante o dia.

A carga assinada não pode ser alterada por um visitante. Ela é válida por dois dias,
mas apenas a carga do dia atual pode gerar uma imagem ausente. A de ontem
armazenadas permanecem legíveis. Os parâmetros de consulta nunca se tornam chaves de armazenamento de objetos.

As imagens bem-sucedidas são persistidas sob `og/images/<digest>.jpg` no configurado
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-bucket compatível.
Apenas uma resposta explícita de objeto ausente inicia a geração. Falhas de armazenamento
retornam uma falha temporária não cacheável, sem iniciar o Chrome. Um upload deve
ter sucesso antes que uma imagem recém-renderizada seja servida.

## Renderização e limites

A renderização usa Carta com BrowseChrome, a mesma pilha que o renderizador de imagem do Tuist.
O pool supervisionado contém dois navegadores. Cada renderização tem um limite de 15 segundos;
cada instância de aplicação permite no máximo doze novas renderizações por minuto.
Requisições de imagem armazenada não consomem essa cota.

O Cachex combina requisições concorrentes para a mesma imagem e retém até 100
imagens por cinco minutos. Uma trava de conselho não bloqueante do PostgreSQL impede
diferentes réplicas de aplicação de renderizar a mesma imagem simultaneamente.
Outras réplicas recebem uma falha temporária e podem tentar novamente uma vez que o objeto exista.

O modelo associa um badge da seção Noora com o fundo quente da Glossia, serif
cabeçalho, acento de gradiente e rodapé sóbrios. Source Serif 4 e Inter são
empacotados localmente para que pré-visualizações não dependam de um serviço de fontes. Fontes e
logotipos estão incorporados. A política de segurança de conteúdo do documento bloqueia scripts e
recursos externos. Logos são carregados apenas do armazenamento de avatares da aplicação
prefixo e são limitados a cinco milhões de bytes, correspondendo às cargas de projeto.

## Comportamento de resposta

| Resultado | Status | Comportamento de cache |
|---|---|---|
| Imagem armazenada ou recém persistida | 200 | Público, um dia, imutável |
| Assinatura inválida, expirada ou alterada | 404 | Sem armazenamento |
| Imagem de ontem ausente do armazenamento | 404 | Sem armazenamento |
| Navegador ocupado, falha de renderização ou armazenamento indisponível | 503 | Sem armazenamento; tente novamente após 60 segundos |
| Limite de solicitações da origem excedido | 429 | Sem armazenamento; intervalo de repetição na resposta |

A origem permite trinta solicitações por minuto por endereço de cliente, incluindo
requisições inválidas.

## Cloudflare

O `social-images-rate-limit.yaml` recurso no repositório de infraestrutura
corresponde `GET` e `HEAD` solicitações abaixo de `/og/`, incluindo crawlers verificados. Ele
permite vinte solicitações por dez segundos por endereço do cliente e Cloudflare
localização. Exceder o limite bloqueia solicitações por dez segundos. O geral
as regras do desafio da página pública excluem este caminho, então os crawlers de imagem nunca precisam
resolver um desafio do navegador.

da Cloudflare [comportamento padrão de cache](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
armazena em cache `.jpg` respostas e respeita cabeçalhos de cache da origem. Mantenha a consulta assinada
string na chave padrão de cache. Não aplique uma duração de cache de substituição que
armazena em cache respostas de erro ou ignora `no-store`. A assinatura determinística evita
uma entrada de cache por solicitação de página.

Implante o recurso de infraestrutura junto com o aplicativo. Garanta que a origem
é acessível apenas pelo ingresso confiável, pois os endereços do cliente encaminhados
são confiados pelo limitador de solicitações existente. A piscina de navegadores e o orçamento de renderização
também restringem falhas distribuídas e solicitações de origem direta.

## Configuração local

Definir `GLOSSIA_OG_IMAGES=true` para habilitar a piscina de navegadores no desenvolvimento. Instale
Google Chrome ou Chromium, construa ativos com `mix assets.build`, e configure
as variáveis de ambiente de armazenamento de objetos existentes:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Execute `mix ecto.setup` e `mix phx.server`. Com o armazenamento configurado, as sementes fornecem
o público `dev/glossia` projeto um logotipo. Inspecione o `og:image` metadados de um
Página do painel para obter o endereço da imagem assinada.