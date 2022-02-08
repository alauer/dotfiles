# chezmoi-dotfiles

# ![chezmoi logo](https://github.com/twpayne/chezmoi/blob/master/logo-144px.svg) chezmoi

[![GitHub Release](https://img.shields.io/github/release/twpayne/chezmoi.svg)](https://github.com/twpayne/chezmoi/releases)

Manage your dotfiles across multiple diverse machines, securely.

chezmoi's documentation is at [chezmoi.io](https://chezmoi.io/).

## License

MIT

## Setup
[Bitwarden vault config](https://dev.to/jmc265/using-bitwarden-and-chezmoi-to-manage-ssh-keys-5hfm)

```bash
sudo snap install bw
bw login <EMAIL-ADDRESS>
bw unlock
export BW_SESSION="<SESSION-ID>"
sh -c "$(curl -fsLS chezmoi.io/get)" -- init --apply https://gitlab.com/alauer/chezmoi-dotfiles.git
```
