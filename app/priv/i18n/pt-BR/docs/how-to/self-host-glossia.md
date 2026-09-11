%{
  title: "Auto-hospede o Glossia",
  summary:
    "Instale o Glossia no seu próprio cluster Kubernetes com o Helm chart incluído, para que sua equipe execute o sistema operacional de idiomas na sua própria infraestrutura.",
  category: "Tutorial",
  order: 2
}
---
Glossia é de código aberto sob a [Licença O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Você pode auto-hospedar, modificá-lo e executá-lo para o uso interno da sua organização. A única coisa que a licença não permite é oferecê-lo a terceiros como um produto hospedado ou SaaS que compete com o serviço hospedado na glossia.ai.

Este guia leva você de um cluster Kubernetes vazio até uma instância Glossia em execução.

## Antes de começar

Você precisará:

- Um cluster Kubernetes no qual você possa instalar gráficos Helm (v1.28 ou mais recentes)
- `helm` e `kubectl` localmente
- Um domínio ao qual você pode apontar para o ingress do cluster
- Um provedor de OpenID Connect ou um serviço de retransmissão de SMTP para autenticação (Glossia suporta ambos)

O chart Helm inclui Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) e ClickHouse (via o [operador oficial](https://github.com/ClickHouse/clickhouse-operator)) por isso você não precisa de bancos de dados externos. Se preferir trazer os seus, ambos podem ser desabilitados em `values.yaml`.

## Instale os operadores

Instale os operadores que correspondam aos componentes que planeja habilitar. No mínimo:

- [CloudNativePG operador](https://cloudnative-pg.io/documentation/current/installation_upgrade/) para o banco de dados da aplicação
- [operador Kubernetes do ClickHouse](https://github.com/ClickHouse/clickhouse-operator) para o banco de dados analítico
- Um controlador de ingress (por exemplo [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) Se você quiser TLS automático

## Instale o chart do Glossia

Clone o repositório e instale o chart:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## Forneça os segredos do aplicativo

Crie um Segredo do Kubernetes chamado `glossia-app-env` com, pelo menos, estas chaves:

| Chave | Propósito |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Chave de assinatura da sessão do Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Proteção do token Bearer `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Autenticação básica para `/ops` painéis |
| `RELEASE_COOKIE` | Cookie de distribuição do Erlang compartilhado por cada pod |
| `GLOSSIA_SMTP_*` | Configurações de e-mail de saída |

Você pode provisioná-los diretamente, utilize [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), ou conecte o chart ao seu gerenciador de segredos por meio da [External Secrets Operator](https://external-secrets.io/) integração descrita na README do chart.

## O que há no chart

- O aplicativo web do Glossia
- Postgres para dados da aplicação (opcional, ativado por padrão)
- ClickHouse para análise (opcional, ativado por padrão)
- Trabalhadores em segundo plano para tarefas de tradução, que rodam como Jobs do Kubernetes para sobreviver às implantações contínuas.

## O que fazer a seguir

- O [README do Helm chart](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) tem a referência completa de cada valor, além de notas sobre backups, armazenamento de objetos e observabilidade.
- [Configure um provedor de modelo](/docs/how-to/configure-a-model-provider) assim que a instância estiver rodando para que as traduções possam chamar um LLM.
- Relate problemas ou sugira melhorias no [Repositório GitHub](https://github.com/glossia/glossia).