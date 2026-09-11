%{
  title: "Auto-hospedar Glossia",
  summary:
    "Instale o Glossia no seu próprio cluster Kubernetes com o chart Helm incluído para que sua equipe execute o sistema operacional de linguagem em sua própria infraestrutura.",
  category: "tutorial",
  order: 2
}
---
O Glossia é de código aberto sob a [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Você pode hospedá-lo internamente, modificá-lo e executá-lo para o uso interno de sua organização. A única coisa que a licença não permite é oferecer a terceiros como um produto hospedado ou SaaS que concorre com o serviço hospedado em glossia.ai.

Este guia leva você de um cluster Kubernetes vazio para uma instância Glossia em execução.

## Antes de começar

Você precisará de:

- Um cluster Kubernetes onde você pode instalar charts do Helm (v1.28 ou mais recente)
- `helm` e `kubectl` localmente
- Um domínio que você pode apontar para o ingress do cluster
- Um provedor OpenID Connect ou relay SMTP para autenticação (Glossia suporta ambos)

O chart Helm inclui Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) e ClickHouse (via o [operador oficial](https://github.com/ClickHouse/clickhouse-operator)) então você não precisa de bancos de dados externos. Se preferir trazer o próprio, ambos podem ser desabilitados em `values.yaml`.

## Instale os operadores

Instale os operadores que correspondam aos componentes que você planeja habilitar. No mínimo:

- [operador CloudNativePG](https://cloudnative-pg.io/documentation/current/installation_upgrade/) para o banco de dados do aplicativo
- [operador ClickHouse Kubernetes](https://github.com/ClickHouse/clickhouse-operator) para o banco de dados de análises
- Um controlador de Ingress (por exemplo [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) Se quiser o TLS automático

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

## Forneça os segredos da aplicação

Crie um Secret do Kubernetes chamado `glossia-app-env` com pelo menos estas chaves:

| Chave | Finalidade |
| --- |
| `GLOSSIA_SECRET_KEY_BASE` | Chave de assinatura de sessão do Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Proteção do token Bearer `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth para `/ops` painéis |
| `RELEASE_COOKIE` | Cookie de distribuição Erlang compartilhado por cada pod |
| `GLOSSIA_SMTP_*` | Configurações de e-mail de saída |

Você pode provisionar esses diretamente, use [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), ou conecte o chart ao seu gestor de segredos através da [External Secrets Operator](https://external-secrets.io/) integração descrita no README do chart.

## O que há no chart

- A aplicação web Glossia
- Postgres para dados da aplicação (opcional, ativado por padrão)
- ClickHouse para análises (opcional, ativado por padrão)
- Trabalhadores em segundo plano para tarefas de tradução, que executam como Jobs do Kubernetes para que sobrevivam a deploys rotativos

## Onde ir em seguida

- O [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) tem a referência completa para cada valor, além de notas sobre backups, armazenamento de objetos e observabilidade.
- [Configurar um provedor de modelo](/docs/how-to/configure-a-model-provider) assim que a instância estiver rodando para que as traduções possam chamar uma LLM.
- Reportar problemas ou sugerir melhorias no [Repositório GitHub](https://github.com/glossia/glossia).