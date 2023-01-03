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

To simulate the first aid procedure as follows:

1. Simulatnously, call emergency number, keeping the call alive of the rest of procedure, and start giving aid to patient by checking vital signs.
2. If no vital signs, lift chin and check breathing.
3. If no breathing, perform CPR
4. Repeat step 3 above until help arrives

## Get Started
1. Install Terraform
2. Install AWS CLI
3. Configure AWS CLI with Administrative credentials
4. Run `terraform init` and then `terraform apply`
5. Invoke the orchestrating worker: `aws lambda invoke --function-name first_aid_worker response.json`
6. See the log for `first_aid_worker` to notice the single completion event: `aws logs tail /aws/lambda/first_aid_worker --filter-pattern "ending the procedure..."` (or without `--filter-pattern` to see all latest events).

## Design

We design a distributed system, deployed on serverless evironment on AWS.
The long-running transaction of preserving intact brain function is managed by Saga pattern. Saga pattern provides transaction management using a sequence of local transactions.
While Saga requires that failures during the transaction will be handled (such as by rollbacks), we will take only a happy path here for the purpose of demonstration.

[AWS Lambda](https://aws.amazon.com/lambda/) functions is used to simulate those local transactions (such as instructing the adaptor to perform operations on the ground).

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


