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

## Load the required files
eval { require $conf; };
if ($@) { print "Content-type: text/html\n\nUnable to find required file, <b>wsr.conf</b>, which should be located at, <b>$conf</b>"; exit; }
eval { require "$cgidir/lib/main-lib.pl"; };
if ($@) { print "Content-type: text/html\n\nUnable to find required file, <b>main-lib.pl</b>, which should be located at, <b>$cgidir/lib/main-lib.pl</b>"; exit; }
eval { require "$cgidir/lib/ezylist-lib.pl"; };
if ($@) { print "Content-type: text/html\n\nUnable to find required file, <b>ezylist-lib.pl</b>, which should be located at, <b>$cgidir/lib/ezylist-lib.pl</b>"; exit; }
&print_header;

## Get started
&get_started;

## Create new member
&create_member;

## Welcome the new member
&welcome_member;

## Exit program
exit(0);

################################################
## Get needed info, and perform checks
################################################

sub get_started {

	## Get needed info
	$user = $in{'username'};
	($status, $type) = &get_ext($user);
	@confirm = split /\0/, $in{'_confirm'};
	$name = $in{$userfields[$dbfields[0]]};
	$email = $in{$userfields[$dbfields[1]]};
	$pass = $in{$userfields[$dbfields[2]]};
	($date, $time) = &getdate;

	## Perform some checks
	if ($user eq '') { &error(500, __LINE__, __FILE__, "No username specified"); }
	elsif ($user =~ /[\s\W]/) { &error(500, __LINE__, __FILE__, "Username contains spaces or special characters, <b>$user</b>"); }
	elsif (defined $status || defined $type) { &error(500, __LINE__, __FILE__, "Username already exists, <b>$user</b>"); }
	elsif ($email !~ /.*\@.*\..*/) { &error(500, __LINE__, __FILE__, "Invalid e-mail address, <b>$addr</b>"); }
	
	foreach $key (keys %in) { $in{lc($key)} = $in{$key}; }
	
	## Make sure all userfields are there
	foreach $field (@userfields) {
		if (!exists $in{$field}) { &error(500, __LINE__, __FILE__, "Required form field does not exist, <b>$field</b>"); }
	}

}

################################################
## Create the new member
################################################

sub create_member {

	## Process member's password
	if (($moptions[1] == 1) || ($moptions[3] == 1)) {
		$encrypt = &encrypt($pass);
		$in{$userfields[$dbfields[2]]} = $encrypt if $moptions[1] == 1;
		&appendfile("$datadir/member.pass", "$user:$encrypt") if $moptions[3] == 1;
	}

	## Create member profile
	$DBSUB = $dbdriver . "_create_account";
	&$DBSUB($user, 'unregistered', @userfields);
	&copy_template($user, 'conf');

	## Update member's conf file with new info
	&edit_conf($user, 'conf', 'EZYLIST_ARNUM', $default[0]);
	&edit_conf($user, 'conf', 'EZYLIST_LISTNUM', $default[1]);
	&edit_conf($user, 'conf', 'EZYLIST_MSGNUM', $default[2]);
	&edit_conf($user, 'conf', 'EZYLIST_CYCLENUM', $default[3]);
	&edit_conf($user, 'conf', 'EZYLIST_MAXSCH', $default[4]);
	&edit_conf($user, 'conf', 'EZYLIST_MAXNUM', $default[5]);
	
	## Send out all needed confirmation messages
	foreach $confirm (@send_confirm) {
		if ($confirm eq 'member') { &mailmsg_from_file($email, "$datadir/messages/signup_member.msg", $admin_email, $admin_name, $admin_pass, %in); }
		elsif ($confirm eq 'admin') { &mailmsg_from_file($admin_email, "$datadir/messages/signup_admin.msg", $email, $name, $pass, %in); }
	}

}

#####################################################
### Finish up and welcome new member
#####################################################

sub welcome_member {

	$STATUS = 200;
	if (exists $in{'_redirect'}) {
		print qq~
		<html><head>
		<script language="javascript">
			window.document.location = "$in{'_redirect'}";
		</script>
		</head></html>~;
	} else {
		print &parse_template('newuser_thankyou.htmlt');
	}

	exit(0);
}

