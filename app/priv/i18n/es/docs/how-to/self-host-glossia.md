%{
  title: "Autohospedar Glossia",
  summary:
    "Instala Glossia en tu propio clúster de Kubernetes con el chart de Helm incluido, para que tu equipo ejecute el sistema operativo de idiomas en su propia infraestructura.",
  category: "Tutorial",
  order: 2
}
---
Glossia es de código abierto bajo la [Licencia O'Saasy](https://github.com/glossia/glossia/blob/main/LICENSE.md). Puedes autoalojarlo, modificarlo y ejecutarlo para el uso interno de tu organización. Lo único que la licencia no permite es ofrecerlo a terceros como un producto alojado o SaaS que compite con el servicio alojado en glossia.ai.

Esta guía te ayuda a pasar de un clúster de Kubernetes vacío a una instancia de Glossia en funcionamiento.

## Antes de empezar

Necesitarás:

- Un clúster de Kubernetes en el que puedas instalar gráficos Helm (v1.28 o más reciente)
- `helm` y `kubectl` localmente
- Un dominio al que puede apuntar al ingress del clúster
- Un proveedor de OpenID Connect o un relé SMTP para la autenticación (Glossia soporta ambos)

El diagrama de Helm incluye Postgres (a través de [CloudNativePG](https://cloudnative-pg.io/)) y ClickHouse (a través de la [operador oficial](https://github.com/ClickHouse/clickhouse-operator)) así no necesitas bases de datos externas. Si prefieres llevártelas tú mismo, ambas se pueden desactivar en `values.yaml`.

## Instalar los operadores

Instale los operadores que coincidan con los componentes que planea habilitar. Mínimo:

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

Crea un Secreto de Kubernetes llamado `glossia-app-env` con al menos estas claves:

| Clave | Propósito |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Clave de firma de sesión de Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Protección del token Bearer | `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth para `/ops` tableros |
| `RELEASE_COOKIE` | cookie de distribución de Erlang compartida por cada pod |
| `GLOSSIA_SMTP_*` | Configuración de correo electrónico saliente |

Puedes aprovisionar estos directamente, usa [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), o conecta el chart a tu gestor de secretos a través de la [External Secrets Operator](https://external-secrets.io/) integración descrita en el README del chart.

## Qué contiene el chart

- La aplicación web de Glossia
- Postgres para datos de la aplicación (opcional, habilitado por defecto)
- ClickHouse para analíticas (opcional, habilitado por defecto)
- Trabajadores en segundo plano para tareas de traducción, que se ejecutan como trabajos de Kubernetes para que sobrevivan a los despliegues rotativos

## A dónde ir a continuación

- El [README del chart de Helm](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) tiene la referencia completa para cada valor, más notas sobre respaldos, almacenamiento de objetos y observabilidad.
- [Configurar un proveedor de modelos](/docs/how-to/configure-a-model-provider) una vez que la instancia esté ejecutándose para que las traducciones puedan llamar a un LLM.
- Reportar problemas o sugerir mejoras en [Repositorio de GitHub](https://github.com/glossia/glossia).