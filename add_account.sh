#!/bin/bash

# 设置起始数字
start_number=1

# 循环直到找不到下一个文件夹
while true; do
    folder="cli$start_number"
    
    # 检查文件夹是否存在
    if [ ! -d "$folder" ]; then
        echo "创建文件夹: ${folder}"
        cp -r cli23 $folder
    fi
    
    echo "处理文件夹: $folder"
    
    # 进入文件夹
    cd "$folder" || exit
    
    # 执行命令
    rm wallet.json && yarn cli wallet create && yarn cli wallet address
    
    # 返回上一级目录
    cd ..
    
    # 增加数字
    ((start_number++))
done
