# chezmoi-dotfiles

Manage your dotfiles across multiple diverse machines, securely.

chezmoi's documentation is at [chezmoi.io](https://chezmoi.io/).

## License

MIT

## Setup
[Bitwarden vault config](https://dev.to/jmc265/using-bitwarden-and-chezmoi-to-manage-ssh-keys-5hfm)

```bash
sudo apt install npm
sudo npm install -g @bitwarden/cli
bw login <EMAIL-ADDRESS>
bw unlock
export BW_SESSION="<SESSION-ID>"
```

```bash
sh -c "$(curl -fsLS chezmoi.io/get)" -- init --apply https://gitlab.com/alauer/chezmoi-dotfiles.git
```
## Pyenv Commands
https://github.com/pyenv/pyenv/blob/master/COMMANDS.md
