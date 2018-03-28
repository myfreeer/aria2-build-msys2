## Readme
aria2 build scripts for `msys2` with custom patches.

### Build Status
[![Build status](https://ci.appveyor.com/api/projects/status/fndjci8g5f71gf6l?svg=true)](https://ci.appveyor.com/project/myfreeer/aria2-build-msys2)

### License
[![GitHub license](https://img.shields.io/github/license/myfreeer/aria2-build-msys2.svg)](LICENSE) 

### Changes
* option `max-connection-per-server`: change maximum value to `*`, default value to `16`
* option `min-split-size`: change minimum value to `1K`, default value to `1M`
* option `piece-length`: change minimum value to `1K`, default value to `1M`
* option `connect-timeout`: change default value to `30`
* option `split`: change default value to `128`
* option `continue`: change default value to `true`
* option `retry-wait`: change default value to `1`
* option `max-concurrent-downloads`: change default value to `16`
* option `netrc-path` `conf-path` `dht-file-path` `dht-file-path6`: change default value to sub-folder of current directory
* option `deamon`: make use of it on mingw
* download: retry on slow speed and connection close

### Environment 
[MSYS2](http://www.msys2.org/)
Should be set up with commands below:
```sh
pacman -Syyuu --noconfirm
pacman -Su --noconfirm
pacman -S --noconfirm --needed base-devel zlib-devel sqlite git unzip zip tar gmp gmp-devel libssh2 libssh2-devel openssl-devel
```

### Artifacts
* x86_64 (64-bits) version: [![aria2c.7z](https://img.shields.io/badge/download-aria2c.7z-brightgreen.svg)](https://ci.appveyor.com/api/projects/myfreeer/aria2-build-msys2/artifacts/aria2c.7z)
* x86 (32-bits) version: [![aria2c_x86.7z](https://img.shields.io/badge/download-aria2c_x86.7z-brightgreen.svg)](https://ci.appveyor.com/api/projects/myfreeer/aria2-build-msys2/artifacts/aria2c_x86.7z)

### Credits
* https://github.com/aria2/aria2
* https://gist.github.com/zhangyubaka/fb56f6bf9be50dbd28e64809cdc659be
* https://github.com/jb-alvarado/media-autobuild_suite
