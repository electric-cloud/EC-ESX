#########################
## createcfg.pl
#########################

use ElectricCommander;
use ElectricCommander::PropDB;

use constant {
	SUCCESS => 0,
	ERROR   => 1,
};

my $opts;

my $PLUGIN_NAME = 'EC-ESX';

if (!defined $PLUGIN_NAME) {
    print "PLUGIN_NAME must be defined\n";
    exit ERROR;
}

# get an EC object
my $ec = new ElectricCommander();
$ec->abortOnError(0);

# load option list from procedure parameters
my $x = $ec->getJobDetails($ENV{COMMANDER_JOBID});
my $nodeset = $x->find("//actualParameter");
foreach my $node ($nodeset->get_nodelist) {
    my $parm = $node->findvalue("actualParameterName");
    my $val = $node->findvalue("value");
    $opts->{$parm}="$val";
}

if (!defined $opts->{config} || "$opts->{config}" eq "" ) {
    print "config parameter must exist and be non-blank\n";
    exit ERROR;
}

# check to see if a config with this name already exists before we do anything else
my $xpath = $ec->getProperty("/myProject/esx_cfgs/$opts->{config}");
my $property = $xpath->findvalue("//response/property/propertyName");

if (defined $property && "$property" ne "") {
    my $errMsg = "A configuration named '$opts->{config}' already exists.";
    $ec->setProperty("/myJob/configError", $errMsg);
    print $errMsg;
    exit ERROR;
}

# check valid esx_url
if ($opts->{esx_url} !~ m/http(s*):\/\/(.*)/) {
    print "You need to use the URL to address the host: 'http(s)://(ip_address|hostname)'";
    exit ERROR;
}


my $cfg = new ElectricCommander::PropDB($ec,"/myProject/esx_cfgs");

# add all the options as properties
foreach my $key (keys % {$opts}) {
    if ("$key" eq "config" ) { 
        next;
    }
    $cfg->setCol("$opts->{config}","$key","$opts->{$key}");
}
exit SUCCESS;
