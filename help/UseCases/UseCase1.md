## Use Case 1: PowerOn, Consume, and PowerOff Job

One of the most common uses for this plugin is to power on
an existing virtual machine, then create an CloudBees CD
resource assigned to this VM, use the resource to run some
operations, and then power off the machine and delete the
resource. To accomplish these task you must:

1. Create a Plugin Configuration.
2. Power on a VM in ESX.
3. Create a Resource for this VM.
4. Use the created resource.
5. Delete the resource.
6. Power off the VM.

### Create a Plugin Configuration

<p>Plugin configurations are created by going to the CloudBees CD "Administration" tab, then to the "Plugins" sub-tab.
On the right side of the line for the ESX plugin, there is a
"Configure" link which will open the Configuration page.<br />
Create a new configuration by specifying the requested
parameters:</p><img alt="" src="../../plugins/@PLUGIN_KEY@/images/use_cases/Case_1/create_config.png" />

<p>Once the configuration is created, you can see it listed in
"ESX Configurations", and now you are able to manage virtual
machines</p>

### PowerOn

<p>Create a new PowerOn procedure and fill in the requested
parameters with real values from your ESX server:</p><img alt="" src="../../plugins/@PLUGIN_KEY@/images/use_cases/Case_1/poweron_parameters.png" />

<p>Make sure you selected the "Create Resource?" checkbox.</p>

### Consume

<p>Create a new command step to use the created resource. In
this example, we will pick a resource from the pool and just add
an ec-perl sleep to use it for 30 seconds.</p><img alt="" src="../../plugins/@PLUGIN_KEY@/images/use_cases/Case_1/consume_parameters.png" />

### Cleanup

<p>Now that the resource has been used and is ready to be deleted,
create a Cleanup step and fill in the requested
parameters.</p><img alt="" src="../../plugins/@PLUGIN_KEY@/images/use_cases/Case_1/cleanup_parameters.png" />

### PowerOff

<p>Now that the resource has been deleted, create a PowerOff
step and fill in the requested parameters.</p><img alt="" src="../../plugins/@PLUGIN_KEY@/images/use_cases/Case_1/poweroff_parameters.png" />

### Results and outputs

<p>Once the job finished, you can see the properties stored in
'Results location'.<br />
<img alt="" src="../../plugins/@PLUGIN_KEY@/images/use_cases/Case_1/job.png" /></p><img alt="" src="../../plugins/@PLUGIN_KEY@/images/use_cases/Case_1/results.png" />

<p>PowerOn output:</p><img alt="" src="../../plugins/@PLUGIN_KEY@/images/use_cases/Case_1/poweron_log.png" />

<p>Cleanup output:</p><img alt="" src="../../plugins/@PLUGIN_KEY@/images/use_cases/Case_1/cleanup_log.png" />

<p>PowerOff output:</p><img alt="" src="../../plugins/@PLUGIN_KEY@/images/use_cases/Case_1/poweroff_log.png" />
