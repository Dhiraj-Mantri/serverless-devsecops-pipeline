import json
from unittest.mock import MagicMock, patch

import app


def make_event(route, body=None, path_params=None):
    return {
        "routeKey": route,
        "body": json.dumps(body) if body is not None else None,
        "pathParameters": path_params,
    }




@patch("app.get_table")
def test_create_item_success(mock_get_table):
    table = MagicMock()
    mock_get_table.return_value = table

    resp = app.handler(make_event("POST /items", {"name": "first"}), None)

    assert resp["statusCode"] == 201
    assert json.loads(resp["body"])["name"] == "first"
    table.put_item.assert_called_once()


@patch("app.get_table")
def test_create_item_rejects_missing_name(mock_get_table):
    resp = app.handler(make_event("POST /items", {"other": "x"}), None)
    assert resp["statusCode"] == 400


@patch("app.get_table")
def test_create_item_rejects_bad_json(mock_get_table):
    event = {"routeKey": "POST /items", "body": "{not json"}
    assert app.handler(event, None)["statusCode"] == 400




@patch("app.get_table")
def test_list_items(mock_get_table):
    table = MagicMock()
    table.scan.return_value = {"Items": [{"id": "1", "name": "a"}]}
    mock_get_table.return_value = table

    resp = app.handler(make_event("GET /items"), None)

    assert resp["statusCode"] == 200
    assert len(json.loads(resp["body"])) == 1


@patch("app.get_table")
def test_get_item_found(mock_get_table):
    table = MagicMock()
    table.get_item.return_value = {"Item": {"id": "1", "name": "a"}}
    mock_get_table.return_value = table

    resp = app.handler(make_event("GET /items/{id}", path_params={"id": "1"}), None)
    assert resp["statusCode"] == 200


@patch("app.get_table")
def test_get_item_not_found(mock_get_table):
    table = MagicMock()
    table.get_item.return_value = {}
    mock_get_table.return_value = table

    resp = app.handler(make_event("GET /items/{id}", path_params={"id": "nope"}), None)
    assert resp["statusCode"] == 404


def test_unknown_route():
    assert app.handler({"routeKey": "DELETE /items"}, None)["statusCode"] == 404
