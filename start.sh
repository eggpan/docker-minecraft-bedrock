#!/bin/bash -e

curl -O "https://minecraft.azureedge.net/bin-linux/bedrock-server-${MINECRAFT_VERSION}.zip"
unzip -o bedrock-server-${MINECRAFT_VERSION}.zip
rm bedrock-server-${MINECRAFT_VERSION}.zip

PARAMS=(
  'SERVER_NAME'
  'GAMEMODE'
  'FORCE_GAMEMODE'
  'DIFFICULTY'
  'ALLOW_CHEATS'
  'MAX_PLAYERS'
  'ONLINE_MODE'
  'ALLOW_LIST'
  'SERVER_PORT'
  'SERVER_PORTV6'
  'ENABLE_LAN_VISIBILITY'
  'VIEW_DISTANCE'
  'TICK_DISTANCE'
  'PLAYER_IDLE_TIMEOUT'
  'MAX_THREADS'
  'LEVEL_NAME'
  'LEVEL_SEED'
  'DEFAULT_PLAYER_PERMISSION_LEVEL'
  'TEXTUREPACK_REQUIRED'
  'CONTENT_LOG_FILE_ENABLED'
  'COMPRESSION_THRESHOLD'
  'COMPRESSION_ALGORITHM'
  'SERVER_AUTHORITATIVE_MOVEMENT'
  'PLAYER_MOVEMENT_SCORE_THRESHOLD'
  'PLAYER_MOVEMENT_ACTION_DIRECTION_THRESHOLD'
  'PLAYER_MOVEMENT_DISTANCE_THRESHOLD'
  'PLAYER_MOVEMENT_DURATION_THRESHOLD_IN_MS'
  'CORRECT_PLAYER_MOVEMENT'
  'SERVER_AUTHORITATIVE_BLOCK_BREAKING'
  'CHAT_RESTRICTION'
  'DISABLE_PLAYER_INTERACTION'
  'CLIENT_SIDE_CHUNK_GENERATION_ENABLED'
)

for PARAM in "${PARAMS[@]}"
do
  PROPERTY=$(echo "$PARAM" | tr [:upper:] [:lower:] | tr _ -)
  if [ -n "${!PARAM}" ];then
    echo "set property: ${PROPERTY}=${!PARAM}"
    sed -i -r "s/^(${PROPERTY})=.*/\1=${!PARAM}/" /data/server.properties
  fi
done

grep -Eq 'emit-server-telemetry' /data/server.properties && :
if [ $? -eq 1 ]; then
  echo -e "\nemit-server-telemetry=true" >> /data/server.properties
fi

screen -d -m -S minecraft bash -c './bedrock_server 2>&1 | grep -Ev --line-buffered "Running AutoCompaction..." | tee /proc/1/fd/1'
while [ true ]; do
  pgrep bedrock_server > /dev/null && :
  if [ $? -eq 0 ]; then
    break
  fi
done

wait_bedrock_server_close() {
  while [ true ]; do
    pgrep bedrock_server > /dev/null && :
    if [ $? -eq 1 ]; then
      exit 0
    fi
    sleep 1
  done
}

terminate() {
  echo Terminating Minecraft...
  screen -S minecraft -X stuff stop^M
  wait_bedrock_server_close
}
trap terminate TERM

wait_bedrock_server_close &
wait
