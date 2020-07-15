
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
## Manage follow ups
################################################

sub followup_manage {
	my ($user, $id, $num, @cycle, %info);

	## Make sure user exists
	$user = $in{'username'};
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }

	## Get needed info
	$id = $in{'list_id'};
	($num) = $id =~ /^(\d+)\..+/;
	%info = &ezylist_get_listinfo($user);
	@cycle = &readfile("$datadir/list/$user/$num.cycle");

	## Parse welcome message HTML
	if ($info{$id}{'welcome'} ne '') { $in{'welcome_html'} = ", and is sent the e-mail message <b>$info{$info{$id}{'welcome'}}{'name'}</b>"; }
	else { $in{'welcome_html'} = ''; }

	## Parse follow up info
	$x=0;
	foreach $line (@cycle) {
		next if $line eq '';
		my ($days, $message) = split /::/, $line;
		push @{$in{'followup_id'}}, $x;
		push @{$in{'followup_cycle'}}, "<b>$days</b> days after the previous follow up cycle, send the <b>$info{$message}{'name'}</b> e-mail message to the subscriber.";
	$x++; }

	## Get a list of all messages
	foreach $key (keys %info) {
		next unless $info{$key}{'type'} eq 'message';
		my $chk = "selected" if $info{$id}{'welcome'} eq $key;
		$in{'message_options'} .= qq!<option value="$key">$info{$key}{'name'}!;
		$in{'welcome_options'} .= qq!<option value="$key" $chk>$info{$key}{'name'}!;
	}

	## Print the HTML template
	$in{'listname'} = $info{$id}{'name'};
	print &parse_template('admin/followup/manage.htmlt');
	exit(0);	
}

################################################
## Manage follow ups - part 2
################################################

sub followup_manage2 {
	my ($user, $id, $num);

	## Get needed info
	($user, $id) = ($in{'username'}, $in{'list_id'});
	($num) = $id =~ /^(\d+)\..+/;
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
	
	## Figure out what to do
	if ($in{'submit'} eq 'Add Follow Up Cycle') {
		
		## Perform a couple checks
		if ($in{'days'} =~ /\D/) { &error(500, __LINE__, __FILE__, "Number of days can only contain digits"); }
		elsif ($in{'days'} <= 0) { &error(500, __LINE__, __FILE__, "Number of days must be greater than 0"); }
		elsif (!-e "$datadir/list/$user/$in{'message'}") { &error(500, __LINE__, __FILE__, "Message does not exist, <b>$in{'message'}</b>"); }

		## Add follow up cycle
		my $cycle = join "::", $in{'days'}, $in{'message'};
		&appendfile("$datadir/list/$user/$num.cycle", $cycle);

		## Print success HTML template
		&success("Successfully added new follow up cycle");

	} elsif ($in{'submit'} eq 'Edit Follow Up Cycle') {
		my ($cycle, $days, $message, @cycle, %info);

		## Get needed info
		$cycle = $in{'followup_id'};
		%info = &ezylist_get_listinfo($user);
		@cycle = &readfile("$datadir/list/$user/$num.cycle");
		($in{'days'}, $message) = split /::/, $cycle[$cycle];
		if ($cycle eq '') { &error(500, __LINE__, __FILE__, "You did not select a follow up cycle to edit"); }

		## Get a list of all messages
		foreach $key (keys %info) {
			next unless $info{$key}{'type'} eq 'message';
			my $chk = "selected" if $key eq $message;
			$in{'message_options'} .= qq!<option value="$key" $chk>$info{$key}{'name'}!;
		}
		
		## Print the HTML template
		print &parse_template('admin/followup/manage_edit.htmlt');
		exit(0);

	} elsif ($in{'submit'} eq 'Delete Follow Up Cycle') {
		if ($in{'followup_id'} eq '') { &error(500, __LINE__, __FILE__, "You did not select a follow up cycle to delete"); }

		## Get ready to print HTML template
		$in{'page_title'} = "Delete Follow Up Cycle";
		$in{'confirm_data'} = (join "::", $user, $id, $in{'followup_id'});
		$in{'QUERY_STRING'} = "menu=followup&action=manage_delete";
		$in{'confirm_text'} = "Are you sure you want to delete the selected follow up cycle?";

		## Print confirm HTML template
		print &parse_template('admin/confirm.htmlt');
		exit(0);

	} else { &error(500, __LINE__, __FILE__, "Nothing to do"); }


}

################################################
## Manage follow ups - edit cycle
################################################

sub followup_manage_edit {
	my ($x, $user, $id, $num, $cycle, $newline, @cycle);
		
	## Get needed info
	($user, $id, $cycle) = ($in{'username'}, $in{'list_id'}, $in{'followup_id'});
	($num) = $id =~ /^(\d+)\..+/;
	@cycle = &readfile("$datadir/list/$user/$num.cycle");

	## Perform a couple checks
	if (!defined &get_ext($user)) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	elsif ($cycle eq '') { &error(500, __LINE__, __FILE__, "You did not select a follow up cycle to edit"); }
	elsif ($in{'days'} =~ /\D/) { &error(500, __LINE__, __FILE__, "Number of days can only contain digits"); }
	elsif ($in{'days'} <= 0) { &error(500, __LINE__, __FILE__, "Number of days must be greater than 0"); }
	elsif (!-e "$datadir/list/$user/$in{'message'}") { &error(500, __LINE__, __FILE__, "Message does not exist, <b>$in{'message'}</b>"); }
	
	## Edit the follow up cycle
	splice @cycle, $cycle, 1, (join "::", $in{'days'}, $in{'message'});
	&writefile("$datadir/list/$user/$num.cycle", @cycle);

	## Print HTML success text
	&success("Successfully edited follow up cycle");
}

################################################
## Manage follow ups - delete cycle
################################################

sub followup_manage_delete {
	my ($user, $id, $cycle, $num, @cycle);
	
	## Get needed info
	if ($in{'confirm'} == 0) { &success("Did not delete the selected follow up cycle"); }
	($user, $id, $cycle) = split /::/, $in{'confirm_data'};
	($num) = $id =~ /^(\d+)\..+/;
	@cycle = &readfile("$datadir/list/$user/$num.cycle");

	## Delete follow up cycle
	splice @cycle, $cycle, 1;
	&writefile("$datadir/list/$user/$num.cycle", @cycle);

	## Print of success HTML template
	&success("Successfully deleted the selected follow up cycle");
}

################################################
## Schedule mailings
################################################

sub followup_schedule {
	my ($user, $listid, %info);

	## Get needed info
	($user, $listid) = ($in{'username'}, $in{'list_id'});
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
	elsif ($listid eq '') { &error(500, __LINE__, __FILE__, "You did not select a mailing list to manage"); }
	elsif (!-e "$datadir/list/$user/$listid") { &error(500, __LINE__, __FILE__, "Mailing list does not exist, <b>$listid</b>"); }
	%info = &ezylist_get_listinfo($user);
	
	## If we need to add a mailing
	if ($in{'submit'} eq 'Add Mailing') {
		my ($x, $newdate, $num, $message, $date, $time, $newline);
		
		## Perform a few checks
		if ($in{'name'} eq '') { &error(500, __LINE__, __FILE__, "You did not specify a name for the e-mail message"); }
		
		## Get scheduled mailing date
		$newdate = join "-", $in{'nextdate_month'}, $in{'nextdate_day'}, $in{'nextdate_year'};
		$newdate = &translate_date($newdate);
		
		## Make sure mailing date is later than today's date
		($date, $time) = &getdate;
		$date = &translate_date($date);
		if ($date >= $newdate) { &error(500, __LINE__, __FILE__, "The mailing date must be set later than today's date"); }
	
		## Format the e-mail message	
		$message = &format_message($in{'_html'}, $in{'subject'}, $in{'contents'});
		$message = $in{'name'} . "\n" . $message;
		
		## Write e-mail message to server
		$x=1;
		while (-e "$datadir/list/$user/$x.mail.msg") { $x++; }
		&writefile("$datadir/list/$user/$x.mail.msg", $message);
		
		## Add info to x.mail file
		($num) = $listid =~ /^(\d+)\..+/;
		$newline = join "::", $newdate, "$x.mail.msg";
		&appendfile("$datadir/list/$user/$num.mail", $newline);
		
		## Print off HTML success template
		$newdate = &format_date(&num2date($newdate));
		&success("Successfully added new scheduled mailing, which will be sent out on <b>$newdate</b>");
	
	## If we need to edit a mailing
	} elsif ($in{'submit'} eq 'Edit Mailing') {
		my ($id, $num, $date, $file, $html, @mail);
		
		## Get needed info
		$id = $in{'mailid'};
		($num) = $listid =~ /^(\d+)\..+/;
		@mail = &readfile("$datadir/list/$user/$num.mail");
		($date, $file) = split /::/, $mail[$id];
		
		## Perform a couple checks
		if ($id eq '') { &error(500, __LINE__, __FILE__, "You did not select a mailing to edit"); }
		elsif (($date eq '') || ($file eq '')) { &error(500, __LINE__, __FILE__, "Invalid mailing ID#, <b>$id</b>"); }
		if (!-e "$datadir/list/$user/$file") { &error(500, __LINE__, __FILE__, "E-Mail message file does not exist, <b>$file</b>"); }
		
		## Get and parse message
		@message = &readfile("$datadir/list/$user/$file");
		$in{'name'} = (shift @message);
		$in{'subject'} = (shift @message);
		$html = (shift @message);

		## Format a few variables
		$in{'subject'} =~ s/^Subject: //;
		$in{'contents'} = join "\n", @message;
		if ($html =~ /html/) { $in{'html_check'} = "checked"; }
		else { $in{'html_check'} = ""; }

		## Print HTML template
		$in{'listname'} = $info{$listid}{'name'};
		$in{'maildate_html'} = &ezylist_get_datehtml($date);
		print &parse_template('admin/followup/schedule_edit.htmlt');
		exit(0);
				
	} elsif ($in{'submit'} eq 'Delete Mailing') {
	
		## Perform a couple checks
		if ($in{'mailid'} eq '') { &error(500, __LINE__, __FILE__, "You did not select a mailing to delete"); }
		
		$in{'page_title'} = "Delete Mailing";
		$in{'confirm_data'} = (join "::", $user, $listid, $in{'mailid'});
		$in{'QUERY_STRING'} = "menu=followup&action=schedule_delete";
		$in{'confirm_text'} = "Are you sure you want to delete the selected mailing?";
		
		print &parse_template('admin/confirm.htmlt');
		exit(0);

	} else {
		my ($num, $x, $date, $time, @mail);
		
		## Get needed info
		($num) = $listid =~ /^(\d+)\..+/;
		@mail = &readfile("$datadir/list/$user/$num.mail");
		($date, $time) = &getdate;
		
		## Process scheduled mailings
		$x=0;
		foreach $line (@mail) {
			next if $line eq '';
			my ($date, $file) = split /::/, $line;
			my @message = &readfile("$datadir/list/$user/$file");
			
			push @{$in{'mailid'}}, $x;
			push @{$in{'message_name'}}, (shift @message);
			push @{$in{'mail_date'}}, (&format_date(&num2date($date)));
		$x++; }
		
		## Get ready to print HTML template
		$in{'listname'} = $info{$listid}{'name'};
 		$in{'maildate_html'} = &ezylist_get_datehtml((&translate_date($date) + 1));
		print &parse_template('admin/followup/schedule.htmlt');
		exit(0);
		
	}

}

################################################
## Schedule mailings - edit mailing
################################################

sub followup_schedule_edit {
	my ($user, $listid, $id, $num, $newdate, $cdate, $file, $date, $time, $message, @mail);
	
	## Get needed info
	($user, $listid, $id) = ($in{'username'}, $in{'list_id'}, $in{'mailid'});
	($num) = $listid =~ /^(\d+)\..+/;
	@mail = &readfile("$datadir/list/$user/$num.mail");
	($cdate, $file) = split /::/, $mail[$id];
	
	## Get scheduled mailing date
	$newdate = join "-", $in{'nextdate_month'}, $in{'nextdate_day'}, $in{'nextdate_year'};
	$newdate = &translate_date($newdate);
		
	## Make sure mailing date is later than today's date
	($date, $time) = &getdate;
	$date = &translate_date($date);
	if ($date >= $newdate) { &error(500, __LINE__, __FILE__, "The mailing date must be set later than today's date"); }
	
	## Format the e-mail message	
	$message = &format_message($in{'_html'}, $in{'subject'}, $in{'contents'});
	$message = $in{'name'} . "\n" . $message;
	
	## Change line in x.mail file
	splice @mail, $id, 1, (join "::", $newdate, $file);
	
	## Save info to server
	&writefile("$datadir/list/$user/$num.mail", @mail);
	&writefile("$datadir/list/$user/$file", $message);
	
	## Print HTML success template
	&success("Successfully edited selected mailing");
}

################################################
## Schedule mailings - delete mailing
################################################

sub followup_schedule_delete {
	my ($user, $listid, $id, $num, @mail);
	
	## Get needed info
	($user, $listid, $id) = split /::/, $in{'confirm_data'};
	($num) = $listid =~ /^(\d+)\..+/;
	@mail = &readfile("$datadir/list/$user/$num.mail");
	($date, $file) = split /::/, $mail[$id];
	
	## See if we wanted to delete mailing or not
	if ($in{'confirm'} == 0) { &success("Did not delete the selected mailing"); }
	
	## Delete the mailing
	splice @mail, $id, 1;
	&deletefile("$datadir/list/$user/$file");
	&writefile("$datadir/list/$user/$num.mail", @mail);
	
	## Print HTML success template
	&success("Successfully deleted the scheduled mailing");
	
}

################################################
## Create messsage
################################################

sub followup_create {

	## Make sure both, user and list exist
	my ($user, $listid) = ($in{'username'}, $in{'list_id'});
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
	elsif ($listid eq '') { &error(500, __LINE__, __FILE__, "You did not select a mailing list"); }
	elsif (!-e "$datadir/list/$user/$listid") { &error(500, __LINE__, __FILE__, "Invalid mailing list, <b>$listid</b>"); }

	## Figure out what to do
	if ($in{'action2'} eq 'create') {
		my ($x, $message, $index, $buffer, $attachment, $attachfile);
		
		## Peform a few checks
		if ($in{'name'} eq '') { &error(500, __LINE__, __FILE__, "You did not specify a name for the e-mail message"); }

		## Create and format the e-mail message
		$message = &format_message($in{'_html'}, $in{'subject'}, $in{'contents'});
		$message = "Follow Up Message\n" . $message;
	
		## Save the message to the server
		$x=1;
		$x++ while -e "$datadir/list/$user/$x.msg";
		&writefile("$datadir/list/$user/$x.msg", $message);

		## If needed, get the attachment
		if ($in{'attachment'} ne '') {
			&uploadfile('attachment', "$datadir/list/$user/$x.attach");

			if ($in{'attachment'} =~ /\\/) { ($attachfile) = $in{'attachment'} =~ /.*\\(.*)/; }
			elsif ($in{'attachment'} =~ /\//) { ($attachfile) = $in{'attachment'} =~ /.*\/(.*)/; }
			else { $attachfile = $in{'attachment'}; }
		}
		
		## Create line for index.dat file
		$index = join "::", 'message', $in{'name'}, "$x.msg", $listid, $attachfile;
		&appendfile("$datadir/list/$user/index.dat", $index);

		## Print off HTML success text
		&success("Successfully created the follow up message, <b>$in{'name'}</b>");

	} else {
		## Get merge fields
		%info = &ezylist_get_listinfo($user);
		splice @{$info{$listid}{'fields'}}, 0, 4;
		foreach $field (@{$info{$listid}{'fields'}}) { $in{'merge_options'} .= "<option>$field"; }
#		$in{'merge_options'} .= qq!<option>unsubscribe_link!;

		## Print HTML template
		print &parse_template('admin/followup/create.htmlt');
		exit(0);
	}
}

################################################
## Edit messsage
################################################

sub followup_edit {
	my ($user, %info);

	## Make sure user exists
	$user = $in{'username'};
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
	%info = &ezylist_get_listinfo($user);

	if ($in{'action'} eq 'getmsg') {
		my ($msgid, $listid, $html, @message);

		## Perform a few checks
		($msgid, $listid, $in{'attachfile'}) = ($in{'message'}, $info{$in{'message'}}{'list'}, $info{$in{'message'}}{'attach'});
		if ($msgid eq '') { &error(500, __LINE__, __FILE__, "You did not select a message to edit"); }

		## Get and parse message
		@message = &readfile("$datadir/list/$user/$msgid");
		shift @message;
		$in{'name'} = $info{$in{'message'}}{'name'};
		$in{'subject'} = (shift @message);
		$html = (shift @message);

		## Format a few variables
		$in{'subject'} =~ s/^Subject: //;
		$in{'contents'} = join "\n", @message;
		$in{'contents'} =~ s/^\n//;
		if ($html =~ /html/) { $in{'html'} = "checked"; }
		else { $in{'html'} = ""; }

		## Get merge options
		splice @{$info{$listid}{'fields'}}, 0, 4;
		foreach $field (@{$info{$listid}{'fields'}}) {
			$in{'merge_options'} .= "<option>$field";
		}
#		$in{'merge_options'} .= "<option>unsubscribe_link";

		## Print HTML template
		print &parse_template('admin/followup/edit.htmlt');
		exit(0);

	} else {
		my (%lists);

		foreach $key (keys %info) {
			next unless $info{$key}{'type'} eq 'message';
			$lists{$info{$key}{'list'}} .= qq!<input type="radio" name="message" value="$key">$info{$key}{'name'}<br>!;
		}

		foreach $key (keys %info) {
			next unless $info{$key}{'type'} eq 'list';
			push @{$in{'listname'}}, $info{$key}{'name'};
			push @{$in{'listmsg'}}, $lists{$key};
		}

		## Print HTML template
		$in{'page_title'} = "Edit Message";
		print &parse_template('admin/followup/get_message.htmlt');
		exit(0);

	}
}

################################################
## Edit messsage - part 2
################################################

sub followup_edit2 {

	## Create and format the e-mail message
	$message = &format_message($in{'_html'}, $in{'subject'}, $in{'contents'});
	$message = "Follow Up Message\n" . $message;
	
	## Save the message to the server
	&writefile("$datadir/list/$in{'username'}/$in{'message'}", $message);

	## If needed, get the attachment
	if ($in{'attachment'} ne '') {
		($num) = $in{'message'} =~ /^\d/;
		while (read($in{'attachment'}, $buffer, 1024)) { $attachment .= $buffer; }
		&writefile("$datadir/list/$user/$num.attach", $attachment);

		if ($in{'attachment'} =~ /\\/) { ($attachfile) = $in{'attachment'} =~ /.*\\(.*)/; }
		elsif ($in{'attachment'} =~ /\//) { ($attachfile) = $in{'attachment'} =~ /.*\/(.*)/; }
		else { $attachfile = $in{'attachment'}; }
		
		## Update the index.dat file
		$x=0;
		@index = &readfile("$datadir/list/$in{'username'}/index.dat");
		foreach $line (@index) {
			my @line = split /::/, $line;
			if ($line[2] eq $in{'message'}) {
				$line[4] = $attachfile;
				$index[$x] = (join "::", @line);
				&writefile("$datadir/list/$in{'username'}/index.dat", @index);
			}
		$x++; }
	}

	## Print off HTML success text
	&success("Successfully edited the selected follow up message");
}


################################################
## Delete message
################################################

sub followup_delete {

	## Figure out what to do
	if (exists $in{'confirm'}) {
		my ($x, $user, $message, $name, @index);

		## Get needed info
		($user, $message) = split /::/, $in{'confirm_data'};
		if ($in{'confirm'} == 0) { &success("Did not delete the selected follow up message"); }

		## Delete message from index.dat file
		$x=0;
		@index = &readfile("$datadir/list/$user/index.dat");
		foreach $line (@index) {
			my @line = split /::/, $line;
			if ($line[2] eq $message) {
				$name = $line[1];
				splice @index, $x, 1;
				last;
			}
		$x++; }

		## Delete message from server
		($num) = $message =~ /^\d+/;
		&writefile("$datadir/list/$user/index.dat", @index);
		&deletefile("$datadir/list/$user/$message");
		&deletefile("$datadir/list/$user/$num.attach");

		## Print off HTML success page
		&success("Successfully deleted the follow up message, <b>$name</b>");

	} elsif ($in{'action'} eq 'getmsg') {
		my ($user, %info);

		## Make sure user exists
		$user = $in{'username'};
		my ($status, $type) = &get_ext($user);
		if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
		if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
		%info = &ezylist_get_listinfo($user);

		if ($in{'message'} eq '') { &error(500, __LINE__, __FILE__, "You did not select a message to delete"); }

		$in{'page_title'} = "Delete Message";
		$in{'confirm_data'} = (join "::", $user, $in{'message'});
		$in{'confirm_text'} = "Are you sure you want to delete the follow up message, <b>$info{$in{'message'}}{'name'}</b>?";
		print &parse_template('admin/confirm.htmlt');
		exit(0);

	} else {
		my ($user, %info, %lists);

		## Make sure user exists
		$user = $in{'username'};
		my ($status, $type) = &get_ext($user);
		if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
		if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
		%info = &ezylist_get_listinfo($user);

		foreach $key (keys %info) {
			next unless $info{$key}{'type'} eq 'message';
			$lists{$info{$key}{'list'}} .= qq!<input type="radio" name="message" value="$key">$info{$key}{'name'}<br>!;
		}

		foreach $key (keys %info) {
			next unless $info{$key}{'type'} eq 'list';
			push @{$in{'listname'}}, $info{$key}{'name'};
			push @{$in{'listmsg'}}, $lists{$key};
		}

		## Print HTML template
		$in{'page_title'} = "Delete Message";
		print &parse_template('admin/followup/get_message.htmlt');
		exit(0);

	}

}

################################################
## View followup logs
################################################

sub followup_viewlogs {
	my ($user, $listid, $num, $date, $time, $days, @log, @error);
	
	## Get needed info
	($user, $listid) = ($in{'username'}, $in{'list_id'});
	($num) = $listid =~ /^(\d+)\..+/;
	($date, $time) = &getdate;
	$days = &translate_date($date);
	
	## Get seven most recent dates
	for ( 1 .. 7 ) {
		$days--;
		next if !-e "$datadir/list/$user/log/$num/$days";
		push @{$in{'date'}}, $days;
		push @{$in{'date_format'}}, &format_date(&num2date($days));
	}
	
	## Get HTML to specify a date
	$days = &translate_date($date);
	$days--;
	$in{'date_html'} = &ezylist_get_datehtml($days);
	
	## Perform a couple checks
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
	elsif ($listid eq '') { &error(500, __LINE__, __FILE__, "You did not select a mailing list"); }
	
	## Print needed HTML template
	print &parse_template('admin/followup/viewlog.htmlt');
	exit(0);
	
}

################################################
## View followup logs - part 2
################################################

sub followup_viewlogs2 {
	my ($user, $listid, $start, $days, $num, @entries);

	## Get needed info
	if ($PARSE == 1) { ($user, $listid, $start) = ($in{'username'}, $in{'list_id'}, 0); }
	else {
		($user, $info, $start) = ($query{'username'}, $query{'listid'}, $query{'start'});
		($listid, $date) = split /,/, $info; $in{'date'} = $date;
		($in{'username'}, $in{'list_id'}) = ($user, $listid);
	}
	%info = &ezylist_get_listinfo($user);
	($num) = $listid =~ /^(\d+)\..+/;
	
	## Get file to view
	if ($in{'date'} ne '') { $days = $in{'date'}; }
	else {
		my $newdate = join "-", $in{'nextdate_month'}, $in{'nextdate_day'}, $in{'nextdate_year'};
		$days = &translate_date($newdate);
	}

	## Make sure log file exists
	if (!-e "$datadir/list/$user/log/$num/$days") {
		my $error_date = &format_date(&num2date($days));
		&error(500, __LINE__, __FILE__, "No follow ups occured on the selected date, <b>$error_date</b>");
	}
	
	## Get entries to show
	@entries = &ezylist_get_browse_info($user, "$listid,$days", "$datadir/list/$user/log/$num/$days", $start, "menu=followup&action=viewlogs2");
	
	## Get total messages sent
	$in{'total_sent'} = 0;
	open FILE, "$datadir/list/$user/log/$num/$days" or &error(201, __LINE__, __FILE__, "$datadir/list/$user/log/$num/$days");
	while (<FILE>) { $in{'total_sent'}++; }
	close FILE;

	## Process the entries to show
	foreach $line (@entries) {
		my ($x, $entryid, $msgname, $cycle, $entry_html, @entry);

		## Get needed info
		@entry = split /::/, $line;
		($entryid, $msgname, $cycle) = splice @entry, 0, 3;

		## Create entry HTML
		$entry_html = qq!<td nowrap><FONT_BODY>$entryid</font></td>!;
		$entry_html .= qq!<td nowrap><FONT_BODY>$msgname</font></td>!;
		$entry_html .= qq!<td nowrap><FONT_BODY>$cycle</font></td>!;

		foreach $field (@entry) {
			$entry_html .= qq!<td nowrap><FONT_BODY>$field</font></td>!;
		}

		push @{$in{'list_entry'}}, $entry_html;
	}
	
	## Get ready to print HTML template
	$in{'listname'} = $info{$listid}{'name'};
	splice @{$info{$listid}{'fields'}}, 0, 4;
	$in{'listfield'} = [ @{$info{$listid}{'fields'}} ];

	## Print HTML template
	$in{'days'} = $days;
	$in{'date'} = &format_date(&num2date($days));
	$in{'qmark'} = "?"; $in{'smark'} = "|";
	print &parse_template('admin/followup/viewlog2.htmlt');
	exit(0);

}

################################################
## View followup logs - error log
################################################

sub followup_viewlogs_error {
	my ($user, $listid, $start, $days, $num, @entries, %error);

	## Get needed info
	if ($PARSE == 1) { ($user, $listid, $start) = ($in{'username'}, $in{'list_id'}, 0); }
	else {
		($user, $info, $start) = ($query{'username'}, $query{'listid'}, $query{'start'});
		($listid, $date) = split /,/, $info; $in{'date'} = $date;
		($in{'username'}, $in{'list_id'}) = ($user, $listid);
	}
	%info = &ezylist_get_listinfo($user);
	%error = &ezylist_get_error_message;
	($num) = $listid =~ /^(\d+)\..+/;
	
	## Get file to view
	if ($in{'date'} ne '') { $days = $in{'date'}; }
	else { &error(500, __LINE__, __FILE__, "No date to view"); }

	## Make sure log file exists
	if (!-e "$datadir/list/$user/error/$num/$days") {
		my $error_date = &format_date(&num2date($days));
		&error(500, __LINE__, __FILE__, "No errors occured on the selected date, <b>$error_date</b>");
	}
	
	## Get entries to show
	@entries = &ezylist_get_browse_info($user, "$listid,$days", "$datadir/list/$user/error/$num/$days", $start, "menu=followup&action=viewlogs_error");
	
	## Get total messages sent
	$in{'total_errors'} = 0;
	open FILE, "$datadir/list/$user/error/$num/$days" or &error(201, __LINE__, __FILE__, "$datadir/list/$user/error/$num/$days");
	while (<FILE>) { $in{'total_errors'}++; }
	close FILE;

	## Process the entries to show
	foreach $line (@entries) {
		my ($x, $entryid, $code, $msgname, $cycle, $entry_html, @entry);

		## Get needed info
		@entry = split /::/, $line;
		($entryid, $code, $msgname, $cycle) = splice @entry, 0, 4;

		## Create entry HTML
		$entry_html = qq!<td nowrap><FONT_BODY>$entryid</font></td>!;
		$entry_html .= qq!<td nowrap><FONT_BODY>$error{$code}</font></td>!;
		$entry_html .= qq!<td nowrap><FONT_BODY>$msgname</font></td>!;
		$entry_html .= qq!<td nowrap><FONT_BODY>$cycle</font></td>!;

		foreach $field (@entry) {
			$entry_html .= qq!<td nowrap><FONT_BODY>$field</font></td>!;
		}

		push @{$in{'list_entry'}}, $entry_html;
	}
	
	## Get ready to print HTML template
	$in{'listname'} = $info{$listid}{'name'};
	splice @{$info{$listid}{'fields'}}, 0, 4;
	$in{'listfield'} = [ @{$info{$listid}{'fields'}} ];

	## Print HTML template
	$in{'days'} = $days;
	$in{'date'} = &format_date(&num2date($days));
	$in{'qmark'} = "?"; $in{'smark'} = "|";
	print &parse_template('admin/followup/viewlog_error.htmlt');
	exit(0);

}

1;

