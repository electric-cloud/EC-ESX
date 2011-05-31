##########################
# createresourcefromvm.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_number_of_vms} = q{$[esx_number_of_vms]};
$opts->{esx_properties_location} = q{$[esx_properties_location]};
$opts->{esx_create_resources} = q{$[esx_create_resources]};
$opts->{esx_pools} = q{$[esx_pools]};
$opts->{esx_workspace} = q{$[esx_workspace]};

$[/myProject/procedure_helpers/preamble]

$gt->createresourcefromvm();
exit($opts->{exitcode});