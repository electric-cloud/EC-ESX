# -------------------------------------------------------------------------
# Package
#    ESX.pm
#
# Dependencies
#    VMware::VIRuntime
#
# Purpose
#    A perl library that encapsulates the logic to manipulate Virtual Machines on ESX using vSphere SDK for Perl
# -------------------------------------------------------------------------

package ESX;

# -------------------------------------------------------------------------
# Includes
# -------------------------------------------------------------------------
use warnings;
use strict;

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------
use constant {
	SUCCESS => 0,
	ERROR   => 1,
	
	DEFAULT_DEBUG    => 1,
	DEFAULT_SDK_PATH => 'C:\Program Files\VMware\VMware vSphere CLI\Perl\lib',
};

################################
# new - Object constructor for ESX
#
# Arguments:
#   opts hash
#
# Returns:
#   -
#
################################
sub new {
	my ( $class, $opts ) = @_;
	my $self = { _opts => $opts, };
	bless $self, $class;
}

################################
# initialize - Set initial values and load required modules
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub initialize {
	my ($self) = @_;
	$self->opts->{Debug} = DEFAULT_DEBUG;
	
	# Add specified or default location to @INC array
	if(defined($self->opts->{sdk_installation_path}) && $self->opts->{sdk_installation_path} ne '') {
		push @INC, $self->opts->{sdk_installation_path};
	}
	else {
		push @INC, DEFAULT_SDK_PATH;
	}
	require VMware::VIRuntime;
}

################################
# opts - Get opts hash
#
# Arguments:
#   -
#
# Returns:
#   opts hash
#
################################
sub opts {
	my ($self) = @_;
	return $self->{_opts};
}

################################
# ecode - Get exit code
#
# Arguments:
#   -
#
# Returns:
#   exit code number
#
################################
sub ecode {
	my ($self) = @_;
	return $self->opts()->{exitcode};
}

################################
# login - Establish a connection with ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub login {
	my ($self) = @_;

	# Connect only if url was set
	if ( defined( $self->opts->{esx_url} ) && $self->opts->{esx_url} ne "" ) {
		Vim::login(
			service_url => $self->opts->{esx_url},
			user_name   => $self->opts->{esx_user},
			password    => $self->opts->{esx_pass}
		);
	}
}

################################
# logout - Disconnect the client from the ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub logout {
	my ($self) = @_;
	Vim::logout();
}

################################
# create - Call create_vm the number of times specified  by 'esx_number_of_vms'
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub create {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Creating virtual machine '".$self->opts->{esx_vmname}."' ...";
		$out .= "\n";
		$out .= "Successfully created virtual machine: '".$self->opts->{esx_vmname}."' under host ".$self->opts->{esx_vmhost};
		$out .= "\n";
		$out .= "Powering on virtual machine '" . $self->opts->{esx_vmname} . "' ...";
		$out .= "\n";
		$out .= "Successfully powered on virtual machine: '" . $self->opts->{esx_vmname}."'";
		return $out;
	}
	
	$self->initialize();
	$self->login();
	
	my $count;
	if ( defined( $self->opts->{esx_number_of_vms} ) && $self->opts->{esx_number_of_vms} ne "" ) {
		$count = $self->opts->{esx_number_of_vms};
	}
	else {
		$count = 1;
	}
	my $vm_prefix = $self->opts->{esx_vmname};
	for ( my $i = 0 ; $i < $count ; $i++ ) {
		my $vm_name = $vm_prefix;
		if ( $i != 0 ) {
			$vm_name = $vm_name . "_$i";
		}
		$self->opts->{esx_vmname} = $vm_name;
		$self->create_vm();
	}

	$self->logout();
}

################################
# create_vm - Create a vm according to the specifications provided
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub create_vm {
	my ($self) = @_;
	my @vm_devices;

	my $host_view = Vim::find_entity_view(
		view_type => 'HostSystem',
		filter    => { 'name' => $self->opts->{esx_vmhost} }
	);
	if ( !$host_view ) {
		$self->debugMsg( 0,
			    'Error creating VM \''.$self->opts->{esx_vmname}.'\': '
			  . 'Host \''.$self->opts->{esx_vmhost}.'\' not found' );
		$self->opts->{exitcode} = ERROR;
		return;
	}

	my $ds_name = $self->opts->{esx_datastore};
	my %ds_info = $self->get_datastore($host_view, $ds_name);

	if ( $ds_info{mor} eq 0 ) {
		if ( $ds_info{name} eq 'datastore_error' ) {
			$self->debugMsg( 0,
				    'Error creating VM \''.$self->opts->{esx_vmname}.'\': '
				  . 'Datastore '.$self->opts->{esx_datastore}.' not available.' );
			$self->opts->{exitcode} = ERROR;
			return;
		}
		if ( $ds_info{name} eq 'disksize_error' ) {
			$self->debugMsg(0, 'Error creating VM \''.$self->opts->{esx_vmname}.'\': The free space '
				  . 'available is less than the specified disksize.'
			);
			$self->opts->{exitcode} = ERROR;
			return;
		}
	}
	my $ds_path = '[' . $ds_info{name} . ']';

	my $controller_vm_dev_conf_spec = $self->create_conf_spec();
	my $disk_vm_dev_conf_spec = $self->create_virtual_disk($ds_path);

	my %net_settings = $self->get_network($host_view);

	if ( $net_settings{'error'} eq 0 ) {
		push( @vm_devices, $net_settings{'network_conf'} );
	}
	elsif ( $net_settings{'error'} eq 1 ) {
		$self->debugMsg( 0,
			    'Error creating VM \''.$self->opts->{esx_vmname}.'\': '
			  . 'Network \''.$self->opts->{esx_nic_network}.'\' not found' );
		$self->opts->{exitcode} = ERROR;
		return;
	}

	push( @vm_devices, $controller_vm_dev_conf_spec );
	push( @vm_devices, $disk_vm_dev_conf_spec );

	my $files = VirtualMachineFileInfo->new(
		logDirectory      => undef,
		snapshotDirectory => undef,
		suspendDirectory  => undef,
		vmPathName        => $ds_path
	);
	my $vm_config_spec = VirtualMachineConfigSpec->new(
		name         => $self->opts->{esx_vmname},
		memoryMB     => $self->opts->{esx_memory},
		files        => $files,
		numCPUs      => $self->opts->{esx_num_cpus},
		guestId      => $self->opts->{esx_guestid},
		deviceChange => \@vm_devices
	);

	my $datacenter_views = Vim::find_entity_views(
		view_type => 'Datacenter',
		filter    => { name => $self->opts->{esx_datacenter} }
	);

	unless (@$datacenter_views) {
		$self->debugMsg( 0,
			    'Error creating VM \''.$self->opts->{esx_vmname}.'\': '
			  . 'Datacenter \''.$self->opts->{esx_datacenter}.'\' not found' );
		$self->opts->{exitcode} = ERROR;
		return;
	}

	if ( $#{$datacenter_views} != 0 ) {
		$self->debugMsg( 0,
			    'Error creating VM \''.$self->opts->{esx_vmname}.'\': '
			  . 'Datacenter \''.$self->opts->{esx_datacenter}.'\' not unique' );
		$self->opts->{exitcode} = ERROR;
		return;
	}
	my $datacenter = shift @$datacenter_views;

	my $vm_folder_view = Vim::get_view( mo_ref => $datacenter->vmFolder );

	my $comp_res_view = Vim::get_view( mo_ref => $host_view->parent );

	$self->debugMsg (1, 'Creating virtual machine \'' . $self->opts->{esx_vmname} . '\' ...');
	eval {
		$vm_folder_view->CreateVM(
			config => $vm_config_spec,
			pool   => $comp_res_view->resourcePool
		);
		$self->debugMsg( 0,
			    'Successfully created virtual machine: \'' . $self->opts->{esx_vmname} .
			    '\' under host ' . $self->opts->{esx_vmhost});
	};
	if ($@) {
		$self->debugMsg( 0, 'Error creating VM \''.$self->opts->{esx_vmname}.'\': ' );
		if ( ref($@) eq 'SoapFault' ) {
			if ( ref( $@->detail ) eq 'PlatformConfigFault' ) {
				$self->debugMsg( 0,
					    'Invalid VM configuration: '
					  . ${ $@->detail }{'text'});
			}
			elsif ( ref( $@->detail ) eq 'InvalidDeviceSpec' ) {
				$self->debugMsg( 0,
					    'Invalid Device configuration: '
					  . ${ $@->detail }{'property'});
			}
			elsif ( ref( $@->detail ) eq 'DatacenterMismatch' ) {
				$self->debugMsg( 0,
					    'DatacenterMismatch, the input arguments had entities '
					  . 'that did not belong to the same datacenter' );
			}
			elsif ( ref( $@->detail ) eq 'HostNotConnected' ) {
				$self->debugMsg( 0,
					    'Unable to communicate with the remote host,'
					  . ' since it is disconnected' );
			}
			elsif ( ref( $@->detail ) eq 'InvalidState' ) {
				$self->debugMsg( 0,
					'The operation is not allowed in the current state' );
			}
			elsif ( ref( $@->detail ) eq 'DuplicateName' ) {
				$self->debugMsg( 0, 'Virtual machine already exists' );
			}
			else {
				$self->debugMsg( 0, $@);
			}
		}
		else {
			$self->debugMsg( 0, $@);
		}
		$self->opts->{exitcode} = ERROR;
		return;
	}
	$self->poweron_vm();
}

################################
# clone_relocate - Connect, call clone_relocate_vm, and disconnect from ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub clone_relocate {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		my $op = $self->opts->{esx_operation};
		if ( $op eq 'clone' ) {
			$out .= "Cloning virtual machine '" . $self->opts->{esx_vmname} . "' ...";
			$out .= "\n";
			$out .= "Clone '".$self->opts->{esx_vmname_destination}."' of virtual machine"
                     . " '".$self->opts->{esx_vmname}."' successfully created";
		}
		else {
			$out .= "Relocating virtual machine '" . $self->opts->{esx_vmname} . "' ...";
			$out .= "\n";
			$out .= "Virtual machine '".$self->opts->{esx_vmname}."' successfully relocated";
		}
		
		return $out;
	}
	
	$self->initialize();
	$self->login();
	$self->clone_relocate_vm();
	$self->logout();
}

################################
# clone_relocate_vm - Clone or relocate a virtual machine (operation specified in 'esx_operation')
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub clone_relocate_vm {
	my ($self) = @_;

	my $op      = $self->opts->{esx_operation};
	my $vm_name = $self->opts->{esx_vmname};
	my $vm_view = Vim::find_entity_view(
		view_type => 'VirtualMachine',
		filter    => { 'name' => $vm_name }
	);
	if ( !$vm_view ) {
		$self->debugMsg( 0, 'Source virtual machine \''.$vm_name.'\' not found' );
		$self->opts->{exitcode} = ERROR;
		return;
	}

	# Get destination host and compute resource views
	my $host_view = Vim::find_entity_view(
		view_type => 'HostSystem',
		filter    => { 'name' => $self->opts->{esx_vmhost_destination} }
	);
	if ( !$host_view ) {
		$self->debugMsg( 0,
			    'Error cloning/relocating VM \''.$self->opts->{esx_vmname}.'\': '
			  . 'Host \''.$self->opts->{esx_vmhost_destination}.'\' not found' );
		$self->opts->{exitcode} = ERROR;
		return;
	}
	my $comp_res_view = Vim::get_view( mo_ref => $host_view->parent );

	# Get datastore info for the destination host
	my $ds_name = $self->opts->{esx_datastore};
	my %ds_info = $self->get_datastore($host_view, $ds_name);
	if ( $self->opts->{exitcode} ) { return; }

	# Create RelocateSpec using the destination host's resource pool;
	my $relocate_spec = VirtualMachineRelocateSpec->new(
		datastore => $ds_info{mor},
		host      => $host_view,
		pool      => $comp_res_view->resourcePool
	);

	if ( $op eq 'clone' ) {

		# Create CloneSpec corresponding to the RelocateSpec
		my $clone_spec = VirtualMachineCloneSpec->new(
			powerOn  => 0,
			template => 0,
			location => $relocate_spec
		);
	
		$self->debugMsg (1, 'Cloning virtual machine \'' . $vm_name . '\' ...');
		
		eval {
			# Clone source vm
			$vm_view->CloneVM(
				folder => $vm_view->parent,
				name   => $self->opts->{esx_vmname_destination},
				spec   => $clone_spec);
				
			$self->debugMsg (1, 'Clone \''.$self->opts->{esx_vmname_destination}.'\' of virtual machine'
                             . ' \''.$vm_name.'\' successfully created');
		};
	}
	else {
		$self->debugMsg (1, 'Relocating virtual machine \'' . $vm_name . '\' ...');
		eval {
			# Relocate the vm
			$vm_view->RelocateVM( spec => $relocate_spec );
			$self->debugMsg (1, 'Virtual machine \''.$vm_name.'\' successfully relocated');
		};
	}
	
	if ($@) {
	   if (ref($@) eq 'SoapFault') {
		  if (ref($@->detail) eq 'FileFault') {
			 $self->debugMsg(0, 'Failed to access the virtual machine files');
		  }
		  elsif (ref($@->detail) eq 'InvalidState') {
			 $self->debugMsg(0,'The operation is not allowed in the current state.');
		  }
		  elsif (ref($@->detail) eq 'NotSupported') {
			 $self->debugMsg(0,'Operation is not supported by the current agent');
		  }
		  elsif (ref($@->detail) eq 'VmConfigFault') {
			 $self->debugMsg(0,
			 'Virtual machine is not compatible with the destination host.');
		  }
		  elsif (ref($@->detail) eq 'InvalidPowerState') {
			 $self->debugMsg(0,
			 'The attempted operation cannot be performed in the current state.');
		  }
		  elsif (ref($@->detail) eq 'DuplicateName') {
			 $self->debugMsg(0,
			 'The name \''.$self->opts->{esx_vmname_destination}.'\' already exists');
		  }
		  elsif (ref($@->detail) eq 'NoDisksToCustomize') {
			 $self->debugMsg(0, 'The virtual machine has no virtual disks that'
						  . ' are suitable for customization or no guest'
						  . ' is present on given virtual machine');
		  }
		  elsif (ref($@->detail) eq 'HostNotConnected') {
			 $self->debugMsg(0, 'Unable to communicate with the remote host, since it is disconnected');
		  }
		  elsif (ref($@->detail) eq 'UncustomizableGuest') {
			 $self->debugMsg(0, 'Customization is not supported for the guest operating system');
		  }
		  else {
			 $self->debugMsg(0, 'Fault' . $@);
		  }
	   }
	   else {
		  $self->debugMsg(0, 'Fault' . $@);
	   }
	   $self->opts->{exitcode} = ERROR;
	   return;
	}
}

################################
# clenaup - Connect, call cleanup_vm, and disconnect from ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub cleanup {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Powering off virtual machine '" . $self->opts->{esx_vmname} . "' ...";
		$out .= "\n";
		$out .= "Successfully powered off virtual machine: '" . $self->opts->{esx_vmname}."'";
		$out .= "\n";
		$out .= "Destroying virtual machine '".$self->opts->{esx_vmname}."' ...";
		$out .= "\n";
		$out .= "Virtual machine '".$self->opts->{esx_vmname}."' successfully destroyed";
		return $out;
	}
	
	$self->initialize();
	$self->login();
	$self->cleanup_vm();
	$self->logout();
}

################################
# cleanup_vm - Cleanup the specified virtual machine
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub cleanup_vm {
	my ($self) = @_;
	my $vm_name = $self->opts->{esx_vmname};

	$self->poweroff_vm();
	if ($self->opts->{exitcode}) { return;}

	if (defined($self->opts->{esx_save_vm}) && $self->opts->{esx_save_vm} eq "0") {
		$self->debugMsg (1, "Destroying up virtual machine '$vm_name' ...");
		
		my $vm_views = Vim::find_entity_views(
			view_type => "VirtualMachine",
			filter => { "config.name" => $vm_name });
	
		foreach (@$vm_views) {
			eval {
				# Destroy the vm
				$_->Destroy ;
				$self->debugMsg (1, "Virtual machine '$vm_name' successfully destroyed");
			};
			if ($@) {
				$self->debugMsg(0, 'Fault' . $@);
				$self->opts->{exitcode} = ERROR;
	   			return;
			}
		}
	}
}

# -------------------------------------------------------------------------
# Helper functions
# -------------------------------------------------------------------------

################################
# poweron_vm - Power on the vm having the name specified on $opts->{esx_vmname}
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub poweron_vm {
	my ($self) = @_;
	
	my $vm_view = Vim::find_entity_view(
		view_type => 'VirtualMachine',
		filter    => { 'name' => $self->opts->{esx_vmname} }
	);
	
	if ( !$vm_view ) {
		$self->debugMsg( 0, 'Virtual machine \''.$self->opts->{esx_vmname} .'\' not found' );
		$self->opts->{exitcode} = ERROR;
		return;
	}
	
	$self->debugMsg (1, 'Powering on virtual machine \'' . $self->opts->{esx_vmname} . '\' ...');
	eval {
		$vm_view->PowerOnVM();
		$self->debugMsg( 0, 'Successfully powered on virtual machine: \'' . $self->opts->{esx_vmname}.'\'');
	};
	if ($@) { 
	    if (ref($@) eq 'SoapFault') {
	        $self->debugMsg (0, "Error powering on '" . $self->opts->{esx_vmname} . "': ");
	        if (ref($@->detail) eq 'NotSupported') {
	            $self->debugMsg(0,"Virtual machine is marked as a template ");
	        }
	        elsif (ref($@->detail) eq 'InvalidPowerState') {
	            $self->debugMsg(0, "The attempted operation cannot be performed in the current state" );
	        }
	        elsif (ref($@->detail) eq 'InvalidState') {
	            $self->debugMsg(0,"Current State of the virtual machine is not supported for this operation");
	        }
	        else {
	            $self->debugMsg(0, "VM '"  .$self->opts->{esx_vmname}.
	            "' can't be powered on\n" . $@ . "" );
	        }
	    }
	    else {
	        $self->debugMsg(0, "VM '"  .$self->opts->{esx_vmname}.
	        "' can't be powered on\n" . $@ . "" );
	    }
	    $self->opts->{exitcode} = ERROR;
	   	return;
	}
}

################################
# poweroff_vm - Power off the vm having the name specified on $opts->{esx_vmname}
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub poweroff_vm {
	my ($self) = @_;
	
	my $vm_view = Vim::find_entity_view(
		view_type => 'VirtualMachine',
		filter    => { 'name' => $self->opts->{esx_vmname} }
	);
	
	if ( !$vm_view ) {
		$self->debugMsg( 0, 'Virtual machine \''.$self->opts->{esx_vmname} .'\' not found' );
		$self->opts->{exitcode} = ERROR;
		return;
	}
	
	$self->debugMsg (1, 'Powering off virtual machine \'' . $self->opts->{esx_vmname} . '\' ...');
	eval {
		$vm_view->PowerOffVM();
		$self->debugMsg( 0, 'Successfully powered off virtual machine: \'' . $self->opts->{esx_vmname}.'\'');
	};
	if ($@) { 
	    if (ref($@) eq 'SoapFault') {
	        if (ref($@->detail) eq 'InvalidPowerState') {
	        	# VM was already powered off, no error
	        	$self->debugMsg(0,"Virtual machine already powered off");
	        	return;
	        }
	        
	        $self->debugMsg (0, "Error powering off '" . $self->opts->{esx_vmname} . "': ");
	        if (ref($@->detail) eq 'InvalidState') {
	            $self->debugMsg(0,"Current State of the virtual machine is not supported for this operation");
	        }
	        elsif(ref($@->detail) eq 'NotSupported') {
	            $self->debugMsg(0,"Virtual machine is marked as template");
	        }
	        else {
	            $self->debugMsg(0, "VM '"  .$self->opts->{esx_vmname}. "' can't be powered off \n"
	            . $@ . "" );
	        }
	    }
	    else {
	       $self->debugMsg(0, "VM '"  .$self->opts->{esx_vmname}. "' can't be powered off \n" . $@ . "" );
	    }
	    $self->opts->{exitcode} = ERROR;
	   	return;
	}
}

################################
# create_conf_spec - Create virtual device config spec for controller
#
# Arguments:
#   -
#
# Returns:
#   controller_vm_dev_conf_spec - spec of configuration for controller 
#
################################
sub create_conf_spec {
	my ($self) = @_;

	my $controller = VirtualBusLogicController->new(
		key       => 0,
		device    => [0],
		busNumber => 0,
		sharedBus => VirtualSCSISharing->new('noSharing')
	);

	my $controller_vm_dev_conf_spec = VirtualDeviceConfigSpec->new(
		device    => $controller,
		operation => VirtualDeviceConfigSpecOperation->new('add')
	);
	return $controller_vm_dev_conf_spec;
}

################################
# create_virtual_disk - Create virtual device config spec for disk
#
# Arguments:
#   ds_path - datastore path
#
# Returns:
#   disk_vm_dev_conf_spec - spec of configuration for disk 
#
################################
sub create_virtual_disk {
	my ( $self, $ds_path ) = @_;

	my $disksize = $self->opts->{esx_disksize};

	my $disk_backing_info = VirtualDiskFlatVer2BackingInfo->new(
		diskMode => 'persistent',
		fileName => $ds_path
	);

	my $disk = VirtualDisk->new(
		backing       => $disk_backing_info,
		controllerKey => 0,
		key           => 0,
		unitNumber    => 0,
		capacityInKB  => $disksize
	);

	my $disk_vm_dev_conf_spec = VirtualDeviceConfigSpec->new(
		device        => $disk,
		fileOperation => VirtualDeviceConfigSpecFileOperation->new('create'),
		operation     => VirtualDeviceConfigSpecOperation->new('add')
	);
	return $disk_vm_dev_conf_spec;
}

################################
# get_network - Get network configuration
#
# Arguments:
#   host_view - view for HostSystem
#
# Returns:
#   return code
#   network_conf - network configuration
#
################################
sub get_network {
	my ( $self, $host_view ) = @_;

	my $network_name = $self->opts->{esx_nic_network};
	my $poweron      = $self->opts->{esx_nic_poweron};
	my $network      = undef;
	my $unit_num = 1;    # 1 since 0 is used by disk

	if ($network_name) {
		my $network_list =
		  Vim::get_views( mo_ref_array => $host_view->network );
		foreach (@$network_list) {
			if ( $network_name eq $_->name ) {
				$network = $_;
				my $nic_backing_info =
				  VirtualEthernetCardNetworkBackingInfo->new(
					deviceName => $network_name,
					network    => $network
				  );

				my $vd_connect_info = VirtualDeviceConnectInfo->new(
					allowGuestControl => 1,
					connected         => 0,
					startConnected    => $poweron
				);

				my $nic = VirtualPCNet32->new(
					backing     => $nic_backing_info,
					key         => 0,
					unitNumber  => $unit_num,
					addressType => 'generated',
					connectable => $vd_connect_info
				);

				my $nic_vm_dev_conf_spec = VirtualDeviceConfigSpec->new(
					device    => $nic,
					operation => VirtualDeviceConfigSpecOperation->new('add')
				);

				return ( error => 0, network_conf => $nic_vm_dev_conf_spec );
			}
		}
		if ( !defined($network) ) {

			# no network found
			return ( error => 1 );
		}
	}

	# default network will be used
	return ( error => 2 );
}

################################
# get_datastore - Retrieve a datastore which is accessible from the vm host.
# 	If a particular datastore is specified, retreive that.
# 	Else, just get the accessible datastore with the largest amount of free space.
#
# Arguments:
#   host_view - view for HostSystem
#   config_datastore - datastore name
#
# Returns:
#   name - name of datastore to use
#   mor 
#
################################
sub get_datastore {
	my ( $self, $host_view, $config_datastore ) = @_;

	my $name = undef;
	my $mor  = undef;

	my $ds_mor_array = $host_view->datastore;
	my $datastores   = Vim::get_views( mo_ref_array => $ds_mor_array );

	my $found_datastore = 0;

	# User specified datastore name.  It's possible no such
	# datastore exists, in which case an error is generated.
	if ( defined($config_datastore) ) {
		foreach (@$datastores) {
			$name = $_->summary->name;
			if ( $name eq $config_datastore ) { # if datastore available to host
				$found_datastore = 1;
				$mor             = $_->{mo_ref};
				last;
			}
		}
	}

	# No datatstore name specified.  The only only way to not find a
	# datastore in this case is if the host doesn't have any attached.
	else {
		my $disksize = 0;
		foreach (@$datastores) {
			my $ds_disksize = ( $_->summary->freeSpace );

			if ( $ds_disksize > $disksize && $_->summary->accessible ) {
				$found_datastore = 1;
				$name            = $_->summary->name;
				$mor             = $_->{mo_ref};
				$disksize        = $ds_disksize;
			}
		}
	}

	if ( !$found_datastore ) {
		my $host_name = $host_view->name;
		my $ds_name   = '<any accessible datastore>';
		if ( defined( $self->opts->{esx_datastore} )
			&& $self->opts->{esx_datastore} ne '')
		{
			$ds_name = $self->opts->{esx_datastore};
		}
		$self->debugMsg( 0,
			'Datastore \''.$ds_name.'\' is not available to host '.$host_name);
		$self->opts->{exitcode} = ERROR;
		return;
	}

	return ( name => $name, mor => $mor );
}

###############################
# debugMsg - Print a debug message
#
# Arguments:
#   errorlevel - number compared to $self->opts->{Debug}
#   msg        - string message
#
# Returns:
#   -
#
################################
sub debugMsg {
	my ( $self, $errlev, $msg ) = @_;
	if ( $self->opts->{Debug} >= $errlev ) { print "$msg\n"; }
}
