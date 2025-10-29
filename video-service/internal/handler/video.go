package handler

import (
    "io"
    "net/http"
    "path/filepath"
    "regexp"
    "strconv"
    "video-service/internal/model"
    "video-service/internal/service"

    "github.com/gin-gonic/gin"
)

type VideoHandler struct {
    service *service.VideoService
}

func NewVideoHandler(service *service.VideoService) *VideoHandler {
    return &VideoHandler{service: service}
}

func (h *VideoHandler) UploadVideo(c *gin.Context) {
    userID, exists := c.Get("userID")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
        return
    }
    userIDInt, ok := userID.(int)
    if !ok {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID type"})
        return
    }

    if err := c.Request.ParseMultipartForm(500 << 20); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Failed to parse form"})
        return
    }

    // Получаем файл
    file, header, err := c.Request.FormFile("video")
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Video file is required"})
        return
    }
    defer file.Close()

    if header.Size > 500<<20 {
        c.JSON(http.StatusBadRequest, gin.H{"error": "File too large"})
        return
    }

    title := c.PostForm("title")
    description := c.PostForm("description")
    
    if title == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Title is required"})
        return
    }

    req := model.CreateVideoRequest{
        Title:       title,
        Description: description,
    }

    fileHeader := &model.FileHeader{
        File:     file,
        Filename: header.Filename,
        Size:     header.Size,
    }

    video, err := h.service.CreateVideo(userIDInt, &req, fileHeader)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create video"})
        return
    }

    // Generate presigned URL for immediate client use
    ctx := c.Request.Context()
    presignedURL, err := h.service.GetVideoStreamURL(ctx, video.FilePath)
    if err != nil {
        presignedURL = ""
    }

    c.JSON(http.StatusCreated, gin.H{
        "message": "Video uploaded successfully",
        "video": model.VideoResponse{
            ID:          video.ID,
            Title:       video.Title,
            Description: video.Description,
            FileSize:    video.FileSize,
            FileURL:     presignedURL,
            Status:      video.Status,
            CreatedAt:   video.CreatedAt,
        },
    })
}

// UploadVideoRaw streams a raw request body (e.g., video/mp4) directly to storage.
// Title and description are taken from query params: ?title=...&description=...
func (h *VideoHandler) UploadVideoRaw(c *gin.Context) {
    userID, exists := c.Get("userID")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
        return
    }
    userIDInt, ok := userID.(int)
    if !ok {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid user ID type"})
        return
    }

    title := c.Query("title")
    description := c.Query("description")
    if title == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Title is required"})
        return
    }

    contentType := c.GetHeader("Content-Type")
    if contentType == "" {
        contentType = "application/octet-stream"
    }

    // Derive a pseudo filename from content type
    filename := "upload" + extFromContentType(contentType)

    req := model.CreateVideoRequest{
        Title:       title,
        Description: description,
    }

    video, err := h.service.CreateVideoStream(userIDInt, &req, c.Request.Body, filename, -1, contentType)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create video"})
        return
    }

    // Debug log
    c.Writer.Header().Add("X-Uploaded-Video-ID", strconv.Itoa(video.ID))

    ctx := c.Request.Context()
    presignedURL, err := h.service.GetVideoStreamURL(ctx, video.FilePath)
    if err != nil {
        presignedURL = ""
    }

    c.JSON(http.StatusCreated, gin.H{
        "message": "Video uploaded successfully",
        "video": model.VideoResponse{
            ID:          video.ID,
            Title:       video.Title,
            Description: video.Description,
            FileSize:    video.FileSize,
            FileURL:     presignedURL,
            Status:      video.Status,
            CreatedAt:   video.CreatedAt,
        },
    })
}

func extFromContentType(ct string) string {
    switch ct {
    case "video/mp4":
        return ".mp4"
    case "video/quicktime":
        return ".mov"
    case "video/x-matroska":
        return ".mkv"
    default:
        return filepath.Ext(ct) // likely empty; kept for future mapping
    }
}

func (h *VideoHandler) GetVideos(c *gin.Context) {
    userID, exists := c.Get("userID")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
        return
    }
    userIDInt := userID.(int)

    // Получаем параметры пагинации
    pageStr := c.DefaultQuery("page", "0")
    limitStr := c.DefaultQuery("limit", "0")
    
    page, _ := strconv.Atoi(pageStr)
    limit, _ := strconv.Atoi(limitStr)
    
    // Если limit не указан, возвращаем все видео
    videos, err := h.service.GetUserVideosPaginated(userIDInt, page, limit)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get videos"})
        return
    }

    // Debug header to quickly see counts
    c.Writer.Header().Add("X-Videos-Count", strconv.Itoa(len(videos)))
    c.JSON(http.StatusOK, gin.H{"videos": videos})
}

func (h *VideoHandler) StreamVideo(c *gin.Context) {
    userID, exists := c.Get("userID")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
        return
    }
    userIDInt := userID.(int)

    videoID, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
        return
    }

    video, err := h.service.GetVideo(userIDInt, videoID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Video not found"})
        return
    }

    ctx := c.Request.Context()
    presignedURL, err := h.service.GetVideoStreamURL(ctx, video.FilePath)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate stream URL"})
        return
    }

    c.Redirect(http.StatusTemporaryRedirect, presignedURL)
}

// GetStreamURL returns a JSON with a presigned URL for the video
func (h *VideoHandler) GetStreamURL(c *gin.Context) {
    userID, exists := c.Get("userID")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
        return
    }
    userIDInt := userID.(int)

    videoID, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
        return
    }

    video, err := h.service.GetVideo(userIDInt, videoID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Video not found"})
        return
    }

    ctx := c.Request.Context()
    presignedURL, err := h.service.GetVideoStreamURL(ctx, video.FilePath)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate stream URL"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"url": presignedURL})
}

// StreamVideoProxy streams content through API (supports Range), so clients go via gateway.
func (h *VideoHandler) StreamVideoProxy(c *gin.Context) {
    userID, exists := c.Get("userID")
    if !exists { c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"}); return }
    userIDInt := userID.(int)

    videoID, err := strconv.Atoi(c.Param("id"))
    if err != nil { c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"}); return }

    video, err := h.service.GetVideo(userIDInt, videoID)
    if err != nil { c.JSON(http.StatusNotFound, gin.H{"error": "Video not found"}); return }

    // Stat object
    size, ctype, err := h.service.StatObject(c.Request.Context(), video.FilePath)
    if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to stat object"}); return }

    totalSize := size
    contentType := ctype
    if contentType == "" { contentType = "application/octet-stream" }

    // Parse Range header
    rangeHeader := c.GetHeader("Range")
    var start int64 = 0
    var end int64 = -1
    status := http.StatusOK
    if rangeHeader != "" {
        // bytes=start-end
        re := regexp.MustCompile(`bytes=(\d+)-(\d*)`)
        if m := re.FindStringSubmatch(rangeHeader); len(m) == 3 {
            if s, err := strconv.ParseInt(m[1], 10, 64); err == nil { start = s }
            if m[2] != "" { if e, err := strconv.ParseInt(m[2], 10, 64); err == nil { end = e } }
            if end >= 0 && end >= totalSize { end = totalSize - 1 }
            status = http.StatusPartialContent
        }
    }

    obj, err := h.service.GetObjectRange(c.Request.Context(), video.FilePath, start, end)
    if err != nil { c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to read object"}); return }
    defer obj.Close()

    // Headers
    c.Header("Accept-Ranges", "bytes")
    c.Header("Content-Type", contentType)
    if status == http.StatusPartialContent {
        var contentLen int64
        if end >= 0 {
            contentLen = end - start + 1
            c.Header("Content-Range", "bytes "+strconv.FormatInt(start,10)+"-"+strconv.FormatInt(end,10)+"/"+strconv.FormatInt(totalSize,10))
        } else {
            contentLen = totalSize - start
            c.Header("Content-Range", "bytes "+strconv.FormatInt(start,10)+"-"+strconv.FormatInt(totalSize-1,10)+"/"+strconv.FormatInt(totalSize,10))
        }
        c.Header("Content-Length", strconv.FormatInt(contentLen, 10))
        c.Status(http.StatusPartialContent)
    } else {
        c.Header("Content-Length", strconv.FormatInt(totalSize, 10))
        c.Status(http.StatusOK)
    }

    // Stream copy
    if _, err := io.Copy(c.Writer, obj); err != nil {
        // client aborted or network error; nothing special to do
        return
    }
}