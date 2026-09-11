%{
  title: "Auto-hospede o Glossia",
  summary:
    "Instale o Glossia no seu próprio cluster Kubernetes com o chart Helm incluído, para que sua equipe execute o Sistema Operacional de Idioma em sua própria infraestrutura.",
  category: "passo a passo",
  order: 2
}
---
O Glossia é de código aberto sob a [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Você pode hospedá-lo por conta própria, modificá-lo e operá-lo para uso interno da sua organização. A única coisa que a licença não permite é oferecê-lo a terceiros como um serviço hospedado ou SaaS que concorra com o serviço hospedado em glossia.ai.

Este guia leva você de um cluster Kubernetes vazio para uma instância do Glossia em execução.

## Antes de começar

Você precisará de:

- Um cluster Kubernetes onde você pode instalar gráficos Helm (v1.28 ou mais recente)
- `helm` e `kubectl` localmente
- Um domínio que você pode apontar para o ingress do cluster
- Um provedor OpenID Connect ou um servidor de relé SMTP para autenticação (Glossia suporta ambos)

O diagrama Helm inclui Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) e o ClickHouse (via o [operador oficial](https://github.com/ClickHouse/clickhouse-operator)) então você não precisa de bancos de dados externos. Se preferir trazer o seu próprio, ambos podem ser desativados em `values.yaml`.

## Instale os operadores

Instale os operadores que correspondam aos componentes que você planeja habilitar. No mínimo:

- [Operador CloudNativePG](https://cloudnative-pg.io/documentation/current/installation_upgrade/) para o banco de dados da aplicação
- [operador do ClickHouse Kubernetes](https://github.com/ClickHouse/clickhouse-operator) para o banco de dados analítico
- Um controlador de Ingress (por exemplo [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) se desejar TLS automático

## Instale o chart da Glossia

Clone o repositório, depois instale o chart:

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
| `GLOSSIA_SECRET_KEY_BASE` | Chave de assinatura da sessão Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Proteção do token Bearer `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth para `/ops` painéis |
| `RELEASE_COOKIE` | cookie de distribuição Erlang compartilhado por cada pod |
| `GLOSSIA_SMTP_*` | Configurações de e-mail de saída |

Você pode provisionar estes diretamente, utilize [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), ou conecte o chart ao seu gerenciador de segredos via o [External Secrets Operator](https://external-secrets.io/) integração descrita na README do chart.

## O que há no chart

- O aplicativo web Glossia
- Postgres para dados da aplicação (opcional, habilitado por padrão)
- ClickHouse para análises (opcional, habilitado por padrão)
- Trabalhadores em segundo plano para tarefas de tradução, que rodam como Kubernetes Jobs para sobreviver a implantações em rolagem

## Para onde ir a seguir

- O [Helm chart README](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) possui a referência completa para todos os valores, além de notas sobre backups, armazenamento de objetos e observabilidade.
- [Configurar um provedor de modelo](/docs/how-to/configure-a-model-provider) assim que a instância estiver em execução para que as traduções possam chamar um LLM.
- Relatar problemas ou sugerir melhorias em [Repositório GitHub](https://github.com/glossia/glossia).