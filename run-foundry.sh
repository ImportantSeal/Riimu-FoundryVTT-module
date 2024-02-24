#!/usr/bin/env bash

run() {
  if [ -z "${FOUNDRY_VERSION}" ]; then
    FOUNDRY_VERSION=latest
  fi

  CONTAINER_NAME="FoundryVTT_${FOUNDRY_VERSION}${DATA_SUFFIX}"
  CURRENT_CONTAINER_VERSION_EXISTS=$(docker ps -q -f name="^${CONTAINER_NAME}$")

  if [ -z "${CURRENT_CONTAINER_VERSION_EXISTS}" ]; then
    stop

    docker pull felddy/foundryvtt:${FOUNDRY_VERSION}

    docker run \
      -d \
      --env FOUNDRY_USERNAME="${FOUNDRY_USERNAME}" \
      --env FOUNDRY_PASSWORD="${FOUNDRY_PASSWORD}" \
      --env CONTAINER_PRESERVE_CONFIG="true" \
      --env CONTAINER_PRESERVE_OWNER=".*custom-system-builder.*" \
      --publish 30000:30000/tcp \
      --volume ~/FoundryData_${FOUNDRY_VERSION}${DATA_SUFFIX}:/data \
      --volume "$(pwd)":/data/Data/systems/custom-system-builder:ro \
      --name "${CONTAINER_NAME}" \
      felddy/foundryvtt:${FOUNDRY_VERSION}

    if [ -n "${WAIT_FOR_START}" ]; then
      docker logs -f "${CONTAINER_NAME}" 2>&1 | grep -m 1 "Server started and listening on port 30000"
    fi
  fi

  if [ -n "${SHOW_LOGS}" ]; then
    log
  else
    echo "Running at http://localhost:30000"
  fi

}

stop() {
  LAST_CONTAINER_ID=$(docker ps -aq -f name="FoundryVTT")
  if [ -n "${LAST_CONTAINER_ID}" ]; then
    docker stop "${LAST_CONTAINER_ID}" && docker rm "${LAST_CONTAINER_ID}"
  fi
}

log() {
  LAST_CONTAINER_ID=$(docker ps -aq -f name="FoundryVTT")
  if [ -n "${LAST_CONTAINER_ID}" ]; then
    docker logs -f "${LAST_CONTAINER_ID}"
  fi
}

COMMAND=$1
shift

if [ -f .env ]; then
  source .env
fi

while [[ $# -gt 0 ]]; do
  case $1 in
  -l | --login)
    FOUNDRY_USERNAME="$2"
    shift # past argument
    shift # past value
    ;;
  -p | --password)
    FOUNDRY_PASSWORD="$2"
    shift # past argument
    shift # past value
    ;;
  -v | --foundry-version)
    FOUNDRY_VERSION="$2"
    shift # past argument
    shift # past value
    ;;
  -s | --data-suffix)
    DATA_SUFFIX="$2"
    shift # past argument
    shift # past value
    ;;
  --logs)
    SHOW_LOGS="true"
    shift # past argument
    shift # past value
    ;;
  --wait-for-start)
    WAIT_FOR_START="true"
    shift # past argument
    shift # past value
    ;;
  *)
    echo "Unknown option $1"
    exit 1
    ;;
  esac
done

case "${COMMAND}" in
run)
  run
  ;;
stop)
  stop
  ;;
log)
  log
  ;;
*)
  echo "Unknown command $COMMAND"
  exit 1
  ;;
esac
