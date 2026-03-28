#!/bin/bash

# --- 設定 ---
# WOLを有効化したい接続名に含まれるキーワードを設定します
# 例: "wired1" の場合は "wired" や "wired1" など
SEARCH_KEYWORD="$1"

# WOL の設定値 (magicパケット)
WOL_SETTING="magic"
# --- 設定終 ---
# 1. nmcli con show の結果から、キーワードに一致する接続名を抽出
# - grep: キーワードを含む行を抽出
# - awk: 1列目 (接続名) のみを取得
# - head -n 1: 複数ヒットした場合は最初の1つのみを使用

if [ -z "$SEARCH_KEYWORD" ]; then
  CONNECTION_NAME=''
else
  CONNECTION_NAME=$(nmcli con show | grep -i "$SEARCH_KEYWORD" | awk '{print $1}' | head -n 1)
fi

# 2. 接続名が取得できたかを確認
if [ -z "$CONNECTION_NAME" ]; then
    echo "🚨 エラー: キーワード '$SEARCH_KEYWORD' に一致する接続が見つかりませんでした。"
    echo "   'nmcli con show' で接続名を確認してください。"
    nmcli con show
    exit 1
fi

echo "✅ 接続名 '$CONNECTION_NAME' を見つけました。"

# 3. nmcli c modify コマンドで WOL を有効化
echo "⚙️ '$CONNECTION_NAME' の Wake-on-LAN を '$WOL_SETTING' に設定しています..."

# 実行
sudo nmcli connection modify "$CONNECTION_NAME" 802-3-ethernet.wake-on-lan "$WOL_SETTING"

# 4. 実行結果の確認
if [ $? -eq 0 ]; then
    echo "🎉 成功: '$CONNECTION_NAME' の Wake-on-LAN は '$WOL_SETTING' に設定されました。"
    
    # 5. 設定後の状態を確認 (オプション)
    echo "👀 現在の WOL 設定を確認しています..."
    sudo nmcli connection show "$CONNECTION_NAME" | grep 802-3-ethernet.wake-on-lan
else
    echo "❌ 失敗: nmcli コマンドの実行中にエラーが発生しました。"
    echo "   root権限 (sudo) で実行しているか、接続名が正しいか確認してください。"
    exit 1
fi
