const AWS = require('aws-sdk')
const sns = new AWS.SNS({apiVersion: '2012-11-05'})
const { setTimeout } = require("node:timers/promises")

console.log('Loading worker remote_aid_worker');
const { help_arrived } = JSON.parse(process.env.SNSPublishArns);
const FOUR_SECONDS = 4000;
console.log('publish topics:', help_arrived);

exports.handler = async (event) => {
    var message = event.Records?.[0]?.Sns?.Subject;
    if (!!message) {
        console.log('Message received from SNS:', message);
    }

    switch (message) {
        case "FIRST_AID_STARTED":
            console.log("Calling emergency...");
            console.log("Emergency team should be on location in 4 seconds.");

            // Mock time-consuming operation, resulting in a message originating at the emergency team
            await setTimeout(FOUR_SECONDS);
            await publishHelpArrived();
            break;   
        default:
            throw new Error("Bad event");
    }
    
    console.log("Event processing done");
    return "Success";
};

async function publishHelpArrived() {
    const params = {
        Message: 'HELP_ARRIVED',
        Subject: 'HELP_ARRIVED',
        TopicArn: help_arrived
      }
      
      // Send to SNS
      await sns.publish(params).promise()
}