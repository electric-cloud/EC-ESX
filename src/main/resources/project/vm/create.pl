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
# create.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_datastore} = q{$[esx_datastore]};
$opts->{esx_vmhost} = q{$[esx_vmhost]};
$opts->{esx_datacenter} = q{$[esx_datacenter]};
$opts->{esx_guestid} = q{$[esx_guestid]};
$opts->{esx_disksize} = q{$[esx_disksize]};
$opts->{esx_memory} = q{$[esx_memory]};
$opts->{esx_num_cpus} = q{$[esx_num_cpus]};
$opts->{esx_nic_network} = q{$[esx_nic_network]};
$opts->{esx_nic_poweron} = q{$[esx_nic_poweron]};
$opts->{esx_number_of_vms} = q{$[esx_number_of_vms]};
$opts->{esx_vm_poweron} = q{$[esx_vm_poweron]};

$[/myProject/procedure_helpers/preamble]

$gt->create();
exit($opts->{exitcode});