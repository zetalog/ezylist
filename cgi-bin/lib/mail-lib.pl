
############################################################################
#
# eZyList Pro version 1.0 by Lv Zheng.
# Created by:
#		Lv 'Zetalog' Zheng
#		eZyScripts.Com
#		http://www.ezyscripts.com/
# Modified by:
#		Lv Zheng
#		zhenglv@hotmail.com
#
# Initiated:      9/12/2002 Version 1.0
#
# Copyright (c) 2002, 2003, eZyScripts.Com. All rights reserved.
# This software is protected by the national and international copyright 
# laws that pertain to computer software. You may not loan, sell, rent,
# lease, give, sub license, or otherwise transfer the software (or any copy).  
# 
# Disclaimer
#
# By using the script(s), you are supposed to agree and understand that
# the writers are not responsible for any damages caused under any
# conditions due to the malfunction or bugs from the script(s). Please
# use at your own risk.
#
############################################################################

############################################################################
## IT IS ILLEGAL FOR YOU TO VIEW, EDIT, COPY, DELETE, 
## TRANSFER, OR IN ANY WAY MANIPULATE THE CODE BELOW 
## THIS LINE.
############################################################################

## Get started.  Set some variables
$rfc_date = &mail_create_date;
$SMTP = 0;
$MAIL_ERROR = 0;

## If needed require the IO::Socket module
if (($mailtype eq 'dns') || ($mailtype eq 'smtp')) { 
	eval { require IO::Socket; };
	if ($@) { &error(101, __LINE__, __FILE__, "IO/Socket.pm"); }
	eval { require Sys::Hostname; };
	if ($@) { &error(101, __LINE__, __FILE__, "Sys/Hostname.pm"); }
}
elsif ($mailtype ne 'sendmail') { &error(500, __LINE__, __FILE__, "Unknown mailer type, <b>$mailtype</b>"); }

################################################
## Send an e-mail from a file
################################################

sub mailmsg_from_file {
	my ($toaddr, $file, $from_addr, $from_name, $from_pass, %input) = @_;
	my ($verify, $message);
	
	## Verify both e-mail addresses
	if ($from_addr !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid sender e-mail address, <b>$from_addr</b>"); }
	$verify = &mail_verify($toaddr);
	return if $verify != 1;
	
	## Read message from file
	$message = &readfile($file);
	$message =~ s/^.+?\n//;
	
	## Prepare and send e-mail message
	$message = &mail_prepare_message($toaddr, $message, $from_addr, $from_name, %input);
	$success = &mail_send_message($toaddr, $from_addr, $from_name, $from_pass, $message, 0);
	
	return $success;
}

################################################
## Send an e-mail from a hash
################################################

sub mailmsg_from_hash {
	my (%input) = @_;
	my ($verify, $message);

	## Verify both e-mail addresses
	if ($input{'_FROM_ADDR'} !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid sender e-mail address, <b>$input{'_FROM_ADDR'}</b>"); }
	$verify = &mail_verify($input{'_TO'});
	return if $verify != 1;
	
	## Prepare and send e-mail message
	$message = &mail_prepare_message($input{'_TO'}, $input{'_MESSAGE'}, $input{'_FROM_ADDR'}, $input{'_FROM_NAME'}, %input);
	$success = &mail_send_message($input{'_TO'}, $input{'_FROM_ADDR'}, $input{'_FROM_NAME'}, $input{'_FROM_PASS'}, $message, 0);
	
	return $success;
}

################################################
## Send the e-mail message
################################################

sub mail_send_message {
	my ($toaddr, $from_addr, $from_name, $from_pass, $message, $open) = @_;

	if ($mailtype eq 'sendmail') {
		open MAIL, "|$mailprog -t" or &error(102, __LINE__, __FILE__);
		print MAIL "To: $toaddr\n";
		print MAIL $message;
		close MAIL or &error(102, __LINE__, __FILE__);
		$success = 1;
		
	} elsif ($mailtype eq 'smtp') {
		$success = &mail_send_smtp($mailprog, $toaddr, $from_addr, $from_name, $from_pass, $message, $open);
		
	} elsif ($mailtype eq 'dns') {
		my ($login, $domain) = split /\@/, $toaddr;
		my $mx = &mail_mx_lookup($domain);
		
		if ($mx eq '') { &mail_error($toaddr, $domain, 608); return 608; }
		$success = &mail_send_smtp($mx, $toaddr, $from_addr, $from_name, $from_pass, $message, $open);
	}
	
	&counter_increase("$datadir/ezylist.sent") if ($success == 1);
	return $success;

}

################################################
## Send bulk mail
################################################

sub mailmsg_bulk {
	my (%info) = @_;
	my ($count, $message, @recip, @merge);
		
	## Verify the sender address
	if ($in{'_FROM_ADDR'} !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid sender e-mail address, <b>$in{'_FROM_ADDR'}</b>"); }
	
	## Get some needed info from %info hash
	@recip = split /::/, $info{'_recipient'};
	@merge = split /::/, $info{'_merge'};

	## Prepare e-mail message
	$message = &mail_prepare_message($in{'_TO'}, $in{'_MESSAGE'}, $in{'_FROM_ADDR'}, $in{'_FROM_NAME'});
	
	## Send the e-mail message to all recipients
	$count=0;
	if (($mailtype eq 'sendmail') || ($mailtype eq 'smtp')) {
		while (@recip) {
			my ($toaddr, $open, $verify, $temp_message);
		
			## Make sure it's a valid e-mail address
			$toaddr = shift @recip;
			$verify = &mail_verify($toaddr);
			next if $verify != 1;
			
			## Replace all merge fields in message
			$temp_message = $message;
			foreach $field (@merge) {
				$temp_message =~ s/~$field~/$info{$toaddr}{$field}/gi;
			}
			
			## Keep the SMTP server open?
			if (@recip == 0) { $open = 0; }
			else { $open = 1; }
			
			## Send the e-mail messasge
			&mail_send_message($toaddr, $in{'_FROM_ADDR'}, $in{'_FROM_NAME'}, $in{'_FROM_PASS'}, $temp_message, $open);
			
			## See if we need to update processing
			my $num = $count; $num = ($num / 10);
			if ($num !~ /\./) { 
				&processing_update($count);
			}
		$count++; }
	}

	elsif ($mailtype eq 'dns') {
		my %recip = &mail_dns_sort(@recip);
		
		foreach $domain (keys %recip) {
			my ($mx, @toaddr);
			
			## Get needed info
			@toaddr = split /::/, $recip{$domain};
			$mx = &mail_mx_lookup($domain);
			if ($mx eq '') { &mail_error($toaddr, $domain, 608); next; }
		
			while (@toaddr) {
				my ($toaddr, $verify, $success, $open, $temp_message);
				
				## Set some variables
				$toaddr = shift (@toaddr);
				$verify = &mail_verify($toaddr);
				next if $verify != 1;
				
				## Replace all merge fields in message
				$temp_message = $message;
				foreach $field (@merge) {
					$temp_message =~ s/~$field~/$info{$addr}{$field}/gi;
				}
				
				## See if we need to keep the server open
				if (@toaddr == 0) { $open = 0; }
				else { $open = 1; }
				
				$success = &mail_send_smtp($mx, $toaddr, $in{'_FROM_ADDR'}, $from_name, $from_pass, $temp_message, $open);
				
				## See if we need to update processing
				if (($PROC == 1) && (($count / 10) !~ /\./)) {
					&processing_update($count);
				}

			$count++; }
		}
	}
				
	return $count;

}

################################################
## Send an e-mail message through SMTP server
################################################

sub mail_send_smtp {
	my ($server, $toaddr, $from_addr, $from_name, $from_pass, $message, $stay_open) = @_;
	my ($localhost, $response, $smtp_user, $smtp_pass, $server_auth);
	
	($server_auth = 1) if (defined $from_name && defined $from_pass && $from_name ne "" && $from_pass ne "");

	if ($server_auth == 1) {
		$smtp_user = mail_encode_base64($from_name);
		$smtp_pass = mail_encode_base64($from_pass);
	}

	## Get the local host
	$localhost = lc Sys::Hostname::hostname();
	$message =~ s/\n/\r\n/g;
	
	## Connect to the SMTP server
	unless ($SMTP == 1) {
		$socket = IO::Socket::INET->new(
			PeerAddr => $server, 
			PeerPort => 25, 
			Proto => 'tcp'
		);
		$SMTP = 1;
	}
		
	if (!$socket) { &mail_error($toaddr, $server, 601); return 601; }

	## Make sure SMTP server won't buffer
	select $socket; $|=1; select STDOUT;

	## Make sure it's an SMTP server
	$response = &mail_get_server_response;
	if ($response !~ /^220/) { &mail_error($toaddr, $server, 602); return 602; }
	
	if ($server_auth == 1) {
		## Say EHLO to the server
		print $socket "EHLO $localhost\r\n";
		$response = &mail_get_server_response;
		if ($response !~ /^250/ || ($response !~ /AUTH/)) { $server_auth = 0; }
	}

	## Say HELO to the server
	if ($server_auth == 0) {
		print $socket "HELO $localhost\r\n";
		$response = &mail_get_server_response;
		if ($response !~ /^250/) { &mail_error($toaddr, $server, 603); return 603; }
	}
	
	## Try to login to the server
	if ($server_auth == 1) {
		print $socket "AUTH LOGIN\r\n";
		$response = &mail_get_server_response;
		## 334 VXNlcm5hbWU6
		if ($response !~ /^334/) { &mail_error($toaddr, $server, 609); return 609; }
		print $socket $smtp_user;
		print "\n";
		$response = &mail_get_server_response;
		## 334 UGFzc3dvcmQ6
		if ($response !~ /^334/) { &mail_error($toaddr, $server, 609); return 609; }
		print $socket $smtp_pass;
		print "\n";
		$response = &mail_get_server_response;
		if ($response !~ /^235/) { &mail_error($toaddr, $server, 609); return 609; }
	}
	
	## Tell the server who the message is from
	print $socket "MAIL FROM: <$from_addr>\r\n";
	$response = &mail_get_server_response;
	if ($response !~ /^250/) { &mail_error($toaddr, $server, 604); return 604; }
	
	## Tell the server who the message is going to
	print $socket "RCPT TO: <$toaddr>\r\n";
	$response = &mail_get_server_response;
	if ($response =~ /^251/) { &mail_error($toaddr, $server, 620); return 620; }
	elsif ($response =~ /^450/) { &mail_error($toaddr, $server, 621); return 621; }
	elsif ($response =~ /^550/) { &mail_error($toaddr, $server, 622); return 622; }
	elsif ($response =~ /^551/) { &mail_error($toaddr, $server, 623); return 623; }
	elsif ($response =~ /^452/) { &mail_error($toaddr, $server, 624); return 624; }
	elsif ($response =~ /^553/) { &mail_error($toaddr, $server, 625); return 625; }
	elsif ($response =~ /^554/) { &mail_error($toaddr, $server, 626); return 626; }
	elsif ($response !~ /^250/) { &mail_error($toaddr, $server, 605); return 605; }
	
	## Start sending the message contents
	print $socket "DATA\r\n";
	$response = &mail_get_server_response;
	if ($response !~ /^354/) { &mail_error($toaddr, $server, 606); return 606; }
	
	## Send message to server
	print $socket "To: <$toaddr>\r\n";
	print $socket "$message\r\n";
	print $socket "\r\n.\r\n";
	
	## Close the server
	$response = &mail_get_server_response;
	if ($response !~ /^250/) { &mail_error($toaddr, $server, 607); return 607; }
	
	if ($stay_open == 1) { print $socket "RSET\r\n"; }
	else { 
		close $socket;
		$SMTP = 0;
	}

	return 1;
	
}

################################################
## Get response from SMTP server
################################################

sub mail_get_server_response {
	my $line = <$socket>;
	my $response = $line;

	while ($line =~ /^\d\d\d\-/) {
		$line = <$socket>;
		if ($line =~ /AUTH/i) {
			$response = $line;
		}
	}
	
	return $response;
}

################################################
## Prepare an e-mail message
################################################

sub mail_prepare_message {
	my ($toaddr, $message, $from_addr, $from_name, %input) = @_;
	my ($verify, $header, $message2);

	## Replace all merge fields in message
	while (($key, $value) = each %input) {
		$message =~ s/~$key~/$value/gi;
	}
	
	## Create the header for the message
	$header = "From: $from_name <$from_addr>\n";
	$header .= "Date: $rfc_date\n";
	if (exists $in{'_CC'}) { $header .= "Cc: $in{'_CC'}\n"; }
	if (exists $in{'_REPLY_TO'}) { $header .= "Reply-To: $in{'_REPLY_TO'}\n"; }
	$header .= "X-Mailer: eZyScripts.Com\n";
	$header .= "X-Mailer-Info: http://www.ezyscripts.com/\n";
	
	## If needed, wrap long lines
	if ($moptions[9] == 1) {
		my @message = split /\n/, $message;
		undef $message;
		
		foreach $line (@message) {
			$line =~ s/[\n\r\f]//g;
			while (length($line) > 60) {
				if ($line =~ s/^(.{60,80}?)\s//) {
					$message .= "$1\n";
				} else { last; }
			}
			$message .= "$line\n";
		}
	}
	
	$message2 = $header . $message;
	return $message2;
}

################################################
## Verify an e-mail address
################################################

sub mail_verify {
	my $addr = shift;
	
	if ($addr !~ /.*\@.*\..*/) {
		$MAIL_ERROR = 1;
		push @{$ERROR{'MAIL_INVALID'}}, (join "::", '600', $addr);
		return;
	} else { return 1; }
	
}

################################################
## Process a SMTP server error
################################################

sub mail_error {
	my ($addr, $server, $code) = @_;
	my $log = join "::", $code, $addr, $server;
	
	$MAIL_ERROR = 1;
	push @{$ERROR{'MAIL_SERVER'}}, $log;
	close $socket;
	
	return $code;
}

################################################
## Create the RFC date for e-mail message
################################################

sub mail_create_date {
	my ($date, $time, @days, @months);

	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime(time);
	@months = qw (Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	@days = qw (Sun Mon Tue Wed Thu Fri Sat);
	
	$year -= 100;
	$year = sprintf "%.3d", $year;
	$year = "2" . $year;

	$mday = sprintf "%.2d", $mday;
	$hour = sprintf "%.2d", $hour;
	$min = sprintf "%.2d", $min;
	$sec = sprintf "%.2d", $sec;

	$time = join ":", $hour, $min, $sec;
	$date = "$days[$wday], $mday $months[$mon] $year $time +0000";
	
	return $date;
}

################################################
## Sort a list of recipients, for DNS sending
################################################

sub mail_dns_sort {
	my (@recip) = @_;
	my (%recip);
	
	foreach $addr (@recip) {
		my ($user, $domain) = split /\@/, $addr;
		if (exists $recip{$domain}) { $recip{$domain} .= "::$addr"; }
		else { $recip{$domain} = $addr; }
	}
	
	return %recip;

}

################################################
## Get the MX records for a domain
################################################

sub mail_mx_lookup {
	my $domain = shift;
	my ($reqid, $byte2, $byte3, $request, $offset, $answer, $addr, $paddr);
	my ($top, $mxserver, $rname, $rtype, $rclass, @header);
	
	## Create the request
	$reqid = int(rand(65535));
	$byte2 = (0 << 7) | (0 << 3) | (0 << 2) | (0 << 1) | 1;
	$byte3 = (0 << 7) | 0;

	$request = pack("n C2 n4", $reqid, $byte2, $byte3, 1, 0, 0, 0);
	$offset = length ($request);
	
	$request .= &mail_mx_compress($domain, $offset);
	$request .= pack("n2", 15, 1);
	
	## Send the request to the name server
	$socket = IO::Socket::INET->new(
		PeerAddr => $mailprog, 
		PeerPort => 53,
		Timeout => 15, 
		Proto => 'udp'
	);
	
	if (!$socket) { &error(500, __LINE__, __FILE__, "Unable to connect to name server, $mailprog"); }
	
	$socket->send($request);
	$socket->recv($answer, 512);
	
	## Parse the answer
	@header = unpack("n C2 n4", $answer);
	$offset = 12;
	
	($rname, $offset) = &mail_mx_expand($answer, $offset);
	($rtype, $rclass) = unpack("\@$offset n2", $answer);
	$offset += 4;
	
	## Parse the MX records from answer
	$top = 10000;
	for ( 1 .. $header[4] ) {
		my ($mx, $pref);
		
		($mx, $pref, $offset) = &mail_mx_parserr($answer, $offset);
		if ($pref < $top) {
			$mxserver = $mx;
			$top = $pref;
		}
	}

	$mxserver = $domain if $mxserver eq '';
	return $mxserver;	
}

################################################
## Compress a domain name, for MX requests
################################################

sub mail_mx_compress {
	my ($name, $offset) = @_;
	my ($compname, @names);
	
	@names = split /\./, $name;
	while (@names) {
		my ($dname, $first, $length);
	
		$dname = join ".", @names;
		$first = shift @names;
		$length = length $first;
		
		$compname .= pack("C a*", $length, $first);
		$offset += $length + 1;		
	}

	$compname .= pack("C", 0);
	return $compname;	

}

################################################
## Expand a domain name, for MX requests
################################################

sub mail_mx_expand {
	my ($data, $offset) = @_;
	my ($name, $length, $datalength);
	$datalength = length($data);
	
	while (1) {
		$length = unpack("\@$offset C", $data);
		
		if ($length == 0) { $offset++; last; }
		elsif (($length & 0xc0) == 0xc0) {
			my ($ptr, $name2);
			
			$ptr = unpack("\@$offset n", $data);
			$ptr &= 0x3fff;
			($name2) = &mail_mx_expand($data, $ptr);
			
			$name .= $name2;
			$offset += 2;
			last;
		} else {
			$offset++;
			
			my $elem = substr($data, $offset, $length);
			$name .= "$elem.";
			$offset += $length;
		}
	}
	
	$name =~ s/\.$//;
	return ($name, $offset);
}

################################################
## Parse the RR record, for MX requests
################################################

sub mail_mx_parserr {
	my ($data, $offset) = @_;
	my ($name, $type, $class, $ttl, $rdlength, $pref, $mx);
		
	($name, $offset) = &mail_mx_expand($data, $offset);
	($type, $class, $ttl, $rdlength) = unpack("\@$offset n2 N n", $data);
	$offset += 10;

	$pref = unpack("\@$offset n", $data);
	$offset += 2;

	($mx) = &mail_mx_expand($data, $offset);
	$offset += ($rdlength - 2);

	return ($mx, $pref, $offset);
}

###################################3
## Encode a file
###################################3

sub mail_encode {
	my $filename = shift;
	my $contents = &readfile($filename);
	
	my $res = "";
	my $eol = "\n";

	pos($contents) = 0;        # thanks, Andreas!
	while ($contents =~ /(.{1,45})/gs) {
		$res .= substr(pack('u', $1), 1);
		chop($res);
	}
	$res =~ tr|` -_|AA-Za-z0-9+/|;

	# Fix padding at the end:
	my $padding = (3 - length($_[0]) % 3) % 3;
	$res =~ s/.{$padding}$/'=' x $padding/e if $padding;

	# Break encoded string into lines of no more than 76 characters each:
	$res =~ s/(.{1,76})/$1$eol/g if (length $eol);
	return $res;

}

###################################3
## Encode a buffer
###################################3

sub mail_encode_base64 {
	$contents = shift;

	my $res = "";
	my $eol = "\n";

	pos($contents) = 0;	# ensure start at the beginning
	while ($contents =~ /(.{1,45})/gs) {
		$res .= substr(pack('u', $1), 1);
		chop($res);
	}
	$res =~ tr|` -_|AA-Za-z0-9+/|;

	# fix padding at the end
	my $padding = (3 - length($contents) % 3) % 3;
	$res =~ s/.{$padding}$/'=' x $padding/e if $padding;

	# break encoded string into lines of no more than 76 characters each
	$res =~ s/(.{1,76})/$1$eol/g if (length $eol);
	return $res;
}


1;
