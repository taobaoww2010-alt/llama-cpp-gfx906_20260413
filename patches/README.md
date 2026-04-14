# llama.cpp for AMD Radeon VII (gfx906) - 补丁文件

本目录包含针对 AMD Radeon Pro VII (gfx906) 显卡编译 llama.cpp 所需的补丁。

## 补丁列表

### 1. ggml-cuda-hipStreamWaitEvent.patch
修复 ROCm 6.3 中 `hipStreamWaitEvent` API 签名变化问题。

**问题**：ROCm 6.3 的 LLVM 18 中 `hipStreamWaitEvent` 需要 3 个参数，但 llama.cpp 代码只传了 2 个参数。

**修复**：在调用处添加第三个参数 `0`。

**适用范围**：ggml/src/ggml-cuda/ggml-cuda.cu

**应用方法**：
```bash
cd /path/to/llama.cpp
git apply patches/ggml-cuda-hipStreamWaitEvent.patch
```

### 2. ggml-hip-fcommon.patch
修复链接时的重复符号问题。

**问题**：HIP bf16 相关函数在多个编译单元中定义，导致链接时出现重复符号错误。

**修复**：在 CMakeLists.txt 中添加 `-fcommon` 编译选项。

**适用范围**：ggml/src/ggml-hip/CMakeLists.txt

**应用方法**：
```bash
cd /path/to/llama.cpp
git apply patches/ggml-hip-fcommon.patch
```

### 3. amd_hip_bf16-static.patch (系统头文件补丁)
此补丁应用于 ROCm 系统头文件，不能包含在源码仓库中。

**问题**：HIP bf16 头文件中的部分函数缺少 `static` 关键字，导致链接时重复符号。

**修复**：为以下函数添加 `static` 关键字：
- `__double2bfloat16`
- `__high2float`
- `__low2float`

**适用范围**：`/usr/include/hip/amd_detail/amd_hip_bf16.h`

**应用方法**：
```bash
sudo patch -p1 < patches/amd_hip_bf16-static.patch
```

### 4. row-split-hip-fix.patch
修复 `--split-mode row` 导致输出乱码的问题。

**问题**：在 gfx906 上使用 `--split-mode row` 时，模型输出出现乱码。这是因为 `ggml_cuda_Memcpy2DPeerAsync` 函数在 HIP 中使用 `hipMemcpy2DAsync` 进行跨 GPU 2D 内存拷贝，在 gfx906 上不正确工作。

**修复**：改用 `hipMemcpyPeerAsync` 循环替代 `hipMemcpy2DAsync`，确保跨 GPU 内存拷贝正确执行。

**适用范围**：ggml/src/ggml-cuda/ggml-cuda.cu

**应用方法**：
```bash
cd /path/to/llama.cpp
git apply patches/row-split-hip-fix.patch
```

**修复效果**：
- ✅ `--split-mode row` 正常工作
- ✅ 双 GPU 负载均衡
- ✅ 输出正确（不再乱码）

## 补丁应用顺序

建议按以下顺序应用补丁：
1. `ggml-hip-fcommon.patch` - 修复链接问题
2. `ggml-cuda-hipStreamWaitEvent.patch` - 修复 API 兼容性
3. `row-split-hip-fix.patch` - 修复 row split 乱码（可选）

## 完整编译流程

详见 ../README.md 中的"完整编译流程"章节。
