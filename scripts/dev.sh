#!/usr/bin/env zsh

# To create an alias for the script, use:
# alias dev="source /path/to/dev.sh"
#
# Then you can use it as follows:
# dev user/repo
# dev https://github.com/user/repo
# dev https://github.com/user/repo/pull/123

# The command to run to start the IDE
# Modify this line if you use another IDE
ide="idea"

# The folder to use for cloning the Git repository
target_folder="$HOME/Development"

show_usage () {
  echo "usage: $ZSH_ARGZERO [repository]"
}

clone () {
  git_repo="$1/$2"
  
  # Where the repository will be cloned
  output="$target_folder/$git_repo"

  # Clone repo if it doesn't exist
  if [[ ! -d "$output" ]]
  then
    gh repo clone "$git_repo" "$output"
  fi

  # Go to local folder
  cd "$output" || exit
}

setup () {
  # Opens the IDE
  "$ide" "$output" &
  
  # Use Node version if .nvmrc exists
  if [[ -f ".nvmrc" ]]
  then
    nvm install
  fi

  # Install dependencies with yarn
  yarn
}

if [[ -z "$1" ]]
then
  show_usage
  exit 1
fi

if [[ "$1" =~ "^https:\/\/github\.com\/(.+)\/(.+)\/pull\/([0-9]+).+$" ]]
then
  clone "${match[1]}" "${match[2]}"
  gh pr checkout "${match[3]}"
elif [[ "$1" =~ "^https://github\.com/(.+)/(.+)" ]]
then
  clone "${match[1]}" "${match[2]}"
elif [[ "$1" =~ "^(.+)/(.+)$" ]]
then
  clone "${match[1]}" "${match[2]}"
else
  show_usage
  exit 1
fi

setup

