package model

import "mime/multipart"

type FileHeader struct {
    File     multipart.File
    Filename string
    Size     int64
}