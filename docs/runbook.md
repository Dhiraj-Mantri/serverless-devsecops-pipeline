# Incident Runbook

Alarms are sent by email through SNS. Each alarm uses a 1-minute window and fires on 1 or more events.
Replace `items-api-dev` with the environment name if needed.

## First 2 minutes (any alarm)

1. Confirm the API is up: `./scripts/health-check.sh`
2. Watch live logs: `./scripts/tail-logs.sh api` and `./scripts/tail-logs.sh lambda`
3. Check what changed recently: `git log --oneline -5` and the latest GitHub Actions run.

## Alarm: `items-api-dev-lambda-errors`

**Meaning:** the Lambda function raised an exception.

1. Read recent errors:
   `aws logs tail /aws/lambda/items-api-dev --since 30m --filter-pattern ERROR`
2. Common causes: DynamoDB permission or table-name problem, a bad deploy, invalid input not handled.
3. If a recent deploy caused it, revert the commit and re-run `terraform apply`.
4. Verify with `./scripts/health-check.sh`.

## Alarm: `items-api-dev-api-5xx`

**Meaning:** API Gateway returned a server error (often Lambda failed or timed out).

1. Check API access logs: `./scripts/tail-logs.sh api` and look for `"status":"5xx"`.
2. Check Lambda errors and duration in the CloudWatch console.
3. Confirm the Lambda permission for API Gateway still exists:
   `aws lambda get-policy --function-name items-api-dev`

## Alarm: `items-api-dev-lambda-throttles`

**Meaning:** Lambda refused to run because the concurrency limit was reached.
The account concurrency quota is small (10), so a traffic spike can cause this.

1. Check for abnormal traffic in the API access logs (many requests from one IP).
2. API Gateway throttling is set to 10 req/s, burst 20. Lower it in
   `terraform/modules/api_gateway/main.tf` if needed, then apply.
3. Long term: request a Lambda concurrency quota increase from AWS Support.

## After the incident

- Add the issue and fix to `docs/problems-solved.md`.
- Test alerting again: `aws cloudwatch set-alarm-state --alarm-name <name> --state-value ALARM --state-reason test`
