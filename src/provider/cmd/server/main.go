// qtcloud-execute provider：量潮任务执行服务端（任务清单 API）
//
// 数据源兼容本地与云端（QTCLOUD_EXECUTE_STORE）：
//
//	local（默认）— 直读本地文件系统（任务数据文件），本地测试友好
//	oss          — 阿里云 OSS（多端共享），凭证见 store.NewOSSStoreFromEnv
//
// 数据路径：QTCLOUD_EXECUTE_DATA（默认 data/tasks.json，相对当前工作目录）
// 监听地址：QTCLOUD_EXECUTE_ADDR（默认 :8080）
package main

import (
	"log"
	"net/http"
	"os"

	"github.com/quanttide/qtcloud-execute-provider/internal/store"
	"github.com/quanttide/qtcloud-execute-provider/internal/task"
)

func main() {
	dataFile := os.Getenv("QTCLOUD_EXECUTE_DATA")
	if dataFile == "" {
		dataFile = "data/tasks.json"
	}

	var st store.Store
	switch os.Getenv("QTCLOUD_EXECUTE_STORE") {
	case "oss":
		ossStore, err := store.NewOSSStoreFromEnv()
		if err != nil {
			log.Fatalf("OSS 数据源初始化失败：%v", err)
		}
		st = ossStore
		log.Printf("数据源：OSS（bucket=%s）", os.Getenv("ALIYUN_OSS_BUCKET"))
	default:
		st = store.NewLocalStore("")
		log.Printf("数据源：本地（data=%s）", dataFile)
	}

	repo := task.NewRepository(st, dataFile)
	h := task.NewHandler(repo)

	mux := http.NewServeMux()
	mux.HandleFunc("GET /api/lists", h.ListLists)
	mux.HandleFunc("GET /api/lists/{id}/tasks", h.ListTasks)
	mux.HandleFunc("PUT /api/lists/{id}/tasks/{taskId}", h.UpdateTask)
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"status":"ok"}`))
	})

	addr := os.Getenv("QTCLOUD_EXECUTE_ADDR")
	if addr == "" {
		addr = ":8080"
	}
	log.Printf("qtcloud-execute provider listening on %s", addr)
	if err := http.ListenAndServe(addr, mux); err != nil {
		log.Fatal(err)
	}
}
