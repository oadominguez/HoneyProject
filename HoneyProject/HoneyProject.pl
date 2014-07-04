#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;
use Time::HiRes qw(gettimeofday usleep);
use threads;
use Term::ANSIColor;

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
	my @arrayData=dataParser("config/chargen.conf");
	my @times;
	my %peticiones=();
	open(CONFIG,"config/chargen.conf") or die "No se pudo abrir";
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
	$chargenSocket = IO::Socket::INET->new(LocalAddr => $chargenIp,
																			 	 LocalPort => $chargenPort,
																				 			Type => SOCK_DGRAM,
																					 	 Proto => 'udp') or die "No se pudo crear el chargenSocket $! \n";
	sleep(1);
	print "  [+]...... Servidor ";
	print color("red"), "CHARGEN", color("reset");
	print " a la escucha en ";
	print color("cyan"), "$chargenIp", color("reset");
	print color("reset"), ":", color("reset");
	print color("magenta"), "$chargenPort ", color("reset");
	print color('reset'), "...... [+] \n";
	while(1)
	{
		my $dataRcv ="";
		$chargenSocket->recv($dataRcv,2048);
		$clientAddr = $chargenSocket->peerhost();
		$clientPort = $chargenSocket->peerport();
		$peticiones{$clientAddr}++; #Aumenta peticiones por cada ip;
		my $contador=$peticiones{$clientAddr}-1;
		if ($contador==0){
			while(1){$chargenSocket->send($dataSend);}
		}
		elsif($contador<10){
			usleep($times[$contador]);
			while(1){$chargenSocket->send($dataSend);}
		}
		else{
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
	my @datos;
	my @arrayData = dataParser("config/qotd.conf");
	if($arrayData[0] ne ""){@datos=@arrayData;}
	my @times;
	my %peticiones=();
	open(CONFIG,"config/qotd.conf") or die "No se pudo abrir";
	  while(<CONFIG>){
			chomp($_);
			if ($_ =~ m/^Tarpiting.*/g){
				@times=split(' ',$_);
			}
		}
	close(CONFIG);
	$qotdSocket = IO::Socket::INET->new(LocalAddr => $qotdIp,
                                    	LocalPort => $qotdPort,
                                       	   Type => SOCK_DGRAM,
                                        	Proto => 'udp') or die "No se pudo crear el qotdSocket $! \n";
	sleep(1);
	print "  [*]...... Servidor ";
	print color("red"), "QOTD", color("reset");
	print " a la escucha en ";
	print color("cyan"), "$qotdIp", color("reset");
	print color("reset"), ":", color("reset");
	print color("magenta"), "$qotdPort ", color("reset");
	print color('reset'), "...... [*] \n";
	while(1)
	{
  	my $dataRcv ="";
  	$qotdSocket->recv($dataRcv,2048);
  	$clientAddr = $qotdSocket->peerhost();
  	$clientPort = $qotdSocket->peerport();
		$peticiones{$clientAddr}++; #Aumenta peticiones por cada ip;
		my $contador=$peticiones{$clientAddr}-1;
		if ($contador==0)
		{
			if(@datos){$qotdSocket->send($datos[int(rand(scalar @datos))]);}
			else
			{
  			my $indexQuote = int(rand(4));
  			$qotdSocket->send($data{$indexQuote});
			}
		}
		elsif($contador<10){
			usleep($times[$contador]);
			if(@datos){$qotdSocket->send($datos[int(rand(scalar @datos))]);}
			else
			{
  			my $indexQuote = int(rand(4));
  			$qotdSocket->send($data{$indexQuote});
			}
		}
		else{
			usleep($times[10]);
			if(@datos){$qotdSocket->send($datos[int(rand(scalar @datos))]);}
			else
			{
  			my $indexQuote = int(rand(4));
  			$qotdSocket->send($data{$indexQuote});
			}
		}
	}
	$qotdSocket->close();
}

sub snmpLogic
{
	my $dataHex = $_[0];
	my $version = substr($dataHex,8,2);
	my $snmpVersion="0201".$version; ## Concatenamos primera capa: SNMP Version
	my $commSize = (sprintf("%d",hex(substr($dataHex,12,2)))*2);
	my $community = substr($dataHex,14,$commSize);
	my $snmpCommStr ="04".substr($dataHex,12,2).$community; #Concatenamos segunda capa: SNMP Community String
	my $requestSize = (sprintf("%d",hex(substr($dataHex,14+$commSize+6,2)))*2); ## tamaño del requestID
	my $requestID = substr($dataHex,14+$commSize+8,$requestSize); ## se recorre el tamaño de las capas
	my $snmpRequest = "02".substr($dataHex,14+$commSize+6,2).$requestID;
	my $snmpError = "020100";
	my $snmpErrorIndex = "020100";
	my $oidSize = (sprintf("%d",hex(substr($dataHex,22+$commSize+$requestSize+22,2)))*2); ## tamaño del oid
	my $oid = substr($dataHex,22+$commSize+$requestSize+24,$oidSize);
	my $snmpOid = "06".substr($dataHex,44+$commSize+$requestSize,2).$oid;
	my @arrayData=dataParser("config/snmp.conf");
	my $value;
	if($arrayData[0] ne ""){$value=$arrayData[0];}
	else {$value = "0a0b0c0d0e0f";}
	my $valueSize = sprintf("%02x",(length($value)/2));
	my $snmpValue = "04".$valueSize.$value; # Respuesta de tipo octect String
	my $snmpVarBindSize=0; #Inicializamos el tamaño
	$snmpVarBindSize = $snmpVarBindSize + (length($snmpOid)/2); ## agregamos tamaño del oid
	$snmpVarBindSize = $snmpVarBindSize + (length($snmpValue)/2); ## agregamos tamaño del valor
	my $snmpVarBindSizeHex = sprintf("%02x",$snmpVarBindSize);
	my $snmpVarBind="30".$snmpVarBindSizeHex.$snmpOid.$snmpValue; ## CAPA de varbind lista
	my $snmpVarBindListSize = 0; # inicializamos el tamaño
	$snmpVarBindListSize = $snmpVarBindListSize + (length($snmpVarBind)/2);
	my $snmpVarBindListSizeHex = sprintf("%02x",$snmpVarBindListSize);
	my $snmpVarBindList = "30".$snmpVarBindListSizeHex.$snmpVarBind; ## CAPA de varbind list lista
	my $snmpPDUSize=0; ## Inicializamos el tamaño
	$snmpPDUSize = $snmpPDUSize + (length($snmpRequest)/2) +(length($snmpError)/2);
	$snmpPDUSize = $snmpPDUSize + (length($snmpErrorIndex)/2) +(length($snmpVarBindList)/2);
	my $snmpPDUSizeHex = sprintf("%02x",$snmpPDUSize);
	my $snmpPDU = "a2".$snmpPDUSizeHex.$snmpRequest.$snmpError.$snmpErrorIndex.$snmpVarBindList; # CAPA snmp PDU lista
	my $snmpMsgSize = 0; #Inicializamos el tamaño
	$snmpMsgSize = $snmpMsgSize + (length($snmpVersion)/2) + (length($snmpCommStr)/2) + (length($snmpPDU)/2);
	my $snmpMsgSizeHex = sprintf("%02x",$snmpMsgSize);
	my $snmpMsg = "30".$snmpMsgSizeHex.$snmpVersion.$snmpCommStr.$snmpPDU; ### Paquete final construido
	return $snmpMsg;
}

sub snmpServer
{
	my $snmpIp=$_[0];
	my $snmpPort=161;
	my $snmpSocket;
	my $clientAddr;
	my $clientPort;
	my @times;
	my %peticiones=();
	open(CONFIG,"config/snmp.conf") or die "No se pudo abrir";
	while(<CONFIG>)
	{
		chomp($_);
		if ($_ =~ m/^Tarpiting.*/g){@times=split(' ',$_);}
	}
	close(CONFIG);
	$snmpSocket = IO::Socket::INET->new(LocalAddr => $snmpIp,
																			LocalPort => $snmpPort,
																					 Type => SOCK_DGRAM,
																					Proto => 'udp') or die "No se pudo crear el socket SNMP $! \n";
	sleep(1);
	print "  [#]...... Servidor ";
	print color("red"), "SNMP", color("reset");
	print " a la escucha en ";
	print color("cyan"), "$snmpIp", color("reset");
	print color("reset"), ":", color("reset");
	print color("magenta"), "$snmpPort ", color("reset");
	print color('reset'), "...... [#] \n";
	while(1)
	{
		my $dataRcv ="";
		$snmpSocket->recv($dataRcv,2048);
		my $dataHex = $dataRcv;
		$dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
		$clientAddr = $snmpSocket->peerhost();
		$clientPort = $snmpSocket->peerport();
		$peticiones{$clientAddr}++; #Aumenta peticiones por cada ip;
		my $response = snmpLogic($dataHex);
		my $contador=$peticiones{$clientAddr}-1;
		if ($contador==0)
		{
			$snmpSocket->send(pack("H*",$response));
		}
		elsif($contador<10)
		{
			usleep($times[$contador]);
			$snmpSocket->send(pack("H*",$response));
		}
		else
		{
			usleep($times[10]);
			$snmpSocket->send(pack("H*",$response));
		}
	}
	$snmpSocket->close();
}



sub dnsLogic
{
  my $dataHex = $_[0];
	my $file="config/dns.conf";
	my @arrayA;
	my @arrayMX;
	my @arrayNS;
	if(-f $file and -r $file) 
	{
		open(CONFIG,$file) or die "No se pudo abrir $file \n";
		while(<CONFIG>)
		{
			chomp($_);
			if(!($_ =~ m/^#.*/g) and ($_ =~ m/^A.*/i)){@arrayA=split(' ',$_); shift(@arrayA)}
			if(!($_ =~ m/^#.*/g) and ($_ =~ m/^MX.*/i)){@arrayMX=split(' ',$_); shift(@arrayMX)}
			if(!($_ =~ m/^#.*/g) and ($_ =~ m/^NS.*/i)){@arrayNS=split(' ',$_); shift(@arrayNS)}
		}
	}
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
		if(@arrayMX){$dataRes=$arrayMX[0];}
		else {$dataRes = "smtp.seguridad.unam.mx";}
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
		if(@arrayNS){$dataRes=$arrayNS[0];}
		else {$dataRes = "dns.seguridad.unam.mx";}
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
		if(@arrayA)
		{
			$dataRes=$arrayA[0];
			my @swap = split('\.',$dataRes);
			$dataRes="";
			foreach(@swap)
			{
				my $aux=sprintf("%02x",$_);
				$dataRes=$dataRes.$aux;
			}
		}
		else {$dataRes = sprintf("%02x%02x%02x%02x", rand 0xFF, rand 0xFF, rand 0xFF, rand 0xFF);} #Random IP
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
	open(CONFIG,"config/ntp.conf") or die "No se pudo abrir";
	  while(<CONFIG>){
			chomp($_);
			if ($_ =~ m/^Tarpiting.*/g){
				@times=split(' ',$_);
			}
		}
	close(CONFIG);
	$dnsSocket = IO::Socket::INET->new(LocalAddr => $dnsIp,
                                   	 LocalPort => $dnsPort,
                                     	    Type => SOCK_DGRAM,
                                       	 Proto => 'udp') or die "No se pudo crear el DNS socket $! \n";
	sleep(1);
	print "  [\$]...... Servidor ";
	print color("red"), "DNS", color("reset");
	print " a la escucha en ";
	print color("cyan"), "$dnsIp", color("reset");
	print color("reset"), ":", color("reset");
	print color("magenta"), "$dnsPort ", color("reset");
	print color('reset'), "...... [\$] \n";
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
			$dnsSocket->send(pack("H*",$response));
		}
		elsif($contador<10){
			usleep($times[$contador]);
			$dnsSocket->send(pack("H*",$response));
		}
		else{
			usleep($times[10]);
			$dnsSocket->send(pack("H*",$response));
		}
	}
	$dnsSocket->close();
}


sub ntpLogic{

		my $ntpIP=shift;
		my $dataRcv=shift;
		my $ntpRespond="";
		my ($ReceiveSec, $ReceiveF) = gettimeofday();
		$ReceiveSec+=2208988800; #Equivalente en segundos de 70 años
		$ReceiveSec = sprintf("%x",$ReceiveSec); #Conversion a hexadecimal de 4 bytes
		$ReceiveF = sprintf("%08x",$ReceiveF); #Conversion a hexadecimal de 4 bytes agregando bytes faltantes
		my $dataHex = $dataRcv;
		$dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
		my @hexData=($dataHex =~ m/../g ); #Arreglo de bytes
		$ntpRespond.="24"; #LI - No warning; Version NTP4; Mode - Server
		$ntpRespond.="02"; #Primary Interface
		$ntpRespond.= $hexData[2]; # Poll Interval
		$ntpRespond.="fa"; # Clock Precision
		$ntpRespond.="00010000"; #Root Delay - 1 segundo
		$ntpRespond.="000005cb"; #Root Dispersion 0.0226 segundos
		my @ip = split('\.',$ntpIP);
		for (my $i=0;$i<4;$i++){
			$ntpRespond.=sprintf("%02x",$ip[$i]);
		}
		my ($ReferSec, $ReferF) = gettimeofday();
		$ReferSec+=2208988800; #Equivalente en segundos de 70 años
		$ReferSec = sprintf("%x",$ReferSec); #Conversion a hexadecimal de 4 bytes
		$ReferF = sprintf("%08x",$ReferF);
		$ntpRespond.="$ReferSec";
		$ntpRespond.="$ReferF";
		for (my $i=40;$i<48;$i++){
			$ntpRespond.=$hexData[$i];
		}
		$ntpRespond.="$ReceiveSec";
		$ntpRespond.="$ReceiveF";
		my ($TransSec, $TransF) = gettimeofday();
		$TransSec+=2208988800; #Equivalente en segundos de 70 años
		$TransSec = sprintf("%x",$TransSec); #Conversion a hexadecimal de 4 bytes
		$TransF = sprintf("%08x",$TransF);
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
	open(CONFIG,"config/ntp.conf") or die "No se pudo abrir";
	  while(<CONFIG>){
			chomp($_);
			if ($_ =~ m/^Tarpiting.*/g){
				@times=split(' ',$_);
			}
		}
	close(CONFIG);
	$ntpSocket = IO::Socket::INET->new(LocalPort => $ntpPort,
																		 LocalAddr => $ntpIP,
																		 			Type => SOCK_DGRAM,
																				 Proto => 'udp') or die "No se pudo crear el socket NTP $! \n";
	sleep(1);
	print "  [&]...... Servidor ";
	print color("red"), "NTP", color("reset");
	print " a la escucha en ";
	print color("cyan"), "$ntpIP", color("reset");
	print color("reset"), ":", color("reset");
	print color("magenta"), "$ntpPort ", color("reset");
	print color('reset'), "...... [&] \n";
	while(1)
	{	
		my $ntpRespond="";
		my $dataRcv ="";
		$ntpSocket->recv($dataRcv,2048);
		$ntpRespond=ntpLogic($ntpIP,$dataRcv);
		$clientAddr = $ntpSocket->peerhost();
		$peticiones{$clientAddr}++; #Aumenta peticiones por cada ip;
		my $contador=$peticiones{$clientAddr}-1;
		if ($contador==0){
			$ntpSocket->send(pack("H*",$ntpRespond));
		}
		elsif($contador<10){
			usleep($times[$contador]);
			$ntpSocket->send(pack("H*",$ntpRespond));
		}
		else{
			usleep($times[10]);
			$ntpSocket->send(pack("H*",$ntpRespond));
		}
		
	}
	$ntpSocket->close();
}


sub netbiosLogic{
	my $dataHex=shift;
	my $equipo=shift;
	chop($equipo);
	my $i=0;
	my @hexData=($dataHex =~ m/../g ); #Arreglo de bytes
	my $tmp='';
	foreach my $byte (@hexData){
		if ($i==2){$tmp.="84";} 
		elsif ($i==3){$tmp.="00";}
		elsif ($i==4){$tmp.="00";}
		elsif ($i==5){$tmp.="00";}
		elsif ($i==6){$tmp.="00";}
		elsif ($i==7){$tmp.="01";}
		else{$tmp.=$byte;}
		$i++;
	}
	$tmp.="00000000";# TTL
	$tmp.="009b06";# Data Length and Number of names
	$equipo=~ s/(.)/sprintf("%02x",ord($1))/eg;
	my $t1=(length($equipo)/2);
	for (my $i=0;$i<15-$t1;$i++){
		$equipo.="20";
	}
	$tmp.=$equipo;# NombreEquipo
	$tmp.="004400574f524b47524f555020202020202000c400"; #Datos adicionales, Workgroup
	$tmp.=$equipo;# NombreEquipo
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
	open(CONFIG,"config/netbios.conf") or die "No se pudo abrir";
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
	$nbSocket = IO::Socket::INET->new(LocalPort => $nbPort,
																		Type => SOCK_DGRAM,
																		LocalAddr => $nbIP,
																		Proto => 'udp') or die "No se pudo crear el socket NETBIOS $! \n";
	sleep(1);
	print "  [^]...... Servidor ";
	print color("red"), "NETBIOS", color("reset");
	print " a la escucha en ";
	print color("cyan"), "$nbIP", color("reset");
	print color("reset"), ":", color("reset");
	print color("magenta"), "$nbPort ", color("reset");
	print color('reset'), "...... [^] \n";
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
			$nbSocket->send(pack("H*",$netbiosData));
		}
		elsif($peticiones{$clientAddr}<10){
			usleep($times[$peticiones{$clientAddr}]);
			$nbSocket->send(pack("H*",$netbiosData));
		}
		else{
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
	open(CONFIG,"config/ssdp.conf") or die "No se pudo abrir";
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
	open(CONFIG,"config/ssdp.conf") or die "No se pudo abrir";
	  while(<CONFIG>){
			chomp($_);
			if ($_ =~ m/^Tarpiting.*/g){
				@times=split(' ',$_);
			}
		}
	close(CONFIG);
	$ssdpSocket = IO::Socket::INET->new(LocalPort => $ssdpPort,
																			Type => SOCK_DGRAM,
																			LocalAddr => $ssdpIP,
																			Proto => 'udp') or die "No se pudo crear el socket SSDP $! \n";
	sleep(1);
	print "  [>]...... Servidor ";
	print color("red"), "SSDP", color("reset");
	print " a la escucha en ";
	print color("cyan"), "$ssdpIP", color("reset");
	print color("reset"), ":", color("reset");
	print color("magenta"), "$ssdpPort ", color("reset");
	print color('reset'), "...... [<] \n";
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
			$ssdpSocket->send($ssdpData);
		}
		elsif($contador<10){
			usleep($times[$contador]);
						$ssdpSocket->send($ssdpData);
		}
		else{
			usleep($times[10]);
						$ssdpSocket->send($ssdpData);
		}
	}
	$ssdpSocket->close();
}



my @threads;
print "Iniciando servidores ";
print color("blue"), "CHARGEN\n", color("reset");
my @chargenIp = ipParser("config/chargen.conf");
if(@chargenIp)
{
	shift(@chargenIp);
	foreach(@chargenIp)
	{
		my $hilo=threads->new(\&chargenServer,$_);
		push(@threads,$hilo);
	}
}
print "Iniciando servidores ";
print color("red"), "QOTD\n", color("reset");
my @qotdIp = ipParser("config/qotd.conf");
if(@qotdIp)
{
	shift(@qotdIp);
	foreach(@qotdIp)
	{
		my $hilo=threads->new(\&qotdServer,$_);
		push(@threads,$hilo);
	}
}
print "Iniciando servidores ";
print color("blue"), "DNS\n", color("reset");
my @dnsIp = ipParser("config/dns.conf");
if(@dnsIp)
{
	shift(@dnsIp);
	foreach(@dnsIp)
	{
		my $hilo=threads->new(\&dnsServer,$_);
		push(@threads,$hilo);
	}
}

print "Iniciando servidores ";
print color("red"), "NTP\n", color("reset");
my @ntpIp = ipParser("config/ntp.conf");
if(@ntpIp)
{
	shift(@ntpIp);
	foreach(@ntpIp)
	{
		my $hilo=threads->new(\&ntpServer,$_);
		push(@threads,$hilo);
	}
}

print "Iniciando servidores ";
print color("blue"), "NETBIOS\n", color("reset");
my @netbiosIp = ipParser("config/netbios.conf");
if(@netbiosIp)
{
	shift(@netbiosIp);
	foreach(@netbiosIp)
	{
		my $hilo=threads->new(\&netbiosServer,$_);
		push(@threads,$hilo);
	}
}

print "Iniciando servidores ";
print color("red"), "SSDP\n", color("reset");
my @ssdpIp = ipParser("config/ssdp.conf");
if(@ssdpIp)
{
	shift(@ssdpIp);
	foreach(@ssdpIp)
	{
		my $hilo=threads->new(\&ssdpServer,$_);
		push(@threads,$hilo);
	}
}

print "Iniciando servidores ";
print color("blue"), "SNMP\n", color("reset");
my @snmpIp = ipParser("config/snmp.conf");
if(@snmpIp)
{
	shift(@snmpIp);
	foreach(@snmpIp)
	{
		my $hilo=threads->new(\&snmpServer,$_);
		push(@threads,$hilo);
	}
}
sleep(10);
print "#########################################################################################\n\n\n";
foreach (@threads) { my $id = $_->join; }
