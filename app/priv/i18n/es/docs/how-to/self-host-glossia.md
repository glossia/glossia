%{
  title: "Autoalojar Glossia",
  summary:
    "Instala Glossia en tu propio clúster de Kubernetes con el diagrama Helm incluido, para que tu equipo ejecute el sistema operativo de idiomas en su propia infraestructura.",
  category: "Guía",
  order: 2
}
---
Glossia es de código abierto bajo la [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Puedes autoalojarlo, modificarlo y ejecutarlo para uso interno de tu organización. Lo único que la licencia no permite es ofrecerlo a terceros como un producto alojado o SaaS que compita con el servicio alojado en glossia.ai.

Esta guía te lleva desde un clúster de Kubernetes vacío hasta una instancia de Glossia en funcionamiento.

## Antes de empezar

Necesitarás:

- Un clúster de Kubernetes en el que puedas instalar diagramas Helm (v1.28 o más reciente)
- `helm` y `kubectl` localmente
- Un dominio al que puedes apuntar el cluster ingress
- Un proveedor OpenID Connect o un relé SMTP para autenticación (Glossia admite ambos)

El diagrama Helm incluye Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) y ClickHouse (vía the [operador oficial](https://github.com/ClickHouse/clickhouse-operator)) así que no necesitas bases de datos externas. Si prefieres traerte las tuyas propias, ambas pueden desactivarse en `values.yaml`.

## Instala los operadores

Instala los operadores que coincidan con los componentes que planeas habilitar. Al menos:

- [Operador CloudNativePG](https://cloudnative-pg.io/documentation/current/installation_upgrade/) para la base de datos de la aplicación
- [Operador ClickHouse Kubernetes](https://github.com/ClickHouse/clickhouse-operator) para la base de datos analítica
- Un controlador de entrada (por ejemplo [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
- [cert-manager](https://cert-manager.io/) si deseas TLS automático

## Instala el chart de Glossia

Clona el repositorio, luego instala el chart:

```bash
git clone https://github.com/glossia/glossia.git
cd glossia

helm install glossia ./deploy/helm/glossia \
  --namespace glossia --create-namespace \
  --set image.tag=main \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=glossia.example.com
```

## Proporciona los secretos de la aplicación

Crea un secreto de Kubernetes llamado `glossia-app-env` con al menos estas claves:

| Clave | Propósito |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Clave de firma de sesión de Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Protección del token Bearer `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Autenticación básica para `/ops` tableros |
| `RELEASE_COOKIE` | cookie de distribución de Erlang compartida por cada pod |
| `GLOSSIA_SMTP_*` | Configuración de correo electrónico saliente |

Puedes provisionar estos directamente, usa [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), o conecta el gráfico a tu gestor de secretos a través de la [External Secrets Operator](https://external-secrets.io/) integración descrita en el README del gráfico.

## ¿Qué contiene el gráfico?

- La aplicación web de Glossia
- Postgres para datos de la aplicación (opcional, activado por defecto)
- ClickHouse para analíticas (opcional, activado por defecto)
- Trabajadores en segundo plano para trabajos de traducción, que se ejecutan como Jobs de Kubernetes para que sobrevivan a los despliegues escalonados

## ¿Qué sigue?

- El [README del Chart de Helm](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) tiene la referencia completa para cada valor, además de notas sobre copias de seguridad, almacenamiento de objetos y observabilidad.
- [Configurar un proveedor de modelo](/docs/how-to/configure-a-model-provider) una vez que la instancia está en ejecución para que las traducciones puedan llamar a un LLM.
- Informe problemas o sugiera mejoras en la [Repositorio de GitHub](https://github.com/glossia/glossia).