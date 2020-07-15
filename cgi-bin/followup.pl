#!/usr/bin/perl
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

## Load the required files
eval { require $conf; };
if ($@) { print "Content-type: text/html\n\nUnable to find required file, <b>ezylist.conf</b>, which should be located at, <b>$conf</b>"; exit; }
eval { require "$cgidir/lib/main-lib.pl"; };
if ($@) { print "Content-type: text/html\n\nUnable to find required file, <b>main-lib.pl</b>, which should be located at, <b>$cgidir/lib/main-lib.pl</b>"; exit; }
eval { require "$cgidir/lib/ezylist-lib.pl"; };
if ($@) { print "Content-type: text/html\n\nUnable to find required file, <b>ezylist-lib.pl</b>, which should be located at, <b>$cgidir/lib/ezylist-lib.pl</b>"; exit; }

## Get started
&get_started;

## Send all needed follow up messages
&followup_all;

## Finish up.  Send an e-mail to admin with summary
&followup_finish;

## Exit the script
exit(0);

################################################
## Get started
################################################

sub get_started {

	## Get needed info
	($date, $time) = &getdate;
	$days = &translate_date($date);
	($total_email, $total_list, $total_semail, $total_slist) = (0, 0, 0, 0);

	## Get a list of all users
	$DBSUB = $dbdriver . "_search_account";
	my $c1 = 'active';
	if ($moptions[6] == 1) { $c1 = 'all'; }
	@users = &$DBSUB($c1, 'all');
	
	$total_user = @users;
	return 1;

}

################################################
## Perform all follow ups
################################################

sub followup_all {
	foreach $user (@users) {
		my ($status, $type, $DBSUB, @userinfo, $DBSUB, %info, %count, %user);
	
		## Get userinfo
		($status, $type) = &get_ext($user);
		next if ($type eq 'advertiser');

		$DBSUB = $dbdriver . "_fetch_account";
		@userinfo = &$DBSUB($user);
		%info = &ezylist_get_listinfo($user);
		($user{'followup_summary'}, $user{'schedule_summary'}) = ('', '');
		
		## Go through all mailing lists
		foreach $key (keys %info) {
			my ($efield, $listfields, $total, $count, $num, $size, $listname, @mail, @mresults);
			next unless $info{$key}{'type'} eq 'list';
			($num) = $key =~ /^(\d+)\..+/;
			
			## Get needed list info
			$listname = $info{$key}{'name'};
			$efield = ($info{$key}{'efield'} - 4);
			$listfields = join "::", @{$info{$key}{'fields'}};
			
			## Send the follow ups for list
			$procount = &process_followups($user, $key, $efield, $listfields, @userinfo);
			$user{'followup_summary'} .= "$procount messages sent to $listname\n";
			$total_email += $procount;
		
			## See if any mailings are scheduled for list
			@mail = &readfile("$datadir/list/$user/$num.mail");
			
			foreach $line (@mail) {
				my ($sdays, $smessage) = split /::/, $line;
				unless ($sdays == $days) { push @mresults, $line; next; }
				
				## Send scheduled mailing to list
				($count, $total) = &process_scheduled($user, $key, $smessage, $efield, $listfields, @userinfo);
				$user{'schedule_summary'} .= "The scheduled mailing to the list, $info{$key}{'name'}, was sent.  $count out of $total messages were sent successfully.\n" unless $info{$key}{'name'} eq '';
				$total_semail += $count;
			}
			
			&writefile("$datadir/list/$user/$num.mail", @mresults);
		}
		
		## Get ready to send e-mail to user
		$x=0;
		$userinfo[$dbfields[2]] = "<--ENCRYPTED-->" if $moptions[2] == 1;
		foreach $field (@userfields) { $user{$field} = $userinfo[$x]; $x++; }
		$user{'date'} = &format_date($date);

		## Send e-mail to user
		if ($user{'schedule_summary'} eq '') { $user{'schedule_summary'} = "No mailings scheduled for today"; }
		
		## Following is for debugging
		open FILE, ">/home/ezyscrips/test3.txt";
		while (($key, $value) = each %user) { print FILE "$key \= $value\n"; }
		&mailmsg_from_file($from_email, "$datadir/messages/followup_user.msg", $admin_email, $admin_name, $admin_pass, %user);
	}
	
	return 1;
}

################################################
## Finish up.  Send e-mail to admin
################################################

sub followup_finish {
	my (%admin);
	
	## Get ready to send the e-mail message
	$admin{'total_list'} = $total_list;
	$admin{'total_user'} = $total_user;
	$admin{'total_email'} = $total_email;
	$admin{'total_schedule_list'} = $total_slist;
	$admin{'total_schedule_email'} = $total_semail;
	$admin{'date'} = &format_date($date);
	
	&mailmsg_from_file($admin_email, "$datadir/messages/followup_admin.msg", $admin_email, $admin_name, $admin_pass, %admin);

	return 1;
}

################################################
## Process all follow ups
################################################

sub process_followups {
	my ($user, $listid, $efield, $listfields, @userinfo) = @_;
	my ($x, $from_name, $from_addr, $count, $num, $size, @listinfo, @listfields, @cycle, @results, %messageinfo);
	
	## Get needed info
	($from_name, $from_email) = ($userinfo[$dbfields[0]], $userinfo[$dbfields[1]]);
	@listinfo = &readfile("$datadir/list/$user/$listid");
	@listfields = split /::/, $listfields;
	%messageinfo = &ezylist_get_listinfo($user);
	
	## Process needed info
	splice @listfields, 0, 4;
	($num) = $listid =~ /^(\d+)\..+/;
	$size = (@listinfo - 1);
	@cycle = &readfile("$datadir/list/$user/$num.cycle");
	
	## Process the list entries
	$count = 0;
	for $x ( 0 .. $size ) {
		my ($y, $code, $advert, %merge);
		
		next if ($listinfo[$x] eq '');
		## See if we need to follow up today
		my ($id, $next, $next_message, $cycle, @line) = split /::/, $listinfo[$x];
		unless ($days >= $next) { push @results, $listinfo[$x]; next; }
		
		## Get the merge info
		$y=0;
		foreach $field (@listfields) { $merge{$field} = $line[$y]; $y++; }
#		$merge{'unsubscribe_link'} = $cgiurl . "/unsubscribe.cgi?user=$user&listid=$listid&id=$id";
		$merge{'advertisement'} = &followup_load_advertisement("text/plain", $user);

		## Send the e-mail
		$code = &followup_send_message($user, $line[$efield], $next_message, $from_email, $from_name, $messageinfo{$next_message}{'attach'}, %merge);
		
		## If mailing was succesful
		if ($code == 1) {
			
			## If needed, add a log
			if ($moptions[8] == 1) {
				my $log = join "::", $id, $next, $info{$next_message}{'name'}, $cycle, @line;
				if (!-d "$datadir/list/$user/log/$num") { &makedir("$datadir/list/$user/log/$num"); }
				if (-e "$datadir/list/$user/log/$num/$days") { &appendfile("$datadir/list/$user/log/$num/$days", $log); }
				else { &writefile("$datadir/list/$user/log/$num/$days", $log); }
			}
			
			## Change entry info in mailing list
			if ($cycle >= @cycle) { &appendfile("$datadir/list/$user/$num.archive", (join "::", $id, @line)) if $moptions[7] == 1; }
			else {
				## Create new entry
				my ($cdays, $cmessage) = split /::/, $cycle[$cycle];
				$next += $cdays; $cycle++;
				push @results, (join "::", $id, $next, $cmessage, $cycle, @line);
			}
			
			## Add 1 to counter
			$count++;
			
		## If an error occured during mailing
		} else {
			
			## Add entry to error log file
			my $error_log = join "::", $id, $code, $info{$next_message}{'info'}, $cycle, @line;
			&appendfile("$datadir/list/$user/error/$num/$days", $error_log);
			
			## If we need to reschedule the follow up
			unless (($code == 620) || ($code == 622) || ($code == 623) || ($code == 626)) {
				push @results, (join "::", $id, ($next + 2), $next_message, $cycle, @line);
			}
		}
	}
	
	## Rewrite the mailing list
	$total_list++;
	&writefile("$datadir/list/$user/$listid", @results);
	
	## Return number of e-mails sent
	return $count;
}

################################################
## Process a scheduled mailing
################################################

sub process_scheduled {
	my ($user, $listid, $message, $efield, $listfields, @userinfo) = @_;
	my ($status, $type, $from_name, $from_email, $size, $count, @listinfo, @listfields, %messageinfo);
	
	($status, $type) = &get_ext($user);

	## Get needed info
	($from_name, $from_email) = ($userinfo[$dbfields[0]], $userinfo[$dbfields[1]]);
	@listinfo = &readfile("$datadir/list/$user/$listid");
	@listfields = split /::/, $listfields;
	splice @listfields, 0, 4;
	$size = (@listinfo - 1);
	%messageinfo = &ezylist_get_listinfo($user);
	
	## Process the list entries
	$count = 0;
	foreach $line (@listinfo) {
		my ($y, $code, %merge);	
		next if $line eq '';
		
		## Get entry info
		my ($id, $next, $next_message, $cycle, @line) = split /::/, $line;
		
		## Get the merge info
		$y=0;
		foreach $field (@listfields) { $merge{$field} = $line[$y]; $y++; }
#		$merge{'unsubscribe_link'} = $cgiurl . "/unsubscribe.cgi?user=$user&listid=$listid&id=$id";
		$merge{'advertisement'} = &followup_load_advertisement("text/plain", $user);

		## Send the e-mail
		$code = &followup_send_message($user, $line[$efield], $message, $from_email, $from_name, $messageinfo{$message}{'attach'}, %merge);
		$count++ if $code == 1;
	}
	
	## Delete the e-meil message
	&deletefile("$datadir/list/$user/$message");
	
	## Return number of messages sent, and size of list
	$total_slist++;
	return ($count, $size);

}

################################################
## Load advertisement
################################################

sub followup_load_advertisement {
	my ($content_type, $user) = @_;
	my ($_html, $_swf, $swfhtml, $adfile, $adindex, $aduser, $adid, $adtext, $advert, @content, @adinfo);

	if ($content_type =~ /html/) { $_html = 1; }
	else { $_html = 0; }

	## Get random advertisement index
	$adfile = randomfile("$datadir/ad", '\\.(ad)$');
	$adindex = &readfile("$datadir/ad/$adfile");
	($aduser, $adid) = split /::/, $adindex;

	## Load advertisement
	my ($adnum) = $adid =~ /^(\d+)\..+/;
	%adinfo = &ezylist_get_adinfo($aduser);

	## Get and parse message
	@content = &readfile("$datadir/ad/$aduser/$adid");
	shift @content;
	$adname = $adinfo{$adid}{'name'};
	$adimage = $adinfo{$adid}{'image'};
	$swf = (shift @content);

	$image_link = $cgiurl . "/advertise.cgi\?action=display\&user=$aduser\&ad=$adid";
	$click_link = $cgiurl . "/advertise.cgi\?action=click\&user=$aduser\&link=$adnum.link";

	## Format a few variables
	$adtext = join "\n", @content;
	$adtext =~ s/^\n//;
	if ($swf =~ /x-shockwave-flash/) {
		$swfhtml = qq!<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=5,0,0,0">
	<param name=movie value=!;
		$swfhtml .= "";
		$swfhtml .= "\"$image_link\"";
		$swfhtml .= qq!>
	<param name=quality value=high>
	<param name=scale value="exactfit">
	<embed src="!;
		$swfhtml .= $adimage;
		$swfhtml .= qq!"
	       quality=high type="application/x-shockwave-flash"
	       plugsinpage="http://www.macromedia.com/shockwave/download/index.cgi?P1_Prod_Version=ShockwaveFlash">
	</embed></object>!;
		$_swf = 1;
	} else {
		$swfhtml = qq!<img src=!;
		$swfhtml .= "\"$image_link\"\n";
		$swfhtml .= qq!>!;
		$_swf = 0;
	}
	if ($_html == 1) {
		$advert = "<br><center><hr width=90%></center>\n<br><font face=\"arial\" size=3><b>";
	} else {
		$advert = "\n--------------------------------\nAdvertisement:\n";
	}
	$advert .= "$adname\n";
	$advert .= "</b></font>\n<br>" if ($_html == 1);
	$advert .= "$adtext\n";
	$advert .= "<br>\n<br>\n\t<a href=" if ($_html == 1);
	$advert .= "\"$click_link\"\n";
	$advert .= ">\n\t" if ($_html == 1);
	$advert .= $swfhtml if ($_html == 1);
	$advert .= "\n\t</a>\n<br>\n\n" if ($_html == 1);

	counter_increase("$datadir/ad/$aduser/$adnum.displayed");
	return $advert;
}

################################################
## Load system links
################################################

sub followup_load_links {
	my ($content_type, $user, $listid, $id) = @_;
	my ($_html, $links);

	if ($content_type =~ /html/) { $_html = 1; }
	else { $_html = 0; }

	$unsubscribe_link = $cgiurl . "/unsubscribe.cgi?user=$user&listid=$listid&id=$id";
	$subscribe_link = $cgiurl . "/subscribe.cgi\?user=$user&listid=$listid";

	if ($_html == 1) {
		$links = qq!<br><center><hr width=90%></center>\n<br><font face="arial" size=3><b>!;
	} else {
		$links = "\n--------------------------------\n";
	}
	$links .= "Subscribe Links:\n";
	$links .= "</b></font>\n<br>" if ($_html == 1);
	$links .= "<br>\n\t<a href=" if ($_html == 1);
	$links .= "\"$subscribe_link\"\n";
	$links .= ">\n\t" if ($_html == 1);
	$links .= "click this to subscribe" if ($_html == 1);
	$links .= "\n\t</a>\n<br>\n\n" if ($_html == 1);

	if ($_html == 1) {
		$links .= qq!<br><center><hr width=90%></center>\n<br><font face="arial" size=3><b>!;
	} else {
		$links .= "\n--------------------------------\n";
	}
	$links .= "Unsubscribe Links:\n";
	$links .= "</b></font>\n<br>" if ($_html == 1);
	$links .= "<br>\n\t<a href=" if ($_html == 1);
	$links .= "\"$unsubscribe_link\"\n";
	$links .= ">\n\t" if ($_html == 1);
	$links .= "click this to unsubscribe" if ($_html == 1);
	$links .= "\n\t</a>\n<br>\n\n" if ($_html == 1);

	return $links;
}

################################################
## Send out a follow up message
################################################

sub followup_send_message {
	my ($user, $email, $msg, $from_email, $from_name, $attachfile, %merge) = @_;
	my ($num, $subject, $content_type, $message, $boundary, $code, $messagebody, $bodylength, $attachext, $attachment, @message);
	my ($status, $type) = &get_ext($user);
	return 0 if (!$status || !$type);
	return 0 if !-e "$datadir/list/$user/$msg";

	## Get and parse the message
	($num) = $msg =~ /^\d+/;

	@message = &readfile("$datadir/list/$user/$msg");
	shift @message; $subject = shift @message; $content_type = shift @message;

	## Set a few variables
	$messagebody = join "\n", @message;
	$bodylength = length($messagebody);
	$boundary = "_----------=" . int(time) . "100";
	$message = "$subject\n";
	
	## If needed, add in the attachment
	if ($attachfile ne '') {
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

		$message .= &followup_load_links($content_type, $user, "$num.list", $email);
		if ($type eq "unregistered") {
			$message .= &followup_load_advertisement($content_type, $user);
		}
		$message .= "\n";
		## Get, and encode attachment
		$attachment = &mail_encode("$datadir/list/$user/$num.attach");
		
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
		$message .= &followup_load_links($content_type, $user, "$num.list", $email);
		if ($type eq "unregistered") {
			$message .= &followup_load_advertisement($content_type, $user);
		}
	}

	## Get ready to send the e-mail message
	$merge{'_TO'} = $email;
	$merge{'_FROM_NAME'} = $from_name;
	$merge{'_FROM_ADDR'} = $from_email;
	$merge{'_MESSAGE'} = $message;
	$code = &mailmsg_from_hash(%merge);
	
	## Return results
	return $code;

}


