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
if($opts->{esx_guestid} eq "") { $opts->{esx_guestid} = "winXPProGuest" }
$opts->{esx_disksize} = "$[esx_disksize]";
if($opts->{esx_disksize} eq "") { $opts->{esx_disksize} = 4096; }
$opts->{esx_memory} = "$[esx_memory]";
if($opts->{esx_memory} eq "") { $opts->{esx_memory} = 256; }
$opts->{esx_num_cpus} = "$[esx_num_cpus]";
if($opts->{esx_num_cpus} eq "") { $opts->{esx_num_cpus} = 1; }
$opts->{esx_nic_network} = "$[esx_nic_network]";
$opts->{esx_nic_poweron} = "$[esx_nic_poweron]";
if($opts->{esx_nic_poweron} eq "") { $opts->{esx_nic_poweron} = 1; }
$opts->{esx_number_of_vms} = "$[esx_number_of_vms]";
if($opts->{esx_number_of_vms} eq "") { $opts->{esx_number_of_vms} = 1; }
$opts->{exitcode} = 0;

$[/myProject/procedure_helpers/preamble]

$gt->create();
exit($opts->{exitcode});