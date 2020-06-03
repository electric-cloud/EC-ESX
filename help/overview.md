VMware ESX and VMware ESXi provide the foundation for
building and managing a reliable and dynamic IT
infrastructure.

ESX Server is managed by the VMware Infrastructure Client. Its
centralized management platform is called Virtual Center. These
hypervisors abstract processor, memory, storage and networking
resources into multiple virtual machines that each can run an
unmodified operating system and applications.


VMware ESXi is the latest hypervisor architecture from VMware.
The original ESX is being replaced by ESXi.

## ESX Links

<p>More information can be found <a href="http://www.vmware.com/products/vsphere/esxi-and-esx/index.html">
here</a>.</p>

<p>Information about the OVF tool can be found <a href="http://communities.vmware.com/community/vmtn/vsphere/automationtools/ovf">
here.</a></p>

<p>For some procedures you need to specify the Guest OS ID. Find these values <a href="http://www.vmware.com/support/developer/converter-sdk/conv50_apireference/vim.vm.GuestOsDescriptor.GuestOsIdentifier.html">
here</a>.</p>

<p>OVF manual is available <a href="http://www.vmware.com/support/developer/ovf/">here.</a></p>

<h2>CloudBees CD Integration to VMware ESX and ESXi</h2>

<p>EC-ESX integration uses modules from the VI Perl Toolkit, which
provides access to the ESX system. By using this toolkit, the
integration can connect to the ESX server to automate and
perform various operations providing a more generic interface
for managing virtual machines on ESX servers.</p>

<p>The plugin interacts with ESX data using PERL to perform the
following tasks:</p>

<ul>
    <li>Create configuration to hold connection information.</li>

    <li>Query for virtual machine information.</li>

    <li>Perform actions on virtual machines.</li>

    <li>Import and export virtual machines.</li>

    <li>Create CloudBees CD resources.</li>
</ul>

<p>This plugin provides the following procedures: Cleanup,
Clone, Create, CreateResourceFromVM, Export,
GetVMConfiguration, Import, PowerOn, PowerOff, RegisterVM,
Relocate, Revert, Shutdown, Snapshot, and Suspend.<br />
This plugin communicates with ESX by using the Perl module
VMware::VIRuntime, provided by VMware.</p>

## OVF Tool

<p>The VMware OVF Tool is a command line utility that allows you to
import and export OVF packages.<br />
In order to execute Import and Export procedures using the ESX
plugin, the OVF Tool must be installed.</p>

<p>You can download this utility from the <a href="http://communities.vmware.com/community/vmtn/vsphere/automationtools/ovf">
OVF Tool page</a>.<br />
You must have an account to download this tool. If you do not
have an account, you can create one for free.</p>

<p class="help">After downloading VMware OVF Tool, use the
corresponding install method for your operating system:</p>

<table border="0" class="help">
    <tr>
        <th>Operating System</th>
        <th>Installation Method</th>
    </tr>
    <tr>
        <td>Linux 32-bit</td>
        <td>Run the shell script as ./VMware-OVF-Tool.sh</td>
    </tr>
    <tr>
        <td>Linux 64-bit</td>
        <td>Run the shell script as
        ./VMware-OVF-Tool.x86_64.sh</td>
    </tr>
    <tr>
        <td>Mac 64-bit</td>
        <td></td>
    </tr>
    <tr>
        <td>Windows 32-bit</td>
        <td>Double-click the installer, VMware-OVF-Tool.exe</td>
    </tr>
    <tr>
        <td>Windows 64-bit</td>
        <td>Double-click the installer,
        VMware-OVF-Tool.x86_64.exe</td>
    </tr>
</table>

<h2>Integrated Version</h2>

<p>This plugin was developed and tested against ESX 3.5 and
ESXi 5.0.</p>
