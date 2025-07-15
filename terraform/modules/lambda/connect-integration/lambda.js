const AWS = require("aws-sdk");

exports.handler = async (event) => {
    try {
        const connectionId = event.requestContext.connectionId;
        const fileId = event.queryStringParameters?.fileId; // Extract fileId from query string
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