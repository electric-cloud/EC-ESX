##########################
# clone.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{sdk_installation_path} = '$[sdk_installation_path]';
$opts->{connection_config} = "$[connection_config]";
$opts->{esx_vmname} = "$[esx_vmname]";
$opts->{esx_vmname_destination} = "$[esx_vmname_destination]";
$opts->{esx_vmhost_destination} = "$[esx_vmhost_destination]";
$opts->{esx_datastore} = "$[esx_datastore]";
$opts->{esx_number_of_clones} = "$[esx_number_of_clones]";

$[/myProject/procedure_helpers/preamble]

$gt->clone();
exit($opts->{exitcode});