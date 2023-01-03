const AWS = require('aws-sdk')
const sns = new AWS.SNS({apiVersion: '2012-11-05'})
const { setTimeout } = require("node:timers/promises")

console.log('Loading worker physical_aid_worker');
const { physical_aid_given_patient_unresponsive, physical_aid_given_patient_breathes } = JSON.parse(process.env.SNSPublishArns);
const TEN_SECONDS = 10000;
console.log('publish topics:', physical_aid_given_patient_unresponsive, physical_aid_given_patient_breathes);

exports.handler = async (event) => {
    var message = event.Records?.[0]?.Sns?.Subject;
    if (!!message) {
        console.log('Message received from SNS:', message);
    }

    switch (message) {
        case "FIRST_AID_STARTED":
            console.log("Checking vital signs and breathing");
            console.log("Performing CPR...");

            // Mock time-consuming operation, resulting in a message originating at the device on the ground
            await setTimeout(TEN_SECONDS);
            await publishPhysicalAidGivenPatientBreathes();
            break;   
        default:
            throw new Error("Bad event");
    }
    
    console.log("Event processing done");
    return "Success";
};

async function publishPhysicalAidGivenPatientBreathes() {
    const params = {
        Message: 'PHYSICAL_AID_GIVEN_PATIENT_BREATHES',
        Subject: 'PHYSICAL_AID_GIVEN_PATIENT_BREATHES',
        TopicArn: physical_aid_given_patient_breathes
      }
      
      // Send to SNS
      await sns.publish(params).promise()
}

async function publishPhysicalAidGivenPatientUnresponsive() {
    const params = {
        Message: 'PHYSICAL_AID_GIVEN_PATIENT_UNRESPONSIVE',
        Subject: 'PHYSICAL_AID_GIVEN_PATIENT_UNRESPONSIVE',
        TopicArn: physical_aid_given_patient_unresponsive
      }
      
      // Send to SNS
      await sns.publish(params).promise()
}