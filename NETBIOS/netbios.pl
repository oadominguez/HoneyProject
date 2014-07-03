#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;
use Time::HiRes qw(usleep);

sub netbiosLogic{
	my $dataHex=shift;
	my $equipo=shift;
	#Leer archivo de configuración
	chop($equipo);
	print "Equipo: $equipo\n";
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
	return $tmp;

}

sub netbiosServer{
	my $nbIP=$_[0];
	my $nbPort=137;
	my $nbSocket;
	my $clientAddr;
	my $clientPort;
	my @times;
	my %peticiones=();
	my $nombreEquipo;

	##Lectura del archivo de configuración para obtener nombre de equipo y tarpiting
	open(CONFIG,"netbios.conf") or die "No se pudo abrir";
	  while(<CONFIG>){
			chomp($_);
			if ($_ =~ m/^Equipo (.*)/g){
				$nombreEquipo=$1;
			}
			if ($_ =~ m/^Tarpiting.*/g){
				@times=split(' ',$_);
			}
		}
	close(CONFIG);
	print "$nombreEquipo\nl@times\n";
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

		$peticiones{$clientAddr}++; #Aumenta peticiones por cada ip;


		my $netbiosData=netbiosLogic($dataHex,$nombreEquipo);
		if ($peticiones{$clientAddr}==0){
			print "Enviando respuesta...\n\n";
			$nbSocket->send(pack("H*",$netbiosData));
		}
		elsif($peticiones{$clientAddr}<10){
			print "Enviando respuesta despues de $times[$peticiones{$clientAddr}] microsegundos...\n\n";
			usleep($times[$peticiones{$clientAddr}]);
			$nbSocket->send(pack("H*",$netbiosData));
		}
		else{
			print "Enviando respuesta despues de $times[10] microsegundos...\n\n";
			usleep($times[10]);
			$nbSocket->send(pack("H*",$netbiosData));
		}

	}
	$nbSocket->close();
}

netbiosServer("127.0.0.1");

