# chezmoi-dotfiles

Manage your dotfiles across multiple diverse machines, securely.

chezmoi's documentation is at [chezmoi.io](https://chezmoi.io/).

## License

MIT
For MacOs, install Homebrew first.
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

```bash
sh -c "$(curl -fsLS chezmoi.io/get)" -- init https://gitlab.com/alauer/chezmoi-dotfiles.git
```

## Pyenv Commands
https://github.com/pyenv/pyenv/blob/master/COMMANDS.md

## To make dotfiles changes in Chezmoi
```bash
chezmoi git remote set-url origin git@gitlab.com:alauer/chezmoi-dotfiles.git
```
