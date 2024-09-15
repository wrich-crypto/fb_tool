#!/bin/bash

# 创建日志目录
log_dir="multi_run_logs"
mkdir -p "$log_dir"

# 获取当前时间戳
timestamp=$(date +"%Y%m%d_%H%M%S")

# 创建主日志文件
main_log="$log_dir/multi_run_$timestamp.log"

# 让用户输入参数
read -p "请输入mint命令的-i参数值: " mint_input
read -p "请设置 gas 费用的上限（satoshis/byte）: " max_fee_rate

if ! [ "$max_fee_rate" -eq "$max_fee_rate" ] 2>/dev/null; then
    echo "无效的gas上限，请输入有效的数字" | tee -a "$main_log"
    exit 1
fi

echo "开始执行 multi_run.sh，时间: $(date)" | tee -a "$main_log"
echo "Mint 输入参数: $mint_input" | tee -a "$main_log"
echo "Gas 费用上限设置为: $max_fee_rate satoshis/byte" | tee -a "$main_log"

pids=()

for i in {21..30}; do
    cli_log="$log_dir/cli${i}_$timestamp.log"
    (
        cd "cli$i" || exit
        while true; do
            # 获取当前费率
            response=$(curl --user bitcoin:opcatAwesome \
                --data-binary '{"jsonrpc": "1.0", "id": "curltest", "method": "estimatesmartfee", "params": [6]}' \
                -H 'content-type: text/plain;' \
                http://127.0.0.1:8332/ 2>/dev/null)

            feerate=$(echo $response | grep -o '"feerate":[^,]*' | sed 's/"feerate"://')

            if [ -z "$feerate" ]; then
                echo "[CLI$i] 无法获取 feerate，退出循环" | tee -a "$cli_log" "$main_log"
                break
            fi

            fee_rate_satoshi=$(echo "$feerate * 100000" | bc | awk '{printf "%.0f", $0}')

            if [ -z "$fee_rate_satoshi" ] || ! echo "$fee_rate_satoshi" | grep -qE '^[0-9]+$'; then
                echo "[CLI$i] 当前费率无效，跳过本次循环" | tee -a "$cli_log" "$main_log"
                sleep 1
                continue
            fi

            echo "[CLI$i] 当前费率 (satoshis/byte): $fee_rate_satoshi" | tee -a "$cli_log" "$main_log"

            if [ "$fee_rate_satoshi" -gt "$max_fee_rate" ]; then
                echo "[CLI$i] 当前费率 $fee_rate_satoshi satoshis/byte 超出用户设置的上限 $max_fee_rate satoshis/byte，等待..." | tee -a "$cli_log" "$main_log"
                sleep 1
                continue
            fi

            echo "[CLI$i] 执行命令，fee-rate: $fee_rate_satoshi" | tee -a "$cli_log" "$main_log"
            yarn cli mint -i "$mint_input" --fee-rate "$fee_rate_satoshi" 2>&1 | tee -a "$cli_log" "$main_log"
            if [ ${PIPESTATUS[0]} -ne 0 ]; then
                echo "[CLI$i] 命令执行失败，退出循环" | tee -a "$cli_log" "$main_log"
                break
            fi
            sleep 1
        done
    ) &

    pids+=($!)
done

echo "所有CLI命令已启动。按 Ctrl+C 停止所有进程。" | tee -a "$main_log"
echo "主日志文件: $main_log" | tee -a "$main_log"
echo "各CLI日志文件位于: $log_dir" | tee -a "$main_log"

trap 'echo "正在停止所有进程..." | tee -a "$main_log"; kill ${pids[@]}; echo "所有进程已停止" | tee -a "$main_log"; exit 1' SIGINT

wait