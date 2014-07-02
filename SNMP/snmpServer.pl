#!/usr/bin/perl -w
use strict;
use IO::Socket::INET;

my $snmpIp='127.0.0.1';
my $snmpPort=161;
my $snmpSocket;
my $clientAddr;
my $clientPort;
sub snmpLogic
{
	my $dataHex = $_[0];
	#my $tam = sprintf("%d",hex(substr($dataHex,6,2)));
	#print "tamaño $tam \n"
	my $snmpMsgSize=0;
	my $snmpMsg="30";  ## secuencia que marca el inicio del paquete
	#### FALTA CONCATENAR EL TAMAÑO TOTAL #######
	my $version = substr($dataHex,8,2);
	my $snmpVersion="0201".$version; ## Concatenamos primera capa: SNMP Version
	$snmpMsgSize = $snmpMsgSize + (length($snmpVersion)/2); ## agregamos tamaño de primera capa
	my $commSize = (sprintf("%d",hex(substr($dataHex,12,2)))*2);
	my $community = substr($dataHex,14,$commSize);
	my $snmpCommStr ="04".substr($dataHex,12,2).$community;  #Concatenamos segunda capa: SNMP Community String
	$snmpMsgSize = $snmpMsgSize + (length($snmpCommStr)/2); ## agregamos tamaño de segunda capa
	my $snmpPDU="a2"; ## Get response de la PDU 
	my $snmpPDUSize=0;
	#### CONCATENAR TAMAÑO DE PDU ###
	$snmpMsgSize = $snmpMsgSize + 2; ## agrega el tamaño de type:PDU y del size:PDU
	my $requestSize = (sprintf("%d",hex(substr($dataHex,14+$commSize+6,2)))*2); ## tamaño del requestID
	my $requestID = substr($dataHex,14+$commSize+8,$requestSize); ## se recorre el tamaño de las capas
	my $snmpRequest = "02".substr($dataHex,14+$commSize+6,2).$requestID;
	$snmpMsgSize = $snmpMsgSize + (length($snmpRequest)/2); ## agregamos tamaño de RequestID
	$snmpPDUSize = $snmpPDUSize + (length($snmpRequest)/2); ## agregamos tamaño de RequestID
	my $snmpError = "020100";
	my $snmpErrorIndex = "020100";
	$snmpMsgSize = $snmpMsgSize + (length($snmpError)/2); ## agregamos tamaño del error
	$snmpPDUSize = $snmpPDUSize + (length($snmpError)/2); ## agregamos tamaño del error 
	$snmpMsgSize = $snmpMsgSize + (length($snmpErrorIndex)/2); ## agregamos tamaño del error index
	$snmpPDUSize = $snmpPDUSize + (length($snmpErrorIndex)/2); ## agregamos tamaño del error index
	#my $snmpVarBindList = "30"; ### Inicia la varbind list
	#my $snmpVarBindListSize = 0;
	#my $snmpVarBind = "30";
	#my $snmpVarBindSize = 0;
	#$snmpVarBindListSize = $snmpVarBindListSize + 2; 
	$snmpMsgSize = $snmpMsgSize + 4; ## agrega el tamaño de type:VarBindList & VarBind y sus respectivos size
	$snmpPDUSize = $snmpPDUSize + 4; ## agrega el tamaño de type:VarBindList & VarBind y sus respectivos size
	my $oidSize = (sprintf("%d",hex(substr($dataHex,22+$commSize+$requestSize+22,2)))*2); ## tamaño del oid
	my $oid = substr($dataHex,22+$commSize+$requestSize+24,$oidSize);
	my $snmpOid = "06".substr($dataHex,44+$commSize+$requestSize,2).$oid;
	$snmpMsgSize = $snmpMsgSize + (length($snmpOid)/2); ## agregamos tamaño del oid
	$snmpPDUSize = $snmpPDUSize + (length($snmpOid)/2); ## agregamos tamaño del oid
	#$snmpVarBindListSize = $snmpVarBindListSize + (length($snmpOid)/2); ## agregamos tamaño del oid
	#$snmpVarBindSize = $snmpVarBindSize + (length($snmpOid)/2); ## agregamos tamaño del oid
	##### VALOR, AJUSTARLO AL ARCHIVO DE CONFIGURACION 
	my $value = "0a0b0c0d0e0f";  
	my $valueSize = sprintf("%02x",(length($value)/2));
	my $snmpValue = "04".$valueSize.$value; # Respuesta de tipo octect String
	#$snmpVarBindSize = $snmpVarBindSize + (length($snmpValue)/2); ## agregamos tamaño del oid
	#my $snmpVarBindSizeHex = sprintf("%02x",$snmpVarBindSize);
	######### CRAFTING DEL PAQUETE #####################
	$snmpVarBind=$snmpVarBind.$snmpVarBindSizeHex.$snmpOid.$snmpValue;
	$snmpVarBindListSize = length($snmpVarBind)/2;
	my $snmpVarBindListSizeHex = sprintf("%02x",$snmpVarBindListSize);
	$snmpVarBind

	print "VERSION LAYER: $snmpVersion \n";
	print "COMMUNITY LAYER: $snmpCommStr \n";
	print "REQUEST SUBLAYER: $snmpRequest \n";
	print "ERROR SUBLAYER: $snmpError \n";
	print "ERROR INDEX SUBLAYER: $snmpErrorIndex \n";
	print "OID SUBLAYER: $snmpOid \n";
	print "VALUE SUBLAYER: $snmpValue \n";
	print "VARBIND LAYER: $snmpVarBind\n";
	print "MSG SIZE: $snmpMsgSize \n";
}
print "Creando SNMP Socket...[+] \n";
# Creamos el Socket
$snmpSocket = IO::Socket::INET->new(LocalAddr => $snmpIp,
																		LocalPort => $snmpPort,
																				 Type => SOCK_DGRAM,
																				Proto => 'udp') or die "No se pudo crear el socket SNMP $! \n";
print "SNMP Socket Creado...[+] \n";
print "Servidor SNMP a la escucha en UDP bajo puerto $snmpPort\n";
while(1)
{
	my $dataRcv ="";
	$snmpSocket->recv($dataRcv,2048);
	my $dataHex = $dataRcv;
	$dataHex =~ s/(.)/sprintf("%02x",ord($1))/eg;
	$clientAddr = $snmpSocket->peerhost();
	$clientPort = $snmpSocket->peerport();
	print "\n $clientAddr : $clientPort dice: $dataRcv \n";
	print "RAW INPUT: $dataHex\n";
	snmpLogic($dataHex);
}
$snmpSocket->close();
