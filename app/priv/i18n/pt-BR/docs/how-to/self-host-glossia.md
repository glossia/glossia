%{
  title: "Autohospedagem do Glossia",
  summary:
    "Instale o Glossia no seu próprio cluster Kubernetes com o Helm chart incluído, para que sua equipe rode o Sistema Operacional de Linguagem em sua própria infraestrutura.",
  category: "Passo a passo",
  order: 2
}
---
Glossia é código aberto sob a [Licença O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Você pode auto-hospedar, modificá-lo e executá-lo para uso interno de sua organização. A única coisa que a licença não permite é oferecê-lo a terceiros como um produto hospedado ou SaaS que concorra com o serviço hospedado na glossia.ai.

Este guia o leva de um cluster Kubernetes vazio para uma instância Glossia rodando.

## Antes de começar

Você precisará de:

- Um cluster Kubernetes onde você possa instalar charts do Helm (v1.28 ou mais recente)
- `helm` e `kubectl` localmente
- Um domínio que você pode apontar para o ingress do cluster
- Um provedor OpenID Connect ou relay SMTP para autenticação (o Glossia suporta ambos)

O gráfico Helm inclui Postgres (via [CloudNativePG](https://cloudnative-pg.io/)""" e ClickHouse (via o [operador oficial](https://github.com/ClickHouse/clickhouse-operator)"") então você não precisa de bancos de dados externos. Se preferir usar os seus, ambos podem ser desativados em `values.yaml`.

## Instale os operadores

Instale os operadores que correspondam aos componentes que planeja habilitar. No mínimo:

- [Operador CloudNativePG](https://cloudnative-pg.io/documentation/current/installation_upgrade/) para o banco de dados da aplicação
- [Operador ClickHouse Kubernetes](https://github.com/ClickHouse/clickhouse-operator) para o banco de dados analítico
- Um controlador de Ingress (por exemplo [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) se você quiser TLS automático

## Instale o chart do Glossia

Clonar o repositório e, em seguida, instale o chart:

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
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Chave de assinatura da sessão do Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Proteção do token Bearer `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth para `/ops` dashboards |
| `RELEASE_COOKIE` | cookie de distribuição do Erlang compartilhada por cada pod |
| `GLOSSIA_SMTP_*` | Configurações de e-mail de saída |

Você pode provisionar esses diretamente, utilize [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), ou conecte o chart ao seu gestor de segredos via o [External Secrets Operator](https://external-secrets.io/) integração descrita no README do chart.

## O que há no chart

- A aplicação web Glossia
- Postgres para dados da aplicação (opcional, ativado por padrão)
- ClickHouse para análise (opcional, ativado por padrão)
- Trabalhadores em segundo plano para jobs de tradução, que rodam como Jobs do Kubernetes para sobreviverem a implantações rolling

## Onde ir a seguir

- O [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) contém a referência completa para cada valor, bem como notas sobre backups, armazenamento de objetos e observabilidade.
- [Configure um provedor de modelo](/docs/how-to/configure-a-model-provider) assim que a instância estiver rodando para que traduções possam chamar um LLM.
- Relatar problemas ou sugerir melhorias em [Repositório GitHub](https://github.com/glossia/glossia).