function get_os --description "判断当前系统类型 (linux, macos, 或 wsl)"
    set -l os_name (uname -s)
    set -l kernel_version (uname -r | string lower)

    # 优先检测 WSL，因为它在 uname -s 中也会返回 Linux
    if string match -q "*microsoft*" $kernel_version
        echo "wsl"
    else if test "$os_name" = "Darwin"
        echo "macos"
    else if test "$os_name" = "Linux"
        echo "linux"
    else
        echo "unknown: $os_name"
    end
end
