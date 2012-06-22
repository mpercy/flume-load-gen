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
# validates syslog sink output to files
#
# TODO: refactor to use Math::BigInt if needed
#
use strict;
use warnings;
use JSON qw(decode_json);
use Data::Dumper qw(Dumper);

my %stats = ();

# cache stats in stats structure
sub cache($$) {
  my $host = shift;
  my $num = shift;

  my $host_cache = $stats{$host};
  if (!defined $host_cache) {
    $host_cache = {};
    $host_cache->{dropped} = 0;
    $host_cache->{duplicated} = 0;
    $stats{$host} = $host_cache;
  }

  if (!defined $host_cache->{total}) {
    $host_cache->{total} = 0;
  }
  $host_cache->{total}++;

  if (!defined $host_cache->{min} || $host_cache->{min} > $num) {
    $host_cache->{min} = $num;
  }

  if (!defined $host_cache->{max} || $host_cache->{max} < $num) {
    $host_cache->{max} = $num;
  }
}

sub validate($$) {
  my $host = shift;
  my $num = shift;

  my $host_cache = $stats{$host};
  if (defined $host_cache->{last}) {
    my $expectedLast = $num - 1;
    if ($host_cache->{last} < $expectedLast) {
      # we dropped events!
      $host_cache->{dropped} += ($expectedLast - $host_cache->{last});
    } elsif ($host_cache->{last} > $expectedLast) {
      # we have duplicates
      $host_cache->{duplicated} += ($host_cache->{last} - $expectedLast);
    }
  }
  $host_cache->{last} = $num;
}

sub print_stats() {
  for my $host (sort keys %stats) {
    print "Stats for $host: ";
    for my $stat qw(min max last duplicated dropped total) {
      print "$stat: " . $stats{$host}->{$stat} . "; ";
    }
    print "\n";
  }
}

###############

if (@ARGV && $ARGV[0] =~ /^--?h(elp)?$/) {
  shift @ARGV;
  die <<"EOF";
Usage: $0 [options] [files]
Options: -h, --help : display this help
         -j, --json : Parse json input instead of normal pig-formatted text
EOF
}

my $jsonMode = 0;
if (@ARGV && $ARGV[0] =~ /^--?j(son)?$/) {
  shift @ARGV;
  $jsonMode = 1;
}

my $line;
while (defined($line = <>)) {
  chomp $line;
  my ($host, $num);
  if (!$jsonMode) {
    my @fields = split /\s+/, $line;
    $host = $fields[1] . "/" . $fields[2];
    $num = int($fields[3]);
  } else {
    my $record = decode_json($line);
    my @fields = split /\s+/, $record->{"body"};
    $host = $record->{"headers"}->{"host"} . "/" . $fields[0];
    $num = int($fields[1]);
  }
  cache($host, $num);
  validate($host, $num);
}

print_stats();
exit 0;
