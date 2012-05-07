#!/bin/bash -e
################################################################################
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
################################################################################
HOST=$1
START_PORT=$2
NUM_INSTANCES=$3
EVENT_SIZE=$4
EVENTS_PER_SEC=$5
LOG_INTERVAL=$6

JAVA=/usr/bin/java

if [[ -z "$HOST" || -z "$START_PORT" || -z "$NUM_INSTANCES" || -z "$EVENT_SIZE" || -z "$EVENTS_PER_SEC" || -z "$LOG_INTERVAL" ]]; then
  echo "Usage: $0 hostname start_port num_instances event_size events_per_sec log_interval_secs"
  exit 1
fi

BASEDIR=$(cd $(dirname $0)/..; pwd)
JAR="$BASEDIR/target/flume-hammer-1.0-SNAPSHOT-jar-with-dependencies.jar"

LOGDIR="$BASEDIR/logs"
if [ ! -d "$LOGDIR" ]; then
  mkdir "$LOGDIR"
fi

INSTANCE=0
PORT="$START_PORT"
while [[ "$INSTANCE" -lt "$NUM_INSTANCES" ]]; do
  TAG="hammer-$INSTANCE"
  LOG="$LOGDIR/$TAG.log"
  set -x
  nohup $JAVA -Xms50m -Xmx50m -jar "$JAR" "$HOST" "$PORT" "$TAG" "$EVENT_SIZE" "$EVENTS_PER_SEC" "$LOG_INTERVAL" > "$LOG" &
  INSTANCE=$(expr $INSTANCE + 1)
  PORT=$(expr $PORT + 1)
done
