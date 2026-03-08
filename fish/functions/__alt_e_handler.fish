function __alt_e_handler
    # 获取当前命令行内容
    set cmd (commandline)

    # 如果为空，直接进入 edit_command_buffer
    if test -z "$cmd"
        edit_command_buffer
        return
    end

    # 如果是存在的文件路径
    if test -e "$cmd"
        # 清空命令行并打开文件
        commandline -r ""
        nvim "$cmd"
        return
    end

    # 否则执行 edit_command_buffer
    edit_command_buffer
end

