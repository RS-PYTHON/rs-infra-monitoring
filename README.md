# rs-infra-monitoring

Monitoring and observability stack of [RS-Python](https://github.com/RS-PYTHON/rs-documentation): metrics, logs and
traces of the Kubernetes cluster and of the RS-Python components, with their dashboards.

## Overview

This repository is a *package* of applications deployed on the cluster created by
[rs-infra-core](https://github.com/RS-PYTHON/rs-infra-core), with its `apps.yaml` playbook. Each folder of
[apps](apps) is an application, made of a [Kustomize](https://kustomize.io/) file that references a Helm chart and
Kubernetes manifests, templated with the variables of the inventory:

| Application | Namespace | Description |
|---|---|---|
| `01-grafana-operator` | `monitoring` | The [Grafana Operator](https://grafana.github.io/grafana-operator/), that manages the data sources and dashboards of Grafana as Kubernetes resources (`GrafanaDatasource`, `GrafanaDashboard`...). |
| `01-listenerset` | `monitoring` | The HTTPS listener of the `monitoring.<domain>` host name on the Envoy Gateway, see [Gateway API](https://github.com/RS-PYTHON/rs-infra-core/blob/develop/docs/how-to/gateway-api-httproute.md). |
| `grafana` | `monitoring` | [Grafana](https://grafana.com/docs/grafana/latest/), the web interface of the monitoring, with the Keycloak authentication (OpenID Connect). |
| `prometheus` | `monitoring` | The [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack): [Prometheus](https://prometheus.io/docs/), its operator and the exporters of the cluster metrics, exposed under `/prometheus` with the Keycloak authentication. |
| `prometheus-datasource` | `monitoring` | The Prometheus data source of Grafana. |
| `loki` | `logging` | [Loki](https://grafana.com/docs/loki/latest/), the storage of the logs of all the pods, in the object storage, with its Grafana data source. |
| `tempo-distributed` | `logging` | [Tempo](https://grafana.com/docs/tempo/latest/), the storage of the [OpenTelemetry](https://opentelemetry.io/) traces, in the object storage, with its Grafana data source. |
| `alloy` | `monitoring` | [Grafana Alloy](https://grafana.com/docs/alloy/latest/), the collector that sends the logs of the pods to Loki and the OpenTelemetry traces to Tempo. |

The data sources of the other components (e.g. the Prefect and performance indicators databases) are deployed with
these components, as `GrafanaDatasource` resources.

## Getting started

Deploy the applications from the bastion, after the [infrastructure installation](https://github.com/RS-PYTHON/rs-infra-core/blob/develop/docs/installation.md):

```shell
cd ~
git clone https://github.com/RS-PYTHON/rs-infra-monitoring.git
cd ~/rs-infra-core
ansible-playbook apps.yaml -i inventory/mycluster/hosts.yaml -e '{"package_paths": ["~/rs-infra-monitoring/apps/"]}'
```

The parameters of the applications (`grafana`, `loki`, `grafanatempo`... sections: credentials, retention, buckets,
additional Grafana plugins, SMTP server) are in the `host_vars/setup/apps.yml` file of the inventory.

## Documentation

- [Monitoring and observability](https://github.com/RS-PYTHON/rs-documentation/blob/develop/docs/administration/monitoring.md):
  usage of the monitoring stack, logs, traces and dashboards of RS-Python.
- [Deploy RS-Python](https://github.com/RS-PYTHON/rs-documentation/blob/develop/docs/administration/deploy.md)
- [Update the infrastructure](https://github.com/RS-PYTHON/rs-documentation/blob/develop/docs/administration/update-infrastructure.md)

## Related repositories

- [rs-infra-core](https://github.com/RS-PYTHON/rs-infra-core): Kubernetes infrastructure and deployment playbooks.
- [rs-workflow-env](https://github.com/RS-PYTHON/rs-workflow-env), [rs-server-deployment](https://github.com/RS-PYTHON/rs-server-deployment):
  the monitored components, with their Grafana data sources.

## Contributing

See the [contribution guidelines](https://github.com/RS-PYTHON/rs-documentation/blob/develop/docs/developers/contributing.md).
Report bugs in the [issue tracker](https://github.com/RS-PYTHON/rs-infra-monitoring/issues). In case of sensitive bugs like
security vulnerabilities, please contact <ops_coprs@airbus.com> directly instead of using the issue tracker.

## Licensing

The code in this project is licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).

---

![](https://raw.githubusercontent.com/RS-PYTHON/.github/refs/heads/main/profile/banner_logo.jpg)

This project is funded by the EU and ESA.
