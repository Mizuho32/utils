# fish right prompt の git ステータス表示を軽量化

## 背景

`fish_right_prompt.fish`(bobthefish 由来のカスタム版)は、プロンプトを描画するたびに
git ステータスを得るために **git サブプロセスを約10個** 起動していた
(`symbolic-ref`, `describe --tags`, `show-ref`, `config --bool` x2, `diff --quiet` x2,
`ls-files --other`, `rev-list --left-right`, `rev-parse --verify refs/stash` 等)。

大きいリポジトリでは `git diff --quiet`(dirty判定)や `git ls-files --other --exclude-standard`
(untracked判定)がワークツリー全体を毎回スキャンするため、Enter を押すたびに体感できる遅延が発生していた。

## 既存ソリューションの調査結果

- **fish 用に「git コマンド実行時のみ再計算」という lazy キャッシュはズバリ存在しない。**
  正確性の理由(エディタ編集など git を介さない変更を見逃す)から、既存ツールはこの方式を採らない。
- 近い発想のものは以下の2系統:
  - **呼び出し統合系**: `fish-pure-prompt`(このマシンに導入済み、未使用)の
    `_pure_prompt_git_dirty.fish` は dirty 判定を `git status --porcelain` 1回にまとめている。
    ただし同期実行のまま(lazy でも async でもない)。
  - **非同期描画系**: `tide`(fishフレームワーク)や `fish-async-prompt`(acomagu)は、
    プロンプト描画自体をバックグラウンドジョブに逃がし、git 呼び出しがブロックしないようにする方式。
    ステータス計算自体は毎回行うが、シェルの入力をブロックしない。
  - **powerlevel10k の `gitstatusd`**(このマシンに zsh 用として導入済み)は常駐デーモンが差分更新で
    ほぼ即座に応答する最も高性能な方式だが、fish 向けの保守されたバインディングが無く見送り。
- 結論: 「単発呼び出し統合」+「git コマンド実行 postexec / 時間経過フォールバックによる自前 lazy キャッシュ」
  を新規に組む方針とした。

## 実装した設計

### 1. git 呼び出しの統合

branch / dirty / staged / untracked / ahead-behind の判定を、
`git status --porcelain=v2 --branch --ignore-submodules` **1回の出力パース**に統合。

- `# branch.head <name>` → ブランチ名(`(detached)` なら `git describe --tags` /
  `git show-ref` によるフォールバックへ、これは detached 時のみ発生する稀なパスなので許容)
- `# branch.ab +N -M` → ahead/behind
- `1 <XY> ...` / `2 <XY> ...` / `u ...` 行の X(index)/Y(worktree)列 → staged / dirty 判定
- `? <path>` 行の有無 → untracked 判定
- stash 数だけは git status に含まれないので `git rev-parse --verify --quiet refs/stash` を継続使用
  (ワークツリーを走査しないので軽量)

これで「フルキャッシュミス時」の呼び出し数が 約10個 → 1〜2個 に減った。

### 2. lazy キャッシュ層

リポジトリルート単位でグローバル変数にキャッシュを持つ:

- `__git_prompt_cache_root` — 直近に計算したリポジトリルート
- `__git_prompt_cache_str` — 直近に計算した、色付け済みの出力文字列そのもの
- `__git_prompt_cache_time` — 直近計算時刻
- `theme_git_prompt_cache_max_age`(デフォルト10秒、`set -g` で上書き可)

以下のいずれかに該当する時だけ実際に再計算する:

1. リポジトリルートが変わった(別リポジトリに移動 / 初回 / リポジトリ外から復帰)
2. `theme_git_prompt_cache_max_age` を経過した(git を介さない編集への追従用フォールバック)
3. 直近で `git ...` コマンドが実行された(`fish_postexec` イベントで検知)

該当しなければキャッシュ済み文字列をそのまま `echo -n` するだけで、git サブプロセスは**1回も起動しない**。

### 3. git コマンド実行検知

`fish_right_prompt` の中で(`functions -q` でガードして)一度だけ postexec ハンドラを登録:

```fish
function __git_prompt_cache_on_postexec --on-event fish_postexec
  string match -qr '^\s*(command\s+)?git\s' -- $argv[1]
  and set -g __git_prompt_cache_time 0
end
```

`__git_prompt_cache_time` を 0 にするだけで、次回描画時に「時間経過フォールバック」の条件に
自然に該当して再計算される(専用の再計算パスを postexec 側に重複実装しない)。

`lazygit` / `tig` / GUI クライアント等 git 以外の経路での変更は検知できないが、
その場合も `theme_git_prompt_cache_max_age` 秒以内には追従する。

## 変更ファイル

- `rcfile/fish/fish_right_prompt.fish` — 上記すべてをこの1ファイルに実装
  (ヘルパー関数・`fish_right_prompt` 本体が元々すべてこのファイルに同居しているため)

## 動作検証(実機で確認済み)

- `git status --porcelain=v2` のパース結果(branch/ahead/behind/staged/dirty/untracked)が実際の
  git 状態と一致すること
- キャッシュヒット時は出力が同一かつ git サブプロセスを起動しないこと
- `git status` 等の実行直後に即座に再計算されること(postexec 経由)
- 非 git コマンドではキャッシュを壊さないこと
- リポジトリ切替・リポジトリ外への移動で正しく無効化されること
- `theme_git_prompt_cache_max_age` 経過後に自動で再計算されること
- detached HEAD 時のフォールバック表示(コミットハッシュ)が動作すること

## 設定

```fish
# ~/.config/fish/config.fish などで上書き可能
set -g theme_git_prompt_cache_max_age 10  # 秒。0にすると事実上 postexec のみに依存
```
