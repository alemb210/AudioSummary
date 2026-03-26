const AWS = require("aws-sdk");

// Mock the AWS SDK before requiring the handler
jest.mock("aws-sdk", () => {
    const mockQuery = jest.fn();
    const mockDelete = jest.fn();
    const mockDocumentClient = jest.fn(() => ({
        query: mockQuery,
        delete: mockDelete,
    }));
    return { DynamoDB: { DocumentClient: mockDocumentClient } };
});

process.env.DYNAMODB_TABLE_NAME = "websocket-connections";

const { handler } = require("./lambda");

const getMocks = () => {
    const instance = new AWS.DynamoDB.DocumentClient();
    return { mockQuery: instance.query, mockDelete: instance.delete };
};

const makeEvent = (connectionId) => ({
    requestContext: { connectionId },
});

beforeEach(() => {
    jest.clearAllMocks();
});

describe("disconnect handler", () => {
    test("deletes DynamoDB record when connection exists", async () => {
        const { mockQuery, mockDelete } = getMocks();
        mockQuery.mockReturnValue({ promise: () => Promise.resolve({ Items: [{ fileId: "file-123", connectionId: "conn-abc" }] }) });
        mockDelete.mockReturnValue({ promise: () => Promise.resolve({}) });

        const result = await handler(makeEvent("conn-abc"));

        expect(result.statusCode).toBe(200);
        expect(result.body).toBe("Disconnection handled successfully");

        expect(mockQuery).toHaveBeenCalledWith({
            TableName: "websocket-connections",
            IndexName: "connectionId-index",
            KeyConditionExpression: "connectionId = :cid",
            ExpressionAttributeValues: { ":cid": "conn-abc" },
        });

        expect(mockDelete).toHaveBeenCalledWith({
            TableName: "websocket-connections",
            Key: { fileId: "file-123" },
        });
    });

    test("returns 200 without deleting when connection record not found", async () => {
        const { mockQuery, mockDelete } = getMocks();
        mockQuery.mockReturnValue({ promise: () => Promise.resolve({ Items: [] }) });

        const result = await handler(makeEvent("conn-unknown"));

        expect(result.statusCode).toBe(200);
        expect(result.body).toBe("Connection not found, nothing to clean up");
        expect(mockDelete).not.toHaveBeenCalled();
    });

    test("returns 500 when DynamoDB query throws", async () => {
        const { mockQuery } = getMocks();
        mockQuery.mockReturnValue({ promise: () => Promise.reject(new Error("DynamoDB unavailable")) });

        const result = await handler(makeEvent("conn-abc"));

        expect(result.statusCode).toBe(500);
        expect(result.body).toBe("Failed to handle disconnection");
    });

    test("returns 500 when DynamoDB delete throws", async () => {
        const { mockQuery, mockDelete } = getMocks();
        mockQuery.mockReturnValue({ promise: () => Promise.resolve({ Items: [{ fileId: "file-123", connectionId: "conn-abc" }] }) });
        mockDelete.mockReturnValue({ promise: () => Promise.reject(new Error("Delete failed")) });

        const result = await handler(makeEvent("conn-abc"));

        expect(result.statusCode).toBe(500);
        expect(result.body).toBe("Failed to handle disconnection");
    });
});
