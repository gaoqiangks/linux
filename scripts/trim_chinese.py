#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
根据汉字白名单过滤文件中的行。

用法:
    python script.py a.txt b.txt

参数:
    a.txt   每行一个汉字的文件（构建允许的汉字集合）
    b.txt   需要过滤的目标文件（直接修改该文件，并创建备份 b.txt.bak）
"""

import sys
import os
from pathlib import Path

def is_chinese_char(char):
    """判断一个字符是否为 CJK 统一汉字（基本区 + 扩展区）"""
    code = ord(char)
    # 基本区 CJK Unified Ideographs (4E00-9FFF)
    if 0x4E00 <= code <= 0x9FFF:
        return True
    # 扩展 A 区 (3400-4DBF)
    if 0x3400 <= code <= 0x4DBF:
        return True
    # 扩展 B 区 (20000-2A6DF)
    if 0x20000 <= code <= 0x2A6DF:
        return True
    return False

def extract_chinese(text):
    """提取字符串中的所有中文字符"""
    return [ch for ch in text if is_chinese_char(ch)]

def main():
    # 解析命令行参数
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    a_path = sys.argv[1]
    b_path = sys.argv[2]

    # 读取 a.txt，构建允许的汉字集合
    try:
        with open(a_path, 'r', encoding='utf-8') as f:
            allowed_chars = {line.strip() for line in f if line.strip()}
        print(f"从 {a_path} 加载了 {len(allowed_chars)} 个汉字")
    except FileNotFoundError:
        print(f"错误：文件 {a_path} 不存在")
        sys.exit(1)
    except Exception as e:
        print(f"读取 {a_path} 时出错：{e}")
        sys.exit(1)

    # 检查 b.txt 是否存在
    if not os.path.exists(b_path):
        print(f"错误：文件 {b_path} 不存在")
        sys.exit(1)

    # 备份原文件
    b_file = Path(b_path)
    backup_path = b_file.with_suffix(b_file.suffix + '.bak')
    try:
        # 如果备份文件已存在，先删除（避免 os.rename 跨设备问题）
        if backup_path.exists():
            backup_path.unlink()
        b_file.rename(backup_path)
        print(f"已备份原文件为 {backup_path}")
    except Exception as e:
        print(f"备份文件时出错：{e}")
        sys.exit(1)

    # 读取备份文件，逐行处理
    kept_lines = []
    removed_count = 0
    try:
        with open(backup_path, 'r', encoding='utf-8') as f:
            for line_num, line in enumerate(f, 1):
                original = line.rstrip('\n')
                chinese_chars = extract_chinese(original)
                if not chinese_chars:
                    # 不含中文的行，直接保留
                    kept_lines.append(original)
                else:
                    # 检查所有中文字符是否都在允许集合中
                    if all(ch in allowed_chars for ch in chinese_chars):
                        kept_lines.append(original)
                    else:
                        removed_count += 1
                        print(f"删除第 {line_num} 行：{original[:60]}{'...' if len(original) > 60 else ''}")
    except Exception as e:
        print(f"处理 {backup_path} 时出错：{e}")
        # 出错时尝试恢复备份
        try:
            backup_path.rename(b_path)
            print("已恢复原文件")
        except:
            print("警告：无法自动恢复，请手动处理")
        sys.exit(1)

    # 将保留的行写回原文件
    try:
        with open(b_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(kept_lines))
        print(f"处理完成，原文件已更新。保留了 {len(kept_lines)} 行，删除了 {removed_count} 行。")
    except Exception as e:
        print(f"写入 {b_path} 时出错：{e}")
        print(f"原始数据已备份在 {backup_path}，请手动恢复")
        sys.exit(1)

if __name__ == '__main__':
    main()
