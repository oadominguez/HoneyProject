#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;

my $genericPort=53;
my $genericSocket;
my $clientAddr;
my $clientPort;
print "Creando UDP Socket...[+] \n";
# Creamos el Socket
$genericSocket = IO::Socket::INET->new(LocalPort => $genericPort,
																				 Type => SOCK_DGRAM,
																				Proto => 'udp') or die "No se pudo crear el socket UDP $! \n";
print "UDP Socket Creado...[+] \n";
print "Servidor a la escucha en UDP bajo puerto $genericPort\n";
while(1)
{
	my $dataRcv ="";
	$genericSocket->recv($dataRcv,2048);
	my $dataHex = $dataRcv;
	$dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
	$clientAddr = $genericSocket->peerhost();
	$clientPort = $genericSocket->peerport();
	print "\n $clientAddr : $clientPort dice: $dataRcv \n";
	print "RAW INPUT: $dataHex";
}
$genericSocket->close();
