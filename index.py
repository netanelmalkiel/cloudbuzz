import json
import boto3


operator = "add"

def lambda_handler(event,context):
    first_num = int(event['queryStringParameters']['first_num'])
    second_num = int(event['queryStringParameters']['second_num'])
    message = {"this is a message from sns": "everything works"}
    client = boto3.client('sns')
    response = client.publish(
        TargetArn='arn:aws:sns:us-east-1:807967462364:topic-calc',
        Message=json.dumps({'default': json.dumps(message)}),
        MessageStructure='json'
    )
    return {
        'statusCode': 200,
        'body': json.dumps(calc(first_num,second_num,operator))
    }


def calc(first_num, second_num, operator):
    result = int(first_num + second_num)

    return result