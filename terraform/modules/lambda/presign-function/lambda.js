const AWS = require("aws-sdk");
const s3 = new AWS.S3();

exports.handler = async (event) => {
    try {
        //extracting data from s3:ObjectCreated event
        const eventRecord = event.Records && event.Records[0],
            inputBucket = eventRecord.s3.bucket.name,
            key = eventRecord.s3.object.key;

        //define parameters for generating presigned URL
        const params = {
            Bucket: inputBucket,
            Key: key,
            Expires: 3600 //URL expires in 1 hour
        }

        //generate presigned URL
        const presignedUrl = s3.getSignedUrl("getObject", params);

        console.log("1 hour presigned URL:", presignedUrl);

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: "Presigned URL generated successfully",
                url: presignedUrl
            })
        };
    } catch (error) {
        console.error("Error generating presigned URL:", error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                message: "Failed to generate presigned URL",
                error: error.message
            })
        };
    }
};