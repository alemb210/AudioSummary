const AWS = require("aws-sdk");
const dynamoDB = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.DYNAMODB_TABLE_NAME;

exports.handler = async (event) => {
    try {
        const connectionId = event.requestContext.connectionId;
        const fileId = event.queryStringParameters?.fileId; // Extract fileId from query string
        console.log(`Connection established with ID: ${connectionId}, File ID: ${fileId}`);

        await dynamoDB.put({
            TableName: TABLE_NAME,
            Item: {
                connectionId: connectionId,
                fileId: fileId, 
            }
        }).promise();

        return {
            statusCode: 200,
            body: `Connection established with ID: ${connectionId}, File ID: ${fileId}`
        };
    }
    catch (error) {
        console.error("Error storing connection:", error);
        return {
            statusCode: 500,
            body: "Failed to store connection"
        };
    }
};