#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;
use Time::HiRes qw(gettimeofday usleep);
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
		close(CONFIG);
	}
}

sub dataParser
{
	my $file=$_[0];
	if(-f $file and -r $file) 
	{
		open(CONFIG,$file) or die "No se pudo abrir $file \n";
		while(<CONFIG>)
		{
			chomp($_);
			if(!($_ =~ m/^#.*/g) and ($_ =~ m/^data.*/i)){my @arrayData=split(' ',$_); shift(@arrayData); return @arrayData;}
		}
	}
}

sub chargenServer
{
	my $chargenIp=$_[0];
	my $chargenPort=19;
	my $chargenSocket;
	my $clientAddr;
	my $clientPort;
	my $dataSend;
	my @arrayData=dataParser("chargen.conf");


	my @times;
	my %peticiones=();

	##Lectura del archivo de configuración para obtener tarpiting
	open(CONFIG,"chargen.conf") or die "No se pudo abrir";
	  while(<CONFIG>){
			chomp($_);
			if ($_ =~ m/^Tarpiting.*/g){
				@times=split(' ',$_);
			}
		}
	close(CONFIG);


	if($arrayData[0] ne ""){$dataSend=$arrayData[0];}
	else		
	{
		$dataSend = '!"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|} ~';
	}
	close(CONFIG);
	print "Creando Chargen Socket...[+]\n";
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
		
		$peticiones{$clientAddr}++; #Aumenta peticiones por cada ip;


		my $contador=$peticiones{$clientAddr}-1;
		if ($contador==0){
			print "Enviando respuesta Chargen...\n\n";
			while(1){$chargenSocket->send($dataSend);}
		}
		elsif($contador<10){
			print "Enviando respuesta Chargen después de $times[$contador] microsegundos...\n\n";
			usleep($times[$contador]);
			while(1){$chargenSocket->send($dataSend);}
		}
		else{
			print "Enviando respuesta Chargen después de $times[10] microsegundos...\n\n";
			usleep($times[10]);
			while(1){$chargenSocket->send($dataSend);}
		}



		
	}
	$chargenSocket->close();
}

sub qotdServer
{
	my $qotdIp=$_[0];
	my $qotdPort=17;
	my $qotdSocket;
	my $clientAddr;
	my $clientPort;
	my %data = (0 => "Duerme, duerme\n", 1 => "Hola\n", 2 => "Hoy va a llover\n", 3 => "Hello\n");
	my $datos="";
	my @arrayData = dataParser("qotd.conf");
	if($arrayData[0] ne ""){$datos=$arrayData[0];}

	my @times;
	my %peticiones=();

	##Lectura del archivo de configuración para obtener tarpiting
	open(CONFIG,"qotd.conf") or die "No se pudo abrir";
	  while(<CONFIG>){
			chomp($_);
			if ($_ =~ m/^Tarpiting.*/g){
				@times=split(' ',$_);
			}
		}
	close(CONFIG);



	print "Creando QOTD Socket...[+] \n";
	$qotdSocket = IO::Socket::INET->new(LocalAddr => $qotdIp,
                                    	LocalPort => $qotdPort,
                                       	   Type => SOCK_DGRAM,
                                        	Proto => 'udp') or die "No se pudo crear el qotdSocket $! \n";
	print "QOTD Socket Creado...[+] \n";
	print "Servidor QOTD a la escucha en $qotdIp UDP bajo puerto $qotdPort\n";
	while(1)
	{
  	my $dataRcv ="";
  	$qotdSocket->recv($dataRcv,2048);
  	$clientAddr = $qotdSocket->peerhost();
  	$clientPort = $qotdSocket->peerport();
		$peticiones{$clientAddr}++; #Aumenta peticiones por cada ip;

		my $contador=$peticiones{$clientAddr}-1;
		if ($contador==0){
			print "Enviando respuesta QOTD...\n\n";
			while(1)
			{
				if($datos ne ""){$qotdSocket->send($datos);}
				else
				{
  				my $indexQuote = int(rand(4));
  				$qotdSocket->send($data{$indexQuote});
				}
			}
		}
		elsif($contador<10){
			print "Enviando respuesta QOTD después de $times[$contador] microsegundos...\n\n";
			usleep($times[$contador]);
			while(1)
			{
				if($datos ne ""){$qotdSocket->send($datos);}
				else
				{
  				my $indexQuote = int(rand(4));
  				$qotdSocket->send($data{$indexQuote});
				}
			}
		}
		else{
			print "Enviando respuesta NTP después de $times[10] microsegundos...\n\n";
			usleep($times[10]);
			while(1)
			{
				if($datos ne ""){$qotdSocket->send($datos);}
				else
				{
  				my $indexQuote = int(rand(4));
  				$qotdSocket->send($data{$indexQuote});
				}
			}
		}
	}
	$qotdSocket->close();
}

sub dnsLogic
{
  my $dataHex = $_[0];
  my $ID = substr($dataHex,0,4);
  my $flags = "8580";   ### Respuesta | Autoritativa | Recursiva | No Error |
  my $numPreg = substr($dataHex,8,4);
  my $numResp = "0001";
  my $numRespAuth = "0000";
  my $numRespAddit = "0000"; ## Adicionales
  my $dataQuery = substr($dataHex,24,length($dataHex));
  my $type = substr($dataQuery,-8,4);
  my $class = substr($dataQuery,-4,4);
  my $tamRes;
  my $dataRes;
  if($type eq "000f") ## Si la peticion es MX
  {
    my $pref  = "0005"; #Preferencia Estandar
    $dataRes = "smtp.seguridad.unam.mx";
    my @dataArray = split(/\./,$dataRes);
    my $dataSwap="";
    foreach my $data (@dataArray) ## Operamos segun QNAME format
    {
      my $tamFrag=sprintf("%02x",length($data));
      $dataSwap=$dataSwap.$tamFrag;
  		my $dataHex = $data;
      $dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
      $dataSwap=$dataSwap.$dataHex;
    }
    $tamRes=sprintf("%04x",(length($dataRes)+3+2)); # + 2 tail + 2 pref
    my $tail = "c00c"; # Cola obligatoria (Apunta al dominio question) 
    $dataRes = $pref.$dataSwap.$tail;
  }
  elsif($type eq "0002") ## Peticion NS
  {
    $dataRes = "dns.seguridad.unam.mx";
    my @dataArray = split(/\./,$dataRes);
    my $dataSwap="";
    foreach my $data (@dataArray) ## Se opera segun formato QNAME
    {
      my $tamFrag=sprintf("%02x",length($data));
      $dataSwap=$dataSwap.$tamFrag;
      my $dataHex = $data;
      $dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
      $dataSwap=$dataSwap.$dataHex;
    }
    $tamRes=sprintf("%04x",(length($dataRes)+3)); # + 2 tail
    my $tail = "c00c"; 
    $dataRes = $dataSwap.$tail;
  }
 else  ## Peticion A por defecto
  {
    $dataRes = sprintf("%02x%02x%02x%02x", rand 0xFF, rand 0xFF, rand 0xFF, rand 0xFF); #Random IP
    $tamRes = sprintf("%04x",(length($dataRes)/2)); ##Tomamos cada dos bytes
  }
  my $response = $ID.$flags.$numPreg.$numResp.$numRespAuth.$numRespAddit.$dataQuery;
  my $pointer = "c00c";
  my $tipoRes = $type;
  my $classRes = $class;
  my $ttl = "00000007"; #Segundos de vida
  $response = $response.$pointer.$tipoRes.$classRes.$ttl.$tamRes.$dataRes;
  return $response;
}


sub dnsServer
{
	my $dnsIp=$_[0];
	my $dnsPort=53;
	my $dnsSocket;
	my $clientAddr;
	my $clientPort;

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



	print "Creando DNS Socket...[+] \n";
	$dnsSocket = IO::Socket::INET->new(LocalAddr => $dnsIp,
                                   	 LocalPort => $dnsPort,
                                     	    Type => SOCK_DGRAM,
                                       	 Proto => 'udp') or die "No se pudo crear el DNS socket $! \n";
	print "DNS Socket Creado...[+] \n";
	print "Servidor DNS a la escucha en $dnsIp UDP bajo puerto $dnsPort\n";
	while(1)
	{
  	my $dataRcv ="";
  	$dnsSocket->recv($dataRcv,2048);
  	my $dataHex = $dataRcv;
  	$dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
  	$clientAddr = $dnsSocket->peerhost();
  	$clientPort = $dnsSocket->peerport();
  	my $response = dnsLogic($dataHex);

		$peticiones{$clientAddr}++; #Aumenta peticiones por cada ip;

		my $contador=$peticiones{$clientAddr}-1;
		if ($contador==0){
			print "Enviando respuesta DNS...\n\n";
			$dnsSocket->send(pack("H*",$response));
		}
		elsif($contador<10){
			print "Enviando respuesta DNS después de $times[$contador] microsegundos...\n\n";
			usleep($times[$contador]);
			$dnsSocket->send(pack("H*",$response));
		}
		else{
			print "Enviando respuesta DNS después de $times[10] microsegundos...\n\n";
			usleep($times[10]);
			$dnsSocket->send(pack("H*",$response));
		}


	}
	$dnsSocket->close();
}


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
	print "ntpIP $ntpIP\n";
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


sub netbiosLogic{
	my $dataHex=shift;
	my $equipo=shift;
	#Leer archivo de configuración
	chop($equipo);
	#print "Equipo: $equipo\n";
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
	#print "$nombreEquipo\n@times\n";
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



my @threads;
print "Iniciando servidores CHARGEN\n";
my @chargenIp = ipParser("chargen.conf");
if(@chargenIp)
{
	shift(@chargenIp);
	print "Servicio CHARGEN iniciara en las ip: @chargenIp \n";
	foreach(@chargenIp)
	{
		my $hilo=threads->new(\&chargenServer,$_);
		push(@threads,$hilo);
	}
}
print "Iniciando servidores QOTD \n";
my @qotdIp = ipParser("qotd.conf");
if(@qotdIp)
{
	shift(@qotdIp);
	print "Servicio QOTD iniciara en las ip: @qotdIp \n";
	foreach(@qotdIp)
	{
		my $hilo=threads->new(\&qotdServer,$_);
		push(@threads,$hilo);
	}
}
print "Iniciando servidores DNS \n";
my @dnsIp = ipParser("dns.conf");
if(@dnsIp)
{
	shift(@dnsIp);
	print "Servicio DNS  iniciara en las ip: @dnsIp \n";
	foreach(@dnsIp)
	{
		my $hilo=threads->new(\&dnsServer,$_);
		push(@threads,$hilo);
	}
}

print "Iniciando servidores NTP \n";
my @ntpIp = ipParser("ntp.conf");
if(@ntpIp)
{
	shift(@ntpIp);
	print "Servicio NTP iniciara en las ip: @ntpIp \n";
	foreach(@ntpIp)
	{
		my $hilo=threads->new(\&ntpServer,$_);
		push(@threads,$hilo);
	}
}

print "Iniciando servidores NETBIOS \n";
my @netbiosIp = ipParser("netbios.conf");
if(@netbiosIp)
{
	shift(@netbiosIp);
	print "Servicio NETBIOS iniciara en las ip: @netbiosIp \n";
	foreach(@netbiosIp)
	{
		my $hilo=threads->new(\&netbiosServer,$_);
		push(@threads,$hilo);
	}
}

print "Iniciando servidores SSDP \n";
my @ssdpIp = ipParser("ssdp.conf");
if(@ssdpIp)
{
	shift(@ssdpIp);
	print "Servicio SSDP iniciara en las ip: @ssdpIp \n";
	foreach(@ssdpIp)
	{
		my $hilo=threads->new(\&ssdpServer,$_);
		push(@threads,$hilo);
	}
}

foreach (@threads) { my $id = $_->join; }
