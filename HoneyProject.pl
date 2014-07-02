#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;
use threads;

sub ipParser
{
	my $file = $_[0];
	if(-f $file and -r $file) 
	{
		open(CONFIG,$file) or die "No se pudo abrir $file \n";
		while(<CONFIG>)
		{
			chomp($_);
			if (!($_ =~ m/^#.*/g) and ($_ =~ m/^ip.*/i)){my @arrayIp=split(' ',$_); return @arrayIp;}
		}
	}
}

sub chargenServer
{
	my $chargenIp=$_[0];
	#my $chargenIp='127.0.0.1';
	my $chargenPort=19;
	my $chargenSocket;
	my $clientAddr;
	my $clientPort;
	my $dataSend = '!"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|} ~';
	#my $dataSend = "hola";
	print "Creando Chargen Socket...[+]\n";
	# Creamos el Socket
	$chargenSocket = IO::Socket::INET->new(LocalAddr => $chargenIp,
																			 	 LocalPort => $chargenPort,
																				 			Type => SOCK_DGRAM,
																					 	 Proto => 'udp') or die "No se pudo crear el chargenSocket $! \n";
	print "Chargen Socket Creado...[+]\n";
	print "Servidor Chargen a la escucha en $chargenIp UDP bajo puerto $chargenPort\n";
	while(1)
	{
		my $dataRcv ="";
		$chargenSocket->recv($dataRcv,2048);
		$clientAddr = $chargenSocket->peerhost();
		$clientPort = $chargenSocket->peerport();
		print "\n $clientAddr : $clientPort dice: $dataRcv \n";
		print "Enviando datos al cliente \n";
		while(1){$chargenSocket->send($dataSend);}
	}
	$chargenSocket->close();
}

my @threads;
print "Iniciando servicio CHARGEN\n";
my @chargenIp = ipParser("chargen.conf");
if (@chargenIp)
{
	shift(@chargenIp);
	print "Servicio CHARGEN iniciara en las ip: @chargenIp \n";
	foreach(@chargenIp)
	{
		my $hilo=threads->new(\&chargenServer,$_);
		push(@threads,$hilo);
	}
}
foreach (@threads) { my $id = $_->join; }
