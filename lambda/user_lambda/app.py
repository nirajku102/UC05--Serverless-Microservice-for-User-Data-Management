import os
import json
import boto3
from boto3.dynamodb.conditions import Key

# Initialize DynamoDB resource
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['USERS_TABLE'])

def lambda_handler(event, context):
    try:
        # Extract HTTP method from the event
        http_method = event['requestContext']['http']['method']

        if http_method == 'POST':
            # Create User
            body = json.loads(event['body'])
            user_id = body.get('id')
            name = body.get('name')
            email = body.get('email')

            if not user_id or not name or not email:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'message': 'Missing required fields'})
                }

            # Insert user into DynamoDB
            table.put_item(Item={
                'id': user_id,
                'name': name,
                'email': email
            })

            return {
                'statusCode': 201,
                'body': json.dumps({'message': 'User created successfully'})
            }

        elif http_method == 'GET':
            # Retrieve User
            user_id = event['queryStringParameters'].get('id')

            if not user_id:
                return {
                    'statusCode': 400,
                    'body': json.dumps({'message': 'User ID is required'})
                }

            # Fetch user from DynamoDB
            response = table.get_item(Key={'id': user_id})

            if 'Item' in response:
                return {
                    'statusCode': 200,
                    'body': json.dumps(response['Item'])
                }
            else:
                return {
                    'statusCode': 404,
                    'body': json.dumps({'message': 'User not found'})
                }

        else:
            return {
                'statusCode': 405,
                'body': json.dumps({'message': 'Method not allowed'})
            }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal server error'})
        }