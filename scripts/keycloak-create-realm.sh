kubectl exec -n keycloak keycloak-0 -- /bin/bash -c '
  # 1. Login (Just in case)
  /opt/bitnami/keycloak/bin/kcadm.sh config credentials \
    --server http://localhost:8080/auth \
    --realm master \
    --user admin \
    --password Password123! \
    --config /tmp/kcadm.config

  # 2. Create "vikunja" Realm (with SSL Disabled!)
  echo "Creating Realm..."
  /opt/bitnami/keycloak/bin/kcadm.sh create realms \
    -s realm=vikunja \
    -s enabled=true \
    -s sslRequired=NONE \
    --config /tmp/kcadm.config

  # 3. Create "vikunja-app" Client
  echo "Creating Client..."
  /opt/bitnami/keycloak/bin/kcadm.sh create clients -r vikunja \
    -s clientId=vikunja-app \
    -s protocol=openid-connect \
    -s publicClient=false \
    -s directAccessGrantsEnabled=true \
    -s standardFlowEnabled=true \
    -s "redirectUris=[\"http://http://34.50.155.115//*\"]" \
    -s "webOrigins=[\"*\"]" \
    -s secret="VikunjaSecret2026!" \
    --config /tmp/kcadm.config

  echo "----------------------------------------------"
  echo "✅ SUCCESS!"
  echo "Client ID:     vikunja-app"
  echo "Client Secret: VikunjaSecret2026!"
  echo "Realm URL:     http://http://34.50.155.115//auth/realms/vikunja"
  echo "----------------------------------------------"
'