##########################
# clone.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = "$[connection_config]";
$opts->{esx_vmname} = "$[esx_vmname]";
$opts->{esx_vmname_destination} = "$[esx_vmname_destination]";
$opts->{esx_vmhost_destination} = "$[esx_vmhost_destination]";
$opts->{esx_datastore} = "$[esx_datastore]";
$opts->{esx_operation} = "clone";
$opts->{exitcode} = 0;

$[/myProject/procedure_helpers/preamble]

$gt->clone_relocate();
exit($opts->{exitcode});