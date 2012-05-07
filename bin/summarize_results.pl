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
# summarize validation results
#
use strict;
use warnings;

# Format:
# Stats for xxxxxx.example.com/hammer-0: min: 100890982; max: 102994870; last: 102994870; duplicated: 0; dropped: 0; total: 2103889;

my %stats = ();

while (defined(my $line = <>)) {
  chomp $line;
  if ($line =~ /Stats for (\S+): min: (\d+); max: (\d+); last: (\d+); duplicated: (\d+); dropped: (\d+); total: (\d+);/) {
    my $key = $1;
    my $record = { min => $2, max => $3, last => $4, dups => $5, drops => $6, tot => $7 };

    if (!defined $stats{$key}) {
      $stats{$key} = [];
    }

    push @{$stats{$key}}, $record;

  } else {
    die "ERROR: bad line: $line\n";
  }
}

my $grand_tot = 0;

# sort keys alpha
foreach my $key (sort keys %stats) {
  # sort records by min, numerically ascending
  my $max = 0;
  my $ok = 1;
  my $tot = 0;
  foreach my $record (sort { $a->{min} <=> $b->{min} } @{$stats{$key}}) {
    print "DEBUG: $key: " . $record->{min} . " : " . $record->{max} . "\n";
    if ($record->{min} > ($max + 1)) {
      print "ERROR: $key: inter-file drops detected: current min (" . $record->{min} . ") is " . ($record->{min} - $max) . " greater than last (" . $max . ")" . "\n";
      $ok = 0;
    }

    if ($record->{drops} > 0) {
      print "ERROR: $key: drops: " . $record->{drops} . "\n";
      $ok = 0;
    }

    if ($record->{dups} > 0) {
      print "WARNING: $key: dups: " . $record->{dups} . "\n";
    }

    # sometimes we get strange overlaps
    if ($record->{max} > $max) {
      $max = $record->{max};
    }

    $tot += $record->{tot};
  }

  if ($ok) {
    print "INFO: $key: total=$tot is OK\n";
  }

  $grand_tot += $tot;

}

print "INFO: grand total=$grand_tot\n";

exit 0;
