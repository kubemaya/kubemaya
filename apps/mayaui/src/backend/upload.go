package main

import (
    "os"
	"log"
    //"path/filepath"
    "github.com/gin-gonic/gin"
    "net/http"
)

// UploadHandler handles POST /upload and saves the uploaded file to a directory
func UploadHandler(c *gin.Context) {
    file, _ := c.FormFile("file")
    log.Println(file.Filename)

    // Upload the file to specific dst.
	// Get upload directory from environment variable or use default

    DEST_UPLOAD := os.Getenv("DEST_UPLOAD")
    if DEST_UPLOAD == "" {
        DEST_UPLOAD ="/tmp/upload/"
    }

    c.SaveUploadedFile(file, DEST_UPLOAD + file.Filename)
    installApp(file.Filename)
    c.JSON(http.StatusOK, gin.H{"message": "App Uploaded & Scheduled to be installed", "filename": file.Filename})
}