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

import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

/*
 * An API to interact with Git and create a pull request when configuration changes
 */
@RestController
@RequestMapping(value = ["configuration"])
class ApiController(private val configuration: Configuration) {

    /*
     * Receive data from the Identity Server, then call GitHub to trigger a pull request
     */
    @PostMapping(value = ["/pull-requests"])
    suspend fun createPullRequest(@RequestBody(required = true) body: PullRequestInput): PullRequestOutput {

        val client = GitHubApiClient(configuration)
        val info = client.createAutomatedPullRequest(body.stage, body.message, body.data)
        return PullRequestOutput(info)
    }
}
