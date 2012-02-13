##########################
# getvmconfiguration.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_number_of_vms} = q{$[esx_number_of_vms]};
$opts->{esx_properties_location} = q{$[esx_properties_location]};

$[/myProject/procedure_helpers/preamble]

$gt->getvmconfiguration();
exit($opts->{exitcode});