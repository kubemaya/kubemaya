package main

import (
    "archive/tar"
    "compress/gzip"
    "io"
    "os"
    "path/filepath"
    "strings"
    "time"
    "os/exec"
	"log"

)

// untarFile extracts DEST_UPLOAD/filename into DEST_UPLOAD/{filename-without-tgz}/
func installApp(filename string) error {
    appName := strings.ReplaceAll(filename, ".tgz", "")

    DEST_UPLOAD := os.Getenv("DEST_UPLOAD")
    if DEST_UPLOAD == "" {
        DEST_UPLOAD ="/tmp/upload"
    }

    DEST_APPS := os.Getenv("DEST_APPS")
    if DEST_APPS == "" {
        DEST_APPS ="/tmp/apps"
    }	

    DEST_IMAGE := os.Getenv("DEST_IMAGE")
    if DEST_IMAGE == "" {
        DEST_IMAGE ="/tmp/imgs"
    }	

    out, err := exec.Command("sh", "-c", "rm -R "+DEST_APPS+appName+" || echo 'Nothing to delete'").CombinedOutput()
    if err != nil {
        log.Println(appName)
        log.Println("output:", string(out))
        log.Println("error:", err.Error())
        return err
    }

    src := filepath.Join(DEST_UPLOAD, filename)
    dest := filepath.Join(DEST_APPS, appName)

    var f *os.File
    //var err error
    for i := 0; i < 3; i++ {
        f, err = os.Open(src)
        if err == nil {
            break
        }
        time.Sleep(2 * time.Second)
    }
    if err != nil {
        return err
    }
    defer f.Close()

    gz, _ := gzip.NewReader(f)
    defer gz.Close()
    tr := tar.NewReader(gz)
    os.MkdirAll(dest, 0755)

    for {
        hdr, err := tr.Next()
        if err == io.EOF {
            break
        }
        target := filepath.Join(dest, hdr.Name)
        switch hdr.Typeflag {
        case tar.TypeDir:
            os.MkdirAll(target, 0755)
        case tar.TypeReg:
            out, _ := os.Create(target)
            io.Copy(out, tr)
            out.Close()
        }
    }
    time.Sleep(10 * time.Second)
	log.Println("./scripts/deploy.sh deployapp "+appName+" "+DEST_IMAGE+" "+DEST_APPS)
	out, errRun := exec.Command("sh", "-c","./scripts/deploy.sh deployapp "+appName+" "+DEST_IMAGE+" "+DEST_APPS).CombinedOutput()
    if errRun != nil {
        log.Println(appName)
        log.Println("output:", string(out))
        log.Println("error:", errRun.Error())
        return errRun
    } else {
        log.Println("output:", string(out))
	}
    return nil
}