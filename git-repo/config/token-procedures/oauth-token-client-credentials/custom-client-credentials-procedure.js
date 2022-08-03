/**
 * @param {se.curity.identityserver.procedures.context.ClientCredentialsTokenProcedureContext} context
 */
 function result(context) {
    
    logger.info("*** Custom Javascript logic would go here ***")

    var delegationData = context.getDefaultDelegationData();
    var issuedDelegation = context.delegationIssuer.issue(delegationData);

    var accessTokenData = context.getDefaultAccessTokenData();
    var issuedAccessToken = context.accessTokenIssuer.issue(accessTokenData, issuedDelegation);

    return {
        scope: accessTokenData.scope,
        access_token: issuedAccessToken,
        token_type: 'bearer',
        expires_in: secondsUntil(accessTokenData.exp)
    };
}