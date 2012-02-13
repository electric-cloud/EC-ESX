##########################
# snapshot.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_snapshotname} = q{$[esx_snapshotname]};
$opts->{esx_number_of_vms} = q{$[esx_number_of_vms]};

$[/myProject/procedure_helpers/preamble]

$gt->snapshot();
exit($opts->{exitcode});