# Glossia operations

This directory contains the production infrastructure, operational Helm
charts, production values, and cluster reconciliation workflow for Glossia.

The application Helm chart lives at `../deploy/helm/glossia`. Flux reconciles
both the application and operations configuration from this repository.
