
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

package encrypt;

#####################################################
## Initizialize a new encryption object
#####################################################

sub new {
	my ($key) = @_;
	my ($length);

	## Make sure key is valid
	$length = length($key);
	if (($length < 24) || ($length > 256)) { return undef; }

	return (bless \$key);

}

#####################################################
## Encrypt some text
#####################################################

sub encrypt {
	my ($key, $text) = @_;
	my ($encrypt, $decrypt, @text, @key, @decrypt);

	@key = split //, $$key;
	@text = split //, $text;

	foreach $char (@text) {
		my ($rand, $right, $left, $var);

		## Create random number for right side
		$rand = rand (length($$key));
		$rand =~ s/\..+$//;
		redo if !$key[$rand];

		## Create the encryption var
		if ($char =~ /\d|\W/) { $right = pack ("C", $rand); }
		else { $right = pack ("H", $rand); }
		$left = ($char ^ $right);
		$var = join "", $left, $right;
		redo if $var =~ /[\n\r]/;

		$encrypt .= $var;
	}

	## Make sure it's encrypted right
	$decrypt = $key->decrypt($encrypt);
	@decrypt = split //, $decrypt;

	$x=0;
	foreach $char (@text) {
		if ($char ne $decrypt[$x]) { &encrypt($key, $text); }
	$x++; }

	return $encrypt;
}

#####################################################
## Decrypt some text
#####################################################

sub decrypt {
	my ($key, $text) = @_;
	my ($decrypt, @text);
	@text = split //, $text;

	while (@text) {
		my ($left, $right, $char);
		
		$left = unpack("a", (shift @text));
		$right = shift @text;
		$char = ($left ^ $right);

		$decrypt .= $char;
	}

	return $decrypt;
}

1;
