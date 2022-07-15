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

class GitHubApiClient(private val configuration: Configuration) {

    @Suppress("UNUSED_PARAMETER")
    fun createPullRequest(stage: String, message: String, data: String): String {
        
        // TODO: use API commands as described here:
        // https://www.softwaretestinghelp.com/github-rest-api-tutorial/

        return "API created GitHub pull request for $stage commit: $message"
    }
}
