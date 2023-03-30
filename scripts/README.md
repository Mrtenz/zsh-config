# Scripts

This folder contains the scripts that I use, mainly for development purposes. Currently, there are three scripts:

- `commit.sh` - This script is used to create clean, descriptive commit messages. It uses OpenAI's GPT-3 to generate a
  commit message based on the changes that you have made.
- `dev.sh` - This script is used to quickly clone a repository and install its dependencies. It will clone repositories
  in the provided folder (`~/Development/<Username>/<Repository>` by default). For example:
  - `dev.sh https://github.com/foo/bar` - Clone `bar` into `~/Development/foo/bar` and install its dependencies.
  - `dev.sh https://github.com/foo/bar/pull/123` - Clone `bar` and check out the pull request with ID `123`.
- `pr.sh` - This script is used to quickly create a pull request. It uses OpenAI's GPT-3 to generate a pull request
  description based on the commits that you have made.

It's recommended to set up an alias for these scripts. See [aliases.zsh](../aliases.zsh) for examples.

## `commit.sh`

This script is used to create clean, descriptive commit messages. It uses OpenAI's GPT-3 to generate a commit message
based on the changes that you have made.

Before the commit is created, you can edit the commit message. The script will open your default editor and display the
commit message.

### Requirements

In addition to basic tooling (e.g., `git`), this script requires the following:

- `OPENAI_TOKEN` must be set. See my [0-secrets.zsh](../0-secrets.zsh) for example.
- `revolver` must be installed. See [revolver](https://github.com/molovo/revolver) for installation instructions.

### Usage

The script does not take any arguments. It uses the current repository and branch to generate a commit message.

```bash
./commit.sh
```

## `dev.sh`

This script is used to quickly clone a repository and install its dependencies. It will clone repositories in the
provided folder (`~/Development/<Username>/<Repository>` by default).

### Requirements

In addition to basic tooling (e.g., `git`), this script requires the following:

- The GitHub CLI must be installed. See [GitHub CLI](https://cli.github.com/) for installation instructions.
- `nvm` must be installed. See [nvm](https://github.com/nvm-sh/nvm) for installation instructions.
- An IDE must be configured in the script. It defaults to `idea`. See [dev.sh](./dev.sh) for details.

### Usage

The script takes one argument: The URL of the repository to clone. It can be a GitHub URL or a `username/repository`
string. Optionally, the URL can include a pull request number. For example:

```bash
./dev.sh foo/bar
./dev.sh https://github.com/foo/bar
./dev.sh https://github.com/foo/bar/pull/123
```

## `pr.sh`

This script is used to quickly create a pull request. It uses OpenAI's GPT-3 to generate a pull request description
based on the commits that you have made. It's recommended to use this script in conjunction with `commit.sh`.

Before the pull request is created, you can edit the pull request description. The script will open your default editor
and display the pull request description.

### Requirements

In addition to basic tooling (e.g., `git`), this script requires the following:

- The GitHub CLI must be installed. See [GitHub CLI](https://cli.github.com/) for installation instructions.
- `OPENAI_TOKEN` must be set. See my [0-secrets.zsh](../0-secrets.zsh) for example.
- `revolver` must be installed. See [revolver](https://github.com/molovo/revolver) for installation instructions.

### Usage

The script does not take any arguments. It uses the current repository and branch to generate a pull request. The
current branch cannot be the `main` branch.

```bash
./pr.sh
```
