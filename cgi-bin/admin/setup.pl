
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
## First Time Setup
################################################

sub setup_firsttime {
	my ($x, $moptions, $send_confirm, $default, @confirm, @conf, @moptions, @default);
	
	## Print 1st Step Template, if needed
	if ($PARSE == 0) { print &parse_template('admin/setup/firsttime1.htmlt'); exit(0); }

	## Perform some checks
	if ($in{'userfields'} =~ /\D/) { &error(500, __LINE__, __FILE__, "Number of userfields may only contain digits"); }
	elsif ($in{'userfields'} eq '') { &error(500, __LINE__, __FILE__, "You did not specify the number of fields you want in your member database"); }
	elsif ($in{'domains'} =~ /\D/) { &error(500, __LINE__, __FILE__, "Number of domain names may only contain digits"); }
	elsif ($in{'domains'} eq '') { &error(500, __LINE__, __FILE__, "You did not specify the number of domain names"); }
	elsif ($in{'dump_email'} !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid dump e-mail address, <b>$in{'dump_email'}</b>"); }
	elsif ($in{'support_email'} !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid support e-mail address, <b>$in{'support_email'}</b>"); }
	
	for $x ( 0 .. 5 ) {
		if ($in{"default$x"} eq '') { &error(500, __LINE__, __FILE__, "You did not specify a number for the default profile question <b>$x+1</b>"); }
		elsif ($in{"default$x"} =~ /\D/) { &error(500, __LINE__, __FILE__, "Default profile question <b>$x+1</b> can only contain digits"); }
	}
	
	## Get contents of ezylist.conf file
	@conf = &readfile("$datadir/ezylist.conf");
	
	## Format a couple variables
	$in{'dump_email'} =~ s/\@/\\\@/gi;
	$in{'support_email'} =~ s/\@/\\\@/gi;
	
	## Get the moptions
	@moptions = qw (1 0 0 0 0 0 0 0 0 0);
	$moptions[1] = $in{'moptions1'};
	$moptions[2] = $in{'moptions2'};
	$moptions[3] = $in{'moptions3'};
	$moptions[4] = $in{'moptions4'};
	$moptions[5] = $in{'moptions5'};
	$moptions[6] = $in{'moptions6'};
	$moptions[7] = $in{'moptions7'};
	$moptions[8] = $in{'moptions8'};
	$moptions[9] = $in{'moptions9'};
	$moptions = join " ", @moptions;
	
	## Get send confirm
	@confirm = split /\0/, $in{'send_confirm'};
	foreach $confirm (@confirm) {
		&writefile("$datadir/messages/signup_$confirm.msg", "\u\L$confirm\E Confirmation of New Member") unless -e "$datadir/messages/signup_$confirm.msg";
	}
	$send_confirm = join " ", @confirm;
	
	## Get default settings
	@default = qw (0 0 0 0 0 0);
	$default[0] = $in{'default0'};
	$default[1] = $in{'default1'};
	$default[2] = $in{'default2'};
	$default[3] = $in{'default3'};
	$default[4] = $in{'default4'};
	$default[5] = $in{'default5'};
	$default = join " ", @default;
	
	## Change info in ezylist.conf file
	$conf[2] = "\$dump_email \= \"$in{'dump_email'}\"\;";
	$conf[3] = "\$support_email \= \"$in{'support_email'}\"\;";
	$conf[12] = "\@send_confirm \= qw ($send_confirm)\;";
	$conf[13] = "\@moptions \= qw ($moptions)\;";
	$conf[15] = "\@default \= qw ($default)\;";
	$conf[16] = "\$mailtype \= \"$in{'mailtype'}\"\;";
	$conf[18] = "\@auto_options \= qw ($in{'auto_options0'})\;";
	$conf[20] = "\$dbdriver \= \"$in{'dbdriver'}\"\;";
	
	## Rewrite the ezylist.conf file
	&writefile("$datadir/ezylist.conf", @conf);
	
	## Write to .htaccess file for Member's Only Area
	if ($moptions[3] == 1) {
		my $text = "AuthName \"Member Control Panel\"\n";
		$text .= "AuthUserFile $datadir/member.pass\n";
		$text .= "AuthType Basic\n";
		$text .= "require valid-user\n";
		
		&writefile("$cgidir/cpanel/.htaccess", $text);
		chmod 0644, "$cgidir/cpanel/.htaccess";
		&writefile("$datadir/member.pass", '');
	} else { &deletefile("$cgidir/cpanel/.htaccess"); }
	
	## Create .htaccess for admin panel, if needed
	if ($moptions[2] == 1) {
		my ($text, $admin_pass, @admins);

		opendir DIR, "$datadir/admin" or &error(206, __LINE__, __FILE__, "$datadir/admin", "DIR");
		@admins = grep /\.admin$/, readdir(DIR);
		closedir DIR;
		
		foreach $admin (@admins) {
			my @admin_info = &readfile("$datadir/admin/$admin");
			my @info = split /::/, $admin_info[0];
			$admin_pass .= "$info[0]:$info[3]\n";
		}
		&writefile("$datadir/admin.pass", $admin_pass);

		$text = "AuthName \"$in{'SCRIPT_TITLE'} v$VERSION - Admin Control Panel\"\n";
		$text .= "AuthUserFile $datadir/admin.pass\n";
		$text .= "AuthType Basic\n";
		$text .= "require valid-user\n";
		
		&writefile("$cgidir/admin/.htaccess", $text);
		chmod 0644, "$cgidir/admin/.htaccess";
	} else {
		&deletefile("$cgidir/admin/.htaccess");
		&writefile("$datadir/.random.admin") unless -e "$datadir/.random.admin";
	}
	
	## Get ready to print HTML template
	for $x ( 1 .. $in{'userfields'} ) { push @{$in{'field_num'}}, $x; }	
	for $x ( 1 .. $in{'domains'} ) { push @{$in{'domain_num'}}, $x; }

	$in{'_sendmail'} = 1 if $in{'mailtype'} eq 'sendmail';
	$in{'_smtp'} = 1 if $in{'mailtype'} eq 'smtp';
	$in{'_dns'} = 1 if $in{'mailtype'} eq 'dns';
	$in{'_backup'} = $auto_options[0];
	
	$in{'_cgi'} = 1 if $in{'dbdriver'} eq 'cgi';
	$in{'_mysql'} = 1 if $in{'dbdriver'} eq 'mysql';

	## Print the HTML template
	print &parse_template('admin/setup/firsttime2.htmlt');
	exit(0);

}

################################################
## First Time Setup - part 2
################################################

sub setup_firsttime2 {
	my ($userfields, $auto_options, $extfield, @domains, @userfields, @conf);

	## Get info from ezylist.conf file
	@conf = &readfile("$datadir/ezylist.conf");
	
	## Process the user fields
	@userfields = qw (username);
	$extfield = $in{'userfields'} + 1;
	for $x ( 1 .. $in{'userfields'} ) {
		my $field = lc($in{"field".$x});
		if ($field eq 'username') { &error(500, __LINE__, __FILE__, "The database field, <b>username</b> is automatically added in by the script and is not needed"); }
		elsif ($field =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "The database field $x contains spaces or special characters, <b>$field</b>"); }
		elsif ($field eq '') { &error(500, __LINE__, __FILE__, "You did not specify a name for the database field, $x"); }
		push @userfields, $field;		
	}
	$userfields = join " ", @userfields;

	## Process the domains
	@domains = qw ();
	for $x ( 1 .. $in{'domains'} ) {
		my $field = lc($in{"domain".$x});
		if ($field !~ /.+\..+/) { &error(500, __LINE__, __FILE__, "Invalid domain name, <b>$field</b>"); }
		elsif ($field =~ /\s/) { &error(500, __LINE__, __FILE__, "The database field $x contains spaces, <b>$field</b>"); }
		elsif ($field eq '') { &error(500, __LINE__, __FILE__, "You did not specify a name for the database field, $x"); }
		&makedir("$datadir/ar/$field");
		&makedir("$datadir/arlog/$field");
		push @domains, $field;		
	}

	## Process auto_options info
	if ($auto_options[0] == 1) {
		$auto_options[1] = $in{'backup_interval'};
		$auto_options = join " ", @auto_options;
	}
	
	## Change info in ezylist.conf file
	$conf[10] = "\@userfields \= qw ($userfields)\;";
	$conf[17] = "\$mailprog \= \"$in{'mailprog'}\"\;";
	$conf[18] = "\@auto_options \= qw ($auto_options)\;" if $auto_options[0] == 1;
	$conf[19] = "\$extfield \= $extfield\;";
	$conf[21] = "\$dbname \= \"$in{'dbname'}\"\;";
	$conf[22] = "\$dbhost \= \"$in{'dbhost'}\"\;";
	$conf[23] = "\$dbuser \= \"$in{'dbuser'}\"\;";
	$conf[24] = "\$dbpassword \= \"$in{'dbpassword'}\"\;";

	## Write new info to ezylist.conf file
	&writefile("$datadir/ezylist.conf", @conf);
	&writefile("$datadir/dat/domains.dat", @domains);

	&writefile("$datadir/$dbdriver.mls", 0);
	&writefile("$datadir/$dbdriver.ads", 0);
	
	## Get ready to print HTML template
	splice @userfields, 0, 1;
	@{$in{'field'}} = @userfields;

	$x=1;
	foreach $field (@userfields) {
		$in{'userfield_options'} .= "<option value\=\"$x\">$field\n";
	$x++; }

	## Print HTML template
	print &parse_template('admin/setup/firsttime3.htmlt');
	exit(0);	

}

################################################
## First Time Setup - part 3
################################################

sub setup_firsttime3 {
	my ($dbfields, $edit_fields, @conf);

	## Get info from ezylist.conf file
	@conf = &readfile("$datadir/ezylist.conf");

	## Process the dbfields
	@dbfields = ($in{'dbfields0'}, $in{'dbfields1'}, $in{'dbfields2'});
	$dbfields = join " ", @dbfields;

	## Process the edit fields
	@edit_fields = split /\0/, $in{'edit_fields'};
	$edit_fields = join " ", @edit_fields;

	## Add new information to wsr.conf file
	$conf[11] = "\@edit_fields \= qw ($edit_fields)\;";
	$conf[14] = "\@dbfields \= qw ($dbfields)\;";
	
	## Write ezylist.conf file
	&writefile("$datadir/ezylist.conf", @conf);
	
	## Get ready to print HTML template
	if ($auto_options[0] == 1) {
		my $text = "1 0 * * * $cgidir/update.pl\n";
		&appendfile("$datadir/ezylist.cron", $text);
		$in{'datadir'} = $datadir;
		$in{'_cron'} = 1;
	} else { $in{'_cron'} = 0; }
	
	if ($dbdriver eq 'mysql') {
		my $field, $index, $table, @tables;
		@tables = &mysql_get_table_names;
		foreach $table (@tables) {
			mysql_drop_table($table);
		}

		## Construct query string
		my $sql = "CREATE TABLE member(\n";
		for $index (0 .. @userfields) {
			my $field = $userfields[$index];
			if ($field ne UNDEF && $field ne "") {
				$sql .= $field;
				$sql .= " varchar(";
				if ($index == 0) { $sql .= '8'; $found = 1; }
				else { $sql .= '60'; }
				$sql .= ") ";
				if ($index == $dbfields[2]) { $sql .= "NULL"; }
				elsif ($index == 0) { $sql .= "NOT NULL"; }
				elsif ($index == $dbfields[0] || $index == $dbfields[1]) { $sql .= "NOT NULL"; }
				else  { $sql .= "NULL"; }
				$sql .= " ";
				if ($index == 0) { $sql .= "PRIMARY KEY"; }
#				elsif ($index == $dbfields[1]) { $sql .= "UNIQUE"; }
				$sql .= ",\n";
			}
		}
		$sql .= "status varchar(10) NOT NULL DEFAULT \"active\",\n";
		$sql .= "type varchar(15) NOT NULL DEFAULT \"unregistered\");";
#		$sql .= "type varchar(15) NOT NULL DEFAULT \"unregistered\",\n";
#		$sql .= "CONSTRAINT check_status CHECK(status in(\"active\", \"inactive\")),\n";
#		$sql .= "CONSTRAINT check_type CHECK(type in(\"unregistered\", \"registered\", \"advertiser\")))\;";
		## Create member table
		my $sth = $dbh->prepare($sql);
		$sth->execute or &error(303, __LINE__, __FILE__, "Cannot create <b>member</b> table.");
	}

	## Print the HTML template
	print &parse_template('admin/setup/firsttime4.htmlt');
	exit(0);

}

################################################
## Settings
################################################

sub setup_settings {

	## Get ready to print HTML template
	$in{'admin_name'} = $admin_name;
	$in{'admin_email'} = $admin_email;
	$in{'dump_email'} = $dump_email;
	$in{'support_email'} = $support_email;
	$in{'mailprog'} = $mailprog;
	$in{'dbname'} = $dbname;
	$in{'dbhost'} = $dbhost;
	$in{'dbuser'} = $dbuser;
	$in{'dbpassword'} = $dbpassword;

	## Process moptions
	$in{"moptions2_$moptions[2]"} = "checked";
	$in{"moptions3_$moptions[3]"} = "checked";
	$in{"moptions4_$moptions[4]"} = "checked";
	$in{"moptions5_$moptions[5]"} = "checked";
	$in{"moptions6_$moptions[6]"} = "checked";
	$in{"moptions7_$moptions[7]"} = "checked";
	$in{"moptions8_$moptions[8]"} = "checked";
	$in{"moptions9_$moptions[9]"} = "checked";

	$in{"auto_options0_$auto_options[0]"} = "checked";
	$in{"backup_$auto_options[1]"} = "checked";
	$in{"mailtype_$mailtype"} = "checked";
	$in{"_$mailtype"} = 1;
	$in{'_backup'} = $auto_options[0];
	$in{"dbdriver_$dbdriver"} = "checked";
	$in{"_$dbdriver"} = 1;
	
	## Process send confirm
	foreach $confirm (@send_confirm) { $in{"send_confirm_$confirm"} = "checked"; }

	## Process dbfields
	$x=1;
	splice @userfields, 0, 1;
	foreach $field (@userfields) {
		if ($x == $dbfields[0]) { $in{'dbfields0'} .= "<option value\=\"$x\" selected>$field\n"; }
		else { $in{'dbfields0'} .= "<option value\=\"$x\">$field\n"; }
			
		if ($x == $dbfields[1]) { $in{'dbfields1'} .= "<option value\=\"$x\" selected>$field\n"; }
		else { $in{'dbfields1'} .= "<option value\=\"$x\">$field\n"; }
			
		if ($x == $dbfields[2]) { $in{'dbfields2'} .= "<option value\=\"$x\" selected>$field\n"; }
		else { $in{'dbfields2'} .= "<option value\=\"$x\">$field\n"; }

		if ($x == $dbfields[3]) { $in{'dbfields3'} .= "<option value\=\"$x\" selected>$field\n"; }
		else { $in{'dbfields3'} .= "<option value\=\"$x\">$field\n"; }
	$x++; }
	
	## Process defaults
	$x=0;
	foreach (@default) { $in{"default$x"} = $default[$x]; $x++; }
	
	## Process edit fields
	foreach $field (@userfields) {
		my $chk;
		foreach $edit (@edit_fields) { $chk = "checked" if $field eq $edit; }
		$in{'edit_fields'} .= qq!<input type="checkbox" name="edit_fields" value="$field" $chk>\u\L$field\E<br>!;
	}
	
	## Print HTML template
	print &parse_template('admin/setup/settings.htmlt');
	exit(0);
}

################################################
## Settings - part 2
################################################

sub setup_settings2 {
	my ($moptions, $send_confirm, $extfield, $dbfields, $auto_options, $edit_fields, $default, @confirm, @conf, @members);

	## See if we need to do something else
	if ($in{'submit'} eq 'System Settings') { &setup_settings_system; }
	elsif ($in{'submit'} eq 'Style Settings') { &setup_settings_styles; }
	elsif ($in{'submit'} eq 'Manage Domains') { &setup_settings_domains; }

	## Perform a few checks
	if ($in{'admin_email'} !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid e-mail address, <b>$in{'admin_email'}</b>"); }
	elsif ($in{'dump_email'} !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid dump e-mail address, <b>$in{'dump_email'}</b>"); }
	elsif ($in{'support_email'} !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid support e-mail address, <b>$in{'support_email'}</b>"); }
	$in{'admin_email'} =~ s/\@/\\\@/g;
	$in{'dump_email'} =~ s/\@/\\\@/g;
	$in{'support_email'} =~ s/\@/\\\@/g;

	for $x ( 0 .. 5 ) {
		if ($in{"default$x"} eq '') { &error(500, __LINE__, __FILE__, "You did not specify a number for the default profile question <b>$x+1</b>"); }
		elsif ($in{"default$x"} =~ /\D/) { &error(500, __LINE__, __FILE__, "Default profile question <b>$x+1</b> can only contain digits"); }
	}

	## Get contents of ezylist.conf file
	@conf = &readfile("$datadir/ezylist.conf");

	## Get a list of all members
	opendir DIR, "$datadir/cgi" or &error(206, __LINE__, __FILE__, "$datadir/cgi", "DIR");
	@members = grep /\.cgi$|\.pl$/, readdir(DIR);
	closedir DIR;
	
	## Process member's auth type
	if (($moptions[3] == 1) && ($in{'moptions3'} == 0)) {
		&deletefile("$cgidir/cpanel/.htaccess");
		&deletefile("$datadir/member.pass");
	} elsif (($moptions[3] == 0) && ($in{'moptions3'} == 1)) {
		my ($text, @member_pass);
	
		$text = "AuthName \"Member's Only Area\"\n";
		$text .= "AuthUserFile $datadir/member.pass\n";
		$text .= "AuthType Basic\n";
		$text .= "require valid-user\n";
		
		&writefile("$cgidir/cpanel/.htaccess", $text);
		chmod 0644, "$cgidir/cpanel/.htaccess";
		
		foreach $member (@members) {
			my ($encrypt, @userinfo);
			@userinfo = split /::/, (&readfile("$datadir/cgi/$member"));
			if ($moptions[1] == 1) { $encrypt = $userinfo[$dbfields[2]]; }
			else { $encrypt = &encrypt($userinfo[$dbfields[2]]); }
			
			push @member_pass, (join ":", $userinfo[0], $encrypt);
		}

		&writefile("$datadir/member.pass", @member_pass);
	}


	## Process admin auth type
	if (($moptions[2] == 1) && ($in{'moptions2'} == 0)) {
		&deletefile("$cgidir/admin/.htaccess");
		&deletefile("$datadir/admin.pass");
		&writefile("$datadir/.random.admin", '');
	} elsif (($moptions[2] == 0) && ($in{'moptions2'} == 1)) {
		my ($text, @admins, @admin_pass);
		
		$text = "AuthName \"Admin Control Panel - $in{'SCRIPT_TITLE'} v$VERSION\"\n";
		$text .= "AuthUserFile $datadir/admin.pass\n";
		$text .= "AuthType Basic\n";
		$text .= "require valid-user\n";
		
		opendir DIR, "$datadir/admin" or &error(206, __LINE__, __FILE__, "$datadir/admin", "DIR");
		@admins = grep /\.admin$/, readdir(DIR);
		closedir DIR;
		
		foreach $admin (@admins) {
			my @info = split /::/, (&readfile("$datadir/admin/$admin"));
			push @admin_pass, (join ":", $info[0], $info[3]);
		}
	
		&writefile("$datadir/admin.pass", @admin_pass);
		&writefile("$cgidir/admin/.htaccess", $text);
		chmod 0644, "$cgidir/admin/.htaccess";
		&deletefile("$datadir/.random.admin");
	}
	
	## Process archived lists option
	if ($moptions[7] != $in{'moptions7'}) {
		foreach $member (@members) {
			my ($user, $ext, @lists);
			($user, $ext) = split /,/, $member;
			
			## Get all mailing lists for user
			opendir DIR, "$datadir/list/$user" or next;
			@lists = grep /\.list$/, readdir(DIR);
			closedir DIR;
			
			foreach $list (@lists) {
				my ($num) = $list =~ /^(\d+)\..+/;
				if ($in{'moptions7'} == 0) { &deletefile("$datadir/list/$user/$num.archive"); }
				else { &writefile("$datadir/list/$user/$num.archive"); }
			}
		}	
	}
	
	## Process follow up logs
	if ($moptions[8] != $in{'moptions8'}) {
		foreach $member (@members) {
			my ($user, $ext, @lists);
			($user, $ext) = split /,/, $member;
		
			## Get all mailing lists for user
			opendir DIR, "$datadir/list/$user" or next;
			@lists = grep /\.list$/, readdir(DIR);
			closedir DIR;
			
			&writefile("$datadir/list/$user/log");			
			foreach $list (@lists) {
				my ($num) = $list =~ /^(\d+)\..+/;
				if ($in{'moptions8'} == 0) { &removedir("$datadir/list/$user/log/$num"); }
				else { &makedir("$datadir/list/$user/log/$num"); }
			}
			&removedir("$datadir/list/$user/log");
		}	
	}
	

	## Gather up new information
	$moptions[2] = $in{'moptions2'};
	$moptions[3] = $in{'moptions3'};
	$moptions[4] = $in{'moptions4'};
	$moptions[5] = $in{'moptions5'};
	$moptions[6] = $in{'moptions6'};
	$moptions[7] = $in{'moptions7'};
	$moptions[8] = $in{'moptions8'};
	$moptions[9] = $in{'moptions9'};
	$moptions = join " ", @moptions;
	
	## Process send_confirm
	@confirm = split /\0/, $in{'send_confirm'};
	foreach $confirm (@confirm) {
		&writefile("$datadir/messages/signup_$confirm.msg", "\u\L$confirm\E Confirmation of New Mmeber") unless -e "$datadir/messages/signup_$confirm.msg";
	}
	$send_confirm = join " ", @confirm;

	## Process the dbfields
	@dbfields = ($in{'dbfields0'}, $in{'dbfields1'}, $in{'dbfields2'}, $in{'dbfields3'});
	$dbfields = join " ", @dbfields;
	
	## Process default member settings
	@default = ($in{'default0'}, $in{'default1'}, $in{'default2'}, $in{'default3'}, $in{'default4'}, $in{'default5'});
	$default = join " ", @default;

	## Process edit fields
	@edit_fields = split /\0/, $in{'edit_fields'};
	$edit_fields = join " ", @edit_fields;

	## Caculate extension fields
	$extfield = @userfields;
	
	## Process auto options
	if ($auto_options[0] == 1) { $auto_options[1] = $in{'backup_interval'}; }
	$auto_options[0] = $in{'auto_options0'};
	$auto_options = join " ", @auto_options;
	
	
	## Change info in ezylist.conf file
	$conf[0] = "\$admin_name \= \"$in{'admin_name'}\"\;";
	$conf[1] = "\$admin_email \= \"$in{'admin_email'}\"\;";
	$conf[2] = "\$dump_email \= \"$in{'dump_email'}\"\;";
	$conf[3] = "\$support_email \= \"$in{'support_email'}\"\;";
	$conf[11] = "\@edit_fields \= qw ($edit_fields)\;";	
	$conf[12] = "\@send_confirm \= qw ($send_confirm)\;";
	$conf[13] = "\@moptions \= qw ($moptions)\;";
	$conf[14] = "\@dbfields \= qw ($dbfields)\;";
	$conf[15] = "\@default \= qw ($default)\;";
	$conf[16] = "\$mailtype \= \"$in{'mailtype'}\"\;";
	$conf[17] = "\$mailprog \= \"$in{'mailprog'}\"\;";
	$conf[18] = "\@auto_options \= qw ($auto_options)\;";
	$conf[19] = "\$extfield \= $extfield\;";
	$conf[20] = "\$dbdriver \= \"$in{'dbdriver'}\"\;";
	$conf[21] = "\$dbname \= \"$in{'dbname'}\"\;";
	$conf[22] = "\$dbhost \= \"$in{'dbhost'}\"\;";
	$conf[23] = "\$dbuser \= \"$in{'dbuser'}\"\;";
	$conf[24] = "\$dbpassword \= \"$in{'dbpassword'}\"\;";
	
	## Rewrite the ezylist.conf file
	&writefile("$datadir/ezylist.conf", @conf);
	
	## Print off HTML success template
	&success("Successfully updated general settings");
		
}

################################################
## Settings - System Settings
################################################

sub setup_settings_system {

	if ($in{'action'} eq 'update') {
		my ($cmds, $refs, @conf, @format);
		
		## Get contents of ezylist.conf file
		@conf = &readfile("$datadir/ezylist.conf");

		## Format the variables as needed
		@format = qw (cmds0 cmds1 cmds2 cmds3 datadir cgidir cgiurl gif_url);
		foreach $var (@format) { $in{$var} =~ s/\/$//g; }

		## Gather new information
		@cmds = ($in{'cmds0'}, $in{'cmds1'}, $in{'cmds2'}, $in{'cmds3'});
		$cmds = join " ", @cmds;
		
		@refs = ($in{'refs1'}, $in{'refs2'}, $in{'refs3'});
		$refs = join " ", @refs;

		## Add new information to wsr.conf file
		$conf[4] = "\@cmds \= qw ($cmds)\;";
		$conf[5] = "\@refs \= qw ($refs)\;";
		$conf[6] = "\$datadir \= \"$in{'datadir'}\"\;";
		$conf[7] = "\$cgidir \= \"$in{'cgidir'}\"\;";
		$conf[8] = "\$cgiurl \= \"$in{'cgiurl'}\"\;";
		$conf[9] = "\$in{\'gif_url\'} \= \"$in{'gifurl'}\"\;";
		
		## Save changes to ezylist.conf file
		&writefile("$datadir/ezylist.conf", @conf);
		
		## Print off HTML success template
		&success("Successfully updated system settings");
			
	} else {
		## Get ready to print HTML template
		($in{'cmds0'}, $in{'cmds1'}, $in{'cmds2'}, $in{'cmds3'}) = ($cmds[0], $cmds[1], $cmds[2], $cmds[3]);
		($in{'refs1'}, $in{'refs2'}, $in{'refs3'}) = ($refs[0], $refs[1], $refs[2]);
		
		$in{'datadir'} = $datadir;
		$in{'cgidir'} = $cgidir;
		$in{'cgiurl'} = $cgiurl;
		
		## Print the HTML template
		print &parse_template('admin/setup/settings_system.htmlt');
		exit(0);
	
	}

}

################################################
## Settings - Style Settings
################################################

sub setup_settings_styles {

	if ($in{'action'} eq 'update') {
		my (@styles, @results);
		
		@styles = &readfile("$datadir/dat/styles_cpanel.dat");
		foreach $line (@styles) {
			next if $line eq '';
			my ($key, $value) = split /::/, $line;
			push @results, (join "::", $key, $in{"\L$key\E"});
		}
		
		&writefile("$datadir/dat/styles_cpanel.dat", @results);
		&success("Successfully updated style settings");
		exit(0);
	
	} else {
		my (@styles);
		
		@styles = &readfile("$datadir/dat/styles_cpanel.dat");
		foreach $line (@styles) {
			next if $line eq '';
			my ($key, $value) = split /::/, $line;
			$in{$key} = $value;
		}
		
		## Print HTML template
		print &parse_template('admin/setup/settings_styles.htmlt');
		exit(0);
		
	}

}

################################################
## Settings - Manage Domains
################################################

sub setup_settings_domains {

	if ($in{'submit'} eq 'Delete Domain') {
		my ($x, @domains);
		
		$x=0;
		@domains = &readfile("$datadir/dat/domains.dat");
		foreach $domain (@domains) {
			if ($domain eq $in{'domain'}) { 
				splice @domains, $x, 1;
				last;
			}
		$x++; }
		&removedir("$datadir/ar/$in{'domain'}");
		&removedir("$datadir/arlog/$in{'domain'}");
		
		&writefile("$datadir/dat/domains.dat", @domains);
		&success("Successfully deleted the domain name, <b>$in{'domain'}</b>");

	} elsif ($in{'submit'} eq 'Add Domain') {
		my $field = $in{'domain_name'};

		if ($field !~ /.+\..+/) { &error(500, __LINE__, __FILE__, "Invalid domain name, <b>$field</b>"); }
		elsif ($field =~ /\s/) { &error(500, __LINE__, __FILE__, "The database field $x contains spaces, <b>$field</b>"); }
		elsif ($field eq '') { &error(500, __LINE__, __FILE__, "You did not specify a name for the database field, $x"); }
		&makedir("$datadir/ar/$field");
		&makedir("$datadir/arlog/$field");
		&appendfile("$datadir/dat/domains.dat", $field);
		
		&success("Successfully added new domain, <b>$field</b>");
	
	} else {
	
		@{$in{'domain'}} = &readfile("$datadir/dat/domains.dat");
		print &parse_template('admin/setup/settings_domains.htmlt');
		exit(0);	
	}

}

################################################
## Backup Member Data
################################################

sub setup_backup {
	if ($PARSE == 1) {
		my ($date, $time, $tarfile, $success);
		if ($in{'confirm'} != 1) { &success("Did not backup the member database"); }	
		
		## Get needed info
		($date, $time) = &getdate;
		$tarfile = "$datadir/backup/$date.tar";
		if (-e "$tarfile.gz") { &error(500, __LINE__, __FILE__, "A backup of the database has already been created today"); }
		
		## Put database into a .tar.gz file
		$success = chdir "$datadir";
		if ($success == 0) { &error(500, __LINE__, __FILE__, "Unable to change to the directory, <b>$datadir</b>"); }
		system("$cmds[2] -cf $tarfile --exclude=backup ./");
		system("$cmds[3] $tarfile");
		
		## Finish up the backup
		if (-e $tarfile) { &deletefile($tarfile); }
		if (!-e "$tarfile.gz") { &error(500, __LINE__, __FILE__, "Unable to backup member database"); }
		
		## Print off success HTML template
		&success("Successfully performed backup of member database.  The backup is located at <b>$tarfile.gz</b>");
	
	} else {
		$in{'page_title'} = "Backup Member Data";
		$in{'confirm_text'} = "Are you sure you want to backup your entire member database?";
		print &parse_template('admin/confirm.htmlt');
		exit(0);
	}

}

################################################
## Manage administrators
################################################

sub setup_admin {
	$in{'page_title'} = "Manage Administrators";
	
	if ($PARSE == 1) {
		$in{'page_title'} = $in{'submit'};

		my @actions = &readfile("$datadir/dat/navmenu.dat");
		foreach $line (@actions) {
			my ($name, $menu, @options) = split /::/, $line;
			$in{'actions_html'} .= qq!<th nowrap bgcolor="#000000">$style{'FONT_BODY'}<font color="#FFFFFF">$name</font></th>!;
		}
		$in{'actions_html'} .= "\n</tr><tr>\n";

		if ($in{'submit'} eq 'Create New Administrator') {

			foreach $line (@actions) {
				my ($name, $menu, @options) = split /::/, $line;
				$in{'actions_html'} .= qq!<td nowrap valign=top>$style{'FONT_BODY'}!;
			
				my $x=1;
				foreach $option (@options) {
					my ($oname, $oaction) = split /,/, $option;
					$in{'actions_html'} .= qq!<input type="checkbox" name="$menu-$x" value="1">$oname<br>!;
				$x++; }
				$in{'actions_html'} .= "</font></td>\n";
			}
		
			&run_modules("admin/admin.cgi?menu=setup&action=admin");
			print &parse_template('admin/setup/admin_create.htmlt');
			exit(0);

		} elsif ($in{'submit'} eq 'Edit Administrator') {
			my ($user, $profile, $action, @profile, @action);
		
			$user = $in{'username'};
			if (!-e "$datadir/admin/$user.admin") { &error(500, __LINE__, __FILE__, "Administrator does not exist, $user"); }
			
			## Get admin info
			($profile, $action) = &readfile("$datadir/admin/$user.admin");
			@profile = split /::/, $profile;
			@action = split /::/, $action;
			
			## Set some variables
			$in{'username'} = $profile[0];
			$in{'fullname'} = $profile[1];
			$in{'email'} = $profile[2];
			$in{'encrypt'} = $profile[3];
			
			## Get the action info
			$x=0;
			foreach $line (@actions) {
				my ($name, $menu, @options) = split /::/, $line;
				my @info = split /,/, $action[$x];
				$in{'actions_html'} .= qq!<td nowrap valign=top>$style{'FONT_BODY'}!;
								
				$y=1;
				foreach $option (@options) {
					my ($oname, $oaction) = split /,/, $option;
					my $chk;
					$chk = "checked" if $info[($y-1)] == 1;
					$in{'actions_html'} .= qq!<input type="checkbox" name="$menu-$y" value="1" $chk>$oname<br>!;
				$y++; }
				
				$in{'actions_html'} .= qq!</font></td>!;

			$x++; }
			
			## Print the HTML template
			&run_modules("admin/admin.cgi?menu=setup&action=admin");
			print &parse_template('admin/setup/admin_edit.htmlt');
			exit(0);

		} elsif ($in{'submit'} eq 'Delete Administrator') {
			if (exists $in{'confirm'}) {
				my ($user);
				
				$user = $in{'confirm_data'};
				if ($in{'confirm'} == 0) { &success("Did not delete the administrator, $user"); }
				
				## Delete the administrator
				&deletefile("$datadir/admin/$user.admin");
				if ($moptions[2] == 1) { &delete_fileline("$datadir/admin.pass", 'begin', "$user:"); }
				&success("Successfully deleted administrator, $user");
				
			} else {
				my $user = $in{'username'};
				if (!-e "$datadir/admin/$user.admin") { &error(500, __LINE__, __FILE__, "Administrator does not exist, $user"); }
			
				$in{'confirm_data'} = $user;
				$in{'title'} = "Delete Administrator";
				$in{'confirm_text'} = "Are you sure you want to delete the administrator, $user?";
				$in{'confirm_text'} .= qq!<input type="hidden" name="submit" value="Delete Administrator">!;
				&run_modules("admin/admin.cgi?menu=setup&action=admin");
				print &parse_template('admin/confirm.htmlt');
				exit(0);
			}
		}

	} else {
		## Get a list of all admin's
		opendir DIR, "$datadir/admin" or &error(206, __LINE__, __FILE__, "$datadir/admin", "DIR");
		my @admins = grep /\.admin$/, readdir(DIR);
		closedir DIR;
		
		## Get all admin info
		foreach $admin (@admins) {
			my ($info, $actions) = &readfile("$datadir/admin/$admin");
			my ($user, $name, $email, $pass) = split /::/, $info;
			push @{$in{'admin_username'}}, $user;
			push @{$in{'admin_name'}}, $name;
			push @{$in{'admin_email'}}, $email;
		}
		
		&run_modules("admin/admin.cgi?menu=setup&action=admin");
		print &parse_template('admin/setup/admin.htmlt');
		exit(0);
	
	}

}

################################################
## Create a new administrator
################################################

sub setup_admin_create {
	$in{'page_title'} = "Create New Administrator";
	
	my ($x, $user, $addr, $admin_info, $encrypt, @navinfo, @action);
	
	## Get some info
	$user = $in{'username'};
	$addr = $in{'email'};
	
	## Perform some checks
	if ($user eq '') { &error(500, __LINE__, __FILE__, "You did not specify a username"); }
	elsif ($user =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Username contains spaces or special characters"); }
	elsif (-e "$datadir/admin/$user.admin") { &error(500, __LINE__, __FILE__, "Administrator already exists, $user"); }
	elsif ($addr !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid e-mail address, $addr"); }
	elsif ($in{'password'} ne $in{'password2'}) { &error(500, __LINE__, __FILE__, "Passwords do not match"); }
	
	## Create the admin profile
	$encrypt = &encrypt($in{'password'});
	$admin_info = join "::", $user, $in{'fullname'}, $addr, $encrypt;
	
	## Process admin password
	if ($moptions[2] == 1) { &appendfile("$datadir/admin.pass", "$user:$encrypt"); }
	
	## Gather up the action info
	@navinfo = &readfile("$datadir/dat/navmenu.dat");
	foreach $line (@navinfo) {
		next if $line eq '';
		my ($name, $menu, @actions) = split /::/, $line;
		my @info; 
		
		for $x ( 1 .. @actions ) {
			if ($in{"$menu-$x"} == 1) { push @info, 1; }
			else { push @info, 0; }
		}
		push @action, (join ",", @info);
	}
	$admin_info .= "\n" . (join "::", @action);

	## Add new admin to database
	&writefile("$datadir/admin/$user.admin", $admin_info);
	
	## Print the HTML success page
	&run_modules("admin/admin.cgi?menu=setup&action=admin_create");
	&success("Successfully created new administrator, $user");
}

################################################
## Edit an administrator
################################################

sub setup_admin_edit {
	$in{'page_title'} = "Edit Administrator";
	
	my ($x, $user, $addr, $admin_info, $encrypt, @navinfo, @action);
	
	## Get some info
	$user = $in{'username'};
	$addr = $in{'email'};
	
	## Perform some checks
	if ($addr !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid e-mail address, $addr"); }
		
	## Create the admin profile
	if ($in{'password'} ne "<--ENCRYPTED-->") { $encrypt = &encrypt($in{'password'}); }
	else { $encrypt = $in{'encrypt'}; }
	$admin_info = join "::", $user, $in{'fullname'}, $addr, $encrypt;
	
	## Process the password
	if ($moptions[2] == 1) { &replace_fileline("$datadir/admin.pass", 'begin', "$user:", "$user:$encrypt"); }

	## Gather up the action info
	@navinfo = &readfile("$datadir/dat/navmenu.dat");
	foreach $line (@navinfo) {
		next if $line eq '';
		my ($name, $menu, @actions) = split /::/, $line;
		my @info; 
		
		for $x ( 1 .. @actions ) {
			if ($in{"$menu-$x"} == 1) { push @info, 1; }
			else { push @info, 0; }
		}
		push @action, (join ",", @info);
	}
	$admin_info .= "\n" . (join "::", @action);

	## Add new admin to database
	&writefile("$datadir/admin/$user.admin", $admin_info);
	
	## Print the HTML success page
	&run_modules("admin/admin.cgi?menu=setup&action=admin_edit");
	&success("Successfully edited administrator, $user");
}

################################################
## Export database
################################################

sub setup_export {
	if ($PARSE == 1) {
		my ($delim, $html, $total, $count, $fields, $message, $DBSUB, @members, @additional);

		## Make sure e-mail address is valid
		if ($in{'email'} !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid e-mail address, <i>$in{'email'}</i>"); }
		
		## Get database delimiter
		if ($in{'delimiter'} eq 'other') { 
			if ($in{'other_delimiter'} eq '') { &error(500, __LINE__, __FILE__, "No database delimiter specified"); }
			$delim = $in{'other_delimiter'};
		} else { $delim = $in{'delimiter'}; }
		
		## Get a list of all members
		$DBSUB = $dbdriver . "_search_account";
		@members = &$DBSUB('all', 'all');
		$total = @members;
		
		$total = @members;
		$count=0;

		## Get additional information
		if ($in{'additional0'} eq 'status') { push @userfields, 'Member Status'; }
		if ($in{'additional1'} eq 'type') { push @userfields, 'Member Type'; }

		if ($delim eq 'tab') { $fields = join "\t", @userfields; }
		else { $fields = join $delim, @userfields; }
		$fields = uc $fields;

		## Create the header of the message
		$message = "Subject: Web Site Replicator v$VERSION.  Export Database Results\n";
		$message .= "Content-type: text/plain\n\n";
		$message .= "$fields\n";
		
		## Start processing all members
		&processing_start("Currently exporting member database...", "Export Database", $total);
		foreach $member (@members) {
			my ($status, $type, $row, $DBSUB, @userinfo);
			($status, $type) = &get_ext($member);

			next if (!$status || !$type);
			$DBSUB = $dbdriver . "_fetch_account";
			@userinfo = &$DBSUB($member);

			if ($moptions[2] == 1) { $userinfo[$dbfields[2]] = "<--ENCRYPTED-->"; }
			while (@userinfo < @userfields) { push @userinfo, ''; }
			
			if ($in{'additional0'} eq 'status') { push @userinfo, $status; }
			if ($in{'additional1'} eq 'type') { push @userinfo, $type; }
			
			if ($delim eq 'tab') { $row = join "\t", @userinfo; }
			else { $row = join $delim, @userinfo; }
			$message .= "$row\n";

			sleep 1;
			if (($count =~ /0$/) && ($count > 1)) { &processing_update($count); }
		$count++; }
	
		## E-mail the results
		$moptions[11] = 0;
		$in{'_TO'} = $in{'email'};
		$in{'_FROM_NAME'} = $admin_name;
		$in{'_FROM_ADDR'} = $admin_email;
		$in{'_MESSAGE'} = $message;
		&mailmsg_from_hash(%in);
		
		## Finish up
		$in{'success_message'} = "Successfully exported member database.  The results have been e-mailed to, <b>$in{'email'}</b>";
		$html = &parse_template('admin/success.htmlt');
		&processing_finish($html);
		exit(0);

	} else {
		print &parse_template('admin/setup/export.htmlt');
		exit(0);
	}

}

################################################
## Other
################################################

sub setup_other {
	my ($total, $count, $DBSUB, $member, @members);

	if ($PARSE == 0) { print &parse_template('admin/setup/other.htmlt'); exit(0); }
	
	$DBSUB = $dbdriver . "_search_account";
	@members = &$DBSUB('all', 'all');
	$total = @members;

	if ($in{'action'} eq 'delete') {

		$count=0;
		&processing_start("Currently deleting all members...", "Other - Delete Database", $total);
		foreach $member (@members) {
			my ($status, $type, $DBSUB);
		
			($status, $type) = &get_ext($member);
			next if (!$status || !$type);
			
			## Delete the member from database
			$DBSUB = $dbdriver . "_delete_account";
			&$DBSUB($member, $type, $status);

			if (($count =~ /0$/) && ($count > 1)) { &processing_update($count); }
		$count++; }
		
		@domains = &readfile("$datadir/dat/domains.dat");
		foreach $domain (@domains) {
			&removedir("$datadir/ar/$domain");
			&removedir("$datadir/arlog/$domain");
		}
		if ($moptions[3] == 1) { &writefile("$datadir/member.pass"); }

		&writefile("$datadir/$dbdriver.mls", 0);
		&writefile("$datadir/$dbdriver.ads", 0);

		$in{'success_message'} = "Successfully deleted all members from database";
		$html = &parse_template('admin/success.htmlt');
		&processing_finish($html); exit(0);

	}
	


}

1;
