# FROM https://github.com/oh-my-fish/theme-bobthefish

# ==============================
# Helper methods
# ==============================

function __bobthefish_dirname -d 'basically dirname, but faster'
  string replace -r '/[^/]+/?$' '' -- $argv
end

function __bobthefish_project_pwd -S -a project_root_dir -a real_pwd -d 'Print the working directory relative to project root'
  set -q theme_project_dir_length
  or set -l theme_project_dir_length 0

  set -l project_dir (string replace -r '^'"$project_root_dir"'($|/)' '' $real_pwd)

  if [ $theme_project_dir_length -eq 0 ]
    echo -n $project_dir
    return
  end

  string replace -ar '(\.?[^/]{'"$theme_project_dir_length"'})[^/]*/' '$1/' $project_dir
end

function __bobthefish_git_branch_display -S -a branch_head -d 'Format a branch name already resolved from `git status --porcelain=v2`'
  if [ -n "$branch_head" -a "$branch_head" != '(detached)' ]
    [ "$theme_display_git_master_branch" != 'yes' -a "$branch_head" = 'master' ]
    and echo $branch_glyph
    and return

    # truncate the middle of the branch name, but only if it's 25+ characters
    set -l truncname (string replace -r '^(.{28}).{3,}(.{5})$' "\$1…\$2" $branch_head)
    echo "$branch_glyph $truncname"
    return
  end

  # detached HEAD is rare enough to afford its own git calls
  set -l tag (command git describe --tags --exact-match 2>/dev/null)
  and echo "$tag_glyph $tag"
  and return

  set -l branch (command git show-ref --head -s --abbrev 2>/dev/null | head -n1 2>/dev/null)
  echo "$detached_glyph $branch"
end

function __bobthefish_basename -d 'basically basename, but faster'
  string replace -r '^.*/' '' -- $argv
end

function __bobthefish_pretty_parent -S -a child_dir -d 'Print a parent directory, shortened to fit the prompt'
  set -q fish_prompt_pwd_dir_length
  or set -l fish_prompt_pwd_dir_length 1

  # Replace $HOME with ~
  set -l real_home ~
  set -l parent_dir (string replace -r '^'"$real_home"'($|/)' '~$1' (__bobthefish_dirname $child_dir))

  # Must check whether `$parent_dir = /` if using native dirname
  if [ -z "$parent_dir" ]
    echo -n /
    return
  end

  if [ $fish_prompt_pwd_dir_length -eq 0 ]
    echo -n "$parent_dir/"
    return
  end

  string replace -ar '(\.?[^/]{'"$fish_prompt_pwd_dir_length"'})[^/]*/' '$1/' "$parent_dir/"
end
function __bobthefish_start_segment -S -d 'Start a prompt segment'
  set -l bg $argv[1]
  set -e argv[1]
  set -l fg $argv[1]
  set -e argv[1]

  set_color normal # clear out anything bold or underline...
  set_color -b $bg $fg $argv

  switch "$__bobthefish_current_bg"
    case ''
      # If there's no background, just start one
      echo -n ' '
    case "$bg"
      # If the background is already the same color, draw a separator
      echo -ns $right_arrow_glyph ' '
    case '*'
      # otherwise, draw the end of the previous segment and the start of the next
      set_color $__bobthefish_current_bg
      echo -ns $right_black_arrow_glyph ' '
      set_color $fg $argv
  end

  set __bobthefish_current_bg $bg
end

function __bobthefish_finish_segments -S -d 'Close open prompt segments'
  if [ -n "$__bobthefish_current_bg" ]
    set_color normal
    set_color $__bobthefish_current_bg
    echo -ns $right_black_arrow_glyph ' '
  end

  if [ "$theme_newline_cursor" = 'yes' ]
    echo -ens "\n"
    set_color $fish_color_autosuggestion

    if set -q theme_newline_prompt
      echo -ens "$theme_newline_prompt"
    else if [ "$theme_powerline_fonts" = "no" ]
      echo -ns '> '
    else
      echo -ns "$right_arrow_glyph "
    end
  else if [ "$theme_newline_cursor" = 'clean' ]
    echo -ens "\n"
  end

  set_color normal
  set __bobthefish_current_bg
end

function __bobthefish_path_segment -S -a segment_dir -d 'Display a shortened form of a directory'
  set -l segment_color $color_path
  set -l segment_basename_color $color_path_basename

  if not [ -w "$segment_dir" ]
    set segment_color $color_path_nowrite
    set segment_basename_color $color_path_nowrite_basename
  end

  __bobthefish_start_segment $segment_color

  set -l directory
  set -l parent

  switch "$segment_dir"
    case /
      set directory '/'
    case "$HOME"
      set directory '~'
    case '*'
      set parent (__bobthefish_pretty_parent "$segment_dir")
      set directory (__bobthefish_basename "$segment_dir")
  end

  echo -n $parent
  set_color -b $segment_basename_color
  echo -ns $directory ' '
end

function __bobthefish_git_ahead_display -S -a ahead -a behind -d 'Print the ahead/behind state given counts already parsed from `git status --porcelain=v2 --branch`'
  if [ "$theme_display_git_ahead_verbose" = 'yes' ]
    switch "$ahead $behind"
      case '0 0' # equal to upstream (or no upstream)
        return
      case '* 0' # ahead of upstream
        echo "$git_ahead_glyph$ahead"
      case '0 *' # behind upstream
        echo "$git_behind_glyph$behind"
      case '*' # diverged from upstream
        echo "$git_ahead_glyph$ahead$git_behind_glyph$behind"
    end
    return
  end

  if [ "$ahead" -gt 0 -a "$behind" -gt 0 ]
    echo '±'
  else if [ "$ahead" -gt 0 ]
    echo "$git_plus_glyph"
  else if [ "$behind" -gt 0 ]
    echo "$git_minus_glyph"
  end
end

function __bobthefish_git_dirty_verbose -S -d 'Print a more verbose dirty state for the current working tree'
  set -l changes (command git diff --numstat | awk '{ added += $1; removed += $2 } END { print "+" added "/-" removed }')
  or return

  echo "$changes " | string replace -r '(\+0/(-0)?|/-0)' ''
end

function __bobthefish_git_stashed -S -d 'Print the stashed state for the current branch'
  if [ "$theme_display_git_stashed_verbose" = 'yes' ]
    set -l stashed (command git rev-list --walk-reflogs --count refs/stash 2>/dev/null)
    or return

    echo -n "$git_stashed_glyph$stashed"
  else
    command git rev-parse --verify --quiet refs/stash 2>/dev/null
    and echo -n "$git_stashed_glyph"
  end
end

function __bobthefish_prompt_git -S -a git_root_dir -a real_pwd -d 'Display the actual git state'
  set -l branch_head ''
  set -l ahead 0
  set -l behind 0
  set -l has_staged 0
  set -l has_dirty 0
  set -l has_untracked 0

  for line in (command git status --porcelain=v2 --branch --ignore-submodules 2>/dev/null)
    set -l parts (string split ' ' -- $line)
    switch $parts[1]
      case '#'
        switch $parts[2]
          case branch.head
            set branch_head $parts[3]
          case branch.ab
            set ahead (string sub -s 2 -- $parts[3])
            set behind (string sub -s 2 -- $parts[4])
        end
      case 1 2
        [ (string sub -l 1 -- $parts[2]) != '.' ]
        and set has_staged 1
        [ (string sub -l 1 -s 2 -- $parts[2]) != '.' ]
        and set has_dirty 1
      case u
        set has_staged 1
        set has_dirty 1
      case '?'
        set has_untracked 1
    end
  end

  set -l dirty ''
  if [ "$theme_display_git_dirty" != 'no' -a "$has_dirty" = 1 ]
    set dirty "$git_dirty_glyph"
    if [ "$theme_display_git_dirty_verbose" = 'yes' ]
      set dirty "$dirty"(__bobthefish_git_dirty_verbose)
    end
  end

  set -l staged ''
  [ "$has_staged" = 1 ]
  and set staged "$git_staged_glyph"

  set -l stashed (__bobthefish_git_stashed)
  set -l ahead_display (__bobthefish_git_ahead_display $ahead $behind)

  set -l new ''
  [ "$theme_display_git_untracked" != 'no' -a "$has_untracked" = 1 ]
  and set new "$git_untracked_glyph"

  set -l flags "$dirty$staged$stashed$ahead_display$new"

  [ "$flags" ]
  and set flags " $flags"

  set -l flag_colors $color_repo
  if [ "$dirty" ]
    set flag_colors $color_repo_dirty
  else if [ "$staged" ]
    set flag_colors $color_repo_staged
  end

#  __bobthefish_path_segment $git_root_dir

  __bobthefish_start_segment $flag_colors
  echo -ns (__bobthefish_git_branch_display $branch_head) $flags ' '
  set_color normal

  if [ "$theme_git_worktree_support" != 'yes' ]
    set -l project_pwd (__bobthefish_project_pwd $git_root_dir $real_pwd)
    if [ "$project_pwd" ]
      if [ -w "$real_pwd" ]
        __bobthefish_start_segment $color_path
      else
        __bobthefish_start_segment $color_path_nowrite
      end

      echo -ns $project_pwd ' '
    end
    return
  end

  set -l project_pwd (command git rev-parse --show-prefix 2>/dev/null | string trim --right --chars=/)
  set -l work_dir (command git rev-parse --show-toplevel 2>/dev/null)

  # only show work dir if it's a parent…
  if [ "$work_dir" ]
    switch $real_pwd/
      case $work_dir/\*
        string match "$git_root_dir*" $work_dir >/dev/null
        and set work_dir (string sub -s (math 1 + (string length $git_root_dir)) $work_dir)
      case \*
        set -e work_dir
    end
  end

  if [ "$project_pwd" -o "$work_dir" ]
    set -l colors $color_path
    if not [ -w "$real_pwd" ]
      set colors $color_path_nowrite
    end

    __bobthefish_start_segment $colors

    # handle work_dir != project dir
    if [ "$work_dir" ]
      set -l work_parent (__bobthefish_dirname $work_dir)
      if [ "$work_parent" ]
        echo -n "$work_parent/"
      end

      set_color normal
      set_color -b $color_repo_work_tree
      echo -n (__bobthefish_basename $work_dir)

      set_color normal
      set_color -b $colors
      [ "$project_pwd" ]
      and echo -n '/'
    end

    echo -ns $project_pwd ' '
  else
    set project_pwd $real_pwd

    string match "$git_root_dir*" $project_pwd >/dev/null
    and set project_pwd (string sub -s (math 1 + (string length $git_root_dir)) $project_pwd)

    set project_pwd (string trim --left --chars=/ -- $project_pwd)

    if [ "$project_pwd" ]
      set -l colors $color_path
      if not [ -w "$real_pwd" ]
        set colors $color_path_nowrite
      end

      __bobthefish_start_segment $colors

      echo -ns $project_pwd ' '
    end
  end
end


function __bobthefish_git_prompt_cache_defaults -S -d 'Initialize the lazy git-status cache state on first use'
  set -q __git_prompt_cache_root
  or set -g __git_prompt_cache_root ''
  set -q __git_prompt_cache_str
  or set -g __git_prompt_cache_str ''
  set -q __git_prompt_cache_time
  or set -g __git_prompt_cache_time 0
  set -q theme_git_prompt_cache_max_age
  or set -g theme_git_prompt_cache_max_age 10

  # invalidate the cache after any `git ...` command, so the next prompt
  # recomputes instead of waiting out the max-age fallback
  if not functions -q __git_prompt_cache_on_postexec
    function __git_prompt_cache_on_postexec --on-event fish_postexec -d 'Force a git-status recompute after a git command runs'
      string match -qr '^\s*(command\s+)?git\s' -- $argv[1]
      and set -g __git_prompt_cache_time 0
    end
  end
end

function fish_right_prompt -d 'git right prompt'

  set -g theme_display_git yes
  set -g theme_display_git_dirty yes
  set -g theme_display_git_untracked yes
  set -g theme_display_git_ahead_verbose yes
  set -g theme_display_git_dirty_verbose yes
  set -g theme_display_git_stashed_verbose yes
  set -g theme_display_git_master_branch yes

  set -g theme_powerline_fonts no
  set -g theme_nerd_fonts yes

  __bobthefish_glyphs
  __bobthefish_colors $theme_color_scheme

  #echo -n $left_black_arrow_glyph

  # VCS
  __bobthefish_git_prompt_cache_defaults

  set -l root (command git rev-parse --show-toplevel 2>/dev/null)
  if [ -n "$root" ]
    set -l now (date +%s)
    if [ "$root" != "$__git_prompt_cache_root" ]
      or [ (math "$now - $__git_prompt_cache_time") -ge "$theme_git_prompt_cache_max_age" ]
      set -g __git_prompt_cache_str (__bobthefish_prompt_git $root $PWD | string collect)
      set -g __git_prompt_cache_root $root
      set -g __git_prompt_cache_time $now
    end

    echo -n $__git_prompt_cache_str
  else
    set -g __git_prompt_cache_root ''
  end

  #echo -n $left_arrow_glyph
  #__bobthefish_finish_segments
end
