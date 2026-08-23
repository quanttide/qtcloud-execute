use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

/// 量潮执行云 CLI —— 命令行任务管理（对齐执行云领域模型）
#[derive(Parser)]
#[command(name = "qtcloud-execute", version, about = "量潮执行云 CLI：命令行任务管理")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// 列出任务清单
    Lists,
    /// 列出某清单的任务（显示 title/status/priority/category）
    Tasks {
        /// 清单 ID
        list_id: String,
        /// 按状态过滤（notStarted/inProgress/reviewing/done）
        #[arg(long)]
        status: Option<String>,
    },
    /// 新增任务（status 默认 notStarted）
    Add {
        /// 清单 ID
        list_id: String,
        /// 任务标题
        title: String,
        /// 任务描述
        #[arg(long)]
        description: Option<String>,
        /// 优先级（urgent/high/medium/low，默认 medium）
        #[arg(long)]
        priority: Option<String>,
        /// 分类（如 business/product/operation）
        #[arg(long)]
        category: Option<String>,
    },
    /// 更新任务（按 task ID 定位，未提供的字段保持原值）
    Update {
        /// 清单 ID
        list_id: String,
        /// 任务 ID
        task_id: String,
        /// 状态（notStarted/inProgress/reviewing/done）
        #[arg(long)]
        status: Option<String>,
        /// 优先级（urgent/high/medium/low）
        #[arg(long)]
        priority: Option<String>,
        /// 任务描述
        #[arg(long)]
        description: Option<String>,
        /// 分类
        #[arg(long)]
        category: Option<String>,
    },
}

// ─── 数据模型（对齐 tasks.json 结构） ───

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Task {
    id: String,
    title: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    description: Option<String>,
    status: String,
    priority: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    category: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct List {
    id: String,
    name: String,
    tasks: Vec<Task>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct TaskList {
    lists: Vec<List>,
}

// 领域模型枚举取值（对齐 provider/internal/task）
const STATUSES: [&str; 4] = ["notStarted", "inProgress", "reviewing", "done"];
const PRIORITIES: [&str; 4] = ["urgent", "high", "medium", "low"];

// ─── 数据文件访问 ───

/// 数据文件路径：环境变量 QTCLOUD_EXECUTE_DATA，默认 data/tasks.json
fn data_file() -> PathBuf {
    match std::env::var("QTCLOUD_EXECUTE_DATA") {
        Ok(p) if !p.is_empty() => PathBuf::from(p),
        _ => PathBuf::from("data/tasks.json"),
    }
}

/// 读取数据文件；不存在时返回空结构（`{"lists": []}`）
fn load(path: &PathBuf) -> Result<TaskList, String> {
    match std::fs::read_to_string(path) {
        Ok(raw) => serde_json::from_str(&raw)
            .map_err(|e| format!("JSON 解析失败 {}: {e}", path.display())),
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => {
            Ok(TaskList { lists: Vec::new() })
        }
        Err(e) => Err(format!("无法读取 {}: {e}", path.display())),
    }
}

/// 写回数据文件（2 空格缩进，与 tasks.json 格式一致；父目录不存在时自动创建）
fn save(path: &PathBuf, tl: &TaskList) -> Result<(), String> {
    if let Some(parent) = path.parent() {
        if !parent.as_os_str().is_empty() {
            std::fs::create_dir_all(parent)
                .map_err(|e| format!("无法创建目录 {}: {e}", parent.display()))?;
        }
    }
    let mut data = serde_json::to_string_pretty(tl)
        .map_err(|e| format!("序列化失败: {e}"))?;
    data.push('\n');
    std::fs::write(path, data).map_err(|e| format!("无法写入 {}: {e}", path.display()))
}

/// 按 ID 查找清单（返回索引）
fn find_list(tl: &TaskList, list_id: &str) -> Option<usize> {
    tl.lists.iter().position(|l| l.id == list_id)
}

// ─── 枚举校验 ───

fn check_status(status: &str) -> Result<(), String> {
    if STATUSES.contains(&status) {
        Ok(())
    } else {
        Err(format!(
            "非法状态 `{status}`，可选：{}",
            STATUSES.join("/")
        ))
    }
}

fn check_priority(priority: &str) -> Result<(), String> {
    if PRIORITIES.contains(&priority) {
        Ok(())
    } else {
        Err(format!(
            "非法优先级 `{priority}`，可选：{}",
            PRIORITIES.join("/")
        ))
    }
}

// ─── 子命令实现 ───

/// lists：列出任务清单（数据文件不存在时初始化空结构）
fn lists() {
    let path = data_file();
    if !path.is_file() {
        save(&path, &TaskList { lists: Vec::new() }).unwrap_or_else(|e| {
            eprintln!("错误: {e}");
            std::process::exit(1);
        });
        println!("（暂无清单）已初始化数据文件: {}", path.display());
        return;
    }
    let tl = load(&path).unwrap_or_else(|e| {
        eprintln!("错误: {e}");
        std::process::exit(1);
    });

    if tl.lists.is_empty() {
        println!("（暂无清单）数据文件: {}", path.display());
        return;
    }
    println!("── 任务清单 ──  {}", path.display());
    for l in &tl.lists {
        println!("  {:<12} {}  ({} 个任务)", l.id, l.name, l.tasks.len());
    }
}

/// tasks：列出某清单的任务
fn tasks(list_id: &str, status_filter: Option<&str>) {
    if let Some(s) = status_filter {
        check_status(s).unwrap_or_else(|e| {
            eprintln!("错误: {e}");
            std::process::exit(1);
        });
    }
    let path = data_file();
    let tl = load(&path).unwrap_or_else(|e| {
        eprintln!("错误: {e}");
        std::process::exit(1);
    });
    let idx = find_list(&tl, list_id).unwrap_or_else(|| {
        eprintln!("错误: 清单不存在: {list_id}");
        std::process::exit(1);
    });
    let list = &tl.lists[idx];

    println!("── {} ──  {}", list.name, list.id);
    let tasks: Vec<&Task> = list
        .tasks
        .iter()
        .filter(|t| status_filter.map(|s| t.status == s).unwrap_or(true))
        .collect();
    if tasks.is_empty() {
        println!("  （暂无任务）");
        return;
    }
    for t in &tasks {
        let cat = t.category.as_deref().unwrap_or("-");
        println!(
            "  {:<38} {:<11} {:<7} {}",
            t.title, t.status, t.priority, cat
        );
        if let Some(d) = &t.description {
            println!("      {}  {d}", t.id);
        } else {
            println!("      {}", t.id);
        }
    }
}

/// 生成任务 ID：`{list_id}-{unix秒}`，冲突则自增
fn gen_task_id(list_id: &str, existing: &[String]) -> String {
    let base = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    for i in 0..10000u64 {
        let id = format!("{list_id}-{}", base + i);
        if !existing.contains(&id) {
            return id;
        }
    }
    // 兜底（极端情况）
    format!("{list_id}-{}", base)
}

/// add：新增任务
fn add(list_id: &str, title: &str, description: Option<&str>, priority: Option<&str>, category: Option<&str>) {
    let priority = priority.unwrap_or("medium");
    check_priority(priority).unwrap_or_else(|e| {
        eprintln!("错误: {e}");
        std::process::exit(1);
    });

    let path = data_file();
    let mut tl = load(&path).unwrap_or_else(|e| {
        eprintln!("错误: {e}");
        std::process::exit(1);
    });
    let idx = find_list(&tl, list_id).unwrap_or_else(|| {
        eprintln!("错误: 清单不存在: {list_id}");
        std::process::exit(1);
    });

    let existing_ids: Vec<String> = tl.lists[idx]
        .tasks
        .iter()
        .map(|t| t.id.clone())
        .collect();
    let task_id = gen_task_id(list_id, &existing_ids);
    let task = Task {
        id: task_id.clone(),
        title: title.to_string(),
        description: description.map(String::from),
        status: "notStarted".to_string(),
        priority: priority.to_string(),
        category: category.map(String::from),
    };
    tl.lists[idx].tasks.push(task);
    save(&path, &tl).unwrap_or_else(|e| {
        eprintln!("错误: {e}");
        std::process::exit(1);
    });
    println!("✓ 已新增任务 {task_id} → {title} (notStarted/{priority})");
}

/// update：更新任务
fn update(
    list_id: &str,
    task_id: &str,
    status: Option<&str>,
    priority: Option<&str>,
    description: Option<&str>,
    category: Option<&str>,
) {
    if let Some(s) = status {
        check_status(s).unwrap_or_else(|e| {
            eprintln!("错误: {e}");
            std::process::exit(1);
        });
    }
    if let Some(p) = priority {
        check_priority(p).unwrap_or_else(|e| {
            eprintln!("错误: {e}");
            std::process::exit(1);
        });
    }
    if status.is_none() && priority.is_none() && description.is_none() && category.is_none() {
        eprintln!("错误: 至少提供一项要更新的字段（--status/--priority/--description/--category）");
        std::process::exit(1);
    }

    let path = data_file();
    let mut tl = load(&path).unwrap_or_else(|e| {
        eprintln!("错误: {e}");
        std::process::exit(1);
    });
    let idx = find_list(&tl, list_id).unwrap_or_else(|| {
        eprintln!("错误: 清单不存在: {list_id}");
        std::process::exit(1);
    });
    let title = {
        let t = tl.lists[idx]
            .tasks
            .iter_mut()
            .find(|t| t.id == task_id)
            .unwrap_or_else(|| {
                eprintln!("错误: 任务不存在: {task_id}（清单 {list_id}）");
                std::process::exit(1);
            });

        if let Some(s) = status {
            t.status = s.to_string();
        }
        if let Some(p) = priority {
            t.priority = p.to_string();
        }
        if let Some(d) = description {
            t.description = Some(d.to_string());
        }
        if let Some(c) = category {
            t.category = Some(c.to_string());
        }
        t.title.clone()
    };
    save(&path, &tl).unwrap_or_else(|e| {
        eprintln!("错误: {e}");
        std::process::exit(1);
    });
    println!("✓ 已更新任务 {task_id}：{title}");
}

fn main() {
    let cli = Cli::parse();
    match cli.command {
        Command::Lists => lists(),
        Command::Tasks { list_id, status } => tasks(&list_id, status.as_deref()),
        Command::Add {
            list_id,
            title,
            description,
            priority,
            category,
        } => add(
            &list_id,
            &title,
            description.as_deref(),
            priority.as_deref(),
            category.as_deref(),
        ),
        Command::Update {
            list_id,
            task_id,
            status,
            priority,
            description,
            category,
        } => update(
            &list_id,
            &task_id,
            status.as_deref(),
            priority.as_deref(),
            description.as_deref(),
            category.as_deref(),
        ),
    }
}
