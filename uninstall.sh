#!/usr/bin/env bash

CLASHCTL_SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
. "$CLASHCTL_SRC/scripts/preflight.sh"
. "$CLASHCTL_SRC/scripts/cmd/off.sh"

! _is_root && tunstatus >&/dev/null && {
    _errorcat "请先关闭 Tun 模式"
    exit
}

validate_uninstall_path() {
    [ -n "$CLASHCTL_HOME" ] || _errorcat "CLASHCTL_HOME 为空，拒绝卸载" || exit 1
    [ "$CLASHCTL_HOME" != "/" ] || _errorcat "CLASHCTL_HOME 指向根目录，拒绝卸载" || exit 1
    [ "$CLASHCTL_HOME" != "$HOME" ] || _errorcat "CLASHCTL_HOME 指向 HOME 目录，拒绝卸载" || exit 1

    [ -d "$CLASHCTL_HOME" ] || return 0
    [ -f "$CLASHCTL_HOME/.env" ] &&
        [ -f "$CLASHCTL_HOME/scripts/cmd/clashctl.sh" ] &&
        [ -f "$CLASHCTL_HOME/uninstall.sh" ] || {
        _errorcat "$CLASHCTL_HOME 不像有效的 clashctl 安装目录，拒绝删除"
        exit 1
    }
}

validate_uninstall_path
uninstall_service

command -v crontab >&/dev/null && {
    crontab -l 2>/dev/null | grep -Fv "$CLASHCTL_CRON_TAG" | crontab -
}

/usr/bin/rm -rf "$CLASHCTL_HOME"
revoke_rc

_okcat '✨' "已卸载，相关配置已清除"
[ -n "$http_proxy" ] && _failcat '❗' "当前终端仍残留代理环境变量，重开终端即可清除"
