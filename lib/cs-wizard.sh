# cs-wizard.sh - Interactive provider setup wizard
# Sourced by cs-core.sh and bin/cs

_CS_CATALOG_URL="https://raw.githubusercontent.com/leebo/cs/main/providers.json"
_CS_CATALOG_FILE="${CS_HOME}/providers_catalog.json"
_CS_CATALOG_TTL=86400

# ─── JSON Engine ─────────────────────────────────────────────────────────────

_CS_JSON_ENGINE=""

_cs_detect_json_engine() {
    [[ -n "$_CS_JSON_ENGINE" ]] && return 0
    if command -v jq >/dev/null 2>&1; then
        _CS_JSON_ENGINE="jq"
    elif command -v python3 >/dev/null 2>&1 && python3 -c "import json" 2>/dev/null; then
        _CS_JSON_ENGINE="python3"
    else
        echo "❌ 需要 jq 或 python3 来运行向导"
        echo "   安装 jq: brew install jq  (macOS) / apt install jq  (Linux)"
        return 1
    fi
}

# ─── JSON Parsing ─────────────────────────────────────────────────────────────

# 输出格式：index|id|name
_cs_json_list_providers() {
    local f="$1"
    case "$_CS_JSON_ENGINE" in
        jq)
            jq -r '.providers | to_entries[] | "\(.key)|\(.value.id)|\(.value.name)"' "$f"
            ;;
        python3)
            python3 - "$f" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
for i, p in enumerate(data["providers"]):
    print(f"{i}|{p['id']}|{p['name']}")
PY
            ;;
    esac
}

# 输出格式：index|model_id|label
_cs_json_list_models() {
    local f="$1" pid="$2"
    case "$_CS_JSON_ENGINE" in
        jq)
            jq -r --arg id "$pid" \
               '.providers[] | select(.id==$id) | .models | to_entries[] | "\(.key)|\(.value.id)|\(.value.label)"' "$f"
            ;;
        python3)
            python3 - "$f" "$pid" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
for p in data["providers"]:
    if p["id"] == sys.argv[2]:
        for i, m in enumerate(p.get("models", [])):
            print(f"{i}|{m['id']}|{m['label']}")
        break
PY
            ;;
    esac
}

# 获取提供商单个字段值
_cs_json_get_field() {
    local f="$1" pid="$2" field="$3"
    case "$_CS_JSON_ENGINE" in
        jq)
            jq -r --arg id "$pid" \
               '.providers[] | select(.id==$id) | .'"$field"' // ""' "$f"
            ;;
        python3)
            python3 - "$f" "$pid" "$field" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
for p in data["providers"]:
    if p["id"] == sys.argv[2]:
        val = p.get(sys.argv[3], "")
        print("" if val is None else val)
        break
PY
            ;;
    esac
}

# 输出格式：VAR_NAME|value_template（每行一个）
_cs_json_get_set_vars() {
    local f="$1" pid="$2"
    case "$_CS_JSON_ENGINE" in
        jq)
            jq -r --arg id "$pid" \
               '.providers[] | select(.id==$id) | .set_vars | to_entries[] | "\(.key)|\(.value)"' "$f"
            ;;
        python3)
            python3 - "$f" "$pid" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
for p in data["providers"]:
    if p["id"] == sys.argv[2]:
        for k, v in p.get("set_vars", {}).items():
            print(f"{k}|{v}")
        break
PY
            ;;
    esac
}

# 每行一个变量名
_cs_json_get_unset_vars() {
    local f="$1" pid="$2"
    case "$_CS_JSON_ENGINE" in
        jq)
            jq -r --arg id "$pid" \
               '.providers[] | select(.id==$id) | .unset_vars[]' "$f"
            ;;
        python3)
            python3 - "$f" "$pid" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))
for p in data["providers"]:
    if p["id"] == sys.argv[2]:
        for v in p.get("unset_vars", []):
            print(v)
        break
PY
            ;;
    esac
}

# ─── Catalog Cache ────────────────────────────────────────────────────────────

_cs_catalog_is_fresh() {
    [[ -f "$_CS_CATALOG_FILE" ]] || return 1
    local now mtime
    now=$(date +%s)
    if [[ "$(uname)" == "Darwin" ]]; then
        mtime=$(stat -f %m "$_CS_CATALOG_FILE" 2>/dev/null) || return 1
    else
        mtime=$(stat -c %Y "$_CS_CATALOG_FILE" 2>/dev/null) || return 1
    fi
    (( now - mtime < _CS_CATALOG_TTL ))
}

_cs_catalog_is_valid() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    case "$_CS_JSON_ENGINE" in
        jq)     jq -e '.providers | length > 0' "$file" >/dev/null 2>&1 ;;
        python3) python3 -c "
import json,sys
d=json.load(open('$file'))
assert len(d.get('providers',[]))>0
" 2>/dev/null ;;
    esac
}

_cs_download_file() {
    local url="$1" dest="$2"
    local tmp="${dest}.tmp"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --connect-timeout 5 --max-time 15 "$url" -o "$tmp" 2>/dev/null
    elif command -v wget >/dev/null 2>&1; then
        wget -q --timeout=15 "$url" -O "$tmp" 2>/dev/null
    else
        return 1
    fi
    if [[ -s "$tmp" ]]; then
        mv "$tmp" "$dest"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

_cs_catalog_fetch_remote() {
    local tmp="${_CS_CATALOG_FILE}.tmp"
    _cs_download_file "$_CS_CATALOG_URL" "$tmp" || return 1
    if _cs_catalog_is_valid "$tmp"; then
        mv "$tmp" "$_CS_CATALOG_FILE"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# ─── Self-Update ──────────────────────────────────────────────────────────────

_CS_BASE_URL="https://raw.githubusercontent.com/leebo/cs/main"

_cs_update() {
    echo "🔄 Updating cs..."
    echo ""

    local failed=0

    _cs_update_one_file() {
        local remote_path="$1" local_path="$2" label="$3"
        local dest_dir
        dest_dir=$(dirname "$local_path")
        mkdir -p "$dest_dir"
        if _cs_download_file "${_CS_BASE_URL}/${remote_path}" "$local_path"; then
            echo "  ✅ $label"
        else
            echo "  ❌ $label (download failed)"
            (( failed++ )) || true
        fi
    }

    _cs_update_one_file "bin/cs"           "${CS_HOME}/bin/cs"                  "bin/cs"
    chmod +x "${CS_HOME}/bin/cs" 2>/dev/null || true
    _cs_update_one_file "lib/cs-core.sh"   "${CS_HOME}/lib/cs-core.sh"          "lib/cs-core.sh"
    _cs_update_one_file "lib/cs-wizard.sh" "${CS_HOME}/lib/cs-wizard.sh"        "lib/cs-wizard.sh"
    _cs_update_one_file "lib/cs-core.fish" "${CS_HOME}/lib/cs-core.fish"        "lib/cs-core.fish"

    # Force-refresh providers catalog (bypass TTL)
    local tmp="${_CS_CATALOG_FILE}.tmp"
    if _cs_download_file "$_CS_CATALOG_URL" "$tmp" && _cs_catalog_is_valid "$tmp"; then
        mv "$tmp" "$_CS_CATALOG_FILE"
        echo "  ✅ providers catalog"
    else
        rm -f "$tmp"
        echo "  ❌ providers catalog (download failed)"
        (( failed++ )) || true
    fi

    echo ""
    if (( failed == 0 )); then
        echo "✅ cs updated successfully!"
    else
        echo "⚠️  cs updated with $failed error(s). Check network and retry."
    fi

    # Detect which RC file to suggest
    local rc_file=""
    case "$(basename "${SHELL:-}")" in
        zsh)  rc_file="~/.zshrc" ;;
        bash) rc_file="~/.bashrc" ;;
        fish) rc_file="~/.config/fish/config.fish" ;;
    esac
    [[ -n "$rc_file" ]] && echo "   Run: source $rc_file  (to reload shell functions)"

    unset -f _cs_update_one_file
    return $failed
}

_cs_get_catalog_file() {
    mkdir -p "$CS_HOME"
    _cs_detect_json_engine || return 1

    if _cs_catalog_is_fresh; then
        echo "$_CS_CATALOG_FILE"
        return 0
    fi

    if _cs_catalog_fetch_remote; then
        echo "$_CS_CATALOG_FILE"
        return 0
    fi

    if _cs_catalog_is_valid "$_CS_CATALOG_FILE"; then
        echo "[offline] 无法连接网络，使用本地缓存" >&2
        echo "$_CS_CATALOG_FILE"
        return 0
    fi

    echo "❌ 无法获取 providers 目录，且无本地缓存" >&2
    echo "   请检查网络连接，或运行 cs -a <name> 手动添加" >&2
    return 1
}

# ─── Interactive UI ───────────────────────────────────────────────────────────

# 读取 stdin 的 "index|value|label" 条目，显示菜单，结果写入 _CS_MENU_RESULT
_cs_menu_select() {
    local prompt="$1"
    local -a vals=() labels=()
    local idx val label
    while IFS='|' read -r idx val label; do
        vals+=("$val")
        labels+=("$label")
    done
    local count=${#vals[@]}
    [[ $count -eq 0 ]] && return 1

    echo ""
    echo "$prompt"
    local i
    for (( i=0; i<count; i++ )); do
        printf "  %2d) %s\n" "$(( i+1 ))" "${labels[$i]}"
    done

    local choice
    while true; do
        printf "Enter number (1-%d, or q to quit): " "$count"
        read -r choice </dev/tty
        [[ "$choice" == "q" || "$choice" == "Q" ]] && return 1
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= count )); then
            _CS_MENU_RESULT="${vals[$(( choice - 1 ))]}"
            return 0
        fi
        echo "  请输入 1-$count 之间的数字"
    done
}

_cs_read_secret() {
    local prompt="$1"
    printf "%s" "$prompt"
    read -rs _CS_SECRET_RESULT </dev/tty
    echo ""
}

# ─── Write .env File ──────────────────────────────────────────────────────────

_cs_write_env_file() {
    local json_file="$1" provider_id="$2" api_key="$3"
    local model_id="$4" base_url="$5" config_file="$6"
    local provider_alias="$7" display_name="$8"

    local set_vars_raw unset_vars_raw
    set_vars_raw=$(_cs_json_get_set_vars "$json_file" "$provider_id")
    unset_vars_raw=$(_cs_json_get_unset_vars "$json_file" "$provider_id")

    {
        echo "# Provider: $display_name"
        echo "# Alias:    $provider_alias"
        echo "# Created:  $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Edit:     cs -e $provider_alias"
        echo ""

        while IFS='|' read -r var_name var_tpl; do
            [[ -z "$var_name" ]] && continue
            local val="${var_tpl//\{\{api_key\}\}/$api_key}"
            val="${val//\{\{model\}\}/$model_id}"
            val="${val//\{\{base_url\}\}/$base_url}"
            echo "export ${var_name}=\"${val}\""
        done <<< "$set_vars_raw"

        echo ""

        while IFS= read -r var_name; do
            [[ -z "$var_name" ]] && continue
            echo "unset $var_name"
        done <<< "$unset_vars_raw"

    } > "$config_file"

    chmod 600 "$config_file"
}

# ─── Interactive Wizard ───────────────────────────────────────────────────────

_cs_add_interactive() {
    _cs_detect_json_engine || return 1

    echo "🚀 Add Provider - Interactive Wizard"
    echo "   (enter q at any prompt to quit)"

    # Ctrl+C 优雅退出
    local _cs_wizard_interrupted=0
    trap '_cs_wizard_interrupted=1' INT

    local catalog_file
    catalog_file=$(_cs_get_catalog_file) || { trap - INT; return 1; }

    # 选择提供商
    _CS_MENU_RESULT=""
    _cs_json_list_providers "$catalog_file" | \
        _cs_menu_select "Select a provider:" || { echo "Cancelled."; trap - INT; return 0; }
    local provider_id="$_CS_MENU_RESULT"
    local display_name
    display_name=$(_cs_json_get_field "$catalog_file" "$provider_id" "name")
    echo "  -> $display_name"

    # 选择或手动输入模型
    local model_id
    local model_lines
    model_lines=$(_cs_json_list_models "$catalog_file" "$provider_id")

    if [[ -z "$model_lines" ]]; then
        printf "\nEnter model ID: "
        read -r model_id </dev/tty
        if [[ -z "$model_id" ]]; then echo "Cancelled."; trap - INT; return 0; fi
    else
        _CS_MENU_RESULT=""
        echo "$model_lines" | _cs_menu_select "Select a model:" || { echo "Cancelled."; trap - INT; return 0; }
        model_id="$_CS_MENU_RESULT"
        echo "  -> $model_id"
    fi

    # base_url（自定义时需用户输入）
    local base_url
    local need_input_url
    need_input_url=$(_cs_json_get_field "$catalog_file" "$provider_id" "input_base_url")
    if [[ "$need_input_url" == "true" ]]; then
        printf "\nEnter base URL (e.g. https://api.example.com/v1): "
        read -r base_url </dev/tty
        if [[ -z "$base_url" ]]; then echo "Cancelled."; trap - INT; return 0; fi
    else
        base_url=$(_cs_json_get_field "$catalog_file" "$provider_id" "base_url")
    fi

    # API Key（隐藏输入）
    echo ""
    _cs_read_secret "Enter API Key: "
    local api_key="$_CS_SECRET_RESULT"
    if [[ -z "$api_key" ]]; then
        echo "❌ API Key 不能为空"
        trap - INT
        return 1
    fi

    # Provider 简称（alias）
    local default_alias
    default_alias=$(_cs_json_get_field "$catalog_file" "$provider_id" "default_alias")
    printf "\nProvider alias (default: %s): " "$default_alias"
    local alias_input
    read -r alias_input </dev/tty
    local provider_alias="${alias_input:-$default_alias}"

    if [[ ! "$provider_alias" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "❌ Alias 只能包含字母、数字、下划线和连字符"
        trap - INT
        return 1
    fi

    # 检查重名
    local config_file="${PROVIDERS_DIR}/${provider_alias}.env"
    if [[ -f "$config_file" ]]; then
        printf "Provider '%s' 已存在，覆盖？[y/N] " "$provider_alias"
        local overwrite
        read -r overwrite </dev/tty
        if [[ "$overwrite" != "y" && "$overwrite" != "Y" ]]; then
            echo "Cancelled."
            trap - INT
            return 0
        fi
    fi

    # 生成配置文件
    _cs_write_env_file \
        "$catalog_file" "$provider_id" "$api_key" \
        "$model_id" "$base_url" "$config_file" \
        "$provider_alias" "$display_name"

    trap - INT

    echo ""
    echo "✅ Provider '$provider_alias' configured successfully!"
    echo "   Switch with: cs $provider_alias"
}
