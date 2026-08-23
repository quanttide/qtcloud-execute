variable "region" {
  description = "阿里云地域"
  type        = string
  default     = "cn-hangzhou"
}

variable "bucket_name" {
  description = "studio Web 部署的 OSS 桶名（与 deploy-studio.yml 保持一致）"
  type        = string
  default     = "qtcloud-execute-studio"
}

variable "cdn_domain" {
  description = "studio CDN 加速域名"
  type        = string
  default     = "execute.cloud.quanttide.com"
}

variable "cdn_scope" {
  description = "CDN 加速区域：domestic / overseas / global"
  type        = string
  default     = "global"
}

# ============================================================
# provider（FC 容器）相关变量
# ============================================================
variable "project" {
  description = "项目名（资源命名前缀）"
  type        = string
  default     = "qtcloud-execute"
}

variable "environment" {
  description = "环境：dev / prod"
  type        = string
  default     = "prod"
}

variable "image" {
  description = "FC 容器镜像（ACR 地址）。由 CI 注入（TF_VAR_image 拼接 secret ALIYUN_ACR_REGISTRY 的实例地址）或 terraform.tfvars 提供；实例地址属敏感信息不写默认值"
  type        = string
}

variable "oss_data_bucket" {
  description = "provider 运行时任务数据 OSS 桶（QTCLOUD_EXECUTE_STORE=oss 时读写 data/tasks.json）"
  type        = string
  default     = "qtcloud-execute-data"
}

variable "oss_endpoint" {
  description = "阿里云 OSS Endpoint（provider 运行时 ALIYUN_OSS_ENDPOINT，region 内网/公网地址）"
  type        = string
  default     = "oss-cn-hangzhou.aliyuncs.com"
}

variable "oss_access_key_id" {
  description = "provider 运行时访问 OSS 的 AccessKey ID（FC 环境变量 ALIYUN_ACCESS_KEY_ID；会明文落入 tfstate，生产建议后续改用 FC 密钥管理注入）"
  type        = string
  sensitive   = true
}

variable "oss_access_key_secret" {
  description = "provider 运行时访问 OSS 的 AccessKey Secret（FC 环境变量 ALIYUN_ACCESS_KEY_SECRET；会明文落入 tfstate，生产建议后续改用 FC 密钥管理注入）"
  type        = string
  sensitive   = true
}

variable "fc_memory" {
  description = "FC 函数内存（MB）"
  type        = number
  default     = 512
}

variable "fc_timeout" {
  description = "FC 函数超时（秒）"
  type        = number
  default     = 60
}
