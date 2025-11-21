#!/bin/bash
set -e

# -----------------------------
# PARAMETERS
# -----------------------------
PAT_TOKEN="$1"                # PAT token
AZDO_ORG_URL="$2"             # Example: https://dev.azure.com/odluser290301
PROJECT_NAME="$3"             # Example: quality_release
ENV_NAME="$4"                 # Example: test_env
SERVICE_CONNECTION="$5"       # Example: my-service-connection
VM_TAGS="$6"                  # Example: selenium,web

AGENT_DIR="/home/azureuser/azagent"

# -----------------------------
# CHECK IF ALREADY INSTALLED
# -----------------------------
if [ -f "$AGENT_DIR/.agent" ]; then
  echo "Agent already configured. Skipping registration."
  cd $AGENT_DIR
  sudo ./svc.sh restart || true
  exit 0
fi

# -----------------------------
# INSTALL AGENT
# -----------------------------
echo "Agent not configured. Installing..."

mkdir -p $AGENT_DIR
cd $AGENT_DIR

curl -fkSL -o vstsagent.tar.gz \
  https://download.agent.dev.azure.com/agent/4.264.2/vsts-agent-linux-x64-4.264.2.tar.gz

tar -zxvf vstsagent.tar.gz

./config.sh --environment \
  --environmentname "$ENV_NAME" \
  --acceptteeeula \
  --agent "$HOSTNAME" \
  --url "$AZDO_ORG_URL" \
  --projectname "$PROJECT_NAME" \
  --work _work \
  --auth PAT \
  --token "$PAT_TOKEN" \
  --environmentServiceNameAzureRM "$SERVICE_CONNECTION" \
  --addvirtualmachinetags \
  --virtualmachinetags "$VM_TAGS" \
  --runasservice

sudo ./svc.sh install
sudo ./svc.sh start

echo "Agent installation complete."
