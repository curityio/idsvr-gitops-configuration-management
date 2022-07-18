/*
 *  Copyright 2022 Curity AB
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

package io.curity.githubintegration

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.node.ObjectNode
import kotlinx.coroutines.future.await
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter

/*
 * A facade for calling GitHub with some basic operations
 */
class GitHubApiClient(private val configuration: Configuration) {

    private val repoBaseUrl = "${configuration.getGitHubBaseUrl()}/repos/${configuration.getGitHubUserAccount()}/${configuration.getGitHubRepositoryName()}"

    /*
     * The entry point for creating a pull request
     */
    suspend fun createPullRequest(stage: String, message: String, data: String): String {
        
        createBranch(stage, message)

        println("API created GitHub pull request for $stage commit: $message")
        return "API created GitHub pull request for $stage commit: $message"
    }

    /*
     * First create a branch where the configuration update will be saved
     */
    private suspend fun createBranch(stage: String, message: String) {

        // Get the latest commit on the main branch
        val getLatestCommitResponse = callApi("GET", "/commits/main", null)
        val commitSha = readResponseStringField(getLatestCommitResponse,"sha")

        // Create a new branch for the current date
        val formatter = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss").withZone(ZoneId.from(ZoneOffset.UTC));
        val formattedTime = formatter.format(Instant.now())
        val branchName = "$stage-configuration-update-$formattedTime)"
        val mapper = ObjectMapper()
        val createBranchRequest = mapper.createObjectNode()
        createBranchRequest.put("ref", "refs/heads/$branchName")
        createBranchRequest.put("sha", commitSha)
        val createBranchResponse = callApi("POST", "/git/refs", createBranchRequest.toString())
    }

    /*
     * First create a branch for the pull request
     */
    private suspend fun saveConfigurationToBranch() {
    }

    /*
     * Do the work of calling the API with the Java 11+ async HTTP Client
     */
    private suspend fun callApi(method: String, path: String, data: String?): ObjectNode
    {
        val operationUrl = "$repoBaseUrl$path"

        var bodyPublisher = HttpRequest.BodyPublishers.noBody()
        if (data != null) {
            bodyPublisher = HttpRequest.BodyPublishers.ofString(data)
        }

        println("*** CALLING $operationUrl")
        val requestBuilder = HttpRequest.newBuilder()
            .method(method, bodyPublisher)
            .uri(URI(operationUrl))
            .headers("Authorization", "Bearer ${configuration.getGitHubAccessToken()}")

        val request = requestBuilder.build()
        val client = HttpClient.newBuilder()
            .build()

        return client.sendAsync(request, HttpResponse.BodyHandlers.ofString()).handle(this::processResponse).await()
    }

    /*
     * Handle the response and any response errors
     */
    private fun processResponse(response: HttpResponse<String>?, ex: Throwable?): ObjectNode {

        if (ex != null) {
            ex.printStackTrace()
            throw RuntimeException(ex)
        }

        if (response == null) {
            throw RuntimeException("Connection error calling GitHub")
        }

        if (response.statusCode() > 400) {
            println("*** ERROR RESPONSE RECEIVED")
            println(response.body())
            throw RuntimeException("GitHub returned status code 400 or above")
        }

        println("*** SUCCESS RESPONSE RECEIVED")
        println(response.body())
        return ObjectMapper().readValue(response.body(), ObjectNode::class.java)
    }

    /*
     * Safely read a string from the response
     */
    private fun readResponseStringField(data: ObjectNode, fieldName: String): String {

        val node = data.get(fieldName) ?: throw RuntimeException("Missing response field for $fieldName")
        return node.asText()
    }
}
