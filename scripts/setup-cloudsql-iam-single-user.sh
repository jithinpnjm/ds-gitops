#!/usr/bin/env bash
set -euo pipefail

# -------------------------------
# CONFIG
# -------------------------------
PROJECT_ID="jithin-gcp-1234"
INSTANCE_NAME="vikunja-production-db"
REGION="us-central1"

# Shared IAM DB user (GSA)
GSA_EMAIL="vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com"

# Databases
DATABASES=("vikunja" "keycloak")

echo "Project: ${PROJECT_ID}"
echo "Instance: ${INSTANCE_NAME}"
echo "IAM DB User: ${GSA_EMAIL}"
echo "Databases: ${DATABASES[*]}"

# -------------------------------
# 1. Enable IAM DB authentication
# -------------------------------
echo "Enabling IAM DB authentication (if not already enabled)..."

gcloud sql instances patch "${INSTANCE_NAME}" \
  --project="${PROJECT_ID}" \
  --database-flags=cloudsql.iam_authentication=on \
  --quiet

echo "IAM DB authentication enabled."

# -------------------------------
# 2. Connect to Cloud SQL as admin
# -------------------------------
echo
echo "Next steps require psql access."
echo "Run the following command in another terminal or Cloud Shell:"
echo
echo "  gcloud sql connect ${INSTANCE_NAME} --project=${PROJECT_ID} --user=postgres"
echo
echo "Then paste the SQL below."
echo "---------------------------------------------"

cat <<'SQL'
-- ============================================================
-- Create a single IAM-authenticated DB user
-- ============================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_roles
    WHERE rolname = 'vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com'
  ) THEN
    CREATE ROLE "vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com"
      WITH LOGIN;
  END IF;
END
$$;

-- ============================================================
-- Grant access to Vikunja database
-- ============================================================
GRANT ALL PRIVILEGES ON DATABASE vikunja
TO "vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com";

\c vikunja

GRANT ALL PRIVILEGES ON SCHEMA public
TO "vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com";

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public
TO "vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com";

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public
TO "vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com";

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES
TO "vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com";

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES
TO "vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com";

-- ============================================================
-- Grant access to Keycloak database
-- ============================================================
\c keycloak

GRANT ALL PRIVILEGES ON SCHEMA public
TO "vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com";

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public
TO "vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com";

GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public
TO "vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com";

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON TABLES
TO "vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com";

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT ALL ON SEQUENCES
TO "vikunja-cloudsql@jithin-gcp-1234.iam.gserviceaccount.com";

-- ============================================================
-- Done
-- ============================================================
SQL

echo "---------------------------------------------"
echo "SQL printed. Execute it inside psql."
echo "Script completed."
