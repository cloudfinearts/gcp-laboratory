# GCP laboratory
gcloud container clusters get-credentials blueprints-gke-dev --region=europe-central2

## TODO
create GKE with private nodes and Cloud NAT
Upgrade GKE with terraform
Use Wireguard for node-to-node encryption

## Karpenter
https://github.com/cloudpilot-ai/karpenter-provider-gcp/tree/main/charts

Unusable as of now 9/25
Throws weird errors on GCENodeClass
Creates NodeClaim for pending pod but does not create a node, nothing in the log
Using nodeSelector fied ends up in another error