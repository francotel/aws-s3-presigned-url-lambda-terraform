import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import crypto from "crypto";

const s3 = new S3Client({});

export const handler = async (event) => {
  try {
    const body = JSON.parse(event.body || "{}");
    const { fileName, contentType } = body;

    if (!fileName || !contentType) {
      return response(400, "fileName and contentType are required");
    }

    const extension = fileName.split(".").pop();
    const key = `uploads/${crypto.randomUUID()}.${extension}`;

    const command = new PutObjectCommand({
      Bucket: process.env.BUCKET_NAME,
      Key: key,
      ContentType: contentType
    });

    const uploadUrl = await getSignedUrl(
      s3,
      command,
      { expiresIn: Number(process.env.URL_EXPIRY) }
    );

    return response(200, {
      uploadUrl,
      key,
      expiresIn: process.env.URL_EXPIRY
    });

  } catch (error) {
    console.error("Error generating presigned URL", error);
    return response(500, "Internal server error");
  }
};

const response = (statusCode, body) => ({
  statusCode,
  headers: {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*"
  },
  body: JSON.stringify(body)
});