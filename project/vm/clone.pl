##########################
# clone.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_vmname_destination} = q{$[esx_vmname_destination]};
$opts->{esx_vmhost_destination} = q{$[esx_vmhost_destination]};
$opts->{esx_datastore} = q{$[esx_datastore]};
$opts->{esx_number_of_clones} = q{$[esx_number_of_clones]};

$[/myProject/procedure_helpers/preamble]

$gt->clone();
exit($opts->{exitcode});