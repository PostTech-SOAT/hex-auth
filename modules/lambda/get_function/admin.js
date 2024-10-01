const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();

exports.handler = async (event) => {
  const cpf = event.queryStringParameters?.cpf;

  const response = function (principalId, effect, resource) {
    let authResponse = {};
    authResponse.principalId = principalId;

    if (effect && resource) {

      let policyDocument = {};
      policyDocument.Version = '2012-10-17';
      policyDocument.Statement = [];
      let statementOne = {};
      statementOne.Action = 'execute-api:Invoke';
      statementOne.Effect = effect;
      statementOne.Resource = resource;
      policyDocument.Statement[0] = statementOne;
      authResponse.policyDocument = policyDocument;
    }
    return authResponse;
  }

  if (!cpf) {
    return response('user', 'Deny', event.methodArn);
  }

  const userPoolId = process.env.USER_POOL_ID;
  const params = {
    UserPoolId: userPoolId,
    Username: cpf
  };
  try {
    const data = await cognito.adminGetUser(params).promise();
    const isAdmin = data.UserAttributes.find(attr => attr.Name === 'custom:isadmin')['Value'];

    if (isAdmin === 'false') {
      return response('user', 'Deny', event.methodArn);
    }

    return response('user', 'Allow', event.methodArn);

  } catch (error) {
    return response('user', 'Deny', event.methodArn);
  }
};
