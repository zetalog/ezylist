
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

## See if we need to get a username or mailing list
%ezylist_needuser = (
	'communicate_notify' => 'Notify Member', 
	'member_activate' => 'Activate Member', 
	'member_deactivate' => 'Deactivate Member', 
	'database_edit' => 'Edit Member', 
	'database_delete' => 'Delete Member', 
	'database_view' => 'View Member', 
	'database_activate' => 'Activate Member', 
	'database_deactivate' => 'Deactivate Member', 
	'lists_create' => 'Create Mailing List', 
	'lists_manage' => 'Manage Mailing List', 
	'lists_delete' => 'Delete Mailng List', 
	'lists_edit' => 'Edit Mailing List', 
	'lists_browse' => 'Browse Mailing List', 
	'lists_welcome' => 'Set Welcome Message', 
	'lists_archive' => 'Manage Archived Lists', 
	'lists_import' => 'Import Mailing List', 
	'lists_export' => 'Export Mailing List', 
	'followup_manage' => 'Manage Follow Ups', 
	'followup_schedule' => 'Schedule Mailings', 
	'followup_create' => 'Create Message', 
	'followup_edit' => 'Edit Message', 
	'followup_delete' => 'Delete Message', 
	'followup_viewlogs' => 'View Follow Up Logs', 
	'ar_create' => 'Create Auto Responder', 
	'ar_edit' => 'Edit Auto Responder', 
	'ar_delete' => 'Delete Auto Responder', 
	'ar_view' => 'View Autoresponder', 
	'ad_create' => 'Create Advertisement', 
	'ad_manage' => 'Manage Advertisement', 
	'ad_edit' => 'Edit Advertisement', 
	'ad_delete' => 'Delete Advertisement'
);

%ezylist_needlist = (
	'lists_form' => 'Generate Subscribe Form', 
	'lists_delete' => 'Delete Mailing List', 
	'lists_edit' => 'Edit Mailing List', 
	'lists_browse' => 'Browse Mailing List', 
	'lists_welcome' => 'Set Welcome Message', 
	'lists_archive' => 'Manage Archived Lists', 
	'lists_import' => 'Import Mailing List', 
	'lists_export' => 'Export Mailing List', 
	'followup_manage' => 'Manage Follow Ups', 
	'followup_schedule' => 'Schedule Mailings', 
	'followup_create' => 'Create Message', 
	'followup_viewlogs' => 'View Follow Up Logs'
);

%ezylist_needad = (
	'ad_edit' => 'Edit Advertisement', 
	'ad_delete' => 'Delete Advertisement'
);

if ($ADMIN == 1) {
	if ((exists $ezylist_needuser{$SUB}) && ($PARSE == 0)) {
		unless ((($SUB eq 'lists_browse') || ($SUB eq 'lists_archive') || ($SUB eq 'followup_viewlogs2')) && (exists $query{'start'})) {
			$in{'title'} = $ezylist_needuser{$SUB}; &print_header; 
			print &parse_template('admin/get_account.htmlt', 'main');
			exit(0);
		}
	} elsif ((exists $ezylist_needuser{$SUB}) && ($in{'display_all_accounts'} == 1)) {
		&display_all_accounts($ezylist_needuser{$SUB});
	}
}

## See if we need a mailing list
if ((exists $ezylist_needlist{$SUB}) && ($in{'action'} ne 'getlist')) {
	return 1 if $SUB eq 'lists_browse' && exists $query{'start'};
	return 1 if $SUB eq 'lists_archive' && exists $query{'start'};
	return 1 if $SUB eq 'followup_viewlogs2' && exists $query{'start'};
	return 1 if $SUB eq 'lists_welcome' && ($in{'step'} eq 'welcome');

	&ezylist_get_listhtml($in{'username'});
	$in{'title'} = $ezylist_needlist{$SUB}; &print_header;
	
	if ($ADMIN == 1) { print &parse_template('admin/get_list.htmlt', 'main'); exit(0); }
	elsif ($CPANEL == 1) { print &parse_template('cpanel/get_list.htmlt', 'main'); }
	else { &error(500, __LINE__, __FILE__, "Unable to determine template to display"); }
	exit(0);
} 

## See if we need a advertisement
if ((exists $ezylist_needad{$SUB}) && ((!exists $in{'ad_id'}) || ($in{'ad_id'} eq ''))) {
	&ezylist_get_adhtml($in{'username'});
	$in{'title'} = $ezylist_needad{$SUB}; &print_header;
	
	if ($ADMIN == 1) { print &parse_template('admin/get_ad.htmlt', 'main'); exit(0); }
	elsif ($CPANEL == 1) { print &parse_template('cpanel/get_ad.htmlt', 'main'); }
	else { &error(500, __LINE__, __FILE__, "Unable to determine template to display"); }
	exit(0);
} 

################################################
## Get user's conf info
################################################

sub ezylist_get_conf {
	my $user = shift;
	my (%conf);

	## Make sure user exists
	if (!defined &get_ext($user)) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }

	## Get info from conf file
	%conf = &parse_conf($user, 'conf', 'EZYLIST_ARNUM', 'EZYLIST_LISTNUM', 'EZYLIST_MSGNUM', 'EZYLIST_CYCLENUM', 'EZYLIST_MAXSCH', 'EZYLIST_MAXNUM');
	return (@{$conf{'EZYLIST_ARNUM'}}->[0], @{$conf{'EZYLIST_LISTNUM'}}->[0], @{$conf{'EZYLIST_MSGNUM'}}->[0], @{$conf{'EZYLIST_CYCLENUM'}}->[0], @{$conf{'EZYLIST_MAXSCH'}}, @{$conf{'EZYLIST_MAXNUM'}}->[0]);
}

################################################
## Get user's advertisement info
################################################

sub ezylist_get_adinfo {
	my $user = shift;
	my (@adinfo, %info);

	my ($status, $type) = &get_ext($user);
	## Make sure user exists
	if (!status || !$type) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type ne "advertiser") { &error(500, __LINE__, __FILE__, "User is not advertiser, <b>$user</b>"); }

	## Get needed info
	return undef if !-e "$datadir/ad/$user/index.dat";
	@adinfo = &readfile("$datadir/ad/$user/index.dat");

	## Parse through the list info
	foreach $line (@adinfo) {
		next if $line eq '';
		my ($type, $name, $file, $image, $index, $swf) = split /::/, $line;
		$info{$file}{'type'} = $type;
		$info{$file}{'name'} = $name;
		if ($type eq 'advertisement') {
			$info{$file}{'name'} = $name;
			$info{$file}{'image'} = $image;
			$info{$file}{'index'} = $index;
			$info{$file}{'swf'} = $swf;
		}
	}

	## Return advertisement info
	return %info;
}

################################################
## Get advertisement HTML
################################################

sub ezylist_get_adhtml {
	my $user = shift;
	my %info = &ezylist_get_adinfo($user);
	my (@names, %ad);

	## Sort alphabetically
	foreach $key (keys %info) {
		my ($displayed, $clicked);
		next unless $info{$key}{'type'} eq 'advertisement';
		push @{$in{'ad_id'}}, $key;
		push @{$in{'ad_name'}}, $info{$key}{'name'};
		$displayed = &ezylist_displayedad($user, $key);
		$clicked = &ezylist_clickedad($user, $key);
		push @{$in{'ad_displayed'}}, $displayed;
		push @{$in{'ad_clicked'}}, $clicked;
	}
	
	return 1;
}

################################################
## Save advertisement index
################################################

sub ezylist_save_adindex {
	my ($user, $ad_id) = @_;

	my $count, $index;

	$count = 1;
	$count++ while -e "$datadir/ad/$count.ad";
	$index = join "::", $user, $ad_id;
	&writefile("$datadir/ad/$count.ad", $index);

	return $count;

}

################################################
## Count number of advertisement's displayed times
################################################

sub ezylist_displayedad {
	my ($user, $ad_id) = @_;
	my ($displayed, $num);


	($num) = $ad_id =~ /^(\d+)\..+/;
	$displayed = &readfile("$datadir/ad/$user/$num.displayed");

	return $displayed;
}

################################################
## Count number of advertisement's clicked times
################################################

sub ezylist_clickedad {
	my ($user, $ad_id) = @_;
	my ($clicked, $num);


	($num) = $ad_id =~ /^(\d+)\..+/;
	$clicked = &readfile("$datadir/ad/$user/$num.clicked");

	return $clicked;

}

################################################
## Get user's list info
################################################

sub ezylist_get_listinfo {
	my $user = shift;
	my (@listinfo, %info);

	## Make sure user exists
	if (!defined &get_ext($user)) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }

	## Get needed info
	return undef if !-e "$datadir/list/$user/index.dat";
	@listinfo = &readfile("$datadir/list/$user/index.dat");

	## Parse through the list info
	foreach $line (@listinfo) {
		next if $line eq '';
		my ($type, $name, $file, $efield, $nfield, $welcome, $fields) = split /::/, $line;
		$info{$file}{'type'} = $type;
		$info{$file}{'name'} = $name;
		if ($type eq 'list') {
			@{$info{$file}{'fields'}} = split /,/, $fields;
			$info{$file}{'efield'} = $efield;
			$info{$file}{'nfield'} = $nfield;
			$info{$file}{'welcome'} = $welcome;
		} elsif ($type eq 'message') {
			$info{$file}{'list'} = $efield;
			$info{$file}{'attach'} = $nfield;
		}
	}

	## Return list info
	return %info;

}

################################################
## Get list HTML
################################################

sub ezylist_get_listhtml {
	my $user = shift;
	my %info = &ezylist_get_listinfo($user);
	my (@names, $num, %list);
	
	$num = 0;
	## Sort alphabetically
	foreach $key (keys %info) {
		next unless $info{$key}{'type'} eq 'list';
		$num++;
		push @names, $info{$key}{'name'};
		$list{$info{$key}{'name'}} = $key;
	}
	&error(500, __LINE__, __FILE__, "No mailing list exists.") if ($num == 0);
	@names = sort { $a cmp $b } @names;
	
	## Parse list info
	foreach $name (@names) {
		$file = $list{$name};
		next unless $info{$file}{'type'} eq 'list';
		my $count = 0;

		open LIST, "$datadir/list/$user/$file" or &error(201, __LINE__, __FILE__, "$datadir/list/$user/$file", "LIST");
		&lockfile('LIST');
		while (<LIST>) { $count++; }
		&unlockfile('LIST');
		close LIST;
		
		push @{$in{'list_id'}}, $file;
		push @{$in{'list_name'}}, $name;
		push @{$in{'list_subscribers'}}, $count;
	}

	return 1;

}

################################################
## Count number of subscribers in mailing list
################################################

sub ezylist_countlist {
	my ($user, $listid) = @_;
	my $count = 0;

	open LIST, "$datadir/list/$user/$listid" or &error(201, __LINE__, __FILE__, "$datadir/list/$user/$listid", "LIST");
	&lockfile('LIST');
	while (<LIST>) { $count++; }
	&unlockfile('LIST');
	close LIST;

	return $count;

}

################################################
## Check a list for an e-mail address
################################################

sub ezylist_checklist {
	my ($user, $listid, $id) = @_;
	my ($found, $row, @listinfo, %info);

	## Get needed info
	@listinfo = &readfile("$datadir/list/$user/$listid");

	## Are we looking for an e-mail address or ID#
	if ($id =~ /.*\@.*\..*/) { 
		%info = &ezylist_get_listinfo($user);
		$row = $info{$listid}{'efield'};
	} else { $row = 0; }

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
## Get an entry from mailing list
################################################

sub ezylist_get_entry {
	my ($user, $listid, $id) = @_;
	my ($found, $row, @listinfo, @entry, %info);

	## Get needed info
	@listinfo = &readfile("$datadir/list/$user/$listid");

	## Are we looking for an e-mail address or ID#
	if ($id =~ /.*\@.*\..*/) { 
		%info = &ezylist_get_listinfo($user);
		$row = $info{$listid}{'efield'};
	} else { $row = 0; }

	## Find entry in mailing list
	foreach $line (@listinfo) {
		my @line = split /::/, $line;
		if ($line[$row] eq $id) {
			@entry = split /::/, $line;
			$found=1; last;
		}
	}

	## Return the results
	return ($found, @entry);

}

################################################
## Replace an entry in mailing list
################################################

sub ezylist_replace_entry {
	my ($user, $listid, $id, $entry) = @_;
	my ($x, $ok, @listinfo);

	## Get needed info
	$ok=0; $x=0;
	@listinfo = &readfile("$datadir/list/$user/$listid");

	## Find entry in mailing list
	foreach $line (@listinfo) {
		my @line = split /::/, $line;
		if ($line[0] eq $id) {
			splice @listinfo, $x, 1, $entry;
			$ok=1; last;
		}
	$x++; }

	## Rewrite the mailing list
	return 0 if $ok != 1;
	&writefile("$datadir/list/$user/$listid", @listinfo);

	## Return results
	return $ok;
}

################################################
## Delete an entry from mailing list
################################################

sub ezylist_delete_entry {
	my ($user, $listid, $id) = @_;
	my ($x, $ok, $row, @listinfo, %info);

	## Get needed info
	$x=0; $ok=0;
	@listinfo = &readfile("$datadir/list/$user/$listid");

	## Are we looking for an e-mail address or ID#
	if ($id =~ /.*\@.*\..*/) { 
		%info = &ezylist_get_listinfo($user);
		$row = $info{$listid}{'efield'};
	} else { $row = 0; }

	## Find entry in mailing list
	foreach $line (@listinfo) {
		my @line = split /::/, $line;
		if ($line[$row] eq $id) {
			splice @listinfo, $x, 1;
			$ok=1; last;
		}
	$x++; }

	## Rewrite the mailing list
	return 0 if $ok != 1;
	&writefile("$datadir/list/$user/$listid", @listinfo);

	## Return results
	return $ok;
}


################################################
## Get HTML for a follow up date
################################################

sub ezylist_get_datehtml {
	my $days = shift;
	my ($x, $date, $month, $mday, $year, $html, @months);

	## Get needed info
	$date = &num2date($days);
	($month, $mday, $year) = split /-/, $date;
	$html = qq!<select name="nextdate_month">!;

	## Get the array of months
	if ($moptions[4] == 1) { @months = qw (space 01 02 03 04 05 06 07 08 09 10 11 12); }
	elsif ($moptions[4] == 2) { @months = qw (space Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec); }
	elsif ($moptions[4] == 3) { @months = qw (space January February March April May June July August September October November December); }

	## Get months HTML
	for $x ( 1 .. 12 ) { 
		my $chk = "selected" if $month == $x;
		$html .= qq!<option value="$x" $chk>$months[$x]!;
	}

	## Add divider HTML
	if ($moptions[4] == 1) { $html .= qq!</select><FONT_BODY> / </font><select name="nextdate_day">!; }
	elsif ($moptions[4] == 2) { $html .= qq!</select><FONT_BODY> - </font><select name="nextdate_day">!; }
	elsif ($moptions[4] == 3) { $html .= qq!</select><FONT_BODY>  </font><select name="nextdate_day">!; }

	## Get days HTML
	for $x ( 1 .. 31 ) {
		my $chk = "selected" if $mday == $x;
		my $var = sprintf "%.2d", $x;
		$html .= qq!<option value="$x" $chk>$var!;
	}

	## Add divider HTML
	if ($moptions[4] == 1) { $html .= qq!</select><FONT_BODY> / </font><select name="nextdate_year">!; }
	elsif ($moptions[4] == 2) { $html .= qq!</select><FONT_BODY> - </font><select name="nextdate_year">!; }
	elsif ($moptions[4] == 3) { $html .= qq!</select><FONT_BODY> , </font><select name="nextdate_year">!; }

	## Get years HTML
	for $x ( 2001 .. 2025 ) {
		my $var;
		my $chk = "selected" if $year == $x;
		if ($moptions[4] == 1) { $var = $x; $var =~ s/^..//; }
		else { $var = $x; }
		
		$html .= qq!<option value="$x" $chk>$var!;
	}

	## Finish up and return results
	$html .= "</select>\n\n";
	return $html;



}

################################################
## Add entry to mailing list
################################################

sub ezylist_addentry {
	my ($user, $listid) = @_;
	my ($id, $next, $num, $efield, $email, $exists, $days, $message, $date, $time, @entry, @response, @cycle, @listfields, %info);
	
	## Perform a couple checks
	if (!defined &get_ext($user)) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	elsif ($listid eq '') { &error(500, __LINE__, __FILE__, "You did not select a mailing list to manage"); }

	## Get needed info
	($num) = $listid =~ /^(\d+)\..+/;
	%info = &ezylist_get_listinfo($user);
	@listfields = @{$info{$listid}{'fields'}};
	$efield = $listfields[$info{$listid}{'efield'}];
	$email = lc($in{"add_$efield"});
	$in{"add_$efield"} = $email;
	
	$exists = &ezylist_checklist($user, $listid, $email);
	@cycle = &readfile("$datadir/list/$user/$num.cycle");
	($days, $message) = split /::/, $cycle[0];
	($date, $time) = &getdate;

	## Perform a couple checks
	if ($email !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid e-mail address, <b>$email</b>"); }
	elsif ($exists == 1) { &error(500, __LINE__, __FILE__, "E-mail address already exists in mailing list, <b>$email</b>"); }
	elsif ($cycle[0] eq '') { &error(500, __LINE__, __FILE__, "You have not yet added any follow up cycles for this mailing list"); }

	## Create new ID
	$id = &readfile("$datadir/list/$user/$num.count"); $id++;
	&writefile("$datadir/list/$user/$num.count", $id);
	$id = sprintf "%.3d", $id;

	## Create next follow up date
	$next = &translate_date($date);
	$next += $days;
	
	## Create new entry for list
	@entry = ($id, $next, $message, 1);
	splice @listfields, 0, 4;
	foreach $field (@listfields) {
		if ($in{$field} =~ /::/) { &error(500, __LINE__, __FILE__, "List fields can not contain, <b>::</b>"); }
		push @entry, $in{"add_$field"};
	}
	$entry = join "::", @entry;
	
	## Add entry to list
	&appendfile("$datadir/list/$user/$listid", $entry);
	
	## If needed, send a welcome message
	if ($info{$listid}{'welcome'} ne '') {
		foreach (@listfields) { $in{$_} = $in{"add_$_"}; }
		my ($from_name, $from_email, $from_pass) = &get_variable($user, $userfields[$dbfields[0]], $userfields[$dbfields[1]], $userfields[$dbfields[2]]);
#		$in{'unsubscribe_link'} = $cgiurl . "/unsubscribe.cgi?user=$user&listid=$listid&id=$id";
		&mailmsg_from_file($email, "$datadir/list/$user/$info{$listid}{'welcome'}", $from_email, $from_name, $from_pass, %in);
	}
	
	## Get ready to print HTML template
	@response = @entry;
	splice @entry, 0, 4;
	$in{'listfield'} = [ @listfields ];
	$in{'listinfo'} = [ @entry ];

	$in{'entry_id'} = $id;
	$in{'next_date'} = &format_date(&num2date($next));
	$in{'next_message'} = $info{$message}{'name'};
	$in{'listname'} = $info{$listid}{'name'};
	
	## Return the entry
	return @response;
}


################################################
## Get browsing info
################################################

sub ezylist_get_browse_info {
	my ($user, $listid, $file, $start, $qstring) = @_;
	my ($size, $num, @entries, @listinfo);
		
	## Get the list entries to show
	@listinfo = &readfile($file);
	$size = @listinfo;
	@entries = splice @listinfo, $start, 20;

	## Create next link
	$num = ($start + 20);
	if ($num > $size) { $in{'_next'} = 0; }
	else { ($in{'start_next'}, $in{'_next'}) = ($num, 1); }

	## Create previous link
	$num = ($start - 20);
	if ($num < 0) { $in{'_prev'} = 0; }
	else { ($in{'start_previous'}, $in{'_prev'}) = ($num, 1); }

	## Create the jump links
	$in{'jumplinks'} = '';
	if ($start < 40) { $num = 0; }
	else { $num = ($start - 40); }

	for ( 1 .. 5 ) {
		my $jumpstart = ($num + 1);
		my $jumpend = ($num + 20);
		$jumpend = $size if $jumpend > $size;
		last if $jumpstart > $size;
		
		if ($num == $start) { $in{'jumplinks'} .= qq!$jumpstart-$jumpend | !; }
		else { $in{'jumplinks'} .= qq!<a href="$in{'SCRIPT_NAME'}?$qstring&username=$user&listid=$listid&start=$num">$jumpstart-$jumpend</a> | !; }
		$num += 20;
	}

	## Return the entries to show
	return @entries;
	
}

################################################
## Get list of all mail error codes
################################################

sub ezylist_get_error_message {
	my (@error, %error);
	
	@error = &readfile("$datadir/dat/mail_error.dat");
	foreach $line (@error) {
		my ($code, $message) = split /::/, $line;
		$error{$code} = $message;
	}
	
	return %error;

}

1;

