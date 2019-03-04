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
# clone.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_vmname_destination} = q{$[esx_vmname_destination]};
$opts->{esx_vmhost_destination} = q{$[esx_vmhost_destination]};
$opts->{esx_datastore} = q{$[esx_datastore]};
$opts->{esx_number_of_clones} = q{$[esx_number_of_clones]};
$opts->{esx_apply_customization} = q{$[esx_apply_customization]};
$opts->{esx_customization_spec} = q{$[esx_customization_spec]};

$[/myProject/procedure_helpers/preamble]

$gt->clone();
exit($opts->{exitcode});