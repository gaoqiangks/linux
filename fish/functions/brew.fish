function brew --description 'Homebrew 包装器：安装软件后自动更新手册页索引'
    # 执行原始的 brew 命令
    command brew $argv
    set -l brew_status $status

    # 定义需要触发数据库更新的子命令
    set -l update_cmds install upgrade reinstall uninstall

    # 只有在 brew 执行成功，且子命令在列表中时才运行 mandb
    if test $brew_status -eq 0
       and contains -- $argv[1] $update_cmds

        # 使用 -u 更新用户级数据库，-q 为静默模式
        # 手动指定 Homebrew 的手册路径以确保 mandb 一定能扫描到
        set -l brew_manpath (command brew --prefix)/share/man
        if test -d $brew_manpath
            mandb -u -q $brew_manpath 2>/dev/null
        end
    end

    # 返回 brew 原本的退出状态码
    return $brew_status
end
