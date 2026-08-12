# 静态站点部署与运维 —— 关键操作记录（脱敏）

> 记录时间：2026-08-12 | 场景：qtcloud-execute studio（`execute.cloud.quanttide.com`）v0.1.0-alpha.1 首次发布全流程
> 本文件为脱敏版：不包含任何 AccessKey / Secret / 账号 ID，仅记录操作路径与排障结论。

## 一、架构与链路

```
studio/* tag
   ↓ qtcloud-devops release publish（创建 tag + GitHub Release）
GitHub Actions deploy-studio.yml
   ↓ flutter build web → ossutil cp
OSS 桶（qtcloud-execute-studio，公共读 + 静态网站托管）
   ↓ CDN 回源（execute.cloud.quanttide.com CNAME → *.w.cdngslb.com，HTTPS 通配证书）
用户浏览器
```

## 二、发布流程

### 1. 首次发布

```bash
# 预检（版本号/配置一致性/CHANGELOG/工作区/标签冲突/远程）
qtcloud-devops release audit -v studio/v0.1.0-alpha.1
# 发布（创建 tag + GitHub Release，tag 推送自动触发 deploy-studio.yml）
qtcloud-devops release publish -v studio/v0.1.0-alpha.1 -y
```

- 前置：`.quanttide/devops/contract.yaml` 声明 `studio` scope → `src/studio`
- 预检失败项：`pubspec.yaml` 版本未对齐、`CHANGELOG.md` 缺条目、工作区有未提交变更

**坑：pubspec 版本不要带 `+build` 号**

`version: 0.1.0-alpha.1+1` 会被版本一致性检查判定为与 tag（`0.1.0-alpha.1`）不一致——
检查是字符串精确比较。统一写 `0.1.0-alpha.1`。

## 三、首次上线排障记录（2026-08-12）

CI 构建通过但站点无法访问，按链路逐层排查，共 6 个坑：

### 坑 1：OSS 桶不存在（CI 上传 NoSuchBucket）

现象：`deploy-studio.yml` 的 Upload to OSS 失败，`ErrorCode=NoSuchBucket`。
原因：IaC（manifests/terraform）写好了但从未 apply，桶根本没创建。
解决：

```bash
cd manifests/terraform
terraform init && terraform plan && terraform apply -auto-approve
```

### 坑 2：terraform provider 下载失败

现象：`terraform init` 报 provider 找不到/下载超时。
原因：`~/.terraformrc` 把 alicloud provider 指向阿里云镜像
（`mirrors.aliyun.com/terraform-provider/`），镜像 404 失效；官方 registry 可达。
解决：用其他项目已缓存的 provider（文件系统镜像）+ 空配置绕过：

```hcl
# /tmp/tfrc
provider_installation {
  filesystem_mirror {
    path = "/path/to/other/project/.terraform/providers"
    include = ["registry.terraform.io/aliyun/alicloud"]
  }
  direct {
    exclude = ["registry.terraform.io/aliyun/alicloud"]
  }
}
```

```bash
TF_CLI_CONFIG_FILE=/tmp/tfrc terraform init
```

### 坑 3：apply 中断后 CDN 报 DomainAlreadyExist

现象：首次 apply 在 CDN 创建后、写 state 前被中断；重跑 apply 报
`DomainAlreadyExist`（域名实际已创建成功）。
解决：把已存在的资源导入 state 收敛：

```bash
terraform import alicloud_cdn_domain_new.studio execute.cloud.quanttide.com
terraform plan   # 应显示 No changes
```

### 坑 4：DNS 未解析（NXDOMAIN）

现象：`nslookup execute.cloud.quanttide.com` 返回 NXDOMAIN，站点不可达。
原因：CDN 域名已创建，但云解析（hichina）缺少 CNAME 记录。
解决（阿里云云解析，参照 `econ.cloud` 的现有记录）：

```bash
aliyun alidns AddDomainRecord \
  --DomainName quanttide.com \
  --RR execute.cloud \
  --Type CNAME \
  --Value execute.cloud.quanttide.com.w.cdngslb.com
```

注意：CDN CNAME 后缀因 CDN 实例而异（`*.w.cdngslb.com` 与 `*.w.kunlunaq.com` 均在使用），
以 `DescribeCdnDomainDetail` 返回的 Cname 为准。

### 坑 5：桶级 BlockPublicAccess 屏蔽公共读（403 AccessDenied）

现象：桶 ACL 显示 `public-read`，但直连/CDN 访问均 403
（`You have no right to access this object because of bucket acl.`）。
原因：新桶默认开启桶级 BlockPublicAccess（BPA），即使设置 public-read 也会被屏蔽。
解决：

```bash
# 关闭 BPA（PutBucketPublicAccessBlock，需签名请求；脚本见 manifests/scripts/close_bpa.py）
python3 manifests/scripts/close_bpa.py qtcloud-execute-studio
```

已固化进 IaC：`main.tf` 增加 `alicloud_oss_bucket_public_access_block` 资源
（`block_public_access = false`），重建桶不再踩坑。

### 坑 6：HTTPS 握手失败（无证书）

现象：`curl https://execute.cloud.quanttide.com/` SSL 错误（exit 35），
CDN 域名 `ServerCertificateStatus: off`。
解决：复用证书库中的通配证书 `*.cloud.quanttide.com`（ZeroSSL，SAN 含
`quanttide.com` / `*.cloud.quanttide.com` / `*.quanttide.com`），按 CertId 绑定：

```bash
aliyun cdn SetCdnDomainSSLCertificate \
  --DomainName execute.cloud.quanttide.com \
  --CertId <证书库 CertId> \
  --SSLProtocol on
```

注意：用 CertName 方式需传私钥（SSLPri）；用 CertId 直接引用证书库即可。
通配证书有效期至 2026-11-04，到期需续期并重新绑定。

## 四、验证

```bash
curl -s -o /dev/null -w "%{http_code}" https://execute.cloud.quanttide.com/   # 200
curl -s https://execute.cloud.quanttide.com/ | grep -o "<title>[^<]*</title>" # 量潮执行云
```
