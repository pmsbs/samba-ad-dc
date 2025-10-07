#!/bin/bash

read -p "Enter your domain name: " domain
domain_upper=$(echo "$domain" | tr '[:lower:]' '[:upper:]')
realm="${domain_upper%%.*}"
read -s -p "Enter the admin password: " adminpass

# Update system
apt update && apt -y upgrade

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
sudo samba-tool domain provision \
    --domain $domain_upper \
    --realm=$realm \
    --adminpass="$adminpass" \
    --server-role=dc \
    --use-rfc2307 \
    --dns-backend=SAMBA_INTERNAL

# set samba as the DNS backend
unlink /etc/resolv.conf
echo "nameserver 127.0.0.1" >> /etc/resolv.conf
echo "search $domain" >> /etc/resolv.conf

# disable systemd-resolved to avoid conflicts
systemctl disable --now systemd-resolved

# krb5.conf setup
cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf

# start the samba-ad-dc service
systemctl start samba-ad-dc
