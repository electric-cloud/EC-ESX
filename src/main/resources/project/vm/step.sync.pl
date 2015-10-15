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
# step.sync.pl
##########################
use ElectricCommander;
use ElectricCommander::PropDB;
use strict;
use warnings;


my $opts;
$::ec = new ElectricCommander();
$::ec->abortOnError(0);
$::pdb = new ElectricCommander::PropDB($::ec);

$| = 1;

my $esx_config  = "$[connection_config]";
my $deployments = '$[deployments]';

$opts->{connection_config} = q{$[connection_config]};
$[/myProject/procedure_helpers/preamble]





sub main {
    print "ESX Sync:\n";

    # unpack request
    my $xPath = XML::XPath->new(xml => $deployments);
    my $nodeset = $xPath->find('//Deployment');

    my $instanceList = "";

    # put request in perl hash
    my $deplist;
    foreach my $node ($nodeset->get_nodelist) {

        # for each deployment
        my $i = $xPath->findvalue('handle', $node)->string_value;
        my $s = $xPath->findvalue('state',  $node)->string_value;    # alive
        print "Input: $i state=$s\n";
        $deplist->{$i}{state}  = "alive";                            # we only get alive items in list
        $deplist->{$i}{result} = "alive";
        $instanceList .= "$i\;";
    }

    checkIfAlive($instanceList, $deplist);

    my $xmlout = "";
    addXML(\$xmlout, "<SyncResponse>");
    foreach my $handle (keys %{$deplist}) {
        my $result = $deplist->{$handle}{result};
        my $state  = $deplist->{$handle}{state};

        addXML(\$xmlout, "<Deployment>");
        addXML(\$xmlout, "  <handle>$handle</handle>");
        addXML(\$xmlout, "  <state>$state</state>");
        addXML(\$xmlout, "  <result>$result</result>");
        addXML(\$xmlout, "</Deployment>");
    }
    addXML(\$xmlout, "</SyncResponse>");
    $::ec->setProperty("/myJob/CloudManager/sync", $xmlout);
    print "\n$xmlout\n";
    exit 0;
}

# checks status of instances
# if found to be stopped, it marks the deplist to pending
# otherwise (including errors running api) it assumes it is still running
sub checkIfAlive {
    my ($instances, $deplist) = @_;

    foreach my $handle (keys %{$deplist}) {

        # deployment specific response
        my $state = $gt->checkState($handle);

        my $err = "success";
        my $msg = "";
        if ("$state" eq "poweredOn") {
            print("VM $handle still running\n");
            $deplist->{$handle}{state}  = "alive";
            $deplist->{$handle}{result} = "success";
            $deplist->{$handle}{mesg}   = "instance still running";
        }
        else {
            print("VM $handle stopped\n");
            $deplist->{$handle}{state}  = "pending";
            $deplist->{$handle}{result} = "success";
            $deplist->{$handle}{mesg}   = "VM $handle was manually stopped or failed";
        }

    }
    return;
}

sub addXML {
    my ($xml, $text) = @_;
    ## TODO encode
    ## TODO autoindent
    $$xml .= $text;
    $$xml .= "\n";
}

main();
