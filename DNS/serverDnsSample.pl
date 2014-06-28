#!/usr/bin/perl

use strict;
use warnings;
use Net::DNS::Nameserver;

sub reply_handler 
{
	my ($qname, $qclass, $qtype, $peerhost,$query,$conn) = @_;
	my ($rcode, @ans, @auth, @add);
	print "Received query from $peerhost to ". $conn->{sockhost}. "\n";
	$query->print;
	if ($qtype eq "A" && $qname eq "foo.example.com" ) 
	{
		my ($ttl, $rdata) = (3600, "10.1.2.3");
		my $rr = new Net::DNS::RR("$qname $ttl $qclass $qtype $rdata");
		push @ans, $rr;
		$rcode = "NOERROR";
	}
	elsif($qname eq "foo.example.com") 
	{
		$rcode = "NOERROR";
	}
	else
	{
				$rcode = "NXDOMAIN";
	}
# mark the answer as authoritive (by setting the 'aa' flag
	return ($rcode, \@ans, \@auth, \@add, { aa => 1 });
}

my $ns = new Net::DNS::Nameserver( LocalPort    => 5353,
																	 ReplyHandler => \&reply_handler,
																	 Verbose      => 1 ) or die "couldn't create nameserver object\n";
$ns->main_loop;

