#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;
use Time::HiRes qw(usleep);

sub ssdpLogic{

	my $location;
	my $server;
	my $st;
	my $usn;

	##Lectura del archivo de configuración para obtener tarpiting
	open(CONFIG,"ssdp.conf") or die "No se pudo abrir";
	  while(<CONFIG>){
			chomp($_);
			if ($_ =~ m/^LOCATION (.*)/g){
				$location=$1;
			}
			if ($_ =~ m/^SERVER (.*)/g){
				$server=$1;
			}
			if ($_ =~ m/^ST (.*)/g){
				$st=$1;
			}
			if ($_ =~ m/^USN (.*)/g){
				$usn=$1;
			}
		}
	close(CONFIG);

	my $ssdpData = "HTTP/1.1 200 OK
CACHE-CONTROL: max-age=172800
DATE: ".gmtime()." GMT
EXT:
LOCATION: $location
SERVER: $server
ST: $st
USN: $usn\n\n";
	#print "$ssdpData\n";
	return $ssdpData;
}


sub ssdpServer{
	my $ssdpPort=1900;
	my $ssdpSocket;
	my $clientAddr;
	my $ssdpIP=$_[0];
	my $ssdpData;
	my @times;
	my %peticiones=();

	##Lectura del archivo de configuración para obtener tarpiting
	open(CONFIG,"ssdp.conf") or die "No se pudo abrir";
	  while(<CONFIG>){
			chomp($_);
			if ($_ =~ m/^Tarpiting.*/g){
				@times=split(' ',$_);
			}
		}
	close(CONFIG);


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
		$peticiones{$clientAddr}++; #Aumenta peticiones por cada ip;

		$ssdpData=ssdpLogic();
		my $contador=$peticiones{$clientAddr}-1;
		if ($contador==0){
			print "Enviando respuesta SSDP...\n\n";
			$ssdpSocket->send($ssdpData);
		}
		elsif($contador<10){
			print "Enviando respuesta SSDP después de $times[$contador] microsegundos...\n\n";
			usleep($times[$contador]);
						$ssdpSocket->send($ssdpData);
		}
		else{
			print "Enviando respuesta SSDP después de $times[10] microsegundos...\n\n";
			usleep($times[10]);
						$ssdpSocket->send($ssdpData);
		}
	}
	$ssdpSocket->close();
}

ssdpServer("192.168.1.20");

