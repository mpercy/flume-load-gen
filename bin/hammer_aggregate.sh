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
# This code parses the output from flume-hammer clients and captures a snapshot
# of the aggregate throughput of the load generation clients
#
BASEDIR=$(cd $(dirname $0)/..; pwd)
LOGS="$BASEDIR/logs"
(for log in $LOGS/hammer-*.log; do echo -n "$log: "; tail -n 1 $log; done)
(for log in $LOGS/hammer-*.log; do echo -n "$log: "; tail -n 1 $log; done) | awk '{print $19}' | \
  perl -ne 'chomp; $sum+=$_; $count++; END{$avg=sprintf("%.2f", $sum/$count); print "NUM: $count flows; TOTAL: $sum rps; AVG: $avg rps\n";}'
