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
# editCdDvdDrive.pl
##########################
use warnings;
use strict;

my $opts;
print "Editing already existing CD/DVD Drive\n";
$opts->{connection_config} = q{$[connection_config]};
$opts->{device_name} = q{$[device_name]};
$opts->{iso_image} = q{$[iso_image]};
$opts->{vm_name} = q{$[vm_name]};
$opts->{backing_type} = q{$[backing_type]};
$opts->{controller_type} = q{$[controller_type]};
$opts->{edit} = 1;

$[/myProject/procedure_helpers/preamble]

$gt->addOrEditCdDvdDrive();
exit($opts->{exitcode});
