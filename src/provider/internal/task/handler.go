package task

import (
	"encoding/json"
	"errors"
	"net/http"
)

// Handler 任务清单 HTTP 处理器
type Handler struct {
	repo *Repository
}

// NewHandler 创建处理器
func NewHandler(repo *Repository) *Handler {
	return &Handler{repo: repo}
}

// ListLists 处理 GET /api/lists
func (h *Handler) ListLists(w http.ResponseWriter, r *http.Request) {
	lists, err := h.repo.ListLists()
	if err != nil {
		http.Error(w, "清单加载失败："+err.Error(), http.StatusInternalServerError)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"lists": lists})
}

// ListTasks 处理 GET /api/lists/{id}/tasks
func (h *Handler) ListTasks(w http.ResponseWriter, r *http.Request) {
	listID := r.PathValue("id")
	tasks, err := h.repo.ListTasks(listID)
	if err != nil {
		if errors.Is(err, ErrListNotFound) {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}
		http.Error(w, "任务加载失败："+err.Error(), http.StatusInternalServerError)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"tasks": tasks})
}

// UpdateTask 处理 PUT /api/lists/{id}/tasks/{taskId}
func (h *Handler) UpdateTask(w http.ResponseWriter, r *http.Request) {
	listID := r.PathValue("id")
	taskID := r.PathValue("taskId")

	var t Task
	if err := json.NewDecoder(r.Body).Decode(&t); err != nil {
		http.Error(w, "请求体解析失败："+err.Error(), http.StatusBadRequest)
		return
	}
	if t.ID == "" {
		t.ID = taskID
	}
	if t.ID != taskID {
		http.Error(w, "路径 taskId 与请求体 id 不一致", http.StatusBadRequest)
		return
	}
	if err := h.repo.UpdateTask(listID, t); err != nil {
		if errors.Is(err, ErrListNotFound) {
			http.Error(w, err.Error(), http.StatusNotFound)
			return
		}
		http.Error(w, "任务更新失败："+err.Error(), http.StatusInternalServerError)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"task": t})
}

func writeJSON(w http.ResponseWriter, code int, v any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(v)
}
