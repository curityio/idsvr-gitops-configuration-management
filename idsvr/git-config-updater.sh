#!/bin/bash

###########################################################################################
# Runs on the Admin node of the Curity Identity Server when there is a configuration change
# This invokes a REST call to a Git repo to check in the configuration file on a branch
# A pull request is then created, so that changes can be reviewed
###########################################################################################

#
# Ensure that we are running from a known location, in the script folder
#
cd "$(dirname "${BASH_SOURCE[0]}")"

#
# Use the shell to get the configuration as XML
#
idsh <<< "show configuration | display xml" > /tmp/config-backup.xml
echo '****** DEBUG FILE ******' >/tmp/debug

#
# Also get the last commit comment to include in the Git checkin
# Avoid writing this when the server starts up
#

#
# I could use the GitHub API with a personal access token, but code would come out pretty complicated
# Speak to Daniel to see if a Java plugin is possible?
# https://stackoverflow.com/questions/68071992/how-to-commit-a-folder-and-open-a-pull-request-via-github-api
#
