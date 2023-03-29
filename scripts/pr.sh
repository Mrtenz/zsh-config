#!/usr/bin/env zsh

API_URL="https://api.openai.com/v1/chat/completions"

# Check if token is set.
if [[ ! -v OPENAI_TOKEN ]]; then
  echo "OPENAI_TOKEN is not set"
  exit 1
fi

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

  ## Title

  A title for the pull request

  ## Description

  A description of the change.

  ## Why is this change necessary?

  A description of why this change is necessary."

  example_log="commit 0d5fd751d462debf66982fb4a54b9746e5784125
Author: Maarten Zuidhoorn <maarten@zuidhoorn.com>
Date:   Wed Mar 29 20:10:22 2023 +0200

    Rename .env to .env.example

    This change renames \`.env\` to \`.env.example\` to indicate that it is an example file and not to be used in
    production."

  example_description="## Title

Rename \`.env\` to \`.env.example\`

## Description

This pull request renames the \`.env\` file to \`.env.example\` in order to make it clear that it is just an example
file meant for development purpose only. This change has been made as a part of a best practice review for our project.

## Why is this change necessary?

Currently the \`.env\` file contains sensitive information such as database credentials, API keys, and other secrets.
Such files could be mistakenly committed to the repository or transferred to others by email or other forms, which could
result in a security breach. By renaming it to \`.env.example\` and removing sensitive information from it, we ensure
that the development team is reminded that they should not use the file in production environments or expose it
publicly.

This change is important to maintain the security of our project and protect against potential vulnerabilities."

  json=$(echo "$json" | jq --arg format "$format" --arg example_log "$example_log" --arg example_description "$example_description" --arg log "$GIT_LOG" '.messages += [{"role": "system", "content": $format}, {"role": "user", "content": $example_log}, {"role": "assistant", "content": $example_description}, {"role": "user", "content": $log}]')

  response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $OPENAI_TOKEN" -d "$json" "$API_URL")
  message=$(jq -r '.choices[0].message.content' <<< "$response")

  echo "$message"
}

create_pr() {
  message=$(get_message)

  title=$(echo "$message" | sed -n '/## Title/,/## Description/p' | sed '1d;$d' | xargs)
  body=$(echo "$message" | grep -A 1000 "## Description")

  echo "# $title"
  echo "\n$body"

  while true; do
    printf "Create pull request? (y/n)"
    read yn
    case $yn in
      [Yy]* ) gh pr create --title "$title" --body "$body"; break;;
      [Nn]* ) break;;
      * ) echo "Please answer yes or no.";;
    esac
  done
}

create_pr
