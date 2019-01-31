#!/bin/bash
function add_ignition_unit() {
    local name=$1
    local contents=$2
    read -r -d '' unit <<EOF
{
  "name": "${name}",
  "contents": "${contents}"
}
EOF

  IGNITION_CONTENT=$(echo "${IGNITION_CONTENT}" | jq -c " . [\"systemd\"][\"units\"] += [$unit]")
}

function add_ignition_file() {
    local path=$1
    local user=$2
    local perm=$3
    local filesystem=$4
    local content=$(echo "$5" | base64)
    local file_entry=""

    # compose a json entry with given parameters
    read -r -d '' file_entry <<EOF
{
  "filesystem": "${filesystem}",
  "path": "${path}",
  "user": { "name": "${user}" },
  "contents": {
    "source": "data:text/plain;charset=utf-8;base64,${content}",
    "verification": {}
  },
  "mode": "${perm}"
}
EOF
    IGNITION_CONTENT=$(echo "${IGNITION_CONTENT}" | jq -c " . [\"storage\"][\"files\"] += [$file_entry]")
}

IGNITION_CONTENT=$(cat $1)
ETCD_CONTENTS="[Unit]\nDescription=Start etcd pod\nBefore=bootkube.service\nConditionPathExists=!/opt/openshift/.bootetcd.done\n\n[Service]\nWorkingDirectory=/opt/openshift\nExecStart=/usr/local/bin/bootetcd.sh\n\nRestart=on-failure\nRestartSec=5s\n"
PODETCD_CONTENTS="podman run -d  -p 2379:2379   -p 2380:2380 --net=host  --name etcd quay.io/coreos/etcd:latest   /usr/local/bin/etcd   --data-dir=/etcd-data --name node1   --initial-advertise-peer-urls http://127.0.0.1:2380 --listen-peer-urls http://127.0.0.1:2380   --advertise-client-urls http://127.0.0.1:2379 --listen-client-urls http://127.0.0.1:2379   --initial-cluster node1=http://127.0.0.1:2380"

add_ignition_unit "bootetcd.service" "${ETCD_CONTENTS}"
add_ignition_file "/usr/local/bin/bootetcd.sh" root 365 root "${PODETCD_CONTENTS}"
echo "${IGNITION_CONTENT}" > $2
