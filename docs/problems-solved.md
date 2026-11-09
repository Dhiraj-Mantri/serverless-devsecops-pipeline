# Problems I Solved

A log of real issues I hit while building this project, with the cause and the fix for each.

## 1. `git push` failed with "Permission denied (publickey)"
- **Cause:** GitHub did not have an SSH key from my machine.
- **Fix:** Generated an ed25519 key with `ssh-keygen -t ed25519`, added the public key to my GitHub account, and verified it with `ssh -T git@github.com`.

## 2. `git push` rejected (fetch first)
- **Cause:** The GitHub repository was created with an initial commit, so the local and remote histories had diverged.
- **Fix:** Ran `git pull --rebase` to place my commit on top of the remote one, then pushed.

## 3. GitHub OIDC provider could not be created (explicit deny from an SCP)
- **Symptom:** `terraform apply` failed with `AccessDenied` on `iam:CreateOpenIDConnectProvider`.
- **Cause:** The account is a member of an AWS Organization (new Free plan setup), and a Service Control Policy explicitly denies this action. An SCP overrides IAM permissions, even for an administrator user.
- **Fix:** Kept the OIDC role Terraform code in the repository (committed, not applied). Ran CI without AWS credentials (tests, `terraform fmt`/`validate`, security scans). Deployment from CI will be added later using a standalone AWS account or after the restriction is lifted.

## 4. Lambda reserved concurrency failed
- **Symptom:** `InvalidParameterValueException`: reserved concurrency would drop unreserved concurrency below the minimum of 10.
- **Cause:** The account-level Lambda concurrency quota is only 10, and AWS requires at least 10 to stay unreserved.
- **Fix:** Removed the reservation and documented a Checkov skip for `CKV_AWS_115` with the reason. API Gateway throttling (10 req/s, burst 20) limits load instead.

## 5. Checkov reported 18 failed checks on the first scan
- **Cause:** First scan of the code against production-grade rules (KMS customer-managed keys, VPC, DLQ, replication, and others).
- **Fix:** Fixed what was worth fixing (enabled API Gateway access logging, verified in CloudWatch). Skipped the rest deliberately, with a written reason for each in `.checkov.yaml` (cost, scale, or not applicable). Result: 122 passed, 0 failed.

## 6. Trivy GitHub Action failed to install
- **Symptom:** `Unable to resolve action`, then `unable to find 'v0.xx.0'` in the "Install Trivy" step.
- **Cause:** I first used a tag that does not exist for the action. Then the action's built-in default Trivy version was not available on GitHub releases.
- **Fix:** Listed the real tags with `git ls-remote --tags`, pinned a valid action tag, and set `version: latest` for the Trivy binary. Known trade-off: `latest` is not reproducible, so I plan to pin an exact Trivy release later.

## 7. Trivy flagged the state bucket (AWS-0132, HIGH)
- **Cause:** The Terraform state bucket uses AWS-managed encryption (AES256) instead of a customer-managed KMS key.
- **Fix:** Documented the decision in `.trivyignore`. A customer-managed key adds cost and key-policy overhead that is not justified for this project. The bucket is still encrypted, versioned, and blocks all public access.

## 8. CI went red after adding the monitoring module
- **Symptom:** The `security` and `trivy` jobs failed on every push after the SNS topic was added.
- **Cause:** The new SNS topic is not encrypted (the AWS-managed key does not let CloudWatch alarms publish). Checkov flagged `CKV_AWS_26`, and Trivy flagged the same issue.
- **Fix:** Documented both as deliberate skips with reasons (`.checkov.yaml`, `.trivyignore`), and pinned the Checkov version so CI matches my laptop. A customer-managed KMS key is listed as a future improvement.
