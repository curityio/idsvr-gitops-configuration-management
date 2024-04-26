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

import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.context.annotation.Configuration

/*
 * A simple configuration class that reads the application.properties file
 */
@Configuration
@ConfigurationProperties()
open class Configuration {

    private var basicAuthenticationUserName: String = ""
    private var basicAuthenticationPassword: String = ""
    private var gitHubBaseUrl: String = ""
    private var gitHubUserAccount: String = ""
    private var gitHubAccessToken: String = ""
    private var gitHubRepositoryName: String = ""

    fun getBasicAuthenticationUserName(): String {
        return basicAuthenticationUserName
    }

    fun setBasicAuthenticationUserName(value: String) {
        basicAuthenticationUserName = value
    }

    fun getBasicAuthenticationPassword(): String {
        return basicAuthenticationPassword
    }

    fun setBasicAuthenticationPassword(value: String) {
        basicAuthenticationPassword = value
    }

    fun getGitHubBaseUrl(): String {
        return gitHubBaseUrl
    }

    fun setGitHubBaseUrl(value: String) {
        gitHubBaseUrl = value
    }

    fun getGitHubUserAccount(): String {
        return gitHubUserAccount
    }

    fun setGitHubUserAccount(value: String) {
        gitHubUserAccount = value
    }

    fun getGitHubAccessToken(): String {
        return gitHubAccessToken
    }

    fun setGitHubAccessToken(value: String) {
        gitHubAccessToken = value
    }

    fun getGitHubRepositoryName(): String {
        return gitHubRepositoryName
    }

    fun setGitHubRepositoryName(value: String) {
        gitHubRepositoryName = value
    }
}
