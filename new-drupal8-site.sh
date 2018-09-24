#!/bin/bash

# Variables
newSite=null
configDir=$(pwd)/$newSite/config
d8root=web
config='$config'
RED='\033[0;31m'
BLUE='\034[0;31m'
MAGENTA='\035[0;31m'
NC='\033[0m'

echo "What do you want to call your new Drupal site's directory?"
read newSite
siteDir=$(pwd)/$newSite

main() {
    if [ -z ${newSite+x} ]; 
    then 
        echo "${RED}ERROR${NC} You have to input a directory. Try again."
    else 
        echo "Your new drupal will be located at: ${MAGENTA}'$siteDir'${NC}"; 
            composerSetup
            baseSetup
            ddevSetup
            siteInstall
    fi
}

# Install drupal 8 using the composer template
composerSetup() {
    if [ ! -d "$newSite" ] ; 
        then 
            echo "Setting up drupal composer site at: $newSite"
            mkdir -p $newSite
            composer create-project drupal-composer/drupal-project:8.x-dev $siteDir --stability dev --no-interaction 
            cd $siteDir
        else
            echo "${RED}ERROR${NC} That director '$newSite' already exists."
            exit
    fi;
}

# Adding contrib modules and cloning down the base
baseSetup() {
    composer require 'drupal/pathauto:^1.3'
    composer require 'drupal/admin_toolbar:^1.24'
    composer require 'drupal/field_group:3.x-dev'
    composer require 'drupal/adminimal_theme:1.x-dev'
    composer require 'drupal/adminimal_admin_toolbar:^1.8'
    composer require 'drupal/config_filter:^1.2'
    composer require 'drupal/config_split:^1.3'
    composer require 'drupal/devel:1.x-dev'

    mkdir config
    cd config
    git clone https://github.com/brentrobbins/drupal8-base-config.git .
    rm -rf .git
    cd ..
}

# Initial DDEV setup (local dev enviornment) of the Drupal 8 site
ddevSetup() {
    ddev config --docroot=$d8root --projectname=$newSite --projecttype=drupal8 --xdebug-enabled=true
    
    #mkdir .ddev/php
    #printf "[PHP]\n xdebug.remote_port=11011" >> .ddev/php/xdebug_remote_port.ini

    mkdir .vscode
    touch .vscode/launch.json
    printf '{
        "version": "0.2.0",
        "configurations": [{
            "name": "Listen for XDebug",
            "type": "php",
            "request": "launch",
            "port": 11011,
            "pathMappings": {
                "/var/www/html": "${workspaceRoot}"
            }
        }]
    }' >> .vscode/launch.json

    ddev start

    printf "\n// Configuration Split \n" >> web/sites/default/settings.php
    printf "$config['config_split.config_split.dev']['status'] = TRUE;" >> web/sites/default/settings.php
}

# Drupal install using the base configuration files
siteInstall(){
    ddev exec drush si --existing-config --account-mail=brent@variantstudios.com --account-name=theman --account-pass=password --site-name="Drupal8" --site-mail=brent@variantstudios.com -y
}

main $@