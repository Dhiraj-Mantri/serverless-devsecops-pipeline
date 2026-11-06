import json
import os
import time
import uuid
from decimal import Decimal

import boto3

_table = None


def get_table():
    
    global _table
    if _table is None:
        _table = boto3.resource("dynamodb").Table(os.environ["TABLE_NAME"])
    return _table




def _json_default(obj):
    # DynamoDB numbers ko Decimal deta hai, json use samajh nahi pata
    if isinstance(obj, Decimal):
        return int(obj) if obj % 1 == 0 else float(obj)
    raise TypeError


def response(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=_json_default),
    }



def create_item(event):
    try:
        data = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return response(400, {"error": "Body must be valid JSON"})

    name = data.get("name") if isinstance(data, dict) else None
    if not isinstance(name, str) or not name.strip() or len(name) > 100:
        return response(400, {"error": "'name' must be a non-empty string up to 100 characters"})

    item = {
        "id": str(uuid.uuid4()),
        "name": name.strip(),
        "created_at": int(time.time()),
    }
    get_table().put_item(Item=item)
    return response(201, item)



def list_items():
    result = get_table().scan(Limit=50)
    return response(200, result.get("Items", []))


def get_item(item_id):
    result = get_table().get_item(Key={"id": item_id})
    item = result.get("Item")
    if item is None:
        return response(404, {"error": "Item not found"})
    return response(200, item)


def handler(event, context):
    route = event.get("routeKey")
    if route == "POST /items":
        return create_item(event)
    if route == "GET /items":
        return list_items()
    if route == "GET /items/{id}":
        return get_item(event["pathParameters"]["id"])
    return response(404, {"error": "Route not found"})
