# A Kotlin API to call GitHub APIs

A utility API with some code to create a GitHub pull request with changed configuration data.

## API Interface

The API is called at `POST /configuration/pull-requests` with a payload containing parts of the configuration.\
This request is triggered from a post commit hook in the Curity Identity Server:

```json
{
  "stage": "DEV",
  "message": "My configuration edit message typed into the Admin UI",
  "environments": "...",
  "profiles": "...",
  "facilities": "...",
  "processing": "...",
  "nacm": "...",
  "aaa": "...",
}
```

## Setup

You need to create a GitHub repo for your user account.\
Then update the `src/main/resources/application.properties` folder:

```text
server.port=3000
basicAuthenticationUserName=idsvr
basicAuthenticationPassword=idsvr-secret-1
githubBaseUrl=https://api.github.com
githubUserAccount=
githubAccessToken=
githubRepositoryName=idsvr-configuration-store
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
- Commits the configuration XML on that branch
- Creates a pull request to merge to the main branch
