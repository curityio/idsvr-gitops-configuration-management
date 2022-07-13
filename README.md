# Automated Configuration Management

Demonstrates how to save configuration commits made in the Admin UI to a Git repository.

## Prerequisites

First ensure that Docker is installed.\
Also copy a `license.json` file for the Curity Identity Server to the `idsvr` folder.

## Deploy the System

Run the following command to deploy the Curity Identity Server with configuration for a Staging environment:

```bash
.deploy.sh STAGING
```

## Run the Admin UI

Under `Profiles / Token Service / Clients`, edit the web-client.\
Then commit changes and add a useful comment.

## Git Automated Update

The deployed `git-config-updater` script on the Admin node of the Identity Server is invoked.\
This calls a configured Git repo to save changes and add a pull request.