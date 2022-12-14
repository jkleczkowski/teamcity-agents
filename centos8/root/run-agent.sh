#!/bin/bash

check() {
   if [[ $? != 0 ]]; then
      echo "Error! Stopping the script."
      exit 1
   fi
}

configure() {
  if [[ $# -gt 0 ]]; then
    echo "run agent.sh configure $@"
    ${AGENT_DIST}/bin/agent.sh configure "$@"; check
  fi
}

reconfigure() {
    declare -a opts
    [[ -n "${SERVER_URL}" ]]  && opts[${#opts[@]}]='--server-url' && opts[${#opts[@]}]="$SERVER_URL"
    [[ -n "${AGENT_TOKEN}" ]] && opts[${#opts[@]}]='--auth-token' && opts[${#opts[@]}]="$AGENT_TOKEN"
    [[ -n "${AGENT_NAME}" ]]  && opts[${#opts[@]}]='--name'       && opts[${#opts[@]}]="$AGENT_NAME"
    [[ -n "${OWN_ADDRESS}" ]] && opts[${#opts[@]}]='--ownAddress' && opts[${#opts[@]}]="$OWN_ADDRESS"
    [[ -n "${OWN_PORT}" ]]    && opts[${#opts[@]}]='--ownPort'    && opts[${#opts[@]}]="$OWN_PORT"
    if [[ 0 -ne "${#opts[@]}" ]]; then
      # Using sed to strip double quotes produced by docker-compose
      for i in $(seq 0 $(expr ${#opts[@]} - 1)); do
        opts[$i]="$(echo "${opts[$i]}" | sed -e 's/""/"/g')"
      done
      configure "${opts[@]}"
      echo "File ${AGENT_CONF_FILE_NAME} was updated"
    fi
    for AGENT_OPT in ${AGENT_OPTS}; do
      echo ${AGENT_OPT} >>  ${CONFIG_DIR}/${AGENT_CONF_FILE_NAME}
    done
}

prepare_conf() {
    echo "Will prepare agent config" ;
    cp -p ${AGENT_DIST}/conf_dist/*.* ${CONFIG_DIR}/; check
    cp -p ${CONFIG_DIR}/buildAgent.dist.properties ${CONFIG_DIR}/${AGENT_CONF_FILE_NAME}; check
    reconfigure
    echo "File ${AGENT_CONF_FILE_NAME} was created and updated" ;
}

AGENT_DIST=/opt/buildagent

CONFIG_DIR=/data/teamcity_agent/conf

LOG_DIR=/opt/buildagent/logs


rm -f ${LOG_DIR}/*.pid

if [ -f ${CONFIG_DIR}/${AGENT_CONF_FILE_NAME} ] ; then
   echo "File ${AGENT_CONF_FILE_NAME} was found in ${CONFIG_DIR}" ;
   reconfigure
   export CONFIG_FILE=${CONFIG_DIR}/${AGENT_CONF_FILE_NAME}
else
   echo "Will create new ${AGENT_CONF_FILE_NAME} using distributive" ;
   if [[ -n "${SERVER_URL}" ]]; then
      echo "TeamCity URL is provided: ${SERVER_URL}"
   else
      echo "TeamCity URL is not provided, but is required."
      exit 1
   fi
   prepare_conf
fi

if [ -z "$RUN_AS_BUILDAGENT" -o "$RUN_AS_BUILDAGENT" = "false" -o "$RUN_AS_BUILDAGENT" = "no" ]; then
    ${AGENT_DIST}/bin/agent.sh start
else
    echo "Make sure build agent directory ${AGENT_DIST} is owned by buildagent user"
    chown -R buildagent:buildagent ${AGENT_DIST}
    check; sync
    
    echo "Start build agent under buildagent user"
    sudo -E -u buildagent HOME=/home/buildagent ${AGENT_DIST}/bin/agent.sh start
fi



while [ ! -f ${LOG_DIR}/teamcity-agent.log ];
do
   echo -n "."
   sleep 1
done

trap '${AGENT_DIST}/bin/agent.sh stop force; while ps -p $(cat $(ls -1 ${LOG_DIR}/*.pid)) &>/dev/null; do sleep 1; done; kill %%' SIGINT SIGTERM SIGHUP

tail -qF ${LOG_DIR}/teamcity-agent.log &
wait
