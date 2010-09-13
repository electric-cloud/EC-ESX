@files = (
 ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="ESXCreateConfigForm"]/value'  , 'ESXCreateConfigForm.xml'],
 ['//property[propertyName="ui_forms"]/propertySheet/property[propertyName="ESXEditConfigForm"]/value'  , 'ESXEditConfigForm.xml'],

 ['//property[propertyName="preamble"]/value' , 'preamble.pl'],
 ['//property[propertyName="ESX"]/value' , 'ESX.pm'],
 
 ['//procedure[procedureName="CreateConfiguration"]/step[stepName="CreateConfiguration"]/command' , 'conf/createcfg.pl'],
 ['//procedure[procedureName="CreateConfiguration"]/step[stepName="CreateAndAttachCredential"]/command' , 'conf/createAndAttachCredential.pl'],
 ['//procedure[procedureName="DeleteConfiguration"]/step[stepName="DeleteConfiguration"]/command' , 'conf/deletecfg.pl'],
 
 ['//procedure[procedureName="Create"]/step[stepName="Create"]/command' , 'vm/create.pl'],
 ['//procedure[procedureName="Clone"]/step[stepName="Clone"]/command' , 'vm/clone.pl'],
 ['//procedure[procedureName="Relocate"]/step[stepName="Relocate"]/command' , 'vm/relocate.pl'],
 ['//procedure[procedureName="Cleanup"]/step[stepName="Cleanup"]/command' , 'vm/cleanup.pl'],
 ['//procedure[procedureName="Revert"]/step[stepName="Revert"]/command' , 'vm/revert.pl'],

 ['//property[propertyName="ec_setup"]/value', 'ec_setup.pl'],
);
