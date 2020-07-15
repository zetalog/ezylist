
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
## Create a new member
################################################

$table = 'member';

sub member_create {

	if ($PARSE == 1) {
		my ($DBSUB, $user, $name, $email, $pass, $ext1, $ext2, $length, $type, $encrypt, $userinfo, $date, $time, @confirm, @userinfo);

		## Get needed info
		$user = $in{'username'};
		$length = length($user);
		if ($length > 8) { &error(500, __LINE__, __FILE__, "Username is limited to 8 characters, <b>$user</b>"); }
		## Check user fields' limitation here
		
		@confirm = split /\0/, $in{'_confirm'};
		$name = $in{$userfields[$dbfields[0]]};
		$email = $in{$userfields[$dbfields[1]]};
		$pass = $in{$userfields[$dbfields[2]]};
		$type = $in{'type'};
		($date, $time) = &getdate;
		($ext1, $ext2) = &get_ext($user);

		## Perform a few checks
		if ($user eq '') { &error(500, __LINE__, __FILE__, "No username specified"); }
		if ($type !~ /registered|unregistered|advertiser/) { &error(500, __LINE__, __FILE__, "Invalid class, <b>$class</b>"); }
		elsif ($user =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Username contains spaces or special characters, <b>$user</b>"); }
		elsif (defined $ext1 || (defined $ext2)) { &error(500, __LINE__, __FILE__, "Username already exists, <b>$user</b>"); }
		elsif ($email !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid e-mail address, <b>$email</b>"); }
		elsif ($in{'_add_autonum'} =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Number of autoresponders can only contain digits"); }
		elsif ($in{'_add_listnum'} =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Number of mailing lists can only contain digits"); }
		elsif ($in{'_add_msgnum'} =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Number of follow up messages can only contain digits"); }
		elsif ($in{'_add_cyclenum'} =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Number of follow up cycles can only contain digits"); }
		elsif ($in{'_add_maxsch'} =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Number of scheduled mailings can only contain digits"); }
		elsif ($in{'_add_maxmsg'} =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Maximum number of e-mail msesages allowed to be sent can only contain digits"); }

		## Process member's password
		if (($moptions[1] == 1) || ($moptions[3] == 1)) {
			$encrypt = &encrypt($pass);
			$in{$userfields[$dbfields[2]]} = $encrypt if $moptions[1] == 1;
			&appendfile("$datadir/member.pass", "$user:$encrypt") if $moptions[3] == 1;
		}

		$DBSUB = $dbdriver . "_create_account";
		&$DBSUB($user, $type, @userfields);

		## Create member configuration
		&copy_template($user, 'conf');

		## Update member's conf file with new info
		&edit_conf($user, 'conf', 'EZYLIST_ARNUM', $in{'_add_autonum'});
		&edit_conf($user, 'conf', 'EZYLIST_LISTNUM', $in{'_add_listnum'});
		&edit_conf($user, 'conf', 'EZYLIST_MSGNUM', $in{'_add_msgnum'});
		&edit_conf($user, 'conf', 'EZYLIST_CYCLENUM', $in{'_add_cyclenum'});
		&edit_conf($user, 'conf', 'EZYLIST_MAXSCH', $in{'_add_maxsch'});
		&edit_conf($user, 'conf', 'EZYLIST_MAXNUM', $in{'_add_maxmsg'});

		## Constructs additional notification informations
		$in{'date'} = $date;
		$in{'name'} = $in{$userfields[$dbfields[0]]};
		$in{'email'} = $in{$userfields[$dbfields[1]]};
##		$in{'pass'} = $in{$userfields[$dbfields[2]]};
		$in{'type'} = $in{'type'};

		## Send out all needed confirmation messages
		foreach $confirm (@confirm) {
			if ($confirm eq 'member') { &mailmsg_from_file($email, "$datadir/messages/signup_member.msg", $admin_email, $admin_name, $admin_pass, %in); }
			elsif ($confirm eq 'admin') { &mailmsg_from_file($admin_email, "$datadir/messages/signup_admin.msg", $email, $name, $pass, %in); }
		}

		## Print off HTML success text
		&success("Successfully created new member, <b>$user</b>");
	} else {
		for $x ( 0 .. @default ) { $in{"default$x"} = $default[$x]; }		
		$in{'userfield'} = [ @userfields ];
		print &parse_template('admin/member/create.htmlt');
		exit(0);
	}
}

################################################
## Manage a member
################################################

sub member_manage {
	my ($user, $status, @results, $x);

	if ((exists $in{'confirm'}) || ($in{'step'} eq "display")) {
		my ($REDSUB);
		## Redirect actions
		$REDSUB = $query{'menu'} . "_" . $in{'action'};
		&$REDSUB;
		exit(0);
	} else {
		$in{'title'} = "Manage Member"; &print_header; 
		if (($PARSE == 0)) {
			print &parse_template('admin/get_account.htmlt', 'main');
			exit(0);
		} else {
			$DBSUB = $dbdriver . "_fetch_accounts";
			@userinfos = &$DBSUB($in{'username'}, $in{'display_all_accounts'});
			for $x (0 .. (@userinfos-1)) {
				push @{$in{'rusername'}}, $userinfos[$x][0];
				push @{$in{'rname'}}, $userinfos[$x][$dbfields[0]];
				push @{$in{'remail'}}, $userinfos[$x][$dbfields[1]];
				push @{$in{'rstatus'}}, $userinfos[$x][$extfield];
				push @{$in{'rtype'}}, $userinfos[$x][$extfield+1];
			}
		}
		## Get available actions, should from a data file
		push @{$in{'action'}}, "edit";
		push @{$in{'action'}}, "delete";
		push @{$in{'action'}}, "activate";
		push @{$in{'action'}}, "deactivate";
		push @{$in{'action'}}, "register";
		push @{$in{'action'}}, "deregister";
		push @{$in{'action'}}, "view";
		&print_header;
		print &parse_template('admin/member/manage.htmlt', 'main');
		exit(0);
	}

	## Make sure user exists
	$user = $in{'username'};
	$status = &get_ext($user, "status");
	if (!$status) { &error(500, __LINE__, __FILE__, "Username does not exist, <b>$user</b>"); }
}

################################################
## Edit a member
################################################

sub member_edit {
	my ($user, $status, $type);

	## Make sure user exists
	$user = $in{'username'};
	($status, $type) = &get_ext($user);
	if (!$status || !$type) { &error(500, __LINE__, __FILE__, "Username does not exist, <b>$user</b>"); }

	## Figure out what to do
	if ($in{'step'} eq "submit") {
		my ($passrow, $oldpass, $newinfo, @newinfo);

		## Get needed info
		$email = $in{$userfields[$dbfields[1]]};
		$passrow = $userfields[$dbfields[2]];
		$oldpass = &get_variable($user, $passrow);

		## Perform a few checks
		if ($email !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid e-mail address, <b>$email</b>"); }
		elsif ($in{'_add_autonum'} =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Number of autoresponders can only contain digits"); }
		elsif ($in{'_add_listnum'} =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Number of mailing lists can only contain digits"); }
		elsif ($in{'_add_msgnum'} =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Number of follow up messages can only contain digits"); }
		elsif ($in{'_add_cyclenum'} =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Number of follow up cycles can only contain digits"); }
		elsif ($in{'_add_maxsch'} =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Number of scheduled mailings can only contain digits"); }
		elsif ($in{'_add_maxmsg'} =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Maximum number of e-mail msesages allowed to be sent can only contain digits"); }

		## Process member's password
		if ($moptions[1] == 1) {
			if ($in{$passrow} eq "<--ENCRYPTED-->") { $in{$passrow} = $oldpass; }
			else {
				$in{$passrow} = &encrypt($in{$passrow});
				&replace_fileline("$datadir/member.pass", 'begin', "$user:", "$user:$in{$pass_row}") if $moptions[3] == 1;
			}
		} elsif ($moptions[3] == 1) {
			if ($oldpass ne $in{$passrow}) {
				$encrypt = &encrypt($in{$pass_row});
				&replace_fileline("$datadir/member.pass", 'begin', "$user:", "$user:$encrypt");
			}
		}
		
		$DBFUNC = $dbdriver . "_edit_account";
		&$DBFUNC($user, $type, $status, @userfields);

		&edit_conf($user, 'conf', 'EZYLIST_ARNUM', $in{'_add_autonum'});
		&edit_conf($user, 'conf', 'EZYLIST_LISTNUM', $in{'_add_listnum'});
		&edit_conf($user, 'conf', 'EZYLIST_MSGNUM', $in{'_add_msgnum'});
		&edit_conf($user, 'conf', 'EZYLIST_CYCLENUM', $in{'_add_cyclenum'});
		&edit_conf($user, 'conf', 'EZYLIST_MAXSCH', $in{'_add_maxsch'});
		&edit_conf($user, 'conf', 'EZYLIST_MAXNUM', $in{'_add_maxmsg'});

		## Print off success HTML template
		&success("Successfully updated member, <b>$user</b>");
	} else {
		my (@userinfo);

		## Get needed info
		$DBFUNC = $dbdriver . "_fetch_account";
		@userinfo = &$DBFUNC($user);

		$userinfo[$dbfields[2]] = "<--ENCRYPTED-->" if $moptions[1] == 1;

		## Get ready to print HTML template
		splice @userfields, 0, 1;
		splice @userinfo, 0, 1;
		$in{'userfield'} = [ @userfields ];
		$in{'userinfo'} = [ @userinfo ];
		($in{'add_arnum'}, $in{'add_listnum'}, $in{'add_msgnum'}, $in{'add_cyclenum'}, $in{'add_maxsch'}, $in{'add_maxnum'}) = &ezylist_get_conf($user);
		$in{'_moptions1'} = $moptions[1];

		## Print HTML template
		print &parse_template('admin/member/edit.htmlt');
		exit(0);
	}
}

################################################
## Delete a member
################################################

sub member_delete {
	my ($user, $type, $status);

	if (exists $in{'confirm'}) {
		my ($DBSUB);

		## Make sure user exists
		$user = $in{'confirm_data'};
		($status, $type) = &get_ext($user);
		if (!$status || !$type) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }

		if ($in{'confirm'} == 0) { &success("Did not delete the member, <b>$user</b>"); }

		## Delete the member from database
		if ($moptions[3] == 1) { &delete_fileline("$datadir/member.pass", 'begin', "$user:"); }
		$DBSUB = $dbdriver . "_delete_account";
		&$DBSUB($user, $type, $status);

		## Print off success HTML template
		&success("Successfully delete the member, <b>$user</b>");
	} else {
		my ($user, $ext);
		
		## Make sure user exists
		$user = $in{'username'};
		($status, $type) = &get_ext($user);
		if (!$status || !$type) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }

		## Print confirm HTML template
		$in{'confirm_data'} = $user;
		$in{'page_title'} = "Delete Member";
		$in{'confirm_text'} = "Are you sure you want to delete the member, <b>$user</b>?";
		print &parse_template('admin/confirm.htmlt');
		exit(0);
	}
}

################################################
## View a member
################################################

sub member_view {
	my ($user, $status, $type, @userinfo, @conf, $DBSUB, %info);
	
	## Make sure user exists
	$user = $in{'username'};
	($status, $type) = &get_ext($user);
	if (!$status || !$type) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type eq "advertiser") {
		$in{'advertiser'} = 1;
		%info = &ezylist_get_adinfo($user);
	} else {
		$in{'mailer'} = 1;
		%info = &ezylist_get_listinfo($user);
	}
	
	## Get user info
	$DBFUNC = $dbdriver . "_fetch_account";
	@userinfo = &$DBFUNC($user);
	$userinfo[$dbfields[2]] = "<--ENCRYPTED-->" if $moptions[1] == 1;
	$in{'userfield'} = [ @userfields ];
	$in{'userinfo'} = [ @userinfo ];
	
	if ($in{'mailer'} == 1) {
		## Get user's auto responder
		@conf = &parse_conf($user, 'conf', 'EZYLIST_AUTORESPONDER');
		foreach $line (@conf) {
			next if $line eq '';
			my ($ar, $listid, $forward) = split /::/, $line;
			push @{$in{'ar_email'}}, $ar;
			push @{$in{'ar_list'}}, $info{$listid}{'name'};
			push @{$in{'ar_forward'}}, $forward;
		}
	
		## Get ready to print HTML template
		&ezylist_get_listhtml($user);
	} else {
		## Get ready to print HTML template
		&ezylist_get_adhtml($user);
	}
	
	## Print the HTML template
	print &parse_template('admin/member/view.htmlt');
	exit(0);
}

################################################
## Activate a member
################################################

sub member_activate {
	my ($user, $status, $type);

	if (exists $in{'confirm'}) {
		my ($DBSUB);
		
		## Make sure user exists
		$user = $in{'confirm_data'};
		($status, $type) = &get_ext($user);
		if (!$status) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
		elsif ($status eq "active") { &error(500, __LINE__, __FILE__, "Member is already active, <b>$user</b>"); }
		elsif ($in{'confirm'} == 0) { &success("Did not activate the member, <b>$user</b>"); }

		## Activate the member
		$DBSUB = $dbdriver . "_activate_account";
		&$DBSUB($user);
	
		## Print off the HTML success template
		&success("Successfully activated the member, <b>$user</b>");
	} else {
		## Make sure user exists and is inactive
		$user = $in{'username'};
		($status, $type) = &get_ext($user);

		if (!$status) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
		elsif ($status eq "active") { &error(500, __LINE__, __FILE__, "User is already active, <b>$user</b>"); }
		
		## Print the confirm HTML template
		$in{'page_title'} = "Activate Member";
		$in{'confirm_data'} = $user;
		$in{'confirm_text'} = "Are you sure you want to activate the member <b>$user</b>?";
		print &parse_template('admin/confirm.htmlt');
		exit(0);
	}
}

################################################
## Deactivate a member
################################################

sub member_deactivate {
	my ($user, $status, $type);

	if (exists $in{'confirm'}) {
		my ($DBSUB);

		## Make sure user exists
		$user = $in{'confirm_data'};
		($status, $type) = &get_ext($user);
		if (!$status) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
		elsif ($status eq "inactive") { &error(500, __LINE__, __FILE__, "Member is already inactive, <b>$user</b>"); }
		elsif ($in{'confirm'} == 0) { &success("Did not deactivate the member, <b>$user</b>"); }
		
		## Deactivate the member
		$DBSUB = $dbdriver . "_deactivate_account";
		&$DBSUB($user);
		
		## Print the success template
		&success("Successfully deactivated the member, <b>$user</b>");
	} else {
		$user = $in{'username'};
		($status, $type) = &get_ext($user);
		if (!$status) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
		elsif ($status eq "inactive") { &error(500, __LINE__, __FILE__, "User is already inactive, <b>$user</b>"); }
		
		## Print the confirm HTML template
		$in{'page_title'} = "Deactivate Member";
		$in{'confirm_data'} = $user;
		$in{'confirm_text'} = "Are you sure you want to deactivate the member <b>$user</b>?";
		print &parse_template('admin/confirm.htmlt');
		exit(0);
	}
}

################################################
## Register a member
################################################

sub member_register {
	my ($user, $status, $type);

	if (exists $in{'confirm'}) {
		my ($DBSUB);
		
		## Make sure user exists
		$user = $in{'confirm_data'};
		($status, $type) = &get_ext($user);
		if (!$type) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
		elsif ($type ne "unregistered") { &error(500, __LINE__, __FILE__, "Member is already registered, <b>$user</b>"); }
		elsif ($in{'confirm'} == 0) { &success("Did not register the member, <b>$user</b>"); }

		## Register the member
		$DBSUB = $dbdriver . "_register_account";
		&$DBSUB($user);

		## Print off the HTML success template
		&success("Successfully registered the member, <b>$user</b>");
	} else {
		## Make sure user exists and is inactive
		$user = $in{'username'};
		($status, $type) = &get_ext($user);

		if (!$type) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
		elsif ($type ne "unregistered") { &error(500, __LINE__, __FILE__, "User is already registered, <b>$user</b>"); }
		
		## Print the confirm HTML template
		$in{'page_title'} = "Register Member";
		$in{'confirm_data'} = $user;
		$in{'confirm_text'} = "Are you sure you want to register the member <b>$user</b>?";
		print &parse_template('admin/confirm.htmlt');
		exit(0);
	}
}

################################################
## Deregister a member
################################################

sub member_deregister {
	my ($user, $status, $type);

	if (exists $in{'confirm'}) {
		my ($DBSUB);
		
		## Make sure user exists
		$user = $in{'confirm_data'};
		($status, $type) = &get_ext($user, "type");
		if (!$type) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
		elsif ($type ne "registered") { &error(500, __LINE__, __FILE__, "Member is already deregistered, <b>$user</b>"); }
		elsif ($in{'confirm'} == 0) { &success("Did not deregister the member, <b>$user</b>"); }

		## Register the member
		$DBSUB = $dbdriver . "_deregister_account";
		&$DBSUB($user);

		## Print off the HTML success template
		&success("Successfully deregistered the member, <b>$user</b>");
	} else {
		## Make sure user exists and is inactive
		$user = $in{'username'};
		($status, $type) = &get_ext($user);

		if (!$type) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
		elsif ($type ne "registered") { &error(500, __LINE__, __FILE__, "User is already deregistered, <b>$user</b>"); }
		
		## Print the confirm HTML template
		$in{'page_title'} = "Deregister Member";
		$in{'confirm_data'} = $user;
		$in{'confirm_text'} = "Are you sure you want to deregister the member <b>$user</b>?";
		print &parse_template('admin/confirm.htmlt');
		exit(0);
	}
}

################################################
## Search all members
################################################

sub member_search {

	if ((exists $in{'confirm'}) || ($in{'step'} eq "getmember")) {
		my ($REDSUB);
		## Redirect actions
		$REDSUB = $query{'menu'} . "_" . $in{'action'};
		&$REDSUB;
		exit(0);
	} elsif ($PARSE == 1) {
		my ($html, $count, $total, $DBSUB, @users, @userinfo, %search);
		
		## Get the list of members where searching
		$DBSUB = $dbdriver . "_search_account";
		@users = &$DBSUB($in{'_criteria1'}, $in{'_criteria2'});
		
		## Gather us all user info
		@users = sort { lc($a) cmp lc($b) } @users;
		$total = @users;
		
		## Get the search text
		$x=0;
		foreach (@userfields) {
			if ($in{$_} ne '') { $search{$x} = $in{$_}; }
		$x++; }

		## Search through the user info
		$count = 0;
		&processing_start("Currently searching member database...", "Search All Members", $total);
		foreach $user (@users) {
			my $ok=0;
			$DBSUB = $dbdriver . "_fetch_account";
			my @userinfo = &$DBSUB($user);
			while (($key, $value) = (each %search)) {
				next if $ok == 1;
				if ($userinfo[$key] =~ /$value/i) {
					$ok=1;
					push @{$in{'rusername'}}, $userinfo[0];
					push @{$in{'rname'}}, $userinfo[$dbfields[0]];
					push @{$in{'remail'}}, $userinfo[$dbfields[1]];
					push @{$in{'rstatus'}}, $userinfo[$extfield];
					push @{$in{'rtype'}}, $userinfo[$extfield+1];
				}
			}

			if (($count =~ /0$/) && ($count > 1)) { &processing_update($count); }			
		$count++; }
		
		## Get available actions, should from a data file
		push @{$in{'action'}}, "delete";
		if ($in{'_criteria1'} eq 'all' || $in{'_criteria1'} eq 'inactive') {
			push @{$in{'action'}}, "activate";
		}
		if ($in{'_criteria1'} eq 'all' || $in{'_criteria1'} eq 'active') {
			push @{$in{'action'}}, "deactivate";
		}
		if ($in{'_criteria2'} eq 'all' || $in{'_criteria2'} ne 'registered') {
			push @{$in{'action'}}, "register";
		}
		if ($in{'_criteria2'} eq 'all' || $in{'_criteria2'} ne 'unregistered') {
			push @{$in{'action'}}, "deregister";
		}
		push @{$in{'action'}}, "view";

		## Print the HTML template
		$html = &parse_template('admin/member/manage.htmlt');
		&processing_finish($html);
		exit(0);
		
	} else {

		## Print HTML template
		$in{'userfield'} = [ @userfields ];
		print &parse_template('admin/member/search.htmlt');
	}

}

1;
