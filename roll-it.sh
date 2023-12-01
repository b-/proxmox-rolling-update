#!/usr/bin/env bash
# update-nodes/roll.sh
set -euxo pipefail


DO_SSH(){
  NODE=$1
  SSH_USER=$2
  shift
  shift
  SSH_COMMAND=('ssh' "${NODE}" '-l' "${SSH_USER}" 'sudo' "${@}")
  "${SSH_COMMAND[@]}"
}

# get list of nodes
GET_NODES(){
  #NODES=(192.168.12.5{1..5})
  API_METHOD='get'
  API_PATH='/nodes'
  API_CALL=("${API_METHOD}" "${API_PATH}")
  PVESH_QUERY=('pvesh' "${API_CALL[@]}" '--output-format' 'json')
  JQ_QUERY='.[].node'
  QUERY_NODE=n3
  # NODES=($(ssh 192.168.12.51 sudo pvecm nodes | tail -n+5 | tr -s '  ' | cut -d\  -f4))
  mapfile -t NODES < <(DO_SSH "${QUERY_NODE}" "${USER}" "${PVESH_QUERY[@]}" | jq -r "${JQ_QUERY}")
  export NODES
}

ROLL(){
  #!/bin/bash
  # roll.sh
  set -euxo pipefail
  NODE=$1
  DO_SSH "${NODE}" "${USER}" reboot

  DO_SSH "${NODE}" "${USER}" dmesg -w # wait on dmesg logs until reboot begins
  until DO_SSH "${NODE}" "${USER}" whoami # then loop until we can authenticate again
    do
      sleep 1s
    done
}

UPDATE_NODES(){
  for NODE in "${NODES[@]}"
  do
    DO_SSH "${NODE}" "${USER}" sudo apt-get update
    DO_SSH "${NODE}" "${USER}" sudo apt-get dist-upgrade -y --autoremove
  done
}

ROLL_NODES(){
  for NODE in "${NODES[@]}"
  do
    echo "REBOOTING NODE ${NODE} IN 5 SECONDS!"
    sleep 5s
    ROLL "${NODE}"
  done

}

main(){
  GET_NODES
  UPDATE_NODES
  ROLL_NODES
}

main
