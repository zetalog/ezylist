
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
## Handle an error
################################################

sub error_handleit {
	my ($code, @data) = @_;
	
	## If it is a general user error
	if ($code == 500) {
		return (0, $data[0]);
	}
	
	## Split up the error code
	my ($c1, $c2, $c3) = $code =~ /(.)(.)(.)/;
	my $err_sub = 'error_code' . $c1 . $c2;
	return &{$err_sub}($c3, @data);

}

################################################
## Error codes 10x - Server Program Error
################################################

sub error_code10 {
	my ($c3, @data) = @_;
	my ($message);
	
	## Get the message
	if ($c3 == 1) { $message = "Unable to open Sendmail at, <b>$mailprog</b>"; }
	elsif ($c3 == 2) { $message = "Unable to find required Perl module/library, <b>$data[0]</b>"; }
	
	## Figure out the Sendmail error
	if ($c3 == 1) {
		if (!-e $mailprog) { return(0, $message, "Sendmail does not exist at, <b>$mailprog</b>", "Contact server administrator"); }

		my $results = `$mailprog -bv testing\@test.com`;
		if ($results ne "testing\@test.com... deliverable: mailer esmtp, host test.com., user testing\@test.com") {
			return (0, "Sendmail exists and partially works, but doesn't seem to be operational.", "Contact server administrator");
		} else { return (0, "Unknown"); }
	}

	## Figure out Perl module error
	elsif ($c3 == 2) {
		my $success = 0;
		foreach (@INC) {
			if (-e "$_/$data[0]") { $success = 1; }
		}
		
		if ($success == 1) {
			eval { require $data[0]; };
			if ($@) { return (0, $message, "The Perl module/library exists, but contains errors.", "If possible, reinstall the Perl module/library.  If not possible, contact server administrator."); }
			else { return 1; }
		} else { return (0, $message, "Perl module/library, <b>$data[0]</b> does not exist.", "If possible, install the Perl module/library.  If not possible, contact server administrator."); }
	}

}

################################################
## Error codes 20x - File Handling error
################################################

sub error_code20 {
	my ($c3, @data) = @_;
	my ($opr, $file, $handle, $perm, $rootdir, $rootdir_perm, $retry, $success, @stats, @rootdir_stats);
	
	## Set some variables
	$file = $data[0];
	$handle = $data[1];
	
	if ($c3 < 6) { $opr = "file"; }
	else { $opr = "directory"; }
	
	## Figure out the error message
	if ($c3 == 1) { $message = "Unable to read file, $file"; }
	elsif ($c3 == 2) { $message = "Unable to append to file, $file"; }
	elsif ($c3 == 3) { $message = "Unable to write to file, $file"; }
	elsif ($c3 == 4) { $message = "Unable to delete file, $file"; }
	elsif ($c3 == 5) { $message = "Unable to rename file, $file"; }
	elsif ($c3 == 6) { $message = "Unable to open directory, $file"; }
	elsif ($c3 == 7) { $message = "Unable to create directory, $file"; }
	elsif ($c3 == 8) { $message = "Unable to delete directory, $file"; }
	elsif ($c3 == 9) { $message = "Unable to renane directory, $file"; }
	
	## Get some info on the file
	if (-e $file) { 
		@stats = stat $file;
		$perm = sprintf "%ol", ($stats[2] & 07777);
		
		($rootdir) = $file =~ /^(.*)\/.+$/;
		@rootdir_stats = stat $rootdir;
		$rootdir_perm = sprintf "%ol", ($rootdir_stats[2] & 07777);
	} else {
		if ($c3 == (4 || 8)) { return 1; }
		else { return(0, $message, "\u\L$opr\E does not exist, <b>$file</b>"); }
	}
	
	## Check if permissions are 0777
	if ($perm != 777) {
		$success = chmod 0777, $file;
		
		if ($success == 1) {
			$retry = &error_code20_retry($c3, @data);
			return 1 if $retry == 1;
		} else { return (0, $message, "\u\L$opr\E permissions are not 0777", "CHMOD the $opr, <i>$file</i>, to 0777"); }
	}
	
	## Check the parent directory
	if ($rootdir_perm != 777) {
		$success = chmod 0777, $file;
		if ($success == 1) {
			$retry = &error_code20_retry($c3, @data);
			if ($retry == 1) { return 1; }
			else { &error_code20($c3, @data); }
		} else { return(0, $message, "Directory permissions are not 0777", "CHMOD the directory, <i>$rootdir</i> to 0777"); }
	}
	
	return(0, $message);
	
}

################################################
## Error codes 20x - Retry function
################################################

sub error_code20_retry {
	my ($c3, @data) = @_;
	my ($file, $handle, $success);
	
	## Set some variables
	$file = $data[0];
	$handle = $data[1];

	## Try to manipulate the file again
	if ($c3 == 1) { open $handle, "$file" or return; }
	elsif ($c3 == 2) { open $handle, ">>$file" or return; }
	elsif ($c3 == 3) { open $handle, ">$file" or return; }
	elsif ($c3 == 4) { 
		$success = unlink "$file";
		return if $success != 1;
	} elsif ($c3 == 5) {
		$success = rename($file, $handle);
		return if $success != 1;
	} elsif ($c3 == 6) { opendir $handle, "$file" or return; }
	elsif ($c3 == 7) {
		$success = mkdir($file, 0777);
		return if $success != 1;
	} elsif ($c3 == 8) {
		$success = rmdir $file;
		return if $success != 1;
	} elsif ($c3 == 9) {
		$success = rename $file, $handle;
		return if $success != 1;
	}
	
	return 1;
	
}

#####################################################
## Handle error - code 3
#####################################################

sub error_code3 {
	## Get the error message
	if ($code2 == 0) {
		if ($code3 == 1) { $message = "Unable to connect to MySQL database, <i>$db{'dbname'}</i>"; }
		elsif ($code3 == 2) { $message = "Unable to show columns from MySQL database ($db{'dbname'}) table, <i>$err[0]</i>"; }
		elsif ($code3 == 3) { $message = "Unable to show table names from MySQL database, $db{'dbname'}"; }
		elsif ($code3 == 4) { $message = "Unable to drop table, <i>$err[0]</i>, from MySQL database ($db{'dbname'})"; }
		elsif ($code3 == 5) { $message = "Unable to create table, <i>$err[0]</i>, in MySQL database ($db{'dbname'})"; }
	} elsif ($code2 == 1) {
		if ($code3 == 1) { $message = "Unable to perform select statement on table, <i>$err[0]</i>, column name, <i>$err[1]</i>, record, <i>$err[2]</i>"; }
		elsif ($code3 == 2) { $message = "Unable to perform insert statment on table, <i>$err[0]</i>"; }
		elsif ($code3 == 3) { $message = "Unable to perform update statement on table, <i>$err[0]</i>, column name, <i>$err[3]</i>, with new record, <i>$err[4]</i>"; }
		elsif ($code3 == 4) { $message = "Unable to perform delete statement on table, <i>$err[0]</i>, column name, <i>$err[1]</i>, record <i>$err[2]</i>"; }
	}

	## First, make sure were connected to the database
	if (!ref $dbh) {
		$dbh = DBI->connect("DBI:mysql:$db{'dbname'}", $db{'username'}, $db{'password'});
		if (ref $dbh) { return 1; }
		else { return (0, $message, "Unknown", "Contact server administrator"); }
	}
	
	if ($code2 == 0) {
		if ($code3 == 2) { 
			$found = &error_code3_check_table($err[0]);
			if ($found == 0) { return(0, $message, "Table does not exist, <i>$err[0]</i>", "Not applicable"); }
			
			$sth = $dbh->prepare("show columns from $err[0]");
			$rv = $sth->execute or return(0, $message, "Unknown", "Unknown");
			if ($rv >= 1) { return 1; }
			else { return(0, $message, "Unknown", "Unknown"); }
		}

		elsif ($code3 == 3) { return (0, $message, "Unknown", "Unknown"); }
		elsif ($code3 == 4) {
			$found = &error_code3_check_table($err[0]);
			if ($found == 0) { return 1; }
			
			$sth = $dbh->prepare("drop table $err[0]");
			$sth->execute or return(0, $message, "Unknown", "Unknown");
			
			$found = &error_code3_check_table($err[0]);
			if ($found == 0) { return 1; }
			else { return (0, $message, "Unknown", "Unknown"); }
		}
		
		elsif ($code3 == 5) {
			$found = &error_code3_check_table($err[0]);
			if ($found == 1) { return (0, $message, "Table already exists, <i>$err[0]</i>", "Not applicable"); }
			else { return (0, $message, "Unknown", "Unknown"); }
		}		
	}
	
	elsif ($code2 == 1) {
		if ($code3 == 1) {
			$found = &error_code3_check_table($err[0]);
			if ($found == 0) { return(0, $message, "Table does not exist, <i>$err[0]</i>", "Not applicable"); }
			
			$found = &error_code3_check_column($err[0], $err[1]);
			if ($found == 0) { return (0, $message, "Column, <i>$err[1]</i>, does not exist in table, <i>$err[0]</i>", "Not applicable"); }
			else { return (0, $message, "Unknown", "Unknown"); }			
		}
		
		elsif ($code3 == 2) {
			$found = &error_code3_check_table($err[0]);
			if ($found == 0) { return(0, $message, "Table does not exist, <i>$err[0]</i>", "Not applicable"); }
			else { return(0, $message, "Unknown", "Unknown"); }
		}
		
		elsif ($code3 == 3) {
			$found = &error_code3_check_table($err[0]);
			if ($found == 0) { return(0, $message, "Table does not exist, <i>$err[0]</i>", "Not applicable"); }
		
			$found = &error_code3_check_column($err[0], $err[1]);
			if ($found == 0) { return (0, $message, "Column, <i>$err[1]</i>, does not exist in table, <i>$err[0]</i>", "Not applicable"); }
			$found = &error_code3_check_column($err[0], $err[3]);
			if ($found == 0) { return (0, $message, "Column, <i>$err[1]</i>, does not exist in table, <i>$err[0]</i>", "Not applicable"); }
			else { return (0, $message, "Unknown", "Unknown"); }
		}
		
		elsif ($code3 == 4) {
			$found = &error_code3_check_table($err[0]);
			if ($found == 0) { return(0, $message, "Table does not exist, <i>$err[0]</i>", "Not applicable"); }
		
			$found = &error_code3_check_column($err[0], $err[1]);
			if ($found == 0) { return (0, $message, "Column, <i>$err[1]</i>, does not exist in table, <i>$err[0]</i>", "Not applicable"); }
			else { return(0, $message, "Unknown", "Unknown"); }
		}
	} else { return(0, "Unknown Error Code", "Not applicable", "Not applicable"); }

}

#####################################################
## Error Code 3 - get MySQL table names
#####################################################

sub error_code3_get_tables {
	my ($rv, $sth, @results, @names);

	$sth = $dbh->prepare("show tables");
	$rv = $sth->execute or &error(303, __LINE__, __FILE__);
	
	while (@results = $sth->fetchrow_array) {
		push @names, $results[0];
	}
	
	return @names;

}

#####################################################
## Error Code 3 - check if MySQL table exists
#####################################################

sub error_code3_check_table {
	my $table = shift;
	my ($found, @tables);
	
	$found = 0;
	@tables = &error_code3_get_tables;
	foreach (@tables) {
		if ($_ eq $table) { $found = 1; last; }
	}
	
	return $found; 
	
}

#####################################################
## Error Code 3 - check if MySQL column exists
#####################################################

sub error_code3_check_column {
	my ($table, $column) = @_;
	my ($rv, $sth, $found, @results);
	
	$sth = $dbh->prepare("show columns from $table");
	$rv = $sth->execute or &error(302, __LINE__, __FILE__, $table);
	if ($rv == 0) { &error(302, __LINE__, __FILE__, $table); }

	$found = 0;
	while (@results = $sth->fetchrow_array) {
		if ($results[0] eq $column) { $found = 1; last; }
	}
	
	return $found;	
}

1;

