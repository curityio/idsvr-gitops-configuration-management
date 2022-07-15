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
import spark.ExceptionHandler
import spark.Request
import spark.Response

class CustomExceptionHandler: ExceptionHandler<Exception> {

    override fun handle(caught: Exception?, request: Request?, response: Response?) {

        println("API problem encountered")
        caught?.printStackTrace();

        val mapper = ObjectMapper()
        val data = mapper.createObjectNode()

        data.put("code", "problem_encountered")
        data.put("message", caught?.message)

        response?.status(500)
        response?.header("content-type", "application/json")
        response?.body(data.toString())
    }
}