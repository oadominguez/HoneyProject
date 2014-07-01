#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;
use Time::HiRes qw(gettimeofday);

my $ntpIP="192.168.1.20";
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
	#Receive Timestamp
	my ($ReceiveSec, $ReceiveF) = gettimeofday();
	$ReceiveSec+=2208988800; #Equivalente en segundos de 70 años
	$ReceiveSec = sprintf("%x",$ReceiveSec); #Conversion a hexadecimal de 4 bytes
	$ReceiveF = sprintf("%08x",$ReceiveF); #Conversion a hexadecimal de 4 bytes agregando bytes faltantes

	my $dataHex = $dataRcv;
	$dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
	my @hexData=($dataHex =~ m/../g ); #Arreglo de bytes

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

	$ntpSocket->send(pack("H*",$ntpRespond));
	#print "\n $clientAddr : $clientPort dice: $dataRcv \n\n";
	#print "RAW OUT: $ntpRespond\n";
}
$ntpSocket->close();


