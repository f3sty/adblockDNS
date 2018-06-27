Quick-Start Installation Steps
===============================

These are the rough steps for a debian-like system
running bind 9.

1) Checkout repo:
 $ git clone https://github.com/f3sty/adblockDNS.git
 $ cd adblockDNS

2) Create Mysql database and dbuser:
 $ sudo ./install_db.sh 

3) Install files:
 $ sudo mkdir -p /etc/bind/adblockDNS
 $ sudo cp null.zone.file /etc/bind/adblockDNS 
 
4) Populate the db:
 $ ./updateblockDB.pl --fetch

5) Create an empty bind blocklist conf:
 $ sudo touch /etc/bind/adblockDNS/blocked_domains.conf
 
6) Include blocklist in bind's config:
 $ sudo echo "include /etc/bind/adblockDNS/blocked_domains.conf" >>/etc/bind/named.conf.local
 (for RHEL: sudo echo "include /etc/bind/adblockDNS/blocked_domains.conf" >>/etc/named.conf )

7) Generate the blocklist and reload bind:
 $ sudo ./generate_blocklist.pl

