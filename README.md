# GitOps Identity Server Configuration Management

Demonstrates a method to automate updates to a Git repo when Identity Server configuration changes.

## Prerequisites

First ensure that Docker is installed.\
Also copy a `license.json` file for the Curity Identity Server to the `idsvr` folder.

## Deploy the System

Run the following command to deploy the Curity Identity Server with configuration for a Staging environment:

```bash
./build.sh
.deploy.sh STAGING
```

## Run the Admin UI

Under `Profiles / Token Service / Clients`, edit the web-client.\
Then commit changes and add a useful comment.

## Post Commit Scripts

A `post-commit-trigger-pull-request.sh` script runs on the Admin node of the Identity Server.\
This calls a utility API with a JSON payload to submit the latest changes and the Admin UI comment.

## Git Integration API

A small utility API does the work of creating a GitHub pull request.\
This uses GitHub's REST API to create the necessary resources.