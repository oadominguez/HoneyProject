#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;

my $dnsIp='127.0.0.1';
my $dnsPort=53;
my $dnsSocket;
my $clientAddr;
my $clientPort;

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
		my $tail = "c012"; # Cola obligatoria 
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
		my $tail = "c012";
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

print "Creando DNS Socket...[+] \n";
# Creamos el Socket
$dnsSocket = IO::Socket::INET->new(LocalAddr => $dnsIp,
																	 LocalPort => $dnsPort,
																				Type => SOCK_DGRAM,
																			 Proto => 'udp') or die "No se pudo crear el socket UDP $! \n";
print "UDP Socket Creado...[+] \n";
print "Servidor DNS a la escucha en UDP bajo puerto $dnsPort\n";
while(1)
{
	my $dataRcv ="";
	$dnsSocket->recv($dataRcv,2048);
	my $dataHex = $dataRcv;
	$dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
	$clientAddr = $dnsSocket->peerhost();
	$clientPort = $dnsSocket->peerport();
	#print "\n $clientAddr : $clientPort dice: $dataRcv \n";
	#print "RAW INPUT: $dataHex";
	my $response = dnsLogic($dataHex);
	$dnsSocket->send(pack("H*",$response));
}
$dnsSocket->close();
