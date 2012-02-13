use ElectricCommander;
use ElectricCommander::PropDB;

$::ec = new ElectricCommander();
$::ec->abortOnError(0);

$| = 1;

my $opts;

$opts->{connection_config} = q{$[connection_config]};

my $number   = "$[number]";
my $poolName = "$[poolName]";

my $esx_workspace           = "$[esx_workspace]";
my $pattern                 = "$[esx_pattern]";

$[/myProject/procedure_helpers/preamble]



my @deparray = split(/\|/, $deplist);

sub main {
    print "ESX Grow:\n";

    #
    # Validate inputs
    #
    $number   =~ s/[^0-9]//gixms;
    $poolName =~ s/[^A-Za-z0-9_-].*//gixms;
    $opts->{connection_config}       =~ s/[^A-Za-z0-9_-\s]//gixms;

  
    my $xmlout = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n";
    addXML(\$xmlout, "<GrowResponse>");

    my $xPath;
    
    for (1 .. $number) {
    
    my $esx_vmname = $gt->getAvailableVM($pattern);
    
    if ($esx_vmname eq undef){
    last;
    }

    ### PowerOn VMS ###
    print("Running ESX PowerOn\n");
    my $proj = "$[/myProject/projectName]";
    my $proc = "PowerOn";
    $xPath = $::ec->runProcedure(
        "$proj",
        {
           procedureName   => "$proc",
           pollInterval    => 1,
           timeout         => 3600,
           actualParameter => [
           { actualParameterName => "connection_config", value => "$opts->{connection_config}" }, 
           { actualParameterName => "esx_vmname", value => "$esx_vmname" }, 
           { actualParameterName => "esx_properties_location", value => "/myJob/ESX/vms" }, 
           { actualParameterName => "esx_create_resources", value => "1" }, 
           { actualParameterName => "esx_pools", value => "$poolName" }, 
           { actualParameterName => "esx_workspace", value => "$esx_workspace" }, 
           { actualParameterName => "esx_number_of_vms", value => "1" }, 
           ],

        }
    );

    if ($xPath) {
        my $code = $xPath->findvalue('//code');
        if ($code ne "") {
            my $mesg = $xPath->findvalue('//message');
            print "Run procedure returned code is '$code'\n$mesg\n";
        }
    }
    my $outcome = $xPath->findvalue('//outcome')->string_value;
    if ("$outcome" ne "success") {
        print "ESX PowerOn job failed.\n";
        exit 1;
    }

    my $jobId = $xPath->findvalue('//jobId')->string_value;
    if (!$jobId) {

        exit 1;
    }

    my $depobj = new ElectricCommander::PropDB($::ec, "");
    my $vmList = $depobj->getProp("/jobs/$jobId/ESX/vms/VMList");
    print "VM list=$vmList\n";
    my @vms = split(/;/, $vmList);
    my $createdList = ();

    foreach my $vm (@vms) {
        addXML(\$xmlout, "<Deployment>");
        addXML(\$xmlout, "<handle>$vm</handle>");
        addXML(\$xmlout, "<hostname>" . $depobj->getProp("/jobs/$jobId/ESX/vms/$vm/hostName") . "</hostname>");
        addXML(\$xmlout, "<resource>" . $depobj->getProp("/jobs/$jobId/ESX/vms/$vm/resource") . "</resource>");
        addXML(\$xmlout, "<ipaddress>" . $depobj->getProp("/jobs/$jobId/ESX/vms/$vm/ipAddress") . "</ipaddress>");
        addXML(\$xmlout, "<results>/jobs/$jobId/ESX/vms</results>");
        addXML(\$xmlout, "</Deployment>");
    }
}
    addXML(\$xmlout, "</GrowResponse>");

    my $prop = "/myJob/CloudManager/grow";
    print "Registering results for $vmList in $prop\n";
    $::ec->setProperty("$prop", $xmlout);
}

sub addXML {
    my ($xml, $text) = @_;
    ## TODO encode
    ## TODO autoindent
    $$xml .= $text;
    $$xml .= "\n";
}

main();
