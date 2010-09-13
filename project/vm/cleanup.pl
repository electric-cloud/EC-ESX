##########################
# cleanup.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = "$[connection_config]";
$opts->{esx_vmname} = "$[esx_vmname]";
$opts->{esx_save_vm} = "$[esx_save_vm]";

$[/myProject/procedure_helpers/preamble]

$gt->cleanup();
exit($opts->{exitcode});