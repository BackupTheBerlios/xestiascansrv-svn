#################################################################################
# Xestia Scanner Server Database Module - PostgreSQL Database Module		#
# Database module for mainipulating data in a PostgreSQL database.		#
#										#
# Copyright (C) 2010-2011 Steve Brokenshire <sbrokenshire@xestia.co.uk>		#
#										#
# This module is licensed under the same license as Xestia Scanner Server which #
# is the GPL version 3.								#
#										#
# This program is free software: you can redistribute it and/or modify		#
# it under the terms of the GNU General Public License as published by		#
# the Free Software Foundation, version 3 of the License.			#
#										#
# This program is distributed in the hope that it will be useful,		#
# but WITHOUT ANY WARRANTY; without even the implied warranty of		#
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the			#
# GNU General Public License for more details.					#
#										#
# You should have received a copy of the GNU General Public License		#
# along with this program.  If not, see <http://www.gnu.org/licenses/>.		#
################################################################################# 

# Define the package (perl module) name.

package Modules::Auth::PostgreSQL;

# Enable strict and use warnings.

use strict;
use warnings;
use Encode;
use Digest;
use utf8;

# Load the following Perl modules.

use DBI qw(:sql_types);

# Set the following values.

our $VERSION 	= "0.1.0";
my ($options, %options);
my $database_handle;
my $statement_handle;
my $error;
my $errorext;
my $database_filename;
my $second_database_filename;

#################################################################################
# Generic Subroutines.								#
#################################################################################

sub new{
#################################################################################
# new: Create an instance of the PostgreSQL module.				#
# 										#
# Usage:									#
#										#
# $dbmodule = PostgreSQL->new();						#
#################################################################################
	
	# Get the perl module name.

	my $class = shift;
	my $self = {};

	return bless($self, $class);

}

sub capabilities{
#################################################################################
# capabilities: Get the capabilities for this module as a hash.			#
#										#
# Usage:									#
#										#
# $dbmodule->capabilities();							#
#################################################################################
	
	my $class = shift;
	
	my %capabilities = (
		"multiuser"	=> 1,
	);
	
	return %capabilities; 
	
}

sub loadsettings{
#################################################################################
# loadsettings: Loads settings into the PostgreSQL authentication module	#
#										#
# Usage:									#
#										#
# $dbmodule->loadsettings(options);						#
#										#
# options	Specifies the following options (in any order).			#
#										#
# DateTime	Specifies the date and time format to use.			#
# Server	Specifies the server to use.					#
# Database	Specifies the database to use.					#
# Username	Specifies the username to use.					#
# Password	Specifies the password to use.					#
# Port		Specifies the server port to use.				#
# Protocol	Specifies the protocol to use.					#
# TablePrefix	Specifies the table prefix to use.				#
#################################################################################

	# Get the data passed to the subroutine.

	my $class = shift;
	my ($passedoptions)	= @_;

	# Add the directory setting to the list of options (as it's the only
	# one needed for this database module).

	%options = (
		"Directory" 	=> $passedoptions->{"Directory"},
		"DateTime"	=> $passedoptions->{"DateTime"},
		"Server"	=> $passedoptions->{"Server"},
		"Database"	=> $passedoptions->{"Database"},
		"Username"	=> $passedoptions->{"Username"},
		"Password"	=> $passedoptions->{"Password"},
		"Port"		=> $passedoptions->{"Port"},
		"Protocol"	=> $passedoptions->{"Protocol"},
		"TablePrefix"	=> $passedoptions->{"TablePrefix"}
	);

}

sub convert{
#################################################################################
# convert: Converts data into SQL formatted data.				#
#										#
# Usage:									#
#										#
# $dbmodule->convert(data);							#
#										#
# data		Specifies the data to convert.					#
#################################################################################

	# Get the data passed to the subroutine.

	my $class	= shift;
	my $data	= shift;

	if (!$data){
		$data = "";
	}

	$data =~ s/\'/''/g;
	$data =~ s/\b//g;

	return $data;

}

sub dateconvert{
#################################################################################
# dateconvert: Converts a SQL date into a proper date.				#
#										#
# Usage:									#
#										#
# $dbmodule->dateconvert(date);							#
#										#
# date		Specifies the date to convert.					#
#################################################################################

	# Get the date passed to the subroutine.

	my $class 	= shift;
	my $data	= shift;

	# Convert the date given into the proper date.

	# Create the following varialbes to be used later.

	my $date;
	my $time;
	my $day;
	my $day_full;
	my $month;
	my $month_check;
	my $month_full;
	my $year;
	my $year_short;
	my $hour;
	my $hour_full;
	my $minute;
	my $minute_full;
	my $second;
	my $second_full;
	my $seek = 0;
	my $timelength;
	my $datelength;
	my $daylength;
	my $secondlength;
	my $startchar = 0;
	my $char;
	my $length;
	my $count = 0;

	# Split the date and time.

	$length = length($data);

	if ($length > 0){

		do {

			# Get the character and check if it is a space.

			$char = substr($data, $seek, 1);

			if ($char eq ' '){

				# The character is a space, so get the date and time.

				$date 		= substr($data, 0, $seek);
				$timelength	= $length - $seek - 1;
				$time 		= substr($data, $seek + 1, $timelength);

			}

			$seek++;

		} until ($seek eq $length);

		# Get the year, month and date.

		$length = length($date);
		$seek = 0;

		do {

			# Get the character and check if it is a dash.

			$char = substr($date, $seek, 1);

			if ($char eq '-'){

				# The character is a dash, so get the year, month or day.

				$datelength = $seek - $startchar;

				if ($count eq 0){

					# Get the year from the date.

					$year		= substr($date, 0, $datelength) + 1900;
					$startchar	= $seek;
					$count = 1;

					# Get the last two characters to get the short year
					# version.

					$year_short	= substr($year, 2, 2);

				} elsif ($count eq 1){

					# Get the month and day from the date.

					$month 	= substr($date, $startchar + 1, $datelength - 1) + 1;

					# Check if the month is less then 10, if it is
					# add a zero to the value.

					if ($month < 10){

						$month_full = '0' . $month;

					} else {

						$month_full = $month;

					}

					$startchar	= $seek;
					$count = 2;

					$daylength	= $length - $seek + 1;
					$day		= substr($date, $startchar + 1, $daylength);

					$day =~ s/^0//;

					# Check if the day is less than 10, if it is
					# add a zero to the value.

					if ($day < 10){

						$day_full 	= '0' . $day;

					} else {

						$day_full	= $day;

					}

				}

			}

			$seek++;

		} until ($seek eq $length);

		# Get the length of the time value and reset certain
		# values to 0.

		$length = length($time);
		$seek = 0;
		$count = 0;
		$startchar = 0;

		do {

			# Get the character and check if it is a colon.

			$char = substr($time, $seek, 1);

			if ($char eq ':'){

				# The character is a colon, so get the hour, minute and day.

				$timelength = $seek - $startchar;

				if ($count eq 0){

					# Get the hour from the time.

					$hour = substr($time, 0, $timelength);
					$hour =~ s/^0//;
					$count = 1;
					$startchar = $seek;

					# If the hour is less than ten then add a
					# zero.

					if ($hour < 10){

						$hour_full = '0' . $hour;

					} else {

						$hour_full = $hour;

					}

				} elsif ($count eq 1){

					# Get the minute and second from the time.

					$minute = substr($time, $startchar + 1, $timelength - 1);
					$minute =~ s/^0//;
					$count = 2;
						
					# If the minute is less than ten then add a
					# zero.

					if ($minute < 10){

						$minute_full = '0' . $minute;

					} else {

						$minute_full = $minute;

					}

					$startchar = $seek;

					$secondlength = $length - $seek + 1;
					$second = substr($time, $startchar + 1, $secondlength);
					$second =~ s/^0//;
					
					# If the second is less than ten then add a
					# zero.

					if ($second < 10){

						$second_full = '0' . $second;

					} else {

						$second_full = $second;

					}

				}

			}

			$seek++;

		} until ($seek eq $length);

		# Get the setting for displaying the date and time.

		$data = $options{"DateTime"};

		# Process the setting for displaying the date and time
		# using regular expressions

		$data =~ s/DD/$day_full/g;
		$data =~ s/D/$day/g;
		$data =~ s/MM/$month_full/g;
		$data =~ s/M/$month/g;
		$data =~ s/YY/$year/g;
		$data =~ s/Y/$year_short/g;

		$data =~ s/hh/$hour_full/g;
		$data =~ s/h/$hour/g;
		$data =~ s/mm/$minute_full/g;
		$data =~ s/m/$minute/g;
		$data =~ s/ss/$second_full/g;
		$data =~ s/s/$second/g;

	}

	return $data;

}

sub geterror{
#################################################################################
# geterror: Gets the error message (or extended error message).			#
#										#
# Usage:									#
#										#
# $dbmodule->geterror(extended);						#
#										#
# Extended	Specifies if the extended error should be retrieved.		#
#################################################################################

	# Get the data passed to the subroutine.

	my $class	= shift;
	my $extended	= shift;

	if (!$extended){
		$extended = 0;
	}

	if (!$errorext){
		$errorext = "";
	}

	if (!$error){
		$error = "";
	}

	# Check to see if extended information should be returned.

	if ($extended eq 1){

		# Extended information should be returned.

		return $errorext;

	} else {

		# Basic information should be returned.

		return $error;

	}

}

#################################################################################
# General subroutines.								#
#################################################################################

sub connect{
#################################################################################
# connect: Connect to the server.						#
#										#
# Usage:									#
#										#
# $dbmodule->connect();								#
#################################################################################

	$error = "";
	$errorext = "";

	# Connect to the server.

	$database_handle = DBI->connect("DBI:Pg:dbname=" . $options{"Database"} . ";host=" . $options{"Server"} . ";port=" . $options{"Port"}, $options{"Username"}, $options{"Password"}) or ( $error = "AuthConnectionError", $errorext = DBI->errstr, return );
	$database_handle->do("SET CLIENT_ENCODING TO 'UTF8'");
	#$database_handle->do('SET NAMES utf8');

}

sub disconnect{
#################################################################################
# connect: Disconnect from the server.						#
#										#
# Usage:									#
#										#
# $dbmodule->disconnect();							#
#################################################################################
	
	# Disconnect from the server.

	if ($statement_handle){

		$statement_handle->finish();

	}

	if ($database_handle){

		$database_handle->disconnect();

	}

}

sub getuserlist{
#################################################################################
# getuserlist: Get the user list.						#
#										#
# Usage:									#
#										#
# $dbmodule->getuserlist(options);						#
#										#
# options	Specifies the following options in any order.			#
#										#
# Reduced		Gets a reduced version of the user list.		#
# ShowDeactivated	Show users that are deactivated from the list.		#
#################################################################################

	$error = "";
	$errorext = "";

	# Get the values passed to the subroutine.

	my $class = shift;
	my ($passedoptions) = @_;
	my $sqlquery = "";
	my @user_data;
	my %user_list;
	my $user_seek = 1;

	tie(%user_list, 'Tie::IxHash');

	my $reduced_list	= $passedoptions->{"Reduced"};
	my $deactivated_show	= $passedoptions->{"ShowDeactivated"};
	$deactivated_show = 0 if !$passedoptions->{"ShowDeactivated"};

	# Check if a reduced version of the user list should be retreived.

	if ($reduced_list eq 1){

		# Get the list of users with reduced information.

		$sqlquery = 'SELECT username, name, enabled FROM ' . $class->convert($options{"TablePrefix"}) . '_users';

	} else {

		# Get the list of users.

		$sqlquery = 'SELECT * FROM ' . $class->convert($options{"TablePrefix"}) . '_users';

	}

	# Check if the deactivated users should be hidden.

	if ($deactivated_show eq 0){

		# The deactivated users should be hidden from the list.

		$sqlquery = $sqlquery . ' WHERE enabled=TRUE';

	}
	
	$sqlquery = $sqlquery . ' ORDER BY username';

	# Run the query.

	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();

	# Process the user list.

	while (@user_data = $statement_handle->fetchrow_array()){

		$user_list{$user_seek}{username} 	= decode_utf8($user_data[0]);
		$user_list{$user_seek}{name} 		= decode_utf8($user_data[1]);

		if ($user_data[2] eq 0){

			$user_list{$user_seek}{deactivated} 	= 1;

		} else {

			$user_list{$user_seek}{deactivated} 	= 0;

		}

		$user_seek++;

	}

	return %user_list;

}

sub getpermissions{
#################################################################################
# getpermissions: Get the permissions for scanner or module.			#
#										#
# Usage:									#
#										#
# $dbmodule->getpermissions(options);						#
#										#
# options	Specifies the following options in any order.			#
#										#
# Username		Specifies the username to get permissions for.		#
# PermissionType	Specifies the permission type.				#
# PermissionName	Get a specific permission name.				#
#										#
# If no permission name is specified then a list of permissions will be 	#
# returned as hash otherwise the value will be returned as a normal string.	#
#################################################################################

	$error = "";
	$errorext = "";

	# Get the value passed to the subroutine.

	my $class = shift;
	my ($passedoptions) = @_;
	
	my $username		= $passedoptions->{'Username'};
	my $permissiontype	= $passedoptions->{'PermissionType'};
	my $permissionname	= $passedoptions->{'PermissionName'};
	my $sqlquery = "";
	my $user_exists = 0;
	
	my $permissionresult = 0;
	my @userdata;
	my @permissiondata;
	my $uid = 0;
	
	if (!$username){

		# The username is blank so return an error.

		$error = "UsernameBlank";
		return;

	}

	if (!$permissiontype){
	
		# The permissions type is blank so return an error.
		
		$error = "PermissionTypeBlank";
		return;
		
	}
	
	#if (!$permissionname){
	
		# The permissions name is blank so return a list of
		# permissions for that type.
		
	#	my %user_permissions;
		
	#	return %user_permissions;
		
	#}
	
	# Get the user ID number.
	
	$sqlquery = 'SELECT uid, username FROM ' . $class->convert($options{"TablePrefix"}) . '_users WHERE username=\'' . $class->convert(decode_utf8($username)) . '\'';
	
	# Run the query.
	
	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();
	
	while(@userdata = $statement_handle->fetchrow_array()){
		
		$uid = $userdata[0];
		
	}
	
	if ($permissiontype eq "OutputModule"){
		
		if (!$permissionname){
			
			my %useroutputinfo;
			
			# No permission name was specified so get the list of
			# scanner permissions.
			
			$sqlquery = 'SELECT uid, moduletype, modulename, enabled FROM ' . $class->convert($options{"TablePrefix"}) . '_modules WHERE uid=\'' . $class->convert($uid) . '\' AND moduletype=\'Output\'';
			
			# Run the query.
			
			$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
			$statement_handle->execute();
			
			# Process the list of permissions.
			
			while(@permissiondata = $statement_handle->fetchrow_array()){
				
				$useroutputinfo{$permissiondata[2]}		= $permissiondata[3];
				
			}
			
			return %useroutputinfo;
			
		}
		
		$sqlquery = 'SELECT uid, moduletype, modulename, enabled FROM ' . $class->convert($options{"TablePrefix"}) . '_modules WHERE uid=\'' . $class->convert($uid) . '\' AND moduletype=\'Output\' AND modulename=\'' . $class->convert($permissionname) . '\'';

		# Run the query.
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();		

		# Check to see the value of the permission.
		
		while(@permissiondata = $statement_handle->fetchrow_array()){
			
			if ($permissiondata[3] eq 1){
				
				$permissionresult = 1;
				
			} else {
				
				$permissionresult = 0;
				
			}
			
		}
		
	} elsif ($permissiontype eq "ExportModule"){

		if (!$permissionname){
			
			my %userexportinfo;
			
			# No permission name was specified so get the list of
			# scanner permissions.
			
			$sqlquery = 'SELECT uid, moduletype, modulename, enabled FROM ' . $class->convert($options{"TablePrefix"}) . '_modules WHERE uid=\'' . $class->convert($uid) . '\' AND moduletype=\'Export\'';
			
			# Run the query.
			
			$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
			$statement_handle->execute();
			
			# Process the list of permissions.
			
			while(@permissiondata = $statement_handle->fetchrow_array()){
				
				$userexportinfo{$permissiondata[2]}		= $permissiondata[3];
				
			}
			
			return %userexportinfo;
			
		}
		
		$sqlquery = 'SELECT uid, moduletype, modulename, enabled FROM ' . $class->convert($options{"TablePrefix"}) . '_modules WHERE uid=\'' . $class->convert($uid) . '\' AND moduletype=\'Export\' AND modulename=\'' . $class->convert($permissionname) . '\'';
		
		# Run the query.
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();		
		
		# Check to see the value of the permission.
		
		while(@permissiondata = $statement_handle->fetchrow_array()){
			
			if ($permissiondata[3] eq 1){
				
				$permissionresult = 1;
				
			} else {
				
				$permissionresult = 0;
				
			}
			
		}
		
	} elsif ($permissiontype eq "Scanner"){

		# The permission type is a Scanner permission.
		
		if (!$permissionname){
		
			my %userscannerinfo;
			
			# No permission name was specified so get the list of
			# scanner permissions.
			
			$sqlquery = 'SELECT uid, scannerid, enabled FROM ' . $class->convert($options{"TablePrefix"}) . '_scanners WHERE uid=\'' . $class->convert($uid) . '\'';
			
			# Run the query.
			
			$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
			$statement_handle->execute();
			
			# Process the list of permissions.
			
			while(@permissiondata = $statement_handle->fetchrow_array()){
				
				$userscannerinfo{$permissiondata[1]}		= $permissiondata[2];
				
			}
			
			return %userscannerinfo;
			
		}
		
		# The permission type is a Scanner permission.
		
		$sqlquery = 'SELECT uid, scannerid, enabled FROM ' . $class->convert($options{"TablePrefix"}) . '_scanners WHERE uid=\'' . $class->convert($uid) . '\' AND scannerid=\'' . $class->convert($permissionname) . '\'';
		
		# Run the query.
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
		# Check to see the value of the permission.
		
		while(@permissiondata = $statement_handle->fetchrow_array()){
			
			if ($permissiondata[2] eq 1){
			
				$permissionresult = 1;
				
			} else {
			
				$permissionresult = 0;
				
			}
			
		}
		
	} elsif ($permissiontype eq "Admin"){
	
		# Check to see if the user has administrative permissions.
		
		$sqlquery = 'SELECT uid, admin FROM ' . $class->convert($options{"TablePrefix"}) . '_users WHERE uid=\'' . $class->convert($uid) . '\' AND admin=TRUE AND enabled=TRUE';
		
		# Run the query.
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
		# Check to see the value of the admin permission.

		while(@permissiondata = $statement_handle->fetchrow_array()){
			
			if ($permissiondata[1] eq 1){
				
				$permissionresult = 1;
				
			} else {
				
				$permissionresult = 0;
				
			}
			
		}
		
	} elsif ($permissiontype eq "UserInfo"){
	
		my %userinfo;
		
		# Get the details of the user.
		
		$sqlquery = 'SELECT uid, username, name, admin, enabled FROM ' . $class->convert($options{"TablePrefix"}) . '_users WHERE uid=\'' . $class->convert($uid) . '\'';
		
		# Run the query.
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
		while(@permissiondata = $statement_handle->fetchrow_array()){
		
			$userinfo{UID}		= $permissiondata[0];
			$userinfo{Username}	= decode_utf8($permissiondata[1]);
			$userinfo{Name}		= decode_utf8($permissiondata[2]);
			$userinfo{Admin}	= $permissiondata[3];
			$userinfo{Enabled}	= $permissiondata[4];
			
		}
		
		return %userinfo;
		
	}
	
	return $permissionresult;
	
}

sub adduser{
#################################################################################
# adduser: Add a user to the user list with specific permissions.		#
#										#
# Usage:									#
#										#
# $dbmodule->adduser(username, userinfo);					#
#										#
# username		Specifies the username.					#
# userinfo		Specifies the user information hash.			#
#################################################################################
	
	$error = "";
	$errorext = "";
	
	my $class	= shift;
	
	my $username	= shift;
	my %userinfo	= @_;
	
	if (!$username){
		
		# The username is blank so return an error.
		
		$error = "UsernameBlank";
		return;
		
	}
	
	# Check if the username exists.
	
	my $sqlquery = "";
	my @user_data;
	my $user_exists = 0;
	$sqlquery = "SELECT * FROM " . $class->convert($options{"TablePrefix"}) . "_users WHERE username='" . $class->convert($username) . "'";
	
	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();
	
	while (@user_data = $statement_handle->fetchrow_array()){
		
		$user_exists = 1;
		
	}
	
	if ($user_exists eq 1){
		
		$error = "UserExists";
		return;
		
	}
	
	$sqlquery = "";
	
	my $adminpriv	= "FALSE";
	my $enabledpriv	= "FALSE";
	
	if (!$userinfo{"Enabled"}){
		
		$userinfo{"Enabled"} = "off";
		
	}
	
	if (!$userinfo{"Admin"}){
		
		$userinfo{"Admin"} = "off";
		
	}
	
	$adminpriv = "TRUE" if $userinfo{Admin} eq "on";
	$enabledpriv = "TRUE" if $userinfo{Enabled} eq "on";
	
	# Generate a random salt for the password and combine it
	# with the password.
	
	my $digest = Digest->new("SHA-512");
	
	my $salt = uc(sprintf("%x",int(rand(50000000))));
	
	$digest->add(decode_utf8($userinfo{Password}));
	$digest->add($salt);
	
	$sqlquery = "INSERT INTO " . $class->convert($options{"TablePrefix"}) . "_users (username, password, salt, version, name, admin, enabled) VALUES(";
	$sqlquery = $sqlquery . "'" . $class->convert(decode_utf8($userinfo{Username})) . "',";
	$sqlquery = $sqlquery . "'" . $digest->hexdigest . "',";
	$sqlquery = $sqlquery . "'" . $salt . "',";
	$sqlquery = $sqlquery . "1,";
	$sqlquery = $sqlquery . "'" . $class->convert(decode_utf8($userinfo{Name})) . "',";
	$sqlquery = $sqlquery . $adminpriv . ",";
	$sqlquery = $sqlquery . $enabledpriv;
	$sqlquery = $sqlquery . ")";
	
	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();
	
	return;
	
}

sub edituser{
#################################################################################
# edituser: Edit a user on the user list.					#
#										#
# Usage:									#
#										#
# $dbmodule->edituser(username, type, data);					#
#										#
# Usage:									#
#										#
# username		Specifies the username to edit.				#
# type			Specifies the type of data to edit.			#
# data			Specifies the data to use (as a hash).			#
#################################################################################
	
	$error = "";
	$errorext = "";
	
	my $class = shift;
	
	my $username		= shift;
	my $type		= shift;	
	my (%data)		= @_;
	
	#(%permissions) 	= @_;
	#my %permissions_final;
	#my $user_exists = 0;
	
	#if (!$username){
	
	# The username is blank so return an error.
	
	#	$error = "UsernameBlank";
	#	return;
	
	#}
	
	#$username = $data{OriginalUsername};
	
	if (!$username){
		
		# The username is blank so return an error.
		
		$error = "UsernameBlank";
		return;
		
	}
	
	if (!$type){
		
		# The type is blank so return an error.
		
		$error = "TypeBlank";
		return;
		
	}
	
	# Check if the username exists.
	
	my $sqlquery = "";
	my @user_data;
	my $user_exists = 0;
	
	$sqlquery = "SELECT * FROM " . $class->convert($options{"TablePrefix"}) . "_users WHERE username='" . decode_utf8($username) . "'";
	
	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();
	
	while (@user_data = $statement_handle->fetchrow_array()){
		
		$user_exists = 1;
		
	}
	
	if ($user_exists ne 1){
		
		$error = "UserDoesNotExist";
		return;
		
	}
	
	# Check what type of data is being updated.
	
	# Get the user ID (UID) number.
	
	my $uid = 0;
	$sqlquery = 'SELECT uid, username FROM ' . $class->convert($options{"TablePrefix"}) . '_users WHERE username=\'' . $class->convert(decode_utf8($username)) . '\'';
	@user_data = [];
	
	# Run the query.
	
	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();
	
	while(@user_data = $statement_handle->fetchrow_array()){
		
		$uid = $user_data[0];
		
	}
	
	if ($type eq "User"){
		
		# Update the user information.
		
		$sqlquery = "UPDATE " . $class->convert($options{"TablePrefix"}) . "_users SET";
		
		if (!$data{"Enabled"}){
			
			$data{"Enabled"} = "off";
			
		}
		
		if (!$data{"Admin"}){
			
			$data{"Admin"} = "off";
			
		}
		
		# Check if the account is enabled or not.
		
		if ($data{Enabled} eq "on"){
			
			$sqlquery = $sqlquery . " enabled = TRUE";
			
		} else {
			
			$sqlquery = $sqlquery . " enabled = FALSE";
			
		}
		
		# Check if the account has administrative status or not.
		
		if ($data{Admin} eq "on"){
			
			$sqlquery = $sqlquery . ", admin = TRUE";
			
		} else {
			
			$sqlquery = $sqlquery . ", admin = FALSE";
			
		}
		
		# Add the name to query.
		
		$sqlquery = $sqlquery . ", name = '" . $class->convert(decode_utf8($data{Name})) . "'";
		
		# Check if the user with the new username already exists.
		
		$user_exists = 0;
		
		if (decode_utf8($username) ne decode_utf8($data{NewUsername})){
			
			my $sqlqueryusername = "";
			@user_data = [];
			$sqlqueryusername = "SELECT * FROM " . $class->convert($options{"TablePrefix"}) . "_users WHERE username='" . $class->convert(decode_utf8($data{NewUsername})) . "'";
			
			$statement_handle = $database_handle->prepare($sqlqueryusername) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
			$statement_handle->execute();
			
			while (@user_data = $statement_handle->fetchrow_array()){
				
				$user_exists = 1;
				
			}
			
			if ($user_exists eq 1){
				
				$error = "NewUsernameAlreadyExists";
				return;
				
			}
			
			$sqlquery = $sqlquery . ", username = \'" . $class->convert(decode_utf8($data{NewUsername})) . "\'";
			
		}
		
		# Check if the password needs to be changed.
		
		if ($data{Password} ne ""){
			
			if ($data{Password} eq $data{ConfirmPassword}){
				
				# Generate a random salt for the password and combine it
				# with the password.
				
				my $digest = Digest->new("SHA-512");
				
				my $salt = uc(sprintf("%x\n",int(rand(50000000))));
				
				$digest->add(decode_utf8($data{Password}));
				$digest->add($salt);
				
				$sqlquery = $sqlquery . ", password = \'" . $class->convert($digest->hexdigest) . "\'";
				$sqlquery = $sqlquery . ", salt = \'" . $class->convert($salt) . "\'";
				$sqlquery = $sqlquery . ", version = 1";
				
			}
			
		}
		
		# Add the user id on the end.
		
		$sqlquery = $sqlquery . " WHERE uid = '" . $class->convert($uid) . "'";
		
		# Run the query.
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
	} elsif ($type eq "Scanner"){
		
		# Drop all scanner information for this user.
		
		$sqlquery = "DELETE FROM " . $class->convert($options{"TablePrefix"}) . "_scanners WHERE uid =\'" . $class->convert($uid)  . "\'";
		
		# Run the query.
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();		
		
		return if (!%data);
		
		# Insert the new scanner information for this user.
		
		$sqlquery = "";
		
		$sqlquery = "INSERT INTO xestiascan_scanners (uid, scannerid, enabled) VALUES";
		
		# Process the hash passed to the subroutine.
		
		my $firstline = 1;
		my $datakeyname;
		
		foreach $datakeyname (keys %data){
			
			if ($firstline eq 1){
				
				$sqlquery = $sqlquery . "(" . $class->convert($uid) . ",\'" . $class->convert($datakeyname) . "\',";
				$firstline = 0;
				
			} else {
				
				$sqlquery = $sqlquery . ",(" . $class->convert($uid) . ",\'" . $class->convert($datakeyname) . "\',";
				
			}
			
			if ($data{$datakeyname} eq "on"){
				
				$sqlquery = $sqlquery . "TRUE)";
				
			} else {
				
				$sqlquery = $sqlquery . "FALSE)";				
				
			}
			
		}
		
		# Run the query.
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
	} elsif ($type eq "OutputModule"){
		
		# Drop all output module information for this user.
		
		$sqlquery = "DELETE FROM " . $class->convert($options{"TablePrefix"}) . "_modules WHERE uid ='" . $class->convert($uid)  . "' AND moduletype ='Output'";
		
		# Run the query.
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
		return if (!%data);		
		
		# Insert the new output module information for this user.
		
		$sqlquery = "";
		
		$sqlquery = "INSERT INTO xestiascan_modules (uid, moduletype, modulename, enabled) VALUES";
		
		# Process the hash passed to the subroutine.
		
		my $firstline = 1;
		my $datakeyname;
		
		foreach $datakeyname (keys %data){
			
			if ($firstline eq 1){
				
				$sqlquery = $sqlquery . "(" . $class->convert($uid) . ",'Output','" . $class->convert($datakeyname) . "',";
				$firstline = 0;
				
			} else {
				
				$sqlquery = $sqlquery . ",(" . $class->convert($uid) . ",'Output','" . $class->convert($datakeyname) . "',";
				
			}
			
			if ($data{$datakeyname} eq "on"){
				
				$sqlquery = $sqlquery . "TRUE)";
				
			} else {
				
				$sqlquery = $sqlquery . "FALSE)";				
				
			}
			
		}
		
		# Run the query.
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
	} elsif ($type eq "ExportModule"){
		
		# Drop all export module information for this user.
		
		$sqlquery = "DELETE FROM " . $class->convert($options{"TablePrefix"}) . "_modules WHERE uid ='" . $class->convert($uid)  . "' AND moduletype ='Export'";
		
		# Run the query.
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
		return if (!%data);
		
		# Insert the new export module information for this user.
		
		$sqlquery = "";
		
		$sqlquery = "INSERT INTO xestiascan_modules (uid, moduletype, modulename, enabled) VALUES";
		
		# Process the hash passed to the subroutine.
		
		my $firstline = 1;
		my $datakeyname;
		
		foreach $datakeyname (keys %data){
			
			if ($firstline eq 1){
				
				$sqlquery = $sqlquery . "(" . $class->convert($uid) . ",\'Export',\'" . $class->convert($datakeyname) . "\',";
				$firstline = 0;
				
			} else {
				
				$sqlquery = $sqlquery . ",(" . $class->convert($uid) . ",\'Export\',\'" . $class->convert($datakeyname) . "\',";
				
			}
			
			if ($data{$datakeyname} eq "on"){
				
				$sqlquery = $sqlquery . "TRUE)";
				
			} else {
				
				$sqlquery = $sqlquery . "FALSE)";				
				
			}
			
		}
		
		# Run the query.
		
		$statement_handle = $database_handle->prepare($sqlquery) or die; #( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
	}
	
}

sub deleteuser{
#################################################################################
# deleteuser: Delete a user from the user list.					#
#										#
# Usage:									#
#										#
# $dbmodule->deleteuser(username);						#
#										#
# username	Specifies the username to delete from the user list.		#
#################################################################################
	
	$error = "";
	$errorext = "";
	
	my $class = shift;
	
	my $username = shift;
	
	if (!$username){
		
		# User name is blank so return an error.
		
		$error = "UsernameBlank";
		return;
		
	}
	
	# Check if the user exists before deleting.
	
	my $user_exists = 0;
	my @user_data;
	
	my $sqlquery = "SELECT * FROM " . $class->convert($options{"TablePrefix"}) . "_users WHERE username=\'" . $class->convert(decode_utf8($username)) . "\' LIMIT 1";
	
	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();

	while (@user_data = $statement_handle->fetchrow_array()){
	
		$user_exists = 1;
		
	}
	
	if ($user_exists eq 0){
	
		$error = "UserDoesNotExist";
		return;
		
	}

	# Get the user ID (UID) number.
	
	my $uid = 0;
	$sqlquery = 'SELECT uid, username FROM ' . $class->convert($options{"TablePrefix"}) . '_users WHERE username=\'' . $class->convert(decode_utf8($username)) . '\'';
	@user_data = [];
	
	# Run the query.
	
	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();
	
	while(@user_data = $statement_handle->fetchrow_array()){
		
		$uid = $user_data[0];
		
	}
	
	# Delete the module permissions from the modules table.

	$sqlquery = "DELETE FROM " . $class->convert($options{"TablePrefix"}) . "_scanners where uid=\'" . $class->convert($uid) . "\'";
	
	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();
	
	# Delete the scanner permissions from the scanners table.
	
	$sqlquery = "DELETE FROM " . $class->convert($options{"TablePrefix"}) . "_modules where uid=\'" . $class->convert($uid) . "\'";
	
	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();
	
	# Delete the user from the users table.
	
	$sqlquery = "DELETE FROM " . $class->convert($options{"TablePrefix"}) . "_users where username=\'" . $class->convert(decode_utf8($username)) . "\'";
	
	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();
	
}

sub userauth{
#################################################################################
# authuser: Authenticate a user.						#
#										#
# Usage:									#
#										#
# $dbmodule->authuser(type, user, password, keeploggedin);			#
#										#
# type		Specifies the type of authentication.				#
# user		Specifies the name of the user.					#
# password	Specifies the password or authentication token.			#
# keeploggedin	Specifies if the user should stay logged in for one year.	#
#################################################################################
	
	$error = "";
	$errorext = "";
	
	my $class = shift;
	
	my $type = shift;
	my $username = shift;
	my $password = shift;
	my $keeploggedin = shift;

	my $user_exists = 0;
	my @user_data;

	# Check to see if the user exists before authenticating.
	
	#my $sqlquery = "";
	my $sqlquery = "SELECT * FROM " . $class->convert($options{"TablePrefix"}) . "_users WHERE username=\'" . $class->convert(decode_utf8($username)) . "\' LIMIT 1";
	
	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();
	
	while (@user_data = $statement_handle->fetchrow_array()){
		
		$user_exists = 1;
		
	}
	
	if ($user_exists eq 0){
		
		$error = "UserDoesNotExist";
		return 0;
		
	}
	
	# Authenticate the user.
	
	my @auth_data;
	my $valid_login = 0;
	
	if ($type eq "seed"){
		
		$sqlquery = "SELECT * FROM " . $class->convert($options{"TablePrefix"}) . "_sessions WHERE username=\'" . $class->convert(decode_utf8($username)) . "\' AND seed=\'" . $class->convert($password) . "\' AND expires > now() LIMIT 1";
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
		while (@auth_data = $statement_handle->fetchrow_array()){
			
			$valid_login = 1;
			
		}
		
		return $valid_login;
		
	} elsif ($type eq "password") {
		
		$sqlquery = "SELECT username, salt, enabled FROM " . $class->convert($options{"TablePrefix"}) . "_users WHERE username=\'" . $class->convert(decode_utf8($username)) . "\' LIMIT 1";
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
		my $digest = Digest->new("SHA-512");
		my $salt = "";
		my $hash = "";
		
		while (@auth_data = $statement_handle->fetchrow_array()){
			
			$valid_login = 1;
			
			# Check if the user account has been disabled.
			
			if ($auth_data[2] eq 0){
				
				# Account has been disabled so login is invalid.
				
				$valid_login = 0;
				
			} else {
				
				# Generate the passsword hash using the password and salt given.
				
				$salt = $auth_data[1];
				$digest->add(decode_utf8($password));
				$digest->add($salt);
				
			}
			
		}
		
		return if $valid_login eq 0;
		
		$sqlquery = "SELECT username, password, enabled FROM " . $class->convert($options{"TablePrefix"}) . "_users WHERE username=\'" . $class->convert(decode_utf8($username)) . "\' AND password =\'" . $class->convert($digest->hexdigest) . "\' LIMIT 1";
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
		$valid_login = 0;
		
		while (@auth_data = $statement_handle->fetchrow_array()){
			
			$valid_login = 1;
			
			# Check if the user account has been disabled.
			
			if ($auth_data[2] eq 0){
				
				# Account has been disabled so login is invalid.
				
				$valid_login = 0;
				
			}
			
		}
		
		if ($valid_login eq 1){
			
			my $auth_seed_unique = "yes";
			my $new_auth_seed;
			my @auth_seed_data;
			
			# Check if the auth seed already exists and generate
			# a new random number if it does exist.
			
			do {
				
				$auth_seed_unique = "yes";
				$new_auth_seed = int(rand(192000000));
				
				$sqlquery = "SELECT * FROM  " . $class->convert($options{"TablePrefix"}) . "_sessions WHERE seed=\'" . $class->convert($new_auth_seed) . "\' LIMIT 1";
				
				$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
				$statement_handle->execute();				
				
				while (@auth_seed_data = $statement_handle->fetchrow_array()){
					
					$auth_seed_unique = "no";
					
				}
				
			} until ($auth_seed_unique eq "yes");
			
			# Insert this into the sessions database. 
			
			if ($keeploggedin eq 1){
				
				$sqlquery = "INSERT INTO " . $class->convert($options{"TablePrefix"}) . "_sessions (username, seed, expires) VALUES( '" . $class->convert(decode_utf8($username)) . "', '" . $class->convert($new_auth_seed) . "', 'now'::timestamp + '1 year'::interval);";
				
			} else {
				
				$sqlquery = "INSERT INTO " . $class->convert($options{"TablePrefix"}) . "_sessions (username, seed, expires) VALUES( '" . $class->convert(decode_utf8($username)) . "', '" . $class->convert($new_auth_seed) . "', 'now'::timestamp + '3 hours'::interval);";				
				
			}
			
			$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
			$statement_handle->execute();
			
			return ($valid_login, $new_auth_seed);
			
		}
		
		# Return the result.
		
		return $valid_login;
		
	}
		
}

sub flushusers{
#################################################################################
# flushusers: Flush all users from the sessions table.				#
#										#
# Usage:									#
#										#
# $dbmodule->flushusers();							#
#################################################################################
	
	$error = "";
	$errorext = "";
	
	# Flush all users from the sessions table. (This includes the user who
	# called the action to flush the table).
	
	my $class = shift;
	
	my $sqlquery = "DELETE FROM " . $class->convert($options{"TablePrefix"})  . "_sessions";
	
	$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
	$statement_handle->execute();
	
}

sub populatetables{
#################################################################################
# populatetables: Populate the database with tables.				#
#										#
# Usage:									#
#										#
# type		Specifies the type of table to populate.			#
# forcerecreate	Force recreates the table (delete and create).			#
#################################################################################
	
	$error = "";
	$errorext = "";
	
	my $class = shift;
	
	my $type = shift;
	my $forcerecreate = shift;
	
	my $sqlquery = "";
	
	if ($type eq "modules"){
		
		if ($forcerecreate eq 1){
		
			$sqlquery = "DROP TABLE " . $class->convert($options{"TablePrefix"})  . "_modules";
			
			$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
			$statement_handle->execute();
			
			if ($DBI::err){
				
				$error = "DatabaseError";
				$errorext = $DBI::errstr;
				return;
				
			}
			
		}
		
		$sqlquery = "CREATE TABLE " . $class->convert($options{"TablePrefix"})  . "_modules (
		uid bigint NOT NULL,
		moduletype varchar(12) NOT NULL,
		modulename varchar(256) NOT NULL,
		enabled boolean NOT NULL
		)";
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();		
		
		if ($DBI::err){
		
			$error = "DatabaseError";
			$errorext = $DBI::errstr;
			return;
			
		}
		
	} elsif ($type eq "scanners"){
		
		if ($forcerecreate eq 1){
			
			$sqlquery = "DROP TABLE " . $class->convert($options{"TablePrefix"})  . "_scanners";
			
			$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
			$statement_handle->execute();
			
			if ($DBI::err){
				
				$error = "DatabaseError";
				$errorext = $DBI::errstr;
				return;
				
			}
		
		}
		
		$sqlquery = "CREATE TABLE " . $class->convert($options{"TablePrefix"})  . "_scanners (
		uid bigint NOT NULL,
		scannerid varchar(256) NOT NULL,
		enabled boolean NOT NULL
		)";
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
		
		if ($DBI::err){
			
			$error = "DatabaseError";
			$errorext = $DBI::errstr;
			return;
			
		}
		
	} elsif ($type eq "sessions"){
		
		if ($forcerecreate eq 1){
			
			$sqlquery = "DROP TABLE " . $class->convert($options{"TablePrefix"})  . "_sessions";
			
			$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
			$statement_handle->execute();
			
			if ($DBI::err){
				
				$error = "DatabaseError";
				$errorext = $DBI::errstr;
				return;
				
			}
			
		}
		
		$sqlquery = "CREATE TABLE " . $class->convert($options{"TablePrefix"})  . "_sessions (
		seed varchar(32) UNIQUE PRIMARY KEY NOT NULL,
		username text NOT NULL,
		expires timestamp NOT NULL
		)";
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();	

		if ($DBI::err){
			
			$error = "DatabaseError";
			$errorext = $DBI::errstr;
			return;
			
		}
		
	} elsif ($type eq "users"){
	
		if ($forcerecreate eq 1){
			
			$sqlquery = "DROP TABLE " . $class->convert($options{"TablePrefix"})  . "_users";
			
			$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
			$statement_handle->execute();
			
			if ($DBI::err){
				
				$error = "DatabaseError";
				$errorext = $DBI::errstr;
				return;
				
			}
			
		}
		
		$sqlquery = "CREATE TABLE " . $class->convert($options{"TablePrefix"})  . "_users (
		uid SERIAL PRIMARY KEY,
		username varchar(64) UNIQUE NOT NULL,
		password text NOT NULL,
		salt varchar(512) NOT NULL,
		version integer NOT NULL,
		name varchar(128) NOT NULL,
		admin boolean NOT NULL,
		enabled boolean NOT NULL
		)";
		
		$statement_handle = $database_handle->prepare($sqlquery) or ( $error = "DatabaseError", $errorext = $database_handle->errstr, return );
		$statement_handle->execute();
	
		if ($DBI::err){
			
			$error = "DatabaseError";
			$errorext = $DBI::errstr;
			return;
			
		}
		
	}
	
}

1;