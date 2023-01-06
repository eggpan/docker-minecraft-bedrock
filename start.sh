#!/bin/bash -e

if [ ! -f 'bedrock_server' ]; then
  curl -O "https://minecraft.azureedge.net/bin-linux/bedrock-server-${MINECRAFT_VERSION}.zip"
  unzip bedrock-server-*.zip
  rm bedrock-server-*.zip
fi


if [ -z "$ALLOW_CHEATS" ]; then
  ALLOW_CHEATS=true
fi

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

./bedrock_server 0</proc/self/fd/0 1>/proc/self/fd/1 2>/proc/self/fd/2 &
MINECRAFT_PID=$!

terminate() {
  echo Terminating Minecraft... $MINECRAFT_PID
  echo stop > /proc/${MINECRAFT_PID}/fd/0
  while [ true ]; do
    pgrep bedrock_server > /dev/null && :
    if [ $? -eq 1 ]; then
      exit 0
    fi
    sleep 1
  done
}
trap terminate TERM
wait
