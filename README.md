# GitOps Configuration Management

Demonstrates some advanced techniques for managing configuration for the Curity Identity Server.\
This provides a secure and maintainable setup that avoids duplication, with reliable change management.\
It also eliminates most risk when adding new environments to your deployment pipeline.

## Prerequisites

To run the end-to-end setup ensure that these tools are installed locally:

- [Docker](https://www.docker.com/products/docker-desktop) to deploy the system
- [xmlstarlet](http://xmlstar.sourceforge.net/) to run a migration script that parses XML
- [openssl](https://www.openssl.org/source/) to run crypto operations later

You will also need a `license.json` file for the Curity Identity Server.

## Documentation

The following resources explain the concepts and automation in further detail:

- [Configuration Best Practices](https://curity.io/resources/learn/configuration-best-practices)
- [GitOps Configuration Tutorial](https://curity.io/resources/learn/gitops-configuration-management)

## Overview

### First Deployment

Run the first deployment, which performs auto-configuration to provide a working system.\
This also creates a configuration encryption key.

```bash
cd initial-config
./first-deployment.sh
```

Then login to the Admin UI at https://localhost:6749/admin with credentials `admin / Password1`.\
Complete the initial setup and upload a license file.\
Under `Token Service / Clients`, create a web client and assign these values:

- A client ID of `web-client`
- A client secret
- Redirect URI and allowed origins set to `https://web.example-dev.com`
- Scopes of `openid profile`

Then select `Changes / Download` to back up the configuration to an XML file.\
Save this to `initial-config/initial-config-backup.xml`.

### Second Deployment

Then redeploy the system without running autoconfiguration.\
This will use the license file in the config backup file and the same configuration encryption key:

```bash
./second-deployment.sh
```

### Split and Parameterize the Configuration

An example split configuration is provided at `git-repo/config`, which consists of multiple XML files:

- base.xml
- environments.xml
- facilities.xml
- tokenservice.xml
- authenticationservice.xml

Next extract environment specific values from your `initial-config-backup.xml` file.\
For demo purposes this can be done by running the following script:

```bash
./migrate-configuration.sh
```

This creates the following plaintext environment data at `./github-repo/dev.env`:

```text
RUNTIME_BASE_URL='http://localhost:8443'
DB_USERNAME='SA'
WEB_BASE_URL='https://web.example-dev.com'
```

It also creates the following protected environment variables at `./vault/dev/secure.env`:

```text
ADMIN_PASSWORD='$5$uquoeYRe$GLtb4BhlI4HMAB7bScW7r6CETdFhM6DKyRoQdev3EqC'
DB_CONNECTION='data:text/plain;aes,v:S.UWVaUGR1N1JwN2JC ...'
DB_PASSWORD='data:text/plain;aes,v:S.Nzl1UGVRZklDVlNMMGRDSw==.2JiZkUjJKhlvYQoMH ...'
WEB_CLIENT_SECRET='$5$.T/sE5LWsmRoD3xb$hL7dXaOV8WEKVRZeMuPlM6oFYFD7PH1UmUUHsirjaG1'
SYMMETRIC_KEY='data:text/plain;aes,v:S.NzhhTTA3TWlHZ1BtSEJacg==.6xaTrU ...'
SSL_KEY='data:application/p12;aes,v:S.THcyaW9XUzRxakpGZzMwcQ==.MPKK96RQ9z6 ...'
SIGNING_KEY='data:application/p12;aes,v:S.bFRjcXpBY3hmSHREYXpBUg==.YdBLTdZTGlW ...'
VERIFICATION_KEY='data:application/pem;aes,v:S.YUJnaGcxT0U5MjJjdTlQZQ==.RmC3nWa6x4 ...'
```

### Run Deployment with Parameters

The example parameterized deployment requires a stage of the deployment pipeline as an input parameter.\
A Docker image is built containing the parameterized configuration and other resources.\
A license key for the Curity Identity Server is also provided as a parameter.\
The deployment uses the configuration encryption key created earlier:

```bash
export STAGE=DEV
export LICENSE_FILE_PATH=~/Desktop/license.json
./build.sh
./deploy.sh
```

In the Admin UI, edit the configuration, and add the email scope to the web client.\
Upon saving, a post commit script saves the configuration to your local `./configbackup` folder:

- The `config_params.xml` file contains the parameterized configuration
- The `config_values.xml` file contains stage specific values
- The `commit_message.txt` file contains the comment used in the Admin UI

### Implement Advanced Configuration Backup

Create a GitHub repository with the contents of the `git-repo` folder.\
Edit the `Git Integration API` and configure the `src/main/resources/application.properties` file.\
Point the utility API to your repository by entering your GitHub settings:

```bash
githubBaseUrl=https://api.github.com
githubUserAccount=
githubAccessToken=
githubRepositoryName=idsvr-configuration-store
```

Redeploy the system with additional Git parameters:

```bash
export GIT_CONFIG_BACKUP=true
export GITHUB_USER_ACCOUNT_NAME=john.doe
export STAGE=DEV
export LICENSE_FILE_PATH=~/Desktop/license.json
./build.sh
./deploy.sh
```

The post commit script then calls a utility API, which uses GitHub REST APIs to update the repo.\
This results in changes being submitted to a branch, and a pull request automatically created.\
This would enable a process where all configuration changes undergo people reviews:

![Pull Request](doc/pull-request.png)

### Create a New Environment

When configuring a new stage of the deployment pipeline, you only need to populate new environment data.\
The following script creates some crypto keys for testing, and creates a new config encryption key:

```bash
cd vault
export STAGE=STAGING
./create-development-keys.sh
```

Next generate the secure environment specific data.\
The script shows how to convert keystores and secrets to the Curity Identity Server's secure format:

```bash
export IDSVR_HOME=~/idsvr-7.3.1/idsvr
./create-secure-environment-data.sh
```

Once the environment setup is done, you can immediately deploy the new stage with a working configuration.\
You will need to add the self signed certificate generated at `/vault/staging/ssl.crt` to the system trust store.\
You can then login to the Admin UI for the new STAGING environment:

```bash
./deploy.sh
```

## Further Information

Please visit [curity.io](https://curity.io/) for more information about the Curity Identity Server.
