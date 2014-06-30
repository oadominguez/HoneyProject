#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;
use Time::HiRes qw(usleep);

my $nbIP="127.0.0.1";
my $nbPort=137;
my $nbSocket;
my $clientAddr;
my $clientPort;
my @valConfig;
my $peticiones=0;
#Leer archivo de configuración
open(CONFIG,"netbios.conf") or die "No se pudo abrir";
  while(<CONFIG>){
		chomp($_);
		#print "$_\n";
		if (!($_ =~ m/^#.*/g)){
			@valConfig=split(',',$_);
		}
	}
close(CONFIG);

#print "@valConfig";


print "Creando UDP Socket...[+] \n";
# Creamos el Socket
$nbSocket = IO::Socket::INET->new(LocalPort => $nbPort,
																	Type => SOCK_DGRAM,
																	LocalAddr => $nbIP,
																	Proto => 'udp') or die "No se pudo crear el socket UDP $! \n";
print "UDP Socket Creado...[+] \n";
print "Servidor a la escucha en UDP bajo puerto $nbPort\n";

while(1)
{
	my $dataRcv ="";
	$nbSocket->recv($dataRcv,2048);
	my $dataHex = $dataRcv;
	$dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
	$clientAddr = $nbSocket->peerhost();
	$clientPort = $nbSocket->peerport();
	#print "\n $clientAddr : $clientPort dice: $dataRcv \n";
	#print "RAW INPUT: $dataHex\n";
	
	#Modificación del original para convertirlo en un paquete de respuesta
	my $i=0;
	my @hexData=($dataHex =~ m/../g ); #Arreglo de bytes
	my $tmp='';
	foreach my $byte (@hexData){
		#Name Query Response, no error
		if ($i==2){$tmp.="84";} 
		elsif ($i==3){$tmp.="00";}
		#Questions
		elsif ($i==4){$tmp.="00";}
		elsif ($i==5){$tmp.="00";}
		#Answer
		elsif ($i==6){$tmp.="00";}
		elsif ($i==7){$tmp.="01";}
		else{$tmp.=$byte;}
		$i++;
	}
  $tmp.="00000000";# TTL
	$tmp.="009b06";# Data Length and Number of names

	#Nombre del equipo falso (hasta 16 caracteres)
	my $equipo=$valConfig[0]; 
	$equipo=~ s/(.)/sprintf("%02x",ord($1))/eg;
	my $t1=(length($equipo)/2);

	#Se llena con 20 los caracteres faltantes
	for (my $i=0;$i<15-$t1;$i++){
		$equipo.="20";
	}
	$tmp.=$equipo;# NombreEquipo
	$tmp.="004400574f524b47524f555020202020202000c400"; #Datos adicionales, Workgroup
	$tmp.=$equipo;# NombreEquipo
#Resto del paquete, incluye worgroup y MAC Address
$tmp.="204400574f524b47524f55502020202020201ec400574f524b47524f55502020202020201d440001025f5f4d5342524f5753455f5f0201c400000c2924709200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
	
	#print "RAW OUTPUT: $tmp\n\n";
	if ($peticiones==0){
		print "Enviando respuesta...\n\n";
		$nbSocket->send(pack("H*",$tmp));
	}
	elsif($peticiones<10){
		print "Enviando respuesta despues de $valConfig[$peticiones] microsegundos...\n\n";
		usleep($valConfig[$peticiones]);
		$nbSocket->send(pack("H*",$tmp));
	}
	else{
		print "Enviando respuesta despues de $valConfig[10] microsegundos...\n\n";
		usleep($valConfig[10]);
		$nbSocket->send(pack("H*",$tmp));
	}
	$peticiones++;
}
$nbSocket->close();
