function disable_winpath
    set -l silent 0
    if test (count $argv) -ge 1
        if test "$argv[1]" = "-s"
            set silent 1
        end
    end

    set -l linux_paths
    set -l win_paths

    # 拆分 PATH
    for p in $PATH
        if string match -q "/mnt/c/*" -- $p
            set win_paths $win_paths $p
        else
            set linux_paths $linux_paths $p
        end
    end

    # 没有 Windows 路径就不动
    if test (count $win_paths) -eq 0
        if test $silent -eq 0
            echo "当前 PATH 中没有 Windows 路径，无需禁用"
        end
        return
    end

    # 保存被移除的 Windows 路径
    set -g __WINPATH_SAVED $win_paths

    # 只保留非 Windows 路径
    set -gx PATH $linux_paths

    if test $silent -eq 0
        echo "Windows PATH 已禁用（移除路径数量："(count $win_paths)"）"
    end
end

