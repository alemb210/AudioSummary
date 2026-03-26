const AWS = require("aws-sdk");
const dynamoDB = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.DYNAMODB_TABLE_NAME;

exports.handler = async (event) => {
    const connectionId = event.requestContext.connectionId;
    console.log(`Disconnecting connection ID: ${connectionId}`);

    try {
        // Query the GSI to find the fileId associated with this connectionId
        const queryResult = await dynamoDB.query({
            TableName: TABLE_NAME,
            IndexName: "connectionId-index",
            KeyConditionExpression: "connectionId = :cid",
            ExpressionAttributeValues: { ":cid": connectionId }
        }).promise();

        if (queryResult.Items.length === 0) {
            console.log(`No record found for connectionId: ${connectionId}`);
            return { statusCode: 200, body: "Connection not found, nothing to clean up" };
        }

        const { fileId } = queryResult.Items[0];

        await dynamoDB.delete({
            TableName: TABLE_NAME,
            Key: { fileId }
        }).promise();

        console.log(`Deleted record for fileId: ${fileId}, connectionId: ${connectionId}`);
        return { statusCode: 200, body: "Disconnection handled successfully" };
    } catch (error) {
        console.error("Error handling disconnection:", error);
        return { statusCode: 500, body: "Failed to handle disconnection" };
    }
};
