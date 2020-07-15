
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


#####################################################
## Get column names of a table
#####################################################

sub mysql_get_column_names {
	my $table = shift;
	my ($rv, $sth, @results, @names);
	
	$sth = $dbh->prepare("show columns from $table");
	$rv = $sth->execute or &error(302, __LINE__, __FILE__, $table);
	if ($rv == 0) { &error(302, __LINE__, __FILE__, $table); }

	while (@results = $sth->fetchrow_array) {
		push @names, $results[0];
	}
	
	return @names;
}

#####################################################
## Get column info from a table
#####################################################

sub mysql_get_column_info {
	my $table = shift;
	my ($rv, $sth, @results, %info);
	
	$sth = $dbh->prepare("show columns from $table");
	$rv = $sth->execute or &error(302, __LINE__, __FILE__, $table);
	if ($rv == 0) { &error(302, __LINE__, __FILE__, $table); }

	while (@results = $sth->fetchrow_array) {
		$info{$results[0]} = $results[1];
	}
	
	return %info;
}

#####################################################
## Get the table names of the database
#####################################################

sub mysql_get_table_names {
	my ($rv, $sth, @results, @names);

	$sth = $dbh->prepare("show tables");
	$rv = $sth->execute or &error(303, __LINE__, __FILE__);
	
	while (@results = $sth->fetchrow_array) {
		push @names, $results[0];
	}
	
	return @names;

}

#####################################################
## Check to see if a record exists
#####################################################

sub mysql_count_record {
	my ($table, $column, $record) = @_;
	my ($rv, $sth);
	
	$sth = $dbh->prepare("select $column from $table where $column='$record'");
	$rv = $sth->execute or &error(311, __LINE__, __FILE__, $table, $column, $record);
	return $rv;

}

#####################################################
## Drop a table from the database
#####################################################

sub mysql_drop_table {
	my $table = shift;
	my ($found, $sth, @table_names);
	
	$sth = $dbh->prepare("drop table $table");
	$sth->execute or &error(304, __LINE__, __FILE__, $table);

	$found = 0;
	@table_names = &mysql_get_table_names;
	foreach (@table_names) {
		if ($_ eq $table) { $found = 1; last; }
	}
	if ($found == 1) { &error(304, __LINE__, __FILE__, $table); }

	return 1;
}

#####################################################
## Select a record from a table
#####################################################

sub mysql_select {
	my ($table, $column, $operator, $record, @results) = @_;
	my ($rv, $sth, $sql, @fields, @query_results);
	
	@fields = &mysql_get_column_names($table);
	
	## Create the SQL statment
	if (uc ($results[0]) eq 'ALL') { $sql = "select * from $table "; }
	else { $sql = "select ".(join ",", @results)." from $table "; }

	if ((uc($column) eq 'ALL') || ($column eq '')) { chop $sql; }
	else { 
		if ($operator =~ /^EQUALS$|^EQUAL$|^\=$/i) { $sql .= "where $column='$record'"; }
		elsif ($operator =~ /^LIKE%$/i) { $sql .= "where $column like \'$record\%\'"; }
		elsif ($operator =~ /^%LIKE$/i) { $sql .= "where $column like \'\%$record\'"; }
		elsif ($operator =~ /^%LIKE%$/i) { $sql .= "where $column like \'\%$record\%\'"; }
	}
	
	## Execute the SQL statement

	$sth = $dbh->prepare($sql);
	$rv = $sth->execute or &error(311, __LINE__, __FILE__, $table, $column, $record);
	return 0 if $rv == 0;
	
	## Parse the results
	while (@row = $sth->fetchrow_array) {
		push @query_results, [ @row ];
	}

	if ($rv == 1) { return ($rv, @{$query_results[0]}); }
	else { return ($rv, @query_results); }
	
}

#####################################################
## Insert a record into a table
#####################################################

sub mysql_insert {
	my ($table, @info) = @_;
	my ($x, $rv, $sth, $sql, @fields, %dbinfo);
	
	## Get some info
	@fields = &mysql_get_column_names($table);
	%dbinfo = &mysql_get_column_info($table);
	
	## Create SQL statemnt
	$x=0;
	$sql = "insert into $table values(";
	foreach $field (@fields) {
			my $record = $dbh->quote($info[$x]);
			$sql .= "$record,";
	$x++; }
	chop $sql;
	$sql .= ")";

	## Insert SQL into 
	$sth = $dbh->prepare($sql);
	$rv = $sth->execute or &error(312, __LINE__, __FILE__, $table, @info);
	if ($rv == 0) { &error(312, __LINE__, __FILE__, $table, @info); }

	return 1;
}

#####################################################
## Update a record in a table
#####################################################

sub mysql_update {
	my ($table, $column, $record, $update_column, $new_info) = @_;
	my ($sth);
	
	$record = $dbh->quote($record);
	$new_info = $dbh->quote($new_info);
	
	$sth = $dbh->prepare("update $table set $update_column=$new_info where $column=$record");
	$sth->execute or &error(313, __LINE__, __FILE__, @_);
	
	return 1;

}

#####################################################
## Update multiple records in a table
#####################################################

sub mysql_updates {
	my ($table, $column, $record, %set_info) = @_;
	my ($sth, $sql, $key, $value, $x);
	
	$record = $dbh->quote($record);
	$sql = "update $table set ";
	while (($key, $x) = each(%set_info)) {
		if ($key ne UNDEF && ($key ne "")) {
			$value = $dbh->quote($x);
			$sql .= "$key=$value,";
		}
	}
	chop $sql;
	$sql .= " where $column=$record";

	$sth = $dbh->prepare($sql);
	$sth->execute or &error(313, __LINE__, __FILE__, @_);
	
	return 1;
}

#####################################################
## Delete a record from a table
#####################################################

sub mysql_delete {
	my ($table, $column, $record) = @_;
	my ($sth, $quote);
	
	$quote=$dbh->quote($record);
	$sth = $dbh->prepare("delete from $table where $column=$quote");
	$sth->execute or &error(314, __LINE__, __FILE__, @_);
	
	return 1;

}

1;
