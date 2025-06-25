
#!/bin/bash

REPO="OpenListTeam/OpenList"
INSTALL_DIR="$HOME/openlist"
ARCH="386"
OS="linux"
FILENAME="openlist-${OS}-${ARCH}.tar.gz"
PORT_FILE="$INSTALL_DIR/.port"
PASS_FILE="$INSTALL_DIR/.passwd"

# 检查依赖
command -v curl >/dev/null || { echo "❌ 缺少 curl，请手动安装。"; exit 1; }
command -v tar >/dev/null || { echo "❌ 缺少 tar，请手动安装。"; exit 1; }

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

install_openlist() {
    echo "📦 准备安装 OpenList 到 $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    echo "🌐 获取最新版本号..."
    LATEST_TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep tag_name | cut -d '"' -f4)
    if [ -z "$LATEST_TAG" ]; then
        echo "❌ 获取版本失败"
        return
    fi

    echo "⬇️ 下载 openlist $LATEST_TAG..."
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${FILENAME}"
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

    cd "$INSTALL_DIR"

    echo "🔐 设置密码..."
    ./openlist admin set "$PASSWD"

    echo "🚀 使用 nohup 启动..."
    nohup ./openlist -port "$PORT" > openlist.log 2>&1 &

    echo "✅ 启动完成"
}

show_info() {
    if [ ! -f "$PORT_FILE" ]; then
        echo "ℹ️ 尚未启动 OpenList。"
        return
    fi

    PORT=$(cat "$PORT_FILE")
    PASSWD=$(cat "$PASS_FILE")
    IP=$(hostname -I | awk '{print $1}')

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
    cd "$INSTALL_DIR"
    ./openlist admin set "$NEWPASS"
    echo "$NEWPASS" > "$PASS_FILE"
    echo "✅ 密码已修改"
}

check_update() {
    echo "🔍 检查 OpenList 是否有新版本..."

    # 获取远程最新版本
    LATEST_TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep tag_name | cut -d '"' -f4)
    if [ -z "$LATEST_TAG" ]; then
        echo "⚠️ 无法获取最新版本信息"
        return
    fi

    # 获取本地版本
    if [ -x "$INSTALL_DIR/openlist" ]; then
        LOCAL_VER=$("$INSTALL_DIR/openlist" version 2>/dev/null | grep Version | awk '{print $2}')
    else
        LOCAL_VER="none"
    fi

    echo "🧩 本地版本: $LOCAL_VER"
    echo "🆕 最新版本: $LATEST_TAG"

    if [ "$LOCAL_VER" != "$LATEST_TAG" ]; then
        echo "🚨 检测到新版本！"
        read -p "是否更新至 $LATEST_TAG ? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            cd "$INSTALL_DIR"
            echo "⬇️ 下载新版本..."
            DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${FILENAME}"
            curl -L "$DOWNLOAD_URL" -o "$FILENAME"
            tar -xzf "$FILENAME"
            chmod +x openlist
            rm "$FILENAME"
            echo "✅ 已更新到最新版本！"
        else
            echo "ℹ️ 已取消更新"
        fi
    else
        echo "✅ 当前已是最新版本。"
    fi
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
        5) check_update ;;
        0) echo "👋 退出"; exit 0 ;;
        *) echo "⚠️ 无效输入，请重试。" ;;
    esac
    echo ""
done
