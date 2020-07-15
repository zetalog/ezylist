
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

################################################
## Create auto responder
################################################

sub ar_create {

	## Make sure user exists
	my $user = $in{'username'};
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
	my %info = &ezylist_get_listinfo($user);

	## Figure out what to do
	if ($in{'action'} eq 'create') {
		my ($username, $domain, $listid, $arlog);
		
		## Get needed info
		($username, $domain, $listid) = ($in{'ar_username'}, $in{'ar_domain'}, $in{'attach_list'});
		if ($username =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Auto responder username contains spaces or special characters"); }
		$username = lc($username);
		$domain = lc($domain);
		
		## Perform a few checks
		if ($username eq '') { &error(500, __LINE__, __FILE__, "You did not specify a username for te auto responder"); }
		elsif ($username =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Auto responder username contains spaces or special characters"); }
		elsif ($username =~ /\.attach$/) { &error(500, __LINE__, __FILE__, "Auto responder username can not contain <b>.attach</b>"); }
		elsif (-e "$datadir/ar/$domain/$username") { &error(500, __LINE__, __FILE__, "Auto responder already exists, <b>$user\@$domain</b>"); }
		elsif (($in{'forward'} ne '') && ($in{'forward'} !~ /.*\@.*\..*/)) { &error(500, __LINE__, __FILE__, "Invalid forwarding e-mail address, <b>$in{'forward'}</b>"); }
				
		## Get name of mailing list
		if ($listid eq '') { $in{'listname'} = "No Mailing List"; }
		else { $in{'listname'} = $info{$listid}{'name'}; }
		
		## Create the arlog file
		$arlog = join "::", "$username\@$domain", $listid, $in{'forward'};
		
		## Write all information to database
		&append_conf($user, 'conf', 'EZYLIST_AUTORESPONDER', $arlog);
		&writefile("$datadir/arlog/$domain/$username") if $moptions[5] == 1;
		&writefile("$datadir/ar/$domain/$username");

		## Print HTML template
		print &parse_template('admin/ar/create2.htmlt');
		exit(0);
		
	} else {
		my (@domains);
		
		## Get needed info
		@domains = &readfile("$datadir/dat/domains.dat");
		
		## Get ready to print HTML template
		$in{'list_options'} = qq!<option value="">No Mailing List!;
		foreach (@domains) { $in{'domain_options'} .= "<option>$_"; }
		foreach $key (keys %info) {
			next unless $info{$key}{'type'} eq 'list';
			$in{'list_options'} .= qq!<option value="$key">$info{$key}{'name'}!;
		}
		
		## Print HTML template
		print &parse_template('admin/ar/create.htmlt');
		exit(0);
	
	}

}

################################################
## Create auto responder - part 2
################################################

sub ar_create2 {

	## Create and format the e-mail message
	my $message = &format_message($in{'_html'}, $in{'subject'}, $in{'contents'});
	$message = $in{'username'} . "\n" . $message;
	my $username = lc($in{'ar_username'});
	
	## If needed, get the attachment
	if ($in{'attachment'} ne '') {
		while (read($in{'attachment'}, $buffer, 1024)) { $attachment .= $buffer; }
		&writefile("$datadir/ar/$in{'ar_domain'}/$in{'ar_username'}.attach", $attachment);

		if ($in{'attachment'} =~ /\\/) { ($attachfile) = $in{'attachment'} =~ /.*\\(.*)/; }
		elsif ($in{'attachment'} =~ /\//) { ($attachfile) = $in{'attachment'} =~ /.*\/(.*)/; }
		else { $attachfile = $in{'attachment'}; }
		
		## Add attachfile to user's .conf file
		$user = $in{'username'};
		my $x=0; my $search = join "@", $in{'ar_username'}, $in{'ar_domain'};
		my @conf = &parse_conf($user, 'conf', 'EZYLIST_AUTORESPONDER');
		foreach $line (@conf) {
			my @line = split /::/, $line;
			if (lc($line[0]) eq lc($search)) {
				$line[3] = $attachfile;
				$conf[$x] = (join "::", @line);
				&edit_conf($user, 'conf', 'EZYLIST_AUTORESPONDER', (join "\n", @conf));
			}
		$x++; }
	}

	## Save the message to the server
	&writefile("$datadir/ar/$in{'ar_domain'}/$in{'ar_username'}", $message);
	
	## Print off HTML success template
	&success("Successfully created auto responder, <b>$in{'ar_username'}\@$in{'ar_domain'}</b>");

}

################################################
## Edit auto responder
################################################

sub ar_edit {
	
	## Make sure user exists
	my $user = $in{'username'};
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }

	## Figure out what to do
	if ($in{'action'} eq 'getar') {
		my ($username, $domain, $ar, $listid, $forward, $attachfile, $content_type, @message, @conf, %info);
		
		## Get needed info
		if ($in{'ar'} eq '') { &error(500, __LINE__, __FILE__, "You did not select an auto responder to edit"); }
		($username, $domain) = split /\@/, $in{'ar'};
		@conf = &parse_conf($user, 'conf', 'EZYLIST_AUTORESPONDER');
		%info = &ezylist_get_listinfo($user);
		
		## Get auto responder info from @conf
		foreach $line (@conf) {
			next if $line eq '';
			($ar, $listid, $forward, $attachfile) = split /::/, $line;
			last if $ar eq $in{'ar'};
		}
		$in{'forward'} = $forward;
		$in{'attachfile'} = $attachfile;
		
		## Get needed info from %info hash
		$in{'list_options'} = qq!<option value="">No Mailing List!;
		foreach $key (keys %info) {
			next unless $info{$key}{'type'} eq 'list';
			my $chk = "selected" if $key eq $listid;
			$in{'list_options'} .= qq!<option value="$key" $chk>$info{$key}{'name'}!;
		}
		
		## Get message info
		@message = &readfile("$datadir/ar/$domain/$username"); shift @message;
		$in{'subject'} = shift @message; $content_type = shift @message;
				
		$in{'subject'} =~ s/^Subject: //;
		$in{'contents'} = join "\n", @message;
		if ($content_type =~ /html/) { $in{'html_check'} = "checked"; }
		else { $in{'html_check'} = ""; }
		
		## Print out HTML template
		print &parse_template('admin/ar/edit.htmlt');
		exit(0);

	} else { &ar_getar($user, "Edit Auto Responder"); }
}

################################################
## Edit auto responder - part 2
################################################

sub ar_edit2 {
	my ($x, $user, $username, $domain, $ar, $listid, $forward, $message, $attachment, $attachfile, @conf, @index, @newline);
	
	## Get needed info
	($user, $ar) = ($in{'username'}, $in{'ar'});
	($username, $domain) = split /\@/, $ar;
	($listid, $forward) = ($in{'listid'}, $in{'forward'});
	@conf = &parse_conf($user, 'conf', 'EZYLIST_AUTORESPONDER');
		
	## Perform a couple checks
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
	elsif (($forward ne '') && ($forward !~ /.*\@.*\..*/)) { &error(500, __LINE__, __FILE__, "Invalid forwarding e-mail address, <b>$forward</b>"); }
	
	## Format the new auto-reply
	$message = &format_message($in{'_html'}, $in{'subject'}, $in{'contents'});
	$message = $user . "\n" . $message;
	
	## If needed, get the attachment
	if ($in{'attachment'} ne '') {
		while (read($in{'attachment'}, $buffer, 1024)) { $attachment .= $buffer; }
		&writefile("$datadir/ar/$domain/$username.attach", $attachment);

		if ($in{'attachment'} =~ /\\/) { ($attachfile) = $in{'attachment'} =~ /.*\\(.*)/; }
		elsif ($in{'attachment'} =~ /\//) { ($attachfile) = $in{'attachment'} =~ /.*\/(.*)/; }
		else { $attachfile = $in{'attachment'}; }
	}
		
	## Update auto responder conf
	$x=0;
	@newline = ($ar, $listid, $forward, '');
	foreach $line (@conf) {
		my @line = split /::/, $line;
		if ($line[0] eq $ar) {
			if ($in{'attachment'} eq '') { $newline[3] = $line[3]; }
			else { $newline[3] = $attachfile; }
			my $newline = join "::", @newline;
			
			splice @conf, $x, 1, $newline;
			last;
		}
	$x++; }
	
	## Save new information to server
	&writefile("$datadir/ar/$domain/$username", $message);
	&edit_conf($user, 'conf', 'EZYLIST_AUTORESPONDER', (join "\n", @conf));
	
	## Print off HTML success template
	&success("Successfully edited the auto responder, <b>$ar</b>");	

}

################################################
## Delete auto responder
################################################

sub ar_delete {

	## Make sure user exists
	my $user = $in{'username'};
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }

	## Figure out what to do
	if ($in{'action'} eq 'getar') {
		if ($in{'ar'} eq '') { &error(500, __LINE__, __FILE__, "You did not select an auto responder to edit"); }
		
		$in{'page_title'} = "Delete Auto Responder";
		$in{'confirm_data'} = join "::", $user, $in{'ar'};
		$in{'QUERY_STRING'} = "menu=ar&action=delete2";
		$in{'confirm_text'} = "Are you sure you want to delete the auto responder, <b>$in{'ar'}</b>?";
		
		print &parse_template('admin/confirm.htmlt');
		exit(0);		

	} else { &ar_getar($user, "Delete Auto Responder"); }

}

################################################
## Delete auto responder - part 2
################################################

sub ar_delete2 {
	my ($x, $user, $ar, $username, $domain, @conf);
	
	## Get needed info
	($user, $ar) = split /::/, $in{'confirm_data'};
	($username, $domain) = split /\@/, $ar;
	@conf = &parse_conf($user, 'conf', 'EZYLIST_AUTORESPONDER');
	
	## Perform a few checks
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
	elsif ($ar eq '') { &error(500, __LINE__, __FILE__, "You did not select an autoresponder to delete"); }
	elsif ($in{'confirm'} == 0) { &success("Did not delete the auto responder, <b>$ar</b>"); }
	
	## Delete auto responder from conf
	$x=0;
	foreach $line (@conf) {
		my @line = split /::/, $line;
		if ($line[0] eq $ar) {
			splice @conf, $x, 1;
			last;
		}
	$x++; }
	
	## Save info to server
	&edit_conf($user, 'conf', 'EZYLIST_AUTORESPONDER', (join "\n", @conf));
	&deletefile("$datadir/ar/$domain/$username");
	&deletefile("$datadir/ar/$domain/$username.attach");
	&deletefile("$datadir/arlog/$domain/$username");
	
	## Print off HTML success template
	&success("Successfully deleted the auto responder, <b>$ar</b>");

}

################################################
## View an auto responder
################################################

sub ar_view {

	## Make sure user exists
	my $user = $in{'username'};
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }

	## Figure out what to do
	if ($in{'action'} eq 'getar') {
		my ($user, $listid, $start, $domain, $username, @entries);
	
		if ($in{'ar'} eq '') { &error(500, __LINE__, __FILE__, "You did not select an auto responder to view"); }
		elsif ($moptions[5] != 1) { &error(500, __LINE__, __FILE__, "Logging of auto responders feature is not enabled"); }
		
		## Get needed info
		if ($PARSE == 1) { ($user, $ar, $start) = ($in{'username'}, $in{'ar'}, 0); }
		else {
			($user, $ar, $start) = ($query{'username'}, $query{'listid'}, $query{'start'});
			($in{'username'}, $in{'ar'}) = ($user, $ar);
		}
		%info = &ezylist_get_listinfo($user);
		($username, $domain) = split /\@/, $ar;
	
		## Make sure user exists
		if (!defined &get_ext($user)) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }

		## Create next/prev links, and get entries to show
		@entries = &ezylist_get_browse_info($user, $ar, "$datadir/arlog/$domain/$username", $start, "menu=ar&action=view");

		## Process the entries to show
		foreach $line (@entries) {
			my ($from_email, $from_name, $date, $time);

			## Get needed info
			($from_email, $from_name, $date, $time) = split /::/, $line;
			
			push @{$in{'from_email'}}, $from_email;
			push @{$in{'from_name'}}, $from_name;
			push @{$in{'date'}}, &format_date($date);
			push @{$in{'time'}}, $time;
		}
		
		## Print the HTML template
		$in{'listname'} = $info{$id}{'name'};
		$in{'qmark'} = "?"; $in{'smark'} = "|";
		print &parse_template('admin/ar/view.htmlt');
		exit(0);	

	} else { &ar_getar($user, "View Auto Responder"); }
	
}

################################################
## Select an auto responder
################################################

sub ar_getar {
	my ($user, $title) = @_;
	my (@conf, @ar, %info, %ar);
	
	## Get needed info
	%info = &ezylist_get_listinfo($user);
	@conf = &parse_conf($user, 'conf', 'EZYLIST_AUTORESPONDER');
	
	## Parse info to get auto responders
	foreach $line (@conf) {
		next if $line eq '';
		my ($ar, $listid, $forward) = split /::/, $line;
		
		$ar{$ar} = $listid;
		push @ar, $ar;
	}
	
	@ar = sort { $a cmp $b } @ar;
	foreach $ar (@ar) {
		push @{$in{'ar'}}, $ar; $listid = $ar{$ar};
		if ($listid eq '') { push @{$in{'listname'}}, "No Mailing List"; }
		else { push @{$in{'listname'}}, $info{$listid}{'name'}; }
	}
	
	## Get ready to print HTML template
	$in{'title'} = $title;
	
	## Print HTML template
	print &parse_template('admin/ar/getar.htmlt');
	exit(0);
	
}

1;
