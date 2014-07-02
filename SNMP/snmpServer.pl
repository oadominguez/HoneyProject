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
	#### FALTA CONCATENAR EL TAMAÑO TOTAL #######
	my $version = substr($dataHex,8,2);
	my $snmpVersion="0201".$version; ## Concatenamos primera capa: SNMP Version
	my $commSize = (sprintf("%d",hex(substr($dataHex,12,2)))*2);
	my $community = substr($dataHex,14,$commSize);
	my $snmpCommStr ="04".substr($dataHex,12,2).$community;  #Concatenamos segunda capa: SNMP Community String
	#### CONCATENAR TAMAÑO DE PDU ###
	my $requestSize = (sprintf("%d",hex(substr($dataHex,14+$commSize+6,2)))*2); ## tamaño del requestID
	my $requestID = substr($dataHex,14+$commSize+8,$requestSize); ## se recorre el tamaño de las capas
	my $snmpRequest = "02".substr($dataHex,14+$commSize+6,2).$requestID;
	my $snmpError = "020100";
	my $snmpErrorIndex = "020100";
	my $oidSize = (sprintf("%d",hex(substr($dataHex,22+$commSize+$requestSize+22,2)))*2); ## tamaño del oid
	my $oid = substr($dataHex,22+$commSize+$requestSize+24,$oidSize);
	my $snmpOid = "06".substr($dataHex,44+$commSize+$requestSize,2).$oid;
	##### VALOR, AJUSTARLO AL ARCHIVO DE CONFIGURACION ##### 
	my $value = "0a0b0c0d0e0f";  
	my $valueSize = sprintf("%02x",(length($value)/2));
	my $snmpValue = "04".$valueSize.$value; # Respuesta de tipo octect String
	######### CRAFTING DEL PAQUETE #####################
	my $snmpVarBindSize=0; #Inicializamos el tamaño
	$snmpVarBindSize = $snmpVarBindSize + (length($snmpOid)/2); ## agregamos tamaño del oid
	$snmpVarBindSize = $snmpVarBindSize + (length($snmpValue)/2); ## agregamos tamaño del valor
	my $snmpVarBindSizeHex = sprintf("%02x",$snmpVarBindSize);
	my $snmpVarBind="30".$snmpVarBindSizeHex.$snmpOid.$snmpValue; ## CAPA de varbind lista
	my $snmpVarBindListSize = 0; # inicializamos el tamaño
	$snmpVarBindListSize = $snmpVarBindListSize + (length($snmpVarBind)/2);
	my $snmpVarBindListSizeHex = sprintf("%02x",$snmpVarBindListSize);
	my $snmpVarBindList = "30".$snmpVarBindListSizeHex.$snmpVarBind;  ## CAPA de varbind list lista
	my $snmpPDUSize=0; ## Inicializamos el tamaño
	$snmpPDUSize = $snmpPDUSize + (length($snmpRequest)/2) +(length($snmpError)/2);
	$snmpPDUSize = $snmpPDUSize + (length($snmpErrorIndex)/2) +(length($snmpVarBindList)/2);
	my $snmpPDUSizeHex = sprintf("%02x",$snmpPDUSize);
	my $snmpPDU = "a2".$snmpPDUSizeHex.$snmpRequest.$snmpError.$snmpErrorIndex.$snmpVarBindList; # CAPA snmp PDU lista
	my $snmpMsgSize = 0; #Inicializamos el tamaño 
	$snmpMsgSize = $snmpMsgSize + (length($snmpVersion)/2) + (length($snmpCommStr)/2) + (length($snmpPDU)/2);
	my $snmpMsgSizeHex = sprintf("%02x",$snmpMsgSize);
	my $snmpMsg = "30".$snmpMsgSizeHex.$snmpVersion.$snmpCommStr.$snmpPDU; ### Paquete final construido
	print "VERSION LAYER: $snmpVersion \n";
	print "COMMUNITY LAYER: $snmpCommStr \n";
	print "REQUEST SUBLAYER: $snmpRequest \n";
	print "ERROR SUBLAYER: $snmpError \n";
	print "ERROR INDEX SUBLAYER: $snmpErrorIndex \n";
	print "OID SUBLAYER: $snmpOid \n";
	print "VALUE SUBLAYER: $snmpValue \n";
	print "VARBIND SUBLAYER: $snmpVarBind\n";
	print "VARBINDLIST SUBLAYER: $snmpVarBindList\n";
	print "SNMP PDU LAYER: $snmpPDU \n";
	print "SNMP PACKET: $snmpMsg \n";
	print "MSG SIZE: $snmpMsgSize \n";
	return $snmpMsg;
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
	my $response = snmpLogic($dataHex);
	$snmpSocket->send(pack("H*",$response));
}
$snmpSocket->close();
