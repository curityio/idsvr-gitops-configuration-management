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

import spark.Spark.before
import spark.Spark.exception
import spark.Spark.port
import spark.Spark.post

/*
 * An API to integrate with GitHub via its API
 */
fun main() {

    // Create global objects at startup
    val configuration = Configuration()
    val controller = ApiController(configuration)

    port(configuration.getPortNumber())

    post("/configuration/pull-requests", controller::createPullRequest)

    before({ _, response -> response.type("application/json") })
    exception(Exception::class.java, CustomExceptionHandler())
}
