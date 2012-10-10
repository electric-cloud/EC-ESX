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
use lib $ENV{COMMANDER_PLUGINS} . '/@PLUGIN_NAME@/agent/lib';

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

    EMPTY => q{},

    TRUE  => 1,
    FALSE => 0,

    ALIVE     => 1,
    NOT_ALIVE => 0,

    DEFAULT_DEBUG               => 1,
    DEFAULT_GUESTID             => 'winXPProGuest',
    DEFAULT_DISKSIZE            => 4096,
    DEFAULT_MEMORY              => 256,
    DEFAULT_NUM_CPUS            => 1,
    DEFAULT_NUMBER_OF_VMS       => 1,
    DEFAULT_PING_TIMEOUT        => 300,
    DEFAULT_SLEEP               => 5,
    DEFAULT_PROPERTIES_LOCATION => '/myJob/ESX/vms',

    CURRENT_DIRECTORY => '.',

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
    ALREADY_EXISTS               => 'AlreadyExists',
    OUT_OF_BOUNDS                => 'OutOfBounds',
    INVALID_ARGUMENT             => 'InvalidArgument',
    INVALID_DATASTORE            => 'InvalidDatastore',
    NOT_FOUND                    => 'NotFound',

    HOST_SYSTEM     => 'HostSystem',
    DATACENTER      => 'Datacenter',
    VIRTUAL_MACHINE => 'VirtualMachine',
    RESOURCE_POOL   => 'ResourcePool',

    DATASTORE_ERROR => 'datastore_error',
    DISKSIZE_ERROR  => 'disksize_error',
             };

$::instlist = q{};

################################
# new - Object constructor for ESX
#
# Arguments:
#   opts hash
#
# Returns:
#   none
#
################################
sub new {
    my ($class, $cmdr, $opts) = @_;
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
#   none
#
# Returns:
#   none
#
################################
sub initialize {
    my ($self) = @_;

    binmode STDOUT, ':encoding(utf8)';
    binmode STDIN,  ':encoding(utf8)';
    binmode STDERR, ':encoding(utf8)';

    # Set defaults
    $self->opts->{Debug}    = DEFAULT_DEBUG;
    $self->opts->{exitcode} = SUCCESS;

    if (defined($self->opts->{esx_guestid}) && $self->opts->{esx_guestid} eq EMPTY) {
        $self->opts->{esx_guestid} = DEFAULT_GUESTID;
    }
    if (defined($self->opts->{esx_disksize}) && $self->opts->{esx_disksize} eq EMPTY) {
        $self->opts->{esx_disksize} = DEFAULT_DISKSIZE;
    }
    if (defined($self->opts->{esx_memory}) && $self->opts->{esx_memory} eq EMPTY) {
        $self->opts->{esx_memory} = DEFAULT_MEMORY;
    }
    if (defined($self->opts->{esx_num_cpus}) && $self->opts->{esx_num_cpus} eq EMPTY) {
        $self->opts->{esx_num_cpus} = DEFAULT_NUM_CPUS;
    }
    if (defined($self->opts->{esx_number_of_vms}) && ($self->opts->{esx_number_of_vms} eq EMPTY or $self->opts->{esx_number_of_vms} <= 0)) {
        $self->opts->{esx_number_of_vms} = DEFAULT_NUMBER_OF_VMS;
    }
    if (defined($self->opts->{esx_properties_location}) && $self->opts->{esx_properties_location} eq EMPTY) {
        $self->opts->{esx_properties_location} = DEFAULT_PROPERTIES_LOCATION;
    }

    # Include vSphere SDK
    require VMware::VIRuntime;
    require VMware::VILib;

    return;
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
#   none
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
#   none
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
#   none
#
# Returns:
#   none
#
################################
sub login {
    my ($self) = @_;

    # Connect only if url was set
    if (defined($self->opts->{esx_url}) && $self->opts->{esx_url} ne EMPTY) {

        # Vim::login(service_url => $self->opts->{esx_url}, user_name   => $self->opts->{esx_user}, password    => $self->opts->{esx_pass});
        eval { my $vim = Vim::login(service_url => $self->opts->{esx_url}, user_name => $self->opts->{esx_user}, password => $self->opts->{esx_pass}); };
        if ($@) {
            $self->debug_msg(0, $@);
            $self->opts->{exitcode} = ERROR;
        }
    }
    else {
        $self->debug_msg(0, 'Error: ESX Url cannot be null.');
        $self->opts->{exitcode} = ERROR;

    }
    return;
}

################################
# logout - Disconnect the client from the ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub logout {
    my ($self) = @_;
    Vim::logout();

    return;
}

################################
# create - Call create_vm the number of times specified  by 'esx_number_of_vms'
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub create {
    my ($self) = @_;

    # Print fake output in systemtests
    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Creating virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Successfully created virtual machine: '" . $self->opts->{esx_vmname} . "' under host " . $self->opts->{esx_vmhost};
        $out .= "\n";
        $out .= "Powering on virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Successfully powered on virtual machine: '" . $self->opts->{esx_vmname} . "'";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    #Call create_vm 'esx_number_of_vms' times
    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->create_vm();
    }
    else {
        my $vm_prefix = $self->opts->{esx_vmname};
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
            $vm_number = $i + 1;
            $self->opts->{esx_vmname} = $vm_prefix . "_$vm_number";
            $self->create_vm();
        }
    }

    #Logout from service
    $self->logout();
    return;
}

################################
# create_vm - Create a vm according to the specifications provided
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub create_vm {
    my ($self) = @_;
    my @vm_devices;
    my $vm_reference;

    my $host_view = Vim::find_entity_view(view_type => HOST_SYSTEM,
                                          filter    => { 'name' => $self->opts->{esx_vmhost} });
    if (!$host_view) {
        $self->debug_msg(0, 'Error creating VM \'' . $self->opts->{esx_vmname} . '\': ' . 'Host \'' . $self->opts->{esx_vmhost} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    my $ds_name = $self->opts->{esx_datastore};
    my %ds_info = $self->get_datastore($host_view, $ds_name);

    if ($ds_info{error}) { return; }

    if ($ds_info{mor} eq 0) {
        if ($ds_info{name} eq DATASTORE_ERROR) {
            $self->debug_msg(0, 'Error creating VM \'' . $self->opts->{esx_vmname} . '\': ' . 'Datastore ' . $self->opts->{esx_datastore} . ' not available.');
            $self->opts->{exitcode} = ERROR;
            return;
        }
        if ($ds_info{name} eq DISKSIZE_ERROR) {
            $self->debug_msg(0, 'Error creating VM \'' . $self->opts->{esx_vmname} . '\': The free space ' . 'available is less than the specified disksize.');
            $self->opts->{exitcode} = ERROR;
            return;
        }
    }
    my $ds_path = '[' . $ds_info{name} . ']';

    my $controller_vm_dev_conf_spec = $self->create_conf_spec();
    my $disk_vm_dev_conf_spec       = $self->create_virtual_disk($ds_path);

    my %net_settings = $self->get_network($host_view);

    if ($net_settings{'error'} eq 0) {
        push(@vm_devices, $net_settings{'network_conf'});
    }
    elsif ($net_settings{'error'} eq 1) {
        $self->debug_msg(0, 'Error creating VM \'' . $self->opts->{esx_vmname} . '\': ' . 'Network \'' . $self->opts->{esx_nic_network} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    push(@vm_devices, $controller_vm_dev_conf_spec);
    push(@vm_devices, $disk_vm_dev_conf_spec);

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

    my $datacenter_views = Vim::find_entity_views(view_type => DATACENTER,
                                                  filter    => { name => $self->opts->{esx_datacenter} });

    unless (@$datacenter_views) {
        $self->debug_msg(0, 'Error creating VM \'' . $self->opts->{esx_vmname} . '\': ' . 'Datacenter \'' . $self->opts->{esx_datacenter} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    if ($#{$datacenter_views} != 0) {
        $self->debug_msg(0, 'Error creating VM \'' . $self->opts->{esx_vmname} . '\': ' . 'Datacenter \'' . $self->opts->{esx_datacenter} . '\' not unique');
        $self->opts->{exitcode} = ERROR;
        return;
    }
    my $datacenter = shift @$datacenter_views;

    my $vm_folder_view = Vim::get_view(mo_ref => $datacenter->vmFolder);

    my $comp_res_view = Vim::get_view(mo_ref => $host_view->parent);

    $self->debug_msg(1, 'Creating virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
    eval {
        $vm_reference = $vm_folder_view->CreateVM(config => $vm_config_spec,
                                                  pool   => $comp_res_view->resourcePool);
        $self->debug_msg(0, 'Successfully created virtual machine \'' . $self->opts->{esx_vmname} . '\' under host ' . $self->opts->{esx_vmhost});
    };
    if ($@) {
        $self->debug_msg(0, 'Error creating VM \'' . $self->opts->{esx_vmname} . '\': ');
        if (ref($@) eq SOAP_FAULT) {
            if (ref($@->detail) eq PLATFORM_CONFIG_FAULT) {
                $self->debug_msg(0, 'Invalid VM configuration: ' . ${ $@->detail }{'text'});
            }
            elsif (ref($@->detail) eq INVALID_DEVICE_SPEC) {
                $self->debug_msg(0, 'Invalid Device configuration: ' . ${ $@->detail }{'property'});
            }
            elsif (ref($@->detail) eq DATACENTER_MISMATCH) {
                $self->debug_msg(0, 'DatacenterMismatch, the input arguments had entities ' . 'that did not belong to the same datacenter');
            }
            elsif (ref($@->detail) eq HOST_NOT_CONNECTED) {
                $self->debug_msg(0, 'Unable to communicate with the remote host,' . ' since it is disconnected');
            }
            elsif (ref($@->detail) eq INVALID_STATE) {
                $self->debug_msg(0, 'The operation is not allowed in the current state');
            }
            elsif (ref($@->detail) eq DUPLICATE_NAME) {
                $self->debug_msg(0, 'Virtual machine already exists');
            }
            else {
                $self->debug_msg(0, $@);
            }
        }
        else {
            $self->debug_msg(0, $@);
        }
        $self->opts->{exitcode} = ERROR;
        return;
    }

    # Power on vm if specified
    if (defined($self->opts->{esx_vm_poweron}) && $self->opts->{esx_vm_poweron}) {
        $self->poweron_vm();
    }
}

################################
# relocate - Connect, call relocate_vm, and disconnect from ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub relocate {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Relocating virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Virtual machine '" . $self->opts->{esx_vmname} . "' successfully relocated";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->relocate_vm();
    }
    else {
        my $vm_prefix = $self->opts->{esx_vmname};
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
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
#   none
#
# Returns:
#   none
#
################################
sub relocate_vm {
    my ($self) = @_;

    my $vm_name = $self->opts->{esx_vmname};
    my $vm_view = Vim::find_entity_view(view_type => VIRTUAL_MACHINE,
                                        filter    => { 'name' => $vm_name });
    if (!$vm_view) {
        $self->debug_msg(0, 'Source virtual machine \'' . $vm_name . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    # Get destination host and compute resource views
    my $host_view = Vim::find_entity_view(view_type => HOST_SYSTEM,
                                          filter    => { 'name' => $self->opts->{esx_vmhost_destination} });
    if (!$host_view) {
        $self->debug_msg(0, 'Error relocating VM \'' . $self->opts->{esx_vmname} . '\': ' . 'Host \'' . $self->opts->{esx_vmhost_destination} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }
    my $comp_res_view = Vim::get_view(mo_ref => $host_view->parent);

    # Get datastore info for the destination host
    my $ds_name = $self->opts->{esx_datastore};
    my %ds_info = $self->get_datastore($host_view, $ds_name);
    if ($ds_info{error}) { return; }

    # Create RelocateSpec using the destination host's resource pool;
    my $relocate_spec = VirtualMachineRelocateSpec->new(
                                                        datastore => $ds_info{mor},
                                                        host      => $host_view,
                                                        pool      => $comp_res_view->resourcePool
                                                       );

    $self->debug_msg(1, 'Relocating virtual machine \'' . $vm_name . '\'...');
    eval {

        # Relocate the vm
        $vm_view->RelocateVM(spec => $relocate_spec);
        $self->debug_msg(1, 'Virtual machine \'' . $vm_name . '\' successfully relocated');
    };

    if ($@) {
        if (ref($@) eq SOAP_FAULT) {
            if (ref($@->detail) eq FILE_FAULT) {
                $self->debug_msg(0, 'Failed to access the virtual machine files');
            }
            elsif (ref($@->detail) eq INVALID_STATE) {
                $self->debug_msg(0, 'The operation is not allowed in the current state');
            }
            elsif (ref($@->detail) eq NOT_SUPPORTED) {
                $self->debug_msg(0, 'Operation is not supported by the current agent');
            }
            elsif (ref($@->detail) eq VM_CONFIG_FAULT) {
                $self->debug_msg(0, 'Virtual machine is not compatible with the destination host');
            }
            elsif (ref($@->detail) eq INVALID_POWER_STATE) {
                $self->debug_msg(0, 'The attempted operation cannot be performed in the current state');
            }
            elsif (ref($@->detail) eq NO_DISK_TO_CUSTOMIZE) {
                $self->debug_msg(0, 'The virtual machine has no virtual disks that' . ' are suitable for customization or no guest' . ' is present on given virtual machine');
            }
            elsif (ref($@->detail) eq HOST_NOT_CONNECTED) {
                $self->debug_msg(0, 'Unable to communicate with the remote host, since it is disconnected');
            }
            elsif (ref($@->detail) eq UNCUSTOMIZABLE_GUEST) {
                $self->debug_msg(0, 'Customization is not supported for the guest operating system');
            }
            else {
                $self->debug_msg(0, 'Fault' . $@);
            }
        }
        else {
            $self->debug_msg(0, 'Fault' . $@);
        }
        $self->opts->{exitcode} = ERROR;
        return;
    }
}

################################
# clone - Connect, call clone_vm, and disconnect from ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub clone {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Cloning virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Clone '" . $self->opts->{esx_vmname_destination} . "' of virtual machine" . " '" . $self->opts->{esx_vmname} . "' successfully created";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }
    $self->clone_vm();
    $self->logout();
}

################################
# clone_vm - Clone a virtual machine
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub clone_vm {
    my ($self) = @_;

    my $vm_name = $self->opts->{esx_vmname};
    my $vm_view = Vim::find_entity_view(view_type => VIRTUAL_MACHINE,
                                        filter    => { 'name' => $vm_name });
    if (!$vm_view) {
        $self->debug_msg(0, 'Source virtual machine \'' . $vm_name . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    # Get destination host and compute resource views
    my $host_view = Vim::find_entity_view(view_type => HOST_SYSTEM,
                                          filter    => { 'name' => $self->opts->{esx_vmhost_destination} });
    if (!$host_view) {
        $self->debug_msg(0, 'Error cloning VM \'' . $self->opts->{esx_vmname} . '\': ' . 'Host \'' . $self->opts->{esx_vmhost_destination} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }
    my $comp_res_view = Vim::get_view(mo_ref => $host_view->parent);

    # Get datastore info for the destination host
    my $ds_name = $self->opts->{esx_datastore};
    my %ds_info = $self->get_datastore($host_view, $ds_name);
    if ($ds_info{error}) { return; }

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
    for (my $i = 0; $i < $self->opts->{esx_number_of_clones}; $i++) {

        $vm_number = $i + 1;
        if ($self->opts->{esx_number_of_clones} == DEFAULT_NUMBER_OF_VMS) {
            $clone_name = $self->opts->{esx_vmname_destination};
        }
        else {
            $clone_name = $self->opts->{esx_vmname_destination} . "_$vm_number";
        }

        $self->debug_msg(1, 'Cloning virtual machine \'' . $vm_name . '\' to \'' . $clone_name . '\'...');

        eval {

            # Clone source vm
            $vm_view->CloneVM(
                              folder => $vm_view->parent,
                              name   => $clone_name,
                              spec   => $clone_spec
                             );

            $self->debug_msg(1, 'Clone \'' . $clone_name . '\' of virtual machine' . ' \'' . $vm_name . '\' successfully created');
        };

        if ($@) {
            if (ref($@) eq SOAP_FAULT) {
                if (ref($@->detail) eq FILE_FAULT) {
                    $self->debug_msg(0, 'Failed to access the virtual machine files');
                }
                elsif (ref($@->detail) eq INVALID_STATE) {
                    $self->debug_msg(0, 'The operation is not allowed in the current state');
                }
                elsif (ref($@->detail) eq NOT_SUPPORTED) {
                    $self->debug_msg(0, 'Operation is not supported by the current agent');
                }
                elsif (ref($@->detail) eq VM_CONFIG_FAULT) {
                    $self->debug_msg(0, 'Virtual machine is not compatible with the destination host');
                }
                elsif (ref($@->detail) eq INVALID_POWER_STATE) {
                    $self->debug_msg(0, 'The attempted operation cannot be performed in the current state');
                }
                elsif (ref($@->detail) eq DUPLICATE_NAME) {
                    $self->debug_msg(0, 'The name \'' . $clone_name . '\' already exists');
                }
                elsif (ref($@->detail) eq NO_DISK_TO_CUSTOMIZE) {
                    $self->debug_msg(0, 'The virtual machine has no virtual disks that' . ' are suitable for customization or no guest' . ' is present on given virtual machine');
                }
                elsif (ref($@->detail) eq HOST_NOT_CONNECTED) {
                    $self->debug_msg(0, 'Unable to communicate with the remote host, since it is disconnected');
                }
                elsif (ref($@->detail) eq UNCUSTOMIZABLE_GUEST) {
                    $self->debug_msg(0, 'Customization is not supported for the guest operating system');
                }
                else {
                    $self->debug_msg(0, 'Fault' . $@);
                }
            }
            else {
                $self->debug_msg(0, 'Fault' . $@);
            }
            $self->opts->{exitcode} = ERROR;
        }
    }
}

################################
# cleanup - Connect, call cleanup_vm, and disconnect from ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub cleanup {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Powering off virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Successfully powered off virtual machine: '" . $self->opts->{esx_vmname} . "'";
        $out .= "\n";
        $out .= "Destroying virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Virtual machine '" . $self->opts->{esx_vmname} . "' successfully destroyed";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->cleanup_vm();
    }
    else {
        my $vm_prefix = $self->opts->{esx_vmname};
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
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
#   none
#
# Returns:
#   none
#
################################
sub cleanup_vm {
    my ($self) = @_;
    my $vm_name = $self->opts->{esx_vmname};

    # Remove resource
    $self->debug_msg(1, 'Deleting resource ' . $vm_name . '...');
    my $cmdrresult = $self->myCmdr()->getResource($vm_name);

    # Check for error return
    my $errMsg = $self->myCmdr()->checkAllErrors($cmdrresult);
    if ($errMsg ne EMPTY) {
        $self->debug_msg(1, "Error: $errMsg");
        $self->opts->{exitcode} = ERROR;
        return;
    }

    $cmdrresult = $self->myCmdr()->deleteResource($vm_name);

    # Check for error return
    $errMsg = $self->myCmdr()->checkAllErrors($cmdrresult);
    if ($errMsg ne EMPTY) {
        $self->debug_msg(1, "Error: $errMsg");
        $self->opts->{exitcode} = ERROR;
        return;
    }
    $self->debug_msg(1, 'Resource deleted');

    if (defined($self->opts->{esx_delete_vm}) && $self->opts->{esx_delete_vm}) {

        # Get virtual machine to destroy
        my $vm_view = Vim::find_entity_view(view_type => VIRTUAL_MACHINE,
                                            filter    => { 'config.name' => $vm_name });

        if (!$vm_view) {
            $self->debug_msg(0, 'Virtual machine \'' . $self->opts->{esx_vmname} . '\' not found');
            $self->opts->{exitcode} = ERROR;
            return;
        }

        # VM must be powered off to be destroyed. If an error occurs in power_off, it can be ignored because then Cleanup is going to show the error
        my $exitcode_temp = $self->opts->{exitcode};
        $self->poweroff_vm();
        $self->opts->{exitcode} = $exitcode_temp;

        $self->debug_msg(1, "Destroying virtual machine '$vm_name'...");

        eval {

            # Destroy the vm
            $vm_view->Destroy;
            $self->debug_msg(1, "Virtual machine '$vm_name' successfully destroyed");
        };
        if ($@) {
            $self->debug_msg(0, 'Fault' . $@);
            $self->opts->{exitcode} = ERROR;
            return;
        }
    }
}

################################
# revert - Connect, call revert_vm, and disconnect from ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub revert {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Reverting virtual machine '" . $self->opts->{esx_vmname} . "' to snapshot " . $self->opts->{esx_snapshotname} . "...";
        $out .= "\n";
        $out .= "Revert to snapshot " . $self->opts->{esx_snapshotname} . " for virtual machine '" . $self->opts->{esx_vmname} . "' completed successfully under host " . $self->opts->{esx_vmhost};
        $out .= "\n";
        $out .= "Powering on virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Successfully powered on virtual machine: '" . $self->opts->{esx_vmname} . "'";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->revert_vm();
    }
    else {
        my $vm_prefix       = $self->opts->{esx_vmname};
        my $snapshot_prefix = $self->opts->{esx_snapshotname};
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
            $vm_number                      = $i + 1;
            $self->opts->{esx_vmname}       = $vm_prefix . "_$vm_number";
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
#   none
#
# Returns:
#   none
#
################################
sub revert_vm {
    my ($self) = @_;

    my $vm_view = Vim::find_entity_view(view_type => VIRTUAL_MACHINE,
                                        filter    => { 'name' => $self->opts->{esx_vmname} });

    if (!$vm_view) {
        $self->debug_msg(0, 'Virtual machine \'' . $self->opts->{esx_vmname} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    my $mor_host = $vm_view->runtime->host;
    my $hostname = Vim::get_view(mo_ref => $mor_host)->name;
    my $ref      = undef;
    my $nRefs    = 0;

    if (defined $vm_view->snapshot) {
        ($ref, $nRefs) = $self->find_snapshot_name($vm_view->snapshot->rootSnapshotList, $self->opts->{esx_snapshotname});
    }
    if (defined $ref && $nRefs == 1) {
        $self->debug_msg(1, 'Reverting virtual machine \'' . $self->opts->{esx_vmname} . '\' to snapshot ' . $self->opts->{esx_snapshotname} . '...');
        my $snapshot = Vim::get_view(mo_ref => $ref->snapshot);
        eval {
            $snapshot->RevertToSnapshot();
            $self->debug_msg(0, 'Revert to snapshot ' . $self->opts->{esx_snapshotname} . ' for virtual machine \'' . $vm_view->name . '\' completed successfully under host ' . $hostname);
        };
        if ($@) {
            if (ref($@) eq SOAP_FAULT) {
                if (ref($@->detail) eq INVALID_STATE) {
                    $self->debug_msg(0, 'Operation cannot be performed in the current state of the virtual machine');
                }
                elsif (ref($@->detail) eq NOT_SUPPORTED) {
                    $self->debug_msg(0, 'Host product does not support snapshots');
                }
                elsif (ref($@->detail) eq INVALID_POWER_STATE) {
                    $self->debug_msg(0, 'Operation cannot be performed in the current power state of the virtual machine');
                }
                elsif (ref($@->detail) eq INSUFFICIENT_RESOURCES_FAULT) {
                    $self->debug_msg(0, 'Operation would violate a resource usage policy');
                }
                elsif (ref($@->detail) eq HOST_NOT_CONNECTED) {
                    $self->debug_msg(0, 'Host not connected');
                }
                else {
                    $self->debug_msg(0, 'Fault: ' . $@);
                }
            }
            else {
                $self->debug_msg(0, 'Fault: ' . $@);
            }
            $self->opts->{exitcode} = ERROR;
            return;
        }

        # If specified, power on the virtual machine
        if (defined($self->opts->{esx_poweron_vm}) && $self->opts->{esx_poweron_vm} ne "0") {
            $self->poweron_vm();
        }
    }
    else {
        if ($nRefs > 1) {
            $self->debug_msg(0, 'More than one snapshot exits with name ' . $self->opts->{esx_snapshotname} . ' in virtual machine \'' . $vm_view->name . '\' under host ' . $hostname);
            $self->opts->{exitcode} = ERROR;
            return;
        }
        if ($nRefs == 0) {
            $self->debug_msg(0, 'Snapshot not found with name ' . $self->opts->{esx_snapshotname} . ' in virtual machine \'' . $vm_view->name . '\' under host ' . $hostname);
            $self->opts->{exitcode} = ERROR;
            return;
        }
    }
}

################################
# snapshot - Connect, call snapshot_vm, and disconnect from ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub snapshot {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Creating snapshot " . $self->opts->{esx_snapshotname} . " for virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Snapshot " . $self->opts->{esx_snapshotname} . " completed for virtual machine '" . $self->opts->{esx_vmname} . "' under host " . $self->opts->{esx_vmhost};
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->snapshot_vm();
    }
    else {
        my $vm_prefix       = $self->opts->{esx_vmname};
        my $snapshot_prefix = $self->opts->{esx_snapshotname};
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
            $vm_number                      = $i + 1;
            $self->opts->{esx_vmname}       = $vm_prefix . "_$vm_number";
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
#   none
#
# Returns:
#   none
#
################################
sub snapshot_vm {
    my ($self) = @_;

    my $vm_view = Vim::find_entity_view(view_type => VIRTUAL_MACHINE,
                                        filter    => { 'name' => $self->opts->{esx_vmname} });

    if (!$vm_view) {
        $self->debug_msg(0, 'Virtual machine \'' . $self->opts->{esx_vmname} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    my $mor_host = $vm_view->runtime->host;
    my $hostname = Vim::get_view(mo_ref => $mor_host)->name;

    $self->debug_msg(1, 'Creating snapshot ' . $self->opts->{esx_snapshotname} . ' for virtual machine \'' . $self->opts->{esx_vmname} . '\'...');

    eval {
        $vm_view->CreateSnapshot(
                                 name        => $self->opts->{esx_snapshotname},
                                 description => 'Snapshot created for virtual machine: ' . $self->opts->{esx_vmname},
                                 memory      => 0,
                                 quiesce     => 0
                                );
        $self->debug_msg(0, 'Snapshot ' . $self->opts->{esx_snapshotname} . ' completed for virtual machine \'' . $vm_view->name . '\' under host ' . $hostname);
    };
    if ($@) {
        $self->debug_msg(0, 'Error creating snapshot of virtual machine: ' . $self->opts->{esx_vmname});
        if (ref($@) eq SOAP_FAULT) {
            if (ref($@->detail) eq INVALID_NAME) {
                $self->debug_msg(0, 'Specified snapshot name is invalid');
            }
            elsif (ref($@->detail) eq INVALID_STATE) {
                $self->debug_msg(0, 'Operation cannot be performed in the current state of the virtual machine');
            }
            elsif (ref($@->detail) eq INVALID_POWER_STATE) {
                $self->debug_msg(0, 'Operation cannot be performed in the current power state of the virtual machine');
            }
            elsif (ref($@->detail) eq HOST_NOT_CONNECTED) {
                $self->debug_msg(0, 'Unable to communicate with the remote host since it is disconnected');
            }
            elsif (ref($@->detail) eq NOT_SUPPORTED) {
                $self->debug_msg(0, 'Host does not support snapshots');
            }
            else {
                $self->debug_msg(0, 'Fault: ' . $@);
            }
        }
        else {
            $self->debug_msg(0, 'Fault: ' . $@);
        }
        $self->opts->{exitcode} = ERROR;
        return;
    }
}

################################
# poweron - Connect, call poweron_vm, and disconnect from ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub poweron {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Powering on virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Successfully powered on virtual machine '" . $self->opts->{esx_vmname} . "'";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->poweron_vm();
    }
    else {
        my $vm_prefix = $self->opts->{esx_vmname};
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
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
#   none
#
# Returns:
#   none
#
################################
sub poweron_vm {
    my ($self) = @_;

    my $powerstate = EMPTY;
    my $vm_view = Vim::find_entity_view(view_type => VIRTUAL_MACHINE,
                                        filter    => { 'name' => $self->opts->{esx_vmname} });

    if (!$vm_view) {
        $self->debug_msg(0, 'Virtual machine \'' . $self->opts->{esx_vmname} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    $powerstate = $vm_view->runtime->powerState->val;

    $self->debug_msg(1, 'Powering on virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
    if ($powerstate eq 'poweredOn') {

        # VM was already powered on, no error
        $self->debug_msg(0, 'Virtual machine already powered on');
    }
    else {

        eval {
            $vm_view->PowerOnVM();
            $self->debug_msg(0, 'Successfully powered on virtual machine \'' . $self->opts->{esx_vmname} . '\'');
        };
        if ($@) {
            if (ref($@) eq SOAP_FAULT and ref($@->detail) eq INVALID_POWER_STATE) {

                # VM was already powered on, no error
                $self->debug_msg(0, 'Virtual machine already powered on');
            }
            else {
                if (ref($@) eq SOAP_FAULT) {

                    $self->debug_msg(0, 'Error powering on \'' . $self->opts->{esx_vmname} . '\': ');
                    if (!$self->print_error(ref($@->detail))) {
                        $self->debug_msg(0, "VM '" . $self->opts->{esx_vmname} . "' can't be powered on \n" . $@ . EMPTY);
                    }
                }
                else {
                    $self->debug_msg(0, "VM '" . $self->opts->{esx_vmname} . "' can't be powered on\n" . $@ . EMPTY);
                }
                $self->opts->{exitcode} = ERROR;
                return;
            }
        }
    }

    # Create resource if specified
    if (defined($self->opts->{esx_create_resources}) && $self->opts->{esx_create_resources}) {
        $self->createresourcefrom_vm();
        if ($self->ecode()) { return; }
        $self->debug_msg(1, "Saving vm list " . $::instlist);
        $self->setProp("/VMList", $::instlist);
    }

}

################################
# poweroff - Connect, call poweroff_vm, and disconnect from ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub poweroff {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Powering off virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Successfully powered off virtual machine '" . $self->opts->{esx_vmname} . "'";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->poweroff_vm();
    }
    else {
        my $vm_prefix = $self->opts->{esx_vmname};
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
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
#   none
#
# Returns:
#   none
#
################################
sub poweroff_vm {
    my ($self) = @_;

    my $powerstate = EMPTY;
    my $vm_view = Vim::find_entity_view(view_type => VIRTUAL_MACHINE,
                                        filter    => { 'name' => $self->opts->{esx_vmname} });

    if (!$vm_view) {
        $self->debug_msg(0, 'Virtual machine \'' . $self->opts->{esx_vmname} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    $powerstate = $vm_view->runtime->powerState->val;

    $self->debug_msg(1, 'Powering off virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
    if ($powerstate eq 'poweredOff') {

        # VM was already powered on, no error
        $self->debug_msg(0, 'Virtual machine already powered off');
    }
    else {

        eval {
            $vm_view->PowerOffVM();
            $self->debug_msg(0, 'Successfully powered off virtual machine \'' . $self->opts->{esx_vmname} . '\'');
        };
        if ($@) {
            if (ref($@) eq SOAP_FAULT) {

                $self->debug_msg(0, 'Error powering off \'' . $self->opts->{esx_vmname} . '\': ');
                if (!$self->print_error(ref($@->detail))) {
                    $self->debug_msg(0, "VM '" . $self->opts->{esx_vmname} . "' can't be powered off \n" . $@ . EMPTY);
                }
            }
            else {
                $self->debug_msg(0, "VM '" . $self->opts->{esx_vmname} . "' can't be powered off \n" . $@ . EMPTY);
            }
            $self->opts->{exitcode} = ERROR;
            return;
        }
    }
}

################################
# shutdown - Connect, call shutdown_vm, and disconnect from ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub shutdown {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Shutting down virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Successfully shut down virtual machine '" . $self->opts->{esx_vmname} . "'";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->shutdown_vm();
    }
    else {
        my $vm_prefix = $self->opts->{esx_vmname};
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
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
#   none
#
# Returns:
#   none
#
################################
sub shutdown_vm {
    my ($self) = @_;

    my $vm_view = Vim::find_entity_view(view_type => VIRTUAL_MACHINE,
                                        filter    => { 'name' => $self->opts->{esx_vmname} });

    if (!$vm_view) {
        $self->debug_msg(0, 'Virtual machine \'' . $self->opts->{esx_vmname} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    $self->debug_msg(1, 'Shutting down virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
    eval {
        $vm_view->ShutdownGuest();
        $self->debug_msg(0, 'Successfully shut down virtual machine \'' . $self->opts->{esx_vmname} . '\'');
    };
    if ($@) {
        if (ref($@) eq SOAP_FAULT) {
            $self->debug_msg(0, 'Error shutting down \'' . $self->opts->{esx_vmname} . '\': ');

            if (!$self->print_error(ref($@->detail))) {
                $self->debug_msg(0, "VM '" . $self->opts->{esx_vmname} . "' can't be shut down \n" . $@ . EMPTY);
            }
        }
        else {
            $self->debug_msg(0, "VM '" . $self->opts->{esx_vmname} . "' can't be shut down \n" . $@ . EMPTY);
        }
        $self->opts->{exitcode} = ERROR;
        return;
    }
}

################################
# suspend - Connect, call suspend_vm, and disconnect from ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub suspend {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Suspending virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Successfully suspended virtual machine '" . $self->opts->{esx_vmname} . "'";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->suspend_vm();
    }
    else {
        my $vm_prefix = $self->opts->{esx_vmname};
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
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
#   none
#
# Returns:
#   none
#
################################
sub suspend_vm {
    my ($self) = @_;

    my $vm_view = Vim::find_entity_view(view_type => VIRTUAL_MACHINE,
                                        filter    => { 'name' => $self->opts->{esx_vmname} });

    if (!$vm_view) {
        $self->debug_msg(0, 'Virtual machine \'' . $self->opts->{esx_vmname} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    $self->debug_msg(1, 'Suspending virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
    eval {
        $vm_view->SuspendVM();
        $self->debug_msg(0, 'Successfully suspended virtual machine \'' . $self->opts->{esx_vmname} . '\'');
    };
    if ($@) {
        if (ref($@) eq SOAP_FAULT) {
            $self->debug_msg(0, 'Error suspending \'' . $self->opts->{esx_vmname} . '\': ');

            if (!$self->print_error(ref($@->detail))) {
                $self->debug_msg(0, "VM '" . $self->opts->{esx_vmname} . "' can't be suspended \n" . $@ . EMPTY);
            }
        }
        else {
            $self->debug_msg(0, "VM '" . $self->opts->{esx_vmname} . "' can't be suspended \n" . $@ . EMPTY);
        }
        $self->opts->{exitcode} = ERROR;
        return;
    }
}

################################
# createresourcefromvm - Connect, call createresourcefrom_vm, and disconnect from ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub createresourcefromvm {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Creating resource for virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Resource created";
        $out .= "\n";
        $out .= "Waiting for ping response #(300) of resource " . $self->opts->{esx_vmname};
        $out .= "\n";
        $out .= "Ping response succesfully received";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->createresourcefrom_vm();
    }
    else {
        my $vm_prefix = $self->opts->{esx_vmname};
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
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
#   none
#
# Returns:
#   none
#
################################
sub createresourcefrom_vm {
    my ($self) = @_;

    $self->debug_msg(1, 'Getting information of virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
    my $vm_view;
    my $ip_address = '';
    my $hostname   = '';

    # Loop until ip address and hostname are correct
    # Timeout must be set in step
    while (TRUE) {
        $vm_view = Vim::find_entity_view(view_type => VIRTUAL_MACHINE,
                                         filter    => { 'name' => $self->opts->{esx_vmname} });
        if (!$vm_view) {
            $self->debug_msg(0, 'Virtual machine \'' . $self->opts->{esx_vmname} . '\' not found');
            $self->opts->{exitcode} = ERROR;
            return;
        }

        $ip_address = $vm_view->guest->ipAddress;
        $hostname   = $vm_view->guest->hostName;
        if (defined($ip_address) && $ip_address ne '' && defined($hostname) && $hostname ne '') {
            last;
        }
        sleep(DEFAULT_SLEEP);
    }

    # Store vm info in properties
    $self->debug_msg(1, 'Storing properties...');
    $self->debug_msg(1, 'IP address: ' . $ip_address);
    $self->debug_msg(1, 'Hostname: ' . $hostname);

    # Create ElectricCommander PropDB and store properties
    $self->{_props} = new ElectricCommander::PropDB($self->myCmdr(), EMPTY);
    $self->setProp('/' . $self->opts->{esx_vmname} . '/ipAddress', $ip_address);
    $self->setProp('/' . $self->opts->{esx_vmname} . '/hostName',  $hostname);

    #-------------------------------------
    # Add the vm name to VMList
    #-------------------------------------
    if ("$::instlist" ne EMPTY) { $::instlist .= ";"; }
    $::instlist .= $self->opts->{esx_vmname};
    $self->debug_msg(1, "Adding " . $self->opts->{esx_vmname} . " to vm list");

    # Create resource if specified
    if (defined($self->opts->{esx_create_resources}) && $self->opts->{esx_create_resources}) {

        $self->debug_msg(1, 'Creating resource for virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
        my $cmdrresult = $self->myCmdr()->createResource(
                                                         $self->opts->{esx_vmname},
                                                         {
                                                            description   => "ESX created resource",
                                                            workspaceName => $self->opts->{esx_workspace},
                                                            hostName      => $ip_address,
                                                            pools         => $self->opts->{esx_pools}
                                                         }
                                                        );

        # Check for error return
        my $errMsg = $self->myCmdr()->checkAllErrors($cmdrresult);
        if ($errMsg ne EMPTY) {
            $self->debug_msg(1, "Error: $errMsg");
            $self->opts->{exitcode} = ERROR;
            return;
        }

        $self->debug_msg(1, 'Resource created');

        # Test connection to vm
        my $resStarted = 0;
        my $try        = DEFAULT_PING_TIMEOUT;
        while ($try > 0) {
            $self->debug_msg(1, "Waiting for ping response #(" . $try . ") of resource " . $self->opts->{esx_vmname});
            my $pingresult = $self->pingResource($self->opts->{esx_vmname});
            if ($pingresult == 1) {
                $resStarted = 1;
                last;
            }
            sleep(1);
            $try -= 1;
        }
        if ($resStarted == 0) {
            $self->debug_msg(1, 'Unable to ping virtual machine');
            $self->opts->{exitcode} = ERROR;
        }
        else {
            $self->debug_msg(1, 'Ping response succesfully received');
        }

        $self->setProp('/' . $self->opts->{esx_vmname} . '/resource', $self->opts->{esx_vmname});
    }

}

################################
# getvmconfiguration - Connect, call get_vm_configuration, and disconnect from ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
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

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->get_vm_configuration();
    }
    else {
        my $vm_prefix = $self->opts->{esx_vmname};
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
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
#   none
#
# Returns:
#   none
#
################################
sub get_vm_configuration {
    my ($self) = @_;

    my $vm_view = Vim::find_entity_view(view_type => VIRTUAL_MACHINE,
                                        filter    => { 'name' => $self->opts->{esx_vmname} });

    if (!$vm_view) {
        $self->debug_msg(0, 'Virtual machine \'' . $self->opts->{esx_vmname} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    $self->debug_msg(1, 'Getting information of virtual machine \'' . $self->opts->{esx_vmname} . '\'...');

    # Retrieve virtual machine info
    my $ip_address = $vm_view->guest->ipAddress;
    my $hostname   = $vm_view->guest->hostName;

    if (!defined($ip_address) or $ip_address eq EMPTY or !defined($hostname) or $hostname eq EMPTY) {

        # Failed to get ip address or hostname
        $self->debug_msg(1, 'Unable to get IP address and/or hostname from virtual machine \'' . $self->opts->{esx_vmname} . '\'');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    # Store vm info in properties
    $self->debug_msg(1, 'Storing properties...');
    $self->debug_msg(1, 'IP address: ' . $ip_address);
    $self->debug_msg(1, 'Hostname: ' . $hostname);

    # Create ElectricCommander PropDB
    $self->{_props} = new ElectricCommander::PropDB($self->myCmdr(), EMPTY);

    $self->setProp('/' . $self->opts->{esx_vmname} . '/ipAddress', $ip_address);
    $self->setProp('/' . $self->opts->{esx_vmname} . '/hostName',  $hostname);
}

################################
# import - Iterate and call import_vm
#
# Arguments:
#   none
#
# Returns:
#   none
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
        $out .= "Opening VI target: " . "vi://" . $self->opts->{esx_user} . ":" . $self->opts->{esx_pass} . "@" . $self->opts->{esx_host} . "/";
        $out .= "Deploying to VI: " . "vi://" . $self->opts->{esx_user} . "@" . $self->opts->{esx_host} . "/";
        $out .= "Disk progress: 0%\nDisk progress: 1%\nDisk progress: 96%\nDisk progress: 97%\nDisk progress: 99%\nDisk Transfer Completed";
        $out .= "\n";
        $out .= "Completed successfully";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->opts->{esx_ovf_file} = CURRENT_DIRECTORY . '/' . $self->opts->{esx_vmname} . '/' . $self->opts->{esx_vmname} . '.ovf';
        $self->import_vm();
    }
    else {
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
            $vm_number = $i + 1;
            $self->opts->{esx_ovf_file} = CURRENT_DIRECTORY . '/' . $self->opts->{esx_vmname} . "_$vm_number/" . $self->opts->{esx_vmname} . "_$vm_number.ovf";
            $self->import_vm();
        }
    }
}

################################
# import_vm - Import an OVF package to the ESX server using ovftool
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub import_vm {
    my ($self) = @_;

    # Call ovftool to import OVF package
    $self->debug_msg(1, 'Importing OVF package...');
    my $command = 'ovftool --datastore=' . $self->opts->{esx_datastore} . ' "' . $self->opts->{esx_ovf_file} . '" "vi://' . $self->opts->{esx_user} . ':' . $self->opts->{esx_pass} . '@' . $self->opts->{esx_host} . '/"';
    system($command);
}

################################
# export - Iterate and call export_vm
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub export {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Exporting virtual machine...";
        $out .= "\n";
        $out .= "Opening VI source: " . "vi://" . $self->opts->{esx_user} . "@" . $self->opts->{esx_host} . "/" . $self->opts->{esx_datacenter};
        $out .= "Opening OVF target: " . $self->opts->{esx_target_directory};
        $out .= "Writing OVF package: " . $self->opts->{esx_target_directory} . "/" . $self->opts->{esx_vmname} . "/" . $self->opts->{esx_vmname} . ".ovf";
        $out .= "Disk progress: 0%\nDisk Transfer Completed";
        $out .= "\n";
        $out .= "Completed successfully";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    if ($self->opts->{esx_number_of_vms} == DEFAULT_NUMBER_OF_VMS) {
        $self->opts->{esx_source} = $self->opts->{esx_vmname} . '/' . $self->opts->{esx_vmname} . '.vmx';
        $self->export_vm();
    }
    else {
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
            $vm_number = $i + 1;
            $self->opts->{esx_source} = $self->opts->{esx_vmname} . "_$vm_number/" . $self->opts->{esx_vmname} . "_$vm_number.vmx";
            $self->export_vm();
        }
    }
}

################################
# export_vm - Export a virtual machine to an OVF package using ovftool
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub export_vm {
    my ($self) = @_;

    # Call ovftool to export virtual machine
    $self->debug_msg(1, 'Exporting virtual machine...');
    my $command = 'ovftool "vi://' . $self->opts->{esx_user} . ':' . $self->opts->{esx_pass} . '@' . $self->opts->{esx_host} . '/' . $self->opts->{esx_datacenter} . '?ds=[' . $self->opts->{esx_datastore} . '] ' . $self->opts->{esx_source} . '" "' . CURRENT_DIRECTORY . '"';
    system($command);
}

################################
# register - Connect, call register_vm, and disconnect from ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub register {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Registering virtual machine '" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
        $out .= "Virtual machine '" . $self->opts->{esx_vmname} . "' successfully registered under host " . $self->opts->{esx_host};
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }
    $self->register_vm();
    $self->logout();
}

################################
# register_vm - Register an existing virtual machine to the ESX server
#
# Arguments:
#   none
#
# Returns:
#   none
#
################################
sub register_vm {
    my ($self) = @_;

    # Get host view
    my $host_view = Vim::find_entity_view(view_type => HOST_SYSTEM, filter => { 'name' => $self->opts->{esx_host} });
    if (!$host_view) {
        $self->debug_msg(0, 'No host found with name ' . $self->opts->{esx_host});
        $self->opts->{exitcode} = ERROR;
        return;
    }

    # Get datacenter and folder view
    my $datacenter = Vim::find_entity_view(view_type => DATACENTER, filter => { name => $self->opts->{esx_datacenter} });
    if (!$datacenter) {
        $self->debug_msg(0, 'No data center found with name: ' . $self->opts->{esx_datacenter});
        $self->opts->{exitcode} = ERROR;
        return;
    }
    my $folder_view = Vim::get_view(mo_ref => $datacenter->vmFolder);

    # Get resource pool views
    my $pool_views = Vim::find_entity_views(
                                            view_type    => RESOURCE_POOL,
                                            begin_entity => $host_view->parent,
                                            filter       => { 'name' => $self->opts->{esx_pool} }
                                           );

    unless (@$pool_views) {
        $self->debug_msg(0, 'Resource pool \'' . $self->opts->{esx_pool} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }
    if ($#{$pool_views} != 0) {
        $self->debug_msg(0, 'Resource pool \'' . $self->opts->{esx_pool} . '\' not unique');
        $self->opts->{exitcode} = ERROR;
        return;
    }
    my $pool = shift(@$pool_views);
    eval {
        $self->debug_msg(1, 'Registering virtual machine \'' . $self->opts->{esx_vmname} . '\'...');
        $folder_view->RegisterVM(
                                 path       => $self->opts->{esx_vmxpath},
                                 name       => $self->opts->{esx_vmname},
                                 asTemplate => 'false',
                                 pool       => $pool,
                                 host       => $host_view
                                );

        $self->debug_msg(0, 'Virtual machine \'' . $self->opts->{esx_vmname} . '\' successfully registered under host ' . $host_view->name);
    };
    if ($@) {
        if (ref($@) eq SOAP_FAULT) {
            if (ref($@->detail) eq ALREADY_EXISTS) {
                $self->debug_msg(0, 'The specified key, name, or identifier already exists');
            }
            elsif (ref($@->detail) eq DUPLICATE_NAME) {
                $self->debug_msg(0, 'A virtual machine named ' . $self->opts->{esx_vmname} . ' already exists');
            }
            elsif (ref($@->detail) eq FILE_FAULT) {
                $self->debug_msg(0, 'Failed to access the virtual machine files');
            }
            elsif (ref($@->detail) eq INSUFFICIENT_RESOURCES_FAULT) {
                $self->debug_msg(0, 'Resource usage policy violated');
            }
            elsif (ref($@->detail) eq INVALID_NAME) {
                $self->debug_msg(0, 'Specified name is not valid');
            }
            elsif (ref($@->detail) eq NOT_FOUND) {
                $self->debug_msg(0, 'Configuration file not found on the system');
            }
            elsif (ref($@->detail) eq OUT_OF_BOUNDS) {
                $self->debug_msg(0, 'Maximum number of virtual machines has been exceeded');
            }
            elsif (ref($@->detail) eq INVALID_ARGUMENT) {
                $self->debug_msg(0, 'A specified parameter was not correct');
            }
            elsif (ref($@->detail) eq DATACENTER_MISMATCH) {
                $self->debug_msg(0, 'Datacenter mismatch: The input arguments had entities that did not belong to the same datacenter');
            }
            elsif (ref($@->detail) eq INVALID_DATASTORE) {
                $self->debug_msg(0, 'Invalid datastore path: ' . $self->opts->{esx_vmxpath});
            }
            elsif (ref($@->detail) eq NOT_SUPPORTED) {
                $self->debug_msg(0, 'Operation is not supported');
            }
            elsif (ref($@->detail) eq INVALID_STATE) {
                $self->debug_msg(0, 'The operation is not allowed in the current state');
            }
            else {
                $self->debug_msg(0, $@);
            }
        }
        else {
            $self->debug_msg(0, $@);
        }
        $self->opts->{exitcode} = ERROR;
        return;
    }
}

###############################
# getAvailableVM - get a list of available vms
#
# Arguments:
#   prefix - prefix for vmname
#
# Returns:
#   vmname
#
################################
sub getAvailableVM {
    my ($self, $pattern) = @_;

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    my $vm_views;

    $vm_views = Vim::find_entity_views(
                                       view_type => VIRTUAL_MACHINE,
                                       filter    => {
                                                   'name'               => qr/$pattern/i,
                                                   'runtime.powerState' => 'poweredOff'
                                                 }
                                      );

    if (!@$vm_views[0]) {
        $self->debug_msg(0, "No available machines with pattern '$pattern'. ");
        $self->opts->{exitcode} = ERROR;
        return;
    }
    $self->logout();

    return @$vm_views[0]->name;

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
        $self->debug_msg(0, 'Current State of the virtual machine is not supported for this operation');
        return TRUE;
    }
    elsif ($error eq INVALID_POWER_STATE) {
        $self->debug_msg(0, 'The attempted operation cannot be performed in the current state');
        return TRUE;
    }
    elsif ($error eq NOT_SUPPORTED) {
        $self->debug_msg(0, 'The operation is not supported on the object');
        return TRUE;
    }
    elsif ($error eq TASK_IN_PROGRESS) {
        $self->debug_msg(0, 'Virtual machine is busy');
        return TRUE;
    }
    elsif ($error eq RUNTIME_FAULT) {
        $self->debug_msg(0, 'A runtime fault occured');
        return TRUE;
    }
    elsif ($error eq TOOLS_UNAVAILABLE) {
        $self->debug_msg(0, 'VMTools are not running in this VM');
        return TRUE;
    }
    return FALSE;
}

################################
# create_conf_spec - Create virtual device config spec for controller
#
# Arguments:
#   none
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

    my $controller_vm_dev_conf_spec = VirtualDeviceConfigSpec->new(device    => $controller,
                                                                   operation => VirtualDeviceConfigSpecOperation->new('add'));
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
    my ($self, $ds_path) = @_;

    my $disksize = $self->opts->{esx_disksize};

    my $disk_backing_info = VirtualDiskFlatVer2BackingInfo->new(diskMode => 'persistent',
                                                                fileName => $ds_path);

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
    my ($self, $host_view) = @_;

    my $network_name = $self->opts->{esx_nic_network};
    my $poweron      = $self->opts->{esx_nic_poweron};
    my $network      = undef;
    my $unit_num     = 1;                                # 1 since 0 is used by disk

    if ($network_name) {
        my $network_list = Vim::get_views(mo_ref_array => $host_view->network);
        foreach (@$network_list) {
            if ($network_name eq $_->name) {
                $network = $_;
                my $nic_backing_info = VirtualEthernetCardNetworkBackingInfo->new(deviceName => $network_name,
                                                                                  network    => $network);

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

                my $nic_vm_dev_conf_spec = VirtualDeviceConfigSpec->new(device    => $nic,
                                                                        operation => VirtualDeviceConfigSpecOperation->new('add'));

                return (error => 0, network_conf => $nic_vm_dev_conf_spec);
            }
        }
        if (!defined($network)) {

            # no network found
            return (error => 1);
        }
    }

    # default network will be used
    return (error => 2);
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
    my ($self, $host_view, $config_datastore) = @_;

    my $name = undef;
    my $mor  = undef;

    my $ds_mor_array = $host_view->datastore;
    my $datastores = Vim::get_views(mo_ref_array => $ds_mor_array);

    my $found_datastore = 0;

    # User specified datastore name.  It's possible no such
    # datastore exists, in which case an error is generated.
    if (defined($config_datastore)) {
        foreach (@$datastores) {
            $name = $_->summary->name;
            if ($name eq $config_datastore) {    # if datastore available to host
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
            my $ds_disksize = ($_->summary->freeSpace);

            if ($ds_disksize > $disksize && $_->summary->accessible) {
                $found_datastore = 1;
                $name            = $_->summary->name;
                $mor             = $_->{mo_ref};
                $disksize        = $ds_disksize;
            }
        }
    }

    if (!$found_datastore) {
        my $host_name = $host_view->name;
        my $ds_name   = '<any accessible datastore>';
        if (defined($self->opts->{esx_datastore})
            && $self->opts->{esx_datastore} ne '')
        {
            $ds_name = $self->opts->{esx_datastore};
        }
        $self->debug_msg(0, 'Datastore \'' . $ds_name . '\' is not available to host ' . $host_name);
        $self->opts->{exitcode} = ERROR;
        return (error => TRUE);
    }

    return (name => $name, mor => $mor);
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
    my ($self, $tree, $name) = @_;
    my $ref   = undef;
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

    my $alive  = "0";
    my $result = $self->myCmdr()->pingResource($resource);
    if (!$result) { return NOT_ALIVE; }
    $alive = $result->findvalue('//alive');
    if ($alive eq "1") { return ALIVE; }
    return NOT_ALIVE;
}

###############################
# checkState - Check the power state of a vm
#
# Arguments:
#   name -  vmname
#
# Returns:
#   state
#
################################
sub checkState {
    my ($self, $name) = @_;

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with WMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    my $vm_view = Vim::find_entity_view(view_type => VIRTUAL_MACHINE,
                                        filter    => { 'name' => $name });

    if (!$vm_view) {
        $self->debug_msg(0, 'Virtual machine \'' . $name . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }

    # print $vm_view->runtime->powerState->val . "\n";

    $self->logout();

    return $vm_view->runtime->powerState->val;

}

###############################
# debug_msg - Print a debug message
#
# Arguments:
#   errorlevel - number compared to $self->opts->{Debug}
#   msg        - string message
#
# Returns:
#   none
#
################################
sub debug_msg {
    my ($self, $errlev, $msg) = @_;
    if ($self->opts->{Debug} >= $errlev) { print "$msg\n"; }
}

