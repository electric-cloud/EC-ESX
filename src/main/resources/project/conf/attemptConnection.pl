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

