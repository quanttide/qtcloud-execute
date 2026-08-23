package task

import (
	"errors"
	"os"
	"path/filepath"
	"testing"

	"github.com/quanttide/qtcloud-execute-provider/internal/store"
)

// sampleData 对齐 tasks.json 结构的最小样例
const sampleData = `{
  "lists": [
    {
      "id": "qtdata",
      "name": "量潮数据",
      "tasks": [
        {
          "id": "qtdata-project-closeout",
          "title": "客户项目结项推进",
          "description": "结项收尾沟通，落实结项各项事宜",
          "status": "inProgress",
          "priority": "high",
          "category": "business"
        },
        {
          "id": "qtdata-reproduction",
          "title": "客户项目复现",
          "description": "数据契约/蓝图/spec 已完成，数据清洗中",
          "status": "inProgress",
          "priority": "high",
          "category": "product"
        }
      ]
    },
    {
      "id": "qtcloud",
      "name": "量潮云",
      "tasks": [
        {
          "id": "qtcloud-toolkit-refactor",
          "title": "工具库实验室重构",
          "description": "quanttide-platform 分解，quanttide 0.2.0 发布 PyPI",
          "status": "done",
          "priority": "medium",
          "category": "product"
        }
      ]
    }
  ]
}`

// newTestRepo 在临时目录写入 tasks.json 并创建仓库
func newTestRepo(t *testing.T, data string) (*Repository, string) {
	t.Helper()
	dir := t.TempDir()
	dataFile := "data/tasks.json"
	if err := os.MkdirAll(filepath.Join(dir, "data"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, dataFile), []byte(data), 0o644); err != nil {
		t.Fatal(err)
	}
	return NewRepository(store.NewLocalStore(dir), dataFile), dir
}

func TestListLists_Load(t *testing.T) {
	repo, _ := newTestRepo(t, sampleData)

	lists, err := repo.ListLists()
	if err != nil {
		t.Fatalf("ListLists: %v", err)
	}
	if len(lists) != 2 {
		t.Fatalf("期望 2 个清单，实际 %d", len(lists))
	}
	if lists[0].ID != "qtdata" || lists[0].Name != "量潮数据" {
		t.Errorf("清单[0] = %+v, 期望 qtdata/量潮数据", lists[0])
	}
	if len(lists[0].Tasks) != 2 {
		t.Errorf("qtdata 任务数 = %d, 期望 2", len(lists[0].Tasks))
	}
	// category 解析（可空字段，样例中非空）
	t0 := lists[0].Tasks[0]
	if t0.Category == nil || *t0.Category != "business" {
		t.Errorf("category = %v, 期望 business", t0.Category)
	}
}

func TestListTasks_Ok(t *testing.T) {
	repo, _ := newTestRepo(t, sampleData)

	tasks, err := repo.ListTasks("qtdata")
	if err != nil {
		t.Fatalf("ListTasks: %v", err)
	}
	if len(tasks) != 2 {
		t.Fatalf("期望 2 个任务，实际 %d", len(tasks))
	}
	if tasks[0].Status != StatusInProgress {
		t.Errorf("status = %s, 期望 inProgress", tasks[0].Status)
	}
}

func TestListTasks_UnknownList(t *testing.T) {
	repo, _ := newTestRepo(t, sampleData)

	if _, err := repo.ListTasks("no-such-list"); !errors.Is(err, ErrListNotFound) {
		t.Errorf("期望 ErrListNotFound，实际 %v", err)
	}
}

func TestUpdateTask_UpdateExisting(t *testing.T) {
	repo, _ := newTestRepo(t, sampleData)

	updated := Task{
		ID:          "qtdata-project-closeout",
		Title:       "客户项目结项推进",
		Description: "结项收尾沟通，已结项",
		Status:      StatusDone,
		Priority:    PriorityMedium,
	}
	if err := repo.UpdateTask("qtdata", updated); err != nil {
		t.Fatalf("UpdateTask: %v", err)
	}

	// 重新加载验证持久化
	tasks, err := repo.ListTasks("qtdata")
	if err != nil {
		t.Fatalf("ListTasks: %v", err)
	}
	var got *Task
	for i := range tasks {
		if tasks[i].ID == updated.ID {
			got = &tasks[i]
		}
	}
	if got == nil {
		t.Fatal("未找到已更新任务")
	}
	if got.Status != StatusDone || got.Priority != PriorityMedium || got.Description != "结项收尾沟通，已结项" {
		t.Errorf("更新后任务 = %+v，期望 status=done/priority=medium", got)
	}
	if len(tasks) != 2 {
		t.Errorf("任务数 = %d, 期望 2（更新不应增删）", len(tasks))
	}
}

func TestUpdateTask_AppendNew(t *testing.T) {
	repo, _ := newTestRepo(t, sampleData)

	cat := "operation"
	added := Task{
		ID:          "qtdata-new-task",
		Title:       "新任务",
		Description: "upsert 追加",
		Status:      StatusNotStarted,
		Priority:    PriorityLow,
		Category:    &cat,
	}
	if err := repo.UpdateTask("qtdata", added); err != nil {
		t.Fatalf("UpdateTask: %v", err)
	}

	tasks, err := repo.ListTasks("qtdata")
	if err != nil {
		t.Fatalf("ListTasks: %v", err)
	}
	if len(tasks) != 3 {
		t.Fatalf("任务数 = %d, 期望 3（追加）", len(tasks))
	}
	found := false
	for _, tk := range tasks {
		if tk.ID == added.ID && *tk.Category == "operation" {
			found = true
		}
	}
	if !found {
		t.Errorf("追加的任务未找到：%+v", tasks)
	}
}

func TestUpdateTask_UnknownList(t *testing.T) {
	repo, _ := newTestRepo(t, sampleData)

	err := repo.UpdateTask("no-such-list", Task{ID: "t", Title: "t"})
	if !errors.Is(err, ErrListNotFound) {
		t.Errorf("期望 ErrListNotFound，实际 %v", err)
	}
}

func TestListLists_Empty(t *testing.T) {
	// 数据文件不存在 → 空集合，不报错（对齐模板空目录行为）
	repo := NewRepository(store.NewLocalStore(t.TempDir()), "data/tasks.json")

	lists, err := repo.ListLists()
	if err != nil {
		t.Fatalf("ListLists: %v", err)
	}
	if len(lists) != 0 {
		t.Errorf("期望空列表，实际 %d", len(lists))
	}
}
