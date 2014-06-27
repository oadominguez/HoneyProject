#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;

my $qotdPort=17;
my $qotdSocket;
my $clientAddr;
my $clientPort;
my %data = (0 => "Duerme, duerme\n", 1 => "Hola\n", 2 => "Hoy va a llover\n", 3 => "Animo, ya casi termina esto\n");
#print $data{2};
#my $dataSend = "hola";
print "Creando QOTD Socket...[+] \n";
# Creamos el Socket
$qotdSocket = IO::Socket::INET->new(LocalPort => $qotdPort,
																				 Type => SOCK_DGRAM,
																				Proto => 'udp') or die "No se pudo crear el qotdSocket $! \n";
print "QOTD Socket Creado...[+] \n";
print "Servidor QOTD a la escucha en UDP bajo puerto $qotdPort\n";
while(1)
{
	my $dataRcv ="";
	$qotdSocket->recv($dataRcv,2048);
	$clientAddr = $qotdSocket->peerhost();
	$clientPort = $qotdSocket->peerport();
	print "\n $clientAddr : $clientPort dice: $dataRcv \n";
	print "Enviando datos al cliente \n";
	while(1){
	my $indexQuote = int(rand(4));
	$qotdSocket->send($data{$indexQuote});}
}
$qotdSocket->close();
