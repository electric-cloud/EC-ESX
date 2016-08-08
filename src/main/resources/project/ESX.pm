#
#  Copyright 2015 Electric Cloud, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

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

#use warnings;
use strict;
use Carp;
use Data::Dumper;
use ElectricCommander;
use ElectricCommander::PropDB;
use ElectricCommander::PropDB qw(/myProject/libs);

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
        #$self->opts->{esx_ovf_file} = CURRENT_DIRECTORY . '/' . $self->opts->{esx_vmname} . '/' . $self->opts->{esx_vmname} . '.ovf';
        $self->import_vm();
    }
    else {
        my $vm_number;
        for (my $i = 0; $i < $self->opts->{esx_number_of_vms}; $i++) {
            $vm_number = $i + 1;
            #$self->opts->{esx_ovf_file} = CURRENT_DIRECTORY . '/' . $self->opts->{esx_vmname} . "_$vm_number/" . $self->opts->{esx_vmname} . "_$vm_number.ovf";
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
    $self->opts->{esx_url} =~ m{https://(.*)};
    my $esx_server = $1;
    my $command = $self->opts->{ovftool_path} . ' --noSSLVerify --datastore=' . $self->opts->{esx_datastore} . ' -n=' . $self->opts->{esx_vmname} . ' ' . $self->opts->{esx_source_directory} . ' vi://' . $self->opts->{esx_user} . ':' . $self->opts->{esx_pass} . '@' . $esx_server . '?ip=' . $self->opts->{esx_host};
    $self->debug_msg(1, 'Executing command: ' . $command);
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
    #
    $self->debug_msg(1, 'Exporting virtual machine...');
    my $command =  $self->opts->{ovftool_path} . ' --disableVerification --noSSLVerify vi://' . $self->opts->{esx_user} . ':' . $self->opts->{esx_pass} . '@' . $self->opts->{esx_host} . '/' . $self->opts->{esx_datacenter} . '?ds=[' . $self->opts->{esx_datastore} . ']/' . $self->opts->{esx_source} . ' ' . $self->opts->{esx_target_directory};
    $self->debug_msg(1, 'Executing command: ' . $command);
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
################################
# list - Connect, call list_entity, and disconnect from ESX server
#
# Arguments:
#   Hash(Entity Type)
#
# Returns:
#   none
#
################################
sub list {
    print "Listing Entity";
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Listing Entity '" . $self->opts->{entity_type} . "'...";
        $out .= "\n";
        $out .= "Successfully listed entity '" . $self->opts->{entity_type} . "'";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    $self->list_entity();

    $self->logout();
}

################################
# list_entity - List the entity of type $opts->{entity_name}
#
# Arguments:
#   Hash(Entity Type)
#
# Returns:
#   none
#
################################
sub list_entity {
    my ($self) = @_;
    $self->debug_msg(1, 'Listing Entity \'' . $self->opts->{entity_type} . '\'...');
    eval {
        my $entity_views = Vim::find_entity_views(view_type => $self->opts->{entity_type});

        if (!$entity_views) {
            $self->debug_msg(0, 'Entity \'' . $self->opts->{entity_type} . '\' not found');
            $self->opts->{exitcode} = ERROR;
            return;
        }
        #Print the output
        foreach my $entity_view (@$entity_views) {
            my $entity_name = $entity_view->name;
            Util::trace(0, "$entity_name\n");
        }

        $self->debug_msg(0, 'Successfully Listed Entity \'' . $self->opts->{entity_type} . '\'');
    };
    if ($@) {
        if (ref($@) eq SOAP_FAULT) {
            $self->debug_msg(0, 'Error listing entity \'' . $self->opts->{entity_type} . '\': ');

            if (!$self->print_error(ref($@->detail))) {
                $self->debug_msg(0, "Entity '" . $self->opts->{entity_type} . "' can't be listed \n" . $@ . EMPTY);
            }
        }
        else {
            $self->debug_msg(0, "Entity '" . $self->opts->{entity_type} . "' can't be listed \n" . $@ . EMPTY);
        }
        $self->opts->{exitcode} = ERROR;
        return;
    }
}

################################
# createFolder - Connect, call create_folder, and disconnect from ESX server
#
# Arguments:
#   Hash(connection_config, folder_name, parent_type) 
#
# Returns:
#   none
#
################################
sub createFolder {
    print "Creating Folder";
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Creating Folder '" . $self->opts->{folder_name} . "'...";
        $out .= "\n";
        $out .= "Successfully created folder '" . $self->opts->{folder_name} . "'";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    $self->create_folder();

    $self->logout();
}

################################
# create_folder - Create a folder inside parent of type $opts->{parent_type} and name $opts->{parent_name}
#
# Arguments:
#   Hash(connection_config, folder_name, parent_type)
#
# Returns:
#   none
#
################################
sub create_folder {
    my ($self) = @_;
    $self->debug_msg(1, 'Creating Folder \'' . $self->opts->{folder_name} . '\'...');
    eval {
        my $parent_view = Vim::find_entity_view(view_type => $self->opts->{parent_type}, filter => { name => $self->opts->{parent_name}});
        if (!$parent_view) {
            $self->debug_msg(0, 'Parent Entity \'' . $self->opts->{parent_name} . '\' not found');
            $self->opts->{exitcode} = ERROR;
            return;
        }
        if ( $self->opts->{parent_type} eq 'Datacenter') {
            #Overwriting Parent View for getting folder view
            $parent_view = Vim::find_entity_view(view_type => 'Folder', begin_entity => $parent_view);
            if (!$parent_view) {
                $self->debug_msg(0, 'Folder View out of Parent Entity \'' . $self->opts->{parent_name} . '\' not found');
                $self->opts->{exitcode} = ERROR;
                return;
            }
        }
        $parent_view->CreateFolder(name => $self->opts->{folder_name});

        $self->debug_msg(0, 'Successfully Created Folder \'' . $self->opts->{folder_name} . '\'');
    };
    if ($@) {
        if (ref($@) eq SOAP_FAULT) {
            $self->debug_msg(0, 'Error creating folder \'' . $self->opts->{folder_name} . '\': ');

            if (!$self->print_error(ref($@->detail))) {
                $self->debug_msg(0, "Folder '" . $self->opts->{folder_name} . "' can't be created \n" . $@ . EMPTY);
            }
        }
        else {
            $self->debug_msg(0, "Folder '" . $self->opts->{folder_name} . "' can't be created \n" . $@ . EMPTY);
        }
        $self->opts->{exitcode} = ERROR;
        return;
    }
}

################################
# delete - Connect, call delete_entity, and disconnect from ESX server
#
# Arguments:
#   Hash(Entity Type, Entity Name)
#
# Returns:
#   none
#
################################
sub delete {
    print "Deleting Entity";
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Deleting Entity '" . $self->opts->{entity_name} . "'...";
        $out .= "\n";
        $out .= "Successfully deleted entity '" . $self->opts->{entity_name} . "'";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    $self->delete_entity();

    $self->logout();
}

################################
# delete_entity - Delete the entity  $opts->{entity_name}
#
# Arguments:
#   Hash(Entity Type, Entity Name)
#
# Returns:
#   none
#
################################
sub delete_entity {
    my ($self) = @_;
    $self->debug_msg(1, 'Deleting Entity \'' . $self->opts->{entity_name} . '\'...');
    eval {
        my $entity_view = Vim::find_entity_view(view_type => $self->opts->{entity_type}, filter => { 'name' => $self->opts->{entity_name} } );

        if (!$entity_view) {
            $self->debug_msg(0, 'Entity \'' . $self->opts->{entity_name} . '\' not found');
            $self->opts->{exitcode} = ERROR;
            return;
        }
        $entity_view->Destroy;
        $self->debug_msg(0, 'Successfully Deleted Entity \'' . $self->opts->{entity_name} . '\'');
    };
    if ($@) {
        if (ref($@) eq SOAP_FAULT) {
            $self->debug_msg(0, 'Error deleting entity \'' . $self->opts->{entity_name} . '\': ');

            if (!$self->print_error(ref($@->detail))) {
                $self->debug_msg(0, "Entity '" . $self->opts->{entity_name} . "' can't be deleted \n" . $@ . EMPTY);
            }
        }
        else {
            $self->debug_msg(0, "Entity '" . $self->opts->{entity_name} . "' can't be deleted \n" . $@ . EMPTY);
        }
        $self->opts->{exitcode} = ERROR;
        return;
    }
}

################################
# rename - Connect, call rename_entity, and disconnect from ESX server
#
# Arguments:
#   Hash(Entity Type, Entity Old Name, Entity New Name)
#
# Returns:
#   none
#
################################
sub rename {
    print "Renaming Entity";
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Renaming Entity '" . $self->opts->{entity_old_name} . "' to '" . $self->opts->{entity_new_name} . "'...";
        $out .= "\n";
        $out .= "Successfully renamed entity '" . $self->opts->{entity_old_name} . "'";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    $self->rename_entity();

    $self->logout();
}

################################
# rename_entity - Rename the entity $opts->{entity_old_name}
#
# Arguments:
#   Hash(Entity Type, Entity Old Name, Entity New Name)
#
# Returns:
#   none
#
################################
sub rename_entity {
    my ($self) = @_;
    $self->debug_msg(1, 'Renaming Entity \'' . $self->opts->{entity_old_name} . '\' to \'' . $self->opts->{entity_new_name} . '\'...');
    eval {
        my $entity_old_view = Vim::find_entity_view(view_type => $self->opts->{entity_type}, filter => { 'name' => $self->opts->{entity_old_name} } );

        if (!$entity_old_view) {
            $self->debug_msg(0, 'Entity \'' . $self->opts->{entity_old_name} . '\' not found');
            $self->opts->{exitcode} = ERROR;
            return;
        }
        $entity_old_view->Rename(newName => $self->opts->{entity_new_name});
        $self->debug_msg(0, 'Successfully renamed Entity \'' . $self->opts->{entity_old_name} . '\'');
    };
    if ($@) {
        if (ref($@) eq SOAP_FAULT) {
            $self->debug_msg(0, 'Error renaming entity \'' . $self->opts->{entity_old_name} . '\': ');

            if (!$self->print_error(ref($@->detail))) {
                $self->debug_msg(0, "Entity '" . $self->opts->{entity_old_name} . "' can't be renamed \n" . $@ . EMPTY);
            }
        }
        else {
            $self->debug_msg(0, "Entity '" . $self->opts->{entity_old_name} . "' can't be renamed \n" . $@ . EMPTY);
        }
        $self->opts->{exitcode} = ERROR;
        return;
    }
}
##BEGIN##
################################
# moveEntity - Connect, call moveEntity, and disconnect from ESX server
#
# Arguments:
#   Hash(connection_config, destination_name, entity_type)
#
# Returns:
#   none
#
################################
sub moveEntity {
    print "Moving VM/Folder to destination Folder" . "\n";
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Moving Entity '" . $self->opts->{entity_name} . "'...";
        $out .= "\n";
        $out .= 'Successfully Moved \'' . $self->opts->{entity_name} . '\' to \'' . $self->opts->{destination_name} . '\'';
        return $out;
    }

    #Set default values
    $self->initialize();
    #$self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    $self->move_entity();

    $self->logout();
}

################################
# moveEntity - Move an Entity  of type $opts->{Entity_type} and name $opts->{entity_name}
#
# Arguments:
#   Hash(connection_config, destination_name, entity_type)
#
# Returns:
#   none
#
################################
sub move_entity {
    my ($self) = @_;
    eval {
        my $source_view = Vim::find_entity_view(view_type => $self->opts->{entity_type}, filter => { 'name' => $self->opts->{entity_name} } );
        if (!$source_view) {
            $self->debug_msg(0, 'source_view\'' . $self->opts->{entity_name} . '\' not found');
            $self->opts->{exitcode} = ERROR;
            return;
        }
        my $destination_view = Vim::find_entity_view(view_type => 'Folder',filter => { 'name' => $self->opts->{destination_name}});
        if (!$destination_view) {
            $self->debug_msg(0, 'destination_view\'' . $self->opts->{destination_name} . '\' not found');
            $self->opts->{exitcode} = ERROR;
            return;
        }
        $destination_view->MoveIntoFolder_Task(list => $source_view);
        $self->debug_msg(0, 'Successfully Moved \'' . $self->opts->{entity_name} . '\' to \'' . $self->opts->{destination_name} . '\'');
        if ($@) {
            if (ref($@) eq SOAP_FAULT) {
                 $self->debug_msg(0, 'Error moving folder \'' . $self->opts->{entity_name} . '\': ');

                 if (!$self->print_error(ref($@->detail))) {
                     $self->debug_msg(0, "Folder '" . $self->opts->{entity_name} . "' can't be moved \n" . $@ . EMPTY);
                 }
            }
            else {
                 $self->debug_msg(0, "Folder '" . $self->opts->{entity_name} . "' can't be moved \n" . $@ . EMPTY);
            }
            $self->opts->{exitcode} = ERROR;
            return;
        }
    }
}
################################
# summary - Connect, call display_esx_summary, and disconnect from ESX server
#
# Arguments:
#   Hash(Host Name)
#
# Returns:
#   none
#
################################
sub summary {
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Displaying summary for Host: '" . $self->opts->{host_name} . "'...";
        $out .= "\n";
        $out .= "Successfully displayed summary for Host: '" . $self->opts->{host_name} . "'";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    $self->display_esx_summary();
    $self->myCmdr->setProperty('/myJob/summary', $self->opts->{summary});
    $self->logout();
}

sub logger{
    my ($self, $debugLevel, $message) = @_;
    $self->debug_msg($debugLevel, $message);
    $self->opts->{summary} .= $message . "\n"; 
}

################################
# display_esx_summary - Display the service of host: $opts->{host_name}
#
# Arguments:
#   Hash(Host Name, Show Live Usage, Show Network Info, Show Storage Info)
#
# Returns:
#   none
#
################################
sub display_esx_summary {
    my ($self) = @_;
    my $message;
    $self->opts->{summary} = "";
    $self->logger(1, 'Displaying summary for Host: \'' . $self->opts->{host_name} . '\'...');
    
    eval {
        my $host = Vim::find_entity_view(view_type => 'HostSystem', filter => { name => $self->opts->{host_name}});
        if (!$host) {
            $self->logger(0, 'Host: \'' . $self->opts->{host_name} . '\' not found');
            $self->opts->{exitcode} = ERROR;
            return;
        }
        $self->{'host'} = $host;
        display_esx_general_info($self);
        if ( $self->opts->{live_usage} == '1' ) {
            display_esx_resource_info($self);
        }
        if ( $self->opts->{network_info} == '1' ) {
            display_esx_network_info($self);
        }
        if ( $self->opts->{storage_info} == '1' ) {
            display_esx_storage_info($self);
        }
        $self->logger(0, 'Successfully displayed summary for Host: \'' . $self->opts->{host_name} . '\'');
    };
    if ($@) {
        if (ref($@) eq SOAP_FAULT) {
            $self->logger(0, 'Error displaying summary for \'' . $self->opts->{host_name} . '\': ');

            if (!$self->print_error(ref($@->detail))) {
                $self->logger(0, "Summary for '" . $self->opts->{host_name} . "' can't be displayed \n" . $@ . EMPTY);
            }
        }
        else {
            $self->logger(0, "Summary for '" . $self->opts->{host_name} . "' can't be displayed \n" . $@ . EMPTY);
        }
        $self->opts->{exitcode} = ERROR;
        return;
    }
}
##BEGIN##
################################
# createResourcepool - Connect, call createResourcepool, and disconnect from ESX server
#
# Arguments:
#   Hash(connection_config,resourcepool_name,parent_resourcepool_name,cpu_shares,mem_shares)
#
# Returns:
#   none
#
################################
sub createResourcepool {
    print "Creating Resoucepool" . "\n";
    my ($self) = @_;
	if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Creating Resoucepool'" . $self->opts->{resourcepool_name} . "'...";
        $out .= "\n";
		#$out .= 'Successfully created \'' . $self->opts->{resourcepool_name} . '\' in \'' . $self->opts->{parent_resourcepool_name} . '\'';
        return $out;
    }

    #Set default values
    $self->initialize();
    #$self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    $self->create_resoucepool();

    $self->logout();
}

################################
# createResourcepool - Creating a resoucepool of name $opts->{resourcepool_name}
#
# Arguments:
#   Hash(connection_config,resourcepool_name,parent_resourcepool_name,cpu_shares,mem_shares)
#
# Returns:
#   none
#
################################
sub create_resoucepool {
    my ($self) = @_;
    eval {
		my $parent_pool_view = Vim::find_entity_view(view_type => 'ResourcePool',filter => { 'name' => $self->opts->{parent_resourcepool_name} } );
		if (!$parent_pool_view) {
        $self->debug_msg(0, 'parent_pool_view\'' . $self->opts->{parent_resourcepool_name} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
        }
		my $sharesLevel = SharesLevel->new($self->opts->{cpu_shares});
		my $memLevel    = SharesLevel->new($self->opts->{mem_shares});
		my $cpuShares   = SharesInfo->new(shares => 0, level => $sharesLevel);
        my $memShares   = SharesInfo->new(shares => 0, level => $memLevel);
        my $cpuAllocation = ResourceAllocationInfo->new(expandableReservation => 'true', limit => -1, reservation => 0, shares => 		   $cpuShares);
        my $memoryAllocation = ResourceAllocationInfo->new(expandableReservation => 'true', limit => -1, reservation => 0, shares => $memShares);
		my $rp_spec = ResourceConfigSpec->new(cpuAllocation => $cpuAllocation, memoryAllocation => $memoryAllocation);
		my $newRP = $parent_pool_view->CreateResourcePool(name => $self->opts->{resourcepool_name}, spec => $rp_spec);
		$self->debug_msg(0, 'Successfully Created \'' . $self->opts->{resourcepool_name} . '\' in \'' . $self->opts->{parent_resourcepool_name} . '\'');
        if ($@) {
            if (ref($@) eq SOAP_FAULT) {
                 $self->debug_msg(0, 'Error Creating resoucepool \'' . $self->opts->{resourcepool_name} . '\': ');

                 if (!$self->print_error(ref($@->detail))) {
                     $self->debug_msg(0, "Resoucepool '" . $self->opts->{resourcepool_name} . "' can't be Created \n" . $@ . EMPTY);
                 }
            }
            else {
                 $self->debug_msg(0, "Resoucepool '" . $self->opts->{resourcepool_name} . "' can't be Created \n" . $@ . EMPTY);
            }
            $self->opts->{exitcode} = ERROR;
            return;
        }
    }
}
##BEGIN##
################################
# editResourcepool - Connect, call editResourcepool, and disconnect from ESX server
#
# Arguments:
#   Hash(connection_config,edit_resourcepool_name,edit_parent_resourcepool_name,edit_cpu_shares,edit_mem_shares)
#
# Returns:
#   none
#
################################
sub editResourcepool {
    print "Editing Resoucepool" . "\n";
    my ($self) = @_;
	if ($::gRunTestUseFakeOutput) {
        # Create and return fake output
        my $out = "";
        $out .= "Editing Resoucepool'" . $self->opts->{edit_resourcepool_name} . "'...";
        $out .= "\n";
		$out .= 'Successfully Edited \'' . $self->opts->{edit_resourcepool_name} . '\' in \'' . $self->opts->{edit_parent_resourcepool_name} . '\'';
        return $out;
    }

    #Set default values
    $self->initialize();
    #$self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    $self->edit_resoucepool();

    $self->logout();
}

################################
# editResourcepool - Editing a resoucepool of name $opts->{edit_resourcepool_name} to $opts->{modified_resourcepool_name}
#
# Arguments:
#   Hash(connection_config,edit_resourcepool_name,edit_parent_resourcepool_name,edit_cpu_shares,edit_mem_shares)
#
# Returns:
#   none
#
################################
sub edit_resoucepool {
    my ($self) = @_;
    eval {
		my $parent_pool_view = Vim::find_entity_view(view_type => 'ResourcePool',filter => { 'name' => $self->opts->{edit_parent_resourcepool_name} } );
		if (!$parent_pool_view) {
        $self->debug_msg(0, 'parent_pool_view\'' . $self->opts->{edit_parent_resourcepool_name} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
        }
		my $sharesLevel = SharesLevel->new($self->opts->{edit_cpu_shares});
		my $memLevel    = SharesLevel->new($self->opts->{edit_mem_shares});
		my $cpuShares   = SharesInfo->new(shares => 0, level => $sharesLevel);
        my $memShares   = SharesInfo->new(shares => 0, level => $memLevel);
        my $cpuAllocation = ResourceAllocationInfo->new(expandableReservation => 'true', limit => -1, reservation => 0, shares => $cpuShares);
        my $memoryAllocation = ResourceAllocationInfo->new(expandableReservation => 'true', limit => -1, reservation => 0, shares => $memShares);
		my $rp_spec = ResourceConfigSpec->new(cpuAllocation => $cpuAllocation, memoryAllocation => $memoryAllocation);
		my $newRP = $parent_pool_view->UpdateConfig(name => $self->opts->{edit_resourcepool_name}, config => $rp_spec);
		$self->debug_msg(0, 'Successfully Edited \'' . $self->opts->{edit_parent_resourcepool_name} . '\' to \'' . $self->opts->{edit_resourcepool_name} . '\'');
        if ($@) {
            if (ref($@) eq SOAP_FAULT) {
                 $self->debug_msg(0, 'Error While Editing resoucepool \'' . $self->opts->{edit_resourcepool_name} . '\': ');

                 if (!$self->print_error(ref($@->detail))) {
                     $self->debug_msg(0, "Resoucepool '" . $self->opts->{edit_resourcepool_name} . "' can't be Edited \n" . $@ . EMPTY);
                 }
            }
            else {
                 $self->debug_msg(0, "Resoucepool '" . $self->opts->{edit_resourcepool_name} . "' can't be Edited \n" . $@ . EMPTY);
            }
            $self->opts->{exitcode} = ERROR;
            return;
        }
    }
}
##BEGIN##
################################
# listSnapshot - Connect, call listSnapshot, and disconnect from ESX server
#
# Arguments:
#   Hash(connection_config,esx_vmname)
#
# Returns:
#   none
#
sub listSnapshot {
    my ($self) = @_;

    print "Listing Snapshots" . "\n";
	if ($::gRunTestUseFakeOutput) {
        # Create and return fake output
        my $out = "";
        #$out .= "Listing Snapshots for VIRTUAL_MACHINE'" . $self->opts->{esx_vmname} . "'...";
        $out .= "\n";
		#$out .= 'Successfully Listed Snapshot for VM\'' . $self->opts->{esx_vmname} . '\' in \'' . $self->opts->{esx_vmname} . '\'';
        return $out;
    }

    #Set default values
    $self->initialize();
    #$self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) {
        return;
    }

    $self->list_snapshot();

    $self->logout();
}
################################
# listSnapshot - Listing snapshots of Vm of  name $opts->{esx_vmname} 
#
# Arguments:
#   Hash(connection_config,esx_vmname)
#
# Returns:
#   none
#
################################
sub list_snapshot {
    my ($self) = @_;

    $self->debug_msg(0, 'Listing Snapshots of VM \'' . $self->opts->{esx_vmname} . '\'...');
	my $view = Vim::find_entity_view(
        view_type => 'VirtualMachine',
        filter => {
            name => $self->opts->{esx_vmname}
        }
    );
    if (!$view) {
        $self->debug_msg(0, 'Virtual Machine\'' . $self->opts->{esx_vmname} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }
    eval {
		my $vm_views = Vim::find_entity_views(
            view_type => 'VirtualMachine',
            filter => {
                name => $self->opts->{esx_vmname}
            }
        );
        if (!$vm_views) {
			$self->debug_msg(0, 'Virtual Machine\'' . $self->opts->{esx_vmname} . '\' not found');
            $self->opts->{exitcode} = ERROR;
            return;
        }
		foreach (@$vm_views) {
            my $count = 0;
            my $snapshots = $_->snapshot;
            if(defined $snapshots) {
                Util::trace(0,"\nSnapshots for Virtual Machine ".$self->opts->{esx_vmname}. "\n");
                my $current_snapshot = $_->snapshot->currentSnapshot();
                my $current_snapshot_view = Vim::get_view(mo_ref => $current_snapshot);
                my $current_snapshot_ref = $current_snapshot_view->{mo_ref}->{value};
                $current_snapshot_ref ||= '';
                print_tree($_->snapshot->currentSnapshot, " " , $_->snapshot->rootSnapshotList, $current_snapshot_ref);
                $self->debug_msg(0, 'Successfully Listed Snapshots for VM \'' . $self->opts->{esx_vmname} . '\'');
            }
            else {
                $self->debug_msg(0, 'NO Snapshots available for VM \'' . $self->opts->{esx_vmname} . '\'');
            }
        }
        if ($@) {
            if (ref($@) eq SOAP_FAULT) {
                $self->debug_msg(0, 'Error listing Snapshots of VM \'' . $self->opts->{esx_vmname} . '\': ');
                if (!$self->print_error(ref($@->detail))) {
                    $self->debug_msg(0, "VM '" . $self->opts->{esx_vmname} . "' can't be listed \n" . $@ . EMPTY);
                }
            }
            else {
                $self->debug_msg(0, "VM '" . $self->opts->{esx_vmname} . "' can't be listed \n" . $@ . EMPTY);
            }
            $self->opts->{exitcode} = ERROR;
            return;
        }
	}
}


sub print_tree {
    my ($ref, $str, $tree, $current_snapshot_ref) = @_;

    $current_snapshot_ref ||= '';
    my $head = " ";
    foreach my $node (@$tree) {
		$head = ($ref->value eq $node->snapshot->value) ? " " : " " if (defined $ref);
		my $quiesced = ($node->quiesced) ? "Y" : "N";
        my $name = $node->name();
        if ($node->snapshot->value() eq $current_snapshot_ref) {
            $name .= " #current";
        }
		printf "%s%-48.48s%16.16s %s %s\n", $head, $str . $name;
		print_tree ($ref, $str . " ", $node->childSnapshotList, $current_snapshot_ref);
    }
    return;
}

################################
# Remove - Connect, call remove_snapshot, and disconnect from ESX server
#
# Arguments:
#   Hash(connection_config,esx_vmname,esx_snapshotname)
#
# Returns:
#   none
#
################################
sub removeSnapshot {
    print "Removing Snapshots";
    my ($self) = @_;

    if ($::gRunTestUseFakeOutput) {

        # Create and return fake output
        my $out = "";
        $out .= "Removing  Snapshots '" . $self->opts->{esx_snapshotname} . "'...";
        $out .= "\n";
        $out .= "Successfully Removed Snapshots '" . $self->opts->{esx_snapshotname} . "'";
        return $out;
    }

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    $self->remove_snapshot();

    $self->logout();
}

################################
# remove_snapshot - Remove the Snapshot  $opts->{esx_snapshotname}
#
# Arguments:
#   Hash(connection_config,esx_vmname,esx_snapshotname)
#
# Returns:
#   none
#
################################
sub remove_snapshot {
    my ($self) = @_;
    my $view = Vim::find_entity_view(view_type => 'VirtualMachine',filter => { 'name' => $self->opts->{esx_vmname} } );
    if (!$view) {
        $self->debug_msg(0, 'Virtual Machine\'' . $self->opts->{esx_vmname} . '\' not found');
        $self->opts->{exitcode} = ERROR;
        return;
    }
	if ($self->opts->{all} eq "1") {
        $self->debug_msg(1, 'Removing Snapshots \'' . $self->opts->{esx_snapshotname} . '\'...');
        my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine',filter => { 'name' => $self->opts->{esx_vmname} } );
        foreach (@$vm_views) {
            my $snapshots = $_->snapshot;
            if(defined $snapshots) {
                eval {
                    $_->RemoveAllSnapshots();
                    Util::trace(0, "\n\nOperation :: Remove All Snapshot For Virtual Machine ". $self->opts->{esx_vmname}. " completed sucessfully\n");
                };
            }
            else {
                $self->debug_msg(0, 'NO Snapshots available for VM \'' . $self->opts->{esx_vmname} . '\'');
            }
        }
        if ($@) {
            if (ref($@) eq SOAP_FAULT) {
                $self->debug_msg(0, 'Error Removing all Snapshots of VM \'' . $self->opts->{esx_vmname} . '\': ');
                if (!$self->print_error(ref($@->detail))) {
                    $self->debug_msg(0, "Snapshots belongs from VM '" . $self->opts->{esx_vmname} . "' can't be removed \n" . $@ . EMPTY);
                }
            }
            else {
                $self->debug_msg(0, "Snapshots belongs from VM '" . $self->opts->{esx_vmname} . "' can't be removed \n" . $@ . EMPTY);
            }
            $self->opts->{exitcode} = ERROR;
            return;
        }
	}
	else {
        my $vm_views = Vim::find_entity_views(
            view_type => VIRTUAL_MACHINE,
            filter    => {
                'name' => $self->opts->{esx_vmname}
            }
        );
        if (!$vm_views) {
            $self->debug_msg(0, 'Virtual machine \'' . $self->opts->{esx_vmname} . '\' not found');
            $self->opts->{exitcode} = ERROR;
            return;
        }
        foreach (@$vm_views) {
            my $ref = undef;
            my $nRefs = 0;
            if(defined $_->snapshot) {
                ($ref, $nRefs) = find_snapshot($_->snapshot->rootSnapshotList, $self->opts->{esx_snapshotname});
            }
            if (defined $ref && $nRefs == 1) {
                my $snapshot = Vim::get_view (mo_ref =>$ref->snapshot);
                eval {
                    $snapshot->RemoveSnapshot(removeChildren => 0);
                    Util::trace(0, "\nOperation :: Remove Snapshot ". $self->opts->{esx_snapshotname} . " For Virtual Machine ".$self->opts->{esx_vmname}." completed sucessfully\n");
                };
            }
            elsif ($nRefs > 1) {
                printf 'Found more than 1 VM snapshot(s) (%s) with provided name (%s)...%s', $nRefs, $self->opts->{esx_vmname}, "\n";
                print "If there are more than one snapshot to remove, please, use All option\n";
                exit 1;
            }
        }
        if ($@) {
            if (ref($@) eq SOAP_FAULT) {
                $self->debug_msg(0, 'Error Removing Snapshot from VM \'' . $self->opts->{esx_vmname} . '\': ');
                if (!$self->print_error(ref($@->detail))) {
                    $self->debug_msg(0, "Snapshot from VM '" . $self->opts->{esx_vmname} . "' can't be removed \n" . $@ . EMPTY);
                }
            }
            else {
                $self->debug_msg(0, "Snapshot from VM '" . $self->opts->{esx_vmname} . "' can't be removed \n" . $@ . EMPTY);
            }
            $self->opts->{exitcode} = ERROR;
            return;
        }
	}
}


sub get_exact_vm {
    my ($self, $vm_path) = @_;

    print "Looking for vm with exact path...\n";
    my $vm_name = $vm_path->{vm_name};
    my $vms = Vim::find_entity_views(
        view_type => VIRTUAL_MACHINE,
        filter => {
            name => $vm_name
        }
    );
    print "Found vms: " . scalar(@$vms) . "\n";
    unless (scalar @$vms) {
        print "No vms found\n";
        return undef;
    }


    my $expected_path = join '/', @{$vm_path->{vm_reverse_path}};
    $expected_path = slash_it($expected_path);
    print "Expected path: " . $expected_path . "\n";
    for my $vm (@$vms) {
        my $folder = $vm->{parent};
        $folder = Vim::get_view(mo_ref => $folder);
        my $folder_paths = build_folders_path($folder, []);
        my $scalar_folder_path = make_folders_path_scalar($folder_paths);
        print "Scalar folder path: " . $scalar_folder_path . "\n";
        if ($scalar_folder_path eq $expected_path) {
            print "Desired VM found...\n";
            return $vm;
        }
    }
    return undef;
}
#########################################
#Arguments:
#    host: host name
#    vm: vm name
#Returns:
#    vm view
##########################################
sub getVirtualMachineView {
    my ($self) = @_;
    print "Getting Virtual Machine View: " . $self->opts->{vm_name} . " and host " . $self->opts->{host_name} . "\n";
    my $vm_path = split_vm_name($self->opts->{vm_name});
    if ($vm_path->{vm_path}) {
        print "Found exact vm path. Working on it..." . "\n";
        my $vm_view = $self->get_exact_vm($vm_path);
        $self->opts->{vm_view} = $vm_view;
        if (!$vm_view) {
            print "ERROR: No vms was found\n";
            exit 1;
        }
        return $vm_view;
    }
    my $hostView = Vim::find_entity_view(
        view_type => HOST_SYSTEM,
        filter    => { 'name' => $self->opts->{host_name} }
    );
    if ($hostView) {
        if (!$self->is_unique_view_name(VIRTUAL_MACHINE, $self->opts->{vm_name})) {
            print "ERROR: There are more than one vm with the same name, please, be more exact";
            exit 1;
        }
        my $vmView = Vim::find_entity_view(
            view_type    => VIRTUAL_MACHINE,
            filter       => { 'name' => $self->opts->{vm_name} },
            begin_entity => $hostView
        );
        if ($vmView) {
            $self->opts->{vm_view} = $vmView;
            return SUCCESS;
        }
    }
    print "Can't find vm view: "
      . $self->opts->{vm_name}
      . " in host: "
      . $self->opts->{host_name} . "\n";

    $self->opts->{exitcode} = ERROR;
    return ERROR;
}


sub is_unique_view_name {
    my ($self, $view_type, $name) = @_;

    my $views;
    eval {
        $views = Vim::find_entity_views(
            view_type => $view_type,
            filter => {'name' => $name},
            # properties => ['name']
        );
        1;
    };
    if (!$views) {
        return 1;
    }
    if (scalar @$views <= 1) {
        return 1;
    }
    return 0;
}

sub fetchDevices {
    my ($self) = @_;
    my @devices;
    my $input;
    my $matcher;
    print "Going for finding " . $self->opts->{device_type} . "\n";
    foreach my $device ( @{ $self->opts->{vm_view}->config->hardware->device } ) {
        $input = $device->deviceInfo->label;
        $matcher = $self->opts->{device_type};
        if ( $input =~ /$matcher/ ) {
            push @devices, $device;
        }
    }
    if(not @devices)
    {
        $self->opts->{exitcode} = ERROR;
        print "Could not obtain device of type: " . $self->opts->{device_type} . "\n";
        return ERROR;
    }
    print "Obtained device of type: " . $self->opts->{device_type} . "\n";
    #Store array Reference
    $self->opts->{devices} = \@devices;
    return SUCCESS;
}

sub listDevices {
    my ($self) = @_;
    print "Going for listing "
      . $self->opts->{device_type} . ": "
      . $self->opts->{device_name}
      . " present on VM: "
      . $self->opts->{vm_name}
      . " and host: "
      . $self->opts->{host_name} . "\n";

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if($self->getVirtualMachineView()){
        print "Can't find Virtual Machine view" . "\n";
        return;
    }
    if ($self->fetchDevices()){
        print "Can't fetch devices" . "\n";
        return;
    }

    print
      "======================================================================"
      . "\n";

    foreach my $device (@{$self->opts->{devices}}){
        #If deviceName is given then list only that one and if not given list all devices of that type

        my %deviceMap = %{$device};
        if ( ( not $self->opts->{device_name} )
            or $deviceMap{deviceInfo}{label} eq $self->opts->{device_name} )
        {
            print "Device Name: " . $device->deviceInfo->label . "\n";
            print "Device Info: ";
            print exists $deviceMap{backing}{fileName}
              ? $deviceMap{backing}{fileName}
              : $deviceMap{backing}{deviceName};
            print "\n";
            print "Backing: "
              . substr( ref( $deviceMap{backing} ), 0, -4 ) . "\n";
            if ( exists $deviceMap{capacityInKB} ) {
                print "Capacity In KB: " . $deviceMap{capacityInKB} . "\n";
            }
            if ( exists $deviceMap{backing}{thinProvisioned} ) {

                my $thinProvisioned =
                  $deviceMap{backing}{thinProvisioned} ? "True" : "False";
                print "Thin Provisioned: " . $thinProvisioned . "\n";
            }
            if ( exists $deviceMap{backing}{diskMode} ) {
                print "Disk Mode: " . $deviceMap{backing}{diskMode} . "\n";
            }
            if ( exists $deviceMap{macAddress} ) {
                print "MAC Address: " . $deviceMap{macAddress} . "\n";
            }
            print
              "======================================================================"
              . "\n";
        }
    }
    $self->logout();
}

#https://www.vmware.com/pdf/vsphere6/r60/vsphere-60-configuration-maximums.pdf
sub fetchController {
    my ($self) = @_;
    my $deviceLimit;
    if ( $self->opts->{controller_type} eq 'SCSI' ) {
        $deviceLimit = 15;
    }
    elsif ( $self->opts->{controller_type} eq 'SATA' ) {
        $deviceLimit = 30;
    }
    elsif ( $self->opts->{controller_type} eq 'IDE' ) {
        $deviceLimit = 2;
    }
    if ($self->fetchDevices()){
        print "Can't fetch devices" . "\n";
        $self->opts->{exitcode} = ERROR;
        return ERROR;
    }
    foreach my $device (@{$self->opts->{devices}}){
        my %deviceMap = %{$device};
        if (   ( not exists $deviceMap{device} )
            or ( @{ $deviceMap{device} } < $deviceLimit ) )
        {
            print "Controller "
              . $deviceMap{deviceInfo}{label}
              . " is free" . "\n";
            $self->opts->{controller} = $device;
            return SUCCESS;
        }
        else {
            print "Controller "
              . $deviceMap{deviceInfo}{label}
              . " is not free" . "\n";
        }
    }
    $self->opts->{exitcode} = ERROR;
    return ERROR;
}

sub getNetworkInterfaceConfig {
    my %args = @_;
    my $backingInfo =
      VirtualEthernetCardNetworkBackingInfo->new(
        deviceName => $args{network} );
    return VirtualPCNet32->new(
        key     => -1,
        backing => $backingInfo
    );
}

#########################################
#Arguments:
#    controller: Controller Map
#    backingType: Passthrough, AtApi, ISOImage
#########################################
sub getCdDvdBackingInfo {
    my %args = @_;
    my $backingInfo;
    print "Going for obtaining backing info for backing type: " . $args{backingType} . "\n";
    if ( $args{backingType} eq "passThrough" ) {
        $backingInfo = VirtualCdromRemotePassthroughBackingInfo->new(
            deviceName => $args{deviceName},
            exclusive  => "FALSE"
        );
    }
    elsif ( $args{backingType} eq "atApi" ) {
        $backingInfo =
          VirtualCdromRemoteAtapiBackingInfo->new(
            deviceName => $args{deviceName} );
    }
    elsif ( $args{backingType} eq "isoImage" ) {
        $backingInfo =
          VirtualCdromIsoBackingInfo->new( fileName => $args{isoPath} );
    }
    return $backingInfo;
}

sub deviceManager {
    my %args       = @_;
    eval{
        my @deviceSpec;
        my $vmSpec;
        if($args{fileOperation}){
            @deviceSpec = VirtualDeviceConfigSpec->new(
                operation => $args{operation},
                device    => $args{deviceConfig},
                fileOperation    => $args{fileOperation}
            );
        }
        elsif($args{deviceConfig}){
            @deviceSpec = VirtualDeviceConfigSpec->new(
                operation => $args{operation},
                device    => $args{deviceConfig}
            );
        }
        else{
            print "Device configurations not required." . "\n";
        } 

        if($args{memoryMB} && $args{numCPUs}) {
           print "Change CPU and Memory-Added in reconfiguring VM" . "\n";
           $vmSpec = VirtualMachineConfigSpec->new(numCPUs => $args{numCPUs},
                                                   memoryMB=>$args{memoryMB});
        }
        elsif($args{memoryMB}) {
           print "Changing Memory-Added in reconfiguring VM" . "\n";
           $vmSpec = VirtualMachineConfigSpec->new(memoryMB=>$args{memoryMB});
        }
        elsif($args{numCPUs}) {
           print "Change CPU-Added in reconfiguring VM" . "\n";
           $vmSpec = VirtualMachineConfigSpec->new(numCPUs => $args{numCPUs});
        }
        elsif(@deviceSpec) {
           print "Add/edit device-Added in reconfiguring VM" . "\n";
           $vmSpec = VirtualMachineConfigSpec->new(deviceChange => \@deviceSpec);
        }
        else {
           Util::trace(0,"\nNo reconfiguration performed as there "
                       . "is no device config spec created.\n");
           return;
        }
        $args{vmView}->ReconfigVM( spec => $vmSpec );
    };
    if ($@) {
      if (ref($@) eq 'SoapFault') {
         if (ref($@->detail) eq 'FileAlreadyExists') {
            Util::trace(0,"Operation failed because file already exists.");
         }
         elsif (ref($@->detail) eq 'InvalidName') {
            Util::trace(0,"If the specified name is invalid.");
         }
         elsif (ref($@->detail) eq 'InvalidDeviceBacking') {
            Util::trace(0,"Incompatible device backing specified for device.");
         }
         elsif (ref($@->detail) eq 'InvalidDeviceSpec') {
            Util::trace(0,"Invalid backing info spec.");
         }
         elsif (ref($@->detail) eq 'InvalidPowerState') {
            Util::trace(0,"Attempted operation cannot be performed on the current state.");
         }
         elsif (ref($@->detail) eq 'GenericVmConfigFault') {
            Util::trace(0,"Unable to configure virtual device.");
         }
         elsif (ref($@->detail) eq 'NoDiskSpace') {
            Util::trace(0,"Insufficient disk space on datastore.");
         }
         else {
            Util::trace(0,"Fault : " . $@);
         }
      }
      else {
         Util::trace(0,"Fault : " . $@);
      }
   }
}

sub addNetworkInterface {
    my ($self) = @_;
    print "Going for adding Network Interface in network "
      . $self->opts->{network}
      . " to VM: "
      . $self->opts->{vm_name}
      . " present on host: "
      . $self->opts->{host_name} . "\n";

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }


    my $operation = VirtualDeviceConfigSpecOperation->new('add');
    if ($operation) {
        if($self->getVirtualMachineView()){
            print "Can't find Virtual Machine view" . "\n";
            return;
        }
        print
          "Got vm view. Going for fetching network interface configurations"
          . "\n";
        my $networkInterfaceConfig =
          getNetworkInterfaceConfig( network => $self->opts->{network} );
        if ($networkInterfaceConfig) {
            print
"Got network interface configurations. Going for applying configurations to VM"
              . "\n";
            deviceManager(
                deviceConfig => $networkInterfaceConfig,
                operation    => $operation,
                vmView       => $self->opts->{vm_view}
            );
            print "Successfully added network interface to VM: "
              . $self->opts->{vm_name} . "\n";

            $self->logout();
            return;
        }
    }
    print "Not able to add network interface to VM: "
      . $self->opts->{vm_name} . "\n";
    $self->opts->{exitcode} = ERROR;
    $self->logout();
    return;
}

sub addOrEditCdDvdDrive {
    my ($self) = @_;
    print "Going for adding/editing CD/DVD Drive: "
      . " [Backing Type: "
      . $self->opts->{backing_type}
      . ", Controller Type: "
      . $self->opts->{controller_type}
      . "] to VM: "
      . $self->opts->{vm_name}
      . " present on host: "
      . $self->opts->{host_name} . "\n";

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    if($self->opts->{backing_type} eq "isoImage"){
        if(not $self->opts->{iso_image}){
            print "ISO Image Path can't ber empty for IsoImage backing type" . "\n";
            $self->opts->{exitcode} = ERROR;
            return;
        }
    }
    $self->login();
    if ($self->opts->{exitcode}) { return; }
    my $operation;
    my $cdConfig;
    my $oldCdConfig;
    my $deviceName;

    if($self->getVirtualMachineView()){
        print "Can't find Virtual Machine view" . "\n";
        return;
    }
    if($self->opts->{edit}){
        print "Going for editing already existing CD/DVD: " . $self->opts->{device_name} . "\n";
        $operation = VirtualDeviceConfigSpecOperation->new('edit');
        $self->opts->{device_type} = 'CD/DVD drive';
        if ($self->fetchDevices()){
            print "Can't fetch devices" . "\n";
            return;
        }
        foreach my $device (@{$self->opts->{devices}}){
            if ( $device->deviceInfo->label eq $self->opts->{device_name} )
            {
                print "Device found. Populating context for " . $self->opts->{device_name} . "\n";
                $oldCdConfig = $device;
            }
        }
        if(not $oldCdConfig){
            $self->opts->{exitcode} = ERROR;
            print "Could not obtain CD/DVD drive config for " . $self->opts->{device_name} . "\n";
            return ERROR;
        }
        $deviceName = $self->opts->{device_name};
    }
    else{
        print "Going for adding new device" . "\n";
        $operation = VirtualDeviceConfigSpecOperation->new('add');
        $deviceName = $self->opts->{vm_name} . "_" . time();
    }

    my $controllerKey;

    if($self->opts->{controller_type}){
        #For finding controller device
        $self->opts->{device_type} = $self->opts->{controller_type};
        if($self->fetchController()){
            print "Can't find controller" . "\n";
            return;
        }
        $controllerKey = $self->opts->{controller}->key;
    }
    else{
        $controllerKey = $oldCdConfig->controllerKey;
    }

    my $backingInfo;
    if($self->opts->{backing_type}){
        $backingInfo = getCdDvdBackingInfo(
            deviceName  => $deviceName,
            backingType => $self->opts->{backing_type},
            isoPath     => $self->opts->{iso_image}
        );
    }
    else{
        $backingInfo = $oldCdConfig->backing;
    }

    if($self->opts->{edit}){
        $cdConfig = $oldCdConfig;
        $cdConfig->backing($backingInfo);
        $cdConfig->controllerKey($controllerKey);
    }
    else{
        $cdConfig = VirtualCdrom->new(
            controllerKey => $controllerKey,
            key           => -1,
            deviceInfo =>
              Description->new( label => $deviceName, summary => '111' ),
            backing => $backingInfo
        );
    }
    if ($cdConfig) {
        print
"Got cd/dvd drive configurations. Going for applying configurations to VM"
          . "\n";
        deviceManager(
            deviceConfig => $cdConfig,
            operation    => $operation,
            vmView       => $self->opts->{vm_view}
        );
        print "Successfully added/edited CD/DVD Drive to VM: "
          . $self->opts->{vm_name} . "\n";
        $self->logout();
        return;
    }

    print "Not able to add CD/DVD ROM to VM: "
      . $self->opts->{vm_name} . "\n";
    $self->opts->{exitcode} = ERROR;
    $self->logout();
    return;
}

sub changeCpuMemAllocation {
    my ($self) = @_;
    print "Going for changing CPU to: "
      . $self->opts->{num_cpu}
      . " and Memory to: "
      . $self->opts->{memory_mb}
      . " for VM: "
      . $self->opts->{vm_name}
      . " present on host: "
      . $self->opts->{host_name} . "\n";

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if($self->getVirtualMachineView()){
        print "Can't find Virtual Machine view" . "\n";
        return;
    }

    deviceManager(
        numCPUs => $self->opts->{num_cpu},
        memoryMB => $self->opts->{memory_mb},
        vmView => $self->opts->{vm_view}
    );

    print "Successfully changed CPU/Mem Shares for VM: "
      . $self->opts->{vm_name} . "\n";
    $self->logout();
    return;
}

sub removeDevice {
    my ($self) = @_;
    print "Going for removing device: "
      . $self->opts->{device_type}
      . " from VM: "
      . $self->opts->{vm_name}
      . " present on host: "
      . $self->opts->{host_name} . "\n";

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    #Login with VMWare service
    $self->login();
    if ($self->opts->{exitcode}) { return; }

    my $operationRemove = VirtualDeviceConfigSpecOperation->new('remove');

    if ($operationRemove) {
        if($self->getVirtualMachineView()){
            print "Can't find Virtual Machine view" . "\n";
            return;
        }
        print "Got vm view. Going for fetching device configurations"
          . "\n";

        if ($self->fetchDevices()){
            print "Can't fetch devices" . "\n";
            return;
        }
        foreach my $deviceConfig (@{$self->opts->{devices}}){
            if ( ( not $self->opts->{device_name} )
                or $deviceConfig->deviceInfo->label eq $self->opts->{device_name} )
            {
                deviceManager(
                    deviceConfig => $deviceConfig,
                    operation    => $operationRemove,
                    vmView       => $self->opts->{vm_view}
                );
                print "Successfully removed device: "
                  . $deviceConfig->deviceInfo->label
                  . " from VM: "
                  . $self->opts->{vm_name} . "\n";
            }
        }
        $self->logout();
        return;
    }
    print "Not able to remove device: "
      . $self->opts->{device_type}
      . " from VM: "
      . $self->opts->{vm_name} . "\n";
    $self->opts->{exitcode} = ERROR;
    $self->logout();
    return;
}

sub addHardDisk {
    my ($self) = @_;
    print "Going for adding Hard Disk : "
      . ", Controller Type: "
      . $self->opts->{controller_type}
      . "] to VM: "
      . $self->opts->{vm_name}
      . " present on host: "
      . $self->opts->{host_name} . "\n";

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    $self->login();
    if ($self->opts->{exitcode}) { return; }

    my $operation = VirtualDeviceConfigSpecOperation->new('add');
    if ($operation) {

        if($self->getVirtualMachineView()){
            print "Can't find Virtual Machine view" . "\n";
            return;
        }

        print "Got vm view. Going for fetching controller configurations"
          . "\n";
        $self->opts->{device_type} = $self->opts->{controller_type};
        if($self->fetchController()){
            print "Can't find controller" . "\n";
            return;
        }
    my $controllerKey = $self->opts->{controller}->key;
    # Set new unit number (7 cannot be used, and limit is 15)
    my $unitNumber;
    my 	$vm_vdisk_number = $self->opts->{controller}->unitNumber + 1;
    if ($vm_vdisk_number < 7) {
        $unitNumber = $vm_vdisk_number;
    }
    elsif ($vm_vdisk_number == 15) {
        die "ERR: one SCSI controller cannot have more than 15 virtual disks\n";
    }
    else {
        $unitNumber = $vm_vdisk_number + 1;
    }
    my $size =$self->opts->{esx_hdsize} * 1024;
    my $diskMode;
    my $source_fileName =$self->opts->{vm_name}."_" . time() . ".vmdk";
    my $fileName = generateFilename(vm_view => $self->opts->{vm_view}, vm_name => $self->opts->{vm_name}, filename => $source_fileName);
    Util::trace(0,"\nAdding new hard disk with file name $fileName . . .");
    my $hdConfig ;
    $hdConfig = getVdiskConfig(backingtype => 'regular',
                             diskMode =>$self->opts->{esx_hd_storagemode},
                             fileName => $fileName,
                             controllerKey => $controllerKey,
                             unitNumber => $unitNumber,
                             size => $size,
    diskProvision =>$self->opts->{esx_hd_provisioning});
    deviceManager(
        deviceConfig => $hdConfig,
        operation    => $operation,
        fileOperation => VirtualDeviceConfigSpecFileOperation->new('create'),
        vmView       => $self->opts->{vm_view}
    );

    print "Successfully added Hard drive to VM: "
      . $self->opts->{vm_name} . "\n";
    $self->logout();
    return;
    }

    print "Not able to add Hard Disk to VM: "
      . $self->opts->{vm_name} . "\n";
    $self->opts->{exitcode} = ERROR;
        $self->logout();
        return;
}
sub revertToCurrentSnapshot {
    my ($self) = @_;
    print "Going for reverting to current snapshot for VM: "
      . $self->opts->{vm_name}
      . " present on host: "
      . $self->opts->{host_name} . "\n";

    #Set default values
    $self->initialize();
    $self->debug_msg(0, '---------------------------------------------------------------------');

    $self->login();
    if ($self->opts->{exitcode}) { return; }

    if($self->getVirtualMachineView()){
        print "Can't find Virtual Machine view" . "\n";
        return;
    }
    print "Got vm view."
      . "\n";

     my $hostname = Vim::get_view(mo_ref => $self->opts->{vm_view}->runtime->host)->name;
   
     eval {
        $self->opts->{vm_view}->RevertToCurrentSnapshot();
        Util::trace(0, "\nOperation :: Revert To Current Snapshot For Virtual "
                         . "Machine " . $self->opts->{vm_view}->name
                         ." completed sucessfully under host ". $hostname
                         . "\n");
     };
     if ($@) {
        if (ref($@) eq 'SoapFault') {
           if(ref($@->detail) eq 'InvalidState') {
              Util::trace(0,"\nOperation cannot be performed in the current state
                             of the virtual machine");
           }
           elsif(ref($@->detail) eq 'NotSupported') {
              Util::trace(0,"\nHost product does not support snapshots.");
           }
           elsif(ref($@->detail) eq 'InvalidPowerState') {
              Util::trace(0,"\nOperation cannot be performed in the current power state
                            of the virtual machine.");
           }
           elsif(ref($@->detail) eq 'InsufficientResourcesFault') {
              Util::trace(0,"\nOperation would violate a resource usage policy.");
           }
           elsif(ref($@->detail) eq 'HostNotConnected') {
              Util::trace(0,"\nHost not connected.");
           }
           elsif(ref($@->detail) eq 'NotFound') {
              Util::trace(0,"\nVirtual machine does not have a current snapshot");
           }
           else {
              Util::trace(0, "\nFault: " . $@ . "\n\n");
           }
        }
        else {
           Util::trace(0, "\nFault: " . $@ . "\n\n");
        }
     }
    $self->logout();
    return;
}

sub generateFilename {
   my %args = @_;
   my $path = $args{vm_view}->config->files->vmPathName;
   my $name = $args{vm_name} . "/" . $args{filename};

   $path =~ /^(\[.*\])/;
   my $fileName = "$1/$name";
   $fileName .= ".vmdk" unless ($fileName =~ /\.vmdk$/);
   return $fileName;
}

sub getVdiskConfig {
   my %args = @_;
   print "Creating Virtual Hard Disk. DiskMode: " . $args{diskMode} . " , FileName: " . $args{fileName} . " , ControllerKey: " . $args{controllerKey} . " , UnitNumber: " . $args{unitNumber} . ", Size: " . $args{size} . ", BackingType: " . $args{backingtype} . " , DiskProvision: " . $args{diskProvision} . "\n";
   my $backingInfo;
   if($args{backingtype} eq "regular") {
       if($args{diskProvision} eq "thin")
       {
           print"\n Enter into provision class having disk_provision" . $args{diskProvision} . "\n";
           my $thinProvisioned="true";
           $backingInfo = VirtualDiskFlatVer2BackingInfo->new(diskMode => $args{diskMode},
                                                                   fileName => $args{fileName},
                                                                   thinProvisioned=>$thinProvisioned);
       }
       else
       {
           $backingInfo = VirtualDiskFlatVer2BackingInfo->new(diskMode => $args{diskMode},
                                                                    fileName => $args{fileName});
       }
   }
   my $diskConfig = VirtualDisk->new(controllerKey => $args{controllerKey},
                               unitNumber => $args{unitNumber},
                               key => -1,
                               backing => $backingInfo,
                               capacityInKB => $args{size});
   return $diskConfig;
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

    my $controller = VirtualLsiLogicController->new(
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
sub find_snapshot {
   my ($tree, $name) = @_;
   my $ref = undef;
   my $count = 0;
   foreach my $node (@$tree) {
      if ($node->name eq $name) {
         $ref = $node;
         $count++;
      }
      my ($subRef, $subCount) = find_snapshot($node->childSnapshotList, $name);
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

use constant STORAGE_MULTIPLIER => 1073741824;  # 1024*1024*1024 (to convert to GB)

###############################
# display_esx_general_info 
#
# Arguments: host_view
#
# Returns:
#   none
#
################################
sub display_esx_general_info {
    my ($self) = @_;
    my $host = $self->{'host'};
    $self->logger(0, "-----------------------------------------GENERAL INFORMATION----------------------------------------");
    $self->logger(0, "Host Name               : " . $host->summary->config->name);
    $self->logger(0, "Host Vendor             : " . $host->summary->hardware->vendor);
    $self->logger(0, "Boot Time               : " . $host->runtime->bootTime);
    $self->logger(0, "CPU Speed               : " . $host->summary->hardware->cpuMhz . " MHz");
    $self->logger(0, "CPU-Model               : " . $host->summary->hardware->cpuModel);
    $self->logger(0, "Model                   : " . $host->summary->hardware->model);
    my $totalMemory = $host->summary->hardware->memorySize/STORAGE_MULTIPLIER;
    $self->logger(0, "Total Memory            : " . $totalMemory . " GB");
    $self->logger(0, "Number of CPU Cores     : " . $host->summary->hardware->numCpuCores);
    $self->logger(0, "Number of CPU Pkgs      : " . $host->summary->hardware->numCpuPkgs);
    $self->logger(0, "Number of CPU Threads   : " . $host->summary->hardware->numCpuThreads);
    $self->logger(0, "HyperThreading Available: " . ($host->config->hyperThread->available ? "YES" : "NO"));
    $self->logger(0, "HyperThreading Active   : " . ($host->config->hyperThread->active ? "YES" : "NO"));
    if (defined ($host->summary->config->product)) {
        $self->logger(0, "Product Name            : " . ${$host->summary->config->product}{'name'});
        $self->logger(0, "Software On Host        : " . ${$host->summary->config->product}{'fullName'});
        $self->logger(0, "Product Vendor          : " . ${$host->summary->config->product}{'vendor'});
        $self->logger(0, "Product Version         : " . ${$host->summary->config->product}{'version'});
    }

    $self->logger(0, "vMotion Enabled         : " . ($host->summary->config->vmotionEnabled ? "YES" : "NO"));
    $self->logger(0, "Number of NICs          : " . $host->summary->hardware->numNics);
    $self->logger(0, "Number of HBAs          : " . $host->summary->hardware->numHBAs);
    $self->logger(0, "UUID                    : " . $host->summary->hardware->uuid);
    $self->logger(0, "-----------------------------------------------------------------------------------------------------");
}

###############################
# display_esx_resource_info 
#
# Arguments: host_view
#
# Returns:
#   none
#
################################
sub display_esx_resource_info {
    my ($self) = @_;
    my $host = $self->{'host'};
    $self->logger(0, "-----------------------------------------RESOURCE INFORMATION----------------------------------------");
    $self->logger(0, "Overall CPU Usage       : " . $host->summary->quickStats->overallCpuUsage . " MHz");
    $self->logger(0, "Overall Memory Usage    : " . $host->summary->quickStats->overallMemoryUsage . "MB");
    $self->logger(0, "-----------------------------------------------------------------------------------------------------");
}

###############################
# display_esx_network_info 
#
# Arguments: host_view
#
# Returns:
#   none
#
################################
sub display_esx_network_info {
    my ($self) = @_;
    my $host = $self->{'host'};
    print "-----------------------------------------NETWORK INFORMATION-----------------------------------------\n";
    ## GATEWAY ##
    my $network_system;
    eval { $network_system = Vim::get_view(mo_ref => $host->configManager->networkSystem); };
    if ($network_system->ipRouteConfig->defaultGateway) {
        $self->logger(0, "IP Default Gateway : " . $network_system->ipRouteConfig->defaultGateway);
    }

    ## DNS ##
    my $dns_add = $host->config->network->dnsConfig->address;

    $self->logger(0,  "    DNS Address : ");
    foreach(@$dns_add) {
        $self->logger(0, "        " . $_);
    }

    $self->logger(0, "    NIC Details : ");
    my $nics = $host->config->network->pnic;
    foreach my $nic (@$nics) {
        $self->logger(0,  "        NIC Device :" . $nic->device);
        $self->logger(0,  "            NIC PCI                       :" . $nic->pci);
        $self->logger(0,  "            NIC Driver                    :" . $nic->driver);
        if ($nic->linkSpeed) {
            $self->logger(0, "            NIC Mode of Channel Operation :" . ($nic->linkSpeed->duplex ?  "FULL-DUPLEX" : "HALF-DUPLEX"));
            $self->logger(0, "            NIC Link Speed Mb             :" . $nic->linkSpeed->speedMb);
        }
        $self->logger(0, "            NIC Wake On Lan Supported     :" . $nic->wakeOnLanSupported);
    }
    $self->logger(0, "-----------------------------------------------------------------------------------------------------");
}

###############################
# display_esx_storage_info 
#
# Arguments: host_view
#
# Returns:
#   none
#
################################
sub display_esx_storage_info {
    my ($self) = @_;
    my $host = $self->{'host'};
    $self->logger(0, "-----------------------------------------STORAGE INFORMATION-----------------------------------------");
    $self->logger(0, "------------------------DATASTORE------------------------");
    my $ds_views = Vim::get_views (mo_ref_array => $host->datastore);
    foreach my $ds (@$ds_views) {
        my $ds_row = "";
        if($ds->summary->accessible) {
            #capture unique datastores seen in cluster
            $self->logger(0, "Datastore Name             : " . $ds->info->name);
            $self->logger(0, "    Datastore Accessible       : " . ($ds->summary->accessible ? "YES" : "NO"));
            $self->logger(0, "    Datastore URL              : " . $ds->info->url);
            $self->logger(0, "    Datastore Type             : " . $ds->summary->type);
            if ( ($ds->summary->freeSpace gt 0) || ($ds->summary->capacity gt 0) ) {
                my $capacity = $ds->summary->capacity/STORAGE_MULTIPLIER;
                my $free_space = $ds->summary->freeSpace/STORAGE_MULTIPLIER;
                my $used_space = $capacity - $free_space;
                my $percent_used_space = ($used_space/$capacity)*100;
                $self->logger(0, "    Datastore Capacity         : " . $capacity . " GB");
                $self->logger(0, "    Datastore FreeSpace        : " . $free_space . " GB");
                $self->logger(0, "    Datastore UsedSpace        : " . $used_space . " GB");
                $self->logger(0, "    Datastore PercentUsedSpace : " . $percent_used_space . " %");
            }
        }
    }

    $self->logger(0, "------------------------LUN------------------------");
    my $luns = $host->config->storageDevice->scsiLun;
    foreach my $lun (@$luns) {
                my $lun_row = "";
                if($lun->isa('HostScsiDisk')) {
                    $self->logger(0, "LUN UID               : " . $lun->uuid);
                    $self->logger(0, "LUN Canonical Name    : " . $lun->canonicalName);
                    $self->logger(0, "LUN Queue Depth       : " . $lun->queueDepth);
                    my $states = $lun->operationalState;
                    print "LUN Operational State : ";
                    foreach (@$states) {
                        $self->logger(0, $_);
                    }
                }
    }
    $self->logger(0, "-----------------------------------------------------------------------------------------------------");
}

sub make_folders_path_scalar {
    my ($map) = @_;
    pop @$map;
    my $path = join '/', map {$_ = $_->{name}} @$map;
    $path = slash_it($path);
    return $path;
}

sub slash_it {
    my ($string) = @_;

    if ($string !~ m/^\//s) {
        $string = '/' . $string;
    }
    if ($string !~ m/\/$/s) {
        $string .= '/';
    }
    return $string
}

sub build_folders_path {
    my ($folder_view, $acc) = @_;
    push @$acc, {name => $folder_view->{name}, mo_ref => $folder_view->{mo_ref}};
    my $parent = $folder_view->{parent};
    if (!$parent || $parent->{type} ne 'Folder') {
        return $acc;
    }
    else {
        my $t = Vim::get_view(mo_ref => $parent);
        build_folders_path($t, $acc);
    }
}

sub split_vm_name {
    my $name = shift;

    my @path = grep {$_} split /\//, $name;
    my $retval = {
        vm_name => pop @path,
        vm_path => '',
        vm_reverse_path => '',
    };

    if (scalar @path > 1) {
        my @reverse_path = reverse @path;
        $retval->{vm_path} = \@path;
        $retval->{vm_reverse_path} = \@reverse_path;
    }

    return $retval;
}

sub in_array {
    my ($what, @where) = @_;

    for my $e (@where) {
        return 1 if $what eq $e;
    }
    return 0;
}
