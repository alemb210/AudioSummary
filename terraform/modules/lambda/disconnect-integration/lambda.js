exports.handler = async (event) => {
    try {
        return {
            statusCode: 200,
            body: `Disconnection successful for connection ID: ${event.requestContext.connectionId}`
        }
    }
    catch (error) {
        return {
            statusCode: 500,
            body: "Failed to handle disconnection"
        };
    }
};