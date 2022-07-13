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
# Use /opt/idsvr/bin/status techniques in the Helm config backup, which saves to the Kubernetes secrets API
# Check server is healthy, to avoid an initial backup when the server starts
# Also get the latest transaction ID and checkin comment if possible
#

#
# I could use the GitHub API with a personal access token, but code would come out pretty complicated
# https://stackoverflow.com/questions/68071992/how-to-commit-a-folder-and-open-a-pull-request-via-github-api
#
