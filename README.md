# How to use buildiso in a Docker container

Why would you want to build ISO images within a Docker container? The primary reason is to ensure determinism
regarding the used 3pp versions or the environment where you build the image files.
For that, I first started to search for a proper Docker base image. What I found on Docker Hub are the
Manjaro base images (manjaro/build, manjaro/base).
I began with the 'build' image because it includes essential components.
After building the image and creating a container using it, follow the official documentation
to start building an ISO file [[2]](https://wiki.manjaro.org/index.php/Build_Manjaro_ISOs_with_buildiso).

## How to try this out

To try out the repo content, just run the following command:

```
bash <(curl -sSL https://raw.githubusercontent.com/SilverTux/manjaro_buildiso_docker/main/run.sh)
```

# Challenges

The following challenges appeared on the road to building ISO files in a Docker container:
  - The container requires either --privileged permissions or the more secure --cap-add=SYS_ADMIN
  - Mounting overlayfs inside the container does not work.
  - Not enough RAM for tmpfs.

## Privileged container

This was needed because of the following errors:

```
==> Creating install root at /var/lib/manjaro-tools/buildiso/xfce/x86_64/rootfs
mount: /var/lib/manjaro-tools/buildiso/xfce/x86_64/rootfs: permission denied.
       dmesg(1) may have more information after failed mount system call.
==> ERROR: failed to setup API filesystems in new root
umount: bad usage
Try 'umount --help' for more information.
==> ERROR: Failed to install all packages
```

The result of the investigation led to a privilege problem because /dev devices
couldn't be reached. So the easiest solution was to use the docker --privileged flag.

## Using the `mount -t overlay` inside the container

Unfortunately it is not possible to mount an overlayfs inside a Docker container because Docker itself
uses the overlayfs driver, so we need a workaround for that [[3]](https://linuxconfig.org/introduction-to-the-overlayfs).
If you have enough RAM, then tmpfs could be a way forward for you [[1]](https://stackoverflow.com/questions/67198603/overlayfs-inside-docker-container).
The only thing you need to do is mount `/var/lib/manjaro-tools/buildiso/xfce` as a tmpfs, like below:

```
mount -t tmpfs tmpfs /var/lib/manjaro-tools/buildiso/xfce
```

If you don't have enough RAM (e.g. you have 8GB or less RAM), this is not a good solution for you.
You have to look for another way forward.

## Use a Docker volume mount instead of a tmpfs mount if you don't have enough RAM.

If you don't have enough RAM, you have to use your disk space somehow.
The easiest way is to use the Docker volume mount mechanism to utilize your disk space
instead of your RAM. 
To do so, just create a tmp directory, e.g. under your home. Modern Linux systems use tmpfs
for `/tmp`, so it won't be a good choice to use a directory under `/tmp` because it has limited free space.

# Solutions

The final solutions to the above-mentioned problems are the following:
  - Create a Dockerfile that contains all the needed dependencies:

```
FROM manjarolinux/build:latest

RUN pacman -S --noconfirm manjaro-tools-iso && \
    yes | pacman -Scc
```

  - Create a script to run a container for building the ISO:

```
#!/usr/bin/env bash

set -euo pipefail

IMAGE=manjaro_buildiso
BUILDISO_TMP_DIR=${HOME}/tmp/buildiso

mkdir -p "${BUILDISO_TMP_DIR}"

docker build -t "${IMAGE}" .

docker run \
    -it \
    --rm \
    --net=host \
    -v ${BUILDISO_TMP_DIR}:/var/lib/manjaro-tools/buildiso/xfce \
    "${IMAGE}" \
    bash
```

Run the script, and after that, you will get a shell inside the container where you can run the following commands:

```
git clone https://gitlab.manjaro.org/profiles-and-settings/iso-profiles.git ~/iso-profiles
cd root/iso-profiles
buildiso -p xfce
```

# Summary

In short, what we needed to be able to build ISO files in containers were:
  - Docker image containing the manjaro-tools-iso dependency
  - run the container with the `-v $HOME/tmp:/var/lib/manjaro-tools/buildiso/xfce` volume mount and `--privileged` flag.
  - Clone the iso-profiles repo inside the container.
  - run the `buildiso -p xfce` command to generate the iso.

## References

[1] https://stackoverflow.com/questions/67198603/overlayfs-inside-docker-container

[2] https://wiki.manjaro.org/index.php/Build_Manjaro_ISOs_with_buildiso

[3] https://linuxconfig.org/introduction-to-the-overlayfs

[4] https://gitlab.manjaro.org/tools/development-tools/manjaro-tools/-/blob/3a5c25c063d9aa795b98495f87a0b109af5b12c0/lib/util-iso-mount.sh#L47
