if ($promoteAction ne '') {
    my @objTypes = ('projects', 'resources', 'workspaces');
    my $query    = $commander->newBatch();
    my @reqs     = map { $query->getAclEntry('user', 'project: @PLUGIN_NAME@', { systemObjectName => $_ }) } @objTypes;
    push @reqs, $query->getProperty('/server/ec_hooks/promote');
    $query->submit();

    foreach my $type (@objTypes) {
        if ($query->findvalue(shift @reqs, 'code') ne 'NoSuchAclEntry') {
            $batch->deleteAclEntry('user', 'project: @PLUGIN_NAME@', { systemObjectName => $type });
        }
    }

    if ($promoteAction eq "promote") {
        foreach my $type (@objTypes) {
            $batch->createAclEntry(
                                   'user',
                                   'project: @PLUGIN_NAME@',
                                   {
                                      systemObjectName           => $type,
                                      readPrivilege              => 'allow',
                                      modifyPrivilege            => 'allow',
                                      executePrivilege           => 'allow',
                                      changePermissionsPrivilege => 'allow'
                                   }
                                  );
        }

        # The plugin is being promoted, create a property reference in the server's property sheet
        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Suspend",
                            {
                               description => "Suspend a virtual machine.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/Suspend]'
                            }
                           );

        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Cleanup",
                            {
                               description => "Cleanup a virtual machine.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/Cleanup]'
                            }
                           );
        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Clone",
                            {
                               description => "Clone a virtual machine.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/Clone]'
                            }
                           );

        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Create",
                            {
                               description => "Create a virtual machine.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/Create]'
                            }
                           );
        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - CreateResourceFromVM",
                            {
                               description => "Store information about a virtual machine and create ElectricCommander resources.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/CreateResourceFromVM]'
                            }
                           );
        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Import",
                            {
                               description => "Import an OVF package to the ESX server.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/Import]'
                            }
                           );
        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - GetVMConfiguration",
                            {
                               description => "Get virtual machine information and store it in properties.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/GetVMConfiguration]'
                            }
                           );
        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Export",
                            {
                               description => "Export a virtual machine to an OVF package using ovftool.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/Export]'
                            }
                           );

        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Relocate",
                            {
                               description => "Relocate a virtual machine.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/Relocate]'
                            }
                           );
        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - RegisterVM",
                            {
                               description => "Register an existing virtual machine.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/RegisterVM]'
                            }
                           );
        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - PowerOff",
                            {
                               description => "Power off a virtual machine.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/PowerOff]'
                            }
                           );
        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - PowerOn",
                            {
                               description => "Power on a virtual machine.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/PowerOn]'
                            }
                           );
        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Revert",
                            {
                               description => "Revert the configuration to the last snapshot.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/Revert]'
                            }
                           );
        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Shutdown",
                            {
                               description => "Shutdown a virtual machine.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/Shutdown]'
                            }
                           );

        $batch->setProperty(
                            "/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Snapshot",
                            {
                               description => "Create a snapshot for the specified virtual machine.",
                               value       => '$[/plugins/@PLUGIN_KEY@-@PLUGIN_VERSION@/project/ui_forms/Snapshot]'
                            }
                           );

    }
    elsif ($promoteAction eq "demote") {
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Suspend");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Clone");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Cleanup");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Create");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - CreateResourceFromVM");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - GetVMConfiguration");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Import");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Export");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Relocate");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - RegisterVM");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - PowerOff");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - PowerOn");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Revert");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Shutdown");
        $batch->deleteProperty("/server/ec_customEditors/pluginStep/@PLUGIN_KEY@ - Snapshot");
    }
}






if ($upgradeAction eq "upgrade") {
    my $query = $commander->newBatch();
    my $newcfg = $query->getProperty(
        "/plugins/$pluginName/project/esx_cfgs");
    my $oldcfgs = $query->getProperty(
        "/plugins/$otherPluginName/project/esx_cfgs");
	my $creds = $query->getCredentials(
        "\$[/plugins/$otherPluginName]");

	local $self->{abortOnError} = 0;
    $query->submit();

    # if new plugin does not already have cfgs
    if ($query->findvalue($newcfg,"code") eq "NoSuchProperty") {
        # if old cfg has some cfgs to copy
        if ($query->findvalue($oldcfgs,"code") ne "NoSuchProperty") {
            $batch->clone({
                path => "/plugins/$otherPluginName/project/esx_cfgs",
                cloneName => "/plugins/$pluginName/project/esx_cfgs"
            });
        }
    }
	
	# Copy configuration credentials and attach them to the appropriate steps
    my $nodes = $query->find($creds);
    if ($nodes) {
        my @nodes = $query->{xpath}->findnodes("credential/credentialName", $nodes);
        for (@nodes) {
            my $cred = $_->string_value;

            # Clone the credential
            $batch->clone({
                path => "/plugins/$otherPluginName/project/credentials/$cred",
                cloneName => "/plugins/$pluginName/project/credentials/$cred"
            });

            # Make sure the credential has an ACL entry for the new project principal
            my $xpath = $commander->getAclEntry("user", "project: $pluginName", {
                projectName => $otherPluginName,
                credentialName => $cred
            });
            if ($xpath->findvalue("//code") eq "NoSuchAclEntry") {
                $batch->deleteAclEntry("user", "project: $otherPluginName", {
                    projectName => $pluginName,
                    credentialName => $cred
                });
                $batch->createAclEntry("user", "project: $pluginName", {
                    projectName => $pluginName,
                    credentialName => $cred,
                    readPrivilege => 'allow',
                    modifyPrivilege => 'allow',
                    executePrivilege => 'allow',
                    changePermissionsPrivilege => 'allow'
                });
            }

            # Attach the credential to the appropriate steps
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'Create',
                stepName => 'Create'
            });
			$batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'Clone',
                stepName => 'Clone'
            });
			$batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'Relocate',
                stepName => 'Relocate'
            });
			$batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'Cleanup',
                stepName => 'Cleanup'
            });
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'Revert',
                stepName => 'Revert'
            });
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'Snapshot',
                stepName => 'Snapshot'
            });
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'PowerOn',
                stepName => 'PowerOn'
            });
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'PowerOff',
                stepName => 'PowerOff'
            });
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'Shutdown',
                stepName => 'Shutdown'
            });
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'Suspend',
                stepName => 'Suspend'
            });
			$batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'CreateResourceFromVM',
                stepName => 'CreateResourceFromVM'
            });
			$batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'GetVMConfiguration',
                stepName => 'GetVMConfiguration'
            });
			$batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'Import',
                stepName => 'Import'
            });
			$batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'Export',
                stepName => 'Export'
            });
			$batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'RegisterVM',
                stepName => 'RegisterVM'
            });
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'CloudManagerGrow',
                stepName => 'grow'
            });
            $batch->attachCredential("\$[/plugins/$pluginName/project]", $cred, {
                procedureName => 'CloudManagerShrink',
                stepName => 'shrink'
            });
        }
    }
}
