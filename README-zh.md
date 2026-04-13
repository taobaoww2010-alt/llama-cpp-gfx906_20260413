# llama.cpp for AMD Radeon Pro VII (gfx906)

> 本分支针对 AMD Radeon Pro VII 显卡进行优化，支持 GPU 加速推理

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## 硬件环境

| 组件 | 规格 |
|------|------|
| 显卡 | AMD Radeon Pro VII (双卡) |
| GPU 架构 | gfx906 (Vega 20) |
| ROCm 版本 | 6.3 |
| 显存 | 16GB HBM2 x 2 = 32GB |
| 系统 | Ubuntu 22.04 |

## 性能对比

| 模式 | 推理速度 |
|------|----------|
| CPU (8线程) | ~20 t/s |
| GPU (双 Radeon VII) | **~67 t/s** |

**GPU 加速效果: 约 3.4 倍提升**

## 快速开始

### 1. 环境准备

```bash
# 安装 ROCm 6.3
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | sudo apt-key add -
echo "deb [arch=amd64] https://repo.radeon.com/rocm/ubuntu/6.3.0 main" | sudo tee /etc/apt/sources.list.d/rocm.list
sudo apt update
sudo apt install -y hip-dev hipblas-dev rocblas

# 设置环境变量
export ROCM_PATH=/opt/rocm-6.3.0
export HIP_PATH=/opt/rocm-6.3.0
```

### 2. 编译

```bash
# 应用补丁
git apply patches/ggml-cuda-hipStreamWaitEvent.patch
git apply patches/ggml-hip-fcommon.patch
sudo patch -p1 < patches/amd_hip_bf16-static.patch

# 编译
cmake -B build \
  -DGGML_HIP=ON \
  -DCMAKE_C_COMPILER=gcc \
  -DCMAKE_CXX_COMPILER=g++-13 \
  -DCMAKE_HIP_HOST_COMPILER=g++-13 \
  -DCMAKE_HIP_FLAGS='--rocm-device-lib-path=/usr/lib/llvm-17/lib/clang/17/amdgcn/bitcode --rocm-path=/opt/rocm-6.3.0' \
  -DGGML_HIP_MMQ_MFMA=OFF \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build -j$(nproc)
```

### 3. 运行测试

```bash
export ROCM_PATH=/opt/rocm-6.3.0
./build/bin/llama-cli -m /path/to/model.gguf -p "你好" -n 100 -t 8
```

**预期输出:**
```
ggml_cuda_init: found 2 ROCm devices (Total VRAM: 32736 MiB):
  Device 0: AMD Radeon Pro VII, gfx906:sramecc+:xnack- (0x906), VRAM: 16368 MiB
  Device 1: AMD Radeon Pro VII, gfx906:sramecc+:xnack- (0x906), VRAM: 16368 MiB
```

## 已修复的问题

### 1. hipStreamWaitEvent API 兼容性问题

ROCm 6.3 的 LLVM 18 中 `hipStreamWaitEvent` 需要 3 个参数，原代码只传了 2 个。

**补丁文件:** `patches/ggml-cuda-hipStreamWaitEvent.patch`

### 2. 重复符号链接错误

HIP bf16 相关函数在多个编译单元中定义，导致链接失败。

**补丁文件:** 
- `patches/ggml-hip-fcommon.patch` (CMake 编译选项)
- `patches/amd_hip_bf16-static.patch` (ROCm 头文件)

详细说明请查看 [patches/README.md](patches/README.md)

## 项目文件结构

```
llama.cpp-gfx906/
├── patches/                    # 补丁文件
│   ├── README.md              # 补丁详细说明
│   ├── ggml-cuda-hipStreamWaitEvent.patch
│   ├── ggml-hip-fcommon.patch
│   └── amd_hip_bf16-static.patch
├── README-zh.md               # 中文说明文档
└── (llama.cpp 源码)
```

## 常用命令

```bash
# 交互式对话
./build/bin/llama-cli -m model.gguf -p "你好" -t 8

# 批量推理
./build/bin/llama-batched -m model.gguf -p "Hello" -n 50

# 性能基准测试
./build/bin/llama-bench -m model.gguf -ngl 99 -t 8
```

## 参考链接

- [llama.cpp 官方仓库](https://github.com/ggerganov/llama.cpp)
- [ROCm 官方文档](https://rocm.docs.amd.com/)
- [AMD Radeon PRO VII 规格](https://www.amd.com/en/products/professional-graphics/amd-radeon-pro-vii)

## License

MIT License - 继承 llama.cpp 许可证
