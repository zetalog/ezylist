
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
## Get account's extension for cgi module
################################################

sub cgi_get_ext {
	my $user = shift;
	
	opendir DIR, "$datadir/cgi" or &die("$datadir/cgi");
	my @users = grep /$user\.(active|inactive)\.(registered$|unregistered$|advertiser$)/, readdir(DIR);
	closedir DIR;

	foreach (@users) {
		if ($_ =~ m!$user\.(active|inactive)\.(registered$|unregistered$|advertiser$)!) {
			return ($1, $2);
		}
	}
	return (undef, undef);
}

################################################
## Get account's info for cgi module
################################################

sub cgi_get_variable {
	my ($user, @vars) = @_;
	my ($x, $status, $type, $userinfo, @userinfo, @result, %userinfo);
	
	($status, $type) = &get_ext($user);
	if (!$status || !$type) { &error(500, __LINE__, __FILE__, "User does not exist, <i>$user</i>"); }
	$userinfo = &readfile("$datadir/cgi/$user.$status.$type");
	@userinfo = split /::/, $userinfo;
	
	$x=0;
	foreach (@userfields) {
		$userinfo{$_} = $userinfo[$x];
	$x++; }
	
	foreach (@vars) {
		push @result, $userinfo{lc($_)};
	}
	
	if (wantarray) { return @result; }
	else { return $result[0]; }
}

################################################
## Fetch account for cgi module
################################################

sub cgi_fetch_account {
	my $user = shift;
	my ($status, $type) = &get_ext($user);
	my @userinfo;

	@userinfo = split /::/, (&readfile("$datadir/cgi/$user.$status.$type"));
	$userinfo[$extfield] = $status;
	$userinfo[$extfield+1] = $type;

	return @userinfo;
}

################################################
## Fetch accounts for cgi module
################################################

sub cgi_fetch_accounts {
	my ($username, $fetch_all) = @_;
	my ($status, $type);

	if ($fetch_all == 1) {
		## Get the members from the database
		opendir DIR, "$datadir/cgi" or &error(206, __LINE__, __FILE__, "$datadir/cgi", "DIR");
		my @users = grep /\.unregistered$|\.registered$|\.advertiser$/, readdir(DIR);
		closedir DIR;
	
		## Get all info from users
		@users = sort { lc($a) cmp lc($b) } @users;
		my $x=0, @query_results;
		foreach $user (@users) {
			my ($user, $status, $type) = split /\./, $user;
			my @userinfo = (split /::/, &readfile("$datadir/cgi/$user.$status.$type"));
			$userinfo[0] = $user;
			$userinfo[$extfield] = $status;
			$userinfo[$extfield+1] = $type;
			push @query_results, [ @userinfo ];
		$x++; }
		return @query_results;
	} else {
		my (@userinfo, @query_results);

		## Make sure user exists
		($status, $type) = &get_ext($username);

		## Get needed info
		my @userinfo = (split /::/, &readfile("$datadir/cgi/$user.$statys.$type"));
		$userinfo[0] = $user;
		$userinfo[$extfield] = $status;
		$userinfo[$extfield+1] = $type;
		push @query_results, [ @userinfo ];
		return @query_results;
	}
}

################################################
## Create account for cgi module
################################################

sub cgi_create_account {
	my ($user, $type, @userfields) = @_;

	## Create member profile
	foreach (@userfields) { push @userinfo, $in{$_}; }
	$userinfo = join "::", @userinfo;
	## Add member to database
	if ($type eq "advertiser") {
		&makedir("$datadir/ad/$user");
		counter_increase("$datadir/cgi.ads");
	}
	else {
		&makedir("$datadir/list/$user");
		&makedir("$datadir/list/$user/error");
		&makedir("$datadir/list/$user/log") if $moptions[8] == 1;
		counter_increase("$datadir/cgi.mls");
	}
	&writefile("$datadir/cgi/$user.active.$type", $userinfo);
}

################################################
## Edit account for cgi module
################################################

sub cgi_edit_account {
	my ($user, $type, $status, @newfields) = @_;
	my ($x, $userinfo, $field, @userinfo);

	@userinfo = cgi_fetch_account($user);
	foreach $field (@newfields) {
LOOPFIELDS:	for ($x = 0; $x < @userfields; $x++) {
			if ($userfields[$x] eq $field) {
				$userinfo[$x] = $in{$userfields[$x]};
				last LOOPFIELDS;
			}
		}
	}

	## Gather up new profile
	$userinfo = join "::", @userinfo;

	## Save new info to database
	&writefile("$datadir/cgi/$user.$status.$type", $userinfo);
}

################################################
## Register accounts for mysql module
################################################

sub cgi_register_account {
	my $user = shift;
	my ($status, $type) = &get_ext($user);
	my $success;

	$success = rename("$datadir/cgi/$user.$status.$type", "$datadir/cgi/$user.$status.registered");
	if ($success == 0) {
		&error(205, __LINE__, ___FILE__, "$datadir/cgi/$user.$status.$type", "$datadir/cgi/$user.$status.registered");
	}
}

################################################
## Deregister accounts for mysql module
################################################

sub cgi_deregister_account {
	my $user = shift;
	my ($status, $type) = &get_ext($user);
	my $success;

	$success = rename("$datadir/cgi/$user.$status.$type", "$datadir/cgi/$user.$status.unregistered");
	if ($success == 0) {
		&error(205, __LINE__, ___FILE__, "$datadir/cgi/$user.$status.$type", "$datadir/cgi/$user.$status.unregistered");
	}
}

################################################
## Activate accounts for cgi module
################################################

sub cgi_activate_account {
	my $user = shift;
	my ($status, $type) = &get_ext($user);
	my $success;

	$success = rename("$datadir/cgi/$user.$status.$type", "$datadir/cgi/$user.active.$type");
	if ($success == 0) {
		&error(205, __LINE__, ___FILE__, "$datadir/cgi/$user.$status.$type", "$datadir/cgi/$user.active.$type");
	}
}

################################################
## Dectivate accounts for cgi module
################################################

sub cgi_deactivate_account {
	my $user = shift;
	my ($status, $type) = &get_ext($user);
	my $success;

	$success = rename("$datadir/cgi/$user.$status.$type", "$datadir/cgi/$user.inactive.$type");
	if ($success == 0) {
		&error(205, __LINE__, ___FILE__, "$datadir/cgi/$user.$status.$type", "$datadir/cgi/$user.inactive.$type");
	}
}

################################################
## Delete accounts for cgi module
################################################

sub cgi_delete_account {
	my ($user, $type, $status) = @_;

	## Remove advertisement and mailing list data here
	if ($type eq "advertiser") {
		my ($x, $line, @index);
		$x=0;
		@index = &readfile("$datadir/ad/$user/index.dat") if -e "$datadir/ad/$user/index.dat";
		foreach $line (@index) {
			my @line = split /::/, $line;
			my $index = $line[4];
			&deletefile("$datadir/ad/$index");
		$x++; }
		&removedir("$datadir/ad/$user");
		counter_decrease("$datadir/cgi.ads");
	} else {
		&removedir("$datadir/list/$user");
		&deletefile("$datadir/conf/$user.conf");
		counter_decrease("$datadir/cgi.mls");
	}
	&deletefile("$datadir/cgi/$user.$status.$type");
}

################################################
## Search accounts for cgi module
################################################

sub cgi_search_account {
	my ($status, $type) = @_;
	my ($user, @users, @results);

	opendir DIR, "$datadir/cgi" or &error(206, __LINE__, __FILE__, "$datadir/cgi", "DIR");
	if ($status eq 'all') {
		if ($type eq'all') { @users = grep /\.(active|inactive)\.(registered$|unregistered$|advertiser$)/, readdir(DIR); }
		elsif ($type eq'registered') { @users = grep /\.(active|inactive)\.(registered$)/, readdir(DIR); }
		elsif ($type eq'unregistered') { @users = grep /\.(active|inactive)\.(unregistered$)/, readdir(DIR); }
		elsif ($type eq'advertiser') { @users = grep /\.(active|inactive)\.(advertiser$)/, readdir(DIR); }
	} elsif ($status eq 'active') {
		if ($type eq'all') { @users = grep /\.(active)\.(registered$|unregistered$|advertiser$)/, readdir(DIR); }
		elsif ($type eq'registered') { @users = grep /\.(active)\.(registered$)/, readdir(DIR); }
		elsif ($type eq'unregistered') { @users = grep /\.(active)\.(unregistered$)/, readdir(DIR); }
		elsif ($type eq'advertiser') { @users = grep /\.(active)\.(advertiser$)/, readdir(DIR); }
	} elsif ($status eq 'inactive') {
		if ($type eq'all') { @users = grep /\.(inactive)\.(registered$|unregistered$|advertiser$)/, readdir(DIR); }
		elsif ($type eq'registered') { @users = grep /\.(inactive)\.(registered$)/, readdir(DIR); }
		elsif ($type eq'unregistered') { @users = grep /\.(inactive)\.(unregistered$)/, readdir(DIR); }
		elsif ($type eq'advertiser') { @users = grep /\.(inactive)\.(advertiser$)/, readdir(DIR); }
	}
	closedir DIR;

	foreach (@users) {
		($user, $status, $type) = split /\./, $_;
		push @results, $user;
	}

	return @results;
}

1;
