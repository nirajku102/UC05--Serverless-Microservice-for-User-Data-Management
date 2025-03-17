# import json
# import os
# import uuid
# import boto3

# dynamodb = boto3.resource('dynamodb')
# table_name = os.environ['USERS_TABLE']
# table = dynamodb.Table(table_name)

# def lambda_handler(event, context):
#     http_method = event['httpMethod']
    
#     if http_method == 'POST':
#         return create_user(event)
#     elif http_method == 'GET':
#         return get_users()
#     else:
#         return {
#             'statusCode': 405,
#             'body': json.dumps({'error': 'Method Not Allowed'})
#         }

# def create_user(event):
#     try:
#         user_data = json.loads(event['body'])
#     except:
#         return {
#             'statusCode': 400,
#             'body': json.dumps({'error': 'Invalid request body'})
#         }

#     user_id = str(uuid.uuid4())

#     item = {
#         'id': user_id,  # Changed from 'user_id' to 'id'
#         'name': user_data['name'],
#         'email': user_data['email']
#     }
    
#     try:
#         table.put_item(Item=item)
#         return {
#             'statusCode': 200,
#             'body': json.dumps({'user_id': user_id})
#         }
#     except Exception as e:
#         return {
#             'statusCode': 500,
#             'body': json.dumps({'error': str(e)})
#         }

# def get_users():
#     try:
#         response = table.scan()
#         return {
#             'statusCode': 200,
#             'body': json.dumps(response['Items'])
#         }
#     except Exception as e:
#         return {
#             'statusCode': 500,
#             'body': json.dumps({'error': str(e)})
#         }

import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['USERS_TABLE'])

def lambda_handler(event, context):
    # Check if 'httpMethod' exists in the event
    if 'httpMethod' in event:
        http_method = event['httpMethod']
        if http_method == 'POST':
            # Handle POST request
            return create_user(event)
        elif http_method == 'GET':
            # Handle GET request
            return get_user(event)
        else:
            return {
                'statusCode': 405,
                'body': json.dumps('Method Not Allowed')
            }
    else:
        # Handle the case when 'httpMethod' is not present
        return {
            'statusCode': 400,
            'body': json.dumps('Bad Request: Missing httpMethod')
        }

def create_user(event):
    try:
        user_data = json.loads(event['body'])
        table.put_item(Item={
            'id': user_data['id'],
            'name': user_data['name'],
            'email': user_data['email']
        })
        return {
            'statusCode': 200,
            'body': json.dumps('User created successfully')
        }
    except KeyError as e:
        return {
            'statusCode': 400,
            'body': json.dumps(f'Missing key: {str(e)}')
        }

def get_user(event):
    user_id = event['queryStringParameters']['id']
    response = table.get_item(Key={'id': user_id})
    if 'Item' in response:
        return {
            'statusCode': 200,
            'body': json.dumps(response['Item'])
        }
    else:
        return {
            'statusCode': 404,
            'body': json.dumps('User not found')
        }