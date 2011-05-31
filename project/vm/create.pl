##########################
# create.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = q{$[connection_config]};
$opts->{esx_vmname} = q{$[esx_vmname]};
$opts->{esx_datastore} = q{$[esx_datastore]};
$opts->{esx_vmhost} = q{$[esx_vmhost]};
$opts->{esx_datacenter} = q{$[esx_datacenter]};
$opts->{esx_guestid} = q{$[esx_guestid]};
$opts->{esx_disksize} = q{$[esx_disksize]};
$opts->{esx_memory} = q{$[esx_memory]};
$opts->{esx_num_cpus} = q{$[esx_num_cpus]};
$opts->{esx_nic_network} = q{$[esx_nic_network]};
$opts->{esx_nic_poweron} = q{$[esx_nic_poweron]};
$opts->{esx_number_of_vms} = q{$[esx_number_of_vms]};
$opts->{esx_vm_poweron} = q{$[esx_vm_poweron]};

$[/myProject/procedure_helpers/preamble]

$gt->create();
exit($opts->{exitcode});