FROM manjarolinux/build:latest

RUN pacman -S --noconfirm manjaro-tools-iso && \
    yes | pacman -Scc
