provider "aws" {
    region = "${var.region}"
}
resource "aws_api_gateway_rest_api" "apigw" {
  name                     = "${var.apigw_name}"
  description              = "${var.description}"
}

resource "aws_api_gateway_resource" "main" {
  rest_api_id = "${aws_api_gateway_rest_api.apigw.id}"
  parent_id   = "${aws_api_gateway_rest_api.apigw.root_resource_id}"
  path_part   = "${var.path_part}"
}
resource "aws_api_gateway_method" "main" {
  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = var.http_method
  authorization = var.authorization
}

resource "aws_api_gateway_integration" "main" {
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_method.main.resource_id
  http_method = aws_api_gateway_method.main.http_method
  integration_http_method = var.integration_http_method
  type                    = var.integration_type
  uri                     = var.lambda_invoke_arn
}
resource "aws_api_gateway_deployment" "apigw" {
  depends_on  = [aws_api_gateway_integration.main]
  rest_api_id = aws_api_gateway_rest_api.apigw.id
  stage_name  = var.stage
}
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_deployment.apigw.execution_arn}/*/*"
}
###########################################################
resource "aws_api_gateway_method" "cors" {
  count = var.enable_cors ? 1 : 0

  rest_api_id   = aws_api_gateway_rest_api.apigw.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors" {
  count = var.enable_cors ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_method.main.resource_id
  http_method = aws_api_gateway_method.cors[0].http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

resource "aws_api_gateway_integration_response" "cors" {
  count = var.enable_cors ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_method.main.resource_id
  http_method = aws_api_gateway_method.cors[0].http_method

  status_code         = 200
  response_parameters = {
    "method.response.header.Content-Type"                 = "'application/json'",
    "method.response.header.Access-Control-Allow-Origin"  = "'${var.cors_origin}'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST, GET, OPTIONS, PUT, DELETE'",
    "method.response.header.Access-Control-Allow-Headers" = "'Accept, Content-Type, Content-Length, Accept-Encoding, Authorization'",
  }

  depends_on = [
    aws_api_gateway_integration.cors,
    aws_api_gateway_method_response.cors,
  ]
}

resource "aws_api_gateway_method_response" "cors" {
  count = var.enable_cors ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.apigw.id
  resource_id = aws_api_gateway_method.main.resource_id
  http_method = aws_api_gateway_method.cors[0].http_method

  status_code         = 200
  response_parameters = {
    "method.response.header.Content-Type"                 = true,
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true,
  }

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [aws_api_gateway_method.cors]
}
