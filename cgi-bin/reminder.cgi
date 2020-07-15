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

print "Content-type: text/html\n\n";
eval { require $conf; };
if ($@) { print "Unable to find required file, <b>ezylist.conf</b>, which should be located at, <b>$conf</b>"; exit; }
eval { require "$cgidir/lib/main-lib.pl"; };
if ($@) { print "Unable to find required file, <b>main-lib.pl</b>, which should be located at <i>$cgidir/lib/main-lib.pl</i>"; exit; }
eval { require "$cgidir/lib/ezylist-lib.pl"; };
if ($@) { print "Unable to find required file, <b>ezylist-lib.pl</b>, which should be located at <i>$cgidir/lib/ezylist-lib.pl</i>"; exit; }
$HEADER = 1;

## See if member's passwords are encrypted
if ($moptions[1] == 1) { &error(500, __LINE__, __FILE__, "Password reminder feature does not work with encrypted passwords"); }

## Figure out what to do
if ($PARSE == 1) { &remind_user; }
else { print &parse_template('reminder.htmlt', 'main'); exit(0); }

################################################
## E-Mail the user their password
################################################

sub remind_user {
	my ($x, $user, $email, $status, $type, $password, @userinfo);

	## Get needed info
	($user, $email) = ($in{'username'}, $in{'email'});
	($status, $type) = &get_ext($user);
	if (!defined $status || !defined $type) { &error(500, __LINE__, __FILE__, "Invalid username or e-mail address"); }
	@userinfo = split /::/, (&readfile("$datadir/cgi/$user.$status.$type"));

	## Make sure e-mail address is valid
	if (lc($userinfo[$dbfields[1]]) ne lc($email)) { &error(500, __LINE__, __FILE__, "Invalid username or e-mail address"); }

	## E-mail the user's password
	$x=0;
	$in{'password'} = $userinfo[$dbfields[2]];
	foreach $field (@userfields) { $in{$field} = $userinfo[$x]; $x++; }

	&mailmsg_from_file($email, "$datadir/messages/password_reminder.msg", $admin_email, $admin_name, $admin_pass, %in);

	## Redirect the user
	if (exists $in{'_redirect'}) {
		print qq~
		<html><head>
		<script language="javascript">
			window.document.location = "$in{'_redirect'}";
		</script>
		</head></html>~;
	} else {
		$in{'success_text'} = "Your password has been e-mailed to you at, <b>$email</b>";
		print &parse_template('success.htmlt', 'main');
	}
	exit(0);
}

1;

