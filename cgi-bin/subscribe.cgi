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
if ($PARSE == 1) { &subscribe; }
else { &subscribe_preview; }

## Exit program
exit(0);


################################################
## Preview subscribe informations
################################################

sub subscribe_preview {
	## Get needed info
	$user = $query{'user'};
	if ($user eq '') { &error(500, __LINE__, __FILE__, "You did not select a mailer"); }
	$listid = $query{'listid'};
	if ($listid eq '') { &error(500, __LINE__, __FILE__, "You did not select a mailing list"); }
	%info = &ezylist_get_listinfo($user);
	
	## Create the HTML form
$form = qq!

<form action="$cgiurl/subscribe.cgi" method="POST">
<input type="hidden" name="username" value="$user">
<input type="hidden" name="listid" value="$listid">
<font face="arial" size=2>
<center>
<br><br>
<big><b>Subscribe Entry of Mailing List</b></big>
<br><br>
Username: $user
<br>
Listname: $listid
<br><br>
</center>
<hr width=90%>
<center>
<br>
!;

	## Add list fields to form
	splice @{$info{$listid}{'fields'}}, 0, 4;
	foreach $field (@{$info{$listid}{'fields'}}) {
		my $hfield = ucfirst($field);
		$form .= qq!$hfield: <input type="text" name="$field" size=25><br>\n\n!;
	}
	$form .= qq!
<br>
</center>
<hr width=90%>
<center>
<br>
<input type="submit" value="Subscribe">
</center>
!;
	$form .= "</font></form>\n\n";

	&print_header;
	print $form;
	exit(0);
}

################################################
## Subscribe new entry
################################################

sub subscribe {

	## Make sure user and list ID exist
	my ($user, $listid) = ($in{'username'}, $in{'listid'});
	my ($status , $type) = &get_ext($user);
	if (!defined $status || !defined $type) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	elsif (!-e "$datadir/list/$user/$listid") { &error(500, __LINE__, __FILE__, "Mailing list does not exist, <b>$listid</b>"); }
	
	## Setup %in hash appropriatley
	foreach $key (keys %in) {
		$in{"add_$key"} = $in{$key};
	}
	
	## Add the entry
	@entry = &ezylist_addentry($user, $listid);
	
	## Print HTML template
	if (exists $in{'_redirect'}) {
		print qq~
		<html><head>
		<script language="javascript">
			window.document.location = "$in{'_redirect'}";
		</script>
		</head></html>~;
	} else { print &parse_template('subscribe.htmlt', 'main'); }

}

################################################
## Unsubsribe entry from list
################################################

sub unsubscribe {
	my ($user, $listid, $status, $type, $id, $ok);
	
	## Get needed info
	($user, $listid, $id) = ($query{'user'}, $query{'listid'}, $query{'id'});
	($status , $type) = &get_ext($user);
	if (!defined $status || !defined $type) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	elsif (!-e "$datadir/list/$user/$listid") { &error(500, __LINE__, __FILE__, "Mailing list does not exist, <b>$listid</b>"); }
	
	## Delete entry from list
	$ok = &ezylist_delete_entry($user, $listid, $id);
	if ($ok != 1) { &error(500, __LINE__, __FILE__, "You are not currently subscribed to the mailing list"); }
	
	## Print off success template
	print &parse_template('unsubscribe.htmlt');

}


