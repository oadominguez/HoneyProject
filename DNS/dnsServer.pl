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
	print "EN LOGICA $dataHex \n";
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
	if($type == "0001")
	{
		print "PETICION DE TIPO A \n";
		$tamRes = "0004";
		$dataRes = sprintf("%02x%02x%02x%02x", rand 0xFF, rand 0xFF, rand 0xFF, rand 0xFF);
		print "TAMAÑO RESPUESTA $tamRes";
		print "RESPUESTA $dataRes";
	}
	elsif($type == "000f")
	{
		print "PETICION DE TIPO MX \n";
		$tamRes = "0010";	
	}
	elsif($type == "0002")
	{
		print "PETICION DE TIPO NS \n";
		$tamRes = "0010";	
	}
	my $response = $ID.$flags.$numPreg.$numResp.$numRespAuth.$numRespAddit.$dataQuery;
	print "ID $ID \n";
	print "FLAGS $flags \n";
	print "NUMPREG $numPreg \n";
	print "NUMRESP $numResp \n";
	print "NUMRESPAUTH $numRespAuth \n";
	print "NUMRESPADDIT $numRespAddit \n";
	print "DATAQUERY $dataQuery \n";
	print "TYPE $type \n";
	print "CLASS $class \n";
	my $pointer = "c00c";
	my $tipoRes = $type;
	my $classRes = $class;
	my $ttl = "00000007"; #Segundos de vida
	print "POINTER $pointer \n";
	print "TIPORES $tipoRes \n";
	print "CLASSRES $classRes \n";
	print "TTL $ttl \n";
	print "TAMRES $tamRes \n";
	print "DATARES $dataRes \n";
	$response = $response.$pointer.$tipoRes.$classRes.$ttl.$tamRes.$dataRes;
	print "CRAFT PACKET $response \n";
	#my $tamRes = "0004";  # A -> '4'
	#$nbSocket->send(pack("H*",$tmp));
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
	print "\n $clientAddr : $clientPort dice: $dataRcv \n";
	print "RAW INPUT: $dataHex";
	my $response = dnsLogic($dataHex);
	$dnsSocket->send(pack("H*",$response));
}
$dnsSocket->close();
