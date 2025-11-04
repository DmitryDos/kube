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

    fileHeader := &model.FileHeader{
        File:     file,
        Filename: header.Filename,
        Size:     header.Size,
    }

    video, err := h.service.CreateVideoFile(userIDInt, fileHeader)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to upload video"})
        return
    }

    ctx := c.Request.Context()
    presignedURL, err := h.service.GetVideoStreamURL(ctx, video.FilePath)
    if err != nil {
        h.service.DeleteVideo(userIDInt, video.ID)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate stream URL"})
        return
    }

    c.JSON(http.StatusCreated, gin.H{
        "message": "Video uploaded successfully",
        "video": model.VideoResponse{
            ID:          video.ID,
            Title:       video.Title,
            Description: video.Description,
            UserID:      video.UserID,
            FileSize:    video.FileSize,
            FileURL:     presignedURL,
            Status:      video.Status,
            CreatedAt:   video.CreatedAt,
        },
    })
}

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

    contentType := c.GetHeader("Content-Type")
    if contentType == "" {
        contentType = "application/octet-stream"
    }

    video, err := h.service.CreateVideoStream(userIDInt, c.Request.Body, "video", -1, contentType)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create video"})
        return
    }

    c.Writer.Header().Add("X-Uploaded-Video-ID", strconv.Itoa(video.ID))

    ctx := c.Request.Context()
    presignedURL, err := h.service.GetVideoStreamURL(ctx, video.FilePath)
    if err != nil {
        h.service.DeleteVideo(userIDInt, video.ID)
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate stream URL"})
        return
    }

    c.JSON(http.StatusCreated, gin.H{
        "message": "Video uploaded successfully",
        "video": model.VideoResponse{
            ID:          video.ID,
            Title:       video.Title,
            Description: video.Description,
            UserID:      video.UserID,
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
    case "video/x-m4v":
        return ".m4v"
    default:
        return ".bin"
    }
}

func (h *VideoHandler) GetVideos(c *gin.Context) {
    userID, exists := c.Get("userID")
    if !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
        return
    }
    userIDInt := userID.(int)

    pageStr := c.DefaultQuery("page", "0")
    limitStr := c.DefaultQuery("limit", "0")
    
    page, _ := strconv.Atoi(pageStr)
    limit, _ := strconv.Atoi(limitStr)
    
    videos, err := h.service.GetUserVideosPaginated(userIDInt, page, limit)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get videos"})
        return
    }

    c.Writer.Header().Add("X-Videos-Count", strconv.Itoa(len(videos)))
    c.JSON(http.StatusOK, gin.H{"videos": videos})
}

func (h *VideoHandler) SearchAllVideos(c *gin.Context) {
    if _, exists := c.Get("userID"); !exists {
        c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"})
        return
    }

    pageStr := c.DefaultQuery("page", "0")
    limitStr := c.DefaultQuery("limit", "20")
    q := c.DefaultQuery("q", "")
    userIDStr := c.DefaultQuery("user_id", "")
    mine := c.DefaultQuery("mine", "false")

    page, _ := strconv.Atoi(pageStr)
    limit, _ := strconv.Atoi(limitStr)
    var filterUserID *int
    if mine == "true" {
        if uid, ok := c.Get("userID"); ok {
            if v, ok2 := uid.(int); ok2 { filterUserID = &v }
        }
    } else if userIDStr != "" {
        if v, err := strconv.Atoi(userIDStr); err == nil { filterUserID = &v }
    }

    videos, err := h.service.GetAllVideosPaginated(q, filterUserID, page, limit)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to search videos"})
        return
    }

    c.JSON(http.StatusOK, gin.H{"videos": videos})
}

func (h *VideoHandler) StreamVideo(c *gin.Context) {
    videoID, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
        return
    }

    video, err := h.service.GetVideoPublic(videoID)
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

func (h *VideoHandler) GetStreamURL(c *gin.Context) {
    videoID, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
        return
    }

    video, err := h.service.GetVideoPublic(videoID)
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

func (h *VideoHandler) StreamVideoProxy(c *gin.Context) {
    videoID, err := strconv.Atoi(c.Param("id"))
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"})
        return
    }

    video, err := h.service.GetVideoPublic(videoID)
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Video not found"})
        return
    }

    rangeHeader := c.GetHeader("Range")
    var start, end int64 = 0, -1

    if rangeHeader != "" {
        re := regexp.MustCompile(`bytes=(\d+)-(\d*)`)
        matches := re.FindStringSubmatch(rangeHeader)
        if len(matches) == 3 {
            start, _ = strconv.ParseInt(matches[1], 10, 64)
            if matches[2] != "" {
                end, _ = strconv.ParseInt(matches[2], 10, 64)
            }
        }
    }

    ctx := c.Request.Context()
    totalSize, contentType, err := h.service.StatObject(ctx, video.FilePath)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get video info"})
        return
    }

    if end < 0 || end >= totalSize {
        end = totalSize - 1
    }

    obj, err := h.service.GetObjectRange(ctx, video.FilePath, start, end)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to stream video"})
        return
    }
    defer obj.Close()

    status := http.StatusOK
    if rangeHeader != "" {
        status = http.StatusPartialContent
    }

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

    if _, err := io.Copy(c.Writer, obj); err != nil {
        return
    }
}

func (h *VideoHandler) DeleteVideo(c *gin.Context) {
    userID, exists := c.Get("userID")
    if !exists { c.JSON(http.StatusUnauthorized, gin.H{"error": "User ID not found in context"}); return }
    userIDInt := userID.(int)
    videoID, err := strconv.Atoi(c.Param("id"))
    if err != nil { c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid video ID"}); return }
    if err := h.service.DeleteVideo(userIDInt, videoID); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete video"})
        return
    }
    c.Status(http.StatusNoContent)
}

