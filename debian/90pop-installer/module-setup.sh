#!/bin/sh

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst /usr/bin/chmod
    inst /usr/bin/chroot
    inst /usr/bin/ln
    inst_hook pre-pivot 90 "$moddir/pop-installer.sh"
}
