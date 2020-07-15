
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
## Create a advertisement
################################################

sub ad_create {
	my ($user, $status, $type, %conf);

	## Make sure user exists
	$user = $in{'username'};
	($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type ne "advertiser") { &error(500, __LINE__, __FILE__, "User is not advertiser, <b>$user</b>"); }

	## Figure out what to do
	if ($in{'step'} eq 'submit') {
		my ($x, $y, $ad, $index, $buffer, $image, $imagefile);
		
		## Peform a few checks
		if ($in{'name'} eq '') { &error(500, __LINE__, __FILE__, "You did not specify a name for the advertisement"); }
		if ($in{'image'} eq '') { &error(500, __LINE__, __FILE__, "You did not provide the image banner for the advertisement"); }

		## Create and format the advertisement
		$ad = &format_advertisement($in{'_swf'}, $in{'contents'});
		$ad = "Advertisement\n" . $ad;
	
		## Save the message to the server
		$x=1;
		$x++ while -e "$datadir/ad/$user/$x.ad";
		if ($x > 10) { &error(500, __LINE__, __FILE__, "You can not create more than 10 advertisements"); }
		&writefile("$datadir/ad/$user/$x.ad", $ad);
		&writefile("$datadir/ad/$user/$x.link", $in{'link'});
		&writefile("$datadir/ad/$user/$x.displayed", "0");
		&writefile("$datadir/ad/$user/$x.clicked", "0");

		## If needed, get the image
		if ($in{'image'} ne '') {
			my ($file, $size) = @_;

			$file = "$datadir/ad/$user/$x.img";
			&uploadfile('image', $file);

			if ($in{'image'} =~ /\\/) { ($imagefile) = $in{'image'} =~ /.*\\(.*)/; }
			elsif ($in{'image'} =~ /\//) { ($imagefile) = $in{'image'} =~ /.*\/(.*)/; }
			else { $imagefile = $in{'image'}; }
		}
		
		## Add index for this advertisement
		$y = ezylist_save_adindex($user, "$x.ad");

		## Create line for index.dat file
		$index = join "::", 'advertisement', $in{'name'}, "$x.ad", $imagefile, "$y.ad", $in{'_swf'};
		&appendfile("$datadir/ad/$user/index.dat", $index);

		## Print off HTML success text
		&success("Successfully created the advertisement, <b>$in{'name'}</b>");

	} else {
		## Print HTML template
		print &parse_template('admin/ad/create.htmlt');
		exit(0);
	}

}

################################################
## Manage advertisement
################################################

sub ad_manage {
	my ($user, $status, $type);

	if (exists $in{'confirm'} || (exists $in{'ad_id'} && (exists $in{'action'}))) {
		## Redirect actions
		$SUB = $query{'menu'} . "_" . $in{'action'};
		&$SUB;
		exit(0);
	} elsif (!exists $in{'ad_id'}) {
		$in{'title'} = "Manage Advertisement"; &print_header; 
		&ezylist_get_adhtml($in{'username'});
		## Get available actions, should from a data file
		push @{$in{'action'}}, "edit";
		push @{$in{'action'}}, "delete";
		&print_header;
		print &parse_template('admin/ad/manage.htmlt', 'main');
		exit(0);
	} else { &error(500, __LINE__, __FILE__, "No action selected for user, <b>$user</b>"); }

	## Make sure user exists
	$user = $in{'username'};
	($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type ne "advertiser") { &error(500, __LINE__, __FILE__, "User is not advertiser, <b>$user</b>"); }
}

################################################
## Edit advertisement
################################################

sub ad_edit {
	my ($user, %info, $ad_id, $swf, $num, $linkfile, @content);

	## Make sure user exists
	$user = $in{'username'};
	($status, $type) = &get_ext($user);
	if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
	if ($type ne "advertiser") { &error(500, __LINE__, __FILE__, "User is not advertiser, <b>$user</b>"); }

	## Get needed info
	$ad_id = $in{'ad_id'};
	($num) = $ad_id =~ /^(\d+)\..+/;
	%info = ezylist_get_adinfo($user);

	if ($in{'step'} eq 'submit') {
		my ($swf, $ad, $global_index, $name, $x, @index);

		## Perform a few checks
		if ($ad_id eq '') { &error(500, __LINE__, __FILE__, "You did not select an advertisement to edit"); }
		$global_index = $info{$ad_id}{'index'};
		$name = $info{$ad_id}{'name'};

		## Create and format the advertisement
		$ad = &format_advertisement($in{'swf'}, $in{'contents'});
		$ad = "Advertisement\n" . $ad;

		## Save the message to the server
		&writefile("$datadir/ad/$user/$ad_id", $ad);
		&writefile("$datadir/ad/$user/$num.link", $in{'link'});

		## If needed, get the image
		if ($in{'image'} ne '') {
			my ($file, $size) = @_;

			$file = "$datadir/ad/$user/$num.img";
			&deletefile($file);
			&uploadfile('image', $file);

			if ($in{'image'} =~ /\\/) { ($imagefile) = $in{'image'} =~ /.*\\(.*)/; }
			elsif ($in{'image'} =~ /\//) { ($imagefile) = $in{'image'} =~ /.*\/(.*)/; }
			else { $imagefile = $in{'image'}; }
		} else {
			$imagefile = $info{$ad_id}{'image'};
		}

		## Create line for index.dat file
		$index = join "::", 'advertisement', $name, $ad_id, $imagefile, $global_index, $in{'swf'};

		$x=0;
		@index = &readfile("$datadir/ad/$user/index.dat");
		foreach $line (@index) {
			my @line = split /::/, $line;
			if ($line[2] eq $ad_id) {
				$index[$x] = $index;
				last;
			}
		$x++; }
		&writefile("$datadir/ad/$user/index.dat", @index);

		## Print off HTML success text
		&success("Successfully edited the selected follow up message");
	} elsif ($in{'step'} eq 'getad') {

		## Get and parse message
		@content = &readfile("$datadir/ad/$user/$ad_id");
		shift @content;
		$in{'name'} = $info{$ad_id}{'name'};
		$in{'image'} = $info{$ad_id}{'image'};
		$in{'link'} = &readfile("$datadir/ad/$user/$num.link");
		$swf = (shift @content);

		## Format a few variables
		$in{'contents'} = join "\n", @content;
		$in{'contents'} =~ s/^\n//;
		if ($swf =~ /x-shockwave-flash/) { $in{'swf'} = "checked"; }
		else { $in{'swf'} = ""; }

		## Print HTML template
		print &parse_template('admin/ad/edit.htmlt');
		exit(0);
	}
}

################################################
## Delete an advertisement
################################################

sub ad_delete {

	## Figure out what to do
	if (exists $in{'confirm'}) {
		my ($x, $user, $ad_id, $name, $num, $index, @index);

		## Get needed info
		($user, $ad_id) = split /::/, $in{'confirm_data'};
		if ($in{'confirm'} == 0) { &success("Did not delete the selected advertisement"); }

		## Delete advertisement from index.dat file
		$x=0;
		@index = &readfile("$datadir/ad/$user/index.dat");
		foreach $line (@index) {
			my @line = split /::/, $line;
			if ($line[2] eq $ad_id) {
				$name = $line[1];
				$index = $line[4];
				splice @index, $x, 1;
				last;
			}
		$x++; }

		## Delete advertisement from server
		($num) = $ad_id =~ /^(\d+)\..+/;
		&writefile("$datadir/ad/$user/index.dat", @index);
		&deletefile("$datadir/ad/$user/$ad_id");
		&deletefile("$datadir/ad/$index");
		&deletefile("$datadir/ad/$user/$num.img");
		&deletefile("$datadir/ad/$user/$num.link");
		&deletefile("$datadir/ad/$user/$num.clicked");
		&deletefile("$datadir/ad/$user/$num.displayed");

		## Print off HTML success page
		&success("Successfully deleted the follow up message, <b>$name</b>");
	} elsif ($in{'step'} eq 'getad') {
		my ($user, %info);

		## Make sure user exists
		$user = $in{'username'};
		($status, $type) = &get_ext($user);
		if (!$status || !$type ) { &error(500, __LINE__, __FILE__, "User does not exist, <b>$user</b>"); }
		if ($type ne "advertiser") { &error(500, __LINE__, __FILE__, "User is not advertiser, <b>$user</b>"); }
		%info = &ezylist_get_adinfo($user);

		if ($in{'ad_id'} eq '') { &error(500, __LINE__, __FILE__, "You did not select an advertisement to delete"); }

		$in{'page_title'} = "Delete Advertisement";
		$in{'confirm_data'} = (join "::", $user, $in{'ad_id'});
		$in{'confirm_text'} = "Are you sure you want to delete the follow up advertisement, <b>$info{$in{'ad_id'}}{'name'}</b>?";
		print &parse_template('admin/confirm.htmlt');
		exit(0);
	}
}

1;



