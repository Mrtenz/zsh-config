#!/usr/bin/env zsh

API_URL="https://api.openai.com/v1/chat/completions"

# Check if token is set.
if [[ ! -v OPENAI_TOKEN ]]; then
  echo "OPENAI_TOKEN is not set"
  exit 1
fi

clean_up() {
  tput cnorm
}

trap clean_up EXIT

tput civis
revolver start "Fetching Git information..."

GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
GIT_REMOTE=$(git remote)
GIT_MAIN_BRANCH=$(git remote show "$GIT_REMOTE" | sed -n '/HEAD branch/s/.*: //p')
GIT_LOG=$(git --no-pager log $(git merge-base "$GIT_MAIN_BRANCH" "$GIT_BRANCH")..HEAD)

if [[ "$GIT_MAIN_BRANCH" == "$GIT_BRANCH" ]]; then
  echo "Cannot create a pull request from the main branch"
  exit 1
fi

if [[ -z "$GIT_LOG" ]]; then
  echo "No new commits on this branch"
  exit 1
fi

get_message() {
  json='{
    "model": "gpt-3.5-turbo",
    "messages": []
  }'

  format="You are to act as the author of a pull request on GitHub. Your mission is to create clean and comprehensive
pull request descriptions, and explain why a change was done. I'll send you an output of 'git log' command, and you
convert it into a pull request description, based on a summary of all commits. Write a title for the pull request on
the first line, and a description on the following lines. You can use the following template as a starting point:

# A title for the pull request

## Description

A description of the change.

## Changes

1. A numeric list of changes made in this pull request."

  example_log="commit 0d5fd751d462debf66982fb4a54b9746e5784125
Author: Maarten Zuidhoorn <maarten@zuidhoorn.com>
Date:   Wed Mar 29 20:10:22 2023 +0200

    Rename .env to .env.example

    This change renames \`.env\` to \`.env.example\` to indicate that it is an example file and not to be used in
    production."

  example_description="# Rename \`.env\` to \`.env.example\`

## Description

This pull request renames the \`.env\` file to \`.env.example\` in order to make it clear that it is just an example
file meant for development purpose only. This change has been made as a part of a best practice review for our project.

Currently the \`.env\` file contains sensitive information such as database credentials, API keys, and other secrets.
Such files could be mistakenly committed to the repository or transferred to others by email or other forms, which could
result in a security breach. By renaming it to \`.env.example\` and removing sensitive information from it, we ensure
that the development team is reminded that they should not use the file in production environments or expose it
publicly.

This change is important to maintain the security of our project and protect against potential vulnerabilities.

## Changes

1. Rename \`.env\` to \`.env.example\`.
2. Remove sensitive information from \`.env.example\`."

  json=$(echo "$json" | jq --arg format "$format" --arg example_log "$example_log" --arg example_description "$example_description" --arg log "$GIT_LOG" '.messages += [{"role": "system", "content": $format}, {"role": "user", "content": $example_log}, {"role": "assistant", "content": $example_description}, {"role": "user", "content": $log}]')

  response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $OPENAI_TOKEN" -d "$json" "$API_URL")
  message=$(jq -r '.choices[0].message.content' <<< "$response")

  echo "$message"
}

# Edit file with the editor.
edit_file() {
  file="$1"
  contents="$2"

  echo "$contents" > "$file"
  open -tn --wait-apps "$file"
}

create_pr() {
  revolver update "Generating pull request description..."

  message=$(get_message)

  revolver update "Waiting for editor to close..."

  file=$(mktemp)
  edit_file "$file" "$message"
  message="$(cat "$file")"

  revolver stop
  tput cnorm

  title=$(echo "$message" | head -n 1 | sed 's/# //')
  body=$(echo "$message" | tail -n +3)

  echo "# $title"
  echo ""
  echo "$body"

  while true; do
    printf "Commit? ([y]es/[n]o/[r]etry)"
    read yn
    case $yn in
      [Yy]* ) break;;
      [Nn]* ) exit 0;;
      [Rr]* ) create_pr; break;;
      * ) echo "Please answer [y]es, [n]o, or [r]etry.";;
    esac
  done

  gh pr create --title "$title" --body "$body";
}

create_pr
