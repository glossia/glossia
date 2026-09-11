%{
  title: "Autoaloja Glossia",
  summary:
    "Instala Glossia en tu propio clúster Kubernetes con el chart de Helm incluido, para que tu equipo pueda ejecutar el sistema operativo de lenguaje en su propia infraestructura.",
  category: "Guía paso a paso",
  order: 2
}
---
Glossia es de código abierto bajo la [Licencia O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Puedes autoalojarlo, modificarlo y ejecutarlo para el uso interno de tu organización. Lo único que la licencia no permite es ofrecerlo a terceros como un producto alojado o SaaS que compita con el servicio alojado en glossia.ai.

Esta guía te lleva desde un clúster de Kubernetes vacío hasta una instancia de Glossia ejecutándose.

## Antes de empezar

Necesitarás:

- Un clúster de Kubernetes en el que puedas instalar diagramas de Helm (v1.28 o posterior)
- `helm` y `kubectl` localmente
- Un dominio al que puedes apuntar al clúster ingress
- Un proveedor de OpenID Connect o un retransmisor de SMTP para autenticación (Glossia soporta ambos)

El chart de Helm incluye Postgres (vía [CloudNativePG](https://cloudnative-pg.io/)) y ClickHouse (a través del [operador oficial](https://github.com/ClickHouse/clickhouse-operator)) para que no necesites bases de datos externas. Si prefieres usar las tuyas, ambas se pueden desactivar en `values.yaml`.

## Instale los operadores

Instale los operadores que coincidan con los componentes que planee habilitar. Como mínimo:

- [Operador CloudNativePG](https://cloudnative-pg.io/documentation/current/installation_upgrade/) para la base de datos de la aplicación
- [Operador Kubernetes de ClickHouse](https://github.com/ClickHouse/clickhouse-operator) para la base de datos analítica
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
| `RELEASE_COOKIE` | Cookie de distribución Erlang compartida por cada pod |
| `GLOSSIA_SMTP_*` | Configuración de correo electrónico saliente |

Puedes aprovisionarlos directamente, usa [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), o conecte el diagrama con su gestor de secretos mediante la [External Secrets Operator](https://external-secrets.io/) integración descrita en el README del diagrama.

## ¿Qué contiene el diagrama?

- La aplicación web de Glossia
- Postgres para datos de la aplicación (opcional, activado por defecto)
- ClickHouse para análisis (opcional, activado por defecto)
- Trabajadores en segundo plano para tareas de traducción, que se ejecutan como Jobs de Kubernetes para que sobrevivan a los despliegues rotativos.

## Dónde ir a continuación

- El [README del chart de Helm](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) tiene la referencia completa para cada valor, además de notas sobre copias de seguridad, almacenamiento de objetos y observabilidad.
- [Configurar un proveedor de modelos](/docs/how-to/configure-a-model-provider) una vez que la instancia esté en ejecución para que las traducciones puedan llamar a un LLM.
- Reportar problemas o sugerir mejoras en [Repositorio de GitHub](https://github.com/glossia/glossia).