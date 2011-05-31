##########################
# cleanup.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_delete_vm} = q{$[esx_delete_vm]};
$opts->{esx_number_of_vms} = q{$[esx_number_of_vms]};

$[/myProject/procedure_helpers/preamble]

$gt->cleanup();
exit($opts->{exitcode});