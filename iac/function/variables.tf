# Input variable definitions

variable "subscribe_to_topics_uris" {
  description = "URIs of topics to subscribe to"
  type        = map(string)
}

variable "publish_to_topics_uris" {
  description = "URIs of topics to publish to"
  type        = map(string)
}

variable "function_name" {
  description = "Key name to reference the function"
  type        = string
}
