
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
## Edit profile
################################################

sub setup_profile {
	my $DBSUB;

	if ($PARSE == 1) {
		my ($email, $oldpass, $passrow, %user);
		
		$oldpass = $userinfo[$dbfields[2]];
		$email = $userinfo[$dbfields[1]];
		$passrow = $userfields[$dbfields[2]];
		
		## Perform a few checks
		if ($email !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid e-mail address, <b>$email</b>"); }
		
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
		
		## Change member profile
		$DBSUB = $dbdriver . "_edit_account";
		&$DBSUB($user, '.cgi', @edit_fields);
		
		## Print off HTML success template
		&success("Successfully edited member profile");
	
	} else {
		
		$ext = &get_ext($user);
		$DBSUB = $dbdriver . "_fetch_account";
		@userinfo = &$DBSUB($user, $ext);
		
		if ($moptions[1] == 1) {
			$in{'_moptions1'} = 1;
			$userinfo[$dbfields[2]] = "<--ENCRYPTED-->";
		}
		
		$x=0;
		foreach $field (@userfields) {
			my $ok=0;
			foreach (@edit_fields) {
				if ($_ eq $field) { $ok=1; last; }
			}
			
			if ($ok == 1) {
				push @{$in{'editfield'}}, $field;
				push @{$in{'userinfo'}}, $userinfo[$x];
			}
		$x++; }
		
		## Print HTML template
		print &parse_template('cpanel/setup/profile.htmlt');
		exit(0);
	
	}

}

################################################
## Contact support
################################################

sub setup_support {

	if ($PARSE == 1) {
		my ($message, $from_name, $from_email);
		
		## Get needed info
		$from_name = $userinfo[$dbfields[0]];
		$from_email = $userinfo[$dbfields[1]];
		$in{'contents'} =~ s/[\r\f]//gi;
		
		## Create support message
		$message = "Subject: [SUPPORT] - $user\n";
		$message .= "Content-type: text/plain\n\n";
		$message .= "Hello there,\n\nA new support request has been submitted.  Below is the contents of the e-mail message.\n\n";
		$message .= "Username: $user\nFull Name: $from_name\nE-Mail Address: $from_email\n\n";
		$message .= "==================================================\n\n";
		$message .= "$in{'contents'}\n\n==================================================\n\n-- END --\n";
		
		## Send the e-mail
		$in{'_TO'} = $support_email;
		$in{'_FROM_ADDR'} = $from_email;
		$in{'_FROM_NAME'} = $from_name;
		$in{'_MESSAGE'} = $message;
		&mailmsg_from_hash(%in);
		
		## Print off HTML success template
		&success("Successfully sent support request to customer support");
	
	} else { print &parse_template('cpanel/setup/support.htmlt'); }

}

1;



