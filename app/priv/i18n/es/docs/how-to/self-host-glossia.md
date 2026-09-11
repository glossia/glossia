%{
  title: "Autoaloja Glossia",
  summary:
    "Instala Glossia en tu propio clúster de Kubernetes con el chart de Helm incluido, para que tu equipo ejecute el sistema operativo de idiomas en su propia infraestructura.",
  category: "Guía",
  order: 2
}
---
Glossia es de código abierto bajo la [Licencia O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Puedes autoalojarlo, modificarlo y ejecutarlo para el uso interno de tu organización. La única cosa que la licencia no permite es ofrecerla a terceros como un servicio alojado o SaaS que compita con el servicio alojado en glossia.ai.

Esta guía te ayuda a pasar de un clúster de Kubernetes vacío a una instancia de Glossia en ejecución.

## Antes de empezar

Necesitarás:

- Un clúster de Kubernetes en el que puedas instalar Helm charts (v1.28 o más reciente)
- `helm` y `kubectl` localmente
- Un dominio al que puedes apuntar el ingreso del clúster
- Un proveedor de OpenID Connect o relay SMTP para autenticación (Glossia admite ambos)

El diagrama Helm incluye Postgres (a través de [CloudNativePG](https://cloudnative-pg.io/)) y ClickHouse (a través del [operador oficial](https://github.com/ClickHouse/clickhouse-operator)) para que no necesites bases de datos externas. Si prefieres traerlas tú mismo, ambos se pueden desactivar en `values.yaml`.

## Instale los operadores

Instale los operadores que coincidan con los componentes que planea habilitar. Como mínimo:

- [CloudNativePG operador](https://cloudnative-pg.io/documentation/current/installation_upgrade/) para la base de datos de la aplicación
- [ClickHouse Kubernetes operador](https://github.com/ClickHouse/clickhouse-operator) para la base de datos analítica
- Un controlador de entrada (por ejemplo [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) si desea TLS automático

## Instale el diagrama de Glossia

Clonar el repositorio, luego instale el diagrama:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## Proporcione los secretos de la aplicación

Cree un Secret de Kubernetes llamado `glossia-app-env` con al menos estas claves:

| Clave | Propósito |
| --- |
| `GLOSSIA_SECRET_KEY_BASE` | Clave de firma de sesión de Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Protección del token Bearer `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Autenticación básica para `/ops` tableros |
| `RELEASE_COOKIE` | Galleta de distribución de Erlang compartida por cada pod |
| `GLOSSIA_SMTP_*` | Configuración de correo electrónico saliente |

Puede provisionar estos directamente, utilice [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), o conecte el chart a su gestor de secretos vía el [External Secrets Operator](https://external-secrets.io/) integración descrita en el README del chart.

## ¿Qué contiene el chart?

- La aplicación web de Glossia
- Postgres para datos de la aplicación (opcional, activado por defecto)
- ClickHouse para análisis (opcional, activado por defecto)
- Trabajadores de segundo plano para trabajos de traducción, que se ejecutan como Jobs de Kubernetes para que sobrevivan a los despliegues rodillo.

## Dónde ir a continuación

- El [README del Helm chart](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) tiene la referencia completa para cada valor, más notas sobre respaldos, almacenamiento de objetos y observabilidad.
- [Configurar un proveedor de modelos](/docs/how-to/configure-a-model-provider) una vez que la instancia esté ejecutándose para que las traducciones puedan invocar a un LLM.
- Reportar problemas o sugerir mejoras en [repositorio de GitHub](https://github.com/glossia/glossia).