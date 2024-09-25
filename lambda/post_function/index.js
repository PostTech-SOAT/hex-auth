const AWS = require('aws-sdk');
const cognito = new AWS.CognitoIdentityServiceProvider();

exports.handler = async (event) => {
  const body = JSON.parse(event.body);
  const { email, cpf, name } = body;
  const userPoolId = process.env.USER_POOL_ID;

  try {
    const params = {
      UserPoolId: userPoolId,
      Username: email,
      UserAttributes: [
        {
          Name: 'email',
          Value: email
        },
        {
          Name: 'custom:cpf',
          Value: cpf
        },
        {
          Name: 'name',
          Value: name
        }
      ]
    };

    const data = await cognito.adminCreateUser(params).promise();

    return {
      statusCode: 200,
      body: JSON.stringify({
        message: 'User created successfully',
        user: data
      })
    };
  } catch (error) {
    if (error.code === 'UsernameExistsException') {
      return {
        statusCode: 400,
        body: JSON.stringify({ message: 'User already exists' })
      };
    }

    return {
      statusCode: 500,
      body: JSON.stringify({ message: 'Error creating user', error: error.message })
    };
  }
};
