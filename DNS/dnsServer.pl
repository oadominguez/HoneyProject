#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;

my $dnsIp='127.0.0.1';
my $dnsPort=53;
my $dnsSocket;
my $clientAddr;
my $clientPort;

sub dnsLogic
{
	my $dataHex = $_[0];
	print "EN LOGICA $dataHex \n";
}

print "Creando DNS Socket...[+] \n";
# Creamos el Socket
$dnsSocket = IO::Socket::INET->new(LocalAddr => $dnsIp,
																	 LocalPort => $dnsPort,
																				Type => SOCK_DGRAM,
																			 Proto => 'udp') or die "No se pudo crear el socket UDP $! \n";
print "UDP Socket Creado...[+] \n";
print "Servidor DNS a la escucha en UDP bajo puerto $dnsPort\n";
while(1)
{
	my $dataRcv ="";
	$dnsSocket->recv($dataRcv,2048);
	my $dataHex = $dataRcv;
	$dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
	$clientAddr = $dnsSocket->peerhost();
	$clientPort = $dnsSocket->peerport();
	print "\n $clientAddr : $clientPort dice: $dataRcv \n";
	print "RAW INPUT: $dataHex";
	dnsLogic($dataHex);
}
$dnsSocket->close();
