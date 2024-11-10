#! /bin/bash

DOTFILES=(.gitconfig .zshrc)

for dotfile in $(echo ${DOTFILES[*]});
do
    cp ~/desktop/projects/dotfiles/$(echo $dotfile) ~/$(echo $dotfile)
done
