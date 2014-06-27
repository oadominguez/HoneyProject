 use POE::Component::Server::Chargen;

 my $self = POE::Component::Server::Chargen->spawn( 
        Alias => 'Chargen-Server',
        BindAddress => '127.0.0.1',
        BindPort => 7777,
        options => { trace => 1 },
 );
 
 POE::Kernel->run()
