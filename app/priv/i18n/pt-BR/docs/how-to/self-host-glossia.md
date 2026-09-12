%{
  title: "Autohospedagem do Glossia",
  summary:
    "Instale o Glossia no seu próprio cluster Kubernetes com o Helm chart embutido, para que sua equipe execute o Sistema Operacional de Idiomas na sua própria infraestrutura.",
  category: "Guia",
  order: 2
}
---
Glossia é de código aberto sob o [Licença O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Você pode auto-hospedá-la, modificá-la e executá-la para uso interno da sua organização. A única coisa que a licença não permite é oferecê-la a terceiros como um produto hospedado ou SaaS que concorre com o serviço hospedado em glossia.ai.

Este guia o levará de um cluster Kubernetes vazio até uma instância de Glossia em execução.

## Antes de começar

Você precisará de:

- Um cluster Kubernetes onde pode instalar charts do Helm (v1.28 ou superior)
- `helm` e `kubectl` localmente
- Um domínio que você pode apontar para o Ingress do cluster
- Um provedor OpenID Connect ou servidor de relé SMTP para autenticação (Glossia suporta ambos)

O Helm chart inclui Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) e ClickHouse (via o [operador oficial](https://github.com/ClickHouse/clickhouse-operator)) então você não precisa de bancos de dados externos. Se preferir trazer os seus, ambos podem ser desabilitados em `values.yaml`.

## Instale os operadores

Instale os operadores que correspondam aos componentes que você planeja habilitar. No mínimo:

- [Operador CloudNativePG](https://cloudnative-pg.io/documentation/current/installation_upgrade/) para o banco de dados da aplicação
- [Operador Kubernetes do ClickHouse](https://github.com/ClickHouse/clickhouse-operator) para o banco de dados analítico
- Um controlador de Ingresso (por exemplo [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) se você quiser TLS automático

## Instale o chart do Glossia

Clone o repositório, em seguida instale o chart:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## Forneça os segredos da aplicação

Crie um Kubernetes Secret chamado `glossia-app-env` com pelo menos estas chaves:

| Chave | Propósito |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Chave de sessão de assinatura Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Proteção do token Bearer | `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth para `/ops` painéis |
| `RELEASE_COOKIE` | cookie de distribuição do Erlang compartilhada por cada pod |
| `GLOSSIA_SMTP_*` | configurações de e-mail de saída |

Você pode provisionar estes diretamente, utilize [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), ou conecte o chart ao seu gerenciador de segredos via o [External Secrets Operator](https://external-secrets.io/) integração descrita no README do chart.

## O que há no chart

- A aplicação web do Glossia
- Postgres para dados da aplicação (opcional, ativado por padrão)
- ClickHouse para análise de dados (opcional, ativado por padrão)
- Workers de fundo para tarefas de tradução, que executam como Kubernetes Jobs para sobreviverem a deploys em rolagem

## Onde ir a seguir

- O [README do Helm chart](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) tem a referência completa para cada valor, além de notas sobre backups, armazenamento de objetos e observabilidade.
- [Configure um provedor de modelo](/docs/how-to/configure-a-model-provider) assim que a instância estiver rodando, para que as traduções possam chamar um LLM.
- Relate problemas ou sugira melhorias em [Repositório GitHub](https://github.com/glossia/glossia).