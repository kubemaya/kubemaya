package main

import (
    "context"
    "net/http"
    "os"

    "github.com/gin-gonic/gin"
    metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
    "k8s.io/client-go/kubernetes"
    "k8s.io/client-go/rest"
    "k8s.io/client-go/tools/clientcmd"
)

// PodInfo holds basic pod data for the API response
type PodInfo struct {
    Name      string `json:"name"`
    Namespace string `json:"namespace"`
    Status    string `json:"status"`
}

// getK8sClient returns a Kubernetes clientset, using in-cluster config if available, otherwise falling back to kubeconfig
func getK8sClient() (*kubernetes.Clientset, error) {
    // Try in-cluster config
    config, err := rest.InClusterConfig()
    if err != nil {
        // Fallback to kubeconfig
        kubeconfig := os.Getenv("KUBECONFIG")
        if kubeconfig == "" {
            home, _ := os.UserHomeDir()
            kubeconfig = home + "/.kube/config"
        }
        config, err = clientcmd.BuildConfigFromFlags("", kubeconfig)
        if err != nil {
            return nil, err
        }
    }
    return kubernetes.NewForConfig(config)
}

// K8sPodsHandler handles GET /k8s and returns pods info as JSON
func K8sPodsHandler(c *gin.Context) {
    clientset, err := getK8sClient()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not create k8s client: " + err.Error()})
        return
    }

    pods, err := clientset.CoreV1().Pods("").List(context.Background(), metav1.ListOptions{})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not list pods: " + err.Error()})
        return
    }

    var result []PodInfo
    for _, pod := range pods.Items {
        status := string(pod.Status.Phase)
        result = append(result, PodInfo{
            Name:      pod.Name,
            Namespace: pod.Namespace,
            Status:    status,
        })
    }

    c.JSON(http.StatusOK, result)
}

//curl -X DELETE http://localhost:8080/namespace/YOUR_NAMESPACE
// DeleteNamespaceHandler handles DELETE /namespace/:name and deletes the given namespace
func DeleteNamespaceHandler(c *gin.Context) {
    name := c.Param("name")
    if name == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Namespace name is required"})
        return
    }

    clientset, err := getK8sClient()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not create k8s client: " + err.Error()})
        return
    }

    err = clientset.CoreV1().Namespaces().Delete(context.Background(), name, metav1.DeleteOptions{})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not delete namespace: " + err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Namespace deleted", "namespace": name})
}


// DeploymentInfo holds basic deployment data for the API response
type DeploymentInfo struct {
    Name      string `json:"name"`
    Namespace string `json:"namespace"`
    Status    string `json:"status"`
}

// K8sDeploymentsHandler handles GET /k8s2 and returns deployments info as JSON
func K8sDeploymentsHandler(c *gin.Context) {
    clientset, err := getK8sClient()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not create k8s client: " + err.Error()})
        return
    }

    deployments, err := clientset.AppsV1().Deployments("").List(context.Background(), metav1.ListOptions{})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not list deployments: " + err.Error()})
        return
    }

    var result []DeploymentInfo
    for _, deploy := range deployments.Items {
        status := "Unknown"
        if deploy.Status.AvailableReplicas == *deploy.Spec.Replicas {
            status = "Available"
        } else if deploy.Status.AvailableReplicas == 0 {
            status = "Unavailable"
        } else {
            status = "Progressing"
        }
        result = append(result, DeploymentInfo{
            Name:      deploy.Name,
            Namespace: deploy.Namespace,
            Status:    status,
        })
    }

    c.JSON(http.StatusOK, result)
}

// RestartDeploymentHandler handles POST /restart and restarts a deployment by updating its annotation
func RestartDeploymentHandler(c *gin.Context) {
    var req struct {
        Namespace string `json:"namespace"`
        Name      string `json:"name"`
    }
    if err := c.ShouldBindJSON(&req); err != nil || req.Namespace == "" || req.Name == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Namespace and name are required"})
        return
    }

    clientset, err := getK8sClient()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not create k8s client: " + err.Error()})
        return
    }

    // Get the deployment
    deploy, err := clientset.AppsV1().Deployments(req.Namespace).Get(context.Background(), req.Name, metav1.GetOptions{})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not get deployment: " + err.Error()})
        return
    }

    // Patch the deployment with a new annotation to trigger a rolling restart
    if deploy.Spec.Template.Annotations == nil {
        deploy.Spec.Template.Annotations = map[string]string{}
    }
    deploy.Spec.Template.Annotations["kubectl.kubernetes.io/restartedAt"] = metav1.Now().Format("2006-01-02T15:04:05Z07:00")

    _, err = clientset.AppsV1().Deployments(req.Namespace).Update(context.Background(), deploy, metav1.UpdateOptions{})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not restart deployment: " + err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Deployment restarted", "namespace": req.Namespace, "name": req.Name})
}

// GetNonSystemDeploymentsHandler handles GET /deployments and returns deployments not in kube-system
func GetNonSystemDeploymentsHandler(c *gin.Context) {
    clientset, err := getK8sClient()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not create k8s client: " + err.Error()})
        return
    }

    deployments, err := clientset.AppsV1().Deployments("").List(context.Background(), metav1.ListOptions{})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not list deployments: " + err.Error()})
        return
    }

    type SimpleDeployment struct {
        Name      string `json:"name"`
        Namespace string `json:"namespace"`
    }

    var result []SimpleDeployment
    for _, deploy := range deployments.Items {
        if deploy.Namespace == "kube-system" {
            continue
        }
        result = append(result, SimpleDeployment{
            Name:      deploy.Name,
            Namespace: deploy.Namespace,
        })
    }

    c.JSON(http.StatusOK, result)
}

// GetNonSystemNamespacesHandler handles GET /namespaces and returns all namespaces except those starting with "kube-"
func GetNonSystemNamespacesHandler(c *gin.Context) {
    clientset, err := getK8sClient()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not create k8s client: " + err.Error()})
        return
    }

    nsList, err := clientset.CoreV1().Namespaces().List(context.Background(), metav1.ListOptions{})
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not list namespaces: " + err.Error()})
        return
    }

    var namespaces []string
    for _, ns := range nsList.Items {
        if len(ns.Name) >= 5 && ns.Name[:5] == "kube-" {
            continue
        }
        if ns.Name == "default" {
            continue
        }
        if ns.Name == "kubemaya" {
            continue
        }        
        namespaces = append(namespaces, ns.Name)
    }

    c.JSON(http.StatusOK, namespaces)
}