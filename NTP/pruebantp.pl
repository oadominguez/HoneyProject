use IO::Socket;

print GetNTPTime('ntp1.cs.wisc.edu');

sub GetNTPTime{
    my $host = shift;
    my $timeout = 2;
    my $sock = IO::Socket::INET->new(
        Proto => 'udp',
        PeerPort => 123,
        PeerAddr => $host,
      Timeout => $timeout
    )    or do {warn "Can't contact $host\n"; return 0};
    my $ntp_msg = pack("B8 C3 N11", '00100011', (0)x14);
    $sock->send($ntp_msg) or do {warn "Can't send NTP msg."; return 0};
    my $rin='';
    vec($rin, fileno($sock), 1) = 1;
    select(my $rout=$rin, undef, my $eout=$rin, $timeout) or do {warn "No answer from $host"; return 0};
    $sock->recv($ntp_msg, length($ntp_msg))
        or do {warn "Receive error from $host: ($!)"; return 0};
    my ($LIVNMode, $Stratum, $Poll, $Precision,
            $RootDelay, $RootDispersion, $RefIdentifier,
            $Reference, $ReferenceF, $Original, $OriginalF,
            $Receive, $ReceiveF, $Transmit, $TransmitF
        )    = unpack('a C2 c1 N8 N N B32', $ntp_msg);
    print "$Receive\n";
    $Receive -= 2208988800;
    print "$Receive\n";
    print "$ReceiveF\n";
    my $NTPTime = $Receive + $ReceiveF / 65536 / 65536;
    $RefIdentifier = unpack('A4', $RefIdentifier);
    my $LI = vec($LIVNMode, 3, 2);
    my $VN = unpack("C", $LIVNMode & "\x38") >> 3;
    my $Mode = unpack("C", $LIVNMode & "\x07");
    $sock->close;
    if ($RefIdentifier ne '1280') {
        return $NTPTime
    } else {
        return 0
    }
}
