# First aid with Lambda, SNS and terraform

Demonstration of AWS-provided serverless setup for simulating a distrbuted transaction.

For extensive review and implementation details, please see the [attached atricle](https://medium.com/@guy.signer/first-aid-with-lambda-sns-and-terraform-c23b3d3a84b8).

## Background

Imagine walking on the street and suddenly encountering a person choking with stress, and then becoming unresponsive.
You remembered to carry your first-aid robot with you this morning, and it is in your backpack.
You're rushing to the choking person and take your first-aid robot out, placing it properly under the person, and pressing the big red button, as per the instructions.

Now what? The robot connects to the serverless backend on AWS, and a long-running transaction is performed until further measures are taken to restore spontaneous blood circulation and breathing in the person.

## Scope

In this post we are going to simulate the logical backend side of a first aid flow, which communicates with the imaginary robot mentioned above, acting on the ground.

We will assume an out-of-scope adaptor backend component (call it: adaptor) responsible for communicating with the robot device on the ground.

### Requirements

The first aid procedure goes as follows:

1. Simulatnously, call emergency number, keeping the call alive of the rest of procedure, and start giving aid to patient by checking vital signs.
2. If no vital signs, lift chin and check breathing.
3. If no breathing, perform CPR
4. Repeat step 3 above until help arrives

To simulate it, we will mock the following behaviour:

1. Emergency call and physical aid start simulatnously.
2. The emergency help arrives after 4 seconds, even if the patient is breathing before that.
3. The physical aid would have managed to restore breathing after 10 seconds, but the arrival of emergency team had completed the procedure.

## Get Started
1. Install Terraform
2. Install AWS CLI
3. Configure AWS CLI with Administrative credentials
4. Clone this repository
5. Run `cd first-aid-with-lambda-sns-and-terraform`
6. Run `cd iac && terraform init && terraform apply` (enter 'yes' on prompt)
7. Invoke the orchestrating worker: `aws lambda invoke --function-name first_aid_worker response.json`
8. Wait for the first aid procedure to complete (see `src/remote_aid_worker/worker.js` and `src/physical_aid_worker/worker.js` for delay mocks)
9. See the log for `first_aid_worker` to notice the single completion event: `aws logs tail /aws/lambda/first_aid_worker --filter-pattern "ending the procedure..."` (or without `--filter-pattern` to see all latest events).

### Output

Following the "Getting Started" section above, we get the following output, indeed containing only one instance of completion log event:

```bash
[***@*** project]$ aws logs tail /aws/lambda/first_aid_worker --filter-pattern "ending the procedure..."
2023-01-03T21:04:19.247000+00:00 2023/01/03/[$LATEST]6efc86c3a5414851bd654236b3da78b1 2023-01-03T21:04:19.247Z  e3bfcb9d-962e-4502-a41f-2fa469b6c4c2      INFO    Emergency team arrived. ending the procedure...
[***@*** project]$ 
```

