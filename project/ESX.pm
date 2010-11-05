# -------------------------------------------------------------------------
# Package
#    ESX.pm
#
# Dependencies
#    VMware::VIRuntime
#    ElectricCommander.pm
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
use ElectricCommander;
use ElectricCommander::PropDB;

# -------------------------------------------------------------------------
# Constants
# -------------------------------------------------------------------------
use constant {
	SUCCESS => 0,
	ERROR   => 1,
	
	TRUE  => 1,
	FALSE => 0,
	
    ALIVE             => 1,
    NOT_ALIVE         => 0,
	
	DEFAULT_DEBUG         => 1,
	DEFAULT_SDK_PATH      => 'C:\Program Files\VMware\VMware vSphere CLI\Perl\lib',
	DEFAULT_GUESTID       => 'winXPProGuest',
	DEFAULT_DISKSIZE      => 4096,
	DEFAULT_MEMORY        => 256,
	DEFAULT_NUM_CPUS      => 1,
	DEFAULT_NUMBER_OF_VMS => 1,
	DEFAULT_PING_TIMEOUT  => 300,
	DEFAULT_PROPERTIES_LOCATION => '/myJob/ESX/vms',
	
	SOAP_FAULT                   => 'SoapFault',
	INVALID_STATE                => 'InvalidState',
	INVALID_POWER_STATE          => 'InvalidPowerState',
	NOT_SUPPORTED                => 'NotSupported',
	TASK_IN_PROGRESS             => 'TaskInProgress',
	RUNTIME_FAULT                => 'RuntimeFault',
	TOOLS_UNAVAILABLE            => 'ToolsUnavailable',
	FILE_FAULT                   => 'FileFault',
	VM_CONFIG_FAULT              => 'VmConfigFault',
	DUPLICATE_NAME               => 'DuplicateName',
	NO_DISK_TO_CUSTOMIZE         => 'NoDisksToCustomize',
	HOST_NOT_CONNECTED           => 'HostNotConnected',
	UNCUSTOMIZABLE_GUEST         => 'UncustomizableGuest',
	INSUFFICIENT_RESOURCES_FAULT => 'InsufficientResourcesFault',
	PLATFORM_CONFIG_FAULT        => 'PlatformConfigFault',
	INVALID_DEVICE_SPEC          => 'InvalidDeviceSpec',
	DATACENTER_MISMATCH          => 'DatacenterMismatch',
	INVALID_NAME                 => 'InvalidName',
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
	my ( $class, $cmdr, $opts ) = @_;
	my $self = { 
		_cmdr => $cmdr,
		_opts => $opts, 
	};
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
	
	# Set defaults 
	$self->opts->{Debug} = DEFAULT_DEBUG;
	$self->opts->{exitcode} = SUCCESS;
	
	if(defined($self->opts->{esx_guestid}) && $self->opts->{esx_guestid} eq "") {
		$self->opts->{esx_guestid} = DEFAULT_GUESTID;
	}
	if(defined($self->opts->{esx_disksize}) && $self->opts->{esx_disksize} eq "") {
		$self->opts->{esx_disksize} = DEFAULT_DISKSIZE;
	}
	if(defined($self->opts->{esx_memory}) && $self->opts->{esx_memory} eq "") {
		$self->opts->{esx_memory} = DEFAULT_MEMORY;
	}
	if(defined($self->opts->{esx_num_cpus}) && $self->opts->{esx_num_cpus} eq "") {
		$self->opts->{esx_num_cpus} = DEFAULT_NUM_CPUS;
	}
	if(defined($self->opts->{esx_number_of_vms}) && ($self->opts->{esx_number_of_vms} eq "" or $self->opts->{esx_number_of_vms} <= 0)) {
		$self->opts->{esx_number_of_vms} = DEFAULT_NUMBER_OF_VMS;
	}
	if(defined($self->opts->{esx_properties_location}) && $self->opts->{esx_properties_location} eq "") {
		$self->opts->{esx_properties_location} = DEFAULT_PROPERTIES_LOCATION;
	}
	
	# Add specified or default location to @INC array
	if(defined($self->opts->{sdk_installation_path}) && $self->opts->{sdk_installation_path} ne '') {
		push @INC, $self->opts->{sdk_installation_path};
	}
	else {
		push @INC, DEFAULT_SDK_PATH;
	}
	require VMware::VIRuntime;
}

###############################
# myCmdr - Get ElectricCommander instance
#
# Arguments:
#   none
#
# Returns:
#   ElectricCommander instance
#
################################
sub myCmdr {
    my ($self) = @_;
    return $self->{_cmdr};
}

###############################
# myProp - Get PropDB
#
# Arguments:
#   none
#
# Returns:
#   PropDB
#
################################
sub myProp {
    my ($self) = @_;
    return $self->{_props};
}

###############################
# setProp - Use stored property prefix and PropDB to set a property
#
# Arguments:
#   location - relative location to set the property
#   value    - value of the property
#
# Returns:
#   setResult - result returned by PropDB->setProp
#
################################
sub setProp {
    my ($self, $location, $value) = @_;
    my $setResult = $self->myProp->setProp($self->opts->{esx_properties_location} . $location, $value);
    return $setResult;
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
		$out .= "Creating virtual machine '".$self->opts->{esx_vmname}."'...";
		$out .= "\n";
		$out .= "Successfully created virtual machine: '".$self->opts->{esx_vmname}."' under host ".$self->opts->{esx_vmhost};
		$out .= "\n";
		$out .= "Powering on virtual machine '" . $self->opts->{esx_vmname} . "'...";
		$out .= "\n";
		$out .= "Successfully powered on virtual machine: '" . $self->opts->{esx_vmname}."'";
		return $out;
	}
	
	$self->initialize();
	$self->login();
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->create_vm();
	}
	else {
		my $vm_prefix = $self->opts->{esx_vmname};
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_vmname} = $vm_prefix . "_$vm_number";
			$self->create_vm();
		}
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
	my $vm_reference;

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
	
	if ( $ds_info{error} ) { return; }

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

	$self->debugMsg (1, 'Creating virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
	eval {
		$vm_reference = $vm_folder_view->CreateVM(
			config => $vm_config_spec,
			pool   => $comp_res_view->resourcePool
		);
		$self->debugMsg( 0,
			    'Successfully created virtual machine \'' . $self->opts->{esx_vmname} .
			    '\' under host ' . $self->opts->{esx_vmhost});
	};
	if ($@) {
		$self->debugMsg( 0, 'Error creating VM \''.$self->opts->{esx_vmname}.'\': ' );
		if ( ref($@) eq SOAP_FAULT ) {
			if ( ref( $@->detail ) eq PLATFORM_CONFIG_FAULT ) {
				$self->debugMsg( 0,
					    'Invalid VM configuration: '
					  . ${ $@->detail }{'text'});
			}
			elsif ( ref( $@->detail ) eq INVALID_DEVICE_SPEC ) {
				$self->debugMsg( 0,
					    'Invalid Device configuration: '
					  . ${ $@->detail }{'property'});
			}
			elsif ( ref( $@->detail ) eq DATACENTER_MISMATCH ) {
				$self->debugMsg( 0,
					    'DatacenterMismatch, the input arguments had entities '
					  . 'that did not belong to the same datacenter' );
			}
			elsif ( ref( $@->detail ) eq HOST_NOT_CONNECTED ) {
				$self->debugMsg( 0,
					    'Unable to communicate with the remote host,'
					  . ' since it is disconnected' );
			}
			elsif ( ref( $@->detail ) eq INVALID_STATE ) {
				$self->debugMsg( 0,
					'The operation is not allowed in the current state' );
			}
			elsif ( ref( $@->detail ) eq DUPLICATE_NAME ) {
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
	
	# Power on vm if specified
	if(defined($self->opts->{esx_vm_poweron}) && $self->opts->{esx_vm_poweron}) {
		$self->poweron_vm();
	}
}

################################
# relocate - Connect, call relocate_vm, and disconnect from ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub relocate {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Relocating virtual machine '" . $self->opts->{esx_vmname} . "'...";
		$out .= "\n";
		$out .= "Virtual machine '".$self->opts->{esx_vmname}."' successfully relocated";
		return $out;
	}
	
	$self->initialize();
	$self->login();
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->relocate_vm();
	}
	else {
		my $vm_prefix = $self->opts->{esx_vmname};
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_vmname} = $vm_prefix . "_$vm_number";
			$self->relocate_vm();
		}
	}

	$self->logout();
}

################################
# relocate_vm - Relocate a virtual machine
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub relocate_vm {
	my ($self) = @_;

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
			    'Error relocating VM \''.$self->opts->{esx_vmname}.'\': '
			  . 'Host \''.$self->opts->{esx_vmhost_destination}.'\' not found' );
		$self->opts->{exitcode} = ERROR;
		return;
	}
	my $comp_res_view = Vim::get_view( mo_ref => $host_view->parent );

	# Get datastore info for the destination host
	my $ds_name = $self->opts->{esx_datastore};
	my %ds_info = $self->get_datastore($host_view, $ds_name);
	if ( $ds_info{error} ) { return; }

	# Create RelocateSpec using the destination host's resource pool;
	my $relocate_spec = VirtualMachineRelocateSpec->new(
		datastore => $ds_info{mor},
		host      => $host_view,
		pool      => $comp_res_view->resourcePool
	);

	$self->debugMsg (1, 'Relocating virtual machine \'' . $vm_name . '\'...');
	eval {
		# Relocate the vm
		$vm_view->RelocateVM( spec => $relocate_spec );
		$self->debugMsg (1, 'Virtual machine \''.$vm_name.'\' successfully relocated');
	};
	
	if ($@) {
	   if (ref($@) eq SOAP_FAULT) {
		  if (ref($@->detail) eq FILE_FAULT) {
			 $self->debugMsg(0, 'Failed to access the virtual machine files');
		  }
		  elsif (ref($@->detail) eq INVALID_STATE) {
			 $self->debugMsg(0,'The operation is not allowed in the current state');
		  }
		  elsif (ref($@->detail) eq NOT_SUPPORTED) {
			 $self->debugMsg(0,'Operation is not supported by the current agent');
		  }
		  elsif (ref($@->detail) eq VM_CONFIG_FAULT) {
			 $self->debugMsg(0,
			 'Virtual machine is not compatible with the destination host');
		  }
		  elsif (ref($@->detail) eq INVALID_POWER_STATE) {
			 $self->debugMsg(0,
			 'The attempted operation cannot be performed in the current state');
		  }
		  elsif (ref($@->detail) eq NO_DISK_TO_CUSTOMIZE) {
			 $self->debugMsg(0, 'The virtual machine has no virtual disks that'
						  . ' are suitable for customization or no guest'
						  . ' is present on given virtual machine');
		  }
		  elsif (ref($@->detail) eq HOST_NOT_CONNECTED) {
			 $self->debugMsg(0, 'Unable to communicate with the remote host, since it is disconnected');
		  }
		  elsif (ref($@->detail) eq UNCUSTOMIZABLE_GUEST) {
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
# clone - Connect, call clone_vm, and disconnect from ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub clone {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Cloning virtual machine '" . $self->opts->{esx_vmname} . "'...";
		$out .= "\n";
		$out .= "Clone '".$self->opts->{esx_vmname_destination}."' of virtual machine"
                    . " '".$self->opts->{esx_vmname}."' successfully created";
		return $out;
	}
	
	$self->initialize();
	$self->login();
	$self->clone_vm();
	$self->logout();
}

################################
# clone_vm - Clone a virtual machine
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub clone_vm {
	my ($self) = @_;

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
			    'Error cloning VM \''.$self->opts->{esx_vmname}.'\': '
			  . 'Host \''.$self->opts->{esx_vmhost_destination}.'\' not found' );
		$self->opts->{exitcode} = ERROR;
		return;
	}
	my $comp_res_view = Vim::get_view( mo_ref => $host_view->parent );

	# Get datastore info for the destination host
	my $ds_name = $self->opts->{esx_datastore};
	my %ds_info = $self->get_datastore($host_view, $ds_name);
	if ( $ds_info{error} ) { return; }

	# Create RelocateSpec using the destination host's resource pool;
	my $relocate_spec = VirtualMachineRelocateSpec->new(
		datastore => $ds_info{mor},
		host      => $host_view,
		pool      => $comp_res_view->resourcePool
	);


	# Create CloneSpec corresponding to the RelocateSpec
	my $clone_spec = VirtualMachineCloneSpec->new(
		powerOn  => 0,
		template => 0,
		location => $relocate_spec
	);

	my $clone_name;
	my $vm_number;
	for ( my $i = 0 ; $i < $self->opts->{esx_number_of_clones} ; $i++ ) {
		
		$vm_number = $i + 1;
		if($self->opts->{esx_number_of_clones} == DEFAULT_NUMBER_OF_VMS) {
			$clone_name = $self->opts->{esx_vmname_destination};
		} else {
			$clone_name = $self->opts->{esx_vmname_destination} . "_$vm_number";
		}
		
		$self->debugMsg (1, 'Cloning virtual machine \'' . $vm_name . '\' to \''.$clone_name.'\'...');

		eval {
			# Clone source vm
			$vm_view->CloneVM(
				folder => $vm_view->parent,
				name   => $clone_name,
				spec   => $clone_spec);
				
			$self->debugMsg (1, 'Clone \''.$clone_name.'\' of virtual machine'
							 . ' \''.$vm_name.'\' successfully created');
		};
		
		if ($@) {
		   if (ref($@) eq SOAP_FAULT) {
			  if (ref($@->detail) eq FILE_FAULT) {
				 $self->debugMsg(0, 'Failed to access the virtual machine files');
			  }
			  elsif (ref($@->detail) eq INVALID_STATE) {
				 $self->debugMsg(0,'The operation is not allowed in the current state');
			  }
			  elsif (ref($@->detail) eq NOT_SUPPORTED) {
				 $self->debugMsg(0,'Operation is not supported by the current agent');
			  }
			  elsif (ref($@->detail) eq VM_CONFIG_FAULT) {
				 $self->debugMsg(0,
				 'Virtual machine is not compatible with the destination host');
			  }
			  elsif (ref($@->detail) eq INVALID_POWER_STATE) {
				 $self->debugMsg(0,
				 'The attempted operation cannot be performed in the current state');
			  }
			  elsif (ref($@->detail) eq DUPLICATE_NAME) {
				 $self->debugMsg(0,
				 'The name \''.$clone_name.'\' already exists');
			  }
			  elsif (ref($@->detail) eq NO_DISK_TO_CUSTOMIZE) {
				 $self->debugMsg(0, 'The virtual machine has no virtual disks that'
							  . ' are suitable for customization or no guest'
							  . ' is present on given virtual machine');
			  }
			  elsif (ref($@->detail) eq HOST_NOT_CONNECTED) {
				 $self->debugMsg(0, 'Unable to communicate with the remote host, since it is disconnected');
			  }
			  elsif (ref($@->detail) eq UNCUSTOMIZABLE_GUEST) {
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
		}
	}
}

################################
# cleanup - Connect, call cleanup_vm, and disconnect from ESX server
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
		$out .= "Powering off virtual machine '" . $self->opts->{esx_vmname} . "'...";
		$out .= "\n";
		$out .= "Successfully powered off virtual machine: '" . $self->opts->{esx_vmname}."'";
		$out .= "\n";
		$out .= "Destroying virtual machine '".$self->opts->{esx_vmname}."'...";
		$out .= "\n";
		$out .= "Virtual machine '".$self->opts->{esx_vmname}."' successfully destroyed";
		return $out;
	}
	
	$self->initialize();
	$self->login();
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->cleanup_vm();
	}
	else {
		my $vm_prefix = $self->opts->{esx_vmname};
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_vmname} = $vm_prefix . "_$vm_number";
			$self->cleanup_vm();
		}
	}

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

	# Remove resource
    $self->debugMsg(1, 'Deleting resource ' . $vm_name .'...');
	my $cmdrresult = $self->myCmdr()->deleteResource( $vm_name);
	
	# Check for error return
	my $errMsg = $self->myCmdr()->checkAllErrors($cmdrresult);
	if ($errMsg ne "") {
		$self->debugMsg(1, "Error: $errMsg");
		$self->opts->{exitcode} = ERROR;
		return;
	}
	$self->debugMsg(1, 'Resource deleted');

	if (defined($self->opts->{esx_delete_vm}) && $self->opts->{esx_delete_vm}) {
		
		# Get virtual machine to destroy
		my $vm_view = Vim::find_entity_view(
			view_type => 'VirtualMachine',
			filter => { 'config.name' => $vm_name });
		
		if ( !$vm_view ) {
			$self->debugMsg( 0, 'Virtual machine \''.$self->opts->{esx_vmname} .'\' not found' );
			$self->opts->{exitcode} = ERROR;
			return;
		}
		
		# VM must be powered off to be destroyed. If an error occurs in power_off, it can be ignored because then Cleanup is going to show the error
		my $exitcode_temp = $self->opts->{exitcode};
		$self->poweroff_vm();
		$self->opts->{exitcode} = $exitcode_temp;
		
		$self->debugMsg (1, "Destroying virtual machine '$vm_name'...");
		
		eval {
			# Destroy the vm
			$vm_view->Destroy ;
			$self->debugMsg (1, "Virtual machine '$vm_name' successfully destroyed");
		};
		if ($@) {
			$self->debugMsg(0, 'Fault' . $@);
			$self->opts->{exitcode} = ERROR;
   			return;
		}
	}
}

################################
# revert - Connect, call revert_vm, and disconnect from ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub revert {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Reverting virtual machine '" . $self->opts->{esx_vmname} . "' to snapshot ".$self->opts->{esx_snapshotname}."...";
		$out .= "\n";
		$out .= "Revert to snapshot ".$self->opts->{esx_snapshotname}." for virtual machine '" . $self->opts->{esx_vmname}."' completed successfully under host ".$self->opts->{esx_vmhost};
		$out .= "\n";
		$out .= "Powering on virtual machine '".$self->opts->{esx_vmname}."'...";
		$out .= "\n";
		$out .= "Successfully powered on virtual machine: '".$self->opts->{esx_vmname}."'";
		return $out;
	}
	
	$self->initialize();
	$self->login();
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->revert_vm();
	}
	else {
		my $vm_prefix = $self->opts->{esx_vmname};
		my $snapshot_prefix = $self->opts->{esx_snapshotname};
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_vmname} = $vm_prefix . "_$vm_number";
			$self->opts->{esx_snapshotname} = $snapshot_prefix . "_$vm_number";
			$self->revert_vm();
		}
	}

	$self->logout();
}

################################
# revert_vm - Revert a virtual machine to a specified snapshot
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub revert_vm {
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
	
	my $mor_host = $vm_view->runtime->host;
	my $hostname = Vim::get_view( mo_ref => $mor_host )->name;
	my $ref      = undef;
	my $nRefs    = 0;

	if ( defined $vm_view->snapshot ) {
		( $ref, $nRefs ) =
		  $self->find_snapshot_name( $vm_view->snapshot->rootSnapshotList, $self->opts->{esx_snapshotname} );
	}
	if ( defined $ref && $nRefs == 1 ) {
		$self->debugMsg (1, 'Reverting virtual machine \'' .	$self->opts->{esx_vmname} .
							'\' to snapshot ' . $self->opts->{esx_snapshotname}.'...');
		my $snapshot = Vim::get_view( mo_ref => $ref->snapshot );
		eval {
			$snapshot->RevertToSnapshot();
			$self->debugMsg( 0, 'Revert to snapshot ' . $self->opts->{esx_snapshotname}
				  			. ' for virtual machine \'' . $vm_view->name
				  			. '\' completed successfully under host ' . $hostname);
		};
        if ($@) {
            if ( ref($@) eq SOAP_FAULT ) {
                if ( ref( $@->detail ) eq INVALID_STATE ) {
                    $self->debugMsg(0, 'Operation cannot be performed in the current state of the virtual machine');
                }
                elsif ( ref( $@->detail ) eq NOT_SUPPORTED ) {
                    $self->debugMsg( 0,'Host product does not support snapshots' );
                }
                elsif ( ref( $@->detail ) eq INVALID_POWER_STATE ) {
                    $self->debugMsg(0, 'Operation cannot be performed in the current power state of the virtual machine');
                }
                elsif ( ref( $@->detail ) eq INSUFFICIENT_RESOURCES_FAULT ) {
                    $self->debugMsg( 0, 'Operation would violate a resource usage policy');
                }
                elsif ( ref( $@->detail ) eq HOST_NOT_CONNECTED ) {
                    $self->debugMsg( 0, 'Host not connected');
                } 
                else {
                    $self->debugMsg( 0, 'Fault: ' . $@);
                }
            }
            else {
                $self->debugMsg( 0, 'Fault: ' . $@);
            }
            $self->opts->{exitcode} = ERROR;
			return;
        }
        # If specified, power on the virtual machine
        if(defined($self->opts->{esx_poweron_vm}) && $self->opts->{esx_poweron_vm} ne "0") {
        	$self->poweron_vm();	
        }
    }
    else {
        if ( $nRefs > 1 ) {
            $self->debugMsg( 0, 'More than one snapshot exits with name ' . 
            		$self->opts->{esx_snapshotname} . ' in virtual machine \'' . 
            		$vm_view->name . '\' under host ' . $hostname);
            $self->opts->{exitcode} = ERROR;
			return;
        }
        if ( $nRefs == 0 ) {
            $self->debugMsg( 0, 'Snapshot not found with name ' . 
            		$self->opts->{esx_snapshotname} . ' in virtual machine \'' . 
            		$vm_view->name . '\' under host ' . $hostname);
            $self->opts->{exitcode} = ERROR;
			return;
        }
    }
}

################################
# snapshot - Connect, call snapshot_vm, and disconnect from ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub snapshot {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Creating snapshot " . $self->opts->{esx_snapshotname} . " for virtual machine '".$self->opts->{esx_vmname}."'...";
		$out .= "\n";
		$out .= "Snapshot ".$self->opts->{esx_snapshotname}." completed for virtual machine '" . $self->opts->{esx_vmname}."' under host ".$self->opts->{esx_vmhost};
		return $out;
	}
	
	$self->initialize();
	$self->login();
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->snapshot_vm();
	}
	else {
		my $vm_prefix = $self->opts->{esx_vmname};
		my $snapshot_prefix = $self->opts->{esx_snapshotname};
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_vmname} = $vm_prefix . "_$vm_number";
			$self->opts->{esx_snapshotname} = $snapshot_prefix . "_$vm_number";
			$self->snapshot_vm();
		}
	}
	
	$self->logout();
}

################################
# snapshot_vm - Create a snapshot for the specified virtual machine
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub snapshot_vm {
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
	
	my $mor_host = $vm_view->runtime->host;
	my $hostname = Vim::get_view( mo_ref => $mor_host )->name;
	
	$self->debugMsg (1, 'Creating snapshot ' . $self->opts->{esx_snapshotname}.' for virtual machine \'' .	$self->opts->{esx_vmname} .'\'...');
	
	eval {
	    $vm_view->CreateSnapshot(name => $self->opts->{esx_snapshotname},
	        description => 'Snapshot created for virtual machine: '.$self->opts->{esx_vmname},
	        memory => 0,
	        quiesce => 0);
	    $self->debugMsg( 0, 'Snapshot ' . $self->opts->{esx_snapshotname}
				  			. ' completed for virtual machine \'' . $vm_view->name
				  			. '\' under host ' . $hostname);
	};
	if ($@) {
		$self->debugMsg(0, 'Error creating snapshot of virtual machine: ' . $self->opts->{esx_vmname});
		if ( ref($@) eq SOAP_FAULT ) {
            if ( ref( $@->detail ) eq INVALID_NAME ) {
                $self->debugMsg( 0,'Specified snapshot name is invalid' );
            }
            elsif ( ref( $@->detail ) eq INVALID_STATE ) {
                $self->debugMsg(0, 'Operation cannot be performed in the current state of the virtual machine');
            }
            elsif ( ref( $@->detail ) eq INVALID_POWER_STATE ) {
                $self->debugMsg(0, 'Operation cannot be performed in the current power state of the virtual machine');
            }
            elsif ( ref( $@->detail ) eq HOST_NOT_CONNECTED ) {
                $self->debugMsg( 0, 'Unable to communicate with the remote host since it is disconnected');
            }
            elsif ( ref( $@->detail ) eq NOT_SUPPORTED ) {
                $self->debugMsg( 0, 'Host does not support snapshots');
            }
            else {
                $self->debugMsg( 0, 'Fault: ' . $@);
            }
        }
        else {
            $self->debugMsg( 0, 'Fault: ' . $@);
        }
        $self->opts->{exitcode} = ERROR;
        return;
    }
}

################################
# poweron - Connect, call poweron_vm, and disconnect from ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub poweron {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Powering on virtual machine '" . $self->opts->{esx_vmname} . "'...";
		$out .= "\n";
		$out .= "Successfully powered on virtual machine '" . $self->opts->{esx_vmname}."'";
		return $out;
	}
	
	$self->initialize();	
	$self->login();
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->poweron_vm();
	}
	else {
		my $vm_prefix = $self->opts->{esx_vmname};
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_vmname} = $vm_prefix . "_$vm_number";
			$self->poweron_vm();
		}
	}
	
	$self->logout();
}

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
	
	$self->debugMsg (1, 'Powering on virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
	eval {
		$vm_view->PowerOnVM();
		$self->debugMsg( 0, 'Successfully powered on virtual machine \'' . $self->opts->{esx_vmname}.'\'');
	};
	if ($@) {
		if (ref($@) eq SOAP_FAULT and ref($@->detail) eq INVALID_POWER_STATE) {
			# VM was already powered on, no error
		    $self->debugMsg(0,'Virtual machine already powered on');
		} else {
		    if (ref($@) eq SOAP_FAULT) {
		        
		        $self->debugMsg (0, 'Error powering on \'' . $self->opts->{esx_vmname} . '\': ');
		        if(!$self->print_error(ref($@->detail))) {
		        	$self->debugMsg(0, "VM '"  .$self->opts->{esx_vmname}. "' can't be powered on \n"
		            . $@ . "" );
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

	# Create resource if specified
	if(defined($self->opts->{esx_create_resources}) && $self->opts->{esx_create_resources}) {
		$self->createresourcefrom_vm();
		if($self->ecode()) {return;}
	}
}

################################
# poweroff - Connect, call poweroff_vm, and disconnect from ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub poweroff {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Powering off virtual machine '" . $self->opts->{esx_vmname} . "'...";
		$out .= "\n";
		$out .= "Successfully powered off virtual machine '" . $self->opts->{esx_vmname}."'";
		return $out;
	}
	
	$self->initialize();
	$self->login();
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->poweroff_vm();
	}
	else {
		my $vm_prefix = $self->opts->{esx_vmname};
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_vmname} = $vm_prefix . "_$vm_number";
			$self->poweroff_vm();
		}
	}
	
	$self->logout();
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
	
	$self->debugMsg (1, 'Powering off virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
	eval {
		$vm_view->PowerOffVM();
		$self->debugMsg( 0, 'Successfully powered off virtual machine \'' . $self->opts->{esx_vmname}.'\'');
	};
	if ($@) { 
	    if (ref($@) eq SOAP_FAULT) {
	        
	        $self->debugMsg (0, 'Error powering off \'' . $self->opts->{esx_vmname} . '\': ');
	        if(!$self->print_error(ref($@->detail))) {
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
# shutdown - Connect, call shutdown_vm, and disconnect from ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub shutdown {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Shutting down virtual machine '" . $self->opts->{esx_vmname} . "'...";
		$out .= "\n";
		$out .= "Successfully shut down virtual machine '" . $self->opts->{esx_vmname}."'";
		return $out;
	}
	
	$self->initialize();
	$self->login();
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->shutdown_vm();
	}
	else {
		my $vm_prefix = $self->opts->{esx_vmname};
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_vmname} = $vm_prefix . "_$vm_number";
			$self->shutdown_vm();
		}
	}
	
	$self->logout();
}

################################
# shutdown_vm - Shut down the vm having the name specified on $opts->{esx_vmname}
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub shutdown_vm {
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
	
	$self->debugMsg (1, 'Shutting down virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
	eval {
		$vm_view->ShutdownGuest();
		$self->debugMsg( 0, 'Successfully shut down virtual machine \'' . $self->opts->{esx_vmname}.'\'');
	};
	if ($@) { 
	    if (ref($@) eq SOAP_FAULT) { 
	        $self->debugMsg (0, 'Error shutting down \'' . $self->opts->{esx_vmname} . '\': ');
	        
	        if(!$self->print_error(ref($@->detail))) {
	        	$self->debugMsg(0, "VM '"  .$self->opts->{esx_vmname}. "' can't be shut down \n"
	            . $@ . "" );
	        }
	    }
	    else {
	       $self->debugMsg(0, "VM '"  .$self->opts->{esx_vmname}. "' can't be shut down \n" . $@ . "" );
	    }
	    $self->opts->{exitcode} = ERROR;
	   	return;
	}
}

################################
# suspend - Connect, call suspend_vm, and disconnect from ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub suspend {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Suspending virtual machine '" . $self->opts->{esx_vmname} . "'...";
		$out .= "\n";
		$out .= "Successfully suspended virtual machine '" . $self->opts->{esx_vmname}."'";
		return $out;
	}
	
	$self->initialize();
	$self->login();
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->suspend_vm();
	}
	else {
		my $vm_prefix = $self->opts->{esx_vmname};
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_vmname} = $vm_prefix . "_$vm_number";
			$self->suspend_vm();
		}
	}
	
	$self->logout();
}

################################
# suspend_vm - Suspend the vm having the name specified on $opts->{esx_vmname}
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub suspend_vm {
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
	
	$self->debugMsg (1, 'Suspending virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
	eval {
		$vm_view->SuspendVM();
		$self->debugMsg( 0, 'Successfully suspended virtual machine \'' . $self->opts->{esx_vmname}.'\'');
	};
	if ($@) { 
	    if (ref($@) eq SOAP_FAULT) { 
	        $self->debugMsg (0, 'Error suspending \'' . $self->opts->{esx_vmname} . '\': ');
	        
	        if(!$self->print_error(ref($@->detail))) {
	        	$self->debugMsg(0, "VM '"  .$self->opts->{esx_vmname}. "' can't be suspended \n"
	            . $@ . "" );
	        }
	    }
	    else {
	       $self->debugMsg(0, "VM '"  .$self->opts->{esx_vmname}. "' can't be suspended \n" . $@ . "" );
	    }
	    $self->opts->{exitcode} = ERROR;
	   	return;
	}
}

################################
# createresourcefromvm - Connect, call createresourcefrom_vm, and disconnect from ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub createresourcefromvm {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Creating resource for virtual machine '".$self->opts->{esx_vmname}."'...";
		$out .= "\n";
		$out .= "Resource created";
		$out .= "\n";
		$out .= "Waiting for ping response #(300) of resource " . $self->opts->{esx_vmname};
		$out .= "\n";
		$out .= "Ping response succesfully received";
		return $out;
	}
	
	$self->initialize();
	$self->login();
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->createresourcefrom_vm();
	}
	else {
		my $vm_prefix = $self->opts->{esx_vmname};
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_vmname} = $vm_prefix . "_$vm_number";
			$self->createresourcefrom_vm();
		}
	}
	
	$self->logout();
}

################################
# createresourcefrom_vm - Store information about a virtual machine and create ElectricCommander resources
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub createresourcefrom_vm {
	my ($self) = @_;
	
	my $hostname = $self->get_vm_configuration();
	if($self->ecode()) {return;}

	# Create resource if specified
	if(defined($self->opts->{esx_create_resources}) && $self->opts->{esx_create_resources}) {

		$self->debugMsg(1, 'Creating resource for virtual machine \''.$self->opts->{esx_vmname}.'\'...');
        my $cmdrresult = $self->myCmdr()->createResource(
           	$self->opts->{esx_vmname},
            {description => "ESX created resource",
             workspaceName => $self->opts->{esx_workspace},
             hostName => $hostname,
             pools => $self->opts->{esx_pools} } );

        # Check for error return
        my $errMsg = $self->myCmdr()->checkAllErrors($cmdrresult);
        if ($errMsg ne "") {
            $self->debugMsg(1, "Error: $errMsg");
            $self->opts->{exitcode} =  ERROR;
            return;
        }
        
        $self->debugMsg(1, 'Resource created');
        
        # Test connection to vm
        my $resStarted = 0;
		my $try  = DEFAULT_PING_TIMEOUT;
		while ($try > 0) {
			$self->debugMsg(1, "Waiting for ping response #("
				. $try . ") of resource " . $self->opts->{esx_vmname});
			my $pingresult = $self->pingResource($self->opts->{esx_vmname});
			if ($pingresult == 1) {
				$resStarted = 1;
				last;
			}
			sleep(1);
			$try -= 1;
		}
		if ($resStarted == 0) {
			$self->debugMsg(1, 'Unable to ping virtual machine');
			$self->opts->{exitcode} =  ERROR;
		} else {
			$self->debugMsg(1, 'Ping response succesfully received');
		}
	}
}

################################
# getvmconfiguration - Connect, call get_vm_configuration, and disconnect from ESX server
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub getvmconfiguration {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Getting information of virtual machine '" . $self->opts->{esx_vmname} . "'...";
		$out .= "\n";
		$out .= "Storing properties...";
		$out .= "\n";
		$out .= "IP address: " . $self->opts->{esx_ipaddress};
		$out .= "\n";
		$out .= "Hostname: " . $self->opts->{esx_hostname};
		return $out;
	}
	
	$self->initialize();
	$self->login();
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->get_vm_configuration();
	}
	else {
		my $vm_prefix = $self->opts->{esx_vmname};
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_vmname} = $vm_prefix . "_$vm_number";
			$self->get_vm_configuration();
		}
	}
	
	$self->logout();
}

################################
# get_vm_configuration - Get virtual machine information and store it in properties
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub get_vm_configuration {
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
	
	$self->debugMsg (1, 'Getting information of virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
	
	# Retrieve virtual machine info
	my $ip_address = $vm_view->guest->ipAddress;
	my $hostname = $vm_view->guest->hostName;
	
	if (!defined($ip_address) or $ip_address eq "" or !defined($hostname) or $hostname eq "") {
		$self->debugMsg(1, 'Unable to get IP address and/or hostname from virtual machine \''.$self->opts->{esx_vmname}.'\'');
		$self->opts->{exitcode} = ERROR;
		return;
	}

	# Store vm info in properties
	$self->debugMsg(1, 'Storing properties...');
	$self->debugMsg(1, 'IP address: ' . $ip_address);
	$self->debugMsg(1, 'Hostname: ' . $hostname);
	
	# Create ElectricCommander PropDB
	$self->{_props} = new ElectricCommander::PropDB($self->myCmdr(),"");
		
	$self->setProp( '/'.$self->opts->{esx_vmname}.'/ipAddress', $ip_address);
	$self->setProp( '/'.$self->opts->{esx_vmname}.'/hostName', $hostname);
	
	return $hostname;
}

################################
# import - Iterate and call import_vm
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub import {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Importing OVF package...";
		$out .= "\n";
		$out .= "Opening OVF source: " . $self->opts->{esx_ovf_file};
		$out .= "Opening VI target: " . "vi://".$self->opts->{esx_user}.":".$self->opts->{esx_pass}."@".$self->opts->{esx_host}."/";
		$out .= "Deploying to VI: " . "vi://".$self->opts->{esx_user}."@".$self->opts->{esx_host}."/";
		$out .= "Disk progress: 0%\nDisk progress: 1%\nDisk progress: 96%\nDisk progress: 97%\nDisk progress: 99%\nDisk Transfer Completed";                    
		$out .= "\n";
		$out .= "Completed successfully";
		return $out;
	}
	
	sleep(80);
	
	# Initialize 
	$self->opts->{Debug} = DEFAULT_DEBUG;
	$self->opts->{exitcode} = SUCCESS;
	if(defined($self->opts->{esx_number_of_vms}) && ($self->opts->{esx_number_of_vms} eq "" or $self->opts->{esx_number_of_vms} <= 0)) {
		$self->opts->{esx_number_of_vms} = DEFAULT_NUMBER_OF_VMS;
	}
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->opts->{esx_ovf_file} = $self->opts->{esx_source_directory} . '/' . $self->opts->{esx_vmname} . '/' . $self->opts->{esx_vmname} . '.ovf';
		$self->import_vm();
	}
	else {
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_ovf_file} = $self->opts->{esx_source_directory} . '/' . $self->opts->{esx_vmname} . "_$vm_number/" . $self->opts->{esx_vmname} . "_$vm_number.ovf";
			$self->import_vm();
		}
	}
}

################################
# import_vm - Import an OVF package to the ESX server using ovftool
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub import_vm {
	my ($self) = @_;
	
	# Call ovftool to import OVF package
	$self->debugMsg(1, 'Importing OVF package...');
	my $command = 'ovftool --datastore='.$self->opts->{esx_datastore}.' "'.$self->opts->{esx_ovf_file}.'" "vi://'.$self->opts->{esx_user}.':'.$self->opts->{esx_pass}.'@'.$self->opts->{esx_host}.'/"';
	system($command);
}

################################
# export - Iterate and call export_vm
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub export {
	my ($self) = @_;
	
	if ($::gRunTestUseFakeOutput) {
		# Create and return fake output
		my $out = "";
		$out .= "Exporting virtual machine...";
		$out .= "\n";
		$out .= "Opening VI source: " . "vi://".$self->opts->{esx_user}."@".$self->opts->{esx_host}."/".$self->opts->{esx_datacenter};
		$out .= "Opening OVF target: " . $self->opts->{esx_target_directory};
		$out .= "Writing OVF package: " . $self->opts->{esx_target_directory}."/".$self->opts->{esx_vmname}."/".$self->opts->{esx_vmname}.".ovf";
		$out .= "Disk progress: 0%\nDisk Transfer Completed";                    
		$out .= "\n";
		$out .= "Completed successfully";
		return $out;
	}
	
	# Initialize 
	$self->opts->{Debug} = DEFAULT_DEBUG;
	$self->opts->{exitcode} = SUCCESS;
	if(defined($self->opts->{esx_number_of_vms}) && ($self->opts->{esx_number_of_vms} eq "" or $self->opts->{esx_number_of_vms} <= 0)) {
		$self->opts->{esx_number_of_vms} = DEFAULT_NUMBER_OF_VMS;
	}
	
	if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
		$self->opts->{esx_source} = $self->opts->{esx_vmname} . '/' . $self->opts->{esx_vmname} . '.vmx';
		$self->export_vm();
	}
	else {
		my $vm_number;
		for ( my $i = 0 ; $i < $self->opts->{esx_number_of_vms} ; $i++ ) {
			$vm_number = $i + 1;
			$self->opts->{esx_source} = $self->opts->{esx_vmname} . "_$vm_number/" . $self->opts->{esx_vmname} . "_$vm_number.vmx";
			$self->export_vm();
		}
	}
}

################################
# export - Export a virtual machine to an OVF package using ovftool
#
# Arguments:
#   -
#
# Returns:
#   -
#
################################
sub export_vm {
	my ($self) = @_;
		
	# Call ovftool to export virtual machine
	$self->debugMsg(1, 'Exporting virtual machine...');
	my $command = 'ovftool "vi://'.$self->opts->{esx_user}.':'.$self->opts->{esx_pass}.'@'.$self->opts->{esx_host}.'/'.$self->opts->{esx_datacenter}.'?ds=['.$self->opts->{esx_datastore}.'] '.$self->opts->{esx_source}.'" "'.$self->opts->{esx_target_directory}.'"';
	system($command);
}

# -------------------------------------------------------------------------
# Helper functions
# -------------------------------------------------------------------------

################################
# print_error - Print the appropiate message error
#
# Arguments:
#   error - string
#
# Returns:
#   1 - Known error, printed
#   0 - Unknown error
#
################################
sub print_error {
	my ($self, $error) = @_;
	
	if ($error eq INVALID_STATE) {
        $self->debugMsg(0,'Current State of the virtual machine is not supported for this operation');
        return TRUE;
    }
    elsif($error eq INVALID_POWER_STATE) {
        $self->debugMsg(0,'The attempted operation cannot be performed in the current state');
        return TRUE;
    }
    elsif($error eq NOT_SUPPORTED) {
        $self->debugMsg(0,'The operation is not supported on the object');
        return TRUE;
    }
    elsif($error eq TASK_IN_PROGRESS) {
        $self->debugMsg(0,'Virtual machine is busy');
        return TRUE;
    }
    elsif($error eq RUNTIME_FAULT) {
        $self->debugMsg(0,'A runtime fault occured');
        return TRUE;
    }
    elsif($error eq TOOLS_UNAVAILABLE) {
		$self->debugMsg(0,'VMTools are not running in this VM');
		return TRUE;
	}
    return FALSE;
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
		return ( error => TRUE );
	}

	return ( name => $name, mor => $mor );
}

################################
# find_snapshot_name - Find a snapshot with the specified name
#
# Arguments:
#   tree - snapshot tree
#   name - snapshot name
#
# Returns:
#   ref - reference to the snapshot
#   count - 0 if not found & 1 if it's a duplicate
#
# Notes:
#	Specified snapshot name must be unique
#
################################
sub find_snapshot_name {
   my ( $self, $tree, $name ) = @_;
   my $ref = undef;
   my $count = 0;
   foreach my $node (@$tree) {
      if ($node->name eq $name) {
         $ref = $node;
         $count++;
      }
      my ($subRef, $subCount) = $self->find_snapshot_name($node->childSnapshotList, $name);
      $count = $count + $subCount;
      $ref = $subRef if ($subCount);
   }
   return ($ref, $count);
}

###############################
# pingResource - Use commander to ping a resource
#
# Arguments:
#   resource - string
#
# Returns:
#   1 if alive, 0 otherwise
#
################################
sub pingResource {
    my ($self, $resource) = @_;

    my $alive = "0";
    my $result = $self->myCmdr()->pingResource($resource);
    if (!$result) { return NOT_ALIVE; }
    $alive = $result->findvalue('//alive');
    if ($alive eq "1") { return ALIVE;}
    return NOT_ALIVE;
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
