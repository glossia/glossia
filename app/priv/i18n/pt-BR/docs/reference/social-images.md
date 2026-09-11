%{
  title: "Imagens sociais",
  summary:
    "Pré-visualizações diárias do painel, renderização do navegador, armazenamento e limites de tráfego.",
  category: "referência",
  order: 30
}
---
As páginas do Dashboard exibem uma imagem de 1200 × 630 por meio de [Open Graph](https://ogp.me/)
e dos metadados de imagem grande do Twitter. Projetos públicos incluem seu nome, seção,
e logo carregado. Contas públicas recebem uma pré-visualização específica da seção. Privadas
contas e configurações pessoais usam imagem de marca genérica do Glossia.

## Identidade da imagem e duração

O digesto da imagem inclui o conteúdo exibido, a revisão do logotipo do projeto, o modelo,
estilos, fontes, um ativo de marca, lockfile de dependências e dia atual em
[Horário Universal Coordenado](https://www.timeanddate.com/time/aboututc.html).
Alterar qualquer um desses cria um novo endereço. Ordenar os atributos e assinar
à meia-noite mantém o endereço completo estável ao longo do dia.

A carga assinada não pode ser alterada por um visitante. É válida por dois dias,
mas apenas a carga do dia atual pode gerar uma imagem ausente. Do dia anterior
as imagens armazenadas permanecem legíveis. Parâmetros de consulta nunca se tornam chaves de armazenamento de objetos.

As imagens bem-sucedidas são persistidas sob `og/images/<digest>.jpg` na configuração
[Amazon Simple Storage Service](https://aws.amazon.com/s3/)-bucket compatível.
Apenas uma resposta explícita de objeto ausente inicia a geração. Falhas de armazenamento
retorna um erro temporário não cacheável, sem iniciar o Chrome. Um upload deve
ter sucesso antes que uma imagem recém-renderizada seja servida.

## Renderização e limites

Renderização usa Carta com BrowseChrome, a mesma pilha do renderizador de imagem do Tuist.
O pool supervisionado contém dois navegadores. Cada renderização possui um prazo de 15 segundos;
cada instância da aplicação permite no máximo doze novas renderizações por minuto.
Solicitações de imagem armazenada não consomem essa cota.

Cachex combina solicitações concorrentes para a mesma imagem e mantém até 100
imagens por cinco minutos. Um bloqueio consultivo não bloqueante do PostgreSQL impede
diferentes réplicas de aplicação de renderizar a mesma imagem simultaneamente.
Outras réplicas recebem uma falha temporária e podem retentar assim que o objeto existir.

O template emparelha um badge de seção Noora com o fundo quente do Glossia, serif
cabeçalho, destaque em gradiente e rodapé sóbrio. Source Serif 4 e Inter são
incluídas localmente para que pré-visualizações não dependam de um serviço de fontes. Fontes e raster
os logotipos estão incorporados. A política de segurança de conteúdo do documento bloqueia scripts e
recursos externos. Os logotipos são carregados apenas do armazenamento de avatar da aplicação
prefixo e são limitados a cinco milhões de bytes, correspondendo aos uploads do projeto.

## Comportamento de resposta

| Resultado | Status | Comportamento de cache |
|---|---|---|
| Imagem armazenada ou recém-persistida | 200 | Pública, um dia, imutável |
| Assinatura inválida, expirada ou alterada | 404 | Sem armazenamento |
| Imagem de ontem ausente no armazenamento | 404 | Sem armazenamento |
| Navegador ocupado, falha de renderização ou armazenamento indisponível | 503 | Sem armazenamento; tente novamente após 60 segundos |
| Limite de solicitações de origem excedido | 429 | Sem armazenamento; intervalo de reensaio na resposta |

A origem permite trinta solicitações por minuto por endereço de cliente, incluindo
solicitações inválidas.

## Cloudflare

O `social-images-rate-limit.yaml` recurso no repositório de infraestrutura
corresponde `GET` e `HEAD` solicitações sob `/og/`, incluindo rastreadores verificados. Isso
permite vinte solicitações por dez segundos por endereço do cliente e Cloudflare
localização. Excedendo o limite bloqueia solicitações por dez segundos. O geral
as regras de desafio da página pública excluem este caminho, então os crawlers de imagem nunca precisam de
resolver um desafio do navegador.

do Cloudflare [comportamento padrão de cache](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
faz cache de `.jpg` respostas e respeita os cabeçalhos de cache de origem. Mantenha a consulta assinada
cadeia na chave de cache padrão. Não aplique uma duração de cache sobreposta que
faz cache das respostas de erro ou ignora `no-store`. A assinatura determinística evita
uma entrada de cache por solicitação de página.

Implante o recurso de infraestrutura ao lado do aplicativo. Garanta que a origem
esteja acessível apenas via o ingress de confiança, pois os endereços de clientes encaminhados
são confiáveis pelo limitador de requisições existente. A piscina de navegador e o orçamento de renderização
também limitam as falhas distribuídas e as solicitações de origem direta.

## Configuração local

Definir `GLOSSIA_OG_IMAGES=true` para habilitar a piscina de navegador em desenvolvimento. Instale
o Google Chrome ou o Chromium, construa os ativos com `mix assets.build`. e configure
as variáveis de ambiente de object-storage existentes:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Execute `mix ecto.setup` e `mix phx.server`. Com o armazenamento configurado, as sementes fornecem
o público `dev/glossia` projeto um logotipo. Inspecione os `og:image` metadados de um
página do painel para obter o endereço da imagem assinada.