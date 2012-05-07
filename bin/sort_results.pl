#!/usr/bin/perl
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
# sort according to key and then min
#
use strict;
use warnings;

# Format:
# Stats for xxxxxx.example.com/hammer-0: min: 100890982; max: 102994870; last: 102994870; duplicated: 0; dropped: 0; total: 2103889;

my @lines = <>;
chomp @lines;
my @sorted = sort {

  my @aFields = split(/\s+/, $a);
  my @bFields = split(/\s+/, $b);
  my $keyCmp = $aFields[2] cmp $bFields[2];
  if ($keyCmp != 0) { return $keyCmp; }
  my $aMin = $aFields[4]; chop $aMin;
  my $bMin = $bFields[4]; chop $bMin;
  return $aMin <=> $bMin;

} @lines;
print join("\n", @sorted), "\n";

exit 0;
