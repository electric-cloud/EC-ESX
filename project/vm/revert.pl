##########################
# revert.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = "$[connection_config]";
$opts->{esx_vmname} = "$[esx_vmname]";
$opts->{esx_snapshotname} = "$[esx_snapshotname]";
$opts->{esx_poweron_vm} = "$[esx_poweron_vm]";

$[/myProject/procedure_helpers/preamble]

$gt->revert();
exit($opts->{exitcode});