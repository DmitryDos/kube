package storage

import (
    "context"
    "io"
    "net/url"
    "os"
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
    useSSL := getEnv("MINIO_USE_SSL", "false") == "true"

    client, err := minio.New(endpoint, &minio.Options{
        Creds:  credentials.NewStaticV4(accessKey, secretKey, ""),
        Secure: useSSL,
    })
    if err != nil {
        return nil, err
    }

    exists, err := client.BucketExists(context.Background(), bucket)
    if err != nil {
        return nil, err
    }

    if !exists {
        err = client.MakeBucket(context.Background(), bucket, minio.MakeBucketOptions{})
        if err != nil {
            return nil, err
        }
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

func (m *MinIOClient) UploadReader(ctx context.Context, objectName string, reader io.Reader, size int64, contentType string) (int64, error) {
    opts := minio.PutObjectOptions{ContentType: contentType}
    info, err := m.client.PutObject(ctx, m.bucket, objectName, reader, size, opts)
    if err != nil {
        return 0, err
    }
    return info.Size, nil
}

func (m *MinIOClient) GeneratePresignedURL(ctx context.Context, objectName string) (string, error) {
    expires := 24 * 60 * 60 * time.Second
    url, err := m.client.PresignedGetObject(ctx, m.bucket, objectName, expires, nil)
    if err != nil {
        return "", err
    }

    raw := url.String()
    if pub := getEnv("MINIO_PUBLIC_ENDPOINT", ""); pub != "" {
        if pubURL, err := urlParseEnsureScheme(pub); err == nil {
            if u, err2 := url.Parse(raw); err2 == nil {
                u.Scheme = pubURL.Scheme
                u.Host = pubURL.Host
                return u.String(), nil
            }
        }
    }
    return raw, nil
}

func (m *MinIOClient) DeleteFile(ctx context.Context, objectName string) error {
    return m.client.RemoveObject(ctx, m.bucket, objectName, minio.RemoveObjectOptions{})
}

func (m *MinIOClient) Stat(ctx context.Context, objectName string) (minio.ObjectInfo, error) {
    return m.client.StatObject(ctx, m.bucket, objectName, minio.StatObjectOptions{})
}

func (m *MinIOClient) GetObjectRange(ctx context.Context, objectName string, start, end int64) (*minio.Object, error) {
    opts := minio.GetObjectOptions{}
    if start >= 0 {
        if end >= 0 {
            if err := opts.SetRange(start, end); err != nil {
                return nil, err
            }
        } else if start > 0 {
            if err := opts.SetRange(start, 9223372036854775807); err != nil {
                return nil, err
            }
        }
    }
    return m.client.GetObject(ctx, m.bucket, objectName, opts)
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}

func urlParseEnsureScheme(s string) (*url.URL, error) {
    if !(len(s) >= 7 && (s[:7] == "http://" || (len(s) >= 8 && s[:8] == "https://"))) {
        s = "http://" + s
    }
    return url.Parse(s)
}
