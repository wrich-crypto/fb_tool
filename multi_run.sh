#!/bin/bash

# 检查是否提供了 fee-rate 参数
if [ $# -eq 0 ]; then
    echo "请提供 fee-rate 参数"
    echo "用法: $0 <fee-rate>"
    exit 1
fi

# 获取 fee-rate 参数
fee_rate=$1

# 创建一个数组来存储所有子进程的PID
pids=()

# 为每个CLI文件夹运行命令
for i in {21..30}; do
    (
        cd "cli$i" || exit
        while true; do
            echo "[CLI$i] 执行命令，fee-rate: $fee_rate"
            yarn cli mint -i 97ab80dc8860a7ff98dc73116bf6fb009eaac2a04a4654f96749190b5dc15eeb_0 --fee-rate "$fee_rate"
            if [ $? -ne 0 ]; then
                echo "[CLI$i] 命令执行失败，退出循环"
                break
            fi
            sleep 1
        done
    ) &

    # 存储子进程的PID
    pids+=($!)
done

echo "所有CLI命令已启动。按 Ctrl+C 停止所有进程。"

# 捕获 SIGINT 信号（Ctrl+C）
trap 'kill ${pids[@]}; exit 1' SIGINT

# 等待所有子进程完成
wait