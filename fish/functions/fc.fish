function fc
    set -l editor $EDITOR
    if test -z "$editor"
        set editor vi
    end

    switch "$argv[1]"
        case '-l'
            history | nl
            return

        case '-s'
            if test (count $argv) -eq 2
                # fc -s pattern
                set cmd (history | grep -m1 -- "$argv[2]")
            else if test (count $argv) -eq 3
                # fc -s old=new
                set last (history | head -n1)
                set cmd (string replace "$argv[2]" "$argv[3]" -- $last)
            end

            if test -n "$cmd"
                commandline -r "$cmd"
                commandline -f execute
            end
            return
    end

    # 默认行为：编辑上一条命令
    set tmp (mktemp)
    history | head -n1 > $tmp

    $editor $tmp
    set edit_status $status

    # 如果编辑器退出码不是 0，代表用户取消编辑
    if test $edit_status -ne 0
        rm $tmp
        return
    end

    set cmd (cat $tmp)
    rm $tmp

    if test -n "$cmd"
        commandline -r "$cmd"
        commandline -f execute
    end
end

