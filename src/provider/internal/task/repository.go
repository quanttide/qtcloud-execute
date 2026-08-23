// Package task 任务清单数据访问（直读数据文件，不依赖 CLI）。
package task

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"

	"github.com/quanttide/qtcloud-execute-provider/internal/store"
)

// 任务状态（对齐 tasks.json 取值）
const (
	StatusNotStarted = "notStarted"
	StatusInProgress = "inProgress"
	StatusReviewing  = "reviewing"
	StatusDone       = "done"
)

// 任务优先级（对齐 tasks.json 取值）
const (
	PriorityUrgent = "urgent"
	PriorityHigh   = "high"
	PriorityMedium = "medium"
	PriorityLow    = "low"
)

// Task 任务
type Task struct {
	ID          string  `json:"id"`
	Title       string  `json:"title"`
	Description string  `json:"description"`
	Status      string  `json:"status"`
	Priority    string  `json:"priority"`
	Category    *string `json:"category,omitempty"`
}

// List 任务清单
type List struct {
	ID    string `json:"id"`
	Name  string `json:"name"`
	Tasks []Task `json:"tasks"`
}

// TaskList 任务清单集合（数据文件顶层结构）
type TaskList struct {
	Lists []List `json:"lists"`
}

// ErrListNotFound 清单不存在
var ErrListNotFound = errors.New("清单不存在")

// Repository 任务清单数据访问
type Repository struct {
	st       store.Store
	dataFile string // 数据文件路径（如 data/tasks.json）
}

// NewRepository 创建仓库（st 为数据源；dataFile 为任务数据文件路径，如 data/tasks.json）
func NewRepository(st store.Store, dataFile string) *Repository {
	return &Repository{st: st, dataFile: dataFile}
}

// load 读取并解析数据文件（文件不存在返回空集合）
func (r *Repository) load() (*TaskList, error) {
	raw, err := r.st.Get(r.dataFile)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return &TaskList{Lists: []List{}}, nil
		}
		return nil, err
	}
	var tl TaskList
	if err := json.Unmarshal(raw, &tl); err != nil {
		return nil, fmt.Errorf("解析任务数据失败：%w", err)
	}
	return &tl, nil
}

// save 写回数据文件
func (r *Repository) save(tl *TaskList) error {
	data, err := json.MarshalIndent(tl, "", "  ")
	if err != nil {
		return err
	}
	return r.st.Put(r.dataFile, data)
}

// ListLists 返回全部清单（含各自任务）
func (r *Repository) ListLists() ([]List, error) {
	tl, err := r.load()
	if err != nil {
		return nil, err
	}
	return tl.Lists, nil
}

// ListTasks 返回指定清单的任务列表（清单不存在返回 ErrListNotFound）
func (r *Repository) ListTasks(listID string) ([]Task, error) {
	tl, err := r.load()
	if err != nil {
		return nil, err
	}
	for _, l := range tl.Lists {
		if l.ID == listID {
			return l.Tasks, nil
		}
	}
	return nil, ErrListNotFound
}

// UpdateTask 更新指定清单中的任务（按 task.ID 定位；任务不存在则追加，upsert 语义；
// 清单不存在返回 ErrListNotFound）
func (r *Repository) UpdateTask(listID string, task Task) error {
	tl, err := r.load()
	if err != nil {
		return err
	}
	for i := range tl.Lists {
		if tl.Lists[i].ID != listID {
			continue
		}
		for j := range tl.Lists[i].Tasks {
			if tl.Lists[i].Tasks[j].ID == task.ID {
				tl.Lists[i].Tasks[j] = task
				return r.save(tl)
			}
		}
		tl.Lists[i].Tasks = append(tl.Lists[i].Tasks, task)
		return r.save(tl)
	}
	return ErrListNotFound
}
