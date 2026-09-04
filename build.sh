#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "🔨 Đang biên dịch keyboard-remapper (Release mode)..."
swift build -c release

BIN_PATH=$(swift build -c release --show-bin-path)/keyboard-remapper
cp "$BIN_PATH" ./keyboard-remapper
chmod +x ./keyboard-remapper

echo "✅ Biên dịch thành công! File thực thi đã được đặt tại: $DIR/keyboard-remapper"
echo "🚀 Chạy thử: ./keyboard-remapper --help"
