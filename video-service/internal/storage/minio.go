package storage

import (
    "context"
    "os"
    "fmt"
    "log"
    "time"
    "github.com/minio/minio-go/v7"
    "github.com/minio/minio-go/v7/pkg/credentials"
)

type MinIOClient struct {
    client *minio.Client
    bucket string
}

func NewMinIOClient() (*MinIOClient, error) {
    endpoint := getEnv("MINIO_ENDPOINT", "localhost:9000")
    accessKey := getEnv("MINIO_ACCESS_KEY", "minioadmin")
    secretKey := getEnv("MINIO_SECRET_KEY", "minio123")
    bucket := getEnv("MINIO_BUCKET", "videos")
    useSSL := false

    client, err := minio.New(endpoint, &minio.Options{
        Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
        Secure: useSSL,
    })
    if err != nil {
        return nil, err
    }

    // Создаем bucket если не существует
    exists, err := client.BucketExists(context.Background(), bucket)
    if err != nil {
        return nil, err
    }

    if !exists {
        err = client.MakeBucket(context.Background(), bucket, minio.MakeBucketOptions{})
        if err != nil {
            return nil, err
        }
        log.Printf("Bucket %s created successfully", bucket)
    }

    return &MinIOClient{
        client: client,
        bucket: bucket,
    }, nil
}

func (m *MinIOClient) UploadFile(ctx context.Context, objectName string, filePath string, fileSize int64) error {
    _, err := m.client.FPutObject(ctx, m.bucket, objectName, filePath, minio.PutObjectOptions{
        ContentType: "application/octet-stream",
    })
    return err
}

func (m *MinIOClient) GetFileURL(objectName string) string {
    return fmt.Sprintf("http://%s/%s/%s", getEnv("MINIO_ENDPOINT", "localhost:9000"), m.bucket, objectName)
}

func (m *MinIOClient) GeneratePresignedURL(ctx context.Context, objectName string) (string, error) {
    expires := 24 * 60 * 60 * time.Second

    url, err := m.client.PresignedGetObject(ctx, m.bucket, objectName, expires, nil)
    if err != nil {
        return "", err
    }

    return url.String(), nil
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {  // ← ИСПРАВИТЬ ЭТУ СТРОКУ
        return value
    }
    return defaultValue
}