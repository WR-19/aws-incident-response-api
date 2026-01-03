# AWS Incident Response API

This is a fully working **AWS Incident Response API** project built for learning and portfolio purposes.

## Features

- **Lambda function** in Python 3.11
- **DynamoDB** table to store incidents
- **SNS** alerts for Lambda failures
- **CloudWatch** logging
- **API Gateway** REST endpoint `/prod/incident`
- **Terraform** for infrastructure-as-code deployment

## Deployment

1. Zip Lambda code:

```bash
cd lambda
zip app.zip app.py
cd ..
