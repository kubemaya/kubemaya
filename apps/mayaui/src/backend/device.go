package main

import (
    "net/http"

    "github.com/gin-gonic/gin"
    "github.com/shirou/gopsutil/v3/cpu"
    "github.com/shirou/gopsutil/v3/disk"
    "github.com/shirou/gopsutil/v3/mem"
)

// DeviceInfo holds memory, swap, cpu, and disk info
type DeviceInfo struct {
    MemoryTotal     uint64  `json:"memory_total"`
    MemoryAvailable uint64  `json:"memory_available"`
    SwapTotal       uint64  `json:"swap_total"`
    SwapFree        uint64  `json:"swap_free"`
    CPUPercent      float64 `json:"cpu_percent"`
    DiskTotal       uint64  `json:"disk_total"`
    DiskFree        uint64  `json:"disk_free"`
}

// DeviceHandler handles GET /device and returns system info as JSON
func DeviceHandler(c *gin.Context) {
    // Memory
    vmStat, err := mem.VirtualMemory()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get memory info"})
        return
    }

    // Swap
    swapStat, err := mem.SwapMemory()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get swap info"})
        return
    }

    // CPU (average over 1 second)
    cpuPercents, err := cpu.Percent(0, false)
    if err != nil || len(cpuPercents) == 0 {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get CPU info"})
        return
    }

    // Disk (root partition)
    diskStat, err := disk.Usage("/")
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to get disk info"})
        return
    }

    info := DeviceInfo{
        MemoryTotal:     vmStat.Total,
        MemoryAvailable: vmStat.Available,
        SwapTotal:       swapStat.Total,
        SwapFree:        swapStat.Free,
        CPUPercent:      cpuPercents[0],
        DiskTotal:       diskStat.Total,
        DiskFree:        diskStat.Free,
    }

    c.JSON(http.StatusOK, info)
}