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

import java.util.Properties
import org.springframework.context.annotation.Configuration

/*
 * A simple configuration class that reads the application.properties file
 */
@Configuration
open class Configuration {

    private val properties = Properties()

    init {
        val inputStream = this.javaClass.getResourceAsStream("/application.properties")
        inputStream.use {
            properties.load(inputStream)
        }
    }

    fun getGitHubBaseUrl(): String {
        return properties.getProperty("githubBaseUrl")
    }

    fun getGitHubUserAccount(): String {
        return properties.getProperty("githubUserAccount")
    }

    fun getGitHubAccessToken(): String {
        return properties.getProperty("githubAccessToken")
    }

    fun getGitHubRepositoryName(): String {
        return properties.getProperty("githubRepositoryName")
    }
}
