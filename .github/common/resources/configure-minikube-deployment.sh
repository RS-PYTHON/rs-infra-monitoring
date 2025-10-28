#!/bin/bash
# Copyright 2025 CS Group
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

APPS=rs-infra-monitoring/apps

# Lower the CPU requests
sed -i -e 's!cpu: 200m!cpu: 1m!g' -e 's!memory: 256Mi!memory: 128Mi!g' "${APPS}/grafana/grafana.yaml"
sed -i -e 's!cpu: 50m!cpu: 1m!g' -e 's!memory: 128Mi!memory: 64Mi!g' "${APPS}/grafana/image-renderer.yaml"
sed -i -e 's!cpu: 500m!cpu: 1m!g' -e 's!memory: 512Mi!memory: 128Mi!g' "${APPS}/prometheus/values.yaml"
# Lower the requests and number of loki replicas
sed -i \
    -e 's!max_concurrent: 4!max_concurrent: 1!g' \
    -e 's!replicas: 3!replicas: 1!g' \
    -e 's!replicas: 2!replicas: 1!g' \
    -e 's!maxUnavailable: 2!maxUnavailable: 0!g' \
    -e 's!maxUnavailable: 1!maxUnavailable: 0!g' \
    -e 's!cpu: 500m!cpu: 5m!g' \
    -e 's!allocatedMemory: 8192!allocatedMemory: 100!g' \
    -e 's!allocatedMemory: 1024!allocatedMemory: 100!g' \
    -e 's!memory: 1229Mi!memory: 120Mi!g' \
    -e 's!memory: 9830Mi!memory: 120Mi!g' \
    -e 's!writebackSizeLimit: 500MB!writebackSizeLimit: 50MB!g' \
    "${APPS}/loki/values.yaml"
# Disable strict podAntiAffinity loki directives that prevent to deploy on a single node
# see https://github.com/grafana/helm-charts/issues/2709#issuecomment-2839130975
for path in $(yq eval '.. | select(has("affinity")) | path | join(".")' "${APPS}/loki/values.yaml"); do
    yq eval -i ".$path.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution += [{
        \"labelSelector\": {\"matchLabels\": {\"app.kubernetes.io/component\": \"not-read\"}},
        \"topologyKey\": \"kubernetes.io/hostname\"
    }]" "${APPS}/loki/values.yaml"
done
# Disable tempo secure mode
sed -i 's!insecure: false!insecure: true!g' "${APPS}/tempo-distributed/values.yaml"
