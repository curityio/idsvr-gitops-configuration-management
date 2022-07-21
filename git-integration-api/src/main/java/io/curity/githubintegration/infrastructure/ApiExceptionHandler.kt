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

package io.curity.githubintegration.infrastructure

import com.fasterxml.jackson.databind.ObjectMapper
import org.slf4j.LoggerFactory
import org.springframework.web.bind.annotation.ExceptionHandler
import org.springframework.web.bind.annotation.RestControllerAdvice
import javax.servlet.http.HttpServletResponse

@RestControllerAdvice
class ApiExceptionHandler {

    /*
     * Handler controller operations
     */
    @ExceptionHandler
    fun handleException(error: ApiError, response: HttpServletResponse) {

        val clientErrorPayload = handleException(error)

        response.setHeader("Content-Type", "application/json")
        response.status = error.statusCode
        response.writer.write(clientErrorPayload.toString())
    }

    /*
     * Used for both controller and worker thread exceptions
     */
    fun handleException(error: ApiError): String {

        val mapper = ObjectMapper()
        val clientErrorPayload = mapper.createObjectNode()
        clientErrorPayload.put("code", error.errorCode)
        clientErrorPayload.put("message", error.message)

        LoggerFactory.getLogger(ApiExceptionHandler::class.java).error(error.logInfo())
        return clientErrorPayload.toString()
    }
}
