#!/bin/env bash

echo "User name:"
read USER
echo "Password:"
read PASSWORD

# Prepare disk
yes | mkfs.ext4 /dev/sda1
mount /dev/sda1 /mnt
yes | mkswap /dev/sda2
swapon /dev/sda2


# sync time:
timedatectl set-ntp true

# update mirrorlist 
pacman -Sy pacman-contrib --noconfirm
echo "--Ranking mirrors--"
# change Arch Linux repo to Indonesia repository
curl -s "https://www.archlinux.org/mirrorlist/?country=ID&protocol=http&use_mirror_status=on" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 6 - > /etc/pacman.d/mirrorlist

pacman -Syy 
pacstrap /mnt $(pacman -Sqg base | sed 's/^linux$/&-zen/') linux-zen-headers base-devel sudo grub os-prober
genfstab -U /mnt >> /mnt/etc/fstab

chroot_actions(){
    
    # locale
    echo 'LANG="en_US.UTF-8"' >> /etc/locale.conf
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
    echo "id_ID.UTF-8 UTF-8" >> /etc/locale.gen
    locale-gen
    ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
    hwclock --systohc

    # hosts
    hostname=nanolab
    echo $hostname > /etc/hostname
    echo "127.0.0.1 localhost.localdomain localhost" > /etc/hosts
    echo "::1       localhost.localdomain localhost" >> /etc/hosts
    echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts

    # users
    user="$1"
    password="$2"
    echo -en "$password\n$password" | passwd
    useradd -m -G wheel,users -s /bin/bash "$user"
    echo -en "$password\n$password" | passwd "$user"
    echo 'root ALL=(ALL) ALL' > /etc/sudoers
    echo '%wheel ALL=(ALL) ALL' >> /etc/sudoers

   # coding
    pacman -S git --noconfirm
    pacman -S python python2 --noconfirm

    # xorg - hardware
    pacman -S xorg-server xorg-apps xorg-xinit xorg-xkill xorg-xinput --noconfirm
    pacman -S xf86-input-libinput --noconfirm
    pacman -S xf86-input-synaptics --noconfirm
    pacman -S xf86-video-intel --noconfirm
    pacman -S acpi --noconfirm
    pacman -S tlp  tlp-rdw --noconfirm
    systemctl enable tlp.service
    systemctl enable tlp-sleep.service
    systemctl mask systemd-rfkill.service
    systemctl mask systemd-rfkill.socket

    #  UI
    pacman -S gvfs gvfs-smb gvfs-mtp polkit-gnome --noconfirm
    pacman -S xdg-user-dirs --noconfirm
    pacman -S bspwm sxhkd --noconfirm
    pacman -S rofi --noconfirm
    
    # login manager
    pacman -S lightdm --noconfirm
    pacman -S lightdm-gtk-greeter --noconfirm
    systemctl enable lightdm
	
    # system
    pacman -S rxvt-unicode --noconfirm
    pacman -S xterm --noconfirm
    pacman -S ntp --noconfirm
    systemctl enable ntpd.service
    #pacman -S openssh --noconfirm
    #systemctl enable sshd.service

    # network
    systemctl enable dhcpcd.service
    pacman -S dialog --noconfirm
    pacman -S wpa_supplicant --noconfirm
    pacman -S wpa_actiond --noconfirm
    pacman -S wireless_tools --noconfirm
    pacman -S broadcom-wl-dkms --noconfirm
    pacman -S networkmanager --noconfirm
    systemctl enable NetworkManager.service

    # sound
    pacman -S pulseaudio --noconfirm
    pacman -S pulseaudio-alsa --noconfirm
    pacman -S alsa-utils --noconfirm
    pacman -S pulseaudio-bluetooth --noconfirm

    # files - ranger
    pacman -S ranger --noconfirm 
    pacman -S p7zip --noconfirm
    pacman -S tar --noconfirm
    pacman -S unrar --noconfirm
    pacman -S unzip --noconfirm
    pacman -S zip --noconfirm
    pacman -S w3m --noconfirm
    pacman -S ntfs-3g --noconfirm
    pacman -S pcmanfm --noconfirm

    # office
    pacman -S imagemagick --noconfirm
    pacman -S zathura zathura-pdf-mupdf --noconfirm

    # internet
    pacman -S curl --noconfirm
    pacman -S wget --noconfirm
  
    # multimedia
    pacman -S feh --noconfirm
    pacman -S mpd --noconfirm
    pacman -S mpc --noconfirm
    pacman -S mpv --noconfirm
    pacman -S ncmpcpp --noconfirm

    # extra
    pacman -S compton --noconfirm
    pacman -S dunst --noconfirm
    pacman -S python-pywal python-setuptools --noconfirm
    pacman -S zsh --noconfirm
    chsh -s /usr/bin/zsh
	
    # Install yay
    echo "[spooky_aur]" >> /etc/pacman.conf
    echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf
    echo "Server = https://raw.github.com/spookykidmm/spooky_aur/master/x86_64" >> /etc/pacman.conf
    pacman -Syy
    pacman -S yay --noconfirm

    # Install yay
    echo "[herecura]" >> /etc/pacman.conf
    echo "Server = https://repo.herecura.be/herecura/$arch" >> /etc/pacman.conf
    pacman -Syy
    pacman -S vivaldi-snapshot vivaldi-snapshot-ffmpeg-codecs --noconfirm

    # grub
    grub-install --recheck --target=i386-pc /dev/sda
    grub-mkconfig -o /boot/grub/grub.cfg

    user_actions(){
        chsh -s /usr/bin/zsh $user
    }
    export -f user_actions
    su "$user" -c "bash -c user_actions"
}

export -f chroot_actions
arch-chroot /mnt /bin/bash -c "chroot_actions $USER $PASSWORD"


echo "Press any key to reboot."
read pause
umount -R /mnt
reboot
