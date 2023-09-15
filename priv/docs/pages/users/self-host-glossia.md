# How to self-host Glossia

The Glossia Community and Enterprise plans permit self-hosting of the project. However, please be aware that **the Enterprise plan necessitates a distinct [licensing agreement](/lib/glossia/features/enterprise/LICENSE.md)**. Without this agreement, self-hosting under the Enterprise plan is prohibited. This guide provides comprehensive instructions for deploying and updating the project.

## Built for Effortless Hosting and Scalability

Central to our [design philosophy](https://handbook.glossia.ai/engineering/stack) is the belief that Glossia should be **straightforward to manage and scale.** This not only streamlines our processes but also simplifies self-hosting for other organizations. For instance, our choice to base our technology stack on Elixir enables vertical scaling by simply enhancing CPU and memory resources in production environments. We've also minimized dependencies and crafted the software to make many components optional. A case in point: our background tasks system utilizes the same PostgreSQL database for job state persistence and notifications as it does for the core application data storage.

Additionally, Glossia ensures updates are **backward-compatible.** This means you can seamlessly deploy newer versions without the stress of disrupting your production environment or undertaking lengthy migrations. Plus, we've streamlined the process to revert to a previous version if needed.

## Requirements


To operate Glossia, ensure you have:

- A production environment capable of running virtualized OSI images. Most cloud providers offer this capability as it's become the industry standard.
- An instance of [PostgreSQL](https://www.postgresql.org/) database. We suggest opting for a managed service such as [Amazon RDS](https://aws.amazon.com/rds/postgresql/) or[ Google Cloud SQL](https://cloud.google.com/sql/docs/postgres/). Another alternative is [Neon](https://neon.tech/), which provides automatic database scaling.
- A Google Cloud account to run builds in ephemeral Linux environments using [Google Cloud Build](https://cloud.google.com/build).

As an added recommendation, consider **integrating a CI solution to establish a deployment pipeline.** This can automate the rollout of new Glossia versions to your servers.

## Environment variables

To configure Glossia, utilize the environment variables listed below. Keep in mind that certain variables are essential; without them, Glossia will not initiate:

| Environment variable | Description | Default value | Required | Example |
| --- | --- | --- | --- | --- |
| `DATABASE_URL` | The URL to the Postgres database | | Yes | | `postgres://{user}:{pass}@url.../dummy` |

> **Note:** The above table is incomplete and we are working on bringing it up to date.

## Deployment

To deploy Glossia to your production environment, follow the steps below. These can be executed manually or incorporated into a continuous deployment pipeline:

- Both the community and enterprise images of Glossia are hosted on the [GitHub Container Registry](https://github.com/orgs/glossia/packages). Begin by pulling the desired image from the registry to your local environment:

```bash
docker pull ghcr.io/glossia/community:0.1.1
# Or the latest version
docker pull ghcr.io/glossia/community:latest
```

- After obtaining the image locally, you need to transfer it to your production environment. The procedure for this can differ based on your organizational setup. Some sophisticated configurations employ tools such as [Kubernetes](https://kubernetes.io/) for deployment. Meanwhile, PaaS platforms like [Fly.io](https://fly.io/) allow direct deployment from a Docker image. It's best to consult with your organization's production environment team for specific guidance on this step.

- Before initiating the application, it's crucial to execute any outstanding database migrations. Execute the command `/app/bin/migrate` within the Docker image to accomplish this. Failing to update the database schema before starting could result in runtime problems that may disrupt the application.

If the steps outlined above are executed correctly, new versions of Glossia should launch without any issues.