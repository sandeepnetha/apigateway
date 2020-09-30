variable "apigw_name" {
  default="apigw"
}
variable "region"{
  default="us-east-2"
}
variable "stage" {
  default="default"
}

variable "path_part" {
  default="sandeep"
}

variable "http_method" {
  default = "GET"
}

variable "authorization" {
  default = "NONE"
}

variable "integration_http_method" {
  default = "GET"
}

variable "description" {
  default = "apigateway"
}

variable "lambda_invoke_arn" {
}

variable "lambda_arn" {
  
}

## This has to be AWS_PROXY for now
variable "integration_type" {
  default = "AWS_PROXY"
}

variable "enable_cors" {
  type    = bool
  default = true
}

variable "cors_origin" {
  type    = string
  default = "*"
}


