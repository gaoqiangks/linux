function enable_winpath
    set -l silent 0
    if test (count $argv) -ge 1 -a "$argv[1]" = "-s"
        set silent 1
    end

    if not set -q __WINPATH_SAVED
        if test $silent -eq 0
            echo "没有保存的 Windows PATH 信息，无法恢复"
        end
        return
    end

    set -l newpath $PATH

    # 按原顺序把之前移除的 Windows 路径加回去（避免重复）
    for p in $__WINPATH_SAVED
        if not contains -- $p $newpath
            set newpath $newpath $p
        end
    end

    set -gx PATH $newpath

    if test $silent -eq 0
        echo "Windows PATH 已恢复（恢复路径数量："(count $__WINPATH_SAVED)"）"
    end
end

