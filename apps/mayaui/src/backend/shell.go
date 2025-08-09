package main

import (
    "net/http"
    "os/exec"

    "github.com/gin-gonic/gin"
)

//curl -X POST http://localhost:8080/shell -H "Content-Type: application/json" -d "{\"cmd\": \"ls -l\"}"
// shellHandler executes a shell command sent as JSON: { "cmd": "ls -l" }
func shellHandler(c *gin.Context) {
    var req struct {
        Cmd string `json:"cmd"`
    }
    if err := c.ShouldBindJSON(&req); err != nil || req.Cmd == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid JSON or missing 'cmd'"})
        return
    }

    out, err := exec.Command("sh", "-c", req.Cmd).CombinedOutput()
    if err != nil {
        c.JSON(http.StatusOK, gin.H{
            "output": string(out),
            "error":  err.Error(),
        })
        return
    }

    c.JSON(http.StatusOK, gin.H{
        "output": string(out),
    })
}

/*func installApp(filename) {
    //Configuring environmental variables

    DEST_APPS := os.Getenv("DEST_APPS")
    if DEST_APPS == "" {
        DEST_APPS ="/tmp/apps/"
    }
    DEST_IMAGE := os.Getenv("DEST_IMAGE")
    if DEST_IMAGE == "" {
        DEST_IMAGE ="/tmp/imgs/"
    }

    out, err := exec.Command("sh", "-c", "./scripts/deploy.sh "+filename+" "+DEST_IMAGE+" "+DEST_APPS).CombinedOutput()
    if err != nil {
        c.JSON(http.StatusOK, gin.H{
            "output": string(out),
            "error":  err.Error(),
        })
        return
    }
}*/