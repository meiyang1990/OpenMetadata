#!/bin/bash
# OpenMetadata 镜像拉取与推送脚本
# 目标仓库: ccr-2owfeef4-pub.cnc.bj.baidubce.com/scheduler/
# 用法: bash push-images.sh

set -e

REGISTRY="ccr-2owfeef4-pub.cnc.bj.baidubce.com/scheduler"

# ============================================================
# 镜像列表 (来源: baidu_k8s.yaml + openmetadata-dependencies)
# ============================================================
# 1. OpenMetadata Server          (baidu_k8s.yaml L454-456)
# 2. OpenMetadata Ingestion Base  (baidu_k8s.yaml L119, k8s pipeline)
# 3. OMJob Operator               (baidu_k8s.yaml L764-766)
# 4. OpenSearch                   (openmetadata-dependencies, 上游默认)
# ============================================================

IMAGES=(
  "docker.getcollate.io/openmetadata/server:1.12.6"
  "docker.getcollate.io/openmetadata/ingestion-base:latest"
  "docker.getcollate.io/openmetadata/omjob-operator:1.12.6"
  "opensearchproject/opensearch:2.19.1"
)

for IMG in "${IMAGES[@]}"; do
  echo "=========================================="
  echo "Processing: ${IMG}"

  # 拆分 name:tag
  NAME="${IMG%%:*}"
  TAG="${IMG##*:}"

  # 提取不含顶级 registry/组织 的路径部分:
  #   docker.getcollate.io/openmetadata/server:1.12.6  ->  openmetadata/server
  #   opensearchproject/opensearch:2.19.1              ->  opensearchproject/opensearch
  if [[ "$NAME" == *.*/* ]]; then
    # 含域名 registry: docker.getcollate.io/openmetadata/server -> openmetadata/server
    PATH_NO_REGISTRY="${NAME#*/}"          # 去掉第一段 docker.getcollate.io/
  else
    PATH_NO_REGISTRY="$NAME"
  fi

  TARGET="${REGISTRY}/${PATH_NO_REGISTRY}:${TAG}"

  echo "  Pull:   ${IMG}"
  docker pull "${IMG}"

  echo "  Tag:    ${TARGET}"
  docker tag "${IMG}" "${TARGET}"

  echo "  Push:   ${TARGET}"
  docker push "${TARGET}"

  echo "  Done!"
  echo ""
done

echo "=========================================="
echo "All images pushed successfully!"
echo ""
echo "Image mapping:"
echo "  SOURCE                                              -> TARGET"
for IMG in "${IMAGES[@]}"; do
  NAME="${IMG%%:*}"
  TAG="${IMG##*:}"
  if [[ "$NAME" == *.*/* ]]; then
    PATH_NO_REGISTRY="${NAME#*/}"
  else
    PATH_NO_REGISTRY="$NAME"
  fi
  TARGET="${REGISTRY}/${PATH_NO_REGISTRY}:${TAG}"
  printf "  %-50s -> %s\n" "${IMG}" "${TARGET}"
done
