##########################
# import.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = "$[connection_config]";
$opts->{esx_host} = "$[esx_host]";
$opts->{esx_datastore} = "$[esx_datastore]";
$opts->{esx_vmname} = "$[esx_vmname]";
$opts->{esx_source_directory} = q{$[esx_source_directory]};
$opts->{esx_number_of_vms} = $[esx_number_of_vms];
$opts->{esx_timeout} = "$[esx_timeout]";

$[/myProject/procedure_helpers/preamble]

$gt->import();
exit($opts->{exitcode});