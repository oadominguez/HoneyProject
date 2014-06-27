#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;

my $chargenPort=19;
my $chargenSocket;
my $clientAddr;
my $clientPort;
my $dataSend = '!"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|} ~';
#my $dataSend = "hola";
print "Creando Chargen Socket...[+]\n";
# Creamos el Socket
$chargenSocket = IO::Socket::INET->new(LocalPort => $chargenPort,
																						Type => SOCK_DGRAM,
																					 Proto => 'udp') or die "No se pudo crear el chargenSocket $! \n";
print "Chargen Socket Creado...[+]\n";
print "Servidor Chargen a la escucha en UDP bajo puerto $chargenPort\n";
while(1)
{
	my $dataRcv ="";
	$chargenSocket->recv($dataRcv,2048);
	$clientAddr = $chargenSocket->peerhost();
	$clientPort = $chargenSocket->peerport();
	print "\n $clientAddr : $clientPort dice: $dataRcv \n";
	print "Enviando datos al cliente \n";
	while(1){
	$chargenSocket->send($dataSend);}
}
$chargenSocket->close();
