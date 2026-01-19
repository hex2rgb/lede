- 更改ip
lede/package/base-files/files/bin/config_generate

- https://cdimage.ubuntu.com/releases/22.04/release/
- ubuntu-22.04.5-live-server-arm64
-ubuntu  arm 依赖包
- 参考 https://mach.design/compile-openwrt-with-apple-silicon/
```shell
sudo apt update -y
sudo apt full-upgrade -y
sudo apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
bzip2 ccache cmake cpio curl device-tree-compiler fastjar flex gawk gettext  \
git gperf haveged help2man intltool libelf-dev libfuse-dev libglib2.0-dev libgmp3-dev \
libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5-dev libpython3-dev libreadline-dev \
libssl-dev libtool lrzsz mkisofs msmtp ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 \
python3-pyelftools python3-setuptools qemu-utils rsync scons squashfs-tools subversion swig texinfo \
uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev
```

```shell
sudo apt install gcc-multilib-i686-linux-gnu gcc-multilib-s390x-linux-gnu gcc-multilib-x86-64-linux-gnu gcc-multilib-x86-64-linux-gnux32

sudo apt install g++-multilib-i686-linux-gnu g++-multilib-s390x-linux-gnu g++-multilib-x86-64-linux-gnu g++-multilib-x86-64-linux-gnux32

sudo apt install libc6-dev-i386-amd64-cross libc6-dev-i386-cross libc6-dev-i386-x32-cross
```