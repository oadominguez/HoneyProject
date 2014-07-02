#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;

my $ssdpPort=1900;
my $ssdpSocket;
my $clientAddr;
my $clientPort;
my $ssdpIP="192.168.1.20";
print "Creando UDP Socket...[+] \n";
# Creamos el Socket
$ssdpSocket = IO::Socket::INET->new(LocalPort => $ssdpPort,
																				 Type => SOCK_DGRAM,
																				LocalAddr => $ssdpIP,
																				Proto => 'udp') or die "No se pudo crear el socket UDP $! \n";
print "UDP Socket Creado...[+] \n";
print "Servidor a la escucha en UDP bajo puerto $ssdpPort\n";
while(1)
{
	my $dataRcv ="";
	$ssdpSocket->recv($dataRcv,2048);
	my $dataHex = $dataRcv;
	$dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
	$clientAddr = $ssdpSocket->peerhost();
	$clientPort = $ssdpSocket->peerport();
	#print "\n $clientAddr : $clientPort dice: $dataRcv \n";
	#print "RAW INPUT: $dataHex";
	my $ssdpdata = "HTTP/1.1 200 OK
CACHE-CONTROL: max-age=172800
DATE: ".gmtime()." GMT
EXT:
LOCATION: http://192.168.10.51:8080/udap/api/data?target=smartText.xml
SERVER: Linux/2.6.18-308.4.1.el5 UDAP/2.0 LGSmartTV_33/2.0
ST: urn:schemas-udap:service:smartText:1
USN: uuid:33068e81-3306-0633-619b-9b61818e0633::urn:schemas-udap:service:smartText:1\n\n";
	$ssdpSocket->send($ssdpdata);
}
$ssdpSocket->close();
