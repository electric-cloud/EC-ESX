##########################
# registervm.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{sdk_installation_path} = '$[sdk_installation_path]';
$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_host} = q{$[esx_host]};
$opts->{esx_datacenter} = q{$[esx_datacenter]};
$opts->{esx_pool} = q{$[esx_pool]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_vmxpath} = q{$[esx_vmxpath]};
$opts->{esx_timeout} = "$[esx_timeout]";

$[/myProject/procedure_helpers/preamble]

$gt->register();
exit($opts->{exitcode});