#!/bin/bash
function add_ignition_unit() {
    local unit=$1
    IGNITION_CONTENT=$(echo "${IGNITION_CONTENT}" | jq -c " . [\"systemd\"][\"units\"] += [$unit]")
}
IGNITION_CONTENT=$(cat $1)

read -r -d '' ETCD_UNIT <<'EOF'
{
  "contents": "[Unit]\nDescription=Start etcd pod\nWants=bootkube.service\nAfter=bootkube.service\nConditionPathExists=!/opt/openshift/.etcd.done\n\n[Service]\nWorkingDirectory=/opt/openshift\nExecStart=/usr/local/bin/bootetcd.sh\n\nRestart=on-failure\nRestartSec=5s\n",
  "name": "etcd.service"
}
EOF
add_ignition_unit "${ETCD_UNIT}"
echo "${IGNITION_CONTENT}" > $2

