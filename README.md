# llama.cpp for AMD Radeon Pro VII (gfx906)

## 简介

本仓库包含针对 AMD Radeon Pro VII (gfx906) 显卡编译的 llama.cpp，包含所有必要的补丁和修改。

## 目标硬件配置

本项目在以下硬件环境开发和测试：

| 项目 | 配置 |
|------|------|
| **操作系统** | Ubuntu 22.04.5 LTS |
| **CPU** | Intel Xeon E5-2696 v4 (22核44线程) @ 2.2GHz |
| **内存** | 23GB DDR4 |
| **磁盘** | 7.3TB |

### 双显卡 AMD Radeon Pro VII

| 项目 | GPU 0 | GPU 1 |
|------|-------|-------|
| **型号** | Vega 20 | Vega 20 |
| **显存** | 16GB HBM | 16GB HBM |
| **计算单元** | 60 CU | 60 CU |
| **架构** | gfx906 | gfx906 |
| **PCIe** | 0000:06:00.0 | 0000:09:00.0 |

### ROCm 环境

| 项目 | 版本 |
|------|------|
| **ROCm** | 6.3.0 |
| **AMD GPU 驱动** | amdgpu 6.10.5 |
| **AMD-SMI** | 24.7.1 |
| **VBIOS** | Vega20 16GB |

## 支持的功能

- ✅ AMD Radeon Pro VII (gfx906) GPU 加速
- ✅ 双显卡并行推理
- ✅ `--split-mode row` 负载均衡（已修复乱码问题）
- ✅ `--split-mode layer` 层分割
- ✅ OpenAI 兼容 API (llama-server)
- ✅ Chat 接口支持

## 包含的补丁

| 补丁文件 | 描述 |
|---------|------|
| `patches/ggml-hip-fcommon.patch` | 修复链接时的重复符号问题 |
| `patches/ggml-cuda-hipStreamWaitEvent.patch` | 修复 ROCm 6.3 API 兼容性 |
| `patches/row-split-hip-fix.patch` | 修复 row split 模式输出乱码 |

## 编译环境

### 依赖

- ROCm 6.3.0
- CMake 3.28+
- g++ 13
- HIP/Clang 18

### 编译步骤

```bash
# 安装依赖（Ubuntu 22.04）
apt-get update && apt-get install -y \
    cmake \
    g++-13 \
    gcc-13 \
    hip-dev \
    hip-runtime-amd \
    rocm-device-libs \
    hipblas-dev \
    rocblas

# 应用补丁
cd /path/to/llama.cpp-gfx906
git apply patches/ggml-hip-fcommon.patch
git apply patches/ggml-cuda-hipStreamWaitEvent.patch
git apply patches/row-split-hip-fix.patch

# 编译
mkdir build && cd build
cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_HIP=ON \
    -DGGML_HIP_NO_VMM=ON \
    -DCMAKE_HIP_COMPILER=/opt/rocm-6.3.0/llvm/bin/clang++ \
    -DCMAKE_HIP_HOST_COMPILER=/usr/bin/g++-13 \
    -DCMAKE_C_COMPILER=/usr/bin/gcc-13 \
    -DCMAKE_CXX_COMPILER=/usr/bin/g++-13

make -j$(nproc) llama-server
```

## 使用方法

### 启动服务

```bash
# 单 GPU 模式
./build/bin/llama-server \
    -m /path/to/model.gguf \
    -c 8192 \
    --port 8080

# 双 GPU row split 模式（负载均衡）
./build/bin/llama-server \
    -m /path/to/model.gguf \
    -c 8192 \
    --split-mode row \
    --port 8080

# 双 GPU layer split 模式
./build/bin/llama-server \
    -m /path/to/model.gguf \
    -c 8192 \
    --split-mode layer \
    --port 8080
```

### 测试 API

```bash
# Chat 接口
curl -X POST http://localhost:8080/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d '{"messages":[{"role":"user","content":"你好"}],"max_tokens":100}'

# Completion 接口
curl -X POST http://localhost:8080/v1/completions \
    -H "Content-Type: application/json" \
    -d '{"prompt":"Hello, how are you?","max_tokens":50}'
```

## 主要修改

### 1. row-split-hip-fix.patch

修复 `--split-mode row` 导致输出乱码的问题。

**问题**：`ggml_cuda_Memcpy2DPeerAsync` 函数在 HIP 中使用 `hipMemcpy2DAsync` 进行跨 GPU 内存拷贝，在 gfx906 上不正确工作。

**修复**：改用 `hipMemcpyPeerAsync` 循环替代。

### 2. ggml-cuda-hipStreamWaitEvent.patch

修复 ROCm 6.3 中 `hipStreamWaitEvent` API 签名变化。

### 3. ggml-hip-fcommon.patch

修复 HIP bf16 相关函数的重复符号问题。

## 更新历史

### 2024-04-14
- 修复 `--split-mode row` 乱码问题
- 所有补丁整合完成

## 许可证

MIT License - 与上游 llama.cpp 相同
