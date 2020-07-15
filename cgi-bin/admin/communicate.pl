
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

#####################################################
## Email member(s)
#####################################################

sub communicate_email {
	if ($PARSE == 0) {
		print &parse_template('admin/communicate/get_action.htmlt');
		exit(0);
	} elsif (($in{'step'} eq "getaction") && ($in{'action'} eq 'notify')) {
		$in{'title'} = "Email Member\(s\)";
		print &parse_template('admin/get_account.htmlt', 'main');
		exit(0);
	} elsif ($in{'step'} eq "getmember") {
		&display_all_accounts("Email Member\(s\)");
	} elsif ($in{'step'} eq "editmsg") {
		my ($message, @contents);
		
		## Make sure sender address is valid
		if ($in{'_FROM_ADDR'} !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid e-mail address, <b>$in{'_FROM_ADDR'}</b>"); }
		
		## Save message to a temp file
		$message = &format_message($in{'_html'}, $in{'subject'}, $in{'contents'});
		&writefile("$datadir/tmp/emailall.msg", $message);
		
		@contents = split /\n/, $in{'contents'};
		delete $in{'contents'};
		foreach $line (@contents) {
			$line =~ s/[\r\n]//g;
			$in{'contents'} .= "$line<br>\n";
		}
		$in{'title'} = "Email Member\(s\)";
		print &parse_template('admin/communicate/email_preview.htmlt');
		exit(0);

	} elsif (($in{'action'} eq 'emailall') || (exists $in{'username'})) {
		if (!exists $in{'_notify'} && !exists $in{'_emailall'}) {
			if ($in{'action'} eq 'emailall') { $in{"_emailall"} = 1; $in{'_notify'} = 0; }
			elsif ((exists $in{'username'}) && ($in{'username'} ne "")) { $in{'_notify'} = 1; }
			else { $in{"_emailall"} = 1; $in{'_notify'} = 0; }
		}

		## If needed, get a message
		if ($in{'message'} eq '') {
			$in{'_custom'} = 1;
			&communicate_get_message("Email Member\(s\)", 1, 1);
		}
		elsif ($in{'message'} eq '_custom_message') {
			$in{'subject'} = "";
			$in{'contents'} = "";
			$in{'_moptions0'} = $moptions[0];
			foreach (@userfields) { $in{'merge_options'} .= "<option>$_\n"; }
			if ($moptions[0] == 1) {
				foreach (@member_types) { $in{'member_type_options'} .= qq!<input type="radio" name="c2" value="$_">\u\L$_\E member type<br>!; }
			}
			
			print &parse_template('admin/communicate/email.htmlt');
			exit(0);
		} else {
			## Get the message
			my @message = &readfile("$datadir/messages/$in{'message'}");
			$in{'name'} = shift @message;
			$in{'subject'} = shift @message;
			$html = shift @message;
			$message =~ s/^\n//;
		
			## Format a few variables
			$in{'subject'} =~ s/^Subject: //;
			$in{'contents'} = (join "\n", @message);
			if ($html =~ /html/) { $in{'html'} = "checked"; }
			else { $in{'html'} = ""; }
		
			foreach (@userfields) { $in{'merge_options'} .= "<option>$_\n"; }

			## Print the HTML template
			print &parse_template('admin/communicate/email.htmlt');
			exit(0);
		}
	}
}

################################################
## E-mail member(s) - part 2
################################################

sub communicate_email2 {
	my ($total, $count, $message, $DBSUB, @users, @recip, %info);
	
	## Get the message contents
	$in{'_MESSAGE'} = &readfile("$datadir/tmp/emailall.msg");
	
	## Get all user info
	if (exists $in{'username'}) {
		$users[0] = $in{'username'};
	} else {
		$DBSUB = $dbdriver . "_search_account";
		@users = &$DBSUB($in{'c1'}, $in{'c2'});
	}

	## Put some last info into the %info hash
	$info{'_merge'} = (join "::", @userfields);
	$info{'_recipient'} = (join "::", @recip);

	## Start processing
	$total = @users; $count=0;
	&processing_start("Currently e-mailing all members...", "E-Mail All Members", $total);
	foreach $user (@users) {
		my ($x, $addr, @userinfo, %merge);
		
		$DBSUB = $dbdriver . "_fetch_account";
		@userinfo = &$DBSUB($user);
		$userinfo[$dbfields[2]] = "<--ENCRYPTED-->" if $moptions[1] == 1;
		$in{'_TO'} = $userinfo[$dbfields[1]];
		
		$x=0;
		foreach (@userfields) { $in{$_} = $userinfo[$x]; $x++; }	
		&mailmsg_from_hash(%in);
		if (($count =~ /0$/) && ($count > 1)) { &processing_update($count); }		
	$count++; }
	
	## print off the HTML success page
	$in{'success_message'} = "Successfully e-mailed all members.  A total of <b>$count</b> messages were sent out.";
	$html = &parse_template('admin/success.htmlt');
	&run_modules("admin/admin.cgi?menu=communicate&action=emailall2");
	&processing_finish($html);
	
	exit(0);

}

################################################
## Create a message
################################################

sub communicate_create {
	if ($PARSE == 1) {
		my ($x, $message);
		
		if ($in{'name'} eq '') { &error(500, __LINE__, __FILE__, "You did not specify a name for the message"); }
		
		$message = &format_message($in{'_html'}, $in{'subject'}, $in{'contents'});
		$message = "$in{'name'}\n" . $message;
		
		## Save the message
		$x=1;
		while (1) {
			last if !-e "$datadir/messages/message$x.msg";
		$x++; }
		
		&writefile("$datadir/messages/message$x.msg", $message);
		
		## Print the HTML success page
		&success("Successfully created message, <b>$in{'name'}</b>");
		
	} else { 
		foreach (@userfields) { $in{'merge_options'} .= "<option>$_\n"; }
		print &parse_template('admin/communicate/create.htmlt');
		exit(0);
	}

}

################################################
## Manage a message
################################################

sub communicate_manage {
	if ((exists $in{'confirm'}) || ($in{'step'} eq 'getmsg')) {
		my $REDSUB;
		## Redirect actions
		$REDSUB = $query{'menu'} . "_" . $in{'action'};
		&$REDSUB;
		exit(0);
	} elsif ($PARSE == 0) {
		$in{'_manage'} = 1;
		&communicate_get_message("Edit Message", 1, 0);
	}

}

################################################
## Edit a message
################################################

sub communicate_edit {
	if ($PARSE == 1) {
		if ($in{'message'} eq '') { &error(500, __LINE__, __FILE__, "You did not select a message to edit"); }
		
		## Get the message
		my @message = &readfile("$datadir/messages/$in{'message'}");
		$in{'name'} = shift @message;
		$in{'subject'} = shift @message;
		$html = shift @message;
		$message =~ s/^\n//;
		
		## Format a few variables
		$in{'subject'} =~ s/^Subject: //;
		$in{'contents'} = (join "\n", @message);
		if ($html =~ /html/) { $in{'html'} = "checked"; }
		else { $in{'html'} = ""; }
		
		foreach (@userfields) { $in{'merge_options'} .= "<option>$_\n"; }

		## Print the HTML template
		print &parse_template('admin/communicate/edit.htmlt');
		exit(0);
		
	} else { &communicate_get_message("Edit Message", 1, 0); }

}

################################################
## Edit a message - part 2
################################################

sub communicate_edit2 {
	my ($x, $message);
		
	$message = &format_message($in{'_html'}, $in{'subject'}, $in{'contents'});
	$message = "$in{'name'}\n" . $message;
	&writefile("$datadir/messages/$in{'message'}", $message);
		
	## Print the HTML success page
	&success("Successfully edited message, <b>$in{'name'}</b>");
}

################################################
## Delete a message
################################################

sub communicate_delete {
	if (exists $in{'confirm'}) {
		my ($message, $name, @message);
		
		## Get some info
		$message = $in{'confirm_data'};
		@message = &readfile("$datadir/messages/$message");
		$name = shift @message;
	
		if ($in{'confirm'} == 0) { &success("Did not delete the message, <b>$name</b>"); }
		
		## Delete the message
		&deletefile("$datadir/messages/$message");
		&success("Successfully deleted the message, <b>$name</b>");
		
	} elsif ($PARSE == 1) {
		if ($in{'message'} eq '') { &error(500, __LINE__, __FILE__, "You did not select a message to delete"); }
		elsif ($in{'message'} !~ /^message/) { &error(500, __LINE__, __FILE__, "You are not allowed to delete System messages"); }
		
		## Get the message name
		my @message = &readfile("$datadir/messages/$in{'message'}");
		my $name = shift @message;

		$in{'page_title'} = "Delete Message";
		$in{'confirm_data'} = $in{'message'};
		$in{'confirm_text'} = "Are you sure you want to delete the message, <b>$name</b>?";
		print &parse_template('admin/confirm.htmlt');
		exit(0);

	} else { &communicate_get_message("Delete Message", 0, 0); }


}

################################################
## Get a message
################################################

sub communicate_get_message {
	($in{'title'}, $in{'_system'}, $in{'_custom'}) = @_;
	
	opendir DIR, "$datadir/messages" or &error(206, __LINE__, __FILE__, "$datadir/messages", "DIR");
	my @messages = grep /\.msg$/, readdir(DIR);
	closedir DIR;
	
	foreach $file (@messages) {

		## Get the name of the message
		open FILE, "$datadir/messages/$file" or &error(201, __LINE__, __FILE__, "$datadir/messages/$file", "FILE");
		my $name = <FILE>;
		my $subject = <FILE>;
		close FILE;
		chomp $name, $subject;
		$subject =~ s/^Subject: //;
		
		push @{$in{'rmessage'}}, $file;
		push @{$in{'rname'}}, $name;
		push @{$in{'rsubject'}}, $subject;
		if ($file =~ /^message\d/) {
			push @{$in{'rtype'}}, "pre written";
		} else {
			push @{$in{'rtype'}}, "system";
		}
	}
	
	push @{$in{'action'}}, "edit";
	push @{$in{'action'}}, "delete";
	print &parse_template('admin/communicate/get_message.htmlt');
	exit(0);

}

1;

