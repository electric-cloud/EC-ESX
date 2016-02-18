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
# moveEntity.pl
##########################
use warnings;
use strict;

my $opts;
print "Moving Entity(VM/Folder) to  Folder";
$opts->{connection_config} = q{$[connection_config]};
$opts->{entity_type} = q{$[entity_type]};
$opts->{entity_name} = q{$[entity_name]};
$opts->{destination_name} = q{$[destination_name]};

$[/myProject/procedure_helpers/preamble]

$gt->moveEntity();
exit($opts->{exitcode});
