#!/bin/bash
set -e


echo "===== Creating Python environment ====="
python3 -m venv /opt/selenium-env
/opt/selenium-env/bin/pip install --upgrade pip
/opt/selenium-env/bin/pip install selenium

echo "===== Done installing Selenium + ChromeDriver ====="


# -----------------------------
# provisioning as test agent
# -----------------------------
echo "provisioning as test agent..."
# -----------------------------
# PARAMETERS
# -----------------------------
PAT_TOKEN="${PAT_TOKEN}"                # PAT token
AZDO_ORG_URL="${AZDO_ORG_URL}"             # Example: https://dev.azure.com/odluser290301
PROJECT_NAME="${PROJECT_NAME}"             # Example: quality_release
ENV_NAME="${ENV_NAME}"                 # Example: test_env
SERVICE_CONNECTION="${SERVICE_CONNECTION}"       # Example: my-service-connection
VM_TAGS="${VM_TAGS}"                  # Example: selenium,web
ADMIN_USER="${ADMIN_USER}"

AGENT_DIR="/home/${ADMIN_USER}/myagent"

# -----------------------------
# CHECK IF ALREADY INSTALLED
# -----------------------------
if [ -f "$AGENT_DIR/.agent" ]; then
  echo "Agent already configured. Skipping registration."
  exit 0
fi

# -----------------------------
# INSTALL AGENT
# -----------------------------
echo "Agent not configured. Installing..."

mkdir -p $AGENT_DIR

curl -fkSL -o /tmp/vstsagent.tar.gz   https://download.agent.dev.azure.com/agent/4.264.2/vsts-agent-linux-x64-4.264.2.tar.gz

tar -zxvf /tmp/vstsagent.tar.gz -C $AGENT_DIR
chown -R ${ADMIN_USER}:${ADMIN_USER} $AGENT_DIR

echo "Configuring agent for ${ENV_NAME} pool on ${AZDO_ORG_URL}..."
su - ${ADMIN_USER} -c "
  cd $${AGENT_DIR} && \
    printf \"y\n${VM_TAGS}\n\" | ./config.sh --environment \
    --environmentname \"$ENV_NAME\" \
    --acceptteeeula \
    --agent \"$HOSTNAME\" \
    --url \"$AZDO_ORG_URL\" \
    --projectname \"$PROJECT_NAME\" \
    --work _work \
    --auth PAT \
    --token \"$PAT_TOKEN\" \
    --environmentServiceNameAzureRM \"$SERVICE_CONNECTION\" \
    --runasservice \
    --replace
"



sudo ./svc.sh install
sudo ./svc.sh start


echo "Agent installation complete."
