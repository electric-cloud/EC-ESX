##########################
# snapshot.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = "$[connection_config]";
$opts->{esx_vmname} = "$[esx_vmname]";
$opts->{esx_snapshotname} = "$[esx_snapshotname]";

$[/myProject/procedure_helpers/preamble]

$gt->snapshot();
exit($opts->{exitcode});