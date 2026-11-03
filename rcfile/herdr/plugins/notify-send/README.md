# herdr notify-send plugin

herdr 上の agent (claude) が入力待ち / 完了になったら KDE の通知を出し、
通知の「表示」ボタン(か通知本体のクリック)でその pane まで飛ぶ。

## 流れ

```
herdr server ── pane.agent_status_changed ──▶ notify.sh   (herdr-plugin.toml)
                                                │ 通知するか判定
                                                ▼ setsid -f
                                              popup.sh    notify-send -A で表示し、クリックを待つ
                                                │ クリックされたら
                                                ▼
                                              focus.sh <pane>
                                                1. herdr agent focus <pane>         herdr 内の pane
                                                2. tmux select-window claudes:herdr tmux のウィンドウ
                                                3. kitten @ focus-tab title:claudes kitty のタブ
                                                4. KWin 一時スクリプト              kitty ウィンドウを前面に
```

外側の入れ子は `kitty (autostart) > タブ claudes > tmux session claudes > window herdr > herdr`。
kitty / tmux の名前は `scripts/autostart.kitty-session` と tmuxinator の `claudes.yml` で固定している。

## 通知する条件 (notify.sh)

pane ごとに直前の状態を覚えておき、遷移で判定する。

| 状態 | 通知 | 条件 |
|---|---|---|
| blocked | 入力待ち (critical: 閉じるまで残る) | 直前が working のときだけ (起動直後の入力待ちを除外) |
| done | 完了 (normal: 数秒で消える) | 常に (herdr で見ていない pane) |
| idle | 完了 | 直前が working で、kitty で claudes タブを見ていないとき |

herdr は表示中の pane が終わると done ではなく idle を出す。
そこで `kitten @ ls` で「kitty にフォーカスがあり、claudes タブを表示中」かを調べ、
見ていなければ完了として通知する(状態が取れないときは通知しない)。

同じ pane の通知は 1 つにまとめる(`notify-send -r` で置き換え、前の待ち受けは kill)。
herdr 自身のトースト (`[ui.toast] delivery = "herdr"`) とは別に出る。

## 依存

- kitty の遠隔操作: `scripts/autostart.sh` が kitty を
  `-o allow_remote_control=socket-only --listen-on unix:$XDG_RUNTIME_DIR/kitty-autostart` で起動する。
  autostart 以外で起動した kitty ではタブ切替と kitty の状態判定が効かない(herdr 内の移動はする)。
- KWin: Wayland ではアプリが自分のウィンドウを前に出せないので、
  `qdbus6 org.kde.KWin /Scripting loadScript` で一時スクリプトを読み込み、実行して外す。
- コマンド: `jq` `notify-send` `kitten` `qdbus6` `tmux` `setsid`

## 登録・状態ファイル

- 登録: `herdr plugin link ~/utils/rcfile/herdr/plugins/notify-send`
  (`rcfile/loc.yaml` の after_install で実行。herdr はプラグインのフォルダを自動では探さない)
- 状態: `~/.local/state/herdr/plugins/local.notify-send/`
  - `events.log` 受け取ったイベントの直近 300 件(デバッグ用)
  - `last-status.<pane>` 直前の状態
  - `notify.<pane>.id` / `.pid` 通知 ID と待ち受けプロセス
- 手で試す: `bash focus.sh w2:p1`、プラグインのログは `herdr plugin log`

## 関連

- `rcfile/claude/hooks/herdr-resume-bwrap.py`: herdr 再起動後に claude を同じ bwrap (ro-env) の中で再開させるフック。
  通知とは別の仕組み。
