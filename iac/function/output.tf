output "function_uri" {
  value       = aws_lambda_function.worker.arn
  description = "ARN of the worker function"
}