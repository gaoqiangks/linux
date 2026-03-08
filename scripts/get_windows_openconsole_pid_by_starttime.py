#!/usr/bin/python3

# 通过windows的任务管理器大概能知道, 每新开一个windows terminal的tab, 就会有一个新的OpenConsole进程, 找到这个OpenConsole之后, 再找到父进程, 也就是WindowsTerminal.exe

# 这个脚本是想通过进程启动的时间戳来找出一个shell和它在windows系统中对应的windows terminal(OpenConsole)的pid
# 如果shell的父进程SessionLeader和一个WindowsTerminal(OpenConsole)的启动时间不超过1秒, 我们就认为这个Terminal就是启动shell的那一个

import psutil
import subprocess


def get_session_leader_info():
    current_process = psutil.Process()
    sessionleader_pid = None
    sessionleader_timestamp = None

    while current_process.parent():
        parent = current_process.parent()
        # 检查父进程是否名称为 "SessionLeader"
        if parent.name() == "SessionLeader":
            sessionleader_pid = parent.pid
            sessionleader_timestamp = int(
                parent.create_time())  # 转换为整数形式的 Unix 时间戳
            break  # 找到后停止搜索
        current_process = parent

    # 如果找到，返回结果；否则返回 None
    return sessionleader_pid, sessionleader_timestamp


def get_processes_as_dict():
    # 定义 PowerShell 命令
    powershell_command = (
        "Get-Process | Where-Object { $_.Name -eq 'WindowsTerminal' -or $_.Name -eq 'OpenConsole' } | "
        "Select-Object Id, @{Name='UnixTimestamp';Expression={[int](([datetime]$_.StartTime).ToUniversalTime() - [datetime]'1970-01-01').TotalSeconds}}"
    )

    try:
        # 执行 PowerShell 命令
        result = subprocess.run(
            ["powershell.exe", "-Command", powershell_command],
            capture_output=True,
            text=True
        )

        if result.returncode != 0:
            print("PowerShell 命令执行失败:")
            print(result.stderr)
            return {}

        # 解析输出并存储到字典中
        process_dict = {}
        output = result.stdout.strip()
        if not output:
            print("没有找到符合条件的进程。")
            return process_dict

        # 按行解析输出
        for line in output.splitlines():
            try:
                parts = line.split()
                pid = int(parts[0])  # 提取 PID
                timestamp = int(parts[1])  # 提取 Unix 时间戳
                process_dict[pid] = timestamp
            except (IndexError, ValueError):
                pass  # 忽略无法解析的行

        return process_dict

    except Exception as e:
        print(f"运行脚本时发生错误: {e}")
        return {}


def find_parent_pid(pid):
    # 定义 PowerShell 命令
    powershell_command = (
        f"$p=Get-CimInstance Win32_Process | Where-Object {{ $_.ProcessId -eq '{
            pid}' }}; "
        f"while($p -and $p.Name -ne 'WindowsTerminal.exe'){{ "
        f"if(-not $p.ParentProcessId){{ Write-Output '-1'; break }}; "
        f"$p=Get-CimInstance Win32_Process | Where-Object {{ $_.ProcessId -eq $p.ParentProcessId }} }}; "
        f"if($p.Name -eq 'WindowsTerminal.exe'){{ Write-Output $p.ProcessId }} else {{ Write-Output '-1' }}"
    )

    try:
        # 执行 PowerShell 命令
        result = subprocess.run(
            ["powershell.exe", "-Command", powershell_command],
            capture_output=True,
            text=True
        )

        # 检查 PowerShell 执行状态
        if result.returncode != 0:
            print("PowerShell 命令执行失败:", result.stderr.strip())
            return "-1"

        # 解析输出，返回结果
        output = result.stdout.strip()
        try:
            return str(output)  # 确保输出以字符串形式返回
        except ValueError:
            return "-1"

    except Exception as e:
        print(f"运行脚本时发生错误: {str(e)}")
        return "-1"


if __name__ == "__main__":
    process_info = get_processes_as_dict()
    sessionleader_pid, sessionleader_timestamp = get_session_leader_info()
    print("sessionleader_timestamp:", sessionleader_timestamp)
    console_pid = "-1"

    if process_info:
        given_timestamp = sessionleader_timestamp  # 设定给定的时间戳

        # 遍历字典并比较时间戳
        for pid, timestamp in process_info.items():
            difference = abs(timestamp - given_timestamp)
            print("timestamp:", timestamp)
            if difference <= 1:
                print(pid)
                console_pid = pid
                print(find_parent_pid(console_pid))
                exit(0)
        print("-1")
    else:
        print("-1")
