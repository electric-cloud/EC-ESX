##########################
# registervm.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_host} = q{$[esx_host]};
$opts->{esx_datacenter} = q{$[esx_datacenter]};
$opts->{esx_pool} = q{$[esx_pool]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_vmxpath} = q{$[esx_vmxpath]};

$[/myProject/procedure_helpers/preamble]

$gt->register();
exit($opts->{exitcode});