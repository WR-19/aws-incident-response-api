import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    try:
        response = table.put_item(
            Item={
                "id": context.aws_request_id,
                "message": "Hello from Lambda"
            }
        )
        return {
            "statusCode": 200,
            "body": json.dumps("Success")
        }
    except Exception as e:
        print("ERROR:", str(e))
        return {
            "statusCode": 500,
            "body": json.dumps("Failure")
        }
