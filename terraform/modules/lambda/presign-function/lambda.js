const AWS = require("aws-sdk");
const s3 = new AWS.S3();
const apiGatewayManagementApi = new AWS.ApiGatewayManagementApi({
    endpoint: process.env.WEBSOCKET_API_ENDPOINT
});
const dynamoDB = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.DYNAMODB_TABLE_NAME;


exports.handler = async (event) => {
    try {
        //extracting data from s3:ObjectCreated event
        const eventRecord = event.Records && event.Records[0],
            inputBucket = eventRecord.s3.bucket.name,
            key = eventRecord.s3.object.key;
            const fileId = path.basename(key);
            
            
        //define parameters for generating presigned URL
        const params = {
            Bucket: inputBucket,
            Key: key,
            Expires: 3600 //URL expires in 1 hour
        }

        //generate presigned URL that allows the user to download the file
        const presignedUrl = s3.getSignedUrl("getObject", params);

        console.log("1 hour presigned URL:", presignedUrl);

        //attempt to retrieve connectionId from DynamoDB using fileId 
        const connectionId = await getConnection(fileId);
        if (connectionId) {
            await sendURL(connectionId, presignedUrl); //send the presigned URL to the client via WebSocket
        }
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: "Presigned URL generated and sent successfully",
                url: presignedUrl
            })
        };
    } catch (error) {
        console.error("Error generating or sending presigned URL:", error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                message: "Failed to generate or send presigned URL",
                error: error.message
            })
        };
    }
};

//Helper functions for communicating with WebSocket and DynamoDB
async function sendURL(connectionId, url) {
    try {
        await apiGatewayManagementApi.postToConnection({
            ConnectionId: connectionId,
            Data: JSON.stringify({ url })
        }).promise();
        console.log(`Message sent to connection ID: ${connectionId}`);
    } catch (error) {
        console.error("Error sending URL to connection:", error);
    }
}

async function getConnection(fileId) {
    try {
        const result = await dynamoDB.get({
            TableName: TABLE_NAME,
            Key: {
                fileId: fileId
            }
        }).promise();

        if (result.Item) {
            return result.Item.connectionId;
        } else {
            console.log(`No connection found for fileId: ${fileId}`);
            return null;
        }

    }
    catch (error) {
        console.error("Error retrieving connection:", error);
    }
}