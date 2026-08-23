output "bucket_name" {
  description = "OSS 桶名"
  value       = alicloud_oss_bucket.studio.bucket
}

output "bucket_domain" {
  description = "OSS 桶访问域名（CDN 回源地址）"
  value       = format("%s.%s", alicloud_oss_bucket.studio.bucket, alicloud_oss_bucket.studio.extranet_endpoint)
}

output "cdn_domain" {
  description = "CDN 加速域名"
  value       = alicloud_cdn_domain_new.studio.domain_name
}

output "cdn_cname" {
  description = "CDN CNAME，需在 DNS 中配置指向（当前已配置为 kunlunaq.com）"
  value       = alicloud_cdn_domain_new.studio.cname
}

# ============================================================
# provider（FC）输出
# ============================================================
output "fc_function_name" {
  description = "函数计算函数名"
  value       = alicloud_fcv3_function.this.function_name
}

output "fc_http_url" {
  description = "FC HTTP 触发器公网地址（系统级 API 网关接入前的直连入口）"
  value       = try(alicloud_fcv3_trigger.http.http_trigger[0].url_internet, "尚未创建")
}

output "oss_data_bucket" {
  description = "provider 运行时任务数据 OSS 桶名"
  value       = alicloud_oss_bucket.data.bucket
}
