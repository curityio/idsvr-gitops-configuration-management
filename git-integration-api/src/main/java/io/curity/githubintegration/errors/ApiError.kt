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

package io.curity.githubintegration.errors

/*
 * A simple error class
 */
class ApiError(val statusCode: Int, val errorCode: String, message: String, cause: Throwable? = null): RuntimeException(message, cause) {
    var details: String = ""

    fun logInfo(): String {

        val data = mutableListOf<String>()
        data.add("$statusCode")
        data.add(errorCode)

        val baseMessage = message
        if (!baseMessage.isNullOrBlank()) {
            data.add(baseMessage)
        }

        if (details.isNotBlank()) {
            data.add(details)
        }

        val baseCause = cause
        if (statusCode == 500 && baseCause != null) {
            data.add(baseCause.stackTraceToString())
        }

        return data.joinToString()
    }
}
