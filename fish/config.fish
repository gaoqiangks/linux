#----------------------------------------------------------------
# 让 fish 加载 bash 的初始化脚本, 否则的话一些系统环境变量会有问题. 毕竟linux的环境变量基本上都是根据bash设置的
bass source /etc/profile
bass source ~/.profile
bass source ~/.bashrc
#----------------------------------------------------------------

if not status is-interactive
    return
end

fish_add_path --prepend "$HOME/linux/bin"
fish_add_path --prepend "$HOME/linux/scripts"

set -gx OS_TYPE (get_os)

fish_vi_key_bindings

function atuin_setup
    # atuin设置
    # 不使用任何atuin内置的快捷键设置
    set -gx ATUIN_NOBIND true
    # source $HOME/.atuin/bin/env.fish
    atuin init fish | source
    # Alt-r 搜索历史记录
    bind --mode insert \er fzf_atuin_history_edit
    bind --mode default \er fzf_atuin_history_edit
end


function alias_setup
    alias vi=nvim
    alias ss=search
    alias lazy="cd ~/.local/share/nvim/lazy"
    alias cv="cd ~/.config/nvim/"
    alias cf="cd ~/.config/fish/"
    alias co="cd ~/OneDrive"
    alias cl="cd ~/OneDrive/WorkSpace/latex"
    alias cvv="cd ~/.config/nvim/lua/plugins"
    # alias stylua="stylua --config-path ~/.config/stylua.toml"
    # alias cat="bat"
    #-n不计算行数, 可以大大提高速度
    #-R可以显示颜色, 比如grep 'xx' --color=always | less -R
    alias less="less -n -R"
    # .iterm2_shell_integration 里用到了grep, 所以要把grep的alias放在iterm2_shell_integration的下面, 否则会导致报错
    # alias grep="rg --color=always --colors='match:style:underline' --ignore-case"
    alias grep="rg --ignore-case"
    alias ss="$HOME/linux/scripts/search"
    alias rg="rg --ignore-case"
    alias lipsum=lorem
    # alias which=type
    alias his=history
end

function env_setup
    set -gx EDITOR nvim
    set -gx PAGER nvimpager

    set -gx MANPAGER nvimpager

    #如果不加的话, man可能会找不到brew安斗的软件的man手册. 但是如果加了的话, 系统的manpage就找不到了.  而且命令manpath本身输出的路径也包含了这个路径了. 所以这里注释掉了.  用mandb -u创建用户级数据库即可. 要更新也是mandb -u
    # set -gx MANPATH $MAHPATH /home/linuxbrew/.linuxbrew/share/man

    # 设置 Homebrew 镜像源 (中国科学技术大学)
    # 设置 Homebrew Git 远程仓库 (主程序)
    set -gx HOMEBREW_BREW_GIT_REMOTE "https://mirrors.ustc.edu.cn/brew.git"

    # 设置 Homebrew Core 仓库 Git 远程仓库
    set -gx HOMEBREW_CORE_GIT_REMOTE "https://mirrors.ustc.edu.cn/homebrew-core.git"

    # 设置 Homebrew 二进制包 (Bottle) 下载域名
    set -gx HOMEBREW_BOTTLE_DOMAIN "https://mirrors.ustc.edu.cn/homebrew-bottles"

    # 设置 Homebrew API 域名
    set -gx HOMEBREW_API_DOMAIN "https://mirrors.ustc.edu.cn/homebrew-bottles/api"

    set -gx HOMEBREW_CASK_GIT_REMOTE "https://mirrors.ustc.edu.cn/homebrew-cask.git"
    # export NO_ALBUMENTATIONS_UPDATE = 1

    set -gx LDFLAGS -L/opt/homebrew/opt/curl/lib
    set -gx CPPFLAGS -I/opt/homebrew/opt/curl/include

    set -gx PKG_CONFIG_PATH /opt/homebrew/opt/curl/lib/pkgconfig

    # fzf搜索的时候, 当前行文本高亮为红色 
    set -gx FZF_DEFAULT_OPTS "\
                                --color=bg+:#9097b7:bold\
                                --bind 'alt-p:up,alt-n:down'\
                                --bind 'tab:accept'\
                                --bind 'alt-q:abort'\
                                --exact\
                             "
    # 去掉 WSL 中 Windows 挂载目录的绿色背景 (ow=其它用户可写, tw=带粘滞位的其它用户可写)
    set -gx LS_COLORS (string join ":" $LS_COLORS "ow=01;34" "tw=01;34")
end

function shortcuts_setup
    #alt-w 接受当前的补全
    bind --mode insert \ew accept-autosuggestion
    bind \ew accept-autosuggestion

    #alt-l 接受下一个单词
    bind --mode insert \el nextd-or-forward-word
    bind \el nextd-or-forward-word

    #alt-s  启动nvim并搜索历史session
    bind --mode insert \es "nvim -c \"Telescope persisted\""
    bind insert \es "nvim -c \"Telescope persisted\""

    # --- 绑定 Alt-p (上一条历史) ---
    bind --mode insert \ep history-search-backward
    bind --mode default \ep history-search-backward

    # --- 绑定 Alt-n (下一条历史) ---
    bind --mode insert \en history-search-forward
    bind --mode default \en history-search-forward

    # --- 绑定 Alt-e  ---
    bind --mode insert \ee __alt_e_handler
    bind --mode default \ee __alt_e_handler
end

function macos_setup
    test -e {$HOME}/.iterm2_shell_integration.fish; and source {$HOME}/.iterm2_shell_integration.fish

    function rime
        nvim /Users/gaoqiang/Library/CloudStorage/OneDrive-个人/MacOS/Rime/wubi98.dict.yaml
    end

    function code
        open -a "Visual Studio Code" $argv
    end
    eval "$(/opt/homebrew/bin/brew shellenv)"
    source ~/.linuxify
end

disable_winpath -s

switch $OS_TYPE
    case linux wsl
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    case macos
        macos_setup
end

# Ctrl-v 搜索变量
# Ctrl-r 或者 Alt-r 命令行历史记录
# Ctrl Alt f  文件搜索, 不包含隐藏的文件
# Alt -f 搜索文件 包含隐藏文件

fzf --fish | source

atuin_setup

# Alt-r 命令行历史记录, 默认是ctrl-r
# fzf_configure_bindings --history=\er

alias_setup

# 环境变量设置
env_setup

# 快捷键设置
shortcuts_setup

starship init fish | source
