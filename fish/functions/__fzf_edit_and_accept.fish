function __fzf_edit_and_accept
    set -l line $argv[1]
    set -l tmp (mktemp)

    # 写入选中的整行
    printf "%s" "$line" > $tmp

    # 编辑
    $EDITOR $tmp

    # 读回
    set -l newcmd (cat $tmp)

    # 写回命令行
    commandline --replace "$newcmd"

    rm $tmp
end

