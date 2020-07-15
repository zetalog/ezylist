#!/usr/bin/perl -w
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

## Full path to the ezylist.conf file
$conf = "~datadir~/ezylist.conf";

############################################################################
## IT IS ILLEGAL FOR YOU TO VIEW, EDIT, COPY, DELETE, 
## TRANSFER, OR IN ANY WAY MANIPULATE THE CODE BELOW 
## THIS LINE.
############################################################################

require $conf;
require "$cgidir/lib/mail-lib.pl";

%headers;
$FLOCK = 1;

# Connect mysql database
if ($dbdriver eq "mysql") {
	eval { require DBI; };
	if ($@) { &error("Unable to load perl module DBI"); }
	eval { require "$cgidir/lib/mysql-lib.pl"; };
	if ($@) { &error("Unable to load mysql library, $cgidir/lib/mysql-lib.pl"); }
	$dbh = DBI->connect("DBI:$dbdriver:$dbname:$dbhost", $dbuser, $dbpassword)
	or &error("Unable to connect to $dbname at $dbhost");
}

require "$cgidir/dbs/$dbdriver.pl";;

## Parse the incoming message
&parse_message;

## Get needed user and list info
&get_info;

## Add entry to the mailing list
&add_entry unless $listid eq '';

## Send auto reply
&send_reply;

## If needed, add a log, never reach
&add_log if $moptions[5] == 1;

## Exit without any errors
exit(0);

################################################
## Parse the incoming message
################################################

sub parse_message {
	my ($message, $lastkey, $line, $header, @lines);
	
	## Get the incoming message
	while (<>) { $message .= $_; }
	($header, $body) = split /\n\n/, $message, 2;

	## Parse the header of the message
	@lines = split /\n/, $header;
	foreach $line (@lines) {
		if ($line =~ /:/) {
			my ($key, $value) = $line =~ /^(.+)?\:\s*(.+)/;
			$headers{"\L$key\E"} = $value;
			$lastkey = lc($key);
		} else { $headers{$lastkey} .= "\n$line"; }
	}
	
	exit(0) unless exists $headers{'to'};
	exit(0) unless exists $headers{'from'};
	exit(0) unless exists $headers{'subject'};

	## Get needed info from header
	if ($headers{'to'} =~ /<.+>/) { ($toaddr) = $headers{'to'} =~ /<(.+?)>/; }
	else { $toaddr = $headers{'to'}; }
	$toaddr = lc($toaddr);

	if ($headers{'from'} =~ /<.+>/) { ($from_email) = $headers{'from'} =~ /<(.+?)>/; }
	else { $from_email = $headers{'from'}; }
	
	if ($headers{'from'} =~ /\".+?\"/) { ($from_name) = $headers{'from'} =~ /\"(.+?)\"/; }
	$subject = $headers{'subject'};

	## Make sure we have all needed info
	exit(0) unless $toaddr =~ /.*\@.*\..*/;
	exit(0) unless $from_email =~ /.*\@.*\..*/;
	
	exit(0) if lc($toaddr) eq lc($admin_email);
	exit(0) if lc($toaddr) eq lc($dump_email);
	exit(0) if lc($toaddr) eq lc($support_email);

	return 1;
	
}

################################################
## Get extension of a user
################################################

sub get_ext {
	my $user = shift;
	
	my $DBSUB = $dbdriver . "_get_ext";
	my @exts = &$DBSUB($user);
	return @exts;
}

################################################
## Get some info from a user's profile
################################################

sub get_variable {
	my ($user, @vars) = @_;

	my $DBSUB = $dbdriver . "_get_variable";
	return &$DBSUB($user, @vars);
}

################################################
## Get needed user and list info
################################################

sub get_info {
	my ($username, $domain, $found, $ok, $ar, @message, @conf);

	## Get user from autoresponder address
	($username, $domain) = split /\@/, $toaddr;
	if (!-e "$datadir/ar/$domain/$username") {
		$in{'_TO'} = $dump_email;
		$in{'_FROM_ADDR'} = $from_email;
		$in{'_FROM_NAME'} = $from_name;
		$in{'_FROM_PASS'} = $from_pass;
		## decrease server load, do not dump
		$in{'_MESSAGE'} = "Subject: $headers{'subject'}\nContent-type: $headers{'content-type'}\n\n$body";
		## &mailmsg_from_hash(%in);
		exit(0);		
	} else {
		@message = &readfile("$datadir/ar/$domain/$username");
		$user = shift @message; chomp $user;
	}
	
	## Make sure user is active
	my ($status, $type) = &get_ext($user);
	exit(0) unless ($status eq 'active' && ($type eq 'registered' || $type eq 'unregistered'));

	my $DBSUB = $dbdriver . "_fetch_account";
	@userinfo = &$DBSUB($user);

	## Get auto responder info from .conf file
	open CONF, "$datadir/conf/$user.conf" or &error("Unable to open local file, $datadir/conf/$user.conf");
	$found = 0;
	while (<CONF>) {
		chop;
		next if $_ eq '';
		next if $_ =~ /^\#/;
		
		if (($dir) = $_ =~ /^\[(.+)?\]/) {
			last if $found == 1;
			$found = 1 if $dir eq "EZYLIST_AUTORESPONDER";
		} elsif ($found == 1) { push @conf, $_; }
	}
	close CONF;
	
	## Process auto responder info from .conf file
	$ok=0;
	foreach $line (@conf) {
		chomp $line;
		($ar, $listid, $forward, $attachfile) = split /::/, $line;
		if (lc($ar) eq lc($toaddr)) { $ok=1; last; }
	}
	if ($ok != 1) { &error("Unable to find auto responder, $toaddr, in user's conf file, $user"); }
	
	## Get list info from user's index.dat file
	$ok=0;
	@index = &readfile("$datadir/list/$user/index.dat");
	foreach $line (@index) {
		my ($type, $name, $file, $efield, $nfield, $welcome, $fields) = split /::/, $line;
		if (($file eq $listid) && ($type eq 'list')) {
			$list{'id'} = $file;
			$list{'name'} = $name;
			$list{'efield'} = $efield;
			$list{'nfield'} = $nfield;
			$list{'welcome'} = $welcome;
			@{$list{'fields'}} = split /,/, $fields;
			$ok=1; last;
		}
	}
	#if ($ok != 1) { &error("Unable to find mailing list in user's profile file, $user"); }

	return 1;
}

################################################
## Increase counter - ignored for auto-reply
################################################
sub counter_increase {
	return 1;
}

################################################
## Add entry to the mailing list
################################################

sub add_entry {
	my ($days, $efield, $nfield, $num, $cdays, $cmessage, @cycle);
	my ($x, $count, $exists, $entry, $unsubscribe_link, @entry);
	&send_reply if $listid eq '';
	
	## Get needed info
	($date, $time) = &getdate;
	$days = &translate_date($date);
	($num) = $listid =~ /^(\d+)\..+/;
	($efield, $nfield) = ($list{'efield'}, $list{'nfield'});
	@listfields = @{$list{'fields'}};
	
	## Get cycle information
	@cycle = &readfile("$datadir/list/$user/$num.cycle");
	($cdays, $cmessage) = split /::/, $cycle[0];
	
	## Get ID of entry
	$count = &readfile("$datadir/list/$user/$num.count"); $count++;
	open FILE, ">$datadir/list/$user/$num.count" or &error("Unable to write to local file, $datadir/list/$user/$num.count");
	print FILE "$count\n"; close FILE;
	$count = sprintf "%.3d", $count;
	
	$merge{'unsubscribe_link'} = $cgiurl . "/unsubscribe.cgi?user=$user&listid=$listid&id=$count";

	## See if e-mail address already exists
	$from_email = lc($from_email);
	$exists = &ezylist_checklist($user, $listid, $from_email);
	
	## Create the new entry
	$days += $cdays;
	@entry = ($count, $days, $cmessage, 1);
	
	$x=4;
	splice @listfields, 0, 4;
	foreach $field (@listfields) {
		if ($x == $efield) { push @entry, $from_email; $merge{$field} = $from_email; }
		elsif (($nfield ne '') && ($x == $nfield)) { push @entry, $from_name; $merge{$field} = $from_name; }
		else { push @entry, ''; }
	$x++; }
	$entry = join "::", @entry;
	
	## Add entry to list
	unless ($exists == 1) {
		open FILE, ">>$datadir/list/$user/$listid" or &error("Unable to append to local file, $datadir/list/$user/$listid");
		print FILE "$entry\n"; close FILE;
	}
	
	## If needed, send a welcome message
	if ($list{'welcome'} ne '') {
		&mailmsg_from_file($from_email, "$datadir/list/$user/$list{'welcome'}", $userinfo[$dbfields[1]], $userinfo[$dbfields[0]], $userinfo[$dbfields[2]], %merge);
	}
	
	## Return
	return 1;
}

################################################
## Send auto reply
################################################

sub send_reply {
	my ($username, $domain, $forward_message, $subject, $content_type, $messagebody, $bodylength, @message, %mail);
	my ($boundary, $message, $attachment);

	## Get needed info
	($username, $domain) = split /\@/, $toaddr;
#	$merge{'unsubscribe_link'} = $unsubscribe_link;
	@message = &readfile("$datadir/ar/$domain/$username");
	
	## Parse the message
	shift @message;
	$subject = shift @message;
	$content_type = shift @message;

	## Set a few variables
	$messagebody = join "\n", @message;
	$bodylength = length($messagebody);
	$boundary = "_----------=" . int(time) . "100";
	$message = "$subject\n";
	
	## If needed, add in the attachment
	if (-e "$datadir/ar/$domain/$username.attach") {
		
		## Create message header
		$message .= "Content-Transfer-Encoding: 7bit\n";
		$message .= "Content-type: multipart/mixed\; boundary\=\"$boundary\"\n";
		$message .= "MIME-Version: 1.0\n\n";
		$message .= "This is a multi-part message in MIME format.\n\n";
	
		## Add the first part of message, text part
		$message .= "--" . $boundary . "\n";
		$message .= "Content-Disposition: inline\n";
		$message .= "Content-Length: $bodylength\n";
		$message .= "Content-Transfer-Encoding: binary\n";
		$message .= "$content_type\n\n";
		$message .= "$messagebody\n";

		## Get, and encode attachment
		$attachment = &mail_encode("$datadir/ar/$domain/$username.attach");

		## Add the second part of message, attachment
		$message .= "--" . $boundary . "\n";
		$message .= "Content-Disposition: inline\; filename\=\"$attachfile\"\n";
		$message .= "Content-Transfer-Encoding: base64\n";
		$message .= "Content-Type: application/octet-stream; name\=\"$attachfile\"\n\n";
		$message .= $attachment;
		$message .= "\n\n--" . $boundary . "--\n\n";

	} else {
		## Or, just create a normal message
		$message .= "$content_type\n\n$messagebody\n";
	}
	


	## Get ready to send the e-mail message
	$merge{'_TO'} = $from_email;
	$merge{'_FROM_NAME'} = $userinfo[$dbfields[0]];
	$merge{'_FROM_ADDR'} = $userinfo[$dbfields[1]];
	$merge{'_FROM_PASS'} = $userinfo[$dbfields[2]];
	$merge{'_MESSAGE'} = $message;
	&mailmsg_from_hash(%merge);
	
	## If needed, forward message
	if (($forward ne '') && ($forward =~ /.*\@.*\..*/)) {
		
		## Create e-mail message to forward
		$forward_message = "Subject: [$toaddr] $header{'subject'}\n";
		$forward_message .= "Content-type: $header{'content-type'}\n\n";
		$forward_message .= $body;
		
		## Get ready to send e-mail
		$mail{'_TO'} = $forward;
		$mail{'_FROM_ADDR'} = $from_email;
		$mail{'_FROM_NAME'} = $from_name;
		$mail{'_FROM_PASS'} = $from_pass;
		$mail{'_MESSAGE'} = $forward_message;
#		$mail{'unsubscribe_link'} = $unsubscribe_link;
		
		## Send the e-mail
		&mailmsg_from_hash(%mail);
		
	}
	
	## Return
	exit(0); ##	return 1;
}

################################################
## Add a log
################################################

sub add_log {

	my ($username, $domain) = split /\@/, $toaddr;
	my ($date, $time) = &getdate;
	my $log = join "::", $from_email, $from_name, $date, $time;
	open FILE, ">>$datadir/arlog/$domain/$username" or &error("Unable to append to local file, $datadir/arlog/$domain/$username");
	print FILE "$log\n"; close FILE;
	
	return 1;
	
}

################################################
## Return the contents of a file
################################################

sub readfile {
	my $file = shift;
	my ($contents, @contents);

	open FILE, $file or &error("Unable to open local file, $file");
	## &lockfile('FILE');
	if (wantarray) {
		@contents = <FILE>;
		## &unlockfile('FILE');
		close FILE;

		chomp @contents;
		return @contents;
	} else {
		while (<FILE>) { $contents .= $_; }
		## &unlockfile('FILE');
		close FILE;
		
		chomp $contents;
		return $contents;
	}

}

################################################
## Lock a file
################################################

sub lockfile {
	my $handle = shift;

	my $success = flock 2, $handle if $FLOCK == 1;
	return $success;
}

################################################
## Unlock a file
################################################

sub unlockfile {
	my $handle = shift;

	my $success = flock 8, $handle if $FLOCK == 1;
	return $success;
}

################################################
## Get the date and time
################################################

sub getdate {
	my ($date, $time);
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	$mon++;
	
	$sec = sprintf "%.2d", $sec;
	$min = sprintf "%.2d", $min;
	$hour = sprintf "%.2d", $hour;
	
	$year -= 100;
	$year = sprintf "%.3d", $year;
	$year = "2" . $year;

	$date = join "-", $mon, $mday, $year;
	$time = join ":", $hour, $min, $sec;
	
	return ($date, $time);

}

################################################
## Translate the date
################################################

sub translate_date {
	my $date = shift;
	my ($month, $mday, $year, $days, @months);

	($month, $mday, $year) = split /-/, $date;
	@months = qw (31 28 31 30 31 30 31 31 30 31 30 31);
	$month -= 2;
	
	for $x ( 0 .. $month ) {
		$days += $months[$x];
	}
	$days += $mday;
	$days += ($year * 365);

	return $days;

}

################################################
## Check a list for an e-mail address
################################################

sub ezylist_checklist {
	my ($user, $listid, $id) = @_;
	my ($found, $row, @listinfo, %info);

	## Get needed info
	$row = $list{'efield'};
	@listinfo = &readfile("$datadir/list/$user/$listid");

	## Check list for e-mail address
	$found=0;
	foreach $line (@listinfo) {
		my @line = split /::/, $line;
		if (lc($line[$row]) eq lc($id)) { $found=1; last; }
	}

	## Return the results
	return $found;

}

################################################
## Give off an error
################################################

sub error {
	my $error = shift;
	my ($message, %mail);
	
	## Create the error message
	$message = "Subject: [eZyList] - ERROR - Autoresponder $toaddr\n";
	$message .= "Content-type: text/plain\n\n\n";
	$message .= "Hello $admin_name,\n\nAn error was reported in the eZyList Pro ";
	$message .= "when a message was sent to the auto responder, $toaddr, which is owned by the member, $user.\n\n";
	$message .= "The error which was reported is as follows:\n\n\t$error\n\n";
	$message .= "Thank you,\n\neZyList Pro v1.0\nCreated by eZyscripts.Com\nhttp://www.ezyscripts.com/\n\n";
	
	## Get ready to send e-mail
	$mail{'_TO'} = $admin_email;
	$mail{'_FROM_ADDR'} = $admin_email;
	$mail{'_FROM_NAME'} = $admin_name;
	$mail{'_FROM_PASS'} = $admin_pass;
	$mail{'_MESSAGE'} = $message;
	
	## Send the e-mail message
	&mailmsg_from_hash(%mail);
	
	## Exit the program
	exit(0);
	
}


