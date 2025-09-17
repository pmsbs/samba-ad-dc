#!/bin/bash

# install necessary packages
sudo apt install -y samba-ad-dc krb5-user bind9-dnsutils

# disable unnecessary services
sudo systemctl disable --now smbd nmbd winbind
sudo systemctl mask smbd nmbd winbind

# enable and unmask samba-ad-dc service
sudo systemctl unmask samba-ad-dc
sudo systemctl enable samba-ad-dc

# backup original smb.conf
sudo mv /etc/samba/smb.conf /etc/samba/smb.conf.orig

# provision the samba AD DC
sudo samba-tool domain provision --use-rfc2307 --interactive

# set samba as the DNS backend
domain=$(sudo samba-tool domain info | grep 'Domain Name' | awk '{print $3}')
sudo unlink /etc/resolv.conf
sudo echo "nameserver 127.0.0.1" >> /etc/resolv.conf
sudo echo "search $domain" >> /etc/resolv.conf


# disable systemd-resolved to avoid conflicts
sudo systemctl disable --now systemd-resolved

# krb5.conf setup
sudo cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf

# start the samba-ad-dc service
sudo systemctl start samba-ad-dc
