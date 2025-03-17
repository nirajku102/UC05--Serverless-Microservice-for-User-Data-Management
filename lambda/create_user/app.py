import json
import os
import uuid
import boto3

dynamodb = boto3.resource('dynamodb')
table_name = os.environ['USERS_TABLE']
table = dynamodb.Table(table_name)

def lambda_handler(event, context):
    try:
        user_data = json.loads(event['body'])
    except:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Invalid request body'})
        }

    user_id = str(uuid.uuid4())

    item = {
        'user_id': user_id,
        'name': user_data['name'],
        'email': user_data['email']
    }
    
    try:
        table.put_item(Item=item)
        return {
            'statusCode': 200,
            'body': json.dumps({'user_id': user_id})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
        