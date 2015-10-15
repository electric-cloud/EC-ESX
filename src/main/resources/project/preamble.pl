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

use ElectricCommander;
use File::Basename;
use ElectricCommander::PropDB;
use ElectricCommander::PropMod;
use Encode;
use utf8;

$| = 1;

use constant {
               SUCCESS => 0,
               ERROR   => 1,
             };

# Create ElectricCommander instance
my $ec = new ElectricCommander();
$ec->abortOnError(0);

my $pluginKey  = 'EC-ESX';
my $xpath      = $ec->getPlugin($pluginKey);
my $pluginName = $xpath->findvalue('//pluginVersion')->value;
print "Using plugin $pluginKey version $pluginName\n";
$opts->{pluginVer} = $pluginName;

if (defined($opts->{connection_config}) && $opts->{connection_config} ne "") {
    my $cfgName = $opts->{connection_config};
    print "Loading config $cfgName\n";

    my $proj = "$[/myProject/projectName]";
    my $cfg = new ElectricCommander::PropDB($ec, "/projects/$proj/esx_cfgs");

    my %vals = $cfg->getRow($cfgName);

    # Check if configuration exists
    unless (keys(%vals)) {
        print "Configuration [$cfgName] does not exist\n";
        exit ERROR;
    }

    # Add all options from configuration
    foreach my $c (keys %vals) {
        print "Adding config $c = $vals{$c}\n";
        $opts->{$c} = $vals{$c};
    }

    # Check that credential item exists
    if (!defined $opts->{credential} || $opts->{credential} eq "") {
        print "Configuration [$cfgName] does not contain an ESX credential\n";
        exit ERROR;
    }

    # Get user/password out of credential named in $opts->{credential}
    my $xpath = $ec->getFullCredential("$opts->{credential}");
    $opts->{esx_user} = $xpath->findvalue("//userName");
    $opts->{esx_pass} = $xpath->findvalue("//password");

    # Check for required items
    if (!defined $opts->{esx_url} || $opts->{esx_url} eq "") {
        print "Configuration [$cfgName] does not contain an ESX server url\n";
        exit ERROR;
    }
}

$opts->{JobStepId} = "$[/myJobStep/jobStepId]";

# Load the actual code into this process
if (!ElectricCommander::PropMod::loadPerlCodeFromProperty($ec, '/myProject/esx_driver/ESX')) {
    print 'Could not load ESX.pm\n';
    exit ERROR;
}

# Make an instance of the object, passing in options as a hash
my $gt = new ESX($ec, $opts);
