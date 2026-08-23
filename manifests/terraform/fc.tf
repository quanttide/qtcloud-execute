# ============================================================
# provider（quanttide-execute 任务 API）—— 阿里云 FC 3.0 容器部署
# 数据：运行时 OSS store（QTCLOUD_EXECUTE_STORE=oss），读写 OSS 桶中 data/tasks.json
# 凭证：provider 通过环境变量读取静态 AK/SK 访问 OSS（见 internal/store/oss.go）；
#       故 FC 函数环境变量注入 ALIYUN_ACCESS_KEY_ID/SECRET。此 AK/SK 会明文落入 tfstate，
#       生产环境建议后续改用 FC 密钥管理/配置中心注入。
# ============================================================

# FC 默认角色：允许 FC 服务挂载弹性网卡访问 VPC（应用级，保留与 sibling 模板一致）
resource "alicloud_ram_role" "fc" {
  role_name                   = "${local.app_name_prefix}-fc"
  assume_role_policy_document = <<EOF
{
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": ["fc.aliyuncs.com"]
      }
    }
  ],
  "Version": "1"
}
EOF
  description                 = "Function Compute 默认角色（qtcloud-execute）"
}

resource "alicloud_ram_role_policy_attachment" "fc_vpc" {
  policy_name = "AliyunECSNetworkInterfaceManagementAccess"
  policy_type = "System"
  role_name   = alicloud_ram_role.fc.role_name
}

# ============================================================
# provider 运行时数据 OSS 桶（私有）：data/tasks.json（GET/PUT）
# 与 studio 静态站桶（main.tf alicloud_oss_bucket.studio）分离
# ============================================================
resource "alicloud_oss_bucket" "data" {
  bucket = var.oss_data_bucket

  tags = {
    App         = "qtcloud-execute-data"
    Environment = var.environment
  }
}

# 函数计算（FC 3.0）：custom-container 容器镜像，运行时 OSS store
resource "alicloud_fcv3_function" "this" {
  function_name   = local.app_name_prefix
  description     = "qtcloud-execute 任务清单 API（运行时 OSS 数据源）"
  runtime         = "custom-container"
  handler         = "index.handler" # custom-container 必填占位，实际由容器监听端口决定
  cpu             = 0.5
  memory_size     = var.fc_memory
  disk_size       = 512 # FC 3.0 必填（MB）
  timeout         = var.fc_timeout
  internet_access = true
  role            = alicloud_ram_role.fc.arn

  custom_container_config {
    image = var.image
    port  = 8080
  }

  # 对齐 provider 运行时约定（见 src/provider/cmd/server/main.go 与 internal/store/oss.go）：
  # QTCLOUD_EXECUTE_STORE=oss 读 OSS 桶中 data/tasks.json；QTCLOUD_EXECUTE_DATA 为桶内对象键
  environment_variables = {
    QTCLOUD_EXECUTE_STORE    = "oss"
    QTCLOUD_EXECUTE_DATA     = "data/tasks.json"
    QTCLOUD_EXECUTE_ADDR     = ":8080"
    ALIYUN_OSS_BUCKET        = alicloud_oss_bucket.data.bucket
    ALIYUN_OSS_ENDPOINT      = var.oss_endpoint
    ALIYUN_ACCESS_KEY_ID     = var.oss_access_key_id
    ALIYUN_ACCESS_KEY_SECRET = var.oss_access_key_secret
  }

  tags = {
    project     = var.project
    environment = var.environment
  }
}

# HTTP 触发器：直接访问（后续经系统级 API 网关统一接入，此触发器保留为直连通道）
resource "alicloud_fcv3_trigger" "http" {
  function_name = alicloud_fcv3_function.this.function_name
  trigger_name  = "http"
  trigger_type  = "http"
  qualifier     = "LATEST"
  trigger_config = jsonencode({
    authType = "anonymous"
    methods  = ["GET", "POST", "PUT", "DELETE", "HEAD", "OPTIONS"]
  })
}
