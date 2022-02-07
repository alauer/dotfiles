#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC1090
function git-checkout-latest-tag {
	git fetch --tags
	tag=$(git describe --tags "$(git rev-list --tags --max-count=1)")
	echo "Checking out tag $tag..."
	git checkout "$tag"
}

function upgrade-all {
    sudo apt-get update;
    sudo apt-get upgrade;
    sudo apt-get autoremove;
# shellcheck source=.aliases
    (source "$HOME"/.aliases && pip-upgrade)
#    (cd "$HOME"/.pyenv/ && git -C pull)
    (cd "$HOME"/.oh-my-zsh/custom/themes/powerlevel10k/ && git -C "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/themes/powerlevel10k pull)
}
