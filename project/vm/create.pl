##########################
# create.pl
##########################
use warnings;
use strict;

my $opts;

$opts->{connection_config} = "$[connection_config]";
$opts->{esx_vmname} = "$[esx_vmname]";
$opts->{esx_datastore} = "$[esx_datastore]";
$opts->{esx_vmhost} = "$[esx_vmhost]";
$opts->{esx_datacenter} = "$[esx_datacenter]";
$opts->{esx_guestid} = "$[esx_guestid]";
$opts->{esx_disksize} = "$[esx_disksize]";
$opts->{esx_memory} = "$[esx_memory]";
$opts->{esx_num_cpus} = "$[esx_num_cpus]";
$opts->{esx_nic_network} = "$[esx_nic_network]";
$opts->{esx_nic_poweron} = "$[esx_nic_poweron]";
$opts->{esx_number_of_vms} = "$[esx_number_of_vms]";

$[/myProject/procedure_helpers/preamble]

$gt->create();
exit($opts->{exitcode});