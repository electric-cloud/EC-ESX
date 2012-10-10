##########################
# attemptConnection.pl
##########################

use ElectricCommander;
use ElectricCommander::PropDB;
use MIME::Base64;
use lib $ENV{COMMANDER_PLUGINS} . '/@PLUGIN_NAME@/agent/lib';
use VMware::VIRuntime;
use VMware::VILib;

use Carp qw( carp croak );

use constant {
               SUCCESS => 0,
               ERROR   => 1,
             };

## get an EC object
my $ec = new ElectricCommander();
$ec->abortOnError(0);

my $credName = "$[/myJob/config]";

my $xpath    = $ec->getFullCredential("credential");
my $errors   = $ec->checkAllErrors($xpath);
my $username = $xpath->findvalue("//userName");
my $password = $xpath->findvalue("//password");

my $projName = "$[/myProject/projectName]";
print "Attempting connection with server\n";

my $esx_url = "$[esx_url]";

# Connect
eval { my $vim = Vim::login(service_url => $esx_url, user_name => $username, password => $password); };
#-----------------------------
# Check if successful login
#-----------------------------
if ($@) {
    print $@ . "\n";

    my $errMsg = "\nTest connection failed.\n";
    $ec->setProperty("/myJob/configError", $errMsg);
    print $errMsg;

    $ec->deleteProperty("/projects/$projName/esx_cfgs/$credName");
    $ec->deleteCredential($projName, $credName);
    exit ERROR;

}

exit SUCCESS;

