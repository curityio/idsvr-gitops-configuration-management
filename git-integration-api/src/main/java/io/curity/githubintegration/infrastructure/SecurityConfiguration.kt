package io.curity.githubintegration.infrastructure

import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.security.config.annotation.web.builders.HttpSecurity
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity
import org.springframework.security.config.http.SessionCreationPolicy
import org.springframework.security.core.userdetails.User
import org.springframework.security.core.userdetails.UserDetailsService
import org.springframework.security.provisioning.InMemoryUserDetailsManager
import org.springframework.security.web.SecurityFilterChain

@Configuration
@EnableWebSecurity
open class SecurityConfiguration(private val configuration: io.curity.githubintegration.Configuration) {

    @Bean
    @Throws(Exception::class)
    open fun filterChain(http: HttpSecurity): SecurityFilterChain? {

        http
            .antMatcher("/**")
            .authorizeHttpRequests { authorize ->
                authorize.anyRequest().authenticated()
            }
            .httpBasic { it.authenticationEntryPoint(AuthenticationFailedHandler()) }
            .csrf().disable()
            .sessionManagement()
                .sessionCreationPolicy(SessionCreationPolicy.STATELESS);

        return http.build()
    }

    @Bean
    open fun userDetailsService(): UserDetailsService {

        val user = User.withDefaultPasswordEncoder()
            .username(configuration.getBasicAuthenticationUserName())
            .password(configuration.getBasicAuthenticationPassword())
            .roles("USER")
            .build()

        val manager = InMemoryUserDetailsManager()
        manager.createUser(user)
        return manager
    }

}