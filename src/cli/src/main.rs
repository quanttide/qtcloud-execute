use clap::{Parser, Subcommand};
use serde::{Deserialize, Serialize};
use std::time::{SystemTime, UNIX_EPOCH};

/// 量潮执行云 CLI —— 云端任务 API 的辅助入口（主要供 AI 使用）
///
/// 纯服务端客户端：只对接已部署 provider 的 HTTP 接口，不读写本地文件。
/// API 基地址：`--server <BASE_URL>` > 环境变量 `QTCLOUD_EXECUTE_API_BASE_URL` > 默认系统级网关
/// `https://api.quanttide.com/qtcloud-execute`（与 studio/delib 约定一致）。
#[derive(Parser)]
#[command(name = "qtcloud-execute", version, about = "量潮执行云 CLI：云端任务管理（AI 辅助入口）")]
struct Cli {
    /// API 基地址覆盖（默认 https://api.quanttide.com/qtcloud-execute；未设时读环境变量 QTCLOUD_EXECUTE_API_BASE_URL）
    #[arg(long, global = true)]
    server: Option<String>,
    /// 以 JSON 输出（AI 友好，直接透传服务端响应）
    #[arg(long, global = true)]
    json: bool,

    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// 列出任务清单
    Lists,
    /// 列出某清单的任务（显示 title/status/priority）
    Tasks {
        /// 清单 ID
        list_id: String,
        /// 按状态过滤（notStarted/inProgress/reviewing/done）
        #[arg(long)]
        status: Option<String>,
    },
    /// 新增任务（status 默认 notStarted；task ID 由 CLI 生成后 PUT）
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
        /// 状态（notStarted/inProgress/reviewing/done，默认 notStarted）
        #[arg(long)]
        status: Option<String>,
    },
    /// 更新任务（按 task ID 定位；未提供的字段保持原值，先 GET 合并再 PUT 全量）
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
    },
}

// ─── 数据模型（对齐 provider/internal/task） ───

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Task {
    id: String,
    title: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    description: Option<String>,
    status: String,
    priority: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct List {
    id: String,
    name: String,
    tasks: Vec<Task>,
}

/// GET /api/lists 的响应包装
#[derive(Debug, Clone, Deserialize)]
struct ListsResp {
    lists: Vec<List>,
}

/// GET /api/lists/{id}/tasks 的响应包装
#[derive(Debug, Clone, Deserialize)]
struct TasksResp {
    tasks: Vec<Task>,
}

// 领域模型枚举取值（对齐 provider/internal/task）
const STATUSES: [&str; 4] = ["notStarted", "inProgress", "reviewing", "done"];
const PRIORITIES: [&str; 4] = ["urgent", "high", "medium", "low"];

fn exit_err(e: &str) -> ! {
    eprintln!("错误: {e}");
    std::process::exit(1);
}

/// 生产 API 基地址（系统级 API 网关，与 studio/delib 约定一致）；`QTCLOUD_EXECUTE_API_BASE_URL` 可覆盖，`--server` 优先。
const DEFAULT_API_BASE: &str = "https://api.quanttide.com/qtcloud-execute";

/// 解析 API 基地址：--server 参数 > 环境变量 QTCLOUD_EXECUTE_API_BASE_URL > 默认网关
fn resolve_base(cli_server: &Option<String>) -> String {
    if let Some(s) = cli_server {
        if !s.trim().is_empty() {
            return s.trim_end_matches('/').to_string();
        }
    }
    match std::env::var("QTCLOUD_EXECUTE_API_BASE_URL") {
        Ok(s) if !s.trim().is_empty() => s.trim_end_matches('/').to_string(),
        _ => DEFAULT_API_BASE.to_string(),
    }
}

// ─── HTTP 访问 ───

/// 发送 HTTP 请求并解析 JSON 响应（2xx 成功；否则返回错误）
fn http_json(method: &str, url: &str, body: Option<&str>) -> Result<serde_json::Value, String> {
    let resp = match method {
        "GET" => ureq::get(url).call(),
        "PUT" => ureq::put(url)
            .set("Content-Type", "application/json")
            .send_string(body.unwrap_or("")),
        _ => return Err(format!("不支持的 HTTP 方法: {method}")),
    };
    let resp = resp.map_err(|e| match e {
        ureq::Error::Status(code, r) => format!("HTTP {code}: {}", r.into_string().unwrap_or_default()),
        other => format!("请求 {url} 失败: {other}"),
    })?;
    let code = resp.status();
    let text = resp
        .into_string()
        .map_err(|e| format!("读取响应失败: {e}"))?;
    if (200..300).contains(&code) {
        serde_json::from_str(&text).map_err(|e| format!("JSON 解析失败: {e}"))
    } else {
        Err(format!("HTTP {code}: {text}"))
    }
}

/// 拉取某清单全部任务（用于 id 去重 / update 合并）
fn http_tasks(base: &str, list_id: &str) -> Result<Vec<Task>, String> {
    let v = http_json("GET", &format!("{base}/api/lists/{list_id}/tasks"), None)?;
    let r: TasksResp = serde_json::from_value(v).map_err(|e| format!("解析任务响应失败: {e}"))?;
    Ok(r.tasks)
}

// ─── 枚举校验 ───

fn check_status(status: &str) -> Result<(), String> {
    if STATUSES.contains(&status) {
        Ok(())
    } else {
        Err(format!("非法状态 `{status}`，可选：{}", STATUSES.join("/")))
    }
}

fn check_priority(priority: &str) -> Result<(), String> {
    if PRIORITIES.contains(&priority) {
        Ok(())
    } else {
        Err(format!("非法优先级 `{priority}`，可选：{}", PRIORITIES.join("/")))
    }
}

fn ensure_update_fields(status: Option<&str>, priority: Option<&str>, description: Option<&str>) {
    if status.is_none() && priority.is_none() && description.is_none() {
        exit_err("至少提供一项要更新的字段（--status/--priority/--description）");
    }
    if let Some(s) = status {
        if let Err(e) = check_status(s) {
            exit_err(&e);
        }
    }
    if let Some(p) = priority {
        if let Err(e) = check_priority(p) {
            exit_err(&e);
        }
    }
}

// ─── 子命令实现 ───

/// lists：GET /api/lists
fn lists(base: &str, json: bool) {
    let v = http_json("GET", &format!("{base}/api/lists"), None).unwrap_or_else(|e| exit_err(&e));
    if json {
        println!("{}", serde_json::to_string(&v).unwrap());
        return;
    }
    let r: ListsResp = serde_json::from_value(v).unwrap_or_else(|e| exit_err(&format!("解析清单失败: {e}")));
    if r.lists.is_empty() {
        println!("（暂无清单）服务器: {base}");
        return;
    }
    println!("── 任务清单 ──  {base}");
    for l in &r.lists {
        println!("  {:<12} {}  ({} 个任务)", l.id, l.name, l.tasks.len());
    }
}

/// tasks：GET /api/lists/{id}/tasks
fn tasks(base: &str, list_id: &str, status_filter: Option<&str>, json: bool) {
    if let Some(s) = status_filter {
        if let Err(e) = check_status(s) {
            exit_err(&e);
        }
    }
    let tasks = http_tasks(base, list_id).unwrap_or_else(|e| exit_err(&e));
    if json {
        let payload = if let Some(s) = status_filter {
            let filtered: Vec<&Task> = tasks.iter().filter(|t| t.status == s).collect();
            serde_json::json!({ "tasks": filtered })
        } else {
            serde_json::json!({ "tasks": tasks })
        };
        println!("{}", serde_json::to_string(&payload).unwrap());
        return;
    }
    println!("── {list_id} ──  {base}/api/lists/{list_id}/tasks");
    let filtered: Vec<&Task> = tasks
        .iter()
        .filter(|t| status_filter.map(|s| t.status == s).unwrap_or(true))
        .collect();
    if filtered.is_empty() {
        println!("  （暂无任务）");
        return;
    }
    for t in &filtered {
        println!("  {:<38} {:<11} {:<7}", t.title, t.status, t.priority);
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
    format!("{list_id}-{}", base)
}

/// add：生成 ID 后 PUT（upsert 追加）
fn add(
    base: &str,
    list_id: &str,
    title: &str,
    description: Option<&str>,
    priority: Option<&str>,
    status: Option<&str>,
    json: bool,
) {
    let priority = priority.unwrap_or("medium");
    if let Err(e) = check_priority(priority) {
        exit_err(&e);
    }
    let status = status.unwrap_or("notStarted");
    if let Err(e) = check_status(status) {
        exit_err(&e);
    }
    let existing = http_tasks(base, list_id).unwrap_or_else(|e| exit_err(&e));
    let existing_ids: Vec<String> = existing.iter().map(|t| t.id.clone()).collect();
    let task_id = gen_task_id(list_id, &existing_ids);
    let task = Task {
        id: task_id.clone(),
        title: title.to_string(),
        description: description.map(String::from),
        status: status.to_string(),
        priority: priority.to_string(),
    };
    let body = serde_json::to_string(&task).unwrap_or_else(|e| exit_err(&format!("序列化失败: {e}")));
    let v = http_json("PUT", &format!("{base}/api/lists/{list_id}/tasks/{task_id}"), Some(&body))
        .unwrap_or_else(|e| exit_err(&e));
    if json {
        println!("{}", serde_json::to_string(&v).unwrap());
    } else {
        println!("✓ 已新增任务 {task_id} → {title} ({status}/{priority}) @ {base}");
    }
}

/// update：先 GET 任务再合并字段，最后 PUT 全量替换
fn update(
    base: &str,
    list_id: &str,
    task_id: &str,
    status: Option<&str>,
    priority: Option<&str>,
    description: Option<&str>,
    json: bool,
) {
    ensure_update_fields(status, priority, description);

    let tasks = http_tasks(base, list_id).unwrap_or_else(|e| exit_err(&e));
    let mut task = tasks
        .into_iter()
        .find(|t| t.id == task_id)
        .unwrap_or_else(|| exit_err(&format!("任务不存在: {task_id}（清单 {list_id}）")));
    let title = task.title.clone();

    if let Some(s) = status {
        task.status = s.to_string();
    }
    if let Some(p) = priority {
        task.priority = p.to_string();
    }
    if let Some(d) = description {
        task.description = Some(d.to_string());
    }

    let body = serde_json::to_string(&task).unwrap_or_else(|e| exit_err(&format!("序列化失败: {e}")));
    let v = http_json("PUT", &format!("{base}/api/lists/{list_id}/tasks/{task_id}"), Some(&body))
        .unwrap_or_else(|e| exit_err(&e));
    if json {
        println!("{}", serde_json::to_string(&v).unwrap());
    } else {
        println!("✓ 已更新任务 {task_id}：{title} @ {base}");
    }
}

fn main() {
    let cli = Cli::parse();
    let base = resolve_base(&cli.server);

    match &cli.command {
        Command::Lists => lists(&base, cli.json),
        Command::Tasks { list_id, status } => tasks(&base, list_id, status.as_deref(), cli.json),
        Command::Add { list_id, title, description, priority, status } => add(
            &base, list_id, title, description.as_deref(), priority.as_deref(), status.as_deref(), cli.json,
        ),
        Command::Update { list_id, task_id, status, priority, description } => update(
            &base, list_id, task_id, status.as_deref(), priority.as_deref(), description.as_deref(), cli.json,
        ),
    }
}
