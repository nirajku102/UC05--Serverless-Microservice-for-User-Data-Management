import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
table_name = os.environ['USERS_TABLE']
table = dynamodb.Table(table_name)

def lamda_handler(event, context):
    try:
        user_id = event['pathParameters'] ['user_id']
    except KeyError:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Missing user_id parameter'})
        }

    try:response = table.get_item(key={'user_id: user_id'})
    if 'Item' not in response:
        return {
            'statusCode': 404,
            'body': json.dumps({'error': 'User not found'})
        }

    return {
        'statusCode': 200,
        'body': json.dumpd(response['Item'])
    }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }


