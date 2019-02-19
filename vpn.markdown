# VPN steup

## OpenVPN setup

[How to Setup and Configure an OpenVPN Server on CentOS 6][openvpn_setup_digitalocean]

0.  add EPEL reporistory

        wget http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
        rpm -Uvh epel-release-6-8.noarch.rpm

1)  install openvpn package

        yum install openvpn -y

2.  copy sample config file

        find /usr/share/doc/openvpn-*/ -name server.conf -exec cp {} /etc/openvpn/ \;

3)  edit config file

        vi /etc/openvpn/server.conf

    uncomment folowing line:

        push "redirect-gateway def1 bypass-dhcp"

    config DNS

        push "dhcp-option DNS 8.8.8.8"
        push "dhcp-option DNS 8.8.4.4"

    uncomment following lines

        user nobody
        group nobody

4)  keys and certificates

        git clone https://github.com/OpenVPN/easy-rsa
        cd easy-rsa
        git checkout origin/release/2.x

        mkdir -p /etc/openvpn/easy-rsa/keys
        cp -rf easy-rsa/2.0/* /etc/openvpn/easy-rsa/
        cd /etc/openvpn/easy-rsa/

    edit `vars`

        export KEY_COUNTRY="US"
        export KEY_PROVINCE="CA"
        export KEY_CITY="SanFrancisco"
        export KEY_ORG="Super Inc."
        export KEY_EMAIL="i@example.com"
        export KEY_OU="MyOrganizationalUnit"

    build ca

        source ./vars
        ./clean-all
        ./build-ca

    create certificate for server

        ./build-key-server server

    generate Diffie Hellman key exchange files

        ./build-dh
        cd keys/
        cp dh2048.pem ca.crt server.crt server.key /etc/openvpn/

    create client certificate

        cd /etc/openvpn/easy-rsa
        ./build-key client

4. client setup

## Other

Check this repo https://github.com/drewsymo/VPN.git

[openvpn_setup_digitalocean]: https://www.digitalocean.com/community/tutorials/how-to-setup-and-configure-an-openvpn-server-on-centos-6
[pptp_vpn_setup]: http://drewsymo.com/2013/11/how-to-install-pptp-vpn-server-on-centos-6-x
