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
import spark.Request
import spark.Response

/*
 * An API to interact with Git and create a pull request when configuration changes
 */
class ApiController(private val configuration: Configuration) {

    /*
     * Receive data from the Curity Identity Server, then call GitHub to trigger a pull request
     */
    @Suppress("UNUSED_PARAMETER")
    fun createPullRequest(request: Request, response: Response): String {

        val mapper = ObjectMapper()
        
        val body = request.body()
        if (!body.isEmpty()) {
            
            val requestData = mapper.readValue(body, ObjectNode::class.java)
            
            val id = requestData.get("id").asText();
            val message = requestData.get("message").asText();
            val base64config = requestData.get("data").asText();
            println("API successfully GIT details and will create a pull request")
        }
        
        val responseData = mapper.createObjectNode()
        responseData.put("done", "DONE")
        return responseData.toString()
    }
}
