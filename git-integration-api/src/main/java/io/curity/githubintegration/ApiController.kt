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

import io.curity.githubintegration.infrastructure.ApiError
import io.curity.githubintegration.infrastructure.ApiExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.slf4j.LoggerFactory
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

/*
 * An API to interact with Git and create a pull request when configuration changes
 */
@RestController
@RequestMapping(value = ["configuration"])
open class ApiController(private val configuration: Configuration) {

    /*
     * Receive data from the Identity Server, then call GitHub to trigger a pull request
     */
    @PostMapping(value = ["/pull-requests"])
    fun createPullRequest(@RequestBody(required = true) body: PullRequestInput): ResponseEntity<PullRequestOutput> {

        // Do the lengthy work in an async task
        CoroutineScope(Dispatchers.IO).launch {

            val logger = LoggerFactory.getLogger(ApiController::class.java)
            try {

                logger.info("API is creating pull request: ${body.message}")
                val client = GitHubApiClient(configuration)
                val pullRequestUrl = client.createAutomatedPullRequest(body.stage, body.message, body.data)
                logger.info("API successfully created pull request at: $pullRequestUrl")

            } catch (ex: ApiError) {
                ApiExceptionHandler().handleException(ex)
            }
        }

        // Return a 202 accepted response to the admin node of the Identity Server
        return ResponseEntity(
            PullRequestOutput("API is creating pull request: ${body.message}"),
            HttpStatus.ACCEPTED)
    }
}
