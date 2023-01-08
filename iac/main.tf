terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.22"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}

resource "aws_sns_topic" "first_aid_started_topic" {
    name = "first_aid_started"
}

resource "aws_sns_topic" "physical_aid_given_patient_unresponsive_topic" {
    name = "physical_aid_given_patient_unresponsive"
}

resource "aws_sns_topic" "physical_aid_given_patient_breathes_topic" {
    name = "physical_aid_given_patient_breathes"
}

resource "aws_sns_topic" "help_arrived_topic" {
    name = "help_arrived"
}

resource "aws_sns_topic" "first_aid_completed_topic" {
    name = "first_aid_completed"
}

module "physical_aid_worker" {
  source                  = "./function"

  function_name           = "physical_aid_worker"
  source_dir              = "${path.module}/../src/physical_aid_worker"
  output_zip              = "${path.module}/../dist/physical_aid_worker_lambda.zip"
  publish_to_topics_uris  = { 
    physical_aid_given_patient_unresponsive = "${aws_sns_topic.physical_aid_given_patient_unresponsive_topic.arn}"
    physical_aid_given_patient_breathes = "${aws_sns_topic.physical_aid_given_patient_breathes_topic.arn}"
  }
  subscribe_to_topics_uris = {
    first_aid_started = "${aws_sns_topic.first_aid_started_topic.arn}"
    first_aid_completed = "${aws_sns_topic.first_aid_completed_topic.arn}"
  }
}

module "remote_aid_worker" {
  source                  = "./function"

  function_name           = "remote_aid_worker"
  source_dir              = "${path.module}/../src/remote_aid_worker"
  output_zip              = "${path.module}/../dist/remote_aid_worker.zip"
  publish_to_topics_uris  = { 
    help_arrived = "${aws_sns_topic.help_arrived_topic.arn}"
  }
  subscribe_to_topics_uris = {
    first_aid_started = "${aws_sns_topic.first_aid_started_topic.arn}"
  }
}

module "first_aid_worker" {
  source                  = "./function"

  function_name           = "first_aid_worker"
  source_dir              = "${path.module}/../src/first_aid_worker"
  output_zip              = "${path.module}/../dist/first_aid_worker.zip"
  publish_to_topics_uris  = { 
    first_aid_started = "${aws_sns_topic.first_aid_started_topic.arn}"
    first_aid_completed = "${aws_sns_topic.first_aid_completed_topic.arn}"
  }
  subscribe_to_topics_uris = {
    physical_aid_given_patient_unresponsive = "${aws_sns_topic.physical_aid_given_patient_unresponsive_topic.arn}"
    physical_aid_given_patient_breathes = "${aws_sns_topic.physical_aid_given_patient_breathes_topic.arn}"
    help_arrived = "${aws_sns_topic.help_arrived_topic.arn}"
  }
}

output "first_aid_started_topic_uri" {
  value       = aws_sns_topic.first_aid_started_topic.arn
  description = "first_aid_started_topic SNS topic URI"
}

output "physical_aid_given_patient_unresponsive_topic_url" {
  value       = aws_sns_topic.physical_aid_given_patient_unresponsive_topic.arn
  description = "physical_aid_given_patient_unresponsive_topic SNS topic URI"
}

output "physical_aid_given_patient_breathes_topic_uri" {
  value       = aws_sns_topic.physical_aid_given_patient_breathes_topic.arn
  description = "physical_aid_given_patient_breathes_topic SNS topic URI"
}

output "help_arrived_topic_uri" {
  value       = aws_sns_topic.help_arrived_topic.arn
  description = "help_arrived_topic SNS topic URI"
}

output "first_aid_completed_topic_uri" {
  value       = aws_sns_topic.first_aid_completed_topic.arn
  description = "first_aid_completed_topic SNS topic URI"
}

output "initial_worker_name" {
  description = "Worker that starts the transaction"
  value = "first_aid_worker"
}
