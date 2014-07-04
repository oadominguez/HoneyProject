#!/bin/bash
echo "Script que instala dependencias mediante CPAN para HoneyProject"
echo "Instalando dependencias necesarias para HoneyProject"
sleep 2
cpan -i POE
cpan -i Time::HiRes
cpan -i IO::Socket::INET
cpan -i Term::ANSIColor
