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
if ($@) { print "Unable to find required file, <b>ezylist.conf</b>"; exit; }

################################################
## Handle the error
################################################

$html = qq!
<html><head><title>Mail Error</title></head><body>
<center><font face="times new roman" size=5><b>Mail Error</b></font><br>
<hr width=90%></center><br><font face="arial" size=2>The script was unable 
to send an e-mail message to all intended recipients.  The below table shows 
which e-mail addresses the script was unable to send e-mail to, and why.
</font><br><br><table border=1 cellspacing=0 cellpadding=2 width=90% align=center>
<tr><th width=100% colspan=4 bgcolor="#008000"><font face="Times New Roman" size=3 color="#FFFFFF">Mail Error</font></th>
</tr><tr><th nowrap bgcolor="#000000"><font face="arial" size=2><font color="#FFFFFF">Error Code</font></th>	
<th nowrap bgcolor="#000000"><font face="arial" size=2><font color="#FFFFFF">E-Mail Address</font></th><th nowrap bgcolor="#000000"><font face="arial" size=2><font color="#FFFFFF">Reason</font></th>
</tr>!;

open FILE, "$datadir/tmp/error.tmp";
while (<FILE>) {
	my ($code, $addr, $server) = split /::/, $_;
	my $reason;
	
	if ($code == 600) { $reason = "Invalid e-mail address"; }
	elsif ($code == 601) { $reason = "Unable to connect to SMTP server, <b>$server</b>"; }
	elsif ($code == 602) { $reason = "Did not appear to be an SMTP server, <b>$server</b>"; }
	elsif ($code == 603) { $reason = "Unable to greet SMTP server, <b>$server</b>"; }
	elsif ($code == 604) { $reason = "Sender address was rejected by SMTP server, <b>$server</b>"; }
	elsif ($code == 605) { $reason = "Recipient address was rejected by SMTP server, <b>$server</b>"; }
	elsif ($code == 606) { $reason = "Unable to send message body to SMTP server, <b>$server</b>"; }
	elsif ($code == 607) { $reason = "Message was not accepted by SMTP server, <b>$server</b>"; }
	elsif ($code == 608) { $reason = "Unable to find SMTP server to send message to for domain, <b>$domain</b>"; }
	
	$html .= qq!
	<tr><th nowrap><font face="arial" size=2>$code</font></th>
	<td nowrap><font face="arial" size=2><a href="mailto:$addr">$addr</a></font></td>
	<td nowrap><font face="arial" size=2>$reason</font></td></tr>!;
}
close FILE;

$html .= qq!</table></body></html>!;
unlink "$datadir/tmp/error.tmp";
print $html;
exit(0);

