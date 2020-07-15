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
if ($@) { print "Content-type: text/html\n\nUnable to find required file, <b>ezylist.conf</b>, which should be located at, <b>$conf</b>"; exit; }
eval { require CGI; };
if ($@) { print "Content-type: text/html\n\nUnable to load perl module, <b>CGI.pm</b>"; exit; }

## query string, if needed
$QUERY = $ENV{'QUERY_STRING'};
%query;

&parse_query;

if ($query{'action'} eq "click") {

	if (exists $query{'user'} && (exists $query{'link'})) {
		my ($user, $link, $num);

		$user = $query{'user'};
		$link = $query{'link'};
		($num) = $link =~ /^(\d+)\..+/;
		$url = &readfile("$datadir/ad/$user/$link");

		## Count clicking
		counter_increase("$datadir/ad/$user/$num.clicked");

		## Redirect to the registered site
		&redirect($url);
	} else { &error("Not supported query"); }

} elsif ($query{'action'} eq "display") {

	if (exists $query{'user'} && (exists $query{'ad'})) {
		my ($user, $type, $ad, $image, $imagefile, %adinfo, $cgi);

		$user = $query{'user'};
		$ad = $query{'ad'};
		($num) = $ad =~ /^(\d+)\..+/;
		%info = ezylist_get_adinfo($user);

		$imagefile = $info{$ad}{'image'};
		$image = "$datadir/ad/$user/$num.img";

		if (!defined $imagefile || $imagefile eq "") { &notfound; }
		$type = &content_type($imagefile);

		## HTTP response
		print "Content-type: $type\n\n";
		## Return image
		&downloadfile($image);
	} else {
		&notfound;
	}

} else { &error("Not supported query"); }


## Exit program
exit(0);


################################################
## Get content type
################################################

sub content_type {
	my ($file) = shift;
	my ($type, $content, $cgi);

	($type) = $file =~ /\.(\w+)$/;
	$type eq "jpg" and $type = "jpeg";

	if ($type eq "swf") { $content = "application/x-shockwave-flash"; }
	else { $content = "image/$type"; }

	return $content;
}

################################################
## Not found
################################################

sub notfound {
	my $cgi = new CGI;
	$cgi->header(-status => "404 Not Found");
	&error("<b>404 Not Found</b>");
}

################################################
## Redirect browser
################################################

sub redirect {
	my $link = shift;

	$cgi = new CGI;
	print $cgi->redirect(-location=>$link);
}

################################################
## Parse the query string
################################################

sub parse_query {
	## Parse the query string
	if ($QUERY) {
		@QUERY = split /&/, $QUERY;
		foreach $var (@QUERY) {
			my ($name, $value) = split /\=/, $var;
			$query{$name} = $value;
		}
	}
}

################################################
## Download a file
################################################

sub downloadfile {
	my ($loadfile) = @_;
	my ($lenth, $buffer, $size, $success);

	$success = 1;
	open FILE, "$loadfile" or &notfound;
	binmode STDOUT;
	binmode FILE;
	print <FILE>;
	close FILE;

	if ($success == 1) { return $length; }
	else { return; }
}

################################################
## Read and return the contents of a file
################################################

sub readfile {
	my $file = shift;
	my ($contents, @contents);

	open FILE, $file or &error("Unable to open file $file");
	if (wantarray) {
		@contents = <FILE>;
		close FILE;

		chomp @contents;
		return @contents;
	} else {
		while (<FILE>) { $contents .= $_; }
		close FILE;
		
		chomp $contents;
		return $contents;
	}

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

################################################
## Increase counter
################################################

sub counter_increase {
	my ($file) = shift;
	my $count;

	open COUNTER, "+<$file" or &error("Could not count $file");
	&lockfile('COUNTER');
	$count = <COUNTER>;
	$count++;
	seek(COUNTER, 0, 0);
	print COUNTER $count;

	&unlockfile('COUNTER');
	close COUNTER;
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
## Get user's advertisement info
################################################

sub ezylist_get_adinfo {
	my $user = shift;
	my (@adinfo, %info);

	## Get needed info
	return undef if !-e "$datadir/ad/$user/index.dat";
	@adinfo = &readfile("$datadir/ad/$user/index.dat");

	## Parse through the list info
	foreach $line (@adinfo) {
		next if $line eq '';
		my ($type, $name, $file, $image, $index, $swf) = split /::/, $line;
		$info{$file}{'type'} = $type;
		$info{$file}{'name'} = $name;
		if ($type eq 'advertisement') {
			$info{$file}{'name'} = $name;
			$info{$file}{'image'} = $image;
			$info{$file}{'index'} = $index;
			$info{$file}{'swf'} = $swf;
		}
	}

	## Return advertisement info
	return %info;

}
