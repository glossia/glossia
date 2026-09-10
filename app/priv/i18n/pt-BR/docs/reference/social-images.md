%{
  title: "Imagens sociais",
  summary:
    "Previsualizações do painel diário, renderização do navegador, armazenamento e limites de tráfego.",
  category: "Referência",
  order: 30
}
---
As páginas do Dashboard anunciam uma imagem de 1200 × 630 via [Open Graph](https://ogp.me/)
e metadados de imagem grande do Twitter. Projetos públicos incluem seu nome, seção,
e logotipo carregado. Contas públicas recebem uma pré-visualização específica da seção. Privadas
contas e configurações pessoais utilizam a marca genérica do Glossia.

## Identidade da imagem e vida útil

O digesto da imagem inclui o conteúdo exibido, a revisão do logotipo do projeto, o modelo,
estilos, fontes, ativo de marca, arquivo de bloqueio de dependências e dia atual em
[Tempo Universal Coordenado](https://www.timeanddate.com/time/aboututc.html).
Alterar qualquer um desses cria um novo endereço. Ordenando os atributos e assinando
à meia-noite mantém o endereço completo estável durante todo o dia.

A carga útil assinada não pode ser alterada pelo visitante. É válida por dois dias,
mas apenas a carga útil do dia atual pode gerar uma imagem ausente. Do dia anterior
as imagens armazenadas permanecem legíveis. Os parâmetros de consulta nunca se tornam chaves de armazenamento de objetos.

As imagens bem-sucedidas são persistidas sob `og/images/<digest>.jpg` no configurado
[Amazon S3](https://aws.amazon.com/s3/)-compatível bucket.
Apenas uma resposta explícita de objeto ausente inicia a geração. Falhas de armazenamento
retornam um erro temporário não cacheável, sem iniciar o Chrome. Um upload deve
ter sucesso antes que uma imagem recém-renderizada seja servida.

## Renderização e limites

A renderização usa o Carta com o BrowseChrome, a mesma pilha que o renderizador de imagens do Tuist.
A piscina supervisionada contém dois navegadores. Cada renderização tem um prazo de 15 segundos;
cada instância de aplicação permite no máximo doze novas renderizações por minuto.
Requisições de imagem armazenada não consomem essa cota.

O Cachex combina requisições simultâneas para a mesma imagem e mantém até 100
imagens por cinco minutos. Um bloqueio consultivo não bloqueante do PostgreSQL impede
diferentes réplicas da aplicação de renderizar a mesma imagem simultaneamente.
Outras réplicas recebem uma falha temporária e podem tentar novamente assim que o objeto existir.

O modelo combina um emblema de seção Noora com o fundo quente da Glossia, em fonte serifada
cabeçalho, acento de gradiente e rodapé sóbrio. Source Serif 4 e Inter estão
empacotados localmente para que as pré-visualizações não dependam de um serviço de fontes. Fontes e imagens
logos estão incorporados. A política de segurança de conteúdo do documento bloqueia scripts e
recursos externos. Os logotipos são carregados apenas do armazenamento de avatar da aplicação
prefixo e são limitados a cinco milhões de bytes, correspondendo aos uploads do projeto.

## Comportamento de resposta

| Resultado | Status | Comportamento do cache |
|---|---|---|
| Imagem armazenada ou recém-persistida | 200 | Público, um dia, imutável |
| Assinatura inválida, expirada ou alterada | 404 | Sem armazenamento |
| Imagem de ontem ausente do armazenamento | 404 | Sem armazenamento |
| Navegador ocupado, falha de renderização ou armazenamento indisponível | 503 | Sem armazenamento; tente novamente após 60 segundos |
| Limite de solicitações de origem excedido | 429 | Sem armazenamento; intervalo de repetição na resposta |

A origem permite trinta solicitações por minuto por endereço de cliente, incluindo
solicitações inválidas.

## Cloudflare

O `social-images-rate-limit.yaml` recurso no repositório de infraestrutura
corresponde `GET` e `HEAD` requisições abaixo `/og/`, incluindo raspadores verificados. Ele
permite vinte requisições por dez segundos por endereço de cliente e Cloudflare
localização. Exceder o limite bloqueia requisições por dez segundos. O geral
as regras de desafio da página pública excluem este caminho, então os rastreadores de imagens nunca precisam
resolver um desafio do navegador.

da Cloudflare [comportamento padrão de cache](https://developers.cloudflare.com/cache/concepts/default-cache-behavior/)
armazena `.jpg` respostas e honora os cabeçalhos do cache de origem. Mantenha a consulta assinada
cadeia na chave padrão de cache. Não aplique uma duração de cache de sobrescrita que
armazena respostas de erro no cache ou ignora `no-store`. A assinatura determinística evita
uma entrada de cache por solicitação de página.

Implante o recurso de infraestrutura junto com o aplicativo. Garanta que a origem
é acessível apenas através do ingress de confiança, já que os endereços do cliente encaminhados
são considerados confiáveis pelo limitador de requisições existente. O pool do navegador e o orçamento de renderização
também limitam as falhas distribuídas e as requisições de origem direta.

## Configuração local

Definir `GLOSSIA_OG_IMAGES=true` para ativar o pool do navegador no ambiente de desenvolvimento. Instale
Google Chrome ou Chromium, construa os ativos com `mix assets.build`, e configure
as variáveis de ambiente de armazenamento de objetos existentes:

- `GLOSSIA_S3_ACCESS_KEY_ID`
- `GLOSSIA_S3_SECRET_ACCESS_KEY`
- `GLOSSIA_S3_ENDPOINT`
- `GLOSSIA_S3_REGION`
- `GLOSSIA_S3_BUCKET`

Execute `mix ecto.setup` e `mix phx.server`. Com o armazenamento configurado, as sementes fornecem
o público `dev/glossia` projeto um logotipo. Inspecte o `og:image` metadados sobre um
página do dashboard para obter o endereço da imagem assinada.