const AWS = require('aws-sdk')
const sns = new AWS.SNS({apiVersion: '2012-11-05'})
let isCompleted = false;

console.log('Loading function first_aid_worker');
const { first_aid_started, first_aid_completed } = JSON.parse(process.env.SNSPublishArns);
console.log('publish topics:', first_aid_started, first_aid_completed);

exports.handler = async (event) => {
    var message = event.Records?.[0]?.Sns?.Subject;
    if (!!message) {
        console.log('Message received from SNS:', message);
    }

    if (isCompleted) {
        return "Success";
    }

    switch (message) {
        case undefined:
            console.log("Starting first aid...");
            await publishStarted();
            isCompleted = false;
            break;
        case "PHYSICAL_AID_GIVEN_PATIENT_UNRESPONSIVE":
            console.log("Physical operation performed on patient, but patient is still unresponsive. Carrying on with procedure...");
            break;
        case "PHYSICAL_AID_GIVEN_PATIENT_BREATHES":
            console.log("Physical operation helped - patient is breathing. Emergency team is expected to arrive soon. With that, ending the procedure...");
            await publishCompleted();
            isCompleted = true;
            break;
        case "HELP_ARRIVED":
            console.log("Emergency team arrived. ending the procedure...");
            await publishCompleted();
            isCompleted = true;
            break;    
        default:
            throw new Error("Bad event");
    }
    
    console.log("Event processing done");
    return "Success";
};

async function publishStarted() {
    const params = {
        Message: 'FIRST_AID_STARTED',
        Subject: 'FIRST_AID_STARTED',
        TopicArn: first_aid_started
      }
      
      // Send to SNS
      await sns.publish(params).promise()
}

async function publishCompleted() {
    const params = {
        Message: 'FIRST_AID_COMPLETED',
        Subject: 'FIRST_AID_COMPLETED',
        TopicArn: first_aid_completed
      }
      
      // Send to SNS
      await sns.publish(params).promise()
}