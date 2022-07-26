#!/bin/bash

export PATH=/bin:/usr/bin

# Script params
scriptPid=$$
scriptName="$(basename "$0")"
scriptPath="$(cd "$(dirname "$0")" && pwd)"
curlParams='-s -k'

# Passed params from Jenkins pipeline
portainerEndpoint=${1:-}
stackName=${2:-}
stackFile=${3:-}
userName=${4:-}
password=${5:-}
portainerBaseUrl=${6:-}

# Static params
prune=false
stackJsonFile="${scriptPath}/${stackName}.json"

# Output log
_log() {
    echo "$(date -u "+%FT%TZ") ${scriptName}[${scriptPid}]${1+" $@"}"
}

# Login to get token
token=$(curl $curlParams -X 'POST' "$portainerBaseUrl/api/auth" -H 'Accept: application/json' -d "{\"password\": \"${password}\", \"username\": \"${userName}\"}" | jq -r '.jwt')

# Logout
_logout(){
    logout=$(curl $curlParams -X 'POST' "$portainerBaseUrl/api/auth/logout" -H 'Accept: application/json' -H "Authorization: Bearer ${token}")
}

# Getting Environment/Endpoint ID
endpointID=$(curl $curlParams -X 'GET' "$portainerBaseUrl/api/endpoints?search=$portainerEndpoint" -H 'Accept: application/json' -H "Authorization: Bearer ${token}" | jq -r '.[].Id')

# Getting Swarm cluster ID
swarmId=$(curl $curlParams -X 'GET' "$portainerBaseUrl/api/endpoints/$endpointID/docker/swarm" -H 'Accept: application/json' -H "Authorization: Bearer ${token}" | jq -r '.ID')

# Getting all stack in the swarm cluster
stacks=$(curl $curlParams -X 'GET' "$portainerBaseUrl/api/stacks?filters=%7B%22SwarmID%22:%22$swarmId%22,%22IncludeOrphanedStacks%22:true%7D" -H 'Accept: application/json' -H "Authorization: Bearer ${token}")

# Covert yaml file to json object
_convertFile(){
    if [ -s ${stackFile} ]; then
        dc=$(cat "${stackFile}")
        dc="${dc//$'\r'/''}"
        dc="${dc//$'"'/'\"'}"
        dc="${dc//$'\n'/'\n'}"
        suffix="\",\"Env\":"${stackEnv}",\"Prune\":${prune}}"
        echo "${prefix}${dc}${suffix}" > ${stackJsonFile}
    else
        _log "File '${stackFile}' is empty"
        _logout
    fi
}

# Deploy new stack
_deploy(){
    # Params for first deploy
    stackEnv="[]"
    prefix="{\"Name\":\"${stackName}\",\"SwarmID\":\"${swarmId}\",\"StackFileContent\":\""
    _convertFile
    _log "Deploying new stack '$stackName'"

    deploy=$(curl $curlParams -X 'POST' \
    "${portainerBaseUrl}/api/stacks?type=1&method=string&endpointId=${endpointID}" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json;charset=UTF-8" \
    -H 'Cache-Control: no-cache' \
    --data-binary "@${stackJsonFile}")

    echo $deploy
}

# Update existing stack
_update(){
    # Params for update
    stackId="$(echo "${stack}" | jq -j ".Id")"
    stackEnv="$(echo -n "${stack}" | jq ".Env" -jc)"
    prefix="{\"Id\":\"${stackId}\",\"StackFileContent\":\""
    _convertFile
    _log "Updating stack '$stackName'"

    update=$(curl $curlParams -X 'PUT' \
    "${portainerBaseUrl}/api/stacks/${stackId}?endpointId=${endpointID}" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json;charset=UTF-8" \
    -H 'Cache-Control: no-cache' \
    --data-binary "@${stackJsonFile}")

    echo $update
}

# Get stack
stack=$(echo $stacks | jq --arg TARGET "${stackName}" -jc '.[] | select(.Name == $TARGET)')

# Check result of Get stack
if [ "${stack}" = "" ]; then
    _deploy
else
    _update
fi

rm -rf ${stackJsonFile}
_logout
