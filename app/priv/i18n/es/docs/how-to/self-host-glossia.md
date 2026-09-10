%{
  title: "Auto-alojar Glossia",
  summary:
    "Instala Glossia en tu propio clúster de Kubernetes con el chart de Helm incluido, para que tu equipo ejecute el sistema operativo de lenguajes en su propia infraestructura.",
  category: "Guía paso a paso",
  order: 2
}
---
Glossia es de código abierto bajo la [Licencia O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Puedes autoalojarlo, modificarlo y ejecutarlo para el uso interno de tu organización. Lo único que la licencia no permite es ofrecerlo a terceros como un producto alojado o SaaS que compite con el servicio alojado de glossia.ai

Esta guía te lleva desde un clúster Kubernetes vacío hasta una instancia de Glossia en funcionamiento.

## Antes de comenzar

Necesitarás:

- Un clúster de Kubernetes en el que puedas instalar archivos de Helm (v1.28 o superior)
- `helm` y `kubectl` localmente
- Un dominio al que puedes apuntar al Ingress del clúster
- Un proveedor OpenID Connect o un relé SMTP para autenticación (Glossia soporta ambos)

El gráfico Helm incluye Postgres (vía [CloudNativePG](https://cloudnative-pg.io/)) y ClickHouse (a través del [operador oficial](https://github.com/ClickHouse/clickhouse-operator)) así que no necesitas bases de datos externas. Si prefieres traer las tuyas, ambas pueden desactivarse en `values.yaml`.

## Instala los operadores

Instala los operadores que coincidan con los componentes que planeas habilitar. Mínimo:

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

Crea un Secreto de Kubernetes llamado `glossia-app-env` con al menos estas claves:

| Clave | Propósito |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Clave de firma de sesión de Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Protección del token de portador `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth para `/ops` paneles |
| `RELEASE_COOKIE` | Cookie de distribución de Erlang compartida por cada pod |
| `GLOSSIA_SMTP_*` | Configuración de correo saliente |

Puede provisionar estos directamente, utilice [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), o conecte el chart con su gestor de secretos a través del [External Secrets Operator](https://external-secrets.io/) integración descrita en el README del chart.

## ¿Qué contiene el chart?

- La aplicación web de Glossia
- Postgres para datos de aplicación (opcional, activado por defecto)
- ClickHouse para analíticas (opcional, activado por defecto)
- Trabajadores en segundo plano para las tareas de traducción, que se ejecutan como Jobs de Kubernetes para que sobrevivan a los despliegues rodantes

## ¿Dónde ir a continuación?

- El [README del chart Helm](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) tiene la referencia completa para cada valor, más notas sobre copias de seguridad, almacenamiento de objetos y observabilidad.
- [Configurar un proveedor de modelo](/docs/how-to/configure-a-model-provider) una vez que la instancia está ejecutándose para que las sesiones de traducción puedan invocar a un LLM.
- Reportar incidencias o sugerir mejoras en el [Repositorio de GitHub](https://github.com/glossia/glossia).