#!/bin/bash

# install necessary packages
apt install -y samba-ad-dc krb5-user bind9-dnsutils

# disable unnecessary services
systemctl disable --now smbd nmbd winbind
systemctl mask smbd nmbd winbind

# enable and unmask samba-ad-dc service
systemctl unmask samba-ad-dc
systemctl enable samba-ad-dc

# backup original smb.conf
mv /etc/samba/smb.conf /etc/samba/smb.conf.orig

# provision the samba AD DC
samba-tool domain provision --use-rfc2307 --interactive

# set samba as the DNS backend
domain=$(samba-tool domain info 127.0.0.1 | grep 'Domain' | awk '{print $3}')
unlink /etc/resolv.conf
echo "nameserver 127.0.0.1" >> /etc/resolv.conf
echo "search $domain" >> /etc/resolv.conf

# disable systemd-resolved to avoid conflicts
systemctl disable --now systemd-resolved

# krb5.conf setup
cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf

# start the samba-ad-dc service
systemctl start samba-ad-dc
