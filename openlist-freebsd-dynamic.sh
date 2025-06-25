
#!/bin/bash

INSTALL_DIR="$HOME/openlist"
ARCHIVE_TYPE="freebsd-amd64"
PORT_FILE="$INSTALL_DIR/.port"
PASS_FILE="$INSTALL_DIR/.passwd"
REPO="OpenListTeam/OpenList"

show_menu() {
    echo "========== OpenList 一键管理菜单 =========="
    echo "1. 安装 OpenList"
    echo "2. 启动 OpenList (守护进程)"
    echo "3. 查看 OpenList 状态与访问信息"
    echo "4. 修改 OpenList 后台密码"
    echo "5. 检查/更新 OpenList 至最新版"
    echo "0. 退出"
    echo "==========================================="
}

get_latest_version() {
    curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep tag_name | cut -d '"' -f4
}

install_openlist() {
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || exit

    echo "🌐 获取最新版本号..."
    LATEST_TAG=$(get_latest_version)
    if [ -z "$LATEST_TAG" ]; then
        echo "❌ 获取版本失败"
        return
    fi

    FILENAME="openlist-${ARCHIVE_TYPE}.tar.gz"
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${FILENAME}"

    echo "⬇️ 下载 OpenList ${LATEST_TAG} (${ARCHIVE_TYPE})..."
    curl -L "$DOWNLOAD_URL" -o "$FILENAME" || { echo "❌ 下载失败"; return; }

    echo "📂 解压中..."
    tar -xzf "$FILENAME"
    chmod +x openlist
    rm "$FILENAME"
    echo "✅ 安装完成。"
}

start_openlist() {
    if [ ! -f "$INSTALL_DIR/openlist" ]; then
        echo "❌ 未安装 OpenList，请先安装。"
        return
    fi

    read -p "请输入监听端口（默认 5244）: " PORT
    PORT=${PORT:-5244}
    echo "$PORT" > "$PORT_FILE"

    read -p "设置后台管理密码（默认 admin123）: " PASSWD
    PASSWD=${PASSWD:-admin123}
    echo "$PASSWD" > "$PASS_FILE"

    cd "$INSTALL_DIR" || exit
    ./openlist admin set "$PASSWD"

    echo "🚀 使用 nohup 启动..."
    nohup ./openlist -port "$PORT" > openlist.log 2>&1 &
    echo "✅ 启动成功！日志文件: $INSTALL_DIR/openlist.log"
}

show_info() {
    if [ ! -f "$PORT_FILE" ]; then
        echo "ℹ️ 尚未启动 OpenList。"
        return
    fi
    PORT=$(cat "$PORT_FILE")
    PASSWD=$(cat "$PASS_FILE")
    IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    echo "========== OpenList 信息 =========="
    echo "地址: http://$IP:$PORT"
    echo "后台密码: $PASSWD"
    echo "安装目录: $INSTALL_DIR"
    echo "日志文件: $INSTALL_DIR/openlist.log"
    echo "==================================="
}

change_password() {
    if [ ! -f "$INSTALL_DIR/openlist" ]; then
        echo "❌ 未检测到 openlist 程序"
        return
    fi
    read -p "请输入新密码: " NEWPASS
    cd "$INSTALL_DIR" || exit
    ./openlist admin set "$NEWPASS"
    echo "$NEWPASS" > "$PASS_FILE"
    echo "✅ 密码已修改"
}

update_openlist() {
    echo "🔍 检查 OpenList 是否有新版本..."
    cd "$INSTALL_DIR" || exit

    LATEST_TAG=$(get_latest_version)
    FILENAME="openlist-${ARCHIVE_TYPE}.tar.gz"
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${FILENAME}"

    echo "⬇️ 下载最新版 ${LATEST_TAG}..."
    curl -L "$DOWNLOAD_URL" -o "$FILENAME" || { echo "❌ 下载失败"; return; }
    tar -xzf "$FILENAME"
    chmod +x openlist
    rm "$FILENAME"
    echo "✅ 已更新至 $LATEST_TAG"
}

# 主菜单循环
while true; do
    show_menu
    read -p "请输入选项 [0-5]: " choice
    case "$choice" in
        1) install_openlist ;;
        2) start_openlist ;;
        3) show_info ;;
        4) change_password ;;
        5) update_openlist ;;
        0) echo "👋 退出"; exit 0 ;;
        *) echo "⚠️ 无效输入，请重试。" ;;
    esac
    echo ""
done
