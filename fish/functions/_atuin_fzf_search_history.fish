function _atuin_fzf_search_history \
    --description "Search shell history via atuin + fzf and put selection into commandline"

    # 仅在交互式 shell 中生效
    status is-interactive; or return

    set -f time_prefix_regex '^.*? │ '

    # 取历史记录（最近的在前）
    set -l selected (
        atuin history list --format "{time} │ {command}" --print0 --reverse false |
        _fzf_wrapper --expect=alt-e --read0 \
            --print0 \
            --multi \
            --scheme=history \
            --prompt="History> " \
            --query=(commandline) \
            --preview="string replace --regex '$time_prefix_regex' '' -- {} | fish_indent --ansi" \
            --preview-window="bottom:3:wrap" \
            $fzf_history_opts |
        string split0 |
        # remove timestamps from commands selected
        string replace --regex $time_prefix_regex ''
        )

    # commandline --function repaint
    if test $status -eq 0
        commandline --replace -- $selected
    end

    commandline --function repaint
end
