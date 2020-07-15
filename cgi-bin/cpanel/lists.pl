
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
## Set a welcome message for mailing list
################################################

sub lists_welcome {
	my ($user, $id, $num, $status, $type);

	## Get needed info
	($user, $id) = ($in{'username'}, $in{'list_id'});
	($num) = $id =~ /^(\d+)\..+/;
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
	if (!$id || ($id eq "")) { &error(500, __LINE__, __FILE__, "List does not selected, <b>$id</b>"); }

	if ($in{'step'} eq 'welcome') {
		my ($x, $message, @index);
		
		## Get needed info
		$message = $in{'welcome_message'};
		@index = &readfile("$datadir/list/$user/index.dat");
		
		## Replace info in index.dat file
		$x=0;
		foreach $line (@index) {
			my @line = split /::/, $line;
			if ($line[2] eq $id) {
				$line[5] = $message;
				splice @index, $x, 1, (join "::", @line);
				last;
			}
		$x++; }
		
		## Rewrite index.dat file
		&writefile("$datadir/list/$user/index.dat", @index);
		
		## Print off HTML success template
		&success("Successfully set welcome message for the mailing list");
		exit(0);
	} else {
		my (%info);
		%info = &ezylist_get_listinfo($user);

		## Parse welcome message HTML
		if ($info{$id}{'welcome'} ne '') { $in{'welcome_html'} = ", and is sent the e-mail message <b>$info{$info{$id}{'welcome'}}{'name'}</b>"; }
		else { $in{'welcome_html'} = ''; }

		## Start the welcome options HTML
		if ($info{$id}{'welcome'} eq '') { $in{'welcome_options'} = qq!<option value="" selected>No Welcome Message!; }
		else { $in{'welcome_options'} = qq!<option value="">No Welcome Message!; }

		## Get a list of all messages
		foreach $key (keys %info) {
			next unless $info{$key}{'type'} eq 'message';
			my $chk = "selected" if $info{$id}{'welcome'} eq $key;
			$in{'message_options'} .= qq!<option value="$key">$info{$key}{'name'}!;
			$in{'welcome_options'} .= qq!<option value="$key" $chk>$info{$key}{'name'}!;
		}

		## Print the HTML template
		$in{'listname'} = $info{$id}{'name'};
		print &parse_template('admin/lists/welcome.htmlt');
	}
}

################################################
## Create a mailing list
################################################

sub lists_create {
	my ($user, %conf);

	## Make sure user exists
	$user = $in{'username'};
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }

	if ($in{'action'} eq 'create') {
		
		## Perform a few checks
		if ($in{'fieldnum'} =~ /\D/) { &error(500, __LINE__, __FILE__, "Number of fields can only contain digits"); }
		elsif ($in{'listname'} eq '') { &error(500, __LINE__, __FILE__, "You did not specify a name for the mailing list"); }

		## Print HTML template
		for $x ( 1 .. $in{'fieldnum'} ) { push @{$in{'num'}}, $x; }
		print &parse_template('admin/lists/create2.htmlt');
		exit(0);

	} else {
		## Print HTML template
		print &parse_template('admin/lists/create.htmlt');
		exit(0);
	}

}

################################################
## Create a mailing list - part 2
################################################

sub lists_create2 {
	my ($x, $y, $user, $num, $listname, $listfields, $listinfo, @listfields);

	## Get needed info
	$user = $in{'username'};
	$num = $in{'fieldnum'};
	$listname = $in{'listname'};
	@listfields = qw (id next next_message cycle);

	## Perform a few checks
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
	elsif ($num =~ /\D/) { &error(500, __LINE__, __FILE__, "Number of fields can only contain digits"); }
	elsif ($listname eq '') { &error(500, __LINE__, __FILE__, "You did not specify a name for the mailing list"); }

	## Gather up list fields
	$y=4;
	for $x ( 1 .. $num ) {
		my $field = $in{"f$x"};
		if ($field eq '') { &error(500, __LINE__, __FILE__, "You did not specify a name for field $x"); }
		elsif ($field =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Field $x contains spaces or special characters"); }
		push @listfields, $field;
		$in{'listfield_options'} .= "<option value\=\"$y\">\L$field\E\n";
	$y++; }
	$listfields = join ",", @listfields;
	$in{'listfields'} = lc($listfields);

	## Print the HTML template
	print &parse_template('admin/lists/create3.htmlt');
	exit(0);

}

################################################
## Create a mailing list - part 3
################################################

sub lists_create3 {
	my ($x, $user, $num, $listname, $listfields, $listinfo, $email_field, $name_field);

	## Get needed info
	$user = $in{'username'};
	$num = $in{'fieldnum'};
	$listname = $in{'listname'};
	$listfields = $in{'listfields'};
	$email_field = $in{'email_field'};
	$name_field = $in{'name_field'};

	## Perform a few checks
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	elsif ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
	elsif ($num =~ /\D/) { &error(500, __LINE__, __FILE__, "Number of fields can only contain digits"); }
	elsif ($listname eq '') { &error(500, __LINE__, __FILE__, "You did not specify a name for the mailing list"); }
	elsif ($listfields eq '') { &error(500, __LINE__, __FILE__, "No list fields specified"); }
	elsif ($email_field =~ /\D/) { &error(500, __LINE__, __FILE__, "Invalid e-mail field"); }
	elsif (($name_field ne '') && ($name_field =~ /\D/)) { &error(500, __LINE__, __FILE__, "Invalid name field"); }
	elsif (($name_field ne '') && ($name_field == $email_field)) { &error(500, __LINE__, __FILE__, "Field containing names and e-mail addresses can not be the same"); }
	
	## Create mailing list
	$x=1;
	while (-e "$datadir/list/$user/$x.list") { $x++; }
	&writefile("$datadir/list/$user/$x.list");
	&writefile("$datadir/list/$user/$x.cycle");
	&writefile("$datadir/list/$user/$x.mail");
	&writefile("$datadir/list/$user/$x.count", "0");
	&writefile("$datadir/list/$user/$x.archive") if $moptions[7] == 1;
	&makedir("$datadir/list/$user/log/$x") if $moptions[8] == 1;
	&makedir("$datadir/list/$user/error/$x");

	## Add entry to index.dat file
	$listinfo = join "::", 'list', $listname, "$x.list", $email_field, $name_field, '', $listfields;
	&appendfile("$datadir/list/$user/index.dat", $listinfo);

	## Print out the success HTML template
	&success("Successfully created new mailing list, <b>$listname</b>");

}

################################################
## Manage mailing list
################################################

sub lists_manage {
	my ($user, %info);

	## Make sure user exists
	$user = $in{'username'};
	($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }

	if (exists $in{'list_id'}) {
		if ($in{'list_id'} eq '') { &error(500, __LINE__, __FILE__, "You did not select a list to manage"); }
		my $SUB = "lists_" . $in{'action'};
		&$SUB;
	} else {
		&ezylist_get_listhtml($in{'username'});
		$in{'title'} = "Manage Mailing Lists"; &print_header;

		push @{$in{'action'}}, "edit";
		push @{$in{'action'}}, "delete";
		push @{$in{'action'}}, "browse";
	
		print &parse_template('admin/lists/manage.htmlt', 'main');
		exit(0);
	}
}

################################################
## Delete a mailing list
################################################

sub lists_delete {
	my ($user);

	## Make sure user exists
	$user = $in{'username'};
	my ($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }

	if (exists $in{'list_id'}) {
		if ($in{'list_id'} eq '') { &error(500, __LINE__, __FILE__, "You did not select a list to delete"); }
		my %info = &ezylist_get_listinfo($user);

		## Print confirm HTML template
		$in{'page_title'} = "Delete Mailing List";
		$in{'confirm_data'} = join "::", $user, $in{'list_id'};
		$in{'confirm_text'} = "Are you sure you want to delete the mailing list, <b>$info{$in{'list_id'}}{'name'}</b>?";
		$in{'QUERY_STRING'} = "menu=lists&action=delete2";
		print &parse_template('admin/confirm.htmlt');
		exit(0);

	} else {
		
		## Print HTML template
		&ezylist_get_listhtml($user);
		print &parse_template('admin/lists/delete.htmlt');
		exit(0);
	}

}

################################################
## Delete a mailing list - part 2
################################################

sub lists_delete2 {
	my ($x, $ok, $user, $id, $num, @index, %info);

	## Get needed info
	($user, $id) = split /::/, $in{'confirm_data'};
	%info = &ezylist_get_listinfo($user);

	if ($in{'confirm'} == 0) { &success("Did not delete the mailing list, <b>$info{$id}{'name'}</b>"); }

	## Delete list from index.dat file
	$x=0; $ok=0;
	@index = &readfile("$datadir/list/$user/index.dat");
	foreach $line (@index) {
		my ($type, $name, $listid, @info) = split /::/, $line;
		if ($listid eq $id) {
			splice @index, $x, 1;
			$ok=1; last;
		}
	$x++; }
	if ($ok != 1) { &error(500, __LINE__, __FILE__, "List ID does not exist in index file"); }

	## Delete the actual mailing list
	($num) = $id =~ /^(\d+)\..+/;
	&deletefile("$datadir/list/$user/$num.cycle");
	&deletefile("$datadir/list/$user/$num.mail");
	&deletefile("$datadir/list/$user/$num.count");
	&deletefile("$datadir/list/$user/$id");
	&deletefile("$datadir/list/$user/$num.archive") if $moptions[7] == 1;
	&removedir("$datadir/list/$user/log/$num") if $moptions[8] == 1;
	&removedir("$datadir/list/$user/error/$num");
	&writefile("$datadir/list/$user/index.dat", @index);

	## Print off HTML success text
	&success("Successfully deleted the mailing list, <b>$info{$id}{'name'}</b>");

}

################################################
## Edit mailing list
################################################

sub lists_edit {
	my ($user, %info);

	## Make sure user exists
	$user = $in{'username'};
	($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") { &error(500, __LINE__, __FILE__, "User is an advertiser, <b>$user</b>"); }
	elsif ($in{'list_id'} eq '') { &error(500, __LINE__, __FILE__, "You did not select a list to manage"); }

	## Get needed info
	$id = $in{'list_id'};
	$in{'subscribers'} = 0;
	%info = &ezylist_get_listinfo($user);
		
	## Get number of subscribers
	$in{'subscribers'} = &ezylist_countlist($user, $id);

	## Get ready to print HTML template
	$in{'listname'} = $info{$id}{'name'};
	splice @{$info{$id}{'fields'}}, 0, 4;
	$in{'listfield'} = [ @{$info{$id}{'fields'}} ];

	## Print HTML template
	print &parse_template('admin/lists/edit.htmlt');
	exit(0);
}

################################################
## Edit mailing list - part 2
################################################

sub lists_edit2 {
	my ($user, $listid, $num, @listfields, %info);

	## Get needed info
	($user, $listid) = ($in{'username'}, $in{'list_id'});
	($num) = $listid =~ /^(\d+)\..+/;
	%info = &ezylist_get_listinfo($user);
	@listfields = @{$info{$listid}{'fields'}};

	## Perform a couple checks
	if (!defined &get_ext($user)) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	elsif ($listid eq '') { &error(500, __LINE__, __FILE__, "You did not select a mailing list to manage"); }

	## Figure out what to do
	if ($in{'submit'} eq 'Add Entry') {
		
		## Add entry to mailing list
		my @entry = &ezylist_addentry($user, $listid);

		## Print HTML template
		print &parse_template('admin/lists/edit_add_success.htmlt');
		exit(0);

	} elsif ($in{'submit'} eq 'Edit Entry') {
		my ($id, $found, @entry);

		## Get needed info
		$id = lc($in{'id'});
		($found, @entry) = &ezylist_get_entry($user, $listid, $id);
		if ($found != 1) { &error(500, __LINE__, __FILE__, "ID# or e-mail address does not exist in mailing list, <b>$id</b>"); }

		## Get a list of all messages
		foreach $key (keys %info) {
			next unless $info{$key}{'type'} eq 'message';
			my $chk = "selected" if $key eq $entry[2];
			$in{'message_options'} .= qq!<option value="$key" $chk>$info{$key}{'name'}!;
		}

		## Get ready to print HTML template
		$in{'entry_id'} = $entry[0];
		$in{'cycle'} = $entry[3];
		$in{'listname'} = $info{$listid}{'name'};
		$in{'nextdate_html'} = &ezylist_get_datehtml($entry[1]);
		splice @listfields, 0, 4; $in{'listfield'} = [ @listfields ];
		splice @entry, 0, 4; $in{'listinfo'} = [ @entry ];

		## Print HTML template
		print &parse_template('admin/lists/edit_edit.htmlt');
		exit(0);

	} elsif ($in{'submit'} eq 'Delete Entry') {
		my ($id, $found, @entry);

		## Get needed info
		$id = lc($in{'id'});
		($found, @entry) = &ezylist_get_entry($user, $listid, $id);
		if ($found != 1) { &error(500, __LINE__, __FILE__, "ID# or e-mail address does not exist in mailing list, <b>$id</b>"); }

		## Get ready to print HTML template
		$in{'entry_id'} = $entry[0];
		$in{'listname'} = $info{$listid}{'name'};
		$in{'nextdate'} = &format_date(&num2date($entry[1]));
		$in{'next_message'} = $info{$entry[2]}{'name'};
		splice @listfields, 0, 4; $in{'listfield'} = [ @listfields ];
		splice @entry, 0, 4; $in{'listinfo'} = [ @entry ];

		## Print HTML template
		print &parse_template('admin/lists/edit_delete.htmlt');
		exit(0);

	} elsif ($in{'submit'} eq 'View Entry') {
		my ($id, $found, @entry);

		## Get needed info
		$id = lc($in{'id'});
		($found, @entry) = &ezylist_get_entry($user, $listid, $id);
		if ($found != 1) { &error(500, __LINE__, __FILE__, "ID# or e-mail address does not exist in mailing list, <b>$id</b>"); }

		## Get ready to print HTML template
		$in{'entry_id'} = $entry[0];
		$in{'listname'} = $in{'listname'} = $info{$listid}{'name'};
		$in{'nextdate'} = &format_date(&num2date($entry[1]));
		$in{'next_message'} = $info{$entry[2]}{'name'};
		splice @listfields, 0, 4; $in{'listfield'} = [ @listfields ];
		splice @entry, 0, 4; $in{'listinfo'} = [ @entry ];

		## Print HTML template
		print &parse_template('admin/lists/edit_view.htmlt');
		exit(0);

	} elsif ($in{'submit'} eq 'Search Entry') {
		my ($x, @listinfo, %search);

		## Get needed info
		splice @listfields, 0, 4;
		@listinfo = &readfile("$datadir/list/$user/$listid");
		
		## Get a list of all search variables
		$x=0;
		foreach $field (@listfields) {
			if ($in{"search_$field"} ne '') { $search{$x} = $in{"search_$field"}; }
		$x++;}

		## Search through all list entries
		foreach $line (@listinfo) {
			my $ok=0;
			my ($entryid, $next, $next_message, $cycle, @entry) = split /::/, $line;
			
			while (($key, $value) = each %search) {
				next if $ok == 1;
				if ($entry[$key] =~ /$value/i) {
					$next = &format_date(&num2date($next));
					$next_message = $info{$next_message}{'name'};

					## Create entry HTML
					$entry_html = qq!<th nowrap><input type="radio" name="id" value="$entryid"></th>!;
					$entry_html .= qq!<td nowrap><FONT_BODY>$entryid</font></td>!;
					$entry_html .= qq!<td nowrap><FONT_BODY>$next</font></td>!;
					$entry_html .= qq!<td nowrap><FONT_BODY>$next_message</font></td>!;

					foreach $field (@entry) {
						$entry_html .= qq!<td nowrap><FONT_BODY>$field</font></td>!;
					}

					push @{$in{'list_entry'}}, $entry_html;
					$ok=1;
				}
			}			
		}
		
		## Get ready to print HTML template
		$in{'listname'} = $info{$listid}{'name'};
		$in{'listfield'} = [ @listfields ];

		## Print HTML template
		$in{'qmark'} = "?"; $in{'smark'} = "|";
		print &parse_template('admin/lists/search.htmlt');
		exit(0);

	} else { &error(500, __LINE__, __FILE__, "Unknown action"); }

}

################################################
## Edit mailing list - edit entry
################################################

sub lists_edit_edit {
	my ($user, $listid, $id, $efield, $email, $newdate, $success, @entry, @listfields, %info);

	## Get needed info
	($user, $listid, $id) = ($in{'username'}, $in{'list_id'}, $in{'entry_id'});
	%info = &ezylist_get_listinfo($user);
	@listfields = @{$info{$listid}{'fields'}};
	$efield = $listfields[$info{$listid}{'efield'}];
	$email = lc($in{$efield});
	$in{$efield} = $email;

	## Perform a couple checks
	if ($email !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid e-mail address, <b>$email</b>"); }

	## Gather up the new entry
	$newdate = join "-", $in{'nextdate_month'}, $in{'nextdate_day'}, $in{'nextdate_year'};
	$newdate = &translate_date($newdate);
	@entry = ($id, $newdate, $in{'next_message'}, $in{'cycle'});
	splice @listfields, 0, 4;

	foreach $field (@listfields) { push @entry, $in{$field}; }
	$entry = join "::", @entry;
	
	## Replace entry in mailing list
	$success = &ezylist_replace_entry($user, $listid, $id, $entry);
	if ($success != 1) { &error("Unable to edit entry in mailing list"); }

	## Print HTML success page
	&success("Successfully edited mailing list entry");
}

################################################
## Edit mailing list - delete entry
################################################

sub lists_edit_delete {
	my ($user, $listid, $id, $ok);

	## Get needed info
	($user, $listid, $id) = ($in{'username'}, $in{'list_id'}, $in{'entry_id'});
	
	## Delete the entry
	$ok = &ezylist_delete_entry($user, $listid, $id);
	if ($ok != 1) { &error(500, __LINE__, __FILE__, "Could not delete the entry from the selected mailing list"); }

	## Print off HTML success template
	&success("Successfully deleted entry from mailing list");

}

################################################
## Browse mailing list
################################################

sub lists_browse {
	my ($user, $id, $start, @entries, %info);

	## Get needed info
	if ($PARSE == 1) { ($user, $id, $start) = ($in{'username'}, $in{'list_id'}, 0); }
	else {
		($user, $id, $start) = ($query{'username'}, $query{'listid'}, $query{'start'});
		($in{'username'}, $in{'list_id'}) = ($user, $id);
	}
	%info = &ezylist_get_listinfo($user);
	
	## Make sure user exists
	if (!defined &get_ext($user)) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	elsif ($id eq '') { &error(500, __LINE__, __FILE__, "You did not select a list to browse"); }
		
	## Get number of subscribers
	$in{'subscribers'} = &ezylist_countlist($user, $id);

	## Create next/prev links, and get entries to show
	@entries = &ezylist_get_browse_info($user, $id, "$datadir/list/$user/$id", $start, "menu=lists&action=browse");

	## Process the entries to show
	foreach $line (@entries) {
		my ($x, $entryid, $next, $next_message, $cycle, $entry_html, @entry);

		## Get needed info
		@entry = split /::/, $line;
		($entryid, $next, $next_message, $cycle) = splice @entry, 0, 4;
		$next = &format_date(&num2date($next));
		$next_message = $info{$next_message}{'name'};

		## Create entry HTML
		$entry_html = qq!<th nowrap><input type="radio" name="id" value="$entryid"></th>!;
		$entry_html .= qq!<td nowrap><FONT_BODY>$entryid</font></td>!;
		$entry_html .= qq!<td nowrap><FONT_BODY>$next</font></td>!;
		$entry_html .= qq!<td nowrap><FONT_BODY>$next_message</font></td>!;

		foreach $field (@entry) {
			$entry_html .= qq!<td nowrap><FONT_BODY>$field</font></td>!;
		}

		push @{$in{'list_entry'}}, $entry_html;
	}

	## Get ready to print HTML template
	$in{'listname'} = $info{$id}{'name'};
	splice @{$info{$id}{'fields'}}, 0, 4;
	$in{'listfield'} = [ @{$info{$id}{'fields'}} ];

	## Print HTML template
	$in{'qmark'} = "?"; $in{'smark'} = "|";
	print &parse_template('admin/lists/browse.htmlt');
	exit(0);

}

################################################
## Generate subscribe form
################################################

sub lists_form {
	my ($form, %info);

	## Get needed info
	$listid = $in{'list_id'};
	%info = &ezylist_get_listinfo($user);
	if ($listid eq '') { &error(500, __LINE__, __FILE__, "You did not select a mailing list"); }
	
	## Create the HTML form
$form = qq!

<form action="$cgiurl/subscribe.cgi" method="POST">
<input type="hidden" name="username" value="$user">
<input type="hidden" name="listid" value="$listid">

<font face="arial" size=2>
!;

	## Add list fields to form
	splice @{$info{$listid}{'fields'}}, 0, 4;
	foreach $field (@{$info{$listid}{'fields'}}) {
		my $hfield = ucfirst($field);
		$form .= qq!$hfield: <input type="text" name="$field" size=25><br><br>\n\n!;
	}
	$form .= qq!<input type="submit" value="Subscribe">\n!;
	$form .= "</font></form>\n\n";
	
	$in{'results'} = $form;
	print &parse_template('cpanel/setup/form.htmlt');
	exit(0);
	
}

################################################
## Manage archived lists
################################################

sub lists_archive {
	my ($user, $listid, $start, $num, @entries, %info);
	
	## Make sure feature is turned on
	if ($moptions[7] != 1) { &error(500, __LINE__, __FILE__, "You did not have the archived lists feature turned on."); }

	## Get needed info
	if ($PARSE == 1) { ($user, $listid, $start) = ($in{'username'}, $in{'list_id'}, 0); }
	else {
		($user, $listid, $start) = ($query{'username'}, $query{'listid'}, $query{'start'});
		($in{'username'}, $in{'list_id'}) = ($user, $listid);
	}
	%info = &ezylist_get_listinfo($user);
	($num) = $listid =~ /^(\d+)\..+/;
	
	## Perform a couple checks
	if (!defined &get_ext($user)) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	elsif ($listid eq '') { &error(500, __LINE__, __FILE__, "You did not select a list to manage"); }

	## Create next/prev links, and get entries to show
	@entries = &ezylist_get_browse_info($user, $listid, "$datadir/list/$user/$num.archive", $start, "menu=lists&action=archive");

	## Process the entries to show
	foreach $line (@entries) {
		my ($x, $entryid, $entry_html, @entry);

		## Get needed info
		@entry = split /::/, $line;
		$entryid = shift @entry;

		## Create entry HTML
		$entry_html = qq!<th nowrap><input type="checkbox" name="id" value="$entryid"></th>!;
		$entry_html .= qq!<td nowrap><FONT_BODY>$entryid</font></td>!;

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
	$in{'qmark'} = "?"; $in{'smark'} = "|";
	print &parse_template('admin/lists/archive.htmlt');
	exit(0);
	
}

################################################
## Manage archived lists - part 2
################################################

sub lists_archive2 {
	my ($user, $listid, $num, @id, @listinfo, @newlist, @results);
	
	## Get needed info
	($user, $listid) = ($in{'username'}, $in{'list_id'});
	($num) = $listid =~ /^(\d+)\..+/;
	@listinfo = &readfile("$datadir/list/$user/$num.archive");
	@id = split /\0/, $in{'id'};
	
	## Take selected entries out of list
	foreach $line (@listinfo) {
		my ($entryid, @line) = split /::/, $line;
		my $ok=0;
		
		foreach $id (@id) {
			if ($id == $entryid) { $ok=1; last; }
		}
		
		if ($ok == 1) { push @results, $line; }
		else { push @newlist, $line; }
	}
	
	## Rewrite the archived list
	&writefile("$datadir/list/$user/$num.archive", @newlist);
	
	## If we need to recycle entries
	if ($in{'submit'} eq 'Recycle Selected Entries') {
		my ($x, $date, $time, $days, $cdays, $message, @cycle);
		
		## Get next follow up date, and message
		($date, $time) = &getdate;
		$days = &translate_date($date);
		$count = &readfile("$datadir/list/$user/$num.count");
		
		@cycle = &readfile("$datadir/list/$user/$num.cycle");
		($cdays, $message) = split /::/, $cycle[0];
		$days += $cdays;		
		
		## Change all list entries
		$x=0;
		foreach $line (@results) {
			next if $line eq '';
			my ($entryid, @line) = split /::/, $line;
			
			$count++;
			$count = sprintf "%.3d", $count;
			unshift @line, $count, $days, $message, 1;
			
			$results[$x] = (join "::", @line);	
		$x++; }
		
		## Rewrite the needed files
		&appendfile("$datadir/list/$user/$listid", (join "\n", @results));
		&writefile("$datadir/list/$user/$num.count", $count);		
	}
	
	## Print off HTML success template
	&success("Successfully updated the archived mailing list");
}

################################################
## Import mailing list
################################################

sub lists_import {
	my ($user, $listid, @listfields, %info);
	
	## Get needed info
	($user, $listid) = ($in{'username'}, $in{'list_id'});
	%info = &ezylist_get_listinfo($user);
	@listfields = @{$info{$listid}{'fields'}};
	$in{'listname'} = $info{$listid}{'name'};	

	## Figure out what to do
	if ($in{'action2'} eq 'import') {
		my ($import, $linenum, $delim, $num, $date, $time, $efield, $fieldsize, $success, $cycledays, $message, $days, $count, @cycle, @import, @success);
	
		## Get some info
		splice @listfields, 0, 4;
		while (read($in{'importfile'}, $buffer, 1024)) { $import .= $buffer; }
		$import =~ s/[\r\f]//gi; @import = split /\n/, $import;
		($num) = $listid =~ /^(\d+)/;
		$efield = ($info{$listid}{'efield'} - 4);
		if ($in{'delim'} eq 'other') { $delim = $in{'delim_other'}; }
		else { $delim = "\t"; }
		$fieldsize = @listfields;
		
		## Get beginning of list entries
		@cycle = &readfile("$datadir/list/$user/$num.cycle");
		$count = &readfile("$datadir/list/$user/$num.count");
		if (!$cycle[0]) { &error(500, __LINE__, __FILE__, "No follow up cycles have been set for this mailing list"); }
		($cycledays, $message) = split /::/, $cycle[0];
		($date, $time) = &translate_date($date);
		$days = &translate_date($date);
		$days += $cycledays;
		
		## Parse through imported file
		$linenum=1;
		($in{'total_success'}, $in{'total_error'}) = (0, 0);
		foreach $line (@import) {
			my ($linesize, $exists, @line);
			@line = split /$delim/, $line;
			$linesize = @line;
			$exists = &ezylist_checklist($user, $listid, $line[$efield]);
			
			## Check for some errors
			if ($line eq '') { 
				$in{'total_error'}++;
				push @{$in{'errornum'}}, $linenum;
				push @{$in{'errordesc'}}, "Line is blank";
			} elsif ($line[$efield] !~ /.*\@.*\..*/) { 
				$in{'total_error'}++;
				push @{$in{'errornum'}}, $linenum;
				push @{$in{'errordesc'}}, "Invalid e-mail address, <b>$line[$efield]</b>";
			} elsif ($linesize < $fieldsize) {
				$in{'total_error'}++;
				push @{$in{'errornum'}}, $linenum;
				push @{$in{'errordesc'}}, "Line does not contain enough columns";
			} elsif ($linesize > $fieldsize) {
				$in{'total_error'}++;
				push @{$in{'errornum'}}, $linenum;
				push @{$in{'errordesc'}}, "Line contains too many columns";
			} elsif ($exists == 1) {
				$in{'total_error'}++;
				push @{$in{'errornum'}}, $linenum;
				push @{$in{'errordesc'}}, "E-mail address already exists in mailing list, <b>$line[$efield]</b>";			
			} else {
				$in{'total_success'}++; $count++;
				
				## Create new line
				my $id = sprintf "%.3d", $count;
				$line[$efield] = lc($line[$efield]);
				unshift @line, $id, $days, $message, 1;
				push @success, (join "::", @line);
			}
		$linenum++; }
		
		## Add entries to mailing list
		$success = join "\n", @success;
		&writefile("$datadir/list/$user/$num.count", $count);
		&appendfile("$datadir/list/$user/$listid", $success);
		
		## Print off HTML template
		print &parse_template('admin/lists/import2.htmlt');
		exit(0);
		
	} else {	
		my ($x, $example);
		
		$x=1;
		splice @listfields, 0, 4;
		foreach $field (@listfields) {
			push @{$in{'colnum'}}, $x;
			push @{$in{'coldesc'}}, ucfirst($field);
		$x++; }
		
		## Create example file
		for $y ( 1 .. 2 ) {
			my ($name, $email);
			
			if ($y == 1) {
				$name = "John Smith";
				$email = "jsmith\@aol.com";
			} elsif ($y == 2) {
				$name = "Randy Thompson";
				$email = "randy\@mail.com";
			}
		
			$x=4;
			foreach $field (@listfields) {
				$example .= q!&nbsp;&nbsp;<i>[TAB]</i>&nbsp;&nbsp;! unless $x == 4;			
				if ($x == $info{$listid}{'efield'}) { $example .= $email; }
				elsif ($x == $info{$listid}{'nfield'}) { $example .= $name; }
				else { $example .= uc($field); }
			$x++; }

			$example .= "<br>";
		}
		
		## Print HTML template
		$in{'example_file'} = $example;
		print &parse_template('admin/lists/import.htmlt');
	}
	
}


################################################
## Export mailing list
################################################

sub lists_export {
	my ($user, $listid, @listfields, %info);
	
	## Get needed info
	($user, $listid) = ($in{'username'}, $in{'list_id'});
	%info = &ezylist_get_listinfo($user);
	@listfields = @{$info{$listid}{'fields'}};
	$in{'listname'} = $info{$listid}{'name'};	

	## Figure out what to do
	if ($in{'action2'} eq 'export') {
		my ($fields, $delim, @listinfo);
		
		## Get delimter
		if ($in{'delim'} eq 'other') { $delim = $in{'delim_other'}; }
		else { $delim = "\t"; }
	
		## Get list info
		splice @listfields, 0, 4;
		@listinfo = &readfile("$datadir/list/$user/$listid");
		$fields = join $delim, @listfields; $fields = uc($fields);
		print "$fields\n";
		
		## Export mailing list
		foreach $line (@listinfo) {
			next if $line eq '';
			my @line = split /::/, $line;
			splice @line, 0, 4;
			
			my $outline = join $delim, @line;
			print "$outline\n";
		}
		
		## Exit the script
		exit(0);
	
	} else { print &parse_template('admin/lists/export.htmlt'); exit(0); }

}

1;



