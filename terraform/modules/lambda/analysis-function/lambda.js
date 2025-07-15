const { BedrockRuntimeClient, InvokeModelCommand } = require("@aws-sdk/client-bedrock-runtime");
const client = new BedrockRuntimeClient({ region: "us-east-1" });
const AWS = require("aws-sdk");
const s3 = new AWS.S3(); 
const path = require("path"); //for base file name

exports.handler = async (event) => {
  try {
    // parse transcription and timestamps from JSON upon event trigger
    // console.log("Event:", JSON.stringify(event, null, 2));
    const eventRecord = event.Records && event.Records[0],
      inputBucket = eventRecord.s3.bucket.name,
      key = eventRecord.s3.object.key;

    const transcriptionsObject = await s3.getObject({ Bucket: inputBucket, Key: key }).promise();
    const transcriptionData = JSON.parse(transcriptionsObject.Body.toString('utf-8'));

    console.log("Contents: ", transcriptionData);

    const transcription = transcriptionData.results.transcripts[0].transcript;

    const segments = transcriptionData.results.audio_segments.map(segment => ({ //map each segment (sentence) to it's start and end time
      transcript: segment.transcript,
      start_time: segment.start_time,
      end_time: segment.end_time,
    }));


    // create prompt
    const prompt = `Summarize the following meeting transcription and provide key points with timestamps. Please note timestamps are provided in seconds format and not converted into minutes. Please convert into hh:mm:ss (when necessary), and truncate decimals from seconds. \n\nTranscript:\n${transcription}\n\nSpoken segments:\n Segments:
    ${segments.map(segment => `Transcript: "${segment.transcript}" (Start: ${segment.start_time}, End: ${segment.end_time})`).join("\n")}`;

    console.log("Prompt:", prompt);

    // define payload for Bedrock
    const payload = {
      anthropic_version: "bedrock-2023-05-31",
      max_tokens: 1000,
      messages: [
        {
          role: "user",
          content: [{ type: "text", text: prompt }],
        },
      ],
    };

    // invoke Claude Bedrock model
    const command = new InvokeModelCommand({
      contentType: "application/json",
      body: JSON.stringify(payload),
      modelId: "anthropic.claude-3-5-sonnet-20240620-v1:0", 
    });

    const apiResponse = await client.send(command);

    // parse AI response
    const decodedResponseBody = new TextDecoder().decode(apiResponse.body);
    const responseBody = JSON.parse(decodedResponseBody);
    console.log("AI Response:", responseBody);


    // uploading Bedrock response to S3
    const outputBucket = "analysis-bucket-for-audio-test";

    // use original filename so frontend can identify the file
    const baseFileName = path.basename(key, path.extname(key)); //extract w/o extension
    const outputKey = `${baseFileName}.txt`;

    // define parameters for uploading to S3
    const uploadParams = {
      Bucket: outputBucket,
      Key: outputKey,
      Body: responseBody.content[0].text,
      ContentType: "text/plain",
    };

    await s3.putObject(uploadParams).promise();
    console.log(`Bedrock response uploaded to s3://${outputBucket}/${outputKey}`);

    return {
      statusCode: 200,
      body: responseBody.content[0].text,
    };
  } catch (error) {
    console.error('Error processing transcription:', error);
    return {
      statusCode: 500,
      body: { error: error.message }
    };
  }
};

