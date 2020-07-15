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

## Print HTML header
&print_header;

## Figure out what to do
if ($PARSE == 1) {
	$query{'user'} = $in{'username'};
	$query{'listid'} = $in{'listid'};
	$query{'id'} = $in{'id'};
	&unsubscribe;
} else { &unsubscribe_preview; }

## Exit program
exit(0);


################################################
## Preview unsubscribe informations
################################################

sub unsubscribe_preview {
	## Get needed info
	$user = $query{'user'};
	if ($user eq '') { &error(500, __LINE__, __FILE__, "You did not select a mailer"); }
	$listid = $query{'listid'};
	if ($listid eq '') { &error(500, __LINE__, __FILE__, "You did not select a mailing list"); }
	$id = $query{'id'};
	if ($id eq '') { &error(500, __LINE__, __FILE__, "You did not select an entry"); }
	%info = &ezylist_get_listinfo($user);
	
	## Create the HTML form
$form = qq!

<form action="$cgiurl/unsubscribe.cgi" method="POST">
<input type="hidden" name="username" value="$user">
<input type="hidden" name="listid" value="$listid">
<input type="hidden" name="id" value="$id">
<font face="arial" size=2>
<center>
<br><br>
<big><b>Unsubscribe Entry of Mailing List</b></big>
<br><br>
Username: $user
<br>
Listname: $listid
<br>
Entryid: $id
<br><br>
</center>
<hr width=90%>
<center>
<br>
<input type="radio" name="confirm" value="1">Yes 
<input type="radio" name="confirm" value="0" checked>No
<br><br>
</center>
<hr width=90%>
<center>
<br>
<input type="submit" value="Unsubscribe">
</center>
!;

	$form .= "</font></form>\n\n";

	&print_header;
	print $form;
	exit(0);
}

################################################
## Unsubsribe entry from list
################################################

sub unsubscribe {
	my ($user, $listid, $status, $type, $id, $ok);
	
	($user, $listid, $id) = ($in{'username'}, $in{'listid'}, $in{'id'});

	if ($in{'confirm'} == 1) {
		## Get needed info
		($status , $type) = &get_ext($user);
		if (!defined $status || !defined $type) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
		elsif (!-e "$datadir/list/$user/$listid") { &error(500, __LINE__, __FILE__, "Mailing list does not exist, <b>$listid</b>"); }
	
		## Delete entry from list
		$ok = &ezylist_delete_entry($user, $listid, $id);
		if ($ok != 1) { &error(500, __LINE__, __FILE__, "You are not currently subscribed to the mailing list"); }
	
		## Print off success template
		print &parse_template('unsubscribe.htmlt');
		exit(0);
	} else { &unsubscribe_cancel($id); }
}

sub unsubscribe_cancel {
	my ($id) = @_;

	## Create the HTML form
$form = qq#

<html>
<head>
	<title>Cancel Subscribe</title>
</head>

<body>
<font face="times new roman" size=4><b>Cancel!</b></font><br><br>
<font face="arial" size=2><b>
Did not unsubscribe entry <i>$id</i>.
<b></font><br><br>

</body>
</html>
#;

	$form .= "\n\n";

	&print_header;
	print $form;
	exit(0);
}

