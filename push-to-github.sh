#!/bin/bash
# push-to-github.sh - 上传 llama.cpp-gfx906 到 GitHub

set -e

echo "=========================================="
echo "llama.cpp-gfx906 GitHub 上传脚本"
echo "=========================================="

# 检查 GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "错误: 需要安装 gh CLI"
    echo "安装方法: https://cli.github.com/"
    echo ""
    echo "或者手动执行以下步骤:"
    echo "1. 在 GitHub 上创建新仓库"
    echo "2. 运行以下命令:"
    echo "   git remote add origin git@github.com:你的用户名/仓库名.git"
    echo "   git push -u origin master"
    exit 1
fi

# 检查登录状态
echo "检查 GitHub 登录状态..."
gh auth status || { echo "请先运行 'gh auth login' 登录"; exit 1; }

# 获取仓库名
read -p "请输入 GitHub 仓库名 (如 llama-cpp-gfx906): " REPO_NAME
read -p "请输入 GitHub 用户名: " USER_NAME

# 创建仓库
echo "创建 GitHub 仓库..."
gh repo create "$USER_NAME/$REPO_NAME" --public --source=. --push

echo ""
echo "=========================================="
echo "上传成功!"
echo "仓库地址: https://github.com/$USER_NAME/$REPO_NAME"
echo "=========================================="
