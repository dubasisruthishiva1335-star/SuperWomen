import { Injectable, Logger } from '@nestjs/common';
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

@Injectable()
export class AwsS3Service {
  private readonly logger = new Logger(AwsS3Service.name);
  private readonly s3: S3Client;
  private readonly bucket: string;
  private readonly isConfigured: boolean;

  constructor() {
    this.bucket = process.env.AWS_S3_BUCKET || 'superwomen-kyc-documents';
    const region = process.env.AWS_REGION || 'ap-south-1'; // Default Mumbai
    const accessKeyId = process.env.AWS_ACCESS_KEY_ID;
    const secretAccessKey = process.env.AWS_SECRET_ACCESS_KEY;

    if (accessKeyId && secretAccessKey) {
      this.s3 = new S3Client({
        region,
        credentials: { accessKeyId, secretAccessKey },
      });
      this.isConfigured = true;
      this.logger.log(`AWS S3 initialized for bucket: ${this.bucket} in region ${region}`);
    } else {
      // Mock / Offline mode
      this.s3 = new S3Client({ region });
      this.isConfigured = false;
      this.logger.warn('AWS S3 credentials not configured. Running in simulated fallback mode.');
    }
  }

  /// Generate a presigned S3 upload URL for Captain KYC documents (Aadhaar, License, RC, Selfie)
  async getPresignedUploadUrl(captainId: string, documentType: string, filename: string): Promise<{ uploadUrl: string; s3Key: string; documentUrl: string }> {
    const cleanDoc = documentType.toLowerCase().replace(/[^a-z0-9]/g, '');
    const s3Key = `kyc/${captainId}/${cleanDoc}_${Date.now()}_${filename}`;

    if (!this.isConfigured) {
      const mockUrl = `https://${this.bucket}.s3.ap-south-1.amazonaws.com/${s3Key}`;
      return {
        uploadUrl: `${mockUrl}?mock-presigned=true`,
        s3Key,
        documentUrl: mockUrl,
      };
    }

    const command = new PutObjectCommand({
      Bucket: this.bucket,
      Key: s3Key,
      ContentType: filename.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg',
    });

    const uploadUrl = await getSignedUrl(this.s3, command, { expiresIn: 3600 });
    const documentUrl = `https://${this.bucket}.s3.${process.env.AWS_REGION || 'ap-south-1'}.amazonaws.com/${s3Key}`;

    return { uploadUrl, s3Key, documentUrl };
  }
}
