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

%cpanel_menu_mailer = (
	'setup' => 'Setup', 
	'lists' => 'Mailing Lists', 
	'followup' => 'Follow Ups', 
	'ar' => 'Auto Responders'
);

%cpanel_menu_advertiser = (
	'setup' => 'Setup', 
	'ad' => 'Advertisement'
);

## Make sure we're loogged in
($user, @userinfo) = &member_checklogin;
$in{'username'} = $user;
($in{'status'}, $in{'type'}) = &get_ext($user);
if (!$in{'status'} || !$in{'type'} ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }

## Get html styles, and header
%style = &cpanel_get_styles;
$style{'HEADER'} = &get_header;
$style{'FOOTER'} = &get_footer;

$CPANEL = 1;

## Require ezylist-lib.pl file
eval { require "$cgidir/lib/ezylist-lib.pl"; };
if ($@) { print "Content-type: text/html\n\nUnable to find required file, <b>ezylist-lib.pl</b>, which should be located at, <b>$cgidir/lib/ezylist-lib.pl</b>"; exit; }

## Print the HTML header
&print_header;

## Figure out what to do
if (!exists $query{'menu'}) {
	$in{'name'} = $userinfo[$dbfields[0]];
	$in{'VERSION'} = $VERSION;
	print &parse_template('cpanel/index.htmlt');
} elsif (($query{'menu'}) && ($query{'action'} eq '')) {
	print &parse_template("cpanel/$query{'menu'}/index.htmlt"); }
elsif (($query{'menu'}) && ($query{'action'})) {
	my $reqfile;

	if ($MODULE eq 'main') { $reqfile = "$cgidir/cpanel/$query{'menu'}.pl"; }
	else { $reqfile = "$cgidir/modules/$MODULE/bin/admin/$query{'menu'}.pl"; }

	eval { require $reqfile; };
	if ($@) { print "Unable to find required file, <b>$reqfile</b>"; exit; }
	&{$SUB};
} else { &error(500, __LINE__, __FILE__, "Nothing to do"); }

exit(0);

################################################
## Check to make sure user is logged in
################################################

sub member_checklogin {
	my ($ok, $ref, $user, $rdtext, $user2, $rdtext2, $ext, $DBSUB, @tmpinfo, @userinfo, %cookie);
	
	if ($in{'action'} eq 'check_pass') { &member_login; }
	if ((exists $ENV{'REMOTE_USER'}) && ($moptions[3] == 1)) { 
		my $ext = &get_ext($ENV{'REMOTE_USER'});
		if ($ext eq '.pl') { &error(500, __LINE__, __FILE__, "This account has been deactivated.  Please contact the administrator"); }
		return $ENV{'REMOTE_USER'};
	}
	
	## Get needed info
	%cookie = &read_cookie;
	$user = $cookie{'user'};
	$rdtext = $cookie{'rdtext'};
	
	## Perform a few checks
	if ($user eq '') { &print_header; print &parse_template('cpanel/login.htmlt', 'main'); exit(0); }
	elsif (!-e "$datadir/tmp/cpanel-$user.tmp") { &print_header; print &parse_template('cpanel/login.htmlt', 'main'); exit(0); }

	## Get info from tmp file
	@tmpinfo = &readfile("$datadir/tmp/cpanel-$user.tmp");
	($user2, $rdtext2) = (@tmpinfo);

	## Check login info
	$ok=0;
	if ($user eq $user2) { $ok = 1 if $rdtext eq $rdtext2; }

	## Perform a couple of checks
	if (!$rdtext) { &print_header; print &parse_template('cpanel/login.htmlt', 'main'); exit(0); }
	elsif ($ok != 1) { &print_header; print &parse_template('cpanel/login.htmlt', 'main'); exit(0); }
	
	## Get user's information
	$ext = &get_ext($user);
	$DBSUB = $dbdriver . "_fetch_account";
	@userinfo = &$DBSUB($user, $ext);
	
	return ($user, @userinfo);

}

################################################
## Login a user
################################################

sub member_login {
	my ($user, $pass, $encrypt, $ok, $ref, $ext, $type, $status, $user2, $pass2, $class, $userip, $cookie, $DBSUB, @info);
	
	## Set some variables
	($user, $pass, $encrypt) = ($in{'username'}, $in{'password'}, $moptions[1]);
	
	## Make sure user exists
	$ext = &get_ext($user);
	if (!$ext) { &error(500, __LINE__, __FILE__, "Invalid username or password"); }
	elsif ($ext eq '.pl') { &error(500, __LINE__, __FILE__, "This account has been deactivated.  Please contact the administrator"); }
	
	## Make sure request is coming from this server
	$ref = &referrer_check;
	if ($ref != 1) { &error(500, __LINE__, __FILE__, "Invalid referrer"); }

	## Get the user's information
	$DBSUB = $dbdriver . "_fetch_account";
	@userinfo = &$DBSUB($user, $ext);
	$user2 = $userinfo[0];
	$pass2 = $userinfo[$dbfields[2]];
	$class = $userinfo[$dbfields[3]];
	$userip = $ENV{'REMOTE_ADDR'};
	
	if ($class eq 'advertiser') {  &error(500, __LINE__, __FILE__, "Invalid user $user"); }
	## Check the login info
	$ok=0;
	if ($encrypt == 1) {
		my ($salt) = $pass2 =~ /^(..)/;
		my $encrypt_pass = crypt($pass, $salt);
		$ok = 1 if $pass2 eq $encrypt_pass;
	} else {
		$ok = 1 if $pass2 eq $pass;
	}

	if ($ok != 1) { &error(500, __LINE__, __FILE__, "Invalid username or password"); }
	
	## Login the new user
	for ( 1 .. 5 ) { $cookie .= &create_salt; }	
	print "Set-cookie: user=$user; path=/\n";
	print "Set-cookie: rdtext=$cookie; path=/\n";
	
	## Write tmp file for user
	&writefile("$datadir/tmp/cpanel-$user.tmp", $user, $cookie);
	
	## Put user's info into %in hash
	$x=0;
	foreach (@userfields) { $in{$_} = $userinfo[$x]; $x++; }
	$in{'name'} = $userinfo[$dbfields[0]];
	
	($in{'status'}, $in{'type'}) = &get_ext($user);
	if (!$in{'status'} || !$in{'type'} ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }

	## Print HTML template
	%style = &cpanel_get_styles;
	$style{'HEADER'} = &get_header;
	$style{'FOOTER'} = &get_footer;

	&print_header;
	print &parse_template('cpanel/index.htmlt', 'main');
	exit(0);
	
}

################################################
## Get html styles for cpanel
################################################

sub cpanel_get_styles {
	my (@styles, %temp, %style);
	
	## Get info from styles_cpanel.dat file
	@styles = &readfile("$datadir/dat/styles_cpanel.dat");
	
	foreach $line (@styles) {
		next if $line eq '';
		my ($key, $value) = split /::/, $line;
		$temp{$key} = $value;
	}
	
	## Create the needed styles
	$in{'SUBMENU_BGCOLOR'} = $temp{'SUBMENU_BGCOLOR'};
	$style{'FONT_BODY'} = qq!<font face="$temp{'BODY_FONT_FACE'}" size="$temp{'BODY_FONT_SIZE'}" color="#$temp{'BODY_FONT_COLOR'}">!;
	$style{'FONT_HEADER'} = qq!<font face="$temp{'HEADER_FONT_FACE'}" size="$temp{'HEADER_FONT_SIZE'}" color="#$temp{'HEADER_FONT_COLOR'}"><b>~1~</b></font><br><br>!;
	$style{'LINE'} = qq!<center><hr width=90%></center><br>!;
	$style{'FOOTER'} = qq!</td></tr></table></form></body></html>!;
	$style{'TABLE_HEADER'} = qq!
		<table border=0 cellspacing=0 cellpadding=0><tr><td colspan=5 valign=top bgcolor="#000000"><img src="~GIF_URL~/spacer.gif" height=1px width=1px border=0></td></tr><tr>
		<td valign=top><img src="~GIF_URL~/line.gif" width=1px height=20px border=0></td><td bgcolor="#$temp{'TABLE_BGCOLOR'}"><img src="~GIF_URL~/spacer.gif" width=2px height=1px border=0></td>	
		<td bgcolor="#$temp{'TABLE_BGCOLOR'}" nowrap><font face="$temp{'TABLE_FONT_FACE'}" size="$temp{'TABLE_FONT_SIZE'}" color="#$temp{'TABLE_FONT_COLOR'}"><b>~1~</b></font></td><td bgcolor="#$temp{'TABLE_BGCOLOR'}"><img src="~GIF_URL~/spacer.gif" width=2px height=1px border=0></td>
		<td valign=top><img src="~GIF_URL~/line.gif" width=1px height=20px border=0></td></tr><tr><td colspan=5 valign=top colspan=3 bgcolor="#000000"><img src="~GIF_URL~/spacer.gif" height=1px width=1px border=0></td></tr></table><br>!;
		
	$style{'MENU'} = qq!
		<tr><td valign=top><img src="~GIF_URL~/line.gif" width=1px height=20px border=0></td><td bgcolor="#$temp{'MENU_BGCOLOR'}"><img src="~GIF_URL~/spacer.gif" width=2px height=1px border=0></td>
		<td bgcolor="#$temp{'MENU_BGCOLOR'}" nowrap><a href="~script_name~?menu=~2~"><font face="$temp{'MENU_FONT_FACE'}" size="$temp{'MENU_FONT_SIZE'}" color="#$temp{'MENU_FONT_COLOR'}"><b>&nbsp;~1~&nbsp;</b></font></a></td>
		<td bgcolor="#$temp{'MENU_BGCOLOR'}"><img src="~GIF_URL~/spacer.gif" width=2px height=1px border=0></td>
		<td valign=top><img src="~GIF_URL~/line.gif" width=1px height=20px border=0></td></tr><tr><td colspan=5 valign=top bgcolor="#000000"><img src="~GIF_URL~/spacer.gif" height=1px width=1px border=0></td></tr>!;
		
	$style{'SUBMENU'} = qq!<tr><td nowrap><a href="~script_name~?menu=~2~&action=~3~"><font face="$temp{'SUBMENU_FONT_FACE'}" size="$temp{'SUBMENU_FONT_SIZE'}" color="#$temp{'SUBMENU_FONT_COLOR'}">&nbsp\;~1~&nbsp\;</font></a></td></tr>!;
	

	return %style;

}

################################################
## Get the HTML header
################################################

sub get_header {
	my ($html, $mainmenu_html, $submenu_html, @menus);

	## Get needed info
	$html = &parse_template("cpanel/header.htmlt");
	@menus = &readfile("$datadir/dat/navmenu_cpanel.dat");

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
	
	$html =~ s/~MAINMENU_OPTIONS~/$mainmenu_html/gi;
	$html =~ s/~SUBMENU_OPTIONS~/$submenu_html/gi;

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
	$html = &parse_template("cpanel/footer.htmlt");
	## Replace all merge fields with appropriate info
	while (($key,$value) = each %in) {
		$html =~ s/~$key~/$value/gi;
	}

	return $html;

}

