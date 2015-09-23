# phillips321
auto pentest script

So I’ve been using my bt5-nmap.sh script for a few years to quickly gather data whilst on a pentest. The main issue with the old way this script worked was it was not easy to continue a session half way through or to modify the number of running threads.
The new script uses dialog which comes as standard in bt5.
Options:

    arpscan “run arp-scan to create targets.txt”
    nmap “nmap targets”
    amap “amap ports found using nmap”
    sslscan “sslscan targets”
    gwp “Take photo of web pages found?”
    snmpscans “Check for default SNMP community strings”
    snmpget “Get data from SNMP services using known strings”
    enum4linux “Run enum4linux against targets”
    smtp “connect to SMTP to check if they allow relaying of mail”
    uniscan “run uniscan against HTTP(s) ports”
    nfsscan “connect to nfs services and list contents”

