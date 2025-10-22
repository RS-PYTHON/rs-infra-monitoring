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

# Lower the number of loki replicas
sed -i \
-e 's!max_concurrent: 4!max_concurrent: 1!g' \
-e 's!replicas: 3!replicas: 1!g' \
-e 's!replicas: 2!replicas: 1!g' \
-e 's!maxUnavailable: 2!maxUnavailable: 0!g' \
-e 's!maxUnavailable: 1!maxUnavailable: 0!g' \
rs-infra-monitoring/apps/loki/values.yaml
# Disable strict podAntiAffinity loki directives that prevent to deploy on a single node
# see https://github.com/grafana/helm-charts/issues/2709#issuecomment-2839130975
for path in $(yq eval '.. | select(has("affinity")) | path | join(".")' rs-infra-monitoring/apps/loki/values.yaml); do
yq eval -i ".$path.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution += [{
    \"labelSelector\": {\"matchLabels\": {\"app.kubernetes.io/component\": \"not-read\"}},
    \"topologyKey\": \"kubernetes.io/hostname\"
}]" rs-infra-monitoring/apps/loki/values.yaml
done
sed -i 's!insecure: false!insecure: true!g' rs-infra-monitoring/apps/tempo-distributed/values.yaml
