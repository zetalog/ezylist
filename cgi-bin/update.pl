#!/usr/bin/perl
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

## Full path to the ezylist.conf filoe
$conf = "~datadir~/ezylist.conf";

############################################################################
## IT IS ILLEGAL FOR YOU TO VIEW, EDIT, COPY, DELETE, 
## TRANSFER, OR IN ANY WAY MANIPULATE THE CODE BELOW 
## THIS LINE.
############################################################################

eval { require $conf; };
if ($@) { return &update_error("Unable to find required file, ezylist.conf, which should be located at, $conf"); }
eval { require "$cgidir/lib/main-lib.pl"; };
if ($@) { return &update_error("Unable to find required file, main-lib.pl, which should be located at $cgidir/lib/main-lib.pl"); }
eval { require "$cgidir/lib/ezylist-lib.pl"; };
if ($@) { return &update_error("Unable to find required file, ezylist-lib.pl, which should be located at $cgidir/lib/ezylist-lib.pl"); }
$HEADER = 1;

## Get the date and time
($date, $time) = &getdate;
($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);

if ($in{'module_action'} eq 'add_to_modules') {
	my $text = join "::", $in{'mod'}, $in{'modname'}, $in{'modversion'};
	&appendfile("$datadir/dat/modules.dat", $text);
	print "Content-type: text/plain\n\n1\n"; exit;
} elsif ($in{'module_action'} eq 'add_to_exec') {
	my $text = "\#\# $in{'mod'}\npush \@{\$exec{\"$in{'left'}\"}}, \"$in{'right'}\"\;\n\n";
	&appendfile("$cgidir/modules/exec.pl", $text);
	print "Content-type: text/plain\n\n1\n"; exit;
} elsif ($in{'module_action'} eq 'add_to_cron') {
	my $text = $in{'crontext'};
	&appendfile("$datadir/cron.wsr", $text);
	print "Content-type: text/plain\n\n1\n"; exit;
}

## See if we need to perform a backup
if ($auto_options[0] == 1) {
	if ($auto_options[1] eq 'daily') { &update_backup; }
	elsif (($auto_options[1] eq 'weekly') && ($wday == 0)) { &update_backup; }
	elsif (($auto_options[1] eq 'biweekly') && (($mday == 1) || ($mday == 15))) { &update_backup; }
	elsif (($auto_options[1] eq 'monthly') && ($mday == 1)) { &update_backup; }
}

exit(0);

################################################
## Backup member database
################################################

sub update_backup {
	my ($tarfile, $success);

	## Get filename to put backup
	$tarfile = "$datadir/backup/$date.tar";
	if (-e "$tarfile.gz") { return &update_error("A backup of the database has already been created today"); }

	## Put database into a .tar.gz file
	$success = chdir "$datadir";
	if ($success == 0) { return &update_error("Unable to change to the directory, $datadir"); }
	system("$cmds[2] -cf $tarfile --exclude=backup ./");
	system("$cmds[3] $tarfile");
	
	## Finish up the backup
	if (-e $tarfile) { &deletefile($tarfile); }
	if (!-e "$tarfile.gz") { return &update_error("Unable to backup member database"); }
	
	return 1;
}

################################################
## Give off an update error
################################################

sub update_error {
	my $error = shift;
	my $message;
	
	## Create the e-mail message
	$message = "Subject: [\U$SCRIPT\E v$VERSION] Update Error\n";
	$message .= "Content-type: text/plain\n\n";
	$message .= "Hello $admin_name, \n\n";
	$message .= "An error occured while the script was trying to either, backup your member database ";
	$message .= "or complete another automatic feature.  The following error was reported\n";
	$message .= "\n========================================\n\n";
	$message .= "$error\n\n========================================\n\n";
	$message .= "$in{'SCRIPT_TITLE'} v$VERSION\n\n";
	
	## Send the e-mail message
	$in{'_TO'} = $admin_email;
	$in{'_FROM_ADDR'} = $admin_email;
	$in{'_FROM_NAME'} = $admin_name;
	$in{'_MESSAGE'} = $message;
	&mailmsg_from_hash(%in);
	
	return 1;
}

