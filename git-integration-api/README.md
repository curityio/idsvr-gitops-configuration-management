# A Kotlin API to call GitHub APIs

A utility API with some code to create a GitHub pull request with changed configuration data.

## API Interface

The API is called at `POST /configuration/pull-requests` with a payload containing parts of the configuration.\
This request is triggered from a post commit hook in the Curity Identity Server:

```json
{
  "stage": "DEV",
  "message": "My configuration edit message typed into the Admin UI",
  "params": "...",
  "values": "..."
}
```

## Setup

You need to create a GitHub repo for your user account.\
Then update the values in the `src/main/resources/application.properties` file or add environment variables:

```text
export SERVER_PORT='3000'
export BASIC_AUTHENTICATION_USER_NAME='idsvr'
export BASIC_AUTHENTICATION_PASSWORD='idsvr-secret-1'
export GITHUB_BASE_URL='https://api.github.com'
export GITHUB_USER_ACCOUNT=''
export GITHUB_ACCESS_TOKEN=''
export GITHUB_REPOSITORY_NAME='idsvr-configuration-store'
```

## Run the API

Execute the following command to run the Git Integration API locally:

```bash
./gradlew bootRun
```

Test it with this command, using a backed up request payload:

```bash
./test/testclient.sh
```

## GitHub REST API Actions

The API's GitHubClient class then performs these steps:

- Creates a branch
- Commits the configuration XML and environment changes on that branch
- Creates a pull request to merge to the main branch
