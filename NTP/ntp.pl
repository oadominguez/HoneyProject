#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;
use Time::HiRes qw(gettimeofday usleep);

sub ntpLogic{

		my $ntpIP=shift;
		my $dataRcv=shift;
		#chop($ntpIP);
		#chop($dataRcv);
		#print "$ntpIP\n$dataRcv\n";

		my $ntpRespond="";
		my ($ReceiveSec, $ReceiveF) = gettimeofday();
		$ReceiveSec+=2208988800; #Equivalente en segundos de 70 años
		$ReceiveSec = sprintf("%x",$ReceiveSec); #Conversion a hexadecimal de 4 bytes
		$ReceiveF = sprintf("%08x",$ReceiveF); #Conversion a hexadecimal de 4 bytes agregando bytes faltantes

		my $dataHex = $dataRcv;
		$dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
		#print "dataHex $dataHex\n";
		my @hexData=($dataHex =~ m/../g ); #Arreglo de bytes
		#print "@hexData\n";
		#Armando paquete de respuesta
		$ntpRespond.="24"; #LI - No warning; Version NTP4; Mode - Server
		#$ntpRespond.="1C"; #LI - No warning; Version NTP4; Mode - Server
		$ntpRespond.="02"; #Primary Interface
		$ntpRespond.= $hexData[2]; # Poll Interval
		$ntpRespond.="fa"; # Clock Precision
		$ntpRespond.="00010000"; #Root Delay - 1 segundo
		$ntpRespond.="000005cb"; #Root Dispersion 0.0226 segundos

		#Reference ID (IP servidor)
		my @ip = split('\.',$ntpIP);
		for (my $i=0;$i<4;$i++){
			$ntpRespond.=sprintf("%02x",$ip[$i]);
		}
		

		#Reference Timestamp (Hora actual del servidor)
		my ($ReferSec, $ReferF) = gettimeofday();
		$ReferSec+=2208988800; #Equivalente en segundos de 70 años
		$ReferSec = sprintf("%x",$ReferSec); #Conversion a hexadecimal de 4 bytes
		$ReferF = sprintf("%08x",$ReferF);
		#print "Reference: $ReferSec $ReferF\n";

		$ntpRespond.="$ReferSec";
		$ntpRespond.="$ReferF";

		#Originate Time Stamp proveniente del campo Transmit Timestamp del paquete recibido (Hora a la que el cliente envio el paquete)
		for (my $i=40;$i<48;$i++){
			$ntpRespond.=$hexData[$i];
		}

		#Receive Time Stamp (Hora a la que se recibio el paquete del cliente)
		#print "Receive: $ReceiveSec $ReceiveF\n";
		$ntpRespond.="$ReceiveSec";
		$ntpRespond.="$ReceiveF";

		#Transmit Timestamp (Hora a la que se envia el paquete)
		my ($TransSec, $TransF) = gettimeofday();
		$TransSec+=2208988800; #Equivalente en segundos de 70 años
		$TransSec = sprintf("%x",$TransSec); #Conversion a hexadecimal de 4 bytes
		$TransF = sprintf("%08x",$TransF);
		#print "Transmit: $TransSec $TransF\n";
		$ntpRespond.="$TransSec";
		$ntpRespond.="$TransF";
		return $ntpRespond;

}

sub ntpServer{
	my $ntpIP=$_[0];
	my $ntpPort=123;
	my $ntpSocket;
	my $clientAddr;
	my @times;
	my %peticiones=();

	##Lectura del archivo de configuración para obtener tarpiting
	open(CONFIG,"ntp.conf") or die "No se pudo abrir";
	  while(<CONFIG>){
			chomp($_);
			if ($_ =~ m/^Tarpiting.*/g){
				@times=split(' ',$_);
			}
		}
	close(CONFIG);

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
		#print "rec: $dataRcv\n";
		$ntpRespond=ntpLogic($ntpIP,$dataRcv);
		$clientAddr = $ntpSocket->peerhost();
		$peticiones{$clientAddr}++; #Aumenta peticiones por cada ip;

		my $contador=$peticiones{$clientAddr}-1;
		if ($contador==0){
			print "Enviando respuesta NTP...\n\n";
			$ntpSocket->send(pack("H*",$ntpRespond));
		}
		elsif($contador<10){
			print "Enviando respuesta NTP después de $times[$contador] microsegundos...\n\n";
			usleep($times[$contador]);
			$ntpSocket->send(pack("H*",$ntpRespond));
		}
		else{
			print "Enviando respuesta NTP después de $times[10] microsegundos...\n\n";
			usleep($times[10]);
			$ntpSocket->send(pack("H*",$ntpRespond));
		}
		
	}
	$ntpSocket->close();

}

ntpServer("192.168.1.20");

