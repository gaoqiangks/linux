#!/usr/bin/env bash

# git clone https://github.com/James-Yu/LaTeX-Workshop.git
# 定义源目录和目标目录
SOURCE_DIR="./LaTeX-Workshop/dev/packages"
TARGET_DIR="./packages"
shopt -s globstar

# 确保目标目录存在
mkdir -p "$TARGET_DIR"

# 遍历源目录中的所有文件
for file in ./LaTeX-Workshop/dev/packages/* ; do
    # 检查是否是文件（忽略子目录）
    if [[ -f "$file" ]]; then
        # 获取文件名（去掉路径）
        filename=$(basename "$file")
        
        # 构造目标文件路径
        target_file="$TARGET_DIR/$filename"
        
        # 使用 Lua 脚本处理文件，并将输出写入目标文件
        echo "正在处理文件: $file"
        ./lw_to_vscode.lua pkg "$file" 0 > "$target_file"
        echo "已写入文件: $target_file"
    fi
done

file="./LaTeX-Workshop/data/commands.json"
target_file="./packages/_commands.json"
lua ./lw_to_vscode.lua cmd  "$file" 3000 > "$target_file"

target_file="./packages/_environments.json"
lua ~/.config/nvim/lua/lib/generate_vscode_env_snippets.lua > "$target_file"

echo "处理完成！"
