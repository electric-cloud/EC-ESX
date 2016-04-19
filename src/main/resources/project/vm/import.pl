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
# import.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_host} = q{$[esx_host]};
$opts->{esx_datastore} = q{$[esx_datastore]};
$opts->{esx_import_file_type} = q{$[esx_import_file_type]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_source_directory} = q{$[esx_source_directory]};
$opts->{esx_number_of_vms} = q{$[esx_number_of_vms]};
$opts->{esx_timeout} = q{$[esx_timeout]};

$[/myProject/procedure_helpers/preamble]

$gt->import();
exit($opts->{exitcode});
