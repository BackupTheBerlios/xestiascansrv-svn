#################################################################################
# Xestia Scanner Server - Common System Module					#
# Version 0.1.0									#
#										#
# Copyright (C) 2010-2011 Steve Brokenshire <sbrokenshire@xestia.co.uk>		#
#										#
# This module is licensed under the same license as Xestia Scanner Server which #
# is licensed under the GPL version 3.						#
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

package Modules::System::Common;

use strict;
use warnings;
use Exporter;
use CGI::Lite;
use MIME::Base64 qw(encode_base64url);

our @ISA = qw(Exporter);
our @EXPORT = qw(xestiascan_initialise xestiascan_settings_load xestiascan_fileexists xestiascan_filepermissions xestiascan_output_header xestiascan_output_page xestiascan_variablecheck xestiascan_processconfig xestiascan_processfilename xestiascan_utf8convert xestiascan_language xestiascan_error);

sub xestiascan_initialise{
#################################################################################
# xestiascan_initialise: Get the enviroment stuff.				#
#################################################################################

	# Get the script filename.

	my $env_script_name = $ENV{'SCRIPT_NAME'};

	# Process the script filename until there is only the
	# filename itself.

	my $env_script_name_length = length($env_script_name);
	my $filename_seek = 0;
	my $filename_char = "";
	my $filename_last = 0;

	do {
		$filename_char = substr($env_script_name, $filename_seek, 1);
		if ($filename_char eq "/"){
			$filename_last = $filename_seek + 1;
		}
		$filename_seek++;
	} until ($filename_seek eq $env_script_name_length || $env_script_name_length eq 0);

	my $env_script_name_finallength = $env_script_name_length - $filename_last;
	my $script_filename = substr($env_script_name, $filename_last, $env_script_name_finallength);

	# Setup the needed enviroment variables for Xestia Scanner Server.

	%main::xestiascan_env = (
		"script_filename" => $script_filename,
	);

}

sub xestiascan_settings_load{
#################################################################################
# xestiascan_settings_load: Load the configuration settings into the global	#
# variables.									#
#										#
# Usage:									#
#										#
# xestiascan_settings_load();							#
#################################################################################

	# Check if the Xestia Scanner Server configuration file exists before 
	# using it and return an critical error if it doesn't exist.

	my ($xestiascan_settingsfilehandle, @config_data, %config, $config);
	my $xestiascan_conf_exist = xestiascan_fileexists("xsdss.cfg");

	if ($xestiascan_conf_exist eq 1){

		# The configuration really does not exist so return an critical error.

		xestiascan_critical("configfilemissing");

	}

	# Check if the Xestia Scanner Server configuration file has valid permission 
	# settings before using it and return an critical error if it doesn't have the
	# valid permission settings.

	my $xestiascan_conf_permissions = xestiascan_filepermissions("xsdss.cfg", 1, 0);

	if ($xestiascan_conf_permissions eq 1){

		# The permission settings for the Xestia Scanner Server configuration 
		# file are invalid, so return an critical error.

		xestiascan_critical("configfileinvalidpermissions");

	}

	# Converts the file into meaningful data for later on in this subroutine.

	my $xestiascan_conf_file = 'xsdss.cfg';

	open($xestiascan_settingsfilehandle, $xestiascan_conf_file);
	binmode $xestiascan_settingsfilehandle, ':utf8';
	@config_data = <$xestiascan_settingsfilehandle>;
	%config = xestiascan_processconfig(@config_data);
	close($xestiascan_settingsfilehandle);

	# Go and fetch the settings and place them into a hash (that is global).

	%main::xestiascan_config = (

		"directory_noncgi_images"	=> $config{config}{directory_noncgi_images},
		"directory_noncgi_scans"	=> $config{config}{directory_noncgi_scans},
		"directory_fs_scans"		=> $config{config}{directory_fs_scans},

		"system_language"		=> $config{config}{system_language},
		"system_presmodule"		=> $config{config}{system_presmodule},
		"system_authmodule"		=> $config{config}{system_authmodule},
		"system_outputmodule"		=> $config{config}{system_outputmodule},
		"system_datetime"		=> $config{config}{system_datetime},

		"database_server"		=> $config{config}{database_server},
		"database_port"			=> $config{config}{database_port},
		"database_protocol"		=> $config{config}{database_protocol},
		"database_sqldatabase"		=> $config{config}{database_sqldatabase},
		"database_username"		=> $config{config}{database_username},
		"database_password"		=> $config{config}{database_password},
		"database_tableprefix"		=> $config{config}{database_tableprefix}

	);

	# Do a validation check on all of the variables that were loaded into the global configuration hash.

	xestiascan_variablecheck($main::xestiascan_config{"directory_noncgi_images"}, "maxlength", 512, 0);
	xestiascan_variablecheck($main::xestiascan_config{"directory_noncgi_scans"}, "maxlength", 512, 0);
	
	xestiascan_variablecheck($main::xestiascan_config{"directory_fs_scans"}, "maxlength", 4096, 0);

	my $xestiascan_config_language_filename = xestiascan_variablecheck($main::xestiascan_config{"system_language"}, "language_filename", "", 1);
	my $xestiascan_config_presmodule_filename = xestiascan_variablecheck($main::xestiascan_config{"system_presmodule"}, "module", 0, 1);
	my $xestiascan_config_authmodule_filename = xestiascan_variablecheck($main::xestiascan_config{"system_authmodule"}, "module", 0, 1);
	# Check if the language filename is valid and return an critical error if
	# they aren't.

	if ($xestiascan_config_language_filename eq 1){

		# The language filename is blank so return an critical error.

		xestiascan_critical("languagefilenameblank");

	} elsif ($xestiascan_config_language_filename eq 2){

		# The language filename is invalid so return an critical error.

		xestiascan_critical("languagefilenameinvalid");

	}

	# Check if the presentation and database module names are valid and return a critical
	# error if they aren't.

	if ($xestiascan_config_presmodule_filename eq 1){

		# The presentation module filename given is blank so return an 
		# critical error.

		xestiascan_critical("presmoduleblank");

	}

	if ($xestiascan_config_presmodule_filename eq 2){

		# The presentation module filename is invalid so return an
		# critical error.

		xestiascan_critical("presmoduleinvalid");

	}

	if ($xestiascan_config_authmodule_filename eq 1){

		# The database module filename given is blank so return an
		# critical error.

		xestiascan_critical("authmoduleblank");

	}

	if ($xestiascan_config_authmodule_filename eq 2){

		# The database module filename given is invalid so return
		# an critical error.

		xestiascan_critical("authmoduleinvalid");

	}

	# Check if the language file does exist before loading it and return an critical error
	# if it does not exist.

	my $xestiascan_config_language_fileexists = xestiascan_fileexists("lang/" . $main::xestiascan_config{"system_language"} . ".lang");

	if ($xestiascan_config_language_fileexists eq 1){

		# Language file does not exist so return an critical error.

		xestiascan_critical("languagefilemissing");

	}

	# Check if the language file has valid permission settings and return an critical error if
	# the language file has invalid permissions settings.

	my $xestiascan_config_language_filepermissions = xestiascan_filepermissions("lang/" . $main::xestiascan_config{"system_language"} . ".lang", 1, 0);

	if ($xestiascan_config_language_filepermissions eq 1){

		# Language file contains invalid permissions so return an critical error.

		xestiascan_critical("languagefilenameinvalidpermissions");

	}

	# Load the language file.

	my ($xestiascan_languagefilehandle, @lang_data);

	open($xestiascan_languagefilehandle, "lang/" . $main::xestiascan_config{"system_language"} . ".lang");
	@lang_data = <$xestiascan_languagefilehandle>;
	%main::xestiascan_lang = xestiascan_processconfig(@lang_data);
	close($xestiascan_languagefilehandle);

 	# Check if the presentation module does exist before loading it and return an critical error
	# if the presentation module does not exist.

	my $xestiascan_config_presmodule_fileexists = xestiascan_fileexists("Modules/Presentation/" . $main::xestiascan_config{"system_presmodule"} . ".pm");

	if ($xestiascan_config_presmodule_fileexists eq 1){

		# Presentation module does not exist so return an critical error.

		xestiascan_critical("presmodulemissing");

	}

	# Check if the presentation module does have the valid permission settings and return a
	# critical error if the presentation module contains invalid permission settings.

	my $xestiascan_config_presmodule_permissions = xestiascan_filepermissions("Modules/Presentation/" . $main::xestiascan_config{"system_presmodule"} . ".pm", 1, 0);

	if ($xestiascan_config_presmodule_permissions eq 1){

		# Presentation module contains invalid permissions so return an critical error.

		xestiascan_critical("presmoduleinvalidpermissions");

	}

	# Check if the database module does exist before loading it and return an critical error
	# if the database module does not exist.

	my $xestiascan_config_authmodule_fileexists = xestiascan_fileexists("Modules/Auth/" . $main::xestiascan_config{"system_authmodule"} . ".pm");

	if ($xestiascan_config_authmodule_fileexists eq 1){

		# Database module does not exist so return an critical error.

		xestiascan_critical("authmodulemissing");

	}

	# Check if the database module does have the valid permission settings and return an
	# critical error if the database module contains invalid permission settings.

	my $xestiascan_config_authmodule_permissions = xestiascan_filepermissions("Modules/Auth/" . $main::xestiascan_config{"system_authmodule"} . ".pm", 1, 0);

	if ($xestiascan_config_authmodule_permissions eq 1){

		# Presentation module contains invalid permissions so return an critical error.

		xestiascan_critical("authmoduleinvalidpermissions");

	}

	# Include the Modules directory.

	use lib "Modules/";

	# Load the presentation module.

 	my $presmodulename = "Presentation::" . $main::xestiascan_config{"system_presmodule"};
 	($presmodulename) = $presmodulename =~ m/^(.*)$/g; # CHECK THIS!!
 	eval "use " . $presmodulename;
 	$presmodulename = "Modules::Presentation::" . $main::xestiascan_config{"system_presmodule"};
 	$main::xestiascan_presmodule = $presmodulename->new();
	$main::xestiascan_presmodule->clear(); 

 	# Load the database module.
 
 	my $dbmodulename = "Auth::" . $main::xestiascan_config{"system_authmodule"};
 	($dbmodulename) = $dbmodulename =~ m/^(.*)$/g; # CHECK THIS!!
 	eval "use " . $dbmodulename;
 	$dbmodulename = "Modules::Auth::" . $main::xestiascan_config{"system_authmodule"};
 	$main::xestiascan_authmodule = $dbmodulename->new();

	# Load the following settings to the database module.

 	$main::xestiascan_authmodule->loadsettings({ DateTime => $main::xestiascan_config{"system_datetime"}, Server => $main::xestiascan_config{"database_server"}, Port => $main::xestiascan_config{"database_port"}, Protocol => $main::xestiascan_config{"database_protocol"}, Database => $main::xestiascan_config{"database_sqldatabase"}, Username => $main::xestiascan_config{"database_username"}, Password => $main::xestiascan_config{"database_password"}, TablePrefix => $main::xestiascan_config{"database_tableprefix"} });

	return;

}

sub xestiascan_language{
#################################################################################
# xestiascan_language: Process language strings that needs certain text		#
#			inserted.						#
#										#
# Usage:									#
#										#
# xestiascan_language(string, [text, text, ...]);				#
#										#
# string	Specifies the string to process.				#
# text		Specifies the text to pass to the string (can be repeated many	#
#		times).								#
#################################################################################

        my $string = shift;
        my $item;

        foreach $item (@_){

                $string =~ s/%s/$item/;

        }

        return $string;

}

sub xestiascan_error{
#################################################################################
# xestiascan_error: Prints out an error message.				#
# 										#
# Usage:									#
#										#
# xestiascan_error(errortype, errorext);					#
#										#
# errortype	Specifies the type of error that occured.			#
# errorext	Specifies the extended error information.			#
#################################################################################

	# Get the error type from the subroutine.

	my ($error_type, $error_extended) = @_;

	# Disconnect from the database server.

	if ($main::xestiascan_authmodule){
		$main::xestiascan_authmodule->disconnect();
	}

	# Load the list of error messages.

	my @xestiascan_error = (

		# Catch all error message.
		"generic", 

		# Standard error messages.
		"blankfilename", "blankvariable", "fileexists",	"internalerror", "invalidoption", "invalidaction", "invalidfilename", "invalidmode", "invalidutf8", "invalidvariable", "variabletoolong",

		# Specific error messages.
		"authconnectionerror", "autherror", "authmoduleblank", "authmoduleinvalid", "authmodulemissing",
		"blankdatetimeformat", "blankdirectory", "blankpictureid", "bottomrightx",
		"bottomrightxinvalidnumber", "bottomrighty", "bottomrightyinvalidnumber", "brightnessblank",
		"brightnessinvalidnumber", "colourblank", "colourinvalidoption", "invaliddatetimeformat",
		"invaliddirectory", "invalidpictureid", "languagefilenamemissing", "moduleinvalid",
		"nametoolong", "notpermitted", "outputmoduleblank", "outputmoduleinvalid",
		"passwordblank", "passwordsdonotmatch", "passwordtoolong", "permissiontypeblank", "presmoduleblank",
		"presmoduleinvalid", "presmodulemissing", "resolutionblank", "resolutioninvalidnumber",
		"rotateblank", "rotateinvalidoption", "scannererror", "serverdatabasenameinvalid",
		"serverdatabasenametoolong", "serverdatabasepasswordtoolong", "serverdatabasetableprefixinvalid", "serverdatabasetableprefixtoolong",
		"serverdatabaseusernameinvalid", "serverdatabaseusernametoolong", "servernameinvalid", "servernametoolong",
		"serverportnumberinvalid", "serverportnumberinvalidcharacters", "serverportnumbertoolong", "serverprotocolinvalid",
		"serverprotocolnametoolong", "topleftxblank", "topleftxinvalidnumber", "topleftyblank", "topleftyinvalidnumber",
		"userexists", "usernameblank", "usernametoolong", "variabletoolong"
	
	);

	# Check if the error message name is a valid error message name
	# and return the generic error message if it isn't.

	my $error_string = "";

	if (grep /^$error_type$/, @xestiascan_error){

		# The error type is valid so get the error language string
		# associated with this error messsage name.

		$error_string = $main::xestiascan_lang{error}{$error_type};

	} else {

		# The error type is invalid so set the error language
		# string using the generic error message name.

		$error_string = $main::xestiascan_lang{error}{generic};

	}

	$main::xestiascan_presmodule->clear();

	$main::xestiascan_presmodule->startbox("errorbox");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{error}, { Style => "errorheader" });
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($error_string, { Style => "errortext" });

	# Check to see if extended error information was passed.

	if ($error_extended){

		# Write the extended error information.

		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{extendederror});
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->startbox("datalist");
		$main::xestiascan_presmodule->addtext($error_extended);
		$main::xestiascan_presmodule->endbox();

	}

	$main::xestiascan_presmodule->endbox();

	my $menulist = "";
	
	if ($main::successful_auth eq 1){
		
		$menulist = "standard";
		
	} else {
	
		$menulist = "none";
		
	}
	
	&xestiascan_output_header;
	xestiascan_output_page($main::xestiascan_lang{error}{error}, $main::xestiascan_presmodule->grab(), $menulist);

	exit;

}

sub xestiascan_fileexists{
#################################################################################
# xestiascan_fileexists: Check if a file exists and returns a value depending on #
# if the file exists or not.							#
#										# 
# Usage:									#
#										#
# xestiascan_fileexists(filename);						#
#										#
# filename	Specifies the file name to check if it exists or not.		#
#################################################################################

	# Get the value that was passed to the subroutine.

	my ($filename) = @_;

	# Check if the filename exists, if it does, return a value of 0, else
	# return a value of 1, meaning that the file was not found.

	if (-e $filename){

		# Specified file does exist so return a value of 0.

		return 0;

	} else {

		# Specified file does not exist so return a value of 1.

		return 1;

	}

}

sub xestiascan_filepermissions{
#################################################################################
# xestiascan_filepermissions: Check if the file permissions of a file and return #
# either a 1 saying that the permissions are valid or return a 0 saying that	#
# the permissions are invalid.							#
# 										#
# Usage:									#
#										#
# xestiascan_filepermissions(filename, [read], [write], [filemissingskip]);	#
#										#
# filename		Specifies the filename to check for permissions.	#
# read			Preform check that the file is readable.		#
# write			Preform check that the file is writeable.		#
# filemissingskip	Skip the check of seeing if it can read or write if the #
#			file is missing.					#
#################################################################################

	# Get the values that was passed to the subroutine.

	my ($filename, $readpermission, $writepermission, $ignorechecks) = @_;

	# Check to make sure that the read permission and write permission values
	# are only 1 character long.

	xestiascan_variablecheck($readpermission, "maxlength", 1, 0);
	xestiascan_variablecheck($writepermission, "maxlength", 1, 0);
	xestiascan_variablecheck($ignorechecks, "maxlength", 1, 0);

	my $ignorechecks_result = 0;

	# Check if the file should be ignored for read and write checking if 
	# it doesn't exist.

	if ($ignorechecks){

		if (-e $filename){

			# The file exists so the checks are to be done.

			$ignorechecks_result = 0;

		} else {

			# The file does not exist so the checks don't need to
			# be done to prevent false positives.

			$ignorechecks_result = 1;

		}

	} else {

		$ignorechecks_result = 0;

	}

	# Check if the file should be checked to see if it can be read.

	if ($readpermission && $ignorechecks_result eq 0){

		# The file should be checked to see if it does contain read permissions
		# and return a 0 if it is invalid.

		if (-r $filename){

			# The file is readable, so do nothing.

		} else {

			# The file is not readable, so return 1.

			return 1;

		}

	}

	# Check if the file should be checked to see if it can be written.

	if ($writepermission && $ignorechecks_result eq 0){

		# The file should be checked to see if it does contain write permissions
		# and return a 0 if it is invalid.

		if (-w $filename){

			# The file is writeable, so do nothing.

		} else {

			# The file is not writeable, so return 1.

			return 1;

		}

	}

	# No problems have occured, so return 0.

	return 0;

}

sub xestiascan_utf8convert{
#################################################################################
# xestiascan_utf8convert: Properly converts values into UTF-8 values.		#
#										#
# Usage:									#
#										#
# utfstring	# The UTF-8 string to convert.					#
#################################################################################

	# Get the values passed to the subroutine.

	my ($utfstring) = @_;

	# Load the Encode perl module.

	use Encode qw(decode_utf8 encode_utf8);

	# Convert the string.

	my $finalutf8 = Encode::decode_utf8( $utfstring );

	return $finalutf8;
	#return $utfstring;

}

sub xestiascan_critical{
#################################################################################
# xestiascan_critical: Displays an critical error message that cannot be		#
# normally by the xestiascan_error subroutine.					#
#										#
# Usage:									#
#										#
# errortype	Specifies the type of critical error that has occured.		#
#################################################################################

	# Get the value that was passed to the subroutine.

	my ($error_type) = @_;

	my %error_list;

	# Get the error type from the errortype string.

	%error_list = (

		# Generic critical error message.

		"generic"			=> "A critical error has occured but the error is not known to Xestia Scanner Server.",

		# Specific critical error messages.

		"configfilemissing" 		=> "The Xestia Scanner Server configuration file is missing! Running the installer script for Xestia Scanner Server is recommended.",
		"configfileinvalidpermissions"	=> "The Xestia Scanner Server configuration file has invalid permission settings set! Please set the valid permission settings for the configuration file.",
		"authmoduleblank"		=> "The authentication module name is blank! Running the installer script for Xestia Scanner Server is recommended.",
		"authmodulemissing"		=> "The authentication module is missing! Running the installer script for Xestia Scanner Server is recommended.",
		"authmoduleinvalidpermissions"	=> "The authentication module cannot be used as it has invalid permission settings set! Please set the valid permission settings for the configuration file.",
		"authmoduleinvalid"		=> "The authentication module name given is invalid. Running the installer script for Xestia Scanner Server is recommended.",
		"invalidvalue"			=> "An invalid value was passed.",
		"languagefilenameblank"		=> "The language filename given is blank! Running the installer script for Xestia Scanner Server is recommended.",
		"languagefilenameinvalid"	=> "The language filename given is invalid! Running the installer script for Xestia Scanner Server is recommended.",
		"languagefilemissing"	=> "The language filename given does not exist. Running the installer script for Xestia Scanner Server is recommended.",
		"languagefilenameinvalidpermissions"	=> "The language file with the filename given has invalid permissions set. Please set the valid permission settings for the language file.",
		"presmodulemissing"		=> "The presentation module is missing! Running the installer script for Xestia Scanner Server is recommended.",
		"presmoduleinvalidpermissions"	=> "The presentation module cannot be used as it has invalid permission settings set! Please set the valid permission settings for the presentation module.",
		"presmoduleinvalid"		=> "The presentation module name given is invalid. Running the installer script for Xestia Scanner Server is recommended.",
		"textarearowblank"		=> "The text area row value given is blank. Running the installer script for Xestia Scanner Server is recommended.",
		"textarearowtoolong"		=> "The text area row value is too long. Running the installer script for Xestia Scanner Server is recommended.",
		"textarearowinvalid"		=> "The text area row value is invalid. Running the installer script for Xestia Scanner Server is recommended.",
		"textareacolblank"		=> "The text area row value given is blank. Running the installer script for Xestia Scanner Server is recommended.",
		"textareacoltoolong"		=> "The text area column value is too long. Running the installer script for Xestia Scanner Server is recommended.",
		"textareacolinvalid"		=> "The text area column value is invalid. Running the installer script for Xestia Scanner Server is recommended.",
		"pagecountblank"		=> "The page count value is blank. Running the installer script for Xestia Scanner Server is recommended.",
		"templatecountblank"		=> "The template count value is blank. Running the installer script for Xestia Scanner Server is recommended.",
		"filtercountblank"		=> "The filter count value is blank. Running the installer script for Xestia Scanner Server is recommended.",
		"pagecounttoolong"		=> "The page count value is too long. Running the installer script for Xestia Scanner Server is recommended.",
		"templatecounttoolong"		=> "The template count value is too long. Running the installer script for Xestia Scanner Server is recommended.",
		"filtercounttoolong"		=> "The filter count value is too long. Running the installer script for Xestia Scanner Server is recommended.",
		"pagecountinvalid"		=> "The page count value is invalid. Running the installer script for Xestia Scanner Server is recommended.",
		"templatecountinvalid"		=> "The template count value is invalid. Running the installer script for Xestia Scanner Server is recommended.",
		"filtercountinvalid"		=> "The filter count is invalid. Running the installer script for Xestia Scanner Server is recommended."

	);

	if (!$error_list{$error_type}){

		$error_type = "generic";

	}

	print "Content-Type: text/html; charset=utf-8;\r\n";
	print "Expires: Sun, 01 Jan 2008 00:00:00 GMT\r\n\r\n";
	print "Critical Error: " . $error_list{$error_type};
	exit;

}

sub xestiascan_variablecheck{
#################################################################################
# xestiascan_variablecheck: Checks the variables for any invalid characters.	#
#										#
# Usage:									#
#										#
# xestiascan_variablecheck(variable, type, length, noerror);			#
#										#
# variable	Specifies the variable to be checked.				#
# type		Specifies what type the variable is.				#
# option	Specifies the maximum/minimum length of the variable		#
#		(if minlength/maxlength is used) or if the filename should be   #
#		checked to see if it is blank.					#
# noerror	Specifies if Xestia Scanner Server should return an error	#
#		or not on certain values.					#
#################################################################################

	# Get the values that were passed to the subroutine.

	my ($variable_data, $variable_type, $variable_option, $variable_noerror) = @_;

	if (!$variable_data){
		$variable_data = "";
	}

	if (!$variable_type){
		$variable_type = "";
	}

	if ($variable_type eq "numbers"){

		# Check for numbers and return an error if there is anything else than numebrs.

		my $variable_data_validated = $variable_data;	# Copy the variable_data to variable_data_validated.
		$variable_data_validated =~ tr/0-9//d;		# Take away all of the numbers and from the variable. 
								# If it only contains numbers then it should be blank.

		if ($variable_data_validated eq ""){
			# The validated variable is blank. So continue to the end of this section where the return function should be.
		} else {
			# The variable is not blank, so check if the no error value is set
			# to 1 or not.

			if ($variable_noerror eq 1){

				# The validated variable is not blank and the noerror
				# value is set to 1. So return an value of 1.
				# (meaning that the data is invalid).

				return 1;

			} elsif ($variable_noerror eq 0) {

				# The validated variable is not blank and the noerror
				# value is set to 0.

				xestiascan_error("invalidvariable");

			} else {

				# The variable noerror value is something else
				# pther than 1 or 0. So return an error.

				xestiascan_error("invalidvariable");

			}

		}

		return 0;

	} elsif ($variable_type eq "decimal"){
		
		# Check for numbers and decimal and return an error if there is anything else than numebrs.
		
		my $variable_data_validated = $variable_data;	# Copy the variable_data to variable_data_validated.
		$variable_data_validated =~ tr/0-9.//d;		# Take away all of the numbers and from the variable. 
		# If it only contains numbers then it should be blank.
		
		if ($variable_data_validated eq ""){
			# The validated variable is blank. So continue to the end of this section where the return function should be.
		} else {
			# The variable is not blank, so check if the no error value is set
			# to 1 or not.
			
			if ($variable_noerror eq 1){
				
				# The validated variable is not blank and the noerror
				# value is set to 1. So return an value of 1.
				# (meaning that the data is invalid).
				
				return 1;
				
			} elsif ($variable_noerror eq 0) {
				
				# The validated variable is not blank and the noerror
				# value is set to 0.
				
				xestiascan_error("invalidvariable");
				
			} else {
				
				# The variable noerror value is something else
				# pther than 1 or 0. So return an error.
				
				xestiascan_error("invalidvariable");
				
			}
			
		}
		
		return 0;
		
	} elsif ($variable_type eq "lettersnumbers"){

		# Check for letters and numbers and return an error if there is anything else other
		# than letters and numbers.

		my $variable_data_validated = $variable_data;	# Copy the variable_data to variable_data_validated
		$variable_data_validated =~ tr/a-zA-Z0-9.//d;
		$variable_data_validated =~ s/\s//g;

		if ($variable_data_validated eq ""){
			# The validated variable is blank. So continue to the end of this section where the return function should be.
		} else {
			# The variable is not blank, so check if the no error value is set
			# to 1 or not.

			if ($variable_noerror eq 1){

				# The validated variable is not blank and the noerror
				# value is set to 1. So return an value of 1.
				# (meaning that the data is invalid).

				return 1;

			} elsif ($variable_noerror eq 0) {

				# The validated variable is not blank and the noerror
				# value is set to 0.

				xestiascan_error("invalidvariable");

			} else {

				# The variable noerror value is something else
				# pther than 1 or 0. So return an error.

				xestiascan_error("invalidvariable");

			}

		}

		return 0;

	} elsif ($variable_type eq "maxlength"){
		# Check for the length of the variable, return an error if it is longer than the length specified.

		# Check if the variable_data string is blank, if it is then set the variable_data_length
		# to '0'.

		my $variable_data_length = 0;

		if (!$variable_data){

			# Set variable_data_length to '0'.
			$variable_data_length = 0;

		} else {

			# Get the length of the variable recieved.
			$variable_data_length = length($variable_data);

		}



		if ($variable_data_length > $variable_option){

			# The variable length is longer than it should be so check if
			# the no error value is set 1.

			if ($variable_noerror eq 1){

				# The no error value is set to 1, so return an
				# value of 1 (meaning tha the variable is
				# too long to be used).

				return 1;

			} elsif ($variable_noerror eq 0){

				# The no error value is set to 0, so return
				# an error.

				xestiascan_error("variabletoolong");

			} else {

				# The no error value is something else other
				# than 0 or 1, so return an error.

				xestiascan_error("variabletoolong");

			}

		} else {

			# The variable length is exactly or shorter than specified, so continue to end of this section where
			# the return function should be.

		}

		return 0;

	} elsif ($variable_type eq "blank"){
		# Check if the variable is blank and if it is blank, then return an error.

		if (!$variable_data){

			# The variable data really is blank, so check what
			# the no error value is set.

			if ($variable_noerror eq 1){

				# The no error value is set to 1, so return
				# a value of 1 (saying that the variable was
				# blank).

				return 1;

			} elsif ($variable_noerror eq 0){

				# The no error value is set to 0, so return
				# an error.

				xestiascan_error("blankvariable");

			} else {

				# The no error value is something else other
				# than 0 or 1, so return an error.

				xestiascan_error("invalidvariable");

			}

		}

		return 0;

	} elsif ($variable_type eq "filename"){
		# Check for letters and numbers, if anything else than letters and numbers is there (including spaces) return
		# an error.

		# Check if the filename passed is blank, if it is then return with an error.

		if ($variable_data eq ""){

			# The filename specified is blank, so check what the
			# noerror value is set.

			if ($variable_noerror eq 1){

				# The no error value is set to 1 so return
				# a value of 1 (meaning that the filename
				# was blank).

				return 1;

			} elsif ($variable_noerror eq 0){

				# The no error value is set to 1 so return
				# an error.

				xestiascan_error("blankfilename");

			} else {

				# The no error value is something else other
				# than 0 or 1, so return an error.

				xestiascan_error("invalidvariable");

			}

		} else {


		}

		my $variable_data_validated = $variable_data;
		$variable_data_validated =~ tr/a-zA-Z0-9\.//d;

		# Check if the validated data variable is blank, if it is 
		# then continue to the end of this section where the return 
		# function should be, otherwise return an error.

		if ($variable_data_validated eq ""){

			# The validated data variable is blank, meaning that 
			# it only contained letters and numbers.

		} else {

			# The validated data variable is not blank, meaning 
			# that it contains something else, so return an error
			# (or a value).

			if ($variable_noerror eq 1){

				# The no error value is set to 1 so return
				# an value of 2. (meaning that the filename
				# is invalid).


				return 2;

			} elsif ($variable_noerror eq 0){

				# The no error value is set to 0 so return
				# an error.

				xestiascan_error("invalidfilename");

			} else {

				# The no error value is something else other
				# than 0 or 1 so return an error.

				xestiascan_error("invalidvariable");

			}

		}

		return 0;

	} elsif ($variable_type eq "filenameindir"){
		# Check if the filename is in the directory and return an
		# error if it isn't.

		if ($variable_data eq ""){

			# The filename specified is blank, so check what the
			# noerror value is set.

			if ($variable_noerror eq 1){

				# The no error value is set to 1 so return
				# a value of 1 (meaning that the filename
				# was blank).

				return 1;

			} elsif ($variable_noerror eq 0){

				# The no error value is set to 1 so return
				# an error.

				xestiascan_error("blankfilename");

			} else {

				# The no error value is something else other
				# than 0 or 1, so return an error.

				xestiascan_error("invalidvariable");

			}

		} else {


		}

		# Set the following variables for later on.

		my $variable_data_length = 0;
		my $variable_data_char = "";
		my $variable_data_validated = "";
		my $variable_data_seek = 0;
		my $variable_database_list = "";
		my $variable_database_listcurrent = "";
		my $variable_data_firstlevel = 1;

		# Get the length of the variable recieved.

		$variable_data_length = length($variable_data);

		# Check if the database filename contains the directory command
		# for up a directory level and if it is, return an error
		# or return with a number.

		do {

			# Get a character from the filename passed to this subroutine.

			$variable_data_char = substr($variable_data, $variable_data_seek, 1);

			# Check if the current character is the forward slash character.

			if ($variable_data_char eq "/"){

				# Check if the current directory is blank (and on the first level), or if the
				# current directory contains two dots or one dot, if it does return an error.

				if ($variable_database_listcurrent eq "" && $variable_data_firstlevel eq 1 || $variable_database_listcurrent eq ".." || $variable_database_listcurrent eq "."){

					# Check if the noerror value is set to 1, if it is return an
					# number, else return an proper error.

					if ($variable_noerror eq 1){

						# Page filename contains invalid characters and
						# the no error value is set to 1 so return a 
						# value of 2 (meaning that the page filename
						# is invalid).

						return 2;

					} elsif ($variable_noerror eq 0) {

						# Page filename contains invalid characters and
						# the no error value is set to 0 so return an
						# error.

						xestiascan_error("invalidfilename");

					} else {

						# The no error value is something else other
						# than 0 or 1 so return an error.

						xestiascan_error("invalidvariable");

					}

				}

				# Append the forward slash, clear the current directory name and set
				# the first directory level value to 0.

				$variable_database_list = $variable_database_list . $variable_data_char;
				$variable_database_listcurrent = "";
				$variable_data_firstlevel = 0;

			} else {

				# Append the current character to the directory name and to the current
				# directory name.

				$variable_database_list = $variable_database_list . $variable_data_char;
				$variable_database_listcurrent = $variable_database_listcurrent . $variable_data_char;

			}

			# Increment the seek counter.

			$variable_data_seek++;

		} until ($variable_data_seek eq $variable_data_length);

		return 0;

	} elsif ($variable_type eq "datetime"){
		# Check if the date and time setting format is valid.

		if ($variable_data eq ""){

			if ($variable_noerror eq 1){

				# The no error value is set to 1 so return
				# a value of 1 (meaning that the date and
				# time format was blank).

				return 1;

			} elsif ($variable_noerror eq 0){

				# The no error value is set to 1 so return
				# an error.

				xestiascan_error("blankdatetimeformat");

			} else {

				# The no error value is something else other
				# than 0 or 1, so return an error.

				xestiascan_error("invalidvariable");

			}

		}

		my $variable_data_validated = $variable_data;
		$variable_data_validated =~ tr|dDmMyYhms/():[ ]||d;

		if ($variable_data_validated eq ""){

			# The date and time format is valid. So
			# skip this bit.

		} else {

			# The validated data variable is not blank, meaning 
			# that it contains something else, so return an error
			# (or a value).

			if ($variable_noerror eq 1){

				# The no error value is set to 1 so return
				# an value of 2. (meaning that the date and
				# time format was invalid).

				return 2;

			} elsif ($variable_noerror eq 0){

				# The no error value is set to 0 so return
				# an error.

				xestiascan_error("invaliddatetimeformat");

			} else {

				# The no error value is something else other
				# than 0 or 1 so return an error.

				xestiascan_error("invalidvariable");

			}

		}

		return 0;

	} elsif ($variable_type eq "directory"){
		# Check if the directory only contains letters and numbers and
		# return an error if anything else appears.

		my $variable_data_validated = $variable_data;
		$variable_data_validated =~ tr/a-zA-Z0-9//d;

		if ($variable_data eq ""){

			if ($variable_noerror eq 1){

				# The no error value is set to 1 so return
				# a value of 1 (meaning that the directory
				# name was blank).

				return 1;

			} elsif ($variable_noerror eq 0){

				# The no error value is set to 1 so return
				# an error.

				xestiascan_error("blankdirectory");

			} else {

				# The no error value is something else other
				# than 0 or 1, so return an error.

				xestiascan_error("invalidvariable");

			}

		}

		if ($variable_data_validated eq ""){

			# The validated data variable is blank, meaning that
			# it only contains letters and numbers.

		} else {

			# The validated data variable is not blank, meaning 
			# that it contains something else, so return an error
			# (or a value).

			if ($variable_noerror eq 1){

				# The no error value is set to 1 so return
				# an value of 2. (meaning that the directory
				# name is invalid).

				return 2;

			} elsif ($variable_noerror eq 0){

				# The no error value is set to 0 so return
				# an error.

				xestiascan_error("invaliddirectory");

			} else {

				# The no error value is something else other
				# than 0 or 1 so return an error.

				xestiascan_error("invalidvariable");

			}

		}

		return 0;

	} elsif ($variable_type eq "language_filename"){

		# The variable type is a language filename type.
		# Check if the language file name is blank and 
		# if it is then return an error (or value).

		if ($variable_data eq ""){

			# The language filename is blank so check the
			# no error value and return an error (or value).

			if ($variable_noerror eq 1){

				# Language filename is blank and the no error value
				# is set as 1, so return a value of 1 (saying that
				# the language filename is blank).

				return 1;

			} elsif ($variable_noerror eq 0) {

				# Language filename is blank and the no error value
				# is not set as 1, so return an error.

				xestiascan_critical("languagefilenameblank");

			} else {

				# The noerror value is something else other
				# than 0 or 1 so return an error.

				xestiascan_error("invalidvariable");

			}

		}

		# Set the following variables for later on.

		my $variable_data_length = 0;
		my $variable_data_char = "";
		my $variable_data_seek = 0;

		# Get the length of the language file name.

		$variable_data_length = length($variable_data);

		do {

			# Get a character from the language filename passed to this 
			# subroutine and the character the seek counter value is set
			# to.

			$variable_data_char = substr($variable_data, $variable_data_seek, 1);

			# Check if the language filename contains a forward slash or a dot, 
			# if the selected character is a forward slash then return an error
			# (or value).

			if ($variable_data_char eq "/" || $variable_data_char eq "."){

				# The language filename contains a forward slash or
				# a dot so depending on the no error value, return
				# an error or a value.

				if ($variable_noerror eq 1){

					# Language filename contains a forward slash or a dot
					# and the no error value has been set to 1, so return 
					# an value of 2 (saying that the language file name is 
					# invalid).

					return 2;

				} elsif ($variable_noerror eq 0) {

					# Language filename contains a forward slash and the no
					# error value has not been set to 1, so return an error.

					xestiascan_critical("languagefilenameinvalid");

				} else {

					# The noerror value is something else other than
					# 1 or 0 so return an error.

					xestiascan_error("invalidvariable");

				}

			}

			# Increment the seek counter.

			$variable_data_seek++;

		} until ($variable_data_seek eq $variable_data_length);

		return 0;

	} elsif ($variable_type eq "module"){

		# The variable type is a presentation module filename.

		# Check if the variable_data is blank and if it is
		# return an error.

		if ($variable_data eq ""){

			# The presentation module is blank so check if an error
			# value should be returned or a number should be
			# returned.

			if ($variable_noerror eq 1){

				# Module name is blank and the no error value 
				# is set to 1 so return a value of 2 (meaning 
				# that the page filename is blank).

				return 1;

			} elsif ($variable_noerror eq 0) {

				# Module name contains is blank and the no error 
				# value is set to 0 so return an error.

				xestiascan_critical("moduleblank");

			} else {

				# The no error value is something else other
				# than 0 or 1 so return an error.

				xestiascan_critical("invalidvalue");

			}

		} else {

		}

		my $variable_data_validated = $variable_data;
		$variable_data_validated =~ tr/a-zA-Z0-9//d;

		if ($variable_data_validated eq ""){

		} else {

			if ($variable_noerror eq 1){

				# Module name contains invalid characters and
				# the no error value is set to 1 so return a 
				# value of 2 (meaning that the page filename
				# is invalid).

				return 2;

			} elsif ($variable_noerror eq 0) {

				# Module name contains invalid characters and
				# the no error value is set to 0 so return an
				# error.

				xestiascan_critical("moduleinvalid");

			} else {

				# The no error value is something else other
				# than 0 or 1 so return an error.

				xestiascan_error("invalidvalue");

			}

		}

		return 0;

	} elsif ($variable_type eq "utf8"){

		# The variable type is a UTF8 string.

		if (!$variable_data){

			$variable_data = "";

		}

		my $chunk = 0;
		my $process = 8192;
		my $length = 0;
		my $chunkdata = "";

		while ($chunk < $length){

  			$chunkdata = substr($variable_data, $chunk, $process);

  			if ($chunkdata =~ m/\A(
     				[\x09\x0A\x0D\x20-\x7E]            # ASCII
   				| [\xC2-\xDF][\x80-\xBF]             # non-overlong 2-byte
   				|  \xE0[\xA0-\xBF][\x80-\xBF]        # excluding overlongs
   				| [\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}  # straight 3-byte
   				|  \xED[\x80-\x9F][\x80-\xBF]        # excluding surrogates
   				|  \xF0[\x90-\xBF][\x80-\xBF]{2}     # planes 1-3
				| [\xF1-\xF3][\x80-\xBF]{3}          # planes 4-15
   				|  \xF4[\x80-\x8F][\x80-\xBF]{2}     # plane 16
			)*\z/x){

				# The UTF-8 string is valid.
	
			} else {
	
				# The UTF-8 string is not valid, check if the no error
				# value is set to 1 and return an error if it isn't.
	
				if ($variable_noerror eq 1){
	
					# The no error value has been set to 1, so return
					# a value of 1 (meaning that the UTF-8 string is
					# invalid).
	
					return 1; 
	
				} elsif ($variable_noerror eq 0) {
	
					# The no error value has been set to 0, so return
					# an error.
	
					xestiascan_error("invalidutf8");
	
				} else {
	
					# The no error value is something else other than 0
					# or 1, so return an error.
	
					xestiascan_error("invalidoption");
	
				}
	
			}


			$chunk = $chunk + $process;

		}

# 		# Check if the string is a valid UTF8 string.
# 
#   		if ($variable_data =~ m/^(
# 			[\x09\x0A\x0D\x20-\x7E]              # ASCII
# 			| [\xC2-\xDF][\x80-\xBF]             # non-overlong 2-byte
# 			|  \xE0[\xA0-\xBF][\x80-\xBF]        # excluding overlongs
# 			| [\xE1-\xEC\xEE\xEF][\x80-\xBF]{2}  # straight 3-byte
# 			|  \xED[\x80-\x9F][\x80-\xBF]        # excluding surrogates
# 			|  \xF0[\x90-\xBF][\x80-\xBF]{2}     # planes 1-3
# 			| [\xF1-\xF3][\x80-\xBF]{3}          # planes 4-15
# 			|  \xF4[\x80-\x8F][\x80-\xBF]{2}     # plane 16
# 		)*$/x){
# 
# 			# The UTF-8 string is valid.
# 
# 		} else {
# 
# 			# The UTF-8 string is not valid, check if the no error
# 			# value is set to 1 and return an error if it isn't.
# 
# 			if ($variable_noerror eq 1){
# 
# 				# The no error value has been set to 1, so return
# 				# a value of 1 (meaning that the UTF-8 string is
# 				# invalid).
# 
# 				return 1; 
# 
# 			} elsif ($variable_noerror eq 0) {
# 
# 				# The no error value has been set to 0, so return
# 				# an error.
# 
# 				xestiascan_error("invalidutf8");
# 
# 			} else {
# 
# 				# The no error value is something else other than 0
# 				# or 1, so return an error.
# 
# 				xestiascan_error("invalidoption");
# 
# 			}
# 
# 		}

		return 0;

	} elsif ($variable_type eq "serverprotocol"){

		# Check if the server protocol is TCP or UDP and return
		# an error if it isn't.

		if ($variable_data ne "tcp" && $variable_data ne "udp"){

			# The protocol given is not valid, check if the no
			# error value is set to 1 and return an error if it isn't.

			if ($variable_noerror eq 1){

				# The no error value has been set to 1, so return a
				# value of 1 (meaning that the server protocol is
				# invalid).

				return 1;

			} elsif ($variable_noerror eq 0){

				# The no error value has been set to 0, so return
				# an error.

				xestiascan_error("serverprotocolinvalid");

			} else {

				# The no error value is something else other than 0
				# or 1, so return an error.

				xestiascan_error("invalidoption");

			}

		}

		return 0;

	} elsif ($variable_type eq "port"){

		# Check if the port number given is less than 0 or more than 65535
		# and return an error if it is.

		if ($variable_data < 0 || $variable_data > 65535){

			# The port number is less than 0 and more than 65535 so
			# check if the no error value is set to 1 and return an
			# error if it isn't.

			if ($variable_noerror eq 1){

				# The no error value has been set to 1, so return a
				# value of 1 (meaning that the port number is invalid).

				return 1;

			} elsif ($variable_noerror eq 0){

				# The no error value has been set to 0, so return
				# an error.

				xestiascan_error("serverportnumberinvalid");

			} else {

				# The no error value is something else other than 0
				# or 1, so return an error.

				xestiascan_error("invalidoption");

			}

		}

		return 0;

	}

	# Another type than the valid ones above has been specified so return an error specifying an invalid option.
	xestiascan_error("invalidoption");

}

sub xestiascan_output_header{
#################################################################################
# xestiascan_output_header: Outputs the header to the browser/stdout/console.	#
#										#
# Usage:									#
#										#
# xestiascan_output_header(username, seed, expires);				#
#################################################################################

	my $headertype = shift;
	
	# Print a header saying that the page expires immediately since the
	# date is set in the past.
	
	$headertype = "none" if !$headertype;
	
	if ($headertype eq "cookie"){
	
		my $username = shift;
		my $seed = shift;
		my $expires = shift;
	
		if (!$expires){
		
			$expires = 0;
			
		}
		
		# Get the date and time information.
		
		my ($exp_sec, $exp_min, $exp_hour, $exp_mday, $exp_mon, $exp_year, $exp_wday, $exp_yday, $exp_isdst) = localtime(time + $expires);
		
		my @month = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
		my @weekday = qw(Sun Mon Tue Wed Thu Fri Sat);
	
		$exp_sec	= "0" . $exp_sec if $exp_sec < 10;
		$exp_min	= "0" . $exp_min if $exp_min < 10;
		$exp_hour	= "0" . $exp_hour if $exp_hour < 10;
		$exp_mday	= "0" . $exp_mday if $exp_mday < 10;
		$exp_mon	= "0" . $exp_mon if $exp_mon < 10;

		my $expires_time = $weekday[$exp_wday] . ", " . $exp_mday . "-" . $month[$exp_mon]  . "-" . ($exp_year + 1900) . " " . $exp_hour . ":" . $exp_min . ":" . $exp_sec . " GMT";
		
		# Print out the cookies.
		
		print "Set-Cookie: " . $main::xestiascan_config{'database_tableprefix'} . "_auth_seed=" . $seed . "; expires="  . $expires_time ."\r\n";
		print "Set-Cookie: " . $main::xestiascan_config{'database_tableprefix'} . "_auth_username=" . encode_base64url($username) . "; expires="  . $expires_time ."\r\n";		
		
	} elsif ($headertype eq "cookie_logout") {

		# Get the date and time information.
		
		my ($exp_sec, $exp_min, $exp_hour, $exp_mday, $exp_mon, $exp_year, $exp_wday, $exp_yday, $exp_isdst) = localtime(time - 100);
		
		my @month = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
		my @weekday = qw(Sun Mon Tue Wed Thu Fri Sat);
		
		$exp_sec	= "0" . $exp_sec if $exp_sec < 10;
		$exp_min	= "0" . $exp_min if $exp_min < 10;
		$exp_hour	= "0" . $exp_hour if $exp_hour < 10;
		$exp_mday	= "0" . $exp_mday if $exp_mday < 10;
		$exp_mon	= "0" . $exp_mon if $exp_mon < 10;
		
		my $expires_time = $weekday[$exp_wday] . ", " . $exp_mday . "-" . $month[$exp_mon]  . "-" . ($exp_year + 1900) . " " . $exp_hour . ":" . $exp_min . ":" . $exp_sec . " GMT";
		
		print "Set-Cookie: " . $main::xestiascan_config{'database_tableprefix'} . "_auth_seed=; expires="  . $expires_time ."\r\n";
		print "Set-Cookie: " . $main::xestiascan_config{'database_tableprefix'} . "_auth_username=; expires="  . $expires_time ."\r\n";				
		
	}

	#print "Set-Cookie: seed=$seed:username=" . $username . "; expires=" . $weekday[$exp_wday] . " " . $exp_mday . "-" . $month[$exp_mon] . "-" . ($exp_year + 1900) . " " . $exp_hour . ":" . $exp_min . ":" . $exp_sec . " GMT\r\n";

	print "Content-Type: text/html; charset=utf-8\r\n";
	print "Expires: Sun, 01 Jan 2007 00:00:00 GMT\r\n\r\n";
	
	return;
	
}

sub xestiascan_processfilename{
#################################################################################
# xestiascan_processfilename: Processes a name and turns it into a filename that#
# can be used by Xestia Scanner Server.						#
#										#
# Usage:									#
#										#
# xestiascan_processfilename(text);						#
#										#
# text		Specifies the text to be used in the process for creating a new	#
#		filename.							#
#################################################################################

	# Get the values that have been passed to the subroutine.

	my ($process_text) = @_;

	# Define some variables that will be used later on.

	my $processed_stageone 	= "";
	my $processed_stagetwo 	= "";
	my $processed_length	= "";
	my $processed_char	= "";
	my $processed_seek	= 0;
	my $processed_filename 	= "";

	# Set the first stage value of the processed filename to the
	# process filename and then filter it out to only contain
	# numbers and letters (no spaces) and then convert the
	# capitals to small letters.

	$processed_stageone = $process_text;
 	$processed_stageone =~ tr#a-zA-Z0-9##cd;
	$processed_stageone =~ tr/A-Z/a-z/;

	# Now set the second stage value of the processed filename
	# to the first stage value of the processed filename and
	# then limit the filename down to 32 characters.

	$processed_stagetwo = $processed_stageone;
	$processed_length = length($processed_stagetwo);

	# Process the second stage filename into the final 
	# filename and do so until the seek counter is 32
	# or reaches the length of the second stage filename.

	do {

		# Get the character that is the seek counter
		# is set at.

		$processed_char = substr($processed_stagetwo, $processed_seek, 1);

		# Append to the final processed filename.

		$processed_filename = $processed_filename . $processed_char;

		# Increment the seek counter.

		$processed_seek++;

	} until ($processed_seek eq 32 || $processed_seek eq $processed_length);

	return $processed_filename;

}


sub xestiascan_processconfig{
#################################################################################
# xestiascan_processconfig: Processes an INI style configuration file.		#
#										#
# Usage:									#
#										#
# xestiascan_processconfig(data);						#
#										#
# data	Specifies the data to process.						#
#################################################################################

	my (@settings) = @_;

	my ($settings_line, %settings, $settings, $sectionname, $setting_name, $setting_value);

	foreach $settings_line (@settings){

		next if !$settings_line;

		# Check if the first character is a bracket.

		if (substr($settings_line, 0, 1) eq "["){
			$settings_line =~ s/\[//;
			$settings_line =~ s/\](.*)//;
			$settings_line =~ s/\n//;
			$sectionname = $settings_line;
			next;
		}

		$setting_name  = $settings_line;
		$setting_value = $settings_line;
		$setting_name  =~ s/\=(.*)//;
		$setting_name  =~ s/\n//;
		$setting_value =~ s/(.*)\=//;
		$setting_value =~ s/\n//;

		# Remove the spacing before and after the '=' sign.

		$setting_name =~ s/\s+$//;
		$setting_value =~ s/^\s+//;
		$setting_value =~ s/\r//;

		$settings{$sectionname}{$setting_name} = $setting_value;

	}

 	return %settings;

}

sub xestiascan_output_page{
#################################################################################
# xestiascan_output_page: Outputs the page to the browser/stdout/console.	#
#										#
# Usage:									#
# 										#
# xestiascan_output_page(pagetitle, pagedata, menutype);			#
# 										#
# pagetitle	Specifies the page title.					#
# pagedata	Specifies the page data.					#
# menutype	Prints out which menu to use.					#
#################################################################################

	my ($pagetitle, $pagedata, $menutype) = @_;

	# Open the script page template and load it into the scriptpage variable,
	# while declaring the variable.

	open (my $filehandle_scriptpage, "<:utf8", 'page.html');
	my @scriptpage = <$filehandle_scriptpage>;
	binmode $filehandle_scriptpage, ':utf8';
	close ($filehandle_scriptpage);

	my $query_lite = new CGI::Lite;
	my $form_data = $query_lite->parse_form_data;	

	# Define the variables required.

	my $scriptpageline = "";
	my $pageoutput = "";

	$main::xestiascan_presmodule->clear();

	# Print out the main menu for Xestia Scanner Server.

	if ($menutype ne "none"){
	
		$main::xestiascan_presmodule->addlink($main::xestiascan_env{'script_filename'} . "?mode=scan", { Text => $main::xestiascan_lang{menu}{scanconfig} });
		$main::xestiascan_presmodule->addtext(" | ");
		$main::xestiascan_presmodule->addlink($main::xestiascan_env{'script_filename'} . "?mode=users", { Text => $main::xestiascan_lang{menu}{userconfig} });
		$main::xestiascan_presmodule->addtext(" | ");
		$main::xestiascan_presmodule->addlink($main::xestiascan_env{'script_filename'} . "?mode=settings", { Text => $main::xestiascan_lang{menu}{settingsconfig} });
		$main::xestiascan_presmodule->addtext(" | ");
		$main::xestiascan_presmodule->addlink($main::xestiascan_env{'script_filename'} . "?mode=logout", { Text => $main::xestiascan_lang{menu}{logout} });

		$main::xestiascan_presmodule->addlinebreak();
		
	}

	my $menuoutput = $main::xestiascan_presmodule->grab();

	# Find <xestiascan> tages and replace with the apporiate variables.

	foreach $scriptpageline (@scriptpage){

 		$scriptpageline =~ s/<xestiascan:menu>/$menuoutput/g;
		$scriptpageline =~ s/<xestiascan:imagespath>/$main::xestiascan_config{"directory_noncgi_images"}/g;
		$scriptpageline =~ s/<xestiascan:pagedata>/$pagedata/g;

		# Check if page title specified is blank, otherwise add a page title
		# to the title.

		if (!$pagetitle || $pagetitle eq ""){
			$scriptpageline =~ s/<xestiascan:title>//g;
		} else {
			$scriptpageline =~ s/<xestiascan:title>/ ($pagetitle)/g;
		}

		

		# Append processed line to the pageoutput variable.

		$pageoutput = $pageoutput . $scriptpageline;

	}

	print $pageoutput;

	return;

}

1;