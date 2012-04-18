my %suspend = (
			   label       => "ESX - Suspend",
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

@::createStepPickerSteps = (\%suspend, \%cleanup, \%clone, \%create, \%createresourcefromvm, \%import, \%getvmconfiguration, \%export, \%relocate, \%registervm, \%poweroff, \%poweron, \%revert, \%shutdown, \%snapshot);

    
	
	
        