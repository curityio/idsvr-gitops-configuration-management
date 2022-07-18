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

import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest
import java.net.http.HttpResponse
import java.time.Instant
import java.time.ZoneId
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlinx.coroutines.future.await
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.node.ArrayNode
import com.fasterxml.jackson.databind.node.ObjectNode

/*
 * A facade for calling GitHub with some example operations
 */
class GitHubApiClient(private val configuration: Configuration) {

    private val repoBaseUrl = "${configuration.getGitHubBaseUrl()}/repos/${configuration.getGitHubUserAccount()}/${configuration.getGitHubRepositoryName()}"
    private val mainBranchName = "main"

    /*
     * The entry point for creating a pull request
     */
    suspend fun createAutomatedPullRequest(stage: String, message: String, data: String): String {

        // Create the branch
        val formatter = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss").withZone(ZoneId.from(ZoneOffset.UTC));
        val formattedTime = formatter.format(Instant.now())
        val branchName = "${stage.lowercase(Locale.getDefault())}-configuration-update-$formattedTime"

        // Do the GitHub work
        createBranch(branchName)
        commitConfigurationChanges(branchName, message, data)
        val pullRequestUrl = createPullRequest(branchName, message)

        // Log and return some info
        val info = "API successfully created GitHub pull request: $pullRequestUrl"
        println(info)
        return info
    }

    /*
     * Create a branch where the configuration update will be saved
     */
    private suspend fun createBranch(branchName: String) {

        // Get the latest commit on the main branch
        val getLatestCommitResponse = callApi("GET", "$repoBaseUrl/commits/$mainBranchName", null)
        val currentHead = readResponseStringField(getLatestCommitResponse,"sha")

        // Create a branch from this commit
        val mapper = ObjectMapper()
        val createBranchRequest = mapper.createObjectNode()
        createBranchRequest.put("ref", "refs/heads/$branchName")
        createBranchRequest.put("sha", currentHead)
        callApi("POST", "$repoBaseUrl/git/refs", createBranchRequest.toString())
    }

    /*
     * Commit changes to the branch, which is quite complicated with the GitHub API and explained here:
     * https://www.levibotelho.com/development/commit-a-file-with-the-github-api/
     */
    private suspend fun commitConfigurationChanges(branchName: String, message: String, data: String) {

        // Step 1: Get the current head on the branch
        val getCurrentHeadResponse = callApi("GET", "$repoBaseUrl/git/ref/heads/$branchName", null)
        val currentHeadObjectNode = readResponseObjectField(getCurrentHeadResponse, "object")
        val currentHeadUrl = readResponseStringField(currentHeadObjectNode, "url")

        // Step 2: Get the current commit that head points to
        val getCurrentCommitResponse = callApi("GET", currentHeadUrl, null)
        val lastCommitSha = readResponseStringField(getCurrentCommitResponse,"sha")
        val lastCommitTreeNode = readResponseObjectField(getCurrentCommitResponse, "tree")
        val lastCommitTreeUrl = readResponseStringField(lastCommitTreeNode,"url")

        // Step 3. Create a blob containing a base 64 representation of the Curity Identity Server configuration
        val mapper = ObjectMapper()
        val createBlobPayload = mapper.createObjectNode()
        createBlobPayload.put("content", data)
        createBlobPayload.put("encoding", "base64")
        val createBlobResponse = callApi("POST", "$repoBaseUrl/git/blobs", createBlobPayload.toString())
        val blobSha = readResponseStringField(createBlobResponse, "sha")

        // Step 4: Get the tree sha of the last commit
        val getTreeResponse = callApi("GET", lastCommitTreeUrl, null)
        val treeSha = readResponseStringField(getTreeResponse,"sha")

        // Step 5a: Create a new tree with the files to update
        val createTreePayload = mapper.createObjectNode()
        val filesToUpdate = mapper.createArrayNode()
        val fileToUpdate = mapper.createObjectNode()
        fileToUpdate.put("path", "parameterized-config-backup.xml")
        fileToUpdate.put("mode", "100644")
        fileToUpdate.put("type", "blob")
        fileToUpdate.put("sha", blobSha)
        filesToUpdate.add(fileToUpdate)
        createTreePayload.put("base_tree", treeSha)
        createTreePayload.set<ArrayNode>("tree", filesToUpdate)
        val createTreeResponse = callApi("POST","$repoBaseUrl/git/trees", createTreePayload.toString())
        val newTreeSha = readResponseStringField(createTreeResponse,"sha")

        // Step 6: Create a commit for the tree
        val createCommitPayload = mapper.createObjectNode()
        createCommitPayload.put("message", message)
        val parents = mapper.createArrayNode()
        parents.add(lastCommitSha)
        createCommitPayload.set<ArrayNode>("parents", parents)
        createCommitPayload.put("tree", newTreeSha)
        val createCommitResponse = callApi("POST","$repoBaseUrl/git/commits", createCommitPayload.toString())
        val commitSha =  readResponseStringField(createCommitResponse, "sha")

        // Step 7: Update HEAD on the branch to point to the commit
        val updateHeadPayload = mapper.createObjectNode()
        updateHeadPayload.put("sha", commitSha)
        updateHeadPayload.put("force", true)
        callApi("POST","$repoBaseUrl/git/refs/heads/$branchName", updateHeadPayload.toString())
    }

    /*
     * Create a pull request to commit the branch to the main branch and return its URL
     */
    private suspend fun createPullRequest(branchName: String, message: String): String {

        val mapper = ObjectMapper()
        val pullRequestPayload = mapper.createObjectNode()
        pullRequestPayload.put("title", message)
        pullRequestPayload.put("head", branchName)
        pullRequestPayload.put("base", mainBranchName)
        val pullRequestResponse = callApi("POST","$repoBaseUrl/pulls", pullRequestPayload.toString())
        return readResponseStringField(pullRequestResponse, "html_url")
    }

    /*
     * Do the work of calling the API with the Java 11+ async HTTP Client
     */
    private suspend fun callApi(method: String, operationUrl: String, data: String?): ObjectNode
    {
        var bodyPublisher = HttpRequest.BodyPublishers.noBody()
        if (data != null) {
            bodyPublisher = HttpRequest.BodyPublishers.ofString(data)
        }

        val requestBuilder = HttpRequest.newBuilder()
            .method(method, bodyPublisher)
            .uri(URI(operationUrl))
            .headers("Accept", "application/vnd.github+json")
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

        return ObjectMapper().readValue(response.body(), ObjectNode::class.java)
    }

    /*
     * Safely read an object node string from a GitHub response
     */
    private fun readResponseObjectField(data: ObjectNode, fieldName: String): ObjectNode {

        return data.get(fieldName) as ObjectNode
    }

    /*
     * Safely read a string from a GitHub response
     */
    private fun readResponseStringField(data: ObjectNode, fieldName: String): String {

        val node = data.get(fieldName) ?: throw RuntimeException("Missing response field for $fieldName")
        return node.asText()
    }
}
