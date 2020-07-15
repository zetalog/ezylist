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

$ADMIN=1;

## Load the required files
eval { require $conf; };
if ($@) { print "Content-type: text/html\n\nUnable to find required file, <b>ezylist.conf</b>, which should be located at, <b>$conf</b>"; exit; }
eval { require "$cgidir/lib/main-lib.pl"; };
if ($@) { print "Content-type: text/html\n\nUnable to find required file, <b>main-lib.pl</b>, which should be located at, <b>$cgidir/lib/main-lib.pl</b>"; exit; }
eval { require "$datadir/dat/styles.dat"; };
if ($@) { print "Content-type: text/html\n\nUnable to find required file, <b>styles.dat</b>, which should be located at, <b>$datadir/dat/styles.dat</b>"; exit; }
$style{'HEADER'} = &get_header;
$style{'FOOTER'} = &get_footer;
eval { require "$cgidir/lib/ezylist-lib.pl"; };
if ($@) { print "Content-type: text/html\n\nUnable to find required file, <b>ezylist-lib.pl</b>, which should be located at, <b>$cgidir/lib/ezylist-lib.pl</b>"; exit; }

## Make sure we're loogged in
&admin_checklogin;

## Print the HTML header
&print_header;

## Figure out what to do
if (!exists $query{'menu'}) {
	opendir DIR, "$datadir/messages" or &error(206, __LINE__, __FILE__, "$datadir/messages", "DIR");
	my @messages = grep /\.msg$/, readdir(DIR);
	closedir DIR;
	$in{'messages'} = @messages;

	opendir DIR, "$datadir/ad" or &error(206, __LINE__, __FILE__, "$datadir/ad", "DIR");
	my @ads = grep /\.ad$/, readdir(DIR);
	closedir DIR;
	$in{'advertisments'} = @ads;

	$in{'mail_sent'} = &counter_load("$datadir/ezylist.sent");
	$in{'mail_sent'} = 0 if (!defined $in{'mail_sent'});
	my ($date, $time) = &getdate;
	$in{'date'} = &format_date($date);
	$in{'time'} = $time;

	$in{'dbdriver'} = $dbdriver;
	$in{'mailtype'} = $mailtype;

	$in{'admin_name'} = $admin_name;
	$in{'VERSION'} = $VERSION;
	$in{'ad_member'} = counter_load("$datadir/$dbdriver.ads");
	$in{'ml_member'} = counter_load("$datadir/$dbdriver.mls");
	$in{'total_member'} = $in{'ml_member'} + $in{'ad_member'};
	print &parse_template('admin/index.htmlt');
} elsif (($query{'menu'}) && ($query{'action'} eq '')) {
	print &parse_template("admin/$query{'menu'}/index.htmlt"); }
elsif (($query{'menu'}) && ($query{'action'})) {
	my $reqfile;

	if ($MODULE eq 'main') { $reqfile = "$cgidir/admin/$query{'menu'}.pl"; }
	else { $reqfile = "$cgidir/modules/$MODULE/bin/admin/$query{'menu'}.pl"; }

	eval { require $reqfile; };
	if ($@) { print "Unable to find required file, <b>$reqfile</b>"; exit; }
	&{$SUB};
} else { &error(500, __LINE__, __FILE__, "Nothing to do"); }

exit(0);

################################################
## Log a user in
################################################

sub admin_login {
	my ($user, $pass, $salt, $encrypt, $cookie, $ref, @userinfo, @admin_info);
	
	## Get needed info
	$user = $in{'username'};
	$pass = $in{'password'};
	
	## Make sure user exists
	if (!-e "$datadir/admin/$user.admin") { &error(500, __LINE__, __FILE__, "Invalid Login"); }

	## Do a referrer check
	$ref = &referrer_check;
	if ($ref != 1) { &error(500, __LINE__, __FILE__, "Invalid Login"); }

	## Get user's info
	srand();
	@admin_info = &readfile("$datadir/admin/$user.admin");
	@userinfo = split /::/, $admin_info[0];
	($salt) = $userinfo[3] =~ /^(..)/;
	$encrypt = crypt($pass, $salt);
	
	if ($encrypt ne $userinfo[3]) { &error(500, __LINE__, __FILE__, "Invalid Login"); }
	
	## Login the user
	for ( 1 .. 5 ) { $cookie .= &create_salt; }
	print "Set-cookie: admin_user=$user; path=/\n";
	print "Set-cookie: rdtext=$cookie; path=/\n";
	
	&delete_fileline("$datadir/.random.admin", 'begin', "$user::");
	&appendfile("$datadir/.random.admin", (join "::", $user, $cookie));
	
	opendir DIR, "$datadir/messages" or &error(206, __LINE__, __FILE__, "$datadir/messages", "DIR");
	my @messages = grep /\.msg$/, readdir(DIR);
	closedir DIR;
	$in{'messages'} = @messages;

	opendir DIR, "$datadir/ad" or &error(206, __LINE__, __FILE__, "$datadir/ad", "DIR");
	my @ads = grep /\.ad$/, readdir(DIR);
	closedir DIR;
	$in{'advertisments'} = @ads;

	$in{'mail_sent'} = &counter_load("$datadir/ezylist.sent");
	$in{'mail_sent'} = 0 if (!defined $in{'mail_sent'});
	my ($date, $time) = &getdate;
	$in{'date'} = &format_date($date);
	$in{'time'} = $time;

	$in{'dbdriver'} = $dbdriver;
	$in{'mailtype'} = $mailtype;

	$in{'ad_member'} = counter_load("$datadir/$dbdriver.ads");
	$in{'ml_member'} = counter_load("$datadir/$dbdriver.mls");
	$in{'total_member'} = $in{'ml_member'} + $in{'ad_member'};

	## Print the main menu
	&print_header;
	$in{'admin_name'} = $admin_name;
	$in{'VERSION'} = $VERSION;
	print &parse_template('admin/index.htmlt');
	exit(0);
	
}

################################################
## Make sure we're logged in
################################################

sub admin_checklogin {
	my ($ok, $action, $offset, $user, $rdtext, $ref, @random, @admin_info, @navinfo, @actions, @navactions, @auth, %cookie);

	if ($in{'action'} eq 'check_pass') { &admin_login; }

	$ok=0;
	if ((exists $ENV{'REMOTE_USER'}) && ($moptions[2] == 1)) { $user = $ENV{'REMOTE_USER'}; $ok=1; }
	else { 
		## Get needed info
		%cookie = &read_cookie;
		$user = $cookie{'admin_user'};
		$rdtext = $cookie{'rdtext'};
	
		## Find user in .random.member file
		@random = &readfile("$datadir/.random.admin");
		foreach $line (@random) {
			next if $line eq '';
			my ($login, $text) = split /::/, $line;
			if (($login eq $user) && ($login ne '')) {
				$ok = 1 if $text eq $rdtext;
				last;
			}
		}
	}

	## Perform a couple of checks
	&print_header;
	if ($user eq '') { print &parse_template('admin/login.htmlt'); exit; }
	elsif ($ok != 1) { print &parse_template('admin/login.htmlt'); exit; }
	
	## Make sure admin is allowed to perform the function
	return $user if !exists $query{'action'};
	return $user if $MODULE ne 'main';
	$action = $query{'action'}; $action =~ s/\d+$//g;
	@admin_info = &readfile("$datadir/admin/$user.admin");
	@navinfo = &readfile("$datadir/dat/navmenu.dat");
	@actions = split /::/, $admin_info[1];
	
	$x=0; $ok=0;
	foreach $line (@navinfo) { 
		my ($name, $menu, @links) = split /::/, $line;
		if ($menu eq $query{'menu'}) {
			@navactions = @links;
			$offset = $x;
			$ok=1; last;
		}
	$x++; }

	if ($ok != 1) { &error(500, __LINE__, __FILE__, "You are not authorized to perform this function"); }

	$x=0; $ok=0; $found=0;
	@auth = split /,/, $actions[$offset];
	foreach (@navactions) {
		my ($name, $action) = split /,/, $_;
		if ($action eq $query{'action'}) {
			$found = 1;
			$ok = 1 if $auth[$x] == 1;
			last;
		}
	$x++; }
	return $user if $found != 1;
	if (($ok != 1) && ($found == 1)) { &error(500, __LINE__, __FILE__, "You are not authorized to perform this function"); }

	return $user;

}

################################################
## Get the HTML header
################################################

sub get_header {
	my ($html, $mainmenu_html, $submenu_html, $mod_html, @menus, @modinfo);

	## Get needed info
	$html = &parse_template("admin/header.htmlt");
	if ($MODULE eq 'main') { @menus = &readfile("$datadir/dat/navmenu.dat"); }
	else { @menus = &readfile("$cgidir/modules/$MODULE/dat/navmenu.dat"); }

	$mainmenu_html = qq!<table border='0' cellpadding='0' cellspacing='0' bgcolor='#798399'>
	<tr>!;
	foreach $menu (@menus) {
		next if $menu eq '';
		my ($name, $action, @options) = split /::/, $menu;
		$mainmenu_html .= qq!	<td><a href="~script_name~?module=$MODULE&menu=$action"><div id="menuMain">$name</div></a></td>
	<td><img src='~gif_url~/space.gif' height='40' width='6' border='0'></td>
!;

		if ($action eq $query{'menu'}) {
			$submenu_html = qq!<table border='0' bgcolor='#F0F0F0' cellpadding='0' cellspacing='0'>
	<tr><td><img src='~GIF_URL~/spacer.gif' height='6' width='160' border='0'></td></tr>
	<tr>!;

			$x=0;
			foreach $option (@options) {
				next if $option eq '';
				my ($oname, $oaction) = split /,/, $option;
				$submenu_html .= qq!<tr><td><a href="~script_name~?module=$MODULE&menu=$action&action=$oaction"><div id="menuSub">$oname</div></a></td></tr>
              <tr><td><img src='transparent.gif' height='6' width='160' border='0'></td></tr>
!;
			$x++; }
			$submenu_html .= qq!	</tr>
</table>!;
		}
	}
	$mainmenu_html .= qq!	</tr>
</table>
!;

	## Get module information
	$mod_html = "";
	@modinfo = &readfile("$datadir/dat/modules.dat");
	foreach $line (@modinfo) {
		next if $line eq '';
		my ($mod, $name, $ver) = split /::/, $line;
		$mod_html .= qq!<td><a href="~script_name~?module=$mod"><div id="menuMain">&nbsp;$name</div></a></td>
          <td><img src='~gif_url~/space.gif' height='40' width='6' border='0'></td>
!;
	}
	
	
	$html =~ s/~MAINMENU_OPTIONS~/$mainmenu_html/gi;
	$html =~ s/~SUBMENU_OPTIONS~/$submenu_html/gi;
	$html =~ s/~MODULE_OPTIONS~/$mod_html/gi;
	$html =~ s/~MODULE_TITLE~/$in{'MODULE_TITLE'}/gi;

	## Replace all merge fields with appropriate info
	while (($key,$value) = each %in) {
		$html =~ s/~$key~/$value/gi;
	}

	return $html;

}

################################################
## Get the HTML footer
################################################

sub get_footer {
	my ($html);

	## Get needed info
	$html = &parse_template("admin/footer.htmlt");
	## Replace all merge fields with appropriate info
	while (($key,$value) = each %in) {
		$html =~ s/~$key~/$value/gi;
	}

	return $html;

}

