# chezmoi-dotfiles

Manage your dotfiles across multiple diverse machines, securely.

chezmoi's documentation is at [chezmoi.io](https://chezmoi.io/).

## License

MIT
For Windows and WSL, install [Scoop](https://scoop.sh/#/)
```Powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

scoop install git

scoop bucket add nerd-fonts
scoop install nerd-fonts/Meslo-NF
scoop bucket add extras
scoop install extras/vscode
```


For MacOs, install Homebrew first.
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

```bash
echo insecure > $HOME/.curlrc;export PATH=$HOME/bin:$PATH;sh -c "$(curl -fsLS chezmoi.io/get)" -- -b $HOME/bin init --apply https://github.com/alauer/dotfiles.git
```

## Pyenv Commands
https://github.com/pyenv/pyenv/blob/master/COMMANDS.md

## To make dotfiles changes in Chezmoi
```bash
chezmoi git remote set-url origin git@github.com:alauer/dotfiles.git
```
