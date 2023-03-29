#!/usr/bin/env zsh

API_URL="https://api.openai.com/v1/chat/completions"

# Check if token is set.
if [[ ! -v OPENAI_TOKEN ]]; then
  echo "OPENAI_TOKEN is not set"
  exit 1
fi

# Check if any tracked files have changed.
if [[ -z $(git diff-index HEAD --name-only) ]]; then
  echo "No changes to tracked files"
  exit 1
fi

# Inspired by OpenCommit.
# https://github.com/di-sukharev/opencommit
get_message() {
  json='{
    "model": "gpt-3.5-turbo",
    "messages": []
}'

  format="You are to act as the author of a commit message in git. Your mission is to create clean and comprehensive
commit messages, and explain why a change was done. I'll send you an output of 'git diff' command, and you
convert it into a commit message. Use the present tense. Lines must not be longer than 72 characters. Use the following
template:

Summarize changes in around 50 characters or less, using a single sentence

More detailed explanatory text, if necessary. Wrap it to about 72
characters or so. In some contexts, the first line is treated as the
subject of the commit and the rest of the text as the body. The
blank line separating the summary from the body is critical (unless
you omit the body entirely); various tools like \`log\`, \`shortlog\`
and \`rebase\` can get confused if you run the two together.

Explain the problem that this commit is solving. Focus on why you
are making this change as opposed to how (the code explains that).
Are there side effects or other unintuitive consequences of this
change? Here's the place to explain them.

Further paragraphs come after blank lines.

- Bullet points are okay, too"

  example_diff="diff --git a/src/server.ts b/src/server.ts
index ad4db42..f3b18a9 100644
--- a/src/server.ts
+++ b/src/server.ts
@@ -10,7 +10,7 @@
import {
  initWinstonLogger();

  const app = express();
 -const port = 7799;
 +const PORT = 7799;

  app.use(express.json());

@@ -34,6 +34,6 @@
app.use((_, res, next) => {
  // ROUTES
  app.use(PROTECTED_ROUTER_URL, protectedRouter);

 -app.listen(port, () => {
 -  console.log(\`Server listening on port \${port}\`);
 +app.listen(process.env.PORT || PORT, () => {
 +  console.log(\`Server listening on port \${PORT}\`);
  });"

  example_reply="Change port variable case from lowercase port to uppercase PORT

The port variable is a constant, so it should be in uppercase."

  diff="$(git diff HEAD)"
  json=$(echo "$json" | jq --arg format "$format" --arg example_diff "$example_diff" --arg example_reply "$example_reply" --arg diff "$diff" '.messages += [{"role": "system", "content": $format}, {"role": "user", "content": $example_diff}, {"role": "assistant", "content": $example_reply}, {"role": "user", "content": $diff}]')

  response=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $OPENAI_TOKEN" -d "$json" "$API_URL")
  message=$(jq -r '.choices[0].message.content' <<< "$response")

  echo "$message"
}

# Create a commit with the message from OpenAI.
create_commit() {
  message="$(get_message)"

  echo "$message"

  while true; do
    printf "Commit? (y/n)"
    read yn
    case $yn in
      [Yy]* ) git commit -am "$message"; break;;
      [Nn]* ) break;;
      * ) echo "Please answer yes or no.";;
    esac
  done
}

create_commit
