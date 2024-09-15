#!/bin/bash

# 设置起始数字
start_number=1

# 循环直到找不到下一个文件夹
while true; do
    folder="cli$start_number"
    
    # 检查文件夹是否存在
    if [ ! -d "$folder" ]; then
        echo "没有更多的文件夹，循环结束"
        break
    fi
    
    echo "处理文件夹: $folder"
    
    # 进入文件夹
    cd "$folder" || exit
    
    # 执行命令
    cat wallet.json | jq -r '.mnemonic' && yarn cli wallet address && yarn cli wallet balances
    
    
    # 返回上一级目录
    cd ..
    
    # 增加数字
    ((start_number++))
done
