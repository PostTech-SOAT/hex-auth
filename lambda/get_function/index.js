const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();

exports.handler = async (event) => {
  const cpf = event.cpf;

  if (!cpf) {
    return {
      statusCode: 400,
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ message: 'CPF is missing' })
    };
  }

  const userPoolId = process.env.USER_POOL_ID;
  const params = {
    UserPoolId: userPoolId,
    Username: cpf
  };
  try {
    const data = await cognito.adminGetUser(params).promise();
    const nameAttribute = data.UserAttributes.find(attr => attr.Name === 'name');
    const name = nameAttribute.Value;

    return {
      statusCode: 200,
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ message: `User found: ${name}` })
    };

  } catch (error) {
    if (error.code === 'UserNotFoundException') {
      return {
        statusCode: 404,
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ message: 'Usuário não encontrado. Deseja cadastrar e aproveitar nossas promoções?' })
      };
    } else {
      return {
        statusCode: 500,
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ message: 'Error retrieving user', error: error.message })
      };
    }
  }
};
