# First aid with Lambda, SNS and terraform

Demonstration of AWS-provided serverless setup for simulating a distrbuted transaction.

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

## Design

We design a distributed system, deployed on serverless environment on AWS.
The long-running transaction of preserving intact brain function is managed by Saga pattern. Saga pattern provides transaction management using a sequence of local transactions.
While Saga requires that failures during the transaction will be handled (such as by rollbacks), we will take only a happy path here for the purpose of demonstration.

[AWS Lambda](https://aws.amazon.com/lambda/) functions are used to simulate those local transactions (such as instructing the adaptor to perform operations on the ground).

**All the communication between the worker functions is asynchronous and done via message broker as follows.**

[Amazon SNS](https://aws.amazon.com/sns/) is used as a messaging solution, for the components to publish and subscribe to domain events. 

Node.JS is used for applicative runtime to simulate the logic.

[Terraform](https://www.terraform.io/) is used to provision the serverless infrastructure on the AWS cloud.

> Important: this application uses various AWS services and there are costs associated with these services after the Free Tier usage - please see the AWS Pricing page for details. You are responsible for any AWS costs incurred. No warranty is implied in this example.

### Components

The following components take part in the desired technical flow:

* physical_aid_worker - to instruct the physical device for physical actions on the patient. The service will handle:
    1. Checking vital signs and breathing
    2. Performing CPR
    3. Notifying about patient status
* remote_aid_worker - to communicate with third party emergency services. The service will handle:
    1. Calling for help
    2. Notifying when help arrives
* first_aid_worker - to orchestrate the first aid process and communicate with the two above workers until the end of the procedure

### Domain events

The following events will control the execution:

* FIRST_AID_STARTED
* PHYSICAL_AID_GIVEN_PATIENT_UNRESPONSIVE
* PHYSICAL_AID_GIVEN_PATIENT_BREATHES
* HELP_ARRIVED
* FIRST_AID_COMPLETED

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

