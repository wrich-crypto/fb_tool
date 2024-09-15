#!/bin/bash

# 检查是否提供了参数
if [ $# -ne 2 ]; then
    echo "用法: $0 <起始编号> <结束编号>"
    exit 1
fi

start_number=$1
end_number=$2

# 检查参数是否为数字
if ! [[ "$start_number" =~ ^[0-9]+$ ]] || ! [[ "$end_number" =~ ^[0-9]+$ ]]; then
    echo "错误: 请提供有效的数字作为起始编号和结束编号"
    exit 1
fi

# 检查起始编号是否小于等于结束编号
if [ "$start_number" -gt "$end_number" ]; then
    echo "错误: 起始编号必须小于或等于结束编号"
    exit 1
fi

# 检查原始cli文件夹是否存在
if [ ! -d "cli" ]; then
    echo "错误: 原始cli文件夹不存在"
    exit 1
fi

# 复制并创建新的cli文件夹
for i in $(seq "$start_number" "$end_number"); do
    new_folder="cli$i"
    if [ -d "$new_folder" ]; then
        echo "警告: $new_folder 已存在，是否要覆盖？(y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "覆盖 $new_folder"
            rm -rf "$new_folder"
            cp -r cli "$new_folder"
        else
            echo "跳过 $new_folder"
        fi
    else
        echo "创建 $new_folder"
        cp -r cli "$new_folder"
    fi
done

echo "操作完成"