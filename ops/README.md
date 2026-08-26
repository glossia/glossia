# Glossia operations

Private production operations and deployment configuration for
[Glossia](https://github.com/glossia/glossia).

This repository contains the production infrastructure, operational Helm
charts, production values, and cluster reconciliation workflow. It deliberately
does not contain application source or self-hosting documentation.

The production Helm release includes the public application chart from
`glossia/glossia` through Flux. Keep the two repositories compatible when
changing chart values or release configuration.
