package main

import (
    "net/http"
	"fmt"
    "github.com/gin-gonic/gin"
	"github.com/gin-contrib/static"
)

func main() {
    router := gin.Default()
    router.MaxMultipartMemory = 8 << 20  // 8 MiB
    gin.SetMode(gin.DebugMode)
    router.Use(gin.Logger())
    // Example GET endpoint
    router.GET("/hello", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "message": "Hello, world!",
        })
    })
    // Shell endpoint
    router.POST("/shell", shellHandler)
    router.GET("/pods", K8sPodsHandler)

    router.GET("/deployments", K8sDeploymentsHandler)    
    router.GET("/device", DeviceHandler)
    router.DELETE("/namespace/:name", DeleteNamespaceHandler)
    router.POST("/restart", RestartDeploymentHandler)
    router.GET("/apps", GetNonSystemDeploymentsHandler)
    router.GET("/namespaces", GetNonSystemNamespacesHandler)
    router.POST("/upload", UploadHandler)

    router.Use(static.Serve("/", static.LocalFile("../frontend/dist/spa", true)))//../frontend/dist/spa

	router.NoRoute(func(c *gin.Context) {
		fmt.Printf("%s doesn't exists, redirect on /\n", c.Request.URL.Path)
		c.Redirect(http.StatusMovedPermanently, "/")
	})

    // Listen and serve on 0.0.0.0:8080
    router.Run(":8080")
}
/*package main

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

func main() {
    router := gin.Default()

    // API routes
    router.GET("/hello", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "message": "Hello, world!",
        })
    })
    router.POST("/shell", shellHandler)
    router.GET("/pods", K8sPodsHandler)
    router.GET("/deployments", K8sDeploymentsHandler)
    router.GET("/device", DeviceHandler)
    router.DELETE("/namespace/:name", DeleteNamespaceHandler)
    router.POST("/restart", RestartDeploymentHandler)
    router.GET("/apps", GetNonSystemDeploymentsHandler)
    router.GET("/namespaces", GetNonSystemNamespacesHandler)

    // Serve static files for frontend (Quasar build)
    router.StaticFS("/", http.Dir("../frontend/dist/spa"))

    // Catch-all: serve index.html for SPA routes (except API routes)
    router.NoRoute(func(c *gin.Context) {
        // Only serve index.html for non-API routes
        if c.Request.Method == "GET" && !isApiRoute(c.Request.URL.Path) {
            c.File("../frontend/dist/spa/index.html")
        } else {
            c.JSON(http.StatusNotFound, gin.H{"error": "Not found"})
        }
    })

    router.Run(":8080")
}

// Helper to check if the path is an API route
func isApiRoute(path string) bool {
    apiPrefixes := []string{
        "/hello", "/shell", "/pods", "/deployments", "/device",
        "/namespace/", "/restart", "/apps", "/namespaces",
    }
    for _, prefix := range apiPrefixes {
        if len(path) >= len(prefix) && path[:len(prefix)] == prefix {
            return true
        }
    }
    return false
}*/