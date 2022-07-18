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

import kotlinx.coroutines.future.await
import java.net.URI
import java.net.http.HttpClient
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

class GitHubApiClient(private val configuration: Configuration) {

    /*
     * The entry point for creating a pull request
     */
    suspend fun createPullRequest(stage: String, message: String, data: String): String {
        
        println("API created GitHub pull request for $stage commit: $message")
        val result = callApi("GET", "https://www.google.co.uk")
        println("RECEIVED RESPONSE")

        return "API created GitHub pull request for $stage commit: $message"
    }

    // TODO: use API commands as described here:
    // https://www.softwaretestinghelp.com/github-rest-api-tutorial/

    /*
     * Do the work of calling the API with the Java 11+ async HTTP Client
     */
    private suspend fun callApi(method: String, url: String): String
    {
        // val operationUrl = "${configuration.getGitHubBaseUrl()}/$path"

        val requestBuilder = HttpRequest.newBuilder()
            .method(method, HttpRequest.BodyPublishers.noBody())
            .uri(URI(url))
            .headers("Authorization", String.format("Bearer %s", configuration.getGitHubAccessToken()))

        val request = requestBuilder.build()
        val client = HttpClient.newBuilder()
            .build()

        return client.sendAsync(request, HttpResponse.BodyHandlers.ofString()).handle(this::processResponse).await()
    }

    /*
     * Handle the response and any response errors
     */
    private fun processResponse(response: HttpResponse<String>?, ex: Throwable?): String {

        if (ex != null) {
            ex.printStackTrace()
            throw RuntimeException(ex)
        }

        if (response == null) {
            throw RuntimeException("Connection error calling GitHub")
        }

        if (response.statusCode() > 400) {
            throw RuntimeException("GitHub returned status code 400 or above")
        }

        return response.body()
    }
}
