##########################
# relocate.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_vmhost_destination} = q{$[esx_vmhost_destination]};
$opts->{esx_datastore} = q{$[esx_datastore]};
$opts->{esx_number_of_vms} = q{$[esx_number_of_vms]};

$[/myProject/procedure_helpers/preamble]

$gt->relocate();
exit($opts->{exitcode});