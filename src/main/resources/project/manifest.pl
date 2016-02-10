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

@files = (

    #Configuration files
    ['//procedure[procedureName="CreateConfiguration"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'ESXCreateConfigForm.xml'],
    ['//procedure[procedureName="DeleteConfiguration"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'ui_forms/deleteconfiguration.xml'],
    ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="ESXCreateConfigForm"]/value',           'ESXCreateConfigForm.xml'],
    ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="ESXEditConfigForm"]/value',             'ESXEditConfigForm.xml'],
    ['//procedure[procedureName="CreateConfiguration"]/step[stepName="CreateConfiguration"]/command',                  'conf/createcfg.pl'],
    ['//procedure[procedureName="CreateConfiguration"]/step[stepName="CreateAndAttachCredential"]/command',            'conf/createAndAttachCredential.pl'],
    ['//procedure[procedureName="CreateConfiguration"]/step[stepName="AttemptConnection"]/command',                    'conf/attemptConnection.pl'],
    ['//procedure[procedureName="DeleteConfiguration"]/step[stepName="DeleteConfiguration"]/command',                  'conf/deletecfg.pl'],

    #Procedures
    ['//procedure[procedureName="Create"]/propertySheet/property[propertyName="ec_parameterForm"]/value',               'ui_forms/create.xml'],
    ['//step[stepName="Create"]/command',                                                                               'vm/create.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="Clone"]/propertySheet/property[propertyName="ec_parameterForm"]/value',                'ui_forms/clone.xml'],
    ['//step[stepName="Clone"]/command',                                                                                'vm/clone.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="Cleanup"]/propertySheet/property[propertyName="ec_parameterForm"]/value',              'ui_forms/cleanup.xml'],
    ['//step[stepName="Cleanup"]/command',                                                                              'vm/cleanup.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="Relocate"]/propertySheet/property[propertyName="ec_parameterForm"]/value',             'ui_forms/relocate.xml'],
    ['//step[stepName="Relocate"]/command',                                                                             'vm/relocate.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="Revert"]/propertySheet/property[propertyName="ec_parameterForm"]/value',               'ui_forms/revert.xml'],
    ['//step[stepName="Revert"]/command',                                                                               'vm/revert.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="Snapshot"]/propertySheet/property[propertyName="ec_parameterForm"]/value',             'ui_forms/snapshot.xml'],
    ['//step[stepName="Snapshot"]/command',                                                                             'vm/snapshot.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="PowerOn"]/propertySheet/property[propertyName="ec_parameterForm"]/value',              'ui_forms/poweron.xml'],
    ['//step[stepName="PowerOn"]/command',                                                                              'vm/poweron.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="PowerOff"]/propertySheet/property[propertyName="ec_parameterForm"]/value',             'ui_forms/poweroff.xml'],
    ['//step[stepName="PowerOff"]/command',                                                                             'vm/poweroff.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="Shutdown"]/propertySheet/property[propertyName="ec_parameterForm"]/value',             'ui_forms/shutdown.xml'],
    ['//step[stepName="Shutdown"]/command',                                                                             'vm/shutdown.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="Suspend"]/propertySheet/property[propertyName="ec_parameterForm"]/value',              'ui_forms/suspend.xml'],
    ['//step[stepName="Suspend"]/command',                                                                              'vm/suspend.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="CreateResourceFromVM"]/propertySheet/property[propertyName="ec_parameterForm"]/value', 'ui_forms/createresourcefromvm.xml'],
    ['//step[stepName="CreateResourceFromVM"]/command',                                                                 'vm/createresourcefromvm.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="GetVMConfiguration"]/propertySheet/property[propertyName="ec_parameterForm"]/value',   'ui_forms/getvmconfiguration.xml'],
    ['//step[stepName="GetVMConfiguration"]/command',                                                                   'vm/getvmconfiguration.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="Import"]/propertySheet/property[propertyName="ec_parameterForm"]/value',               'ui_forms/import.xml'],
    ['//step[stepName="Import"]/command',                                                                               'vm/import.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="Export"]/propertySheet/property[propertyName="ec_parameterForm"]/value',               'ui_forms/export.xml'],
    ['//step[stepName="Export"]/command',                                                                               'vm/export.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="RegisterVM"]/propertySheet/property[propertyName="ec_parameterForm"]/value',           'ui_forms/registervm.xml'],
    ['//step[stepName="RegisterVM"]/command',                                                                           'vm/registervm.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    ['//procedure[procedureName="CloudManagerGrow"]/propertySheet/property[propertyName="ec_parameterForm"]/value',     'ui_forms/cloudmanagergrow.xml'],
    ['//step[stepName="grow"]/command',                                                                                 'vm/step.grow.pl'],
    ['//procedure[procedureName="CloudManagerShrink"]/propertySheet/property[propertyName="ec_parameterForm"]/value',   'ui_forms/cloudmanagershrink.xml'],
    ['//step[stepName="shrink"]/command',                                                                               'vm/step.shrink.pl'],
    ['//step[stepName="sync"]/command',                                                                                 'vm/step.sync.pl'],

    ['//procedure[procedureName="ListManagedEntity"]/propertySheet/property[propertyName="ec_parameterForm"]/value',    'ui_forms/listManagedEntity.xml'],
    ['//step[stepName="ListManagedEntity"]/command',                                                                    'vm/listManagedEntity.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],

    ['//procedure[procedureName="CreateFolder"]/propertySheet/property[propertyName="ec_parameterForm"]/value',         'ui_forms/createFolder.xml'],
    ['//step[stepName="CreateFolder"]/command',                                                                         'vm/createFolder.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],

    ['//procedure[procedureName="DeleteManagedEntity"]/propertySheet/property[propertyName="ec_parameterForm"]/value',  'ui_forms/deleteManagedEntity.xml'],
    ['//step[stepName="DeleteManagedEntity"]/command',                                                                  'vm/deleteManagedEntity.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],

    ['//procedure[procedureName="RenameManagedEntity"]/propertySheet/property[propertyName="ec_parameterForm"]/value',  'ui_forms/renameManagedEntity.xml'],
    ['//step[stepName="RenameManagedEntity"]/command',                                                                  'vm/renameManagedEntity.pl'],
    ['//step[stepName="SetTimelimit"]/command',                                                                         'setTimelimit.pl'],
    #Main files
    ['//property[propertyName="preamble"]/value', 'preamble.pl'],
    ['//property[propertyName="ESX"]/value',      'ESX.pm'],
    ['//property[propertyName="ec_setup"]/value', 'ec_setup.pl'],
);
