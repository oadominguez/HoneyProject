#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;

my $ntpIP="192.168.1.10";
my $ntpPort=123;
my $ntpSocket;
my $clientAddr;
my $clientPort;
print "Creando UDP Socket...[+] \n";
# Creamos el Socket
$ntpSocket = IO::Socket::INET->new(LocalPort => $ntpPort,LocalAddr =>$ntpIP,Type => SOCK_DGRAM,Proto => 'udp') or die "No se pudo crear el socket UDP $! \n";


print "UDP Socket Creado...[+] \n";
print "Servidor a la escucha en UDP bajo puerto $ntpPort\n";
while(1)
{	
	my $ntpRespond="";
	my $dataRcv ="";
	$ntpSocket->recv($dataRcv,2048);
	my $dataHex = $dataRcv;
	$dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
	my @hexData=($dataHex =~ m/../g ); #Arreglo de bytes
	
	$clientAddr = $ntpSocket->peerhost();
	$clientPort = $ntpSocket->peerport();
	
	$ntpRespond.="24"; #LI - No warning; Version NTP4; Mode - Server
	#$ntpRespond.="1C"; #LI - No warning; Version NTP4; Mode - Server
	$ntpRespond.="02"; #Primary Interface
	$ntpRespond.= $hexData[2];#"03"; # Poll Interval
	$ntpRespond.="fa"; # Clock Precision
	$ntpRespond.="00010000"; #Root Delay - 1 segundo
	$ntpRespond.="000005cb"; #Root Dispersion 0.0226 segundos
	#Reference ID
	my @ip = split('\.',$ntpIP);
	for (my $i=0;$i<4;$i++){
		$ntpRespond.=sprintf("%02x",$ip[$i]);
	}
	#$ntpRespond.="8069c90b";
	my $epoc = time();
	$epoc += 2208988800;
	#print "EPOC: $epoc\n";
	$epoc = sprintf("%x",$epoc);
	#Reference Time Stamp
	$ntpRespond.="$epoc";
	$ntpRespond.="e3862add";
	#Originate Time Stamp

	for (my $i=40;$i<48;$i++){
		$ntpRespond.=$hexData[$i];
	}

	#$ntpRespond.=#"$epoc";
	#$ntpRespond.="ffab0ce0";
	#Receive Time Stamp
	$ntpRespond.="$epoc";
	$ntpRespond.="00000000";
	#Transmit Time Stamp
	$ntpRespond.="$epoc";
	$ntpRespond.="00000020";

	$ntpSocket->send(pack("H*",$ntpRespond));
	print "\n $clientAddr : $clientPort dice: $dataRcv \n";
	#print "RAW OUT: $ntpRespond\n";
}
$ntpSocket->close();


