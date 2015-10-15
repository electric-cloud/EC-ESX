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
# createresourcefromvm.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_number_of_vms} = q{$[esx_number_of_vms]};
$opts->{esx_properties_location} = q{$[esx_properties_location]};
$opts->{esx_create_resources} = q{$[esx_create_resources]};
$opts->{esx_pools} = q{$[esx_pools]};
$opts->{esx_workspace} = q{$[esx_workspace]};

$[/myProject/procedure_helpers/preamble]

$gt->createresourcefromvm();
exit($opts->{exitcode});