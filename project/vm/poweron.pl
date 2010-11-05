##########################
# poweron.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{sdk_installation_path} = '$[sdk_installation_path]';
$opts->{connection_config} = "$[connection_config]";
$opts->{esx_vmname} = "$[esx_vmname]";
$opts->{esx_properties_location} = "$[esx_properties_location]";
$opts->{esx_create_resources} = "$[esx_create_resources]";
$opts->{esx_pools} = "$[esx_pools]";
$opts->{esx_workspace} = "$[esx_workspace]";
$opts->{esx_number_of_vms} = "$[esx_number_of_vms]";

$[/myProject/procedure_helpers/preamble]

$gt->poweron();
exit($opts->{exitcode});