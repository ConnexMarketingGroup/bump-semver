#!/bin/bash
# Bumps the semantic version of the git-project.
# If no semantic version tags exist in the project, the version starts out at v0.0.0
# and is incremented by one for the field indicated by the bump command argument.

find_latest_semver() {
  pattern="^$PREFIX([0-9]+\.[0-9]+\.[0-9]+)\$"
  versions=$(for tag in $(git tag); do
    [[ "$tag" =~ $pattern ]] && echo "${BASH_REMATCH[1]}"
  done)
  if [ -z "$versions" ];then
    echo 0.0.0
  else
    echo "$versions" | tr '.' ' ' | sort -nr -k 1 -k 2 -k 3 | tr ' ' '.' | head -1
  fi
}

increment_ver() {
  if [[ $4 == 'major' ]]; then
    find_latest_semver | awk -F. -v a="$1" -v b="$2" -v c="$3" '{printf("%d.%d.%d", $1+a, 0 , 0)}'
  elif [[ $4 == 'minor' ]]; then
    find_latest_semver | awk -F. -v a="$1" -v b="$2" -v c="$3" '{printf("%d.%d.%d", $1+a, $2+b , 0)}'
  elif [[ $4 == 'patch' ]]; then
    find_latest_semver | awk -F. -v a="$1" -v b="$2" -v c="$3" '{printf("%d.%d.%d", $1+a, $2+b , $3+c)}'
  fi
}

bump() {
  next_ver="${PREFIX}$(increment_ver "$1" "$2" "$3" "$4")"
  latest_ver="${PREFIX}$(find_latest_semver)"
  latest_commit=$(git rev-parse "${latest_ver}" 2>/dev/null )
  head_commit=$(git rev-parse HEAD)
  if [ "$latest_commit" = "$head_commit" ]; then
      echo "refusing to tag; $latest_ver already tagged for HEAD ($head_commit)"
  else
      echo "tagging $next_ver $head_commit"
      git tag "$next_ver" "$head_commit"
  fi

  # git push
  if [[ ${PUSH} != 'false' ]]; then
    git push origin "${next_ver}"
  fi
}

usage() {
  echo "Usage: bump [-p prefix] {major|minor|patch} | -l"
  echo "Bumps the semantic version field by one for a git-project."
  echo
  echo "Options:"
  echo "  -l  list the latest tagged version instead of bumping."
  echo "  -p  prefix [to be] used for the semver tags. default prefix: v"
  echo "  -n  disable auto pushing new tag to git repository."
  exit 1
}

while getopts p:ln opt; do
  case $opt in
    p) PREFIX="$OPTARG";;
    l) LIST=1;;
    n) PUSH=false;;
    \?) usage;;
    :) echo "option -$OPTARG requires an argument"; exit 1;;
  esac
done

# set default PREFIX
if [[ ${PREFIX} == '' ]]; then PREFIX="v"; fi

shift $((OPTIND-1))

if [ -n "$LIST" ];then
  find_latest_semver
  exit 0
fi

case $1 in
  major) bump 1 0 0 major;;
  minor) bump 0 1 0 minor;;
  patch) bump 0 0 1 patch;;
  *) usage;;
esac