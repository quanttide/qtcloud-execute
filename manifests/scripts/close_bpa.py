#!/usr/bin/env python3
"""关闭 OSS 桶级 BlockPublicAccess（PutBucketPublicAccessBlock）。"""
import base64
import hashlib
import hmac
import json
import sys
import urllib.request
from datetime import datetime, timezone

with open("/home/iguo/.aliyun/config.json") as f:
    profile = json.load(f)["profiles"][0]

ak_id = profile["access_key_id"]
ak_secret = profile["access_key_secret"]

bucket = sys.argv[1] if len(sys.argv) > 1 else "qtcloud-execute-studio"
host = f"{bucket}.oss-cn-hangzhou.aliyuncs.com"
date = datetime.now(timezone.utc).strftime("%a, %d %b %Y %H:%M:%S GMT")
body = (
    b"<PublicAccessBlockConfiguration>"
    b"<BlockPublicAccess>false</BlockPublicAccess>"
    b"</PublicAccessBlockConfiguration>"
)
content_md5 = base64.b64encode(hashlib.md5(body).digest()).decode()
content_type = "application/xml"

string_to_sign = (
    f"PUT\n{content_md5}\n{content_type}\n{date}\n/{bucket}/?publicAccessBlock"
)
signature = base64.b64encode(
    hmac.new(ak_secret.encode(), string_to_sign.encode(), hashlib.sha1).digest()
).decode()

req = urllib.request.Request(
    f"http://{host}/?publicAccessBlock",
    data=body,
    method="PUT",
    headers={
        "Authorization": f"OSS {ak_id}:{signature}",
        "Content-MD5": content_md5,
        "Content-Type": content_type,
        "Date": date,
    },
)
try:
    with urllib.request.urlopen(req) as resp:
        print("BPA closed:", resp.status)
except urllib.error.HTTPError as e:
    print("FAILED:", e.code, e.read().decode()[:300])
