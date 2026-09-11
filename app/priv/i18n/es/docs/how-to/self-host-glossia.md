%{
  title: "Autohospedaje de Glossia",
  summary:
    "Instala Glossia en tu propio clúster de Kubernetes con el gráfico de Helm incluido, para que tu equipo ejecute el sistema operativo de idiomas en su propia infraestructura.",
  category: "guía",
  order: 2
}
---
Glossia es de código abierto bajo la [O'Saasy License](https://github.com/glossia/glossia/blob/main/LICENSE.md). Puedes autoalojarlo, modificarlo y ejecutarlo para el uso interno de tu organización. Lo único que la licencia no permite es ofrecerla a terceros como un producto alojado o SaaS que compita con el servicio alojado en glossia.ai.

Esta guía te lleva desde un clúster de Kubernetes vacío a una instancia de Glossia en funcionamiento.

## Antes de comenzar

Necesitarás:

- Un clúster de Kubernetes en el que puedas instalar charts Helm (v1.28 o posterior)
- `helm` y `kubectl` localmente
- Un dominio al que puedes apuntar el clúster ingress
- Un proveedor OpenID Connect o relay SMTP para autenticación (Glossia soporta ambos)

El flujo Helm empaqueta Postgres (via [CloudNativePG](https://cloudnative-pg.io/)) y ClickHouse (vía el [operador oficial](https://github.com/ClickHouse/clickhouse-operator)) para que no necesites bases de datos externas. Si prefieres llevar las tuyas propias, ambas pueden apagarse en `values.yaml`.

## Instale los operadores

Instale los operadores que coincidan con los componentes que desea habilitar. Al menos:

- [Operador CloudNativePG](https://cloudnative-pg.io/documentation/current/installation_upgrade/) para la base de datos de la aplicación
- [Operador Kubernetes ClickHouse](https://github.com/ClickHouse/clickhouse-operator) para la base de datos analítica
- Un controlador de Ingreso (por ejemplo [ingress-nginx](https://kubernetes.github.io/ingress-nginx/))
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

Crea un secreto de Kubernetes llamado `glossia-app-env` Con al menos estas claves:

| Clave | Propósito |
| --- | --- |
| `GLOSSIA_SECRET_KEY_BASE` | Clave de firma de sesión de Phoenix |
| `GLOSSIA_METRICS_BEARER_TOKEN` | Protección de token Bearer `/metrics` |
| `GLOSSIA_OPS_AUTH_PASSWORD` | Basic-auth para `/ops` | paneles |
| `RELEASE_COOKIE` | cookie de distribución de Erlang compartida por cada pod |
| `GLOSSIA_SMTP_*` Configuración de correo electrónico de salida

Puede provisionarlos directamente, utilice [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets), o conectar el chart a tu gestor de secretos a través de la [External Secrets Operator](https://external-secrets.io/) integración descrita en el README del chart.

## ¿Qué hay en el chart

- La aplicación web de Glossia
- Postgres para datos de la aplicación (opcional, activado por defecto)
- ClickHouse para análisis (opcional, activado por defecto)
- Trabajadores de fondo para tareas de traducción, que se ejecutan como Kubernetes Jobs para que sobrevivan a los despliegues rotativos

## A dónde ir a continuación

- El [README del gráfico Helm](https://github.com/glossia/glossia/blob/main/deploy/helm/glossia/README.md) tiene la referencia completa para cada valor, además de notas sobre respaldos, almacenamiento de objetos y observabilidad.
- [Configurar un proveedor de modelos](/docs/how-to/configure-a-model-provider) una vez que la instancia esté en ejecución para que las traducciones puedan invocar un LLM.
- Reportar problemas o sugerir mejoras en el [Repositorio de GitHub](https://github.com/glossia/glossia).