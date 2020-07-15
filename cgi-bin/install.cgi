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

############################################################################
## IT IS ILLEGAL FOR YOU TO VIEW, EDIT, COPY, DELETE, 
## TRANSFER, OR IN ANY WAY MANIPULATE THE CODE BELOW 
## THIS LINE.
############################################################################

print "Content-type: text/html\n\n";
eval { require IO::Socket; };
if ($@) { print "Unable to find a required Perl module, <b>IO::Socket.pm</b>.  Please contact your server administrator"; exit; }
use Socket;

## If needed, parse the form
&parse_form;

if ($in{'action'} eq 'install') { &install_script; }
else { &print_install_form; }
exit(0);

################################################
## Print the form
################################################

sub print_form {
	print qq!
	<html><head><title>eZyList Pro v1.0 - Installation Program</title></head>
	<body><form action="install.cgi" method="POST"><br><center><font face="times new roman" size=5><b>eZyList Pro v1.0
	 - Installation Program</b></font><br><br><table border=1 cellspacing=1 cellpadding=2 width=70% align=center><tr>
	<th bgcolor="#6E68BD" colspan=2 nowrap><font face="verdana" size=3 color="#FFFFFF">Registration Check</font></th>
	</tr><tr><td width=100% colspan=2><font face="arial" size=2><blockquote>In order to proceed with the installation of this script, please enter the 
	registration number below, which you received from eZyScripts.Com.</blockquote></font></td>
	</tr><tr><td valing=top nowrap><font face="arial" size=2>Registration #: </font></td><td valign=top nowrap><input type="text" name="reg" size=30></td>
	</tr><tr><td valign=top align=center colspan=2 width=100%><font face="arial" size=2>
	<input type="submit" value="Continue"></font></td></tr></table></body></html>!;
}

################################################
## Check the registration
################################################

sub check_registration {
	my ($socket, $query, $response);

	## Create the query string
	$query = "reg=" . $in{'reg'} . "&server=" . $ENV{'SERVER_NAME'} . "&script=ezylist";
	$query =~ tr/ /+/;
	
	## Send request to server
	$socket = IO::Socket::INET->new(
		PeerAddr => "ezyscripts.com", 
		PeerPort => 80, 
		Proto => 'tcp'
	);
	if (!$socket) { &error("Unable to connect to registration server.  Please try again later"); }
	
	print $socket "GET /cgi-bin/system/regcheck.cgi?$query\n\n";
	$response = <$socket>; chomp $response;
	if ($response == 1) {
		close $socket;
		&print_install_form;
	} else {
		while (<$socket>) { print; }
		close $socket;
		exit;
	}	
	
}

################################################
## Print the installation form
################################################

sub print_install_form {
	my ($x, $docroot, $datadir, $cgidir, $ref1, $ref2, $ref3, $html, $cmdhtml, $ok, @commands);

	## Figure out the paths
	if (exists $ENV{'DOCUMENT_ROOT'}) {
		$docroot = $ENV{'DOCUMENT_ROOT'};
		($datadir) = $docroot =~ /^(.*)\/.+$/;
		$datadir .= "/ezylist_data";
		$cgidir = "$docroot/cgi-bin/ezylist";
	} else {
		$docroot = "/home/mysite/html";
		$datadir = "/home/mysite/ezylist_data";
		$cgidir = "/home/mysite/html/cgi-bin/ezylist";
	}
	
	## Figure out the server name
	if (exists $ENV{'SERVER_NAME'}) {
		if ($ENV{'SERVER_NAME'} =~ /^www\./) {
			$ref2 = $ENV{'SERVER_NAME'};
			($ref1) = $ref2 =~ /^www\.(.+)/;
		} else {
			$ref1 = $ENV{'SERVER_NAME'};
			$ref2 = "www." . $ref1;
		}
		
		my $host = inet_aton($ref1);
		if ($host) { $ref3 = inet_ntoa($host); }
		else { $ref3 = "209.163.234.224"; }
	} else { 
		$ref1 = "mysite.com";
		$ref2 = "www.mysite.com";
		$ref3 = "209.163.234.224";
	}
	
	## Try to find the server commands

	## Find the gzip command 
	$x=0; $ok=0;
	@commands = qw (mkdir rmdir tar gzip);
	foreach $cmd (@commands) {
		if (-e "/bin/$cmd") { $cmdhtml .= qq!<input type="hidden" name="cmds$x" value="/bin/$cmd">!; }
		elsif (-e "/usr/bin/$cmd") { $cmdhtml .= qq!<input type="hidden" name="cmds$x" value="/usr/bin/$cmd">!; }
		elsif (-e "/usr/local/bin/$cmd") { $cmdhtml .= qq!<input type="hidden" name="cmds$x" value="/usr/local/bin/$cmd">!; }
		elsif (-e "/usr/local/$cmd") { $cmdhtml .= qq!<input type="hidden" name="cmds$x" value="/usr/local/$cmd">!; }
		else { $ok=1;
			$cmdhtml .= qq!
			<tr><td valing=top><font face="arial" size=2>Location of <b>$cmd</b>: </font></td>
			<td valign=top><input type="text" name="cmds$x" size=40 value="/bin/$cmd"></td></tr>!;
		}
	$x++; }

	## Print the HTML form
	$html = qq!
	<html><head><title>eZyList Pro v1.0 - Installation Program</title></head><body><form action="install.cgi" method="POST">
	<br><center><font face="times new roman" size=5><b>eZyList Pro v1.0 - Installation Program</b></font></center><br><blockquote><font face="arial" size=2>
	Welcome to the installation program for the eZyList Pro v1.0, created by <a href="http://www.ezyscripts.com/">eZyScripts.Com</a>.  To continue with the installation, 
	please complete the following form.</blockquote></font><table border=1 cellspacing=1 cellpadding=2 width=90% align=center><input type="hidden" name="action" value="install">!;
	
	if ($ok == 1) {
		$html .= qq!<tr><th bgcolor="#6E68BD" colspan=2><font face="verdana" size=3 color="#FFFFFF">Server Functions</font></th></tr>
					<td width=100% colspan=2><font face="arial" size=2><blockquote>
					The following four questions ask for the location, on your server, to 
					four different server functions.  If you do not know the locations, please 
					contact your server administrator and ask.</blockquote></font></td></tr>!;
	}
	$html .= $cmdhtml;
	
	$html .= qq!
	<th bgcolor="#6E68BD" colspan=2><font face="verdana" size=3 color="#FFFFFF">Administrator Information</font></th></tr><tr><td width=100% colspan=2><font face="arial" size=2><blockquote>
	This section asks for the information of the administrator of your program.  The name and e-mail address you enter will be used in the <b>From:</b> line of all e-mail messages sent out.  The username and password 
	you enter will be used to access the Admin Control Panel.</blockquote></font></td></tr><tr>
	<td valing=top><font face="arial" size=2>Administrator Name: </font></td><td valign=top><input type="text" name="admin_name" size=40></td></tr><tr>
	<td valing=top><font face="arial" size=2>Administrator E-Mail Address: </font></td><td valign=top><input type="text" name="admin_email" size=40></td></tr><tr>
	<td valing=top><font face="arial" size=2>Administrator Password (Leave blank if no SMTP AUTH): </font></td><td valign=top><input type="password" name="smtp_pass" size=40></td></tr><tr>
	<td valing=top><font face="arial" size=2>Username: </font></td><td valign=top><input type="text" name="admin_username" size=40></td></tr><tr>
	<td valing=top><font face="arial" size=2>Password: </font></td><td valign=top><input type="password" name="admin_pass" size=40></td></tr><tr>
	<td valing=top><font face="arial" size=2>Confirm Password: </font></td><td valign=top><input type="password" name="admin_pass2" size=40></td></tr><tr>
	<th bgcolor="#6E68BD" colspan=2><font face="verdana" size=3 color="#FFFFFF">Referrers</font></th></tr><tr><td width=100% colspan=2><font face="arial" size=2><blockquote>
	In the next three fields, please enter the three referrers of your domain name. This is to ensure the security of the eZyList Pro v1.0, and your member database. You need all three referrers, your domain name, your domain
	name with www. at the beginning, and the IP address of your domain name.</blockquote></font></td></tr><tr>
	<td valing=top><font face="arial" size=2>Referrer 1:</font></td><td valign=top><input type="text" name="ref1" size=40 value="$ref1"></td></tr><tr>
	<td valing=top><font face="arial" size=2>Referrer 2:</font></td><td valign=top><input type="text" name="ref2" size=40 value="$ref2"></td></tr><tr>
	<td valing=top><font face="arial" size=2>Referrer 3:</font></td><td valign=top><input type="text" name="ref3" size=40 value="$ref3"></td></tr><tr>
	<th bgcolor="#6E68BD" colspan=2><font face="verdana" size=3 color="#FFFFFF">Path Information</font></th></tr><tr><td width=100% colspan=2><font face="arial" size=2><blockquote>
	The following fields ask for the full path to several different directories on your web server. The script has tried to determine the paths for you, but they may be wrong, so please check and make sure. If you do not how to find the
	full path of a certain directory on your web server, follow these few steps: <br><blockquote><ol>
	<li>Telnet into your account. If you do not know how, please consult the telnet tutorial in the manual. <li>Change directories to the directory which you want to find the full path of, by typing, cd DIRNAME. 
	<li>At the prompt, type <b>pwd</b></ol></blockquote><br>By typing <b>pwd</b> at the prompt, the full path of the directory you are currently in will be displayed. 	</blockquote></font></td>
	</blockquote></font></td></tr><tr><td valing=top><font face="arial" size=2>Full path to the <b>ezylist_data</b> directory on your server:</font></td>
	<td valign=top><input type="text" name="datadir" size=40 value="$datadir"></td></tr><tr><td valing=top><font face="arial" size=2>Full path to the <b>cgi-bin</b> directory, which contains all CGI scripts for the EZYLIST:</font></td>
	<td valign=top><input type="text" name="cgidir" size=40 value="$cgidir"></td>
	</tr><tr><th bgcolor="#6E68BD" colspan=2><font face="verdana" size=3 color="#FFFFFF">URL Information</font></th></tr><tr>
	<td width=100% colspan=2><font face="arial" size=2><blockquote>The following fields ask for the URL to several different directories on your server.</blockquote></font></td></tr><tr>
	<td valing=top><font face="arial" size=2>URL to the <b>cgi-bin</b> directory, which contains all of the CGI scripts for the EZYLIST:</font></td><td valign=top><input type="text" name="cgiurl" size=40 value="http://$ref2/cgi-bin/ezylist"></td></tr><tr>
	<tr><td valing=top><font face="arial" size=2>URL to the <b>images</b> directory on your server, which contains all of the images for the EZYLIST:</font></td><td valign=top><input type="text" name="gifurl" size=40 value="http://$ref2/images/ezylist"></td></tr></table><br><center>
	<font face="arial" size=2><input type="submit" value="Install the eZyList Pro v1.0"><input type="reset" value="Reset Form"></font><br><br></form></body></html>!;
	
	print $html;
	exit(0);
}

################################################
## Install the script
################################################

sub install_script {
	my ($x, $datadir, $cgidir, $chmod_message, $cmds, $refs, @cmds, @commands, @refs, @files);
	
	## Format a few variables
	$in{'datadir'} =~ s/\/$//;
	$in{'cgidir'} =~ s/\/$//;
	$in{'cgiurl'} =~ s/\/$//;
	$in{'gifurl'} =~ s/\/$//;
	$in{'ref1'} =~ s/\/$//;
	$in{'ref2'} =~ s/\/$//;
	$in{'ref3'} =~ s/\/$//;
	
	## Set a few variables
	$datadir = $in{'datadir'};
	$cgidir = $in{'cgidir'};
	@commands = qw (mkdir rmdir tar gzip);
	@cmds = ($in{'cmds0'}, $in{'cmds1'}, $in{'cmds2'}, $in{'cmds3'});
	@refs = ($in{'ref1'}, $in{'ref2'}, $in{'ref3'});
	$cmds = join " ", @cmds;
	$refs = join " ", @refs;

	## Make sure all cmds exist
	$x=0;
	foreach $cmd (@cmds) {
		if (!-e $cmd) { &error("Location of the server command, <b>$command[$x]</b>, does not exist at, <b>$cmds[$x]</b>"); }
	$x++; }
	
	## Make sure directories exist, and are correct
	if (!-e $datadir) { &error("The <b>ezylist_data</b> directory you specifed does not exist at, <b>$datadir</b>"); }
	elsif (!-e $cgidir) { &error("The <b>cgi-bin</b> directory you specifed does not exist at, <b>$cgidir</b>"); }
	elsif (!-e "$datadir/ezylist.conf") { &error("The <b>ezylist_data</b> directory you specifed is invalid at, <b>$datadir</b>"); }
	elsif (!-e "$cgidir/admin/admin.cgi") { &error("The <b>cgi-bin</b> directory you specified is invalid at, <b>$cgidir</b>"); }
	elsif ($in{'cgiurl'} !~ /^http:\/\//) { &error("The <b>cgi-bin</b> URL you specified is not a valid URL, <b>$in{'cgiurl'}</b>"); }
	elsif ($in{'gifurl'} !~ /^http:\/\//) { &error("The <b>images</b> URL you specified is not a valid URL, <b>$in{'gifurl'}</b>"); }
	elsif ($in{'admin_email'} !~ /.*\@.*\..*/) { &error("Invalid e-mail address, <i>$in{'admin_email'}</i>"); }
	elsif ($in{'admin_username'} eq '') { &error("Admin username not specified"); }
	elsif ($in{'admin_username'} =~ /[\s\W]/) { &error("Admin username contains spaces or special characters, <i>$in{'admin_username'}</i>"); }
	elsif ($in{'admin_pass'} ne $in{'admin_pass2'}) { &error("Admin passwords do not match"); }
	
	## Create the wsr_data directory
	&makedir("$datadir/admin");
	&makedir("$datadir/ar");
	&makedir("$datadir/ad");
	&makedir("$datadir/arlog");
	&makedir("$datadir/backup");
	&makedir("$datadir/cgi");
	&makedir("$datadir/conf");
	&makedir("$datadir/list");
	&makedir("$datadir/messages");
	&makedir("$datadir/template");
	&makedir("$datadir/tmp");

	open FILE, ">$datadir/template/template.conf" or &error("Unable to create file, <b>$datadir/template/template.conf</b>");
	print FILE "\n[EZYLIST_ARNUM]\n0\n\n[EZYLIST_LISTNUM]\n0\n\n[EZYLIST_MSGNUM]\n0\n\n[EZYLIST_CYCLENUM]\n0\n\n[EZYLIST_MAXSCH]\n0\n\n[EZYLIST_MAXNUM]\n0\n\n[EZYLIST_AUTORESPONDER]\n\n[END]\n\n";
	close FILE;
	chmod 0777, "$datadir/template/template.conf";
	
	open FILE, ">$datadir/.htaccess";
	print FILE "<Limit GET>\norder deny,allow\ndeny from all\n</Limit>\n\n";
	close FILE;
	
	open FILE, ">$datadir/.random.admin" or &error("Unable to create file, <b>$datadir/.random.admin");
	print FILE "\n"; close FILE;
	chmod 0777, "$datadir/.random.admin";
	
	## Replace ~datadir~ in needed files
	@files = ("$cgidir/error.cgi", "$cgidir/newuser.cgi", "$cgidir/followup.pl", "$cgidir/process.pl", "$cgidir/reminder.cgi", "$cgidir/subscribe.cgi", "$cgidir/unsubscribe.cgi", "$cgidir/advertise.cgi", "$cgidir/update.pl", 
			  "$cgidir/admin/admin.cgi", "$cgidir/cpanel/index.cgi");
	foreach $file (@files) {
		my ($contents, $success);
		
		open FILE, "$file" or &error("Unable to open file, <b>$file</b>");
		while (<FILE>) { $contents .= $_; }
		close FILE;
		
		$contents =~ s/~datadir~/$datadir/g;
		
		open FILE, ">$file" or &error("Unable to write to file, <b>$file</b>");
		print FILE $contents; close FILE;
		$success = chmod 0755, $file;
		if ($success == 0) { $chmod_message .= "<li>You must CHMOD the <i>$file</i> script to 755\n"; }
	}
	if ($chmod_message ne '') { $chmod_message = "<br><br>In order for the Web Site Replicator to work properly, you must first do the following:<br>\n<ul>$chmod_message\n</ul>\n"; }
	
	## Create the ezylist.cron file
	open FILE, ">$datadir/ezylist.cron" or &error("Unable to write to file, <b>$datadir/ezylist_data/ezylist.cron</b>");
	print FILE "1 0 * * * $cgidir/followup.pl\n";
	close FILE;
	
	## Create needed e-mail messages
	open FILE, ">$datadir/messages/signup_admin.msg" or &error("Unable to write to file, <b>$datadir/messages/signup_admin.msg");
	print FILE "Admin's Signup Notification\nSubject: Signup Notification For ~date~\nContent-type: text/plain\n\n\n";
	print FILE "Hello there,\n\nBelow is a signup notification for ~date~.\n\n\tAdded Account: ~username~\n\tAdded Member: ~name~\n\tAdded Email: ~email~\n\tAccount Type: ~type~\n\n\t";
	print FILE "Autoresponders Allowed: ~_add_autonum~\n\tMailing Lists Allowed: ~_add_listnum~\n\tFollowup Messages Allowed: ~_add_msgnum~\n\tFollowup Cycles Allowed: ~_add_cyclenum~\n\t";
	print FILE "Scheduled Mailings Allowed: ~_add_maxsch~\n\tMaximum Messages One Day: ~_add_maxmsg~\n\nThank you,\neZyList Pro v1.0\n\n";
	close FILE;
	
	open FILE, ">$datadir/messages/signup_member.msg" or &error("Unable to write to file, <b>$datadir/messages/signup_member.msg");
	print FILE "Member's Signup Notification\nSubject: Signup Notification For ~date~\nContent-type: text/plain\n\n\n";
	print FILE "Hello there,\n\nBelow is a signup notification for ~date~.\n\n\tAdded Account: ~username~\n\tAdded Member: ~name~\n\tAdded Email: ~email~\n\tAccount Type: ~type~\n\n\t";
	print FILE "Autoresponders Allowed: ~_add_autonum~\n\tMailing Lists Allowed: ~_add_listnum~\n\tFollowup Messages Allowed: ~_add_msgnum~\n\tFollowup Cycles Allowed: ~_add_cyclenum~\n\t";
	print FILE "Scheduled Mailings Allowed: ~_add_maxsch~\n\tMaximum Messages One Day: ~_add_maxmsg~\n\nThank you,\neZyList Pro v1.0\n\n";
	close FILE;

	open FILE, ">$datadir/messages/followup_user.msg" or &error("Unable to write to file, <b>$datadir/messages/followup_user.msg");
	print FILE "Member's Follow Up Summary\nSubject: Your Follow Up Summary\nContent-type: text/plain\n\n\n";
	print FILE "Hello there,\n\nFollow ups have now been completed on your account for today, ~date~.  Below is a summary of all follow ups performed on your account:\n\n\t~followup_summary~\n\n";
	print FILE "Below is a summary of all scheduled mailings which were sent out today, ~date~.\n\n\t~schedule_summary~\n\n";
	print FILE "If you have any questions or concerns, please feel free to contact customer support.\n\nThank you,\nCustomer Support\n\n";
	close FILE;
	
	open FILE, ">$datadir/messages/password_reminder.msg" or &error("Unable to write to file, <b>$datadir/messages/password_reminder.msg</b>");
	print FILE "Password Reminder Message\nSubject: Your Password\nContent-type: text/plain\n\n\n";
	print FILE "Hello there,\n\nBelow is your username and password which you asked to have e-mailed to you:\n\n";
	print FILE "\tUsername: ~username~\n\tPassword: ~password~\n\nThank you,\nCustomer Support\n\n";
	close FILE;
	
	## Create the administrator
	$admin_info = join "::", $in{'admin_username'}, $in{'admin_name'}, $in{'admin_email'}, &encrypt($in{'admin_pass'});
	open ADMIN, ">$datadir/admin/$in{'admin_username'}.admin" or &error("Unable to create file, <b>$datadir/admin/$in{'admin_username'}.admin</b>");
	print ADMIN "$admin_info\n";
	print ADMIN "1,1,1,1,1,1::1,1,1,1,1,1,1::1,1,1,1,1::1,1,1,1,1::1,1,1,1,1,1::1,1,1,1\n";
	close ADMIN;
	chmod 0777, "$datadir/admin/$in{'admin_username'}.admin";
	
	## Create the ezylist.conf file
	$in{'admin_email'} =~ s/\@/\\\@/;
	open CONF, ">$datadir/ezylist.conf" or &error("Unable to create file, <b>$datadir/ezylist.conf</b>");
	print CONF "\$admin_name \= \"$in{'admin_name'}\"\;\n";
	print CONF "\$admin_email \= \"$in{'admin_email'}\"\;\n";
	print CONF "\$dump_email \= \"\"\;\n";
	print CONF "\$support_email \= \"\"\;\n";	
	print CONF "\@cmds \= qw ($cmds)\;\n";
	print CONF "\@refs \= qw ($refs)\;\n";
	print CONF "\$datadir \= \"$datadir\"\;\n";
	print CONF "\$cgidir \= \"$cgidir\"\;\n";
	print CONF "\$cgiurl \= \"$in{'cgiurl'}\"\;\n";
	print CONF "\$in{'gif_url'} \= \"$in{'gifurl'}\"\;\n";
	print CONF "\@userfields \= qw ( )\;\n";
	print CONF "\@edit_fields \= qw ( )\;\n";
	print CONF "\@send_confirm \= qw ( )\;\n";
	print CONF "\@moptions \= qw ( )\;\n";
	print CONF "\@dbfields \= qw ( )\;\n";
	print CONF "\@default \= qw ( )\;\n";
	print CONF "\$mailtype \= \"dns\"\;\n";
	print CONF "\$mailprog \= \"\"\;\n";
	print CONF "\@auto_options \= qw ( )\;\n";
	print CONF "\$extfield \= 0\;\n";
	print CONF "\$dbdriver \= \"cgi\"\;\n";
	print CONF "\$dbname \= \"ezylist\"\;\n";
	print CONF "\$dbhost \= \"localhost\"\;\n";
	print CONF "\$dbuser \= \"root\"\;\n";
	print CONF "\$dbpassword \= \"\"\;\n";
	print CONF "\$admin_pass \= \"$in{'smtp_pass'}\"\;\n";
	print CONF "1\;\n\n";
	close CONF;
	chmod 0777, "$datadir/ezylist.conf";

	&writefile("$datadir/cgi.mls", 0);
	&writefile("$datadir/cgi.ads", 0);
	&writefile("$datadir/ezylist.sent", 0);
	
	## Print the HTML success page
	print qq!
	<html><head>
		<title>Successfully Installed the eZyList Pro v1.0</title>
	</head>

	<body>
	<center>
	<font face="verdana" size=4 color="#CC0000"><b>eZyList Pro v1.0</b></font><br>
	<font face="verdana" size=2 color="#000000"><b>Created by: 
	<a href="http://www.ezyscripts.com/">eZyScripts.Com</a></b></font>
	</center><br>
	
	<blockquote><font face="arial" size=2>
	The eZyList Pro v1.0 has been successfully installed on your server.  To continue, you need to run First Time Setup 
	from the Admin Control Panel.  To do this, please goto the Admin Control Panel at:

	$chmod_message
	</font></blockquote><br>
	
	<center><b><a href="$in{'cgiurl'}/admin/admin.cgi">$in{'cgiurl'}/admin/admin.cgi</a><br><br>
	Username = $in{'admin_username'}<br>
	Password = $in{'admin_pass'}<br>
	</b></center><br><br>
	
	</body>
	</html>!;

}

################################################
## Give off an error
################################################

sub error {
	my $error = shift;

	print qq!
	<html><head><title>ERROR</title></head><body><font face="times new roman" size=6><b>Error</b></font><br>
	<font face="times new roman" size=3><b>$error</b></font><br><br></body></html>!;
	
	exit(0);
}

################################################
## Parse form
################################################

sub parse_form {

	## If needed, parse the form
	if ($ENV{'CONTENT_LENGTH'} > 0) {

		$PARSE = 1;
		read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
		my @pairs = split(/&/, $buffer);

		foreach $pair (@pairs) {
			my ($name, $value) = split(/=/, $pair);
			$value =~ tr/+/ /;
			$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
			if ($in{$name}) { $in{$name} .= "\0".$value; }
			else { $in{$name} = $value; }
		}
	}
	
	return;
}

################################################
## Make a new directory
################################################

sub makedir {
	my $dir = shift;

	my $success = mkdir ($dir, 0777);
	unless (-d $dir) {
		if ($success == 0) {
			if ($^O =~ /Win/) { $dir =~ s/\//\\/g; }
	
			open MKDIR, "|$cmds[0] $dir" or &error("Unable to create directory, <b>$dir</b>");
			print MKDIR $dir;
			close MKDIR;
		}	
	}

	chmod 0777, $dir;
	if (!-d $dir) { &error("Unable to create directory, <b>$dir</b>"); }

	return;
}

################################################
## Enccypt a password
################################################

sub encrypt {
	my $password = shift;
	my ($salt, $encrypt);
	
	srand();
	$salt = &create_salt;
	$encrypt = crypt($password, $salt);
	
	return $encrypt;
}

################################################
## Create a random salt for crypt() function
################################################

sub create_salt {
	my ($salt, $var, @chars);
	
	@chars = qw (a b c d e f g h i j k l m n o p q r s t 
				 u v w x y z A B C D E F G H I J K L M N 
				 O P Q R S T U V Y X Y Z);
				 
	do {
		$var = rand 52;
		$var =~ s/\..+$//;
	
		$salt = $chars[$var];
	
		$var = rand 52;
		$var =~ s/\..+$//;
		$salt .= $chars[$var];
		
		redo if length($salt) != 2;
	};
	
	return $salt;
}

################################################
## Rewrite a file
################################################

sub writefile {
	my ($file, @contents) = @_;
	
	open FILE, ">$file" or &error(203, __LINE__, __FILE__, $file, "FILE");
	&lockfile('FILE');
	foreach (@contents) { print FILE "$_\n"; }
	&unlockfile('FILE');
	close FILE;
	
	chmod 0777, $file;	
	return;

}

################################################
## Lock a file
################################################

sub lockfile {
	my $handle = shift;

	my $success = flock 2, $handle if $FLOCK == 1;
	return $success;
}

################################################
## Unlock a file
################################################

sub unlockfile {
	my $handle = shift;

	my $success = flock 8, $handle if $FLOCK == 1;
	return $success;
}

