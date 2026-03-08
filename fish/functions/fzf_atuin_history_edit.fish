function fzf_atuin_history_edit
    set -l result (
        atuin history list \
            --reverse false \
            --format '{command}' \
            --print0 |
        fzf --no-sort --read0 --print0 --expect=alt-e |
        string split0
    )

    if test (count $result) -eq 0
        return
    end

    set -l key $result[1]
    set -l cmd $result[2]

    if test -z "$cmd"
        return
    end

    if test "$key" = "alt-e"
        set -l tmp (mktemp)

        printf "%s" "$cmd" > $tmp

        $EDITOR $tmp
        set -l status_code $status

        # 非 0 退出码 -> 取消
        if test $status_code -ne 0
            rm -f $tmp
            return
        end

        set -l newcmd (cat $tmp)
        rm -f $tmp

        commandline --replace -- $newcmd
    else
        commandline --replace -- $cmd
    end
end

