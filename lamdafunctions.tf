##################################################################################
# VARIABLES
##################################################################################

// variable "aws_access_key" {}
// variable "aws_secret_key" {}

variable "aws_dynamodb_table" {
  default = "persons"
}

variable "accountId" {
	default="590755176163"
}

##################################################################################
# PROVIDERS
##################################################################################

// provider "aws" {
  // access_key = "${var.aws_access_key}"
  // secret_key = "${var.aws_secret_key}"
  // region     = "us-west-2"
// }

data "aws_iam_group" "ec2admin" {
  group_name = "adoGroup"
}

data "aws_region" "current" {}

##################################################################################
# RESOURCES
##################################################################################
resource "aws_dynamodb_table" "terraform_datasource" {
  name           = "${var.aws_dynamodb_table}"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "personId"

  attribute {
    name = "personId"
    type = "S"
  }
}

resource "aws_iam_policy" "dynamodb-access-bydevendra" {
  name = "dynamodb-access-bydevendra"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:BatchGet*",
                "dynamodb:DescribeStream",
                "dynamodb:DescribeTable",
                "dynamodb:Get*",
                "dynamodb:Query",
                "dynamodb:Scan",
                "dynamodb:BatchWrite*",
                "dynamodb:CreateTable",
                "dynamodb:Delete*",
                "dynamodb:Update*",
                "dynamodb:PutItem"
            ],
            "Resource": "${aws_dynamodb_table.terraform_datasource.arn}"
        }
    ]
}
EOF
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda_by_devendra"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "dynamodb-access-bydevendra" {
  role       = "${aws_iam_role.iam_for_lambda.name}"
  policy_arn = "${aws_iam_policy.dynamodb-access-bydevendra.arn}"
}

resource "aws_lambda_function" "data_source_person" {
  filename      = "DevendraTestAppPY.zip"
  function_name = "person_db_query"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "persons.handler"
  runtime       = "python3.7"
}

resource "aws_lambda_function" "helloWorld_person" {
  filename      = "DevendraTestAppPY.zip"
  function_name = "helloWorld"
  role          = "${aws_iam_role.iam_for_lambda.arn}"
  handler       = "helloWorld.handler"
  runtime       = "python3.7"
}

resource "aws_api_gateway_rest_api" "personapi" {
  name        = "personDataSourceService"
  description = "Query a DynamoDB Table for values"
}

resource "aws_api_gateway_resource" "personresource" {
  rest_api_id = "${aws_api_gateway_rest_api.personapi.id}"
  parent_id   = "${aws_api_gateway_rest_api.personapi.root_resource_id}"
  path_part   = "person_db_query"
}

resource "aws_api_gateway_method" "personpost" {
  rest_api_id   = "${aws_api_gateway_rest_api.personapi.id}"
  resource_id   = "${aws_api_gateway_resource.personresource.id}"
  http_method   = "POST"
  authorization = "NONE"
}
resource "aws_api_gateway_method" "persondelete" {
  rest_api_id   = "${aws_api_gateway_rest_api.personapi.id}"
  resource_id   = "${aws_api_gateway_resource.personresource.id}"
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "personpost_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.personapi.id}"
  resource_id             = "${aws_api_gateway_resource.personresource.id}"
  http_method             = "${aws_api_gateway_method.personpost.http_method}"
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.helloWorld_person.arn}/invocations"
}
resource "aws_api_gateway_method_response" "personpost_response_200" {
  rest_api_id = aws_api_gateway_rest_api.personapi.id
  resource_id = aws_api_gateway_resource.personresource.id
  http_method = aws_api_gateway_method.personpost.http_method
  status_code = "200"
}
resource "aws_api_gateway_integration_response" "personpost_integration_response_200" {
  depends_on = [
    "aws_api_gateway_integration.personpost_integration",
  ]
  rest_api_id = aws_api_gateway_rest_api.personapi.id
  resource_id = aws_api_gateway_resource.personresource.id
  http_method = aws_api_gateway_method.personpost.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration" "persondelete_integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.personapi.id}"
  resource_id             = "${aws_api_gateway_resource.personresource.id}"
  http_method             = "${aws_api_gateway_method.persondelete.http_method}"
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.data_source_person.arn}/invocations"
}
resource "aws_api_gateway_method_response" "persondelete_response_200" {
  rest_api_id = aws_api_gateway_rest_api.personapi.id
  resource_id = aws_api_gateway_resource.personresource.id
  http_method = aws_api_gateway_method.persondelete.http_method
  status_code = "200"
}
resource "aws_api_gateway_integration_response" "persondelete_integration_response_200" {
  depends_on = [
    "aws_api_gateway_integration.persondelete_integration",
  ]
  rest_api_id = aws_api_gateway_rest_api.personapi.id
  resource_id = aws_api_gateway_resource.personresource.id
  http_method = aws_api_gateway_method.persondelete.http_method
  status_code = "200"
}

resource "aws_lambda_permission" "apigw_lambda_helloWorld_person" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.helloWorld_person.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${var.accountId}:${aws_api_gateway_rest_api.personapi.id}/*/${aws_api_gateway_method.personpost.http_method}${aws_api_gateway_resource.personresource.path}"
}
resource "aws_lambda_permission" "apigw_lambda_data_source_person" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.data_source_person.arn}"
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${var.accountId}:${aws_api_gateway_rest_api.personapi.id}/*/${aws_api_gateway_method.persondelete.http_method}${aws_api_gateway_resource.personresource.path}"
}
resource "aws_api_gateway_deployment" "devendraappdeployment" {
  depends_on = ["aws_api_gateway_integration.personpost_integration","aws_api_gateway_integration.persondelete_integration"]

  rest_api_id = "${aws_api_gateway_rest_api.personapi.id}"
  stage_name  = "prod"
}

output "invoke-url" {
  value = "https://${aws_api_gateway_deployment.devendraappdeployment.rest_api_id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_deployment.devendraappdeployment.stage_name}/${aws_lambda_function.helloWorld_person.function_name}"
}

terraform {
  backend "s3" {
	  # s3://devendra-testapp-py/tf/
    bucket = "devendra-testapp-py"
    region = "ap-south-1"
    key    = "aws.tfstate"
  }
}




# # # {
  # # # "tableName": "persons",
  # # # "operation": "read",
  # # # "payload": {
    # # # "Key": {
      # # # "personId": "devendra.asane@live.com"
    # # # }
  # # # }
# # # }


# # # {
  # # # "tableName": "persons",
  # # # "operation": "delete",
  # # # "payload": {
    # # # "Key": {
      # # # "personId": "devendra.asane@live.com"
    # # # }
  # # # }
# # # }

