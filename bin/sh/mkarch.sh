#!/usr/bin/env bash

# Privileges test
[ ${UID} -ne 0 ] && echo "Error: only root can use this script" && exit 1

# Setup defaults
CURRARCH=$(uname -m)
PRGNAME="${0}"
ROOTDIR="/opt/arch32"
TARGETARCH="i686"
TMPDIR=$(mktemp -d --tmpdir="/dev/shm" "mkarch-XXXXXXXXXX")

usage() {
    cat << EOF
usage: $(basename ${PRGNAME}) [-a i686|x86_64] [-b FILE] [-g] [-h] [-p list] [-r DEVICE|PATH]
    -a --arch   - target architecture (i686)
    -b --backup - archive with settings (none)
    -g --grub   - install bootloader (disabled)
    -h --help   - show this message
    -p --pkgset - space separated list of packages to install. Defaults are:
                      filesystem bash sed coreutils gzip - for bundled installation,
                      base                               - for everything else.
    -r --root   - installation root block device partition or premounted folder (/opt/arch32)
EOF
}

parse_args() {
    while [ ${#} -ne 0 ]; do
        case ${1} in
            -a|--arch)
                shift
                [ -z "${1}" ] && echo "Error: installation architecture not specified" && usage && exit 1
                case "${1}" in
                    i686)
                        TARGETARCH="${1}"
                        ;;
                    x86_64)
                        case ${CURRARCH} in
                            i?86)
                                echo "Error: '${1}' installation from '${CURRARCH}' is currently not supported"
                                exit 1
                                ;;
                            x86_64)
                                TARGETARCH="${1}"
                                ;;
                            *)
                                echo "Error: installation from '${CURRARCH}' is currently not supported"
                                ;;
                        esac
                        ;;
                    *)
                        echo "Error: unsupported target architecture '${1}'"
                        usage
                        exit 1
                        ;;
                esac
                ;;
            -b|--backup)
                shift
                [ -z "${1}" ] && echo "Error: backup archive not specified" && usage && exit 1
                case ${1} in
                    -*)
                        echo "Error: backup option need argument" && usage && exit 1
                        ;;
                    *)
                        BACKUP="${1}"
                        [ ! -f "${BACKUP}" ] && echo "Error: backup file '${BACKUP}' not exists" && exit 1
                        ;;
                esac
                ;;
            -g|--grub)
                GRUBINST="true"
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            -p|--pkgset)
                shift
                [ -z "${1}" ] && echo "Error: installation packages set not specified" && usage && exit 1
                while [ ! -z "${1}" ]; do
                    case "${1}" in
                        -*)
                            [ -z "${PKGSET}" ] && echo "Error: installation packages set option need argument" && usage && exit 1
                            ;;
                        *)
                            PKGSET="${PKGSET} ${1}"
                            ;;
                    esac
                    # Look ahead
                    case "${2}" in
                        -*)
                            break;
                            ;;
                        *)
                            ;;
                    esac
                    shift
                done
                ;;
            -r|--root)
                shift
                [ -z "${1}" ] && echo "Error: installation root not specified" && usage && exit 1
                case "${1}" in
                    -*)
                        echo "Error: root option need argument" && usage && exit 1
                        ;;
                    *)
                        if [ -b "${1}" ]; then
                            ROOTPAR="${1}"
                            ROOTDIR=$(grep -m 1 "${ROOTPAR} " /proc/mounts | cut -f 2 -d " ")
                        else
                            ROOTDIR="${1}"
                            ROOTPAR=$(grep -m 1 " ${ROOTDIR} " /proc/mounts | cut -f 1 -d " ")
                        fi
                        ;;
                esac
                ;;
            *)
                echo "Error: unknown option '${1}'" && usage && exit 1
                ;;
        esac
        shift
    done

    if [ ! -z "${ROOTPAR}" ]; then
        [ -z "${ROOTDIR}" ] && NEEDMOUNT="true" && ROOTDIR="${TMPDIR}/rootfs"
        ROOTDEV=$(echo ${ROOTPAR} | grep -oE '[^0-9]*')
        ROOTNUM=$(echo "${ROOTPAR}" | grep -oE '[0-9]*')
        [ -z "${ROOTNUM}" ] && echo "Error: expected disk partition, not entry disk '${1}'" && usage && exit 1
        GRUBROOT="(hd0,$((ROOTNUM-1)))"
        UUID=$(blkid -s UUID -o value ${ROOTPAR})
    fi

    if [ -z "${PKGSET}" ]; then
        [ -z "${ROOTPAR}" ] && PKGSET="filesystem bash sed coreutils gzip" || PKGSET="base"
    fi
}

mount_pseudo_fs() {
    mkdir -p "${ROOTDIR}/proc" && mount -obind /proc "${ROOTDIR}/proc"
    mkdir -p "${ROOTDIR}/dev" && mount -orbind /dev "${ROOTDIR}/dev"
    mkdir -p "${ROOTDIR}/sys" && mount -obind /sys "${ROOTDIR}/sys"
}

umount_pseudo_fs() {
    umount "${ROOTDIR}/dev/pts"
    umount "${ROOTDIR}/dev/shm"
    umount "${ROOTDIR}/dev"
    umount "${ROOTDIR}/proc"
    umount "${ROOTDIR}/sys"
}

mount_root_fs() {
    mkdir -p "${ROOTDIR}" && [ ! -z "${NEEDMOUNT}" ] && mount "${ROOTPAR}" "${ROOTDIR}"
}

umount_root_fs() {
    [ ! -z "${_TMP_}" ] && umount "${ROOTPAR}" && rm -r "${ROOTDIR}"
}

pre_install() {
    mount_root_fs
    mount_pseudo_fs

    # Prepare mirror list
    MIRRORLIST="${TMPDIR}/pacman.d/mirrorlist"
    mkdir -p $(dirname "${MIRRORLIST}")
    case "${TARGETARCH}" in
        i?86)
            sed -e 's/x86_64/i686/g' /etc/pacman.d/mirrorlist > "${MIRRORLIST}"
            ;;
        x86_64)
            sed -e 's/i686/x86_64/g' /etc/pacman.d/mirrorlist > "${MIRRORLIST}"
            ;;
    esac

    # Prepare pacman.conf
    PACMANCONF="${TMPDIR}/pacman.d/pacman.conf"
    mkdir -p $(dirname "${PACMANCONF}")
    sed -e 's@/etc/pacman.d/mirrorlist@${MIRRORLIST}@g' /etc/pacman.conf > "${PACMANCONF}"
}

post_install() {
    cleanup

    # Make initrd images for real installations only
    if [ ! -z "${ROOTPAR}" ]; then
        # Add usb hook to mkinitcpio.conf
        sed -ri 's/^HOOKS="(.*)"${/HOOKS}="\1 usb"/g' "${ROOTDIR}/etc/mkinitcpio.conf"
        chroot "${ROOTDIR}" mkinitcpio -p kernel26
        if [ ${?} -ne 0 ]; then
            umount_pseudo_fs
            umount_root_fs
            exit 1
        fi
    fi

    umount_pseudo_fs

    # Fix default devices
    ( cd "${ROOTDIR}/dev" && \
        rm -f console &&  mknod -m 600 console c 5 1 && \
        rm -f null &&  mknod -m 666 null c 1 3 && \
        rm -f zero &&  mknod -m 666 zero c 1 5
    )

    # Update configuration from backup
    [ ! -z "${BACKUP}" ] && tar xvf "${BACKUP}" -C "${ROOTDIR}"

    # Skip post-install actions for bundled installations
    if [ ! -z "${ROOTPAR}" ]; then
        # Update fstab
        cat << EOF > ${ROOTDIR}/etc/fstab
devpts                                    /dev/pts    devpts    defaults            0  0
shm                                       /dev/shm    tmpfs     nodev,nosuid        0  0
UUID=${UUID} /           auto      defaults            0  1
EOF
        # Install GRUB
        if [ ! -z "${GRUBINST}" ]; then
            # Install GRUB
            cp -f ${ROOTDIR}/usr/lib/grub/i386-pc/* ${ROOTDIR}/boot/grub
            grub --batch --no-floppy --device-map=/dev/null << EOF
device (hd0) ${ROOTDEV}
root ${GRUBROOT}
setup (hd0)
quit
EOF
            cat << EOF > ${ROOTDIR}/boot/grub/menu.lst
timeout   3
default   0
color light-blue/black light-cyan/blue

title  Arch Linux Live
root   ${GRUBROOT}
kernel /boot/vmlinuz26 root=/dev/disk/by-uuid/${UUID} quiet ro
initrd /boot/kernel26.img

title  Arch Linux Live (fallback)
root   ${GRUBROOT}
kernel /boot/vmlinuz26 root=/dev/disk/by-uuid/${UUID} ro vga=normal single
initrd /boot/kernel26-fallback.img
EOF
        fi
    fi

    umount_root_fs
}

install_arch() {
    parse_args "$@"
    print_debug
    pre_install

    # Create pacman folders
    mkdir -p "${ROOTDIR}"/var/{cache/pacman/pkg,lib/pacman}
    if [ ${?} -ne 0 ]; then
        umount_pseudo_fs
        umount_root_fs
        cleanup
        exit 1
    fi

    # Packages installation
    pacman --arch "${TARGETARCH}" --noconfirm --root "${ROOTDIR}" \
           --cachedir "${ROOTDIR}/var/cache/pacman/pkg" \
           --config /tmp/pacman.conf -Sy ${PKGSET}
    if [ $? -ne 0 ]; then
        umount_pseudo_fs
        umount_root_fs
        cleanup
        exit 1
    fi

    post_install
}

print_debug() {
    echo -n "Installation type     : "
    [ -z "${ROOTPAR}" ] && echo "bundled" || echo "normal"
    echo "Current ARCH          : ${CURRARCH}"
    echo "Target ARCH           : ${TARGETARCH}"
    echo "Backup file           : ${BACKUP:-(none)}"
    echo "Grub install          : ${GRUBINST:-false}"
    echo "Grub root             : ${GRUBROOT:-(none)}"
    echo "Packages set          : ${PKGSET}"
    echo "Root device           : ${ROOTDEV:-(none)}"
    echo "Root folder           : ${ROOTDIR:-(none)}"
    echo "Root partition        : ${ROOTPAR:-(none)}"
    echo "Root partition number : ${ROOTNUM:-(none)}"
    echo "Root partition UUID   : ${UUID:-(none)}"
    echo
    echo "Press 'Enter' to continue or 'CTRL-C' to abort..." && read
}

install_arch "$@"
