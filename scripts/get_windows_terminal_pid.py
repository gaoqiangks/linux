import psutil

import ctypes
from ctypes.wintypes import DWORD

def find_windows_terminal_pid():
    current_process = psutil.Process()  # 当前进程
    while current_process:
        # 获取父进程
        parent_process = current_process.parent()
        if not parent_process:
            # 如果没有父进程，返回 -1
            return "-1"
        try:
            # 检查父进程的 exe 文件
            exe_name = parent_process.name()
            if exe_name.lower() == "windowsterminal.exe":
                # 如果找到了 WindowsTerminal.exe，返回对应的 PID
                return str(parent_process.pid)
            else:
                # 继续检查父进程的父进程
                current_process = parent_process
        except (psutil.AccessDenied, psutil.NoSuchProcess):
            # 如果访问被拒绝或者进程不存在，返回 -1
            return "-1"


TH32CS_SNAPPROCESS = 0x00000002

class PROCESSENTRY32(ctypes.Structure):
    _fields_ = [
        ("dwSize", DWORD),
        ("cntUsage", DWORD),
        ("th32ProcessID", DWORD),
        ("th32DefaultHeapID", ctypes.c_void_p),
        ("th32ModuleID", DWORD),
        ("cntThreads", DWORD),
        ("th32ParentProcessID", DWORD),
        ("pcPriClassBase", ctypes.c_long),
        ("dwFlags", DWORD),
        ("szExeFile", ctypes.c_char * 260)
    ]

def get_parent_pid(pid):
    """获取父进程的 PID 和名称"""
    kernel32 = ctypes.WinDLL('kernel32', use_last_error=True)
    snapshot = kernel32.CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    
    if snapshot == -1:
        raise Exception("无法创建进程快照")

    process_entry = PROCESSENTRY32()
    process_entry.dwSize = ctypes.sizeof(PROCESSENTRY32)

    success = kernel32.Process32First(snapshot, ctypes.byref(process_entry))
    while success:
        if process_entry.th32ProcessID == pid:
            kernel32.CloseHandle(snapshot)
            return process_entry.th32ParentProcessID, process_entry.szExeFile.decode()
        success = kernel32.Process32Next(snapshot, ctypes.byref(process_entry))
    
    kernel32.CloseHandle(snapshot)
    return None, None

def find_windows_terminal_pid_by_pid(pid):
    """寻找父进程是否是 WindowsTerminal.exe（不区分大小写）"""
    while pid != 0:  # 不再有父进程时退出
        parent_pid, parent_name = get_parent_pid(pid)
        # print("parent_name = ", parent_name)
        if parent_pid is None:  # 没找到父进程
            return -1
        
        # 不区分大小写比较进程名称
        if parent_name.lower() == "windowsterminal.exe".lower():
            return parent_pid
        
        # 继续向上检查
        pid = parent_pid

    return -1

rlt = find_windows_terminal_pid()
if rlt == -1:
    current_pid = ctypes.windll.kernel32.GetCurrentProcessId()
    result = find_windows_terminal_pid_by_pid(current_pid)
print(rlt)
