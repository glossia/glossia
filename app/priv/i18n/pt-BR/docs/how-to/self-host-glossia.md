%{
  title: "Auto-hospede Glossia",
  summary:
    "Instale o Glossia no seu próprio cluster Kubernetes com o chart do Helm incluso, permitindo que sua equipe rode o Sistema Operacional de Linguagem em sua própria infraestrutura.",
  category: "Tutorial",
  order: 2
}
---
O Glossia é de código aberto sob a [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Você pode auto-alojar, modificá-lo e executá-lo para uso interno de sua organização. A única coisa que a licença não permite é oferecê-lo a terceiros como produto hospedado ou SaaS que compete com o serviço hospedado em glossia.ai.

Este guia o leva de um cluster Kubernetes vazio para uma instância do Glossia em execução.

## Antes de começar

Você precisará de:

- Um cluster Kubernetes onde você possa instalar Helm charts (v1.28 ou superior)
- `helm` e `kubectl` localmente
- Um domínio que você pode apontar para o ingress do cluster
- Um provedor OpenID Connect ou relé SMTP para autenticação (o Glossia suporta ambos)

O Helm chart inclui Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) e ClickHouse (via o [operador oficial](https://github.com/ClickHouse/clickhouse-operator)) então você não precisa de bancos de dados externos. Se preferir usar os seus, ambos podem ser desativados em `values.yaml`.

## Instale os operadores

Instale os operadores que correspondam aos componentes que pretende habilitar. No mínimo:

- [CloudNativePG operador](https://cloudnative-pg.io/documentation/current/installation_upgrade/) para o banco de dados da aplicação
- [ClickHouse Kubernetes operador](https://github.com/ClickHouse/clickhouse-operator) para o banco de dados analítico
- Um controlador de Ingress (por exemplo [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) se quiser TLS automático

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

Crie um Kubernetes Secret chamado `glossia-app-env` com pelo menos essas chaves:

| Chave | Propósito |
| --- | |
| `GLOSSIA_SECRET_KEY_BASE` | Chave de assinatura de sessão Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Proteção do token Bearer `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth para `/ops` painéis |
| `RELEASE_COOKIE` | cookie de distribuição do Erlang compartilhado por cada pod |
| `GLOSSIA_SMTP_*` | Configurações de e-mail de saída |

Você pode provisionar esses diretamente, utilize [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), ou conecte o chart ao seu gerenciador de segredos via o [External Secrets Operator](https://external-secrets.io/) integração descrita no README do chart.

## O que há no chart

- A aplicação web Glossia
- Postgres para dados da aplicação (opcional, ativado por padrão)
- ClickHouse para análises (opcional, ativado por padrão)
- Trabalhadores em segundo plano para tarefas de tradução, que rodam como Jobs do Kubernetes para sobreviverem a deploys rotativos.

## Para onde ir em seguida

- O [README do Helm Chart](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) possui a referência completa para cada valor, além de notas sobre backups, armazenamento de objetos e observabilidade.
- [Configure um provedor de modelo](/docs/how-to/configure-a-model-provider) uma vez que a instância estiver em execução para que as traduções possam chamar um LLM.
- Relate problemas ou sugira melhorias em [Repositório GitHub](https://github.com/glossia/glossia).