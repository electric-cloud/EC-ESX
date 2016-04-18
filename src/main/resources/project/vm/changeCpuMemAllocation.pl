#
#  Copyright 2015 Electric Cloud, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

##########################
# changeCpuMemAllocation.pl
##########################
use warnings;
use strict;

my $opts;
print "Changing CPU/Memory Allocation\n";
$opts->{connection_config} = q{$[connection_config]};
$opts->{vm_name} = q{$[vm_name]};
$opts->{num_cpu} = q{$[num_cpu]};
$opts->{memory_mb} = q{$[memory_mb]};

$[/myProject/procedure_helpers/preamble]

$gt->changeCpuMemAllocation();
exit($opts->{exitcode});
