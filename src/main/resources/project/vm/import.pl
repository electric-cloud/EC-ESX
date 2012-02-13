##########################
# import.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_host} = q{$[esx_host]};
$opts->{esx_datastore} = q{$[esx_datastore]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_source_directory} = q{$[esx_source_directory]};
$opts->{esx_number_of_vms} = q{$[esx_number_of_vms]};
$opts->{esx_timeout} = q{$[esx_timeout]};

$[/myProject/procedure_helpers/preamble]

$gt->import();
exit($opts->{exitcode});