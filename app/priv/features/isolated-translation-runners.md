%{
  title: "Isolated translation runners",
  summary: "Run translations outside the web application in detached Kubernetes jobs, with dedicated compute placement and optional Kata microVM isolation.",
  edition: "enterprise",
  order: 7,
  icon: "shield-check",
  hero_cta_text: "Contact us",
  hero_cta_url: "mailto:contact@glossia.ai",
  highlights: [
    %{title: "Independent jobs", description: "Translations keep their own lifetime and release image when the web application rolls out.", icon: "refresh-cw"},
    %{title: "Dedicated compute", description: "Place translation jobs and setup sandboxes on nodes provisioned for repository workloads.", icon: "cpu"},
    %{title: "Optional microVMs", description: "Use Kata with a configured Kubernetes RuntimeClass to run workloads with a separate kernel.", icon: "shield-check"}
  ]
}
---

## A shared engine, a different execution environment

Repository translation, language memory, validation, and pull request publication
are part of the open-source Community edition. Enterprise adds control over
where repository workloads run. Each translation becomes a detached Kubernetes
Job rather than work inside the web application's Oban worker.

## Keep translations independent of web rollouts

Each Job inherits the scheduling application's release image and owns its own
lifetime. Replacing a web Pod does not delete its translations. Published files
and durable progress let bounded retries resume unfinished work.

## Choose placement and isolation

Node selectors, tolerations, affinity, and resource requests let operators place
translation Jobs and project-setup sandbox Pods on dedicated capacity. A managed
FLAME pool provides separate pre-warmed runner capacity.

For a separate kernel per workload, install Kata on the execution nodes and
configure its RuntimeClass. Enterprise does not enable microVM isolation by
itself: without that configuration, the Jobs use the cluster's default container
runtime. Jobs also inherit application credentials; treat repository commands
with the corresponding level of trust.

## Available in Enterprise

Enterprise is source-available under a commercial license. Production use
requires a written commercial agreement. Community remains free to self-host
under Apache-2.0, with local execution for trusted repositories.

[Compare editions](/docs/explanation/editions) or read the
[runner reference](/docs/reference/isolated-translation-runners) for requirements,
configuration, and operational limits.
