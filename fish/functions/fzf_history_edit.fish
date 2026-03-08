function fzf_history_edit
    set -l result (atuin history list --format "{command}" | fzf --expect=alt-e)

    if test (count $result) -eq 0
        return
    end

    set -l key $result[1]
    set -l line $result[2]

    if test "$key" = "alt-e"
        set -l tmp (mktemp)

        printf "%s" "$line" > $tmp
        $EDITOR $tmp

        set -l newcmd (cat $tmp)
        rm $tmp

        commandline --replace "$newcmd"
    else
        commandline --replace "$line"
    end
end

