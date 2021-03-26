from __future__ import print_function

import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)
 
def handler(event, context):
    logger.info(event)
    ##print("Received event: " + json.dumps(event, indent=2))

    operation = event['operation']

    if 'tableName' in event:
        dynamo = boto3.resource('dynamodb').Table("persons")
    
    # return {
    #     'statusCode': 200,
    #     'body': datetime.now().isoformat()
    # }
    operations = {
        'create': lambda x: dynamo.put_item(**x),
        'read': lambda x: dynamo.get_item(**x),
        'delete': lambda x: dynamo.delete_item(**x),
        'echo': lambda x: x,
        'ping': lambda x: 'pong'
    }
    personDict = (operations['read'](event.get('payload')))
    #return personDict
    if (len(personDict))>0 :
        #something
        jsonStr=json.dumps(personDict)
        js=json.loads(jsonStr)
        if "Item" in js:
            j=json.loads(json.dumps(js["Item"]))
            return "Welcome Back, " + j["personId"]
        else:
            
            payloadstr= json.dumps( event.get('payload') )
            payjs = json.loads(payloadstr)
            keystr = json.dumps(payjs['Key'])
            personstr=json.loads(keystr)['personId']
            thisdict = {
                "Item": {
                      "personId": personstr
                    }
            }
            operations['create'](thisdict)
            return "Hello " +json.loads(keystr)['personId']
    else:
        #operations['create'](event.get('payload'))
        return "Hello " + event.get('payload')