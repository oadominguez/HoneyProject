#!/bin/bash
cpan -MCPAN -e 'install POE'
cpan -MCPAN -e 'install POE::Component::Server::Chargen'
cpan -MCPAN -e 'install Time::HiRes'
cpan -MCPAN -e 'install threads'

