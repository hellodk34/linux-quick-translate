#!/bin/bash

# ===== 百度翻译 API 配置（请填写你的信息）=====
APPID="你的APPID"
SECRET="你的密钥"
FROM_LANG="en"
TO_LANG="zh"
# =============================================

# Check if clipboard contains plain text (not files, images, etc.)
check_clipboard_is_text() {
    if command -v wl-paste &>/dev/null; then
        local types
        types=$(wl-paste --list-types 2>/dev/null)
        if [[ -z "$types" ]]; then
            return 2   # empty or unknown
        fi
        # image/* or text/uri-list → non-text (files, images)
        if echo "$types" | grep -qE '^image/|^text/uri-list'; then
            return 1
        fi
        if ! echo "$types" | grep -q 'text/plain'; then
            return 2   # no text/plain found, but not image/uri-list either
        fi
    elif command -v xclip &>/dev/null; then
        local targets
        targets=$(xclip -selection clipboard -t TARGETS -o 2>/dev/null)
        if [[ -z "$targets" ]]; then
            return 2   # empty or unknown
        fi
        # image/* or text/uri-list → non-text (files, images)
        if echo "$targets" | grep -qE '^image/|^text/uri-list'; then
            return 1
        fi
        if ! echo "$targets" | grep -qE '^(STRING|TEXT|UTF8_STRING)$' && ! echo "$targets" | grep -q 'text/plain'; then
            return 2   # no text targets found, but not image/uri-list either
        fi
    fi
    return 0
}

get_clipboard() {
    local text=""
    if command -v wl-paste &>/dev/null; then
        text=$(wl-paste 2>/dev/null)
    fi
    if [[ -z "$text" ]] && command -v xclip &>/dev/null; then
        text=$(timeout 1 xclip -o -selection clipboard 2>/dev/null)
    fi
    if [[ -z "$text" ]] && command -v xsel &>/dev/null; then
        text=$(xsel -b 2>/dev/null)
    fi
    echo "$text"
}

show_sdcv_result() {
    local word="$1"
    local result
    result=$(sdcv -n "$word" 2>&1)
    if [[ $? -ne 0 ]] || [[ -z "$result" ]]; then
        notify-send -t 3000 "SDCV 查词" "未找到单词: $word"
        return 1
    fi
    if command -v zenity &>/dev/null; then
        printf '%s' "$result" | zenity --text-info \
            --title="SDCV: $word" \
            --width=600 --height=400 \
            --font="monospace 12" \
            --ok-label="知道了" \
            --cancel-label="关闭" 2>/dev/null
    else
        notify-send -t 15000 "SDCV: $word" "$result"
    fi
}

show_translation() {
    local text="$1" translation="$2"
    local len=${#text} w h

    if [[ $len -le 100 ]]; then
        w=600; h=400
    elif [[ $len -le 500 ]]; then
        w=800; h=500
    else
        w=1000; h=600
    fi

    if command -v zenity &>/dev/null; then
        printf '原文：\n\n%s\n\n译文：\n\n%s' "$text" "$translation" | \
            zenity --text-info \
                --title="在线翻译" \
                --width=$w --height=$h \
                --font="monospace 12" \
                --ok-label="知道了" \
                --cancel-label="关闭" 2>/dev/null
    else
        notify-send -t 15000 "翻译" "$translation"
    fi
}

call_baidu_api() {
    local text="$1" salt sign response

    salt=$(date +%s)
    sign=$(printf '%s' "${APPID}${text}${salt}${SECRET}" | md5sum | cut -d ' ' -f1)

    response=$(curl -s -G "https://api.fanyi.baidu.com/api/trans/vip/translate" \
        --data-urlencode "q=${text}" \
        --data-urlencode "from=${FROM_LANG}" \
        --data-urlencode "to=${TO_LANG}" \
        --data-urlencode "appid=${APPID}" \
        --data-urlencode "salt=${salt}" \
        --data-urlencode "sign=${sign}")

    echo "$response"
}

parse_translation() {
    local json="$1"
    echo "$json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'error_code' in data:
    print('ERROR:' + data.get('error_msg', '未知错误'))
    sys.exit(1)
for r in data.get('trans_result', []):
    print(r['dst'])
"
}

# ==== 主流程 ====

check_clipboard_is_text
case $? in
    1)
        notify-send -t 3000 "⚠️ 只支持文本" "剪贴板内容不是纯文本，只支持文本查询/翻译"
        exit 1
        ;;
    2)
        notify-send -t 3000 "⚠️ 未知内容" "未知的剪贴板内容，无法查询/翻译"
        exit 1
        ;;
esac

RAW=$(get_clipboard)
if [[ -z "$RAW" ]]; then
    notify-send -t 3000 "翻译" "请先复制文本"
    exit 1
fi

# 判断是否单个英文单词
NO_SPACE=$(echo "$RAW" | tr -d '[:space:]')
if echo "$NO_SPACE" | grep -qE '^[a-zA-Z]+$'; then
    show_sdcv_result "$NO_SPACE"
    exit $?
fi

# 多词/句子 → 百度翻译
if [[ -z "$APPID" || -z "$SECRET" ]]; then
    notify-send -t 5000 "翻译" "请先在脚本中配置百度翻译 APPID 和 SECRET"
    exit 1
fi

RESPONSE=$(call_baidu_api "$RAW")
TRANSLATION=$(parse_translation "$RESPONSE")

if [[ "$TRANSLATION" == ERROR:* ]]; then
    notify-send -t 5000 "翻译出错" "${TRANSLATION#ERROR:}"
    exit 1
fi

if [[ -z "$TRANSLATION" ]]; then
    notify-send -t 5000 "翻译" "解析翻译结果失败"
    exit 1
fi

show_translation "$RAW" "$TRANSLATION"
