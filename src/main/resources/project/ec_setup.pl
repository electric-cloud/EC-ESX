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

my %suspend = (
			   label       => "ESX - Suspend Virtual Machine",
			   procedure   => "Suspend",
			   description => "Suspend a virtual machine",
			   category    => "Resource Management"
			  );

my %cleanup = (
			   label       => "ESX - Cleanup Virtual Machine",
			   procedure   => "Cleanup",
			   description => "Cleanup a virtual machine",
			   category    => "Resource Management"
			  );

my %clone = (
			 label       => "ESX - Clone Virtual Machine",
			 procedure   => "Clone",
			 description => "Clone a virtual machine",
			 category    => "Resource Management"
			);

my %create = (
			  label       => "ESX - Create Virtual Machine",
			  procedure   => "Create",
			  description => "Create a virtual machine",
			  category    => "Resource Management"
			 );

my %createresourcefromvm = (
							label       => "ESX - Create Resource From Virtual Machine",
							procedure   => "CreateResourceFromVM",
							description => "Store information about a virtual machine and create ElectricCommander resources",
							category    => "Resource Management"
						   );

my %import = (
			  label       => "ESX - Import",
			  procedure   => "Import",
			  description => "Import an OVF package to the ESX server",
			  category    => "Resource Management"
			 );

my %getvmconfiguration = (
						  label       => "ESX - Get Virtual Machine Configuration",
						  procedure   => "GetVMConfiguration",
						  description => "Get virtual machine information and store it in properties",
						  category    => "Resource Management"
						 );

my %export = (
			  label       => "ESX - Export",
			  procedure   => "Export",
			  description => "Export a virtual machine to an OVF package using ovftool",
			  category    => "Resource Management"
			 );

my %relocate = (
				label       => "ESX - Relocate Virtual Machine",
				procedure   => "Relocate",
				description => "Relocate a virtual machine",
				category    => "Resource Management"
			   );

my %registervm = (
				  label       => "ESX - Register Virtual Machine",
				  procedure   => "RegisterVM",
				  description => "Register an existing virtual machine",
				  category    => "Resource Management"
				 );

my %poweroff = (
				label       => "ESX - Power Off Virtual Machine",
				procedure   => "PowerOff",
				description => "Power off a virtual machine",
				category    => "Resource Management"
			   );

my %poweron = (
			   label       => "ESX - Power On Virtual Machine",
			   procedure   => "PowerOn",
			   description => "Power on a virtual machine",
			   category    => "Resource Management"
			  );

my %revert = (
			  label       => "ESX - Revert",
			  procedure   => "Revert",
			  description => "Revert the configuration to the last snapshot",
			  category    => "Resource Management"
			 );

my %shutdown = (
				label       => "ESX - Shutdown Virtual Machine",
				procedure   => "Shutdown",
				description => "Shutdown a virtual machine",
				category    => "Resource Management"
			   );

my %snapshot = (
				label       => "ESX - Snapshot",
				procedure   => "Snapshot",
				description => "Create a snapshot for the specified virtual machine",
				category    => "Resource Management"
			   );
			   
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - Suspend");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - Clone");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - Cleanup");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - Create");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - CreateResourceFromVM");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - GetVMConfiguration");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - Import");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - Export");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - Relocate");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - RegisterVM");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - PowerOff");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - PowerOn");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - Revert");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - Shutdown");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - Snapshot");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - CloudManagerShrink");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/EC-ESX - CloudManagerGrow");

$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Suspend Virtual Machine");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Suspend");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Clone Virtual Machine");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Cleanup Virtual Machine");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Create Virtual Machine");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Create Resource From Virtual Machine");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Import");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Get Virtual Machine Configuration");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Export");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Relocate Virtual Machine");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Register Virtual Machine");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Power Off Virtual Machine");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Power On Virtual Machine");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Revert");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Shutdown Virtual Machine");
$batch->deleteProperty("/server/ec_customEditors/pickerStep/ESX - Snapshot");

@::createStepPickerSteps = (\%suspend, \%cleanup, \%clone, \%create, \%createresourcefromvm, \%import, \%getvmconfiguration, \%export, \%relocate, \%registervm, \%poweroff, \%poweron, \%revert, \%shutdown, \%snapshot);

my $pluginName = "@PLUGIN_NAME@";
my $pluginKey = "@PLUGIN_KEY@";
if ($promoteAction ne '') {
    my @objTypes = ('projects', 'resources', 'workspaces');
    my $query    = $commander->newBatch();
    my @reqs     = map { $query->getAclEntry('user', "project: $pluginName", { systemObjectName => $_ }) } @objTypes;
    push @reqs, $query->getProperty('/server/ec_hooks/promote');
    $query->submit();

    foreach my $type (@objTypes) {
        if ($query->findvalue(shift @reqs, 'code') ne 'NoSuchAclEntry') {
            $batch->deleteAclEntry('user', "project: $pluginName", { systemObjectName => $type });
        }
    }

    if ($promoteAction eq "promote") {
        foreach my $type (@objTypes) {
            $batch->createAclEntry(
                                   'user',
                                   "project: $pluginName",
                                   {
                                      systemObjectName           => $type,
                                      readPrivilege              => 'allow',
                                      modifyPrivilege            => 'allow',
                                      executePrivilege           => 'allow',
                                      changePermissionsPrivilege => 'allow'
                                   }
                                  );
        }
    }
}

if ($upgradeAction eq "upgrade") {
    my $query   = $commander->newBatch();
    my $newcfg  = $query->getProperty("/plugins/$pluginName/project/esx_cfgs");
    my $oldcfgs = $query->getProperty("/plugins/$otherPluginName/project/esx_cfgs");
    my $creds   = $query->getCredentials("\$[/plugins/$otherPluginName]");

    local $self->{abortOnError} = 0;
    $query->submit();

    # if new plugin does not already have cfgs
    if ($query->findvalue($newcfg, "code") eq "NoSuchProperty") {

        # if old cfg has some cfgs to copy
        if ($query->findvalue($oldcfgs, "code") ne "NoSuchProperty") {
            $batch->clone(
                          {
                            path      => "/plugins/$otherPluginName/project/esx_cfgs",
                            cloneName => "/plugins/$pluginName/project/esx_cfgs"
                          }
                         );
        }
    }

    # Copy configuration credentials and attach them to the appropriate steps
    my $nodes = $query->find($creds);
    if ($nodes) {
        my @nodes = $nodes->findnodes("credential/credentialName");
        for (@nodes) {
            my $cred = $_->string_value;

            # Clone the credential
            $batch->clone(
                          {
                            path      => "/plugins/$otherPluginName/project/credentials/$cred",
                            cloneName => "/plugins/$pluginName/project/credentials/$cred"
                          }
                         );

            # Make sure the credential has an ACL entry for the new project principal
            my $xpath = $commander->getAclEntry(
                                                "user",
                                                "project: $pluginName",
                                                {
                                                   projectName    => $otherPluginName,
                                                   credentialName => $cred
                                                }
                                               );
            if ($xpath->findvalue("//code") eq "NoSuchAclEntry") {
                $batch->deleteAclEntry(
                                       "user",
                                       "project: $otherPluginName",
                                       {
                                          projectName    => $pluginName,
                                          credentialName => $cred
                                       }
                                      );
                $batch->createAclEntry(
                                       "user",
                                       "project: $pluginName",
                                       {
                                          projectName                => $pluginName,
                                          credentialName             => $cred,
                                          readPrivilege              => 'allow',
                                          modifyPrivilege            => 'allow',
                                          executePrivilege           => 'allow',
                                          changePermissionsPrivilege => 'allow'
                                       }
                                      );
            }

            # Attach the credential to the appropriate steps
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'Create',
                                        stepName      => 'Create'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'Clone',
                                        stepName      => 'Clone'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'Relocate',
                                        stepName      => 'Relocate'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'Cleanup',
                                        stepName      => 'Cleanup'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'Revert',
                                        stepName      => 'Revert'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'Snapshot',
                                        stepName      => 'Snapshot'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'PowerOn',
                                        stepName      => 'PowerOn'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'PowerOff',
                                        stepName      => 'PowerOff'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'Shutdown',
                                        stepName      => 'Shutdown'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'Suspend',
                                        stepName      => 'Suspend'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'CreateResourceFromVM',
                                        stepName      => 'CreateResourceFromVM'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'GetVMConfiguration',
                                        stepName      => 'GetVMConfiguration'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'Import',
                                        stepName      => 'Import'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'Export',
                                        stepName      => 'Export'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'RegisterVM',
                                        stepName      => 'RegisterVM'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'CloudManagerGrow',
                                        stepName      => 'grow'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'CloudManagerShrink',
                                        stepName      => 'shrink'
                                     }
                                    );
            $batch->attachCredential(
                                     "\$[/plugins/$pluginName/project]",
                                     $cred,
                                     {
                                        procedureName => 'CloudManagerSync',
                                        stepName      => 'sync'
                                     }
                                    );
        }
    }
}
    
	
	
        
