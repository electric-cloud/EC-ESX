##########################
# cleanup.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{sdk_installation_path} = '$[sdk_installation_path]';
$opts->{connection_config} = "$[connection_config]";
$opts->{esx_vmname} = "$[esx_vmname]";
$opts->{esx_delete_vm} = "$[esx_delete_vm]";
$opts->{esx_number_of_vms} = "$[esx_number_of_vms]";

$[/myProject/procedure_helpers/preamble]

$gt->cleanup();
exit($opts->{exitcode});