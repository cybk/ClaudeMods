#!/usr/bin/env bash
# Claude Code status line: [TAG] repo · branch* · Model
# Reads the session JSON from stdin. Pure bash builtins + one `git status`. Never fails.

raw=$(cat 2>/dev/null)

# --- JSON helpers (no jq): first string value for a key ---
jstr() { # $1=key  $2=text
  local re="\"$1\"[[:space:]]*:[[:space:]]*\"([^\"]*)\""
  [[ $2 =~ $re ]] && printf '%s' "${BASH_REMATCH[1]}"
}
unesc() { # JSON-escaped Windows path -> forward slashes ("D:\\a\\b" -> "D:/a/b")
  local bs='\' s=$1
  s=${s//"$bs"/\/}; s=${s//\/\//\/}
  printf '%s' "$s"
}

dir=$(unesc "$(jstr current_dir "$raw")")
[[ -n $dir && -d $dir ]] || dir=$(unesc "$(jstr cwd "$raw")")
[[ -n $dir && -d $dir ]] || dir=$PWD
dir=${dir%/}; [[ -z $dir ]] && dir=/

model=""
re='"model"[[:space:]]*:[[:space:]]*\{([^}]*)\}'
if [[ $raw =~ $re ]]; then
  blk=${BASH_REMATCH[1]}
  model=$(jstr display_name "$blk"); [[ -z $model ]] && model=$(jstr id "$blk")
fi

# --- color: deterministic hash -> 256-color palette ---
palette=(39 208 41 171 220 203 45 141 118 213 81 214 99 178 49 205 75 154)
color_of() {
  local s=${1,,} h=7 c i
  for ((i = 0; i < ${#s}; i++)); do
    printf -v c '%d' "'${s:i:1}"
    h=$(( (h * 31 + c) % 2147483647 ))
  done
  printf '%s' "${palette[h % ${#palette[@]}]}"
}
paint() { printf '\033[38;5;%sm%s\033[0m' "$(color_of "$2")" "$1"; } # text, hash-key

# --- walk up: .claude-tag (first found) and repo root (.git dir or file) ---
tag=${CLAUDE_TAG:-}
top="" worktree="" repo=""
d=$dir
while :; do
  if [[ -z $tag && -f $d/.claude-tag ]]; then
    IFS= read -r line < "$d/.claude-tag" 2>/dev/null
    line=${line//$'\r'/}; line=${line#"${line%%[![:space:]]*}"}; line=${line%"${line##*[![:space:]]}"}
    [[ -n $line ]] && tag=$line
  fi
  if [[ -d $d/.git ]]; then top=$d; repo=${d##*/}; break; fi
  if [[ -f $d/.git ]]; then # linked worktree: "gitdir: <repo>/.git/worktrees/<name>"
    top=$d; worktree=${d##*/}
    IFS= read -r gl < "$d/.git" 2>/dev/null
    gl=${gl#gitdir: }; gl=${gl%$'\r'}; gl=${gl//\\//}
    if [[ $gl == */.git/worktrees/* ]]; then g=${gl%/.git/worktrees/*}; repo=${g##*/}; else repo=${d##*/}; fi
    break
  fi
  p=${d%/*}
  [[ $p == "$d" || $d != */* ]] && break
  d=$p
done

[[ -z $repo ]] && repo=${dir##*/}; [[ -z $repo ]] && repo=$dir
if [[ -z $tag ]]; then tag=${dir##*/}; [[ -z $tag ]] && tag=$dir; fi

# --- branch + dirty: a single git call ---
branch="" dirty=""
if [[ -n $top ]]; then
  st=$(GIT_OPTIONAL_LOCKS=0 git -C "$dir" status --porcelain=v1 -b -uno 2>/dev/null) && {
    first=${st%%$'\n'*}
    if [[ $first == '## '* ]]; then
      branch=${first#\#\# }
      branch=${branch#No commits yet on }; branch=${branch#Initial commit on }
      branch=${branch%%...*}; branch=${branch%% \[*}
      [[ $branch == 'HEAD (no branch)'* ]] && branch=$(git -C "$dir" rev-parse --short HEAD 2>/dev/null)
    fi
    [[ $st == *$'\n'* ]] && dirty='*'
  }
fi

# --- render ---
out="$(paint "[${tag^^}]" "$tag") $repo"
[[ -n $worktree ]] && out+=" wt:$worktree"
[[ -n $branch ]] && out+=" · $(paint "$branch$dirty" "$branch")"
[[ -n $model ]] && out+=" · $model"
printf '%s' "$out"
exit 0
