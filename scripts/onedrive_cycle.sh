#!/bin/bash

open -a "OneDrive"        # 启动 OneDrive
sleep 300                 # 等待 5 分钟（300 秒）
osascript -e 'quit app "OneDrive"'  # 退出 OneDrive
