
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
## Get account's extension for mysql module
################################################

sub mysql_get_ext {
	my $user = shift;
	my $table = "member";
	my $column = "username";
	my $operator = "EQUALS";
	my $record = $user;
	my @$vars;
	
	$vars[0] = "status";
	$vars[1] = "type";
	my ($rv, @results) = mysql_select($table, $column, $operator, $record, @vars);
	if ($rv == 0) { return (undef, undef); }
	elsif ($rv == 1) { @return_results = @results; }
	elsif ($rv > 1) { @return_results = @{$results[0]}; }
	else { &error(500, __LINE__, __FILE__, "Unknown extension for user, <i>$user</i>"); }
	return @return_results;
}

################################################
## Get account's info for mysql module
################################################

sub mysql_get_variable {
	my ($user, @vars) = @_;
	my ($userinfo, @userinfo, @results);
	my $table = "member";
	my $column = "username";
	my $operator = "EQUALS";
	my $record = $user;
	
	my ($rv, @results) = mysql_select($table, $column, $operator, $record, @vars);
	if ($rv == 0) { &error(500, __LINE__, __FILE__, "User does not exist, <i>$user</i>"); }
	elsif ($rv == 1) { @userinfo = @results; }
	else { @userinfo = @{$results[0]}; }

	if (wantarray) { return @userinfo; }
	else { return $userinfo[0]; }
}

################################################
## Fetch account for mysql module
################################################

sub mysql_fetch_account {
	my $user = shift;
	my $rv, @userinfo;
	my $table = "member";
	my $column = "username";
	my $operator = "EQUALS";
	my $record = $user;

	## my ($status, $type) = &get_ext($user); ## Don't need for mysql module

	($rv, @userinfo) = mysql_select($table, $column, $operator, $record, "ALL");
	if ($rv == 1) { return @userinfo; }
	elsif ($rv > 1) { return @{$userinfo[0]}; }
	else { &error(500, __LINE__, __FILE__, "No result matched."); }
}

################################################
## Fetch accounts for mysql module
################################################

sub mysql_fetch_accounts {
	my ($user, $fetch_all) = @_;

	my $table = "member";
	my $column = "";
	my $operator;
	my $record;

	if ($fetch_all != 1) {
		$column = "username";
		$operator = "EQUALS";
		$record = $user;
	}

	my ($rv, @results) = mysql_select($table, $column, $operator, $record, "ALL");
	if ($rv == 1) {
		my @return_results;
		push @return_results, [ @results ];
		return @return_results;
	} else { return @results; }
}

################################################
## Create account for mysql module
################################################

sub mysql_create_account {
	my ($user, $type, @userfields) = @_;
	my ($table, @userinfo);

	$table = "member";

	foreach $x (0 .. @userfields - 1) { push @userinfo, $in{$userfields[$x]}; }
	push @userinfo, 'active';
	push @userinfo, $type;
	
	if ($type eq "advertiser") {
		&makedir("$datadir/ad/$user");
		counter_increase("$datadir/mysql.ads");
	}
	else {
		&makedir("$datadir/list/$user");
		&makedir("$datadir/list/$user/error");
		&makedir("$datadir/list/$user/log") if $moptions[8] == 1;
		counter_increase("$datadir/mysql.mls");
	}
	mysql_insert($table, @userinfo);
}

################################################
## Edit account for mysql module
################################################

sub mysql_edit_account {
	my ($user, $type, $status, @editfields) = @_;
	my ($table, $column, $x, %userinfo);

	$table = "member";
	$column = "username";
	foreach $x (0 .. @editfields) {
		$userinfo{"$editfields[$x]"} = $in{$editfields[$x]};
	}

	mysql_updates($table, $column, $user, %userinfo);
}

################################################
## Register accounts for mysql module
################################################

sub mysql_register_account {
	my $user = shift;
	my ($table, $success);
	$table = "member";

	$success = mysql_update($table, "username", $user, "type", "registered");
	if ($success == 0) { &error(205, __LINE__, ___FILE__, "Cannot register user <b>$user</b>."); }
}

################################################
## Deregister accounts for mysql module
################################################

sub mysql_deregister_account {
	my $user = shift;
	my ($table, $success);
	$table = "member";

	$success = mysql_update($table, "username", $user, "type", "unregistered");
	if ($success == 0) { &error(205, __LINE__, ___FILE__, "Cannot deregister user <b>$user</b>."); }
}

################################################
## Activate accounts for mysql module
################################################

sub mysql_activate_account {
	my $user = shift;
	my ($table, $success);
	$table = "member";

	$success = mysql_update($table, "username", $user, "status", "active");
	if ($success == 0) { &error(205, __LINE__, ___FILE__, "Cannot activate user <b>$user</b>."); }
}

################################################
## Dectivate accounts for mysql module
################################################

sub mysql_deactivate_account {
	my $user = shift;
	my ($table, $success);
	$table = "member";

	$success = mysql_update($table, "username", $user, "status", "inactive");
	if ($success == 0) { &error(205, __LINE__, ___FILE__, "Cannot deactivate user <b>$user</b>."); }
}

################################################
## Delete accounts for mysql module
################################################

sub mysql_delete_account {
	my ($user, $type, $status) = @_;
	my ($table);
	$table = "member";

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
		counter_decrease("$datadir/mysql.ads");
	} else {
		&removedir("$datadir/list/$user");
		&deletefile("$datadir/conf/$user.conf");
		&deletefile("$datadir/cgi/$user$ext");
		counter_decrease("$datadir/mysql.mls");
	}
	mysql_delete($table, "username", $user);
}

################################################
## Search accounts for mysql module
################################################

sub mysql_search_account {
	my ($status, $type) = @_;
	my ($sql, $rv, $sth, @row, @query_results);

	## Create the SQL statment
	$sql = "select username from member ";
	if ($status ne "all") {
		$sql .= "where status='$status'";
		if ($type ne "all") { $sql .= " and "; }
	}
	if ($type ne "all") {
		if ($status eq "all") { $sql .= "where "; }
		$sql .= "type='$type'";
	}
	
	## Execute the SQL statement
	$sth = $dbh->prepare($sql);
	$rv = $sth->execute or &error(311, __LINE__, __FILE__, "status is $status and type is $type");
	return if $rv == 0;
	
	## Parse the results
	while (@row = $sth->fetchrow_array) {
		push @query_results, $row[0];
	}

	return @query_results;
}

1;
