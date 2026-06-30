#!/bin/bash
# Copyright 2023-2026 Airbus, CS Group
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

APPS="${APPS_DIR:-rs-infra-monitoring/apps}"

# Lower the CPU requests
sed -i -e 's!cpu: 200m!cpu: 1m!g' -e 's!memory: 256Mi!memory: 128Mi!g' "${APPS}/grafana/grafana.yaml"
sed -i -e 's!cpu: 50m!cpu: 1m!g' -e 's!memory: 128Mi!memory: 64Mi!g' "${APPS}/grafana/image-renderer.yaml"
sed -i -e 's!cpu: 500m!cpu: 1m!g' -e 's!memory: 512Mi!memory: 128Mi!g' "${APPS}/prometheus/values.yaml"

# Loki part
yq -i '
  # Remove all memory requests and limits
  del(.. | select(has("resources")).resources.requests.memory) |
  del(.. | select(has("resources")).resources.limits.memory) |

  # Set replicas=1
  .ingester.replicas = 1 |
  .querier.replicas = 1 |
  .queryFrontend.replicas = 1 |
  .queryScheduler.replicas = 1 |
  .distributor.replicas = 1 |
  .indexGateway.replicas = 1 |

  # Set maxUnavailable=0
  (.. | select(has("maxUnavailable")).maxUnavailable) = 0 |

  # Reduce concurrency for single-node mode
  .loki.querier.max_concurrent = 1 |

  # Reduce cache writeback sizes
  .chunksCache.writebackSizeLimit = "50MB" |
  .resultsCache.writebackSizeLimit = "50MB" |

  # Enable insecure S3 access
  .loki.storage.s3.insecure = true
' "${APPS}/loki/values.yaml"

# Disable strict podAntiAffinity loki directives that prevent to deploy on a single node
# see https://github.com/grafana/helm-charts/issues/2709#issuecomment-2839130975
for path in $(yq eval '.. | select(has("affinity")) | path | join(".")' "${APPS}/loki/values.yaml"); do
    yq eval -i ".$path.affinity.podAntiAffinity.requiredDuringSchedulingIgnoredDuringExecution += [{
        \"labelSelector\": {\"matchLabels\": {\"app.kubernetes.io/component\": \"not-read\"}},
        \"topologyKey\": \"kubernetes.io/hostname\"
    }]" "${APPS}/loki/values.yaml"
done

# Tempo part
yq -i '
  # Remove all memory requests and limits
  del(.. | select(has("resources")).resources.requests.memory) |
  del(.. | select(has("resources")).resources.limits.memory) |

  # Disable autoscaling
  .distributor.autoscaling.enabled = false |

  # Set replicas=1 where needed
  .distributor.replicas = 1 |
  .memcached.replicas = 1 |
  .ingester.replicas = 1 |

  # Ensure single-node consistency
  .tempo.structuredConfig.ingester.lifecycler.ring.replication_factor = 1 |

  # Enable insecure S3
  .storage.trace.s3.insecure = true |

  # Remove memcached extraArgs
  del(.memcached.extraArgs)
' "${APPS}/tempo-distributed/values.yaml"
