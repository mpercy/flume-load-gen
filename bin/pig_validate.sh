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
BASEDIR=$(cd $(dirname $0)/..; pwd)
LIB="$BASEDIR/lib"
LOGS="$BASEDIR/logs"

INPUT="$1"
[ "x" != "x$1" ] && shift
OUTPUT="$1"
[ "x" != "x$1" ] && shift

if [[ -z $INPUT || -z $OUTPUT ]]; then
  echo "Usage: $0 input_file output_file [-x local]"
  exit 1
fi

if [ ! -d "$LOGS" ]; then
  mkdir "$LOGS"
fi
cd "$LOGS"

set -x
export PIG_CLASSPATH="$LIB"
pig -Dpig.splitCombination=false $* -p "INPUT=$INPUT" -p "OUTPUT=$OUTPUT" -p "SCRIPT=$BASEDIR/bin/validate.pl" -f "$BASEDIR/src/main/pig/validate.pig"
