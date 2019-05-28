EC-ESX
============

The CloudBees Flow ESX integration

## Compile ##

Run gradlew to compile the plugin

`./gradlew`

## Tests ##


## Compile And Upload ##
0. Install git
   sudo apt-get install git
1. Get this plugin
   https://github.com/electric-cloud/EC-ESX.git
2. Run gradlew to compile the plugin
   `./gradlew jar` (in EC-ESX directory)
3. Upload the plugin to EC server
4. Create a configuration for the EC-ESX plugin.

####Prerequisites:####
    1.An existing VMWare account with the required vCenter/vSphere credentials.

####Required files:####
    1. Create a file called ecplugin.properties inside EC-ESX directory with the below mentioned contents.

####Contents of ecplugin.properties:####
    COMMANDER_SERVER=<COMMANDER_SERVER>(Commander server IP)
    COMMANDER_USER=<COMMANDER_USER>
    COMMANDER_PASSWORD=<COMMANDER_PASSWORD>

####Contents of Configurations.json:####
    1. Configurations.json is a configurable file.
    2. Refer to the sample Configurations.json file, `/src/test/java/ecplugins/esx/Configurations.json`. It has to be updated with the user specific, valid inputs.
   
####Run the tests:#####
`./gradlew test`
