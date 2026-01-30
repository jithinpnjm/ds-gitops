#!/usr/bin/env bash
set -euo pipefail

# -------------------------------
# CONFIG
# -------------------------------
PROJECT_ID="jithin-gcp-1234"
NAMESPACE="vikunja"
KSA_NAME="vikunja"
GSA_NAME="vikunja-cloudsql"
GSA_EMAIL="${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
ROLE="roles/cloudsql.client"

echo "Using project: ${PROJECT_ID}"
gcloud config set project "${PROJECT_ID}" >/dev/null

# -------------------------------
# 1. Create GCP Service Account (idempotent)
# -------------------------------
if ! gcloud iam service-accounts describe "${GSA_EMAIL}" >/dev/null 2>&1; then
  echo "Creating GCP Service Account: ${GSA_EMAIL}"
  gcloud iam service-accounts create "${GSA_NAME}" \
    --display-name "Vikunja Cloud SQL access"
else
  echo "GCP Service Account already exists: ${GSA_EMAIL}"
fi

# -------------------------------
# 2. Grant Cloud SQL Client role
# -------------------------------
echo "Granting Cloud SQL Client role to ${GSA_EMAIL}"
gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
  --member="serviceAccount:${GSA_EMAIL}" \
  --role="${ROLE}" \
  --quiet

# -------------------------------
# 3. Bind KSA -> GSA (Workload Identity)
# -------------------------------
echo "Binding Workload Identity (KSA -> GSA)"
gcloud iam service-accounts add-iam-policy-binding "${GSA_EMAIL}" \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${NAMESPACE}/${KSA_NAME}]" \
  --quiet

# -------------------------------
# 4. Patch Kubernetes ServiceAccount (Helm-managed)
# -------------------------------
echo "Patching Kubernetes ServiceAccount ${NAMESPACE}/${KSA_NAME}"

kubectl patch serviceaccount "${KSA_NAME}" \
  -n "${NAMESPACE}" \
  --type merge \
  -p "{
    \"metadata\": {
      \"annotations\": {
        \"iam.gke.io/gcp-service-account\": \"${GSA_EMAIL}\"
      }
    }
  }"

# -------------------------------
# 5. Verify
# -------------------------------
echo "Verification:"
kubectl get sa "${KSA_NAME}" -n "${NAMESPACE}" \
  -o jsonpath='{.metadata.annotations.iam\.gke\.io/gcp-service-account}'; echo


