
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

## Load some needed files
require "$cgidir/lib/mail-lib.pl";
require "$cgidir/modules/exec.pl" if -e "$cgidir/modules/exec.pl";

## Set some global variables
$|=1;
$SCRIPT = "ezylist";
$VERSION = "1.0";
$SCRIPT_TITLE = "eZyList Pro";

$SUB='';
$HEADER=0;
$PARSE=0;
$PROC=0;
$ERROR = 0;
$FLOCK = 1;
$MODULE = "";
%ERROR = ( );
%STATUS = ( );
%MODULE = ( );

$in{'SCRIPT_TITLE'} = $SCRIPT_TITLE;
$in{'SCRIPT_VERSION'} = $VERSION;
$in{'SCRIPT_NAME'} = $ENV{'SCRIPT_NAME'};
$in{'QUERY_STRING'} = $ENV{'QUERY_STRING'};

## Parse the form and query string, if needed
$QUERY = $ENV{'QUERY_STRING'};
&parse_form;

## Get module information
&get_module_info;

# Load module library if needed
unless ($MODULE eq 'main') {
	if (-e "$cgidir/modules/$MODULE/load.pl") {
		eval { require "$cgidir/modules/$MODULE/load.pl"; };
		if ($@) { &error(500, __LINE__, __FILE__, "Unable to load module file, <b>$cgidir/moduiles/$MODULE/load.pl"); }
	}
}

## If we need to print the version:
if ($query{'action'} eq 'print_version') {
	print "Content-type: text/plain\n\n";
	print "Script: $SCRIPT\nScript Version: $VERSION\n";
	if (-e "/usr/bin/perl") { print "Path To Perl: /usr/bin/perl\n"; }
	elsif (-e "/usr/local/bin/perl") { print "Path To Perl: /usr/local/bin/perl"; }
	exit(0);
}

## If we're processing
elsif ($query{'action'} eq 'processing') { &processing_refresh; }

# Connect mysql database
if ($dbdriver eq "mysql") {
	if ($ADMIN != 1 || (!exists $in{'discard_db'})) {
		return 1 if $SUB eq 'setup_firsttime2';
		eval { require DBI; };
		if ($@) { &error(102, __LINE__, __FILE__, "DBI.pm"); }
		eval { require "$cgidir/lib/mysql-lib.pl"; };
		if ($@) { &error(500, __LINE__, __FILE__, "Unable to load mysql library, <b>$cgidir/lib/mysql-lib.pl</b>"); }
		$dbh = DBI->connect("DBI:$dbdriver:$dbname:$dbhost", $dbuser, $dbpassword)
		or &error(302, __LINE__, __FILE__, "Unable to connect to $dbname at $dbhost");
	}
}

eval { require "$cgidir/dbs/$dbdriver.pl"; };
if ($@) { &error(500, __LINE__, __FILE__, "Unable to load $dbdriver database library, <b>$cgidir/dbs/$dbdriver.pl</b>"); }

################################################
## Make sure everything is ok at end
################################################

END {
	
	## If needed, close file
	if (defined (fileno 'FILE')) { close 'FILE'; }
	
	## If there's a mail error, report it.
	if ($MAIL_ERROR == 1) {
		my @error;
		push @error, @{$ERROR{'MAIL_INVALID'}};
		push @error, @{$ERROR{'MAIL_SERVER'}};
		&writefile("$datadir/tmp/error.tmp", @error);
		
		print qq~
		<script language="javascript">
			window.open("$cgiurl/error.cgi", "error_window", "height=300px, width=400px, status, scrollbars");
		</script>~;
		$MAIL_ERROR = 0;
	}
	
}

################################################
## Parse form
################################################

sub parse_form {

	## If needed, parse the form
	if ($ENV{'CONTENT_LENGTH'} > 0){
		$PARSE = 1;

		if ($ENV{'CONTENT_TYPE'} =~ m#^multipart/form-data#) {
			eval { require CGI; };
			if ($@) { &error(102, __LINE__, __FILE__, "CGI.pm"); }
			
			my $cgi = new CGI;
			my @names = $cgi->param;
			
			foreach $name (@names) {
				$in{$name} = $cgi->param($name);
			}
			
		} else {
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
	}

	## Parse the query string
	if ($QUERY) {
		@QUERY = split /&/, $QUERY;
		foreach $var (@QUERY) {
			my ($name,$value) = split /\=/, $var;
			$query{$name} = $value;
		}
	}
	
	if (($query{'menu'}) && ($query{'action'})) {
		$SUB = $query{'menu'} . "_" . $query{'action'};
	}

	if ($query{'username'}) {
		$in{'username'} = $query{'username'};
		$PARSE = 1;
	}

	if ($query{'message'}) {
		$in{'message'} = $query{'message'};
		$PARSE = 1;
	}
	return;
}

################################################
## Get module information
################################################

sub get_module_info {
	
	my @info = &readfile("$datadir/dat/modules.dat");
	foreach $line (@info) {
		next if $line eq '';
		my ($mod, $name, $version) = split /::/, $line;
		
		$MODULE{$mod} = $name;
		$MODULE{$mod}{'version'} = $version;
	}
	
	## Set a few variables
	if (!exists $query{'module'}) { $MODULE = "main"; }
	else { $MODULE = $query{'module'}; }
	$in{'MODULE_TITLE'} = $MODULE{$MODULE};
	$in{'MODULE_VERSION'} = $MODULE{$MODULE}{'version'};

}

################################################
## Process the modules
################################################

sub run_modules {
	my $mod_action = shift;

	if (-e "$cgidir/modules/exec.pl") {
		eval { require "$cgidir/modules/exec.pl"; };
		if ($@) { &error(500, __LINE__, __FILE__, "Unable to find required file, <b>$cgidir/modules/exec.pl</b>"); }

		foreach $exec (@{$exec{$mod_action}}) {
			eval { require $exec; };
		}
	}

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
## Parse a template
################################################

sub parse_template {
	my ($template, $mod) = @_;
	my ($html);

	if ($mod ne '') {
		if ($mod eq 'main') { $html = &readfile("$datadir/htmlt/$template"); }
		else { $html = &readfile("$cgidir/modules/$mod/htmlt/$template"); }
	} elsif (($MODULE ne 'main') && ($template ne 'admin/header.htmlt')) {
		$html = &readfile("$cgidir/modules/$MODULE/htmlt/$template");
	} else { $html = &readfile("$datadir/htmlt/$template"); }
	$html =~ s/\n/\0/g;
	
	while ($html =~ /<IF\s(.*?)>.*?<\/IF>/gi) {
		my $var = $1;

		if ($in{"_$var"} != 1) { $html =~ s/<IF\s$var>.*?<\/IF>//i; }
	}

	## Process the reproducing text, if needed
	while ($html =~ /(<REPRODUCE\s(.*?)>(.*?)<\/REPRODUCE>)/gi) {
		my ($num, $total, $rephtml, $newhtml, @tags);
		
		$total = $1;
		@tags = split /\s/, $2;
		# Add reserved characters ?, *...
		push @tags, "interrogation";
		push @tags, "star";
		$rephtml = $3;
		$num = (@{$in{$tags[0]}} - 1);
		
		for $x ( 0 .. $num ) {
			my $temp_html = $rephtml;
			foreach $tag (@tags) {
				if ($tag eq "interrogation") { $value = "?"; }
				elsif ($tag eq "star") { $value = "*"; }
				else { $value = $in{$tag}->[$x]; }
				$temp_html =~ s/~$tag~/$value/gi;
				if ($temp_html =~ /~$tag\_titlecase~/i) { $temp_html =~ s/~$tag\_titlecase~/\u\L$value\E/gi; }
				elsif ($temp_html =~ /~$tag\_lowercase~/i) { $temp_html =~ s/~$tag\_lowercase~/\L$value\E/gi; }
				elsif ($temp_html =~ /~$tag\_uppercase~/i) { $temp_html =~ s/~$tag\_uppercase~/\U$value\E/gi; }
			}
			$newhtml .= $temp_html;
		}
		
		$html =~ s/$total/$newhtml/;
	}
	
	$html =~ s/\0/\n/g;
	
	## Process the styles
	foreach $key (keys %style) {
		while ($html =~ /(<$key(.*?)>)/gi) {
			my ($style, $total, $var);

			$total = $1;
			$style = $style{$key};
			$var = $2;
			
			$style =~ s/~1~/$var/g;
			$html =~ s/$total/$style/gi;
		}
	}
	
	## Process the INCLUDE tags
	while ($html =~ /(<include (.+?)>)/gi) {
		my $temp_html = &parse_template($2);
		$html =~ s/$1/$temp_html/g;
	}

	## Replace all merge fields with appropriate info
	while (($key,$value) = each %in) {
		$html =~ s/~$key~/$value/gi;
	}

	return $html;

}

################################################
## Print off a HTML success page
################################################

sub success {
	$in{'success_message'} = shift;
	$in{'page_title'} = "Success";
	
	if ($ADMIN == 1) { print &parse_template('admin/success.htmlt', 'main'); }
	elsif ($CPANEL == 1) { print &parse_template('cpanel/success.htmlt', 'main'); }
	else { &error(500, __LINE__, __FILE__, "Unable to determine template to be displayed"); }
	
	exit(0);
}

################################################
## Handle an error
################################################

sub error {
	my ($code, $line, $file, @data) = @_;
	my $ok = 0;
	
	## Print the HTML header, if needed
	if (defined (fileno 'FILE')) { close 'FILE'; }
	&print_header;
	
	## Load the error-lib.pl file
	eval { require "$cgidir/lib/error-lib.pl"; };
	if ($@) { print "Unable to find required file, <b>error-lib.pl</b>, which should be located at, <b>$cgidir/lib/error-lib.pl</b>"; exit; }

	## Process the error
	($ok, $in{'err_message'}, $in{'err_reason'}, $in{'err_fixit'}) = &error_handleit($code, @data);
	
	## Process the response from error-lib.pl
	if ($ok == 1) { return; }
	else {
		## Print off the error.htmlt template
		$in{'err_code'} = $code;
		$in{'err_line'} = $line;
		$in{'err_file'} = $file;
		$in{'err_reason'} = 'Not Applicable' if $in{'err_reason'} eq '';
		$in{'err_fixit'} = 'Not Applicable' if $in{'err_fixit'} eq '';

		print &parse_template('admin/error.htmlt', 'main');
		exit(1);
	}

}

################################################
## Print the content header if needed
################################################

sub print_header {
	return if $HEADER == 1;

	if ($query{'type'} eq 'text') { print "Content-type: text/plain\n\n"; }
	else { print "Content-type: text/html\n\n"; }
	$HEADER=1;

	return;

}

################################################
## Start processing
################################################

sub processing_start {
	my ($message, $title, $total) = @_;
	my $text;

	## Write info to tracker file
	$text = "\$percent \= 0\;\n";
	$text .= "\$message \= \"$message\"\;\n";
	$text .= "\$title \= \"$title\"\;\n";
	$text .= "\$total \= $total\;\n";
	$text .= "1\;\n";
	&writefile("$datadir/tmp/proc.tmp", $text);
	
	## Print the processing template
	$in{'percent'} = 0;
	$in{'bar_width'} = 1;
	$in{'process_message'} = $message;
	
	$PROC=1;
	$in{'title'} = $title;
	print &parse_template('admin/processing.htmlt', 'main');

}

################################################
## Refresh the processing page
################################################

sub processing_refresh {

	## Get the needed info from proc.tmp file
	&print_header;
	eval { require "$datadir/tmp/proc.tmp" };
	if ($@) { &error(201, __LINE__, __FILE__, "$datadir/tmp/proc.tmp", "TMP"); }

	## Print the processing template	
	$in{'percent'} = $percent;
	$in{'bar_width'} = ($percent * 2);
	$in{'process_message'} = $message;
	$in{'title'} = $title;
	
	$PROC = 1;
	print &parse_template('admin/processing.htmlt', 'main');
	exit(0);
	
}

################################################
## Update the processing
################################################

sub processing_update {
	my $done = shift;
	my $text;
	
	## Get the needed info from proc.tmp file
	eval { require "$datadir/tmp/proc.tmp" };
	if ($@) { &error(201, __LINE__, __FILE__, "$datadir/tmp/proc.tmp", "TMP"); }
	
	## Create new info
	$percent = sprintf "%.0f", ($total / $done) unless $total == 0;
	$text = "\$percent \= $percent\;\n";
	$text .= "\$message \= \"$message\"\;\n";
	$text .= "\$title \= \"$title\"\;\n";
	$text .= "\$total \= $total\;\n";
	$text .= "1\;\n";

	## Save new info to proc.tmp file
	&writefile("$datadir/tmp/proc.tmp", $text);

	return;
}

################################################
## Finish the processing
################################################

sub processing_finish {
	my $html = shift;
	my $text;
	
	$html =~ s/~/\\~/g;
	$html =~ s/\@/\\\@/g;
	$text = "print qq~$html~\;\n\n";
	$text .= "exit(0)\;\n";
	
	## Save info to proc.tmp file
	&writefile("$datadir/tmp/proc.tmp", $text);

	return;
}

################################################
## Get extension of a user
################################################

sub get_ext {
	my $user = shift;
	
	$DBSUB = $dbdriver . "_get_ext";
	my @exts = &$DBSUB($user);
	return @exts;
}

################################################
## Get some info from a user's profile
################################################

sub get_variable {
	my ($user, @vars) = @_;

	$DBSUB = $dbdriver . "_get_variable";
	return &$DBSUB($user, @vars);
}

################################################
## Copy template file for a user
################################################

sub copy_template {
	my ($user, $template) = @_;

	my $contents = &readfile("$datadir/template/template.$template");
	&writefile("$datadir/$template/$user.$template", $contents);
	
	return;

}

################################################
## Add a log entry
################################################

sub add_log {
	my ($user, $type, @info) = @_;
	my ($id, $count, $log, $logdate, $logtype, $ext, $directive);
	
	## Create the log ID
	$count = (&parse_conf($user, 'log', 'LOG_COUNTER') + 1);
	&edit_conf($user, 'log', 'LOG_COUNTER', $count);
	$count = sprintf "%.3d", $count;
	
	open FILE, "$datadir/dat/loginfo.dat" or &error(201, __LINE__, __FILE__, "$datadir/dat/loginfo.dat", "FILE");
	&lockfile('FILE');
	while (<FILE>) {
		chop;
		($logtype, $ext, $directive) = split /::/, $_;
		last if $logtype eq $type;
	}
	&unlockfile('FILE');
	close FILE;
	
	$id = join "-", $user, $type, $count;
	$logdate = join " ", &getdate;
	$log = join "::", $id, $logdate, @info;
	
	## Write log to files
	&append_conf($user, $ext, $directive, $log);
	
	return $id;
}

################################################
## Delete a log
################################################

sub delete_log {
	my $id = shift;
	my ($x, $log, $user, $type, $num, $logtype, $ext, $directive, @info);
	
	($user, $type, $num) = split /-/, $id;
	open FILE, "$datadir/dat/loginfo.dat" or &error(201, __LINE__, __FILE__, "$datadir/dat/loginfo.dat", "FILE");
	&lockfile('FILE');
	while (<FILE>) {
		chop;
		($logtype, $ext, $directive) = split /::/, $_;
		last if $logtype eq $type;
	}
	&unlockfile('FILE');
	close FILE;
	
	$x=0;
	@info = &parse_conf($user, $ext, $directive);
	foreach $line (@info) {
		my @line = split /::/, $line;
		if ($line[0] eq $id) {
			$log = splice @info, $x, 1;
			last;
		}
	$x++; }
	
	&edit_conf($user, $ext, $directive, (join "\n", @info));
	return $log;

}

################################################
## Check referrers
################################################

sub referrer_check {
	my $ref = $ENV{'HTTP_REFERER'};
	my $ok = 0;
	
	foreach (@refs) {
		if ($ref =~ /^http:\/\/$_/i) { $ok=1; last; }
	}
	
	return $ok;
}

#####################################################
### Read the cookie
#####################################################

sub read_cookie {
	my %cookie;
	foreach (split(/; /, $ENV{'HTTP_COOKIE'})) {
        ($chip,$value) = split /=/;
    	$cookie{$chip} = $value;
    }
	
	return %cookie;
}

################################################
## Parse a user's conf file
################################################

sub parse_conf {
	my ($user, $conf, @options) = @_;
	my ($found, $directive, @contents, %conf);
	
	$found = 0;
	open CONF, "$datadir/$conf/$user.$conf" or &error(201, __LINE__, __FILE__, "$datadir/$conf/$user.$conf", "CONF");
	while (<CONF>) {
		chop;
		next if $_ eq '';
		next if $_ =~ /^\#/;
		
		if ($_ =~ /^\[(.+)?\]/) {
			if ($found == 1) { $conf{$directive} = [ @contents ]; }
			$directive = $1;
			$found = 1;
			splice @contents;
		} elsif ($found == 1) { push @contents, $_; }
	}
	close CONF;

	if (!wantarray) { return $conf{$options[0]}->[0]; }
	elsif (@options == 1) { return @{$conf{$options[0]}}; }
	else { return %conf; }
	
}

################################################
## Edit a user's conf file
################################################

sub edit_conf {
	my ($user, $template, $directive, $newtext) = @_;
	my ($x, $start_row, $spnum, $found, @conf);

	if ($user eq '') { print "FOUND IT.  $template, $directive, $newtext<br><br><br>\n"; }	

	@conf = &readfile("$datadir/$template/$user.$template");
	
	$x=1; $found=0; $spnum=0;
	foreach $line (@conf) {
		if ($found == 1) {
			if ($line =~ /^\[.+\]/) { $found = 2; }
			else { $spnum++; }
		} elsif ($line =~ /^\[$directive\]/i) {
			$start_row = $x;
			$found = 1;
		}
		
		last if $found == 2;
	$x++; }

	$spnum--;	
	splice @conf, $start_row, $spnum, $newtext;
	&writefile("$datadir/$template/$user.$template", @conf);
	
	return;
}

################################################
## Append to a user's conf file
################################################

sub append_conf {
	my ($user, $template, $directive, $text) = @_;
	my ($newtext, @conf);
	
	@conf = &parse_conf($user, $template, $directive);
	push @conf, $text;
	$newtext = join "\n", @conf;
	
	&edit_conf($user, $template, $directive, $newtext);
	return;
}

################################################
## Get random file file one directory
################################################

sub randomfile {
	my ($dir, $mask) = @_;
	my ($i, $file);
	local(*DIR, $_);

	$i = 0;

	opendir DIR, $dir;
	while (defined ($_ = readdir DIR)) {
		/$mask/o or next if defined $mask;
		print "$_\n";
		rand ++$i < 1 and $file = $_;
	}
	closedir DIR;
	return $file;
}

################################################
## Load counter
################################################

sub counter_load {
	my ($file) = shift;
	my $count;

	open COUNTER, $file or &error("Could not load counter $file");
	$count = <COUNTER>;
	close COUNTER;

	return $count;
}

################################################
## Increase counter
################################################

sub counter_increase {
	my ($file) = shift;
	my $count;

	open COUNTER, "+<$file" or &error("Could not increase counter $file");
	&lockfile('COUNTER');
	$count = <COUNTER>;
	$count++;
	seek(COUNTER, 0, 0);
	print COUNTER $count;

	&unlockfile('COUNTER');
	close COUNTER;
}

################################################
## Decrease counter
################################################

sub counter_decrease {
	my ($file) = shift;
	my $count;

	open COUNTER, "+<$file" or &error("Could not decrease counter $file");
	&lockfile('COUNTER');
	$count = <COUNTER>;
	$count--;
	$count = 0 if ($count < 0);
	seek(COUNTER, 0, 0);
	print COUNTER $count;

	&unlockfile('COUNTER');
	close COUNTER;
}

################################################
## Read and return the contents of a file
################################################

sub readfile {
	my $file = shift;
	my ($contents, @contents);

	open FILE, $file or &error(201, __LINE__, __FILE__, $file, "FILE");
	&lockfile('FILE');
	if (wantarray) {
		@contents = <FILE>;
		&unlockfile('FILE');
		close FILE;

		chomp @contents;
		return @contents;
	} else {
		while (<FILE>) { $contents .= $_; }
		&unlockfile('FILE');
		close FILE;
		
		chomp $contents;
		return $contents;
	}

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
## Append to a file
################################################

sub appendfile {
	my ($file, @contents) = @_;
	
	open FILE, ">>$file" or &error(202, __LINE__, __FILE__, $file, "FILE");
	&lockfile('FILE');
	foreach (@contents) { print FILE "$_\n"; }
	&unlockfile('FILE');
	close FILE;
	chmod 0777, $file;
	
	return;
}

################################################
## Delete a file
################################################

sub deletefile {
	my $file = shift;
	my $success;
	
	$success = unlink $file;
	if ($success == 0) { &error(204, __LINE__, __FILE__, $file); }

	return;

}

################################################
## Replace a line in a file
################################################

sub replace_fileline {
	my ($file, $opr, $search, $replace) = @_;
	my ($x, $ok, @contents);
	
	$x=0; $ok=0;
	@contents = &readfile($file);
	foreach $line (@contents) {
		if ((lc($opr) eq 'equal') && ($line eq $search)) {
			splice @contents, $x, 1, "$replace\n";
			$ok=1; last;
		} elsif ((lc($opr) eq 'begin') && ($line =~ /^$search/)) {
			splice @contents, $x, 1, "$replace\n";
			$ok=1; last;
		} elsif ((lc($opr) eq 'end') && ($line =~ /$search$/)) {
			splice @contents, $x, 1, "$replace\n";
			$ok=1; last;
		}
	$x++; }
	
	&writefile($file, @contents);
	return $ok;

}

################################################
## Delete a line in a file
################################################

sub delete_fileline {
	my ($file, $opr, $search) = @_;
	my ($x, $ok, @contents);
	
	$x=0; $ok=0;
	@contents = &readfile($file);
	foreach $line (@contents) {
		if ((lc($opr) eq 'equal') && ($line eq $search)) {
			splice @contents, $x, 1;
			$ok=1; last;
		} elsif ((lc($opr) eq 'begin') && ($line =~ /^$search/)) {
			splice @contents, $x, 1;
			$ok=1; last;
		} elsif ((lc($opr) eq 'end') && ($line =~ /$search$/)) {
			splice @contents, $x, 1;
			$ok=1; last;
		}
	$x++; }
	
	&writefile($file, @contents);
	return $ok;
	
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
## Upload file
################################################

sub uploadfile {
	my ($name, $savefile) = @_;
	my ($cgi, $filehandle, $lenth, $buffer, $size, $success);

	$cgi = new CGI;
	$filehandle = $cgi->upload($name);
	$success = 1;
	open FILE, ">$savefile" or &error(203, __LINE__, __FILE__, $savefile, "FILE");
	&lockfile('FILE');
	binmode $filehandle;
	binmode FILE;
	while (1) {
		$size = sysread($filehandle, $buffer, 1024);
		if (!defined $size || $size < 0) {
			&unlockfile('FILE');
			&error(500, __LINE__, __FILE__, "Unable to import image");
		}
		elsif ($size == 0) { $success = 0; last; }
		else { syswrite(FILE, $buffer, $size); $length += $size; }
	}
	&unlockfile('FILE');
	close FILE;

	chmod 0777, $savefile;
	if ($success == 1) { return $length; }
	else { return; }
}

################################################
## Parse a directory, and return contents
################################################

sub parsedir {
	my ($rootdir, $getdir) = @_;
	my ($subdir, @dirs, @results);

	$subdir = '';
	push @dirs, '';

	while (@dirs) {
		my ($dir, @files);
		$dir = shift @dirs;

		opendir DIR, "$rootdir/$dir" or &error(206, __LINE__, __FILE__, "$rootdir/$dir", "DIR");
		@files = grep !/^\.\.?$/, readdir (DIR);
		closedir DIR;
		
		$subdir = "$dir/" unless $dir eq '';
		foreach $file (@files) {
			if (-f "$rootdir/$subdir$file") { push @results, $subdir.$file; }
			elsif (-d "$rootdir/$subdir$file") {
				push @results, $subdir.$file if $getdir == 1;
				push @dirs, $subdir.$file;
			}
		}
	}	
	
	return @results;
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
	
			open MKDIR, "|$cmds[0] $dir" or &error(207, __LINE__, __FILE__, $dir);
			print MKDIR $dir;
			close MKDIR;
		}	
	}

	chmod 0777, $dir;
	if (!-d $dir) { &error(207, __LINE__, __FILE__, $dir); }

	return;
}

################################################
## Remove a directory
################################################

sub removedir {
	my $dir = shift;
	my ($success, @files);
	
	## Get a list of all files inside dir
	@files = &parsedir($dir, 1);
	
	## Delete all files inside dir
	foreach $file (@files) {
		next if -d "$dir/$file";
		&deletefile("$dir/$file");
	}
	
	## Delete all directories inside dir
	unshift @files, '';
	while (@files) {
		my $file = pop @files;
		next if !-d "$dir/$file";

		my $deletedir = "$dir/$file";
		if ($^O =~ /Win/) { $deletedir =~ s/\//\\/g; }		

		$success = rmdir ("$deletedir");
		
		if ($success == 0) {
			open RMDIR, "|$cmds[1] $deletedir" or &error(208, __LINE__, __FILE__, "$deletedir");
			print RMDIR "$deletedir";
			close RMDIR;
		}
		if (-d $deletedir) { &error(208, __LINE__, __FILE__, $deletedir); }
	}

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

################################################
## Get the date and time
################################################

sub getdate {
	my ($date, $time);
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
	$mon++;
	
	$sec = sprintf "%.2d", $sec;
	$min = sprintf "%.2d", $min;
	$hour = sprintf "%.2d", $hour;
	
	$year -= 100;
	$year = sprintf "%.3d", $year;
	$year = "2" . $year;

	$date = join "-", $mon, $mday, $year;
	$time = join ":", $hour, $min, $sec;
	
	return ($date, $time);

}

################################################
## Format the date
################################################

sub format_date {
	my $date = shift;
	my ($month, $mday, $year) = split /-/, $date;
	my $newdate;

	if ($moptions[4] == 1) { 
		$year =~ s/^..//;
		$newdate = join "/", $month, $mday, $year;
	} elsif ($moptions[4] == 2) { 
		my @months = qw (space Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
		$newdate = join "-", $months[$month], $mday, $year;
	} elsif ($moptions[4] == 3) {
		my @months = qw (space January February March April May June July August September October November December);
		$newdate = "$months[$month] $mday, $year";
	} else { $newdate = $date; }
	
	return $newdate;
}

################################################
## Translate the date
################################################

sub num2date {
	my $days = shift;
	my ($x, $month, $year, $date, @months);

	@months = qw (31 28 31 30 31 30 31 31 30 31 30 31);
	while ($days > 364) { $year++; $days -= 365; }

	$x=0;
	while (1) {
		if ($days <= $months[$x]) { last; }
		else {
			$month++;
			$days -= $months[$x];
		}
	$x++; }
	$month++;
	$days = 1 if $days <= 0;

	$date = join "-", $month, $days, $year;
	return $date;
}

################################################
## Translate the date
################################################

sub translate_date {
	my $date = shift;
	my ($month, $mday, $year, $days, @months);

	($month, $mday, $year) = split /-/, $date;
	@months = qw (31 28 31 30 31 30 31 31 30 31 30 31);
	$month -= 2;
	
	for $x ( 0 .. $month ) {
		$days += $months[$x];
	}
	$days += $mday;
	$days += ($year * 365);

	return $days;

}

################################################
## Display all accounts
################################################

sub display_all_accounts {
	$in{'title'} = shift;
	my ($usernum, $x, $num, $DBSUB, @userinfos);

	$DBSUB = $dbdriver . "_fetch_accounts";
	@userinfos = &$DBSUB($in{'username'}, $in{'display_all_accounts'});
	$num = @userinfos;

	for $x (0 .. ($num-1)) {
		push @{$in{'rusername'}}, $userinfos[$x][0];
		push @{$in{'rname'}}, $userinfos[$x][$dbfields[0]];
		push @{$in{'remail'}}, $userinfos[$x][$dbfields[1]];
		push @{$in{'rstatus'}}, $userinfos[$x][$extfield];
		push @{$in{'rtype'}}, $userinfos[$x][$extfield+1];
	}
	
	&error(500, __LINE__, __FILE__, "No member exist.") if ($num == 0);
	$in{'_canaction'} = 1 if ($num > 0);
	&print_header;
	print &parse_template('admin/display_all_accounts.htmlt', 'main');
	exit(0);
}

################################################
## Format an advertisement
################################################

sub format_advertisement {
	my ($swf, $contents) = @_;
	my $advertisement;

	if ($swf == 1) { $advertisement = "Content-type: application/x-shockwave-flash\n"; }
	else { $advertisement = "Content-type: image/gif\n"; }

	$contents =~ s/[\r\f]//gi;
	$advertisement .= "\n" . $contents;

	return $advertisement;
}

################################################
## Format an e-mail message
################################################

sub format_message {
	my ($html, $subject, $contents) = @_;
	my $message;

	$message = "Subject: $subject\n";
	if ($html == 1) { $message .= "Content-type: text/html\n"; }
	else { $message .= "Content-type: text/plain\n"; }

	$contents =~ s/[\r\f]//gi;
	$message .= "\n" . $contents;

	return $message;
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

1;

