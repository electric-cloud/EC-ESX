##########################
# revert.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_snapshotname} = q{$[esx_snapshotname]};
$opts->{esx_poweron_vm} = q{$[esx_poweron_vm]};
$opts->{esx_number_of_vms} = q{$[esx_number_of_vms]};

$[/myProject/procedure_helpers/preamble]

$gt->revert();
exit($opts->{exitcode});