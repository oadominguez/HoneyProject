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
		while(1){$chargenSocket->send($dataSend);}
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
  	$dnsSocket->send(pack("H*",$response));
	}
	$dnsSocket->close();
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
foreach (@threads) { my $id = $_->join; }
