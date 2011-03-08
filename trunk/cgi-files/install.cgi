#!/usr/bin/perl -Tw

#################################################################################
# Xestia Scanner Server Installer Script (install.cgi)				#
# Installation script for Xestia Scanner Server	     				#
#										#
# Version: 0.1.0								#
#										#
# Copyright (C) 2005-2011 Steve Brokenshire <sbrokenshire@xestia.co.uk>		#
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

# TODO: ADD SCANNED IMAGES (FS & URI LOCATIONS) TO THE INSTALLED!!!

use strict;				# Throw errors if there's something wrong.
use warnings;				# Write warnings to the HTTP Server Log file.

use Cwd qw(abs_path cwd);

use utf8;

eval "use CGI::Lite";

if ($@){
	print "Content-type: text/html; charset=utf-8;\r\n\r\n";
	print "The CGI::Lite Perl Module is not installed. Please install CGI::Lite and then run this installation script again. CGI::Lite can be installed through CPAN.";
	exit;
}

eval "use Tie::IxHash";

if ($@){
	print "Content-type: text/html; charset=utf-8;\r\n\r\n";
	print "The Tie::IxHash Perl Module is not installed. Please install Tie::IxHash and then run this installation script again. Tie::IxHash can be installed through CPAN.";
	exit;
}

# Check if mod_perl is running and if it is then add a notice to say
# that additional configuration has to be made.

my $modperlenabled = 0;
my $installscriptname = "install.cgi";
my $multiuserinstallscriptname = "install-multiuser.cgi";
my $xestiascanscriptname = "xsdss.cgi";

#if ($ENV{'MOD_PERL'}){

	# MOD_PERL 2.X SPECIFIC SECTION.

#	use lib '';
#	chdir('');

#	$modperlenabled 	= 1;
#	$installscriptname 	= "install.pl";
#	$xestiascanscriptname 	= "kiriwrite.pl";

#}

# Setup strings in specific languages. Style should be no spacing for
# language title and one tabbed spacing for each string.

# Define some default settings.

my $default_language 		= "en-GB";
my $default_imagesuri		= "/images/xestiascan";
my $default_scansuri		= "/images/xestiascan/scans";

my $default_scansfs		= abs_path("..") . "/images/xestiascan/scans";

my $default_outputmodule	= "Normal";

my $default_server		= "localhost";
my $default_port		= "5432";
my $default_protocol		= "tcp";
my $default_name		= "database";
my $default_username		= "username";
my $default_prefix		= "xestiascan";

my ($xestiascan_lang, %xestiascan_lang);

$xestiascan_lang{"en-GB"}{"languagename"}	= "English (British)";
	$xestiascan_lang{"en-GB"}{"testpass"}		= "OK";
	$xestiascan_lang{"en-GB"}{"testfail"}		= "Error";

	$xestiascan_lang{"en-GB"}{"generic"}			= "An error occured which is not known to the Xestia Scanner Server installer.";
	$xestiascan_lang{"en-GB"}{"invalidvariable"}		= "The variable given was invalid.";
	$xestiascan_lang{"en-GB"}{"invalidvalue"}		= "The value given was invalid.";
	$xestiascan_lang{"en-GB"}{"invalidoption"}		= "The option given was invalid.";
	$xestiascan_lang{"en-GB"}{"variabletoolong"}		= "The variable given is too long.";
	$xestiascan_lang{"en-GB"}{"blankdirectory"}		= "The directory name given is blank.";
	$xestiascan_lang{"en-GB"}{"invaliddirectory"}		= "The directory name given is invalid.";
	$xestiascan_lang{"en-GB"}{"moduleblank"}			= "The module filename given is blank.";
	$xestiascan_lang{"en-GB"}{"moduleinvalid"}		= "The module filename given is invalid.";

	$xestiascan_lang{"en-GB"}{"authdirectorytoolong"}	= "The authentication directory name given is too long.";
	$xestiascan_lang{"en-GB"}{"outputdirectorytoolong"}	= "The output directory name given is too long.";
	$xestiascan_lang{"en-GB"}{"imagesuripathtoolong"}	= "The images URI path name given is too long.";
	$xestiascan_lang{"en-GB"}{"scansuripathtoolong"}	= "The scans URI path name given is too long.";
	$xestiascan_lang{"en-GB"}{"scansfspathtoolong"}		= "The scans filesystem path name given is too long.";
	$xestiascan_lang{"en-GB"}{"dateformattoolong"}		= "The date format given is too long.";
	$xestiascan_lang{"en-GB"}{"customdateformattoolong"}	= "The custom date format given is too long.";
	$xestiascan_lang{"en-GB"}{"languagefilenametoolong"}	= "The language filename given is too long.";

	$xestiascan_lang{"en-GB"}{"dateformatblank"}		= "The date format given was blank.";
	$xestiascan_lang{"en-GB"}{"dateformatinvalid"}		= "The date format given is invalid.";
	$xestiascan_lang{"en-GB"}{"languagefilenameinvalid"}	= "The language filename given is invalid.";

	$xestiascan_lang{"en-GB"}{"authdirectoryblank"}		= "The authentication directory name given is blank.";
	$xestiascan_lang{"en-GB"}{"authdirectoryinvalid"}	= "The authentication directory name given is invalid.";

	$xestiascan_lang{"en-GB"}{"outputdirectoryblank"}	= "The output directory name given is blank.";
	$xestiascan_lang{"en-GB"}{"outputdirectoryinvalid"}	= "The output directory name given is invalid.";

	$xestiascan_lang{"en-GB"}{"textarearowblank"}		= "The text area row value given is blank.";
	$xestiascan_lang{"en-GB"}{"textarearowtoolong"}		= "The text area row value given is too long.";
	$xestiascan_lang{"en-GB"}{"textarearowinvalid"}		= "The text area row value given is invalid.";

	$xestiascan_lang{"en-GB"}{"textareacolsblank"}		= "The text area columns value given is blank.";
	$xestiascan_lang{"en-GB"}{"textareacolstoolong"}		= "The text area columns value given is too long.";
	$xestiascan_lang{"en-GB"}{"textareacolsinvalid"}		= "The text area columns value given is invalid.";

	$xestiascan_lang{"en-GB"}{"presmoduleblank"}		= "The presentation module name given is blank.";
	$xestiascan_lang{"en-GB"}{"presmoduleinvalid"}		= "The presentation module name given is invalid.";

	$xestiascan_lang{"en-GB"}{"authmoduleblank"}		= "The authentication module name given is blank.";
	$xestiascan_lang{"en-GB"}{"authmoduleinvalid"}		= "The authentication module name given is invalid.";
 
	$xestiascan_lang{"en-GB"}{"outputmoduleblank"}		= "The output module name given is blank.";
	$xestiascan_lang{"en-GB"}{"outputmoduleinvalid"}	= "The output module name given is invalid.";
 
	$xestiascan_lang{"en-GB"}{"presmodulemissing"}		= "The presentation module with the filename given is missing.";
	$xestiascan_lang{"en-GB"}{"outputmodulemissing"}		= "The output module with the filename given is missing.";
	$xestiascan_lang{"en-GB"}{"authmodulemissing"}		= "The authentication module with the filename given is missing.";
	$xestiascan_lang{"en-GB"}{"languagefilenamemissing"}	= "The language file with the filename given is missing.";
 
	$xestiascan_lang{"en-GB"}{"servernametoolong"}		= "The database server name given is too long.";
	$xestiascan_lang{"en-GB"}{"servernameinvalid"}		= "The database server name given is invalid.";
	$xestiascan_lang{"en-GB"}{"serverportnumbertoolong"}	= "The database server port number given is too long.";
	$xestiascan_lang{"en-GB"}{"serverportnumberinvalidcharacters"}	= "The database server port number given contains invalid characters.";
	$xestiascan_lang{"en-GB"}{"serverportnumberinvalid"}	= "The database server port number given is invalid.";
	$xestiascan_lang{"en-GB"}{"serverprotocolnametoolong"}	= "The database server protocol name given is too long.";
	$xestiascan_lang{"en-GB"}{"serverprotocolinvalid"}		= "The database server protocol name is invalid.";
	$xestiascan_lang{"en-GB"}{"serverdatabasenametoolong"}	= "The database name given is too long.";
	$xestiascan_lang{"en-GB"}{"serverdatabasenameinvalid"}	= "The database name given is invalid.";
	$xestiascan_lang{"en-GB"}{"serverdatabaseusernametoolong"}	= "The database server username given is too long.";
	$xestiascan_lang{"en-GB"}{"serverdatabaseusernameinvalid"}	= "The database server username given is invalid.";
	$xestiascan_lang{"en-GB"}{"serverdatabasepasswordtoolong"}	= "The database server password is too long.";
	$xestiascan_lang{"en-GB"}{"serverdatabasetableprefixtoolong"}	= "The database server table prefix given is too long.";
	$xestiascan_lang{"en-GB"}{"serverdatabasetableprefixinvalid"}	= "The database server table prefix given is invalid.";
 
	$xestiascan_lang{"en-GB"}{"removeinstallscripttoolong"}	= "The remove installer script value given is too long.";
	$xestiascan_lang{"en-GB"}{"removemultiuserinstallscripttoolong"}	= "The remove multiuser installer script value given is too long.";
	$xestiascan_lang{"en-GB"}{"cannotwriteconfigurationindirectory"}	= "The configuration file cannot be written because the directory the install script is running from has invalid permissions.";
	$xestiascan_lang{"en-GB"}{"configurationfilereadpermissionsinvalid"}	= "The configuration that currently exists has invalid read permissions set.";
	$xestiascan_lang{"en-GB"}{"configurationfilewritepermissionsinvalid"}	= "The configuration that currently exists has invalid write permissions set.";

	$xestiascan_lang{"en-GB"}{"errormessagetext"}	= "Please press the back button on your browser or preform the command needed to return to the previous page.";

	$xestiascan_lang{"en-GB"}{"switch"}		= "Switch";
	$xestiascan_lang{"en-GB"}{"setting"}		= "Setting";
	$xestiascan_lang{"en-GB"}{"value"}		= "Value";
	$xestiascan_lang{"en-GB"}{"filename"}		= "Filename";
	$xestiascan_lang{"en-GB"}{"module"}		= "Module";
	$xestiascan_lang{"en-GB"}{"result"}		= "Result";
	$xestiascan_lang{"en-GB"}{"requiredver"}	= "Required Version";
	$xestiascan_lang{"en-GB"}{"installedver"}	= "Installed Version";
	$xestiascan_lang{"en-GB"}{"error"}		= "Error!";
	$xestiascan_lang{"en-GB"}{"criticalerror"}	= "Critical Error!";
	$xestiascan_lang{"en-GB"}{"errormessage"}	= "Error: ";
	$xestiascan_lang{"en-GB"}{"warningmessage"}	= "Warning: ";

	$xestiascan_lang{"en-GB"}{"doesnotexist"}	= "Does not exist.";
	$xestiascan_lang{"en-GB"}{"invalidpermissionsset"}	= "Invalid permissions set.";

	$xestiascan_lang{"en-GB"}{"dependencyperlmodulesmissing"}	= "One or more Perl modules that are needed by Xestia Scanner Server are not installed or has problems. See the Xestia Scanner Server documentation for more information on this.";
	$xestiascan_lang{"en-GB"}{"databaseperlmodulesmissing"}	= "One or more Perl modules that are needed by the Xestia Scanner Server database modules are not installed or has problems. See the Xestia Scanner Server documentation for more information on this. There should however, be no problems with the database modules which use the Perl modules that have been found.";
	$xestiascan_lang{"en-GB"}{"filepermissionsinvalid"}	= "One or more of the filenames checked does not exist or has invalid permissions set. See the Xestia Scanner Server documentation for more information on this.";
	$xestiascan_lang{"en-GB"}{"dependencymodulesnotinstalled"} 	= "One of the required Perl modules is not installed or has errors. See the Xestia Scanner Server documentation for more information on this.";
	$xestiascan_lang{"en-GB"}{"databasemodulesnotinstalled"}	= "None of Perl modules that are used by the authentication modules are not installed. See the Xestia Scanner Server documentation for more information on this.";
	$xestiascan_lang{"en-GB"}{"filepermissionerrors"}	= "One or more filenames checked has errors. See the Xestia Scanner Server documentation for more information on this.",

	$xestiascan_lang{"en-GB"}{"installertitle"}	= "Xestia Scanner Server Installer";
	$xestiascan_lang{"en-GB"}{"installertext"}	= "This installer script will setup the configuration file used for Xestia Scanner Server. The settings displayed here can be changed at a later date by selecting the Edit Settings link in the View Settings sub-menu.";
	$xestiascan_lang{"en-GB"}{"modperlnotice"}	= "mod_perl has been detected. Please ensure that you have setup this script and the main Xestia Scanner Server script so that mod_perl can use Xestia Scanner Server properly. Please read the mod_perl specific part of Chapter 1: Installation in the Xestia Scanner Server documentation.";
	$xestiascan_lang{"en-GB"}{"dependencytitle"}	= "Dependency and file testing results";
	$xestiascan_lang{"en-GB"}{"requiredmodules"}	= "Required Modules";
	$xestiascan_lang{"en-GB"}{"perlmodules"}	= "These Perl modules are used by Xestia Scanner Server and can be downloaded from CPAN if they are missing. Please check and compare the required and installed versions as installed modules that do not meet the required version may cause Xestia Scanner Server to not work properly.";
	$xestiascan_lang{"en-GB"}{"databasemodules"}	= "Perl Database Modules";
	$xestiascan_lang{"en-GB"}{"databasemodulestext"}= "These Perl modules are used by the authentication modules.";
	$xestiascan_lang{"en-GB"}{"filepermissions"}	= "File permissions";
	$xestiascan_lang{"en-GB"}{"filepermissionstext"}	= "The file permissions are for file and directories that are critical to Xestia Scanner Server such as module and language directories.";
	
	$xestiascan_lang{"en-GB"}{"settingstitle"}	= "Xestia Scanner Server Settings";
	$xestiascan_lang{"en-GB"}{"settingstext"}	= "The settings given here will be used by Xestia Scanner Server. Some default settings are given here. Certain database modules (like SQLite) do not need the database server settings and can be left alone.";
	$xestiascan_lang{"en-GB"}{"directories"}	= "Directories";
	$xestiascan_lang{"en-GB"}{"databasedirectory"}	= "Database Directory";
	$xestiascan_lang{"en-GB"}{"outputdirectory"}	= "Output Directory";
	$xestiascan_lang{"en-GB"}{"imagesuripath"}	= "Images (URI path)";
	$xestiascan_lang{"en-GB"}{"scansuripath"}	= "Scans (URI path)";
	$xestiascan_lang{"en-GB"}{"scansfspath"}	= "Scans (Filesystem path)";
	$xestiascan_lang{"en-GB"}{"display"}		= "Display";
	$xestiascan_lang{"en-GB"}{"textareacols"}	= "Text Area Columns";
	$xestiascan_lang{"en-GB"}{"textarearows"}	= "Text Area Rows";
	$xestiascan_lang{"en-GB"}{"date"}		= "Date";
	$xestiascan_lang{"en-GB"}{"dateformat"}		= "Date Format";
	$xestiascan_lang{"en-GB"}{"language"}		= "Language";
	$xestiascan_lang{"en-GB"}{"systemlanguage"}	= "System Language";
	$xestiascan_lang{"en-GB"}{"modules"}		= "Modules";
	$xestiascan_lang{"en-GB"}{"presentationmodule"}	= "Presentation Module";
	$xestiascan_lang{"en-GB"}{"outputmodule"}	= "Output Module";
	$xestiascan_lang{"en-GB"}{"authmodule"}		= "Authentication Module";
	$xestiascan_lang{"en-GB"}{"databaseserver"}	= "Database Server";
	$xestiascan_lang{"en-GB"}{"databaseport"}	= "Database Port";
	$xestiascan_lang{"en-GB"}{"databaseprotocol"}	= "Database Protocol";
	$xestiascan_lang{"en-GB"}{"databasename"}	= "Database Name";
	$xestiascan_lang{"en-GB"}{"databaseusername"}	= "Database Username";
	$xestiascan_lang{"en-GB"}{"databasepassword"}	= "Database Password";
	$xestiascan_lang{"en-GB"}{"databasetableprefix"}	= "Database Table Prefix";
	$xestiascan_lang{"en-GB"}{"installationoptions"}	= "Installation Options";
	$xestiascan_lang{"en-GB"}{"installoptions"}	= "Install Options";
	$xestiascan_lang{"en-GB"}{"removeinstallscript"}	= "Delete this installer script after configuration file has been written.";
	$xestiascan_lang{"en-GB"}{"removemultiuserinstallscript"}	= "Delete the multiuser installer script if not needed.";
	$xestiascan_lang{"en-GB"}{"savesettingsbutton"}	= "Save Settings";
	$xestiascan_lang{"en-GB"}{"resetsettingsbutton"}	= "Reset Settings";

	$xestiascan_lang{"en-GB"}{"installscriptremoved"}	= "The installer script was removed.";
	$xestiascan_lang{"en-GB"}{"installedmessage"}	= "The configuration file for Xestia Scanner Server has been written. To change the settings in the configuration file at a later date use the Edit Settings link in the View Settings sub-menu at the top of the page when using Xestia Scanner Server.";
	$xestiascan_lang{"en-GB"}{"cannotremovescript"}	= "Unable to remove the installer script: %s. The installer script will have to be deleted manually.";
	$xestiascan_lang{"en-GB"}{"cannotremovemultiuserscript"}	= "Unable to remove the multiuser installer script: %s. The installer script will have to be deleted manually.";
	$xestiascan_lang{"en-GB"}{"usexestiascannerservertext"}	= "To use Xestia Scanner Server click or select the link below (will not work if the Xestia Scanner Server script is not called xsdss.cgi):";
	$xestiascan_lang{"en-GB"}{"usexestiascannerserverlink"}	= "Start using Xestia Scanner Server.";

	$xestiascan_lang{"en-GB"}{"multiuserinstall"} = "The authentication module selected requires additional setup. Please click on the multiuser installer link below for more instructions.";
	$xestiascan_lang{"en-GB"}{"multiuserinstalllink"} = "Start the Multiuser Installer.";

my $query_lite = new CGI::Lite;
my $form_data = $query_lite->parse_form_data;

my $language_selected = "";
my $http_query_confirm = $form_data->{'confirm'};
my $http_query_installlanguage = $form_data->{'installlanguage'};

if (!$http_query_installlanguage){

	$language_selected = $default_language;

} else {

	$language_selected = $http_query_installlanguage;

}

# Process the list of available languages.

my $language_list_name;
my @language_list_short;
my @language_list_long;

foreach my $language (keys %xestiascan_lang){

	$language_list_name = $xestiascan_lang{$language}{"languagename"} . " (" . $language .  ")";
	push(@language_list_short, $language);
	push(@language_list_long, $language_list_name);

}

# The CSS Stylesheet to use.

my $cssstyle = "

a {
	color: #FFFFFF;
}

body {
	margin: 0px; 
	font-family: sans-serif; 
	padding: 0px; 
	font-size: 13px;
	background-color: #402040;
	color: #ffffff;
	background-image: url('/images/xestiascan/pagebackground.png');
	background-repeat: repeat-x;
}

td,table {
	padding: 5px;
	border-spacing: 0px;
}

.languagebar {
	background-color: #204040;
	vertical-align: top;
}

.languagebarselect {
	text-align: right;
	background-color: #204040;
}

.tablecellheader {
	font-size: 12px;
	background-color: #703570;	
	font-weight: bold;
	text-align: left;
	background-image: url('/images/xestiascan/tabletop.png');
	background-repeat: repeat-x;
}

.tabledata {
	background-color: #603060;
}

.topbar {
	padding: 3px;
	background-color: #753575;
	border-bottom-style: solid;
	border-bottom-width: 1px;
	border-bottom-color: #EE70EE;
	text-align: right;
	min-height: 17px;
	background-image: url('/images/xestiascan/menutop.png');
	background-repeat: repeat-x;
}

.title {
	font-size: 16px;
	font-weight: bold;
	position: absolute;
	text-align: left;
	z-index: 0;
	left: 0;
	padding-left: 3px;
}

.pageheader {
	font-size: 18px;
	font-weight: bold;
}

.subheader {
	font-size: 14px;
	font-weight: bold;
}

.tablename {

	background-color: #301530;

}

.pagespacing {

	padding: 3px;

}

";


#################################################################################
# Begin list of subroutines.							#
#################################################################################

sub xestiascan_variablecheck{
#################################################################################
# xestiascan_variablecheck: Check to see if the data passed is valid.		#
#										#
# Usage:									#
#										#
# xestiascan_variablecheck(variablename, type, option, noerror);		#
#										#
# variablename	Specifies the variable to be checked.				#
# type		Specifies what type the variable is.				#
# option	Specifies the maximum/minimum length of the variable		#
#		(if minlength/maxlength is used) or if the filename should be   #
#		checked to see if it is blank.					#
# noerror	Specifies if Kiriwrite should return an error or not on		#
#		certain values.							#
#################################################################################

	# Get the values that were passed to the subroutine.

	my ($variable_data, $variable_type, $variable_option, $variable_noerror) = @_;

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

				xestiascan_error("dateformatblank");

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

				xestiascan_error("dateformatinvalid");

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

				xestiascan_error("languagefilenameblank");

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

					xestiascan_error("languagefilenameinvalid");

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

sub xestiascan_error{
#################################################################################
# xestiascan_error: Subroutine for processing error messages.			#
#										#
# Usage:									#
#										#
# xestiascan_error(errortype);							#
#										#
# errortype	Specifies the error type to use.				#
#################################################################################

	my $error_type = shift;

	# Load the list of error messages.

	my (%xestiascan_error, $xestiascan_error);

	%xestiascan_error = (

		# Generic Error Messages

		"generic"			=> $xestiascan_lang{$language_selected}{generic},

		"invalidvariable"		=> $xestiascan_lang{$language_selected}{invalidvariable},
		"invalidvalue"			=> $xestiascan_lang{$language_selected}{invalidvalue},
		"invalidoption"			=> $xestiascan_lang{$language_selected}{invalidoption},
		"variabletoolong"		=> $xestiascan_lang{$language_selected}{variabletoolong},
		"blankdirectory"		=> $xestiascan_lang{$language_selected}{blankdirectory},
		"invaliddirectory"		=> $xestiascan_lang{$language_selected}{invaliddirectory},
		"moduleblank"			=> $xestiascan_lang{$language_selected}{moduleblank},
		"moduleinvalid"			=> $xestiascan_lang{$language_selected}{moduleinvalid},

		# Specific Error Messages

		"authdirectorytoolong" 		=> $xestiascan_lang{$language_selected}{dbdirectorytoolong},
		"outputdirectorytoolong"	=> $xestiascan_lang{$language_selected}{outputdirectorytoolong},
		"imagesuripathtoolong"		=> $xestiascan_lang{$language_selected}{imagesuripathtoolong},
		"dateformattoolong"		=> $xestiascan_lang{$language_selected}{dateformattoolong},
		"customdateformattoolong"	=> $xestiascan_lang{$language_selected}{customdateformattoolong},
		"languagefilenametoolong"	=> $xestiascan_lang{$language_selected}{languagefilenametoolong},
		
		"dateformatblank"		=> $xestiascan_lang{$language_selected}{dateformatblank},
		"dateformatinvalid"		=> $xestiascan_lang{$language_selected}{dateformatinvalid},
		"languagefilenameinvalid"	=> $xestiascan_lang{$language_selected}{languagefilenameinvalid},
		
		"dbdirectoryblank"		=> $xestiascan_lang{$language_selected}{dbdirectoryblank},
		"dbdirectoryinvalid"		=> $xestiascan_lang{$language_selected}{dbdirectoryinvalid},

		"textarearowblank"		=> $xestiascan_lang{$language_selected}{textarearowblank},
		"textarearowtoolong"		=> $xestiascan_lang{$language_selected}{textarearowtoolong},
		"textarearowinvalid"		=> $xestiascan_lang{$language_selected}{textarearowinvalid},

		"textareacolsblank"		=> $xestiascan_lang{$language_selected}{textareacolsblank},
		"textareacolstoolong"		=> $xestiascan_lang{$language_selected}{textareacolstoolong},
		"textareacolsinvalid"		=> $xestiascan_lang{$language_selected}{textareacolsinvalid},

		"outputdirectoryblank"		=> $xestiascan_lang{$language_selected}{outputdirectoryblank},
		"outputdirectoryinvalid"	=> $xestiascan_lang{$language_selected}{outputdirectoryinvalid},

		"presmoduleblank"		=> $xestiascan_lang{$language_selected}{presmoduleblank},
		"presmoduleinvalid"		=> $xestiascan_lang{$language_selected}{presmoduleinvalid},

		"authmoduleblank"		=> $xestiascan_lang{$language_selected}{authmoduleblank},
		"authmoduleinvalid"		=> $xestiascan_lang{$language_selected}{authmoduleinvalid},

		"presmodulemissing"		=> $xestiascan_lang{$language_selected}{presmodulemissing},
		"authmodulemissing"		=> $xestiascan_lang{$language_selected}{authmodulemissing},
		"languagefilenamemissing"	=> $xestiascan_lang{$language_selected}{languagefilenamemissing},

		"servernametoolong"		=> $xestiascan_lang{$language_selected}{servernametoolong},
		"servernameinvalid"		=> $xestiascan_lang{$language_selected}{servernameinvalid},
		"serverportnumbertoolong"	=> $xestiascan_lang{$language_selected}{serverportnumbertoolong},
		"serverportnumberinvalidcharacters"	=> $xestiascan_lang{$language_selected}{serverportnumberinvalidcharacters},
		"serverportnumberinvalid"	=> $xestiascan_lang{$language_selected}{serverportnumberinvalid},
		"serverprotocolnametoolong"	=> $xestiascan_lang{$language_selected}{serverprotocolnametoolong},
		"serverprotocolinvalid"		=> $xestiascan_lang{$language_selected}{serverprotocolinvalid},
		"serverdatabasenametoolong"	=> $xestiascan_lang{$language_selected}{serverdatabasenametoolong},
		"serverdatabasenameinvalid"	=> $xestiascan_lang{$language_selected}{serverdatabasenameinvalid},
		"serverdatabaseusernametoolong"	=> $xestiascan_lang{$language_selected}{serverdatabaseusernametoolong},
		"serverdatabaseusernameinvalid"	=> $xestiascan_lang{$language_selected}{serverdatabaseusernameinvalid},
		"serverdatabasepasswordtoolong"	=> $xestiascan_lang{$language_selected}{serverdatabasepasswordtoolong},
		"serverdatabasetableprefixtoolong"	=> $xestiascan_lang{$language_selected}{serverdatabasetableprefixtoolong},
		"serverdatabasetableprefixinvalid"	=> $xestiascan_lang{$language_selected}{serverdatabasetableprefixinvalid},

		"removeinstallscripttoolong"	=> $xestiascan_lang{$language_selected}{removeinstallscripttoolong},
		"cannotwriteconfigurationindirectory"	=> $xestiascan_lang{$language_selected}{cannotwriteconfigurationindirectory},
		"configurationfilereadpermissionsinvalid"	=> $xestiascan_lang{$language_selected}{configurationfilereadpermissionsinvalid},
		"configurationfilewritepermissionsinvalid"	=> $xestiascan_lang{$language_selected}{configurationfilewritepermissionsinvalid},

	);

	# Check if the specified error is blank and if it is
	# use the generic error messsage.

	if (!$xestiascan_error{$error_type}){
		$error_type = "generic";
	}

	print "Content-type: text/html; charset=utf-8;\r\n\r\n";

	print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
	print "<head>\n<title>$xestiascan_lang{$language_selected}{installertitle}</title>\n<style type=\"text/css\" media=\"screen\">$cssstyle</style>\n</head>\n<body>\n";

	print "<h2>$xestiascan_lang{$language_selected}{error}</h2>";

	print $xestiascan_error{$error_type};
	print "<br />\n";
	print $xestiascan_lang{$language_selected}{errormessagetext};

	print "</body>\n</html>";

	exit;

}

sub xestiascan_writeconfig{
#################################################################################
# xestiascan_writeconfig: Writes a configuration file.				#
#										#
# Usage:									#
#										#
# xestiascan_writeconfig();							#
#################################################################################

	my ($passedsettings) = @_;

	# Open the configuration file for writing.

	open (my $configfile, "> " . "xsdss.cfg");

	print $configfile "[config]
directory_noncgi_images = $passedsettings->{ImagesURIPath}
directory_noncgi_scans = $passedsettings->{ScansURIPath}
directory_fs_scans = $passedsettings->{ScansFSPath}

system_language = $passedsettings->{Language}
system_presmodule = $passedsettings->{PresentationModule}
system_outputmodule = $passedsettings->{OutputModule}
system_authmodule = $passedsettings->{AuthModule}
system_datetime = $passedsettings->{DateFormat}
		
database_server = $passedsettings->{DatabaseServer}
database_port = $passedsettings->{DatabasePort}
database_protocol = $passedsettings->{DatabaseProtocol}
database_sqldatabase = $passedsettings->{DatabaseName}
database_username = $passedsettings->{DatabaseUsername}
database_password = $passedsettings->{DatabasePassword}
database_tableprefix = $passedsettings->{DatabaseTablePrefix}
	";

	close ($configfile);
	
	# Set the correct permissions for the file.
	
	chmod (0660, "xsdss.cfg");

}

sub xestiascan_addtablerow{
#################################################################################
# xestiascan_addtablerow: Adds a table row.					#
#										#
# Usage:									#
#										#
# xestiascan_addtablerow(name, data);						#
#										#
# name		Specifies the name of the table row.				#
# namestyle	Specifies the style for the name of the table row.		#
# data		Specifies the data to be used in the table row.			#
# datastyle	Specifies the style for the data of the table row.		#
#################################################################################

	#my ($name, $namestyle, $data, $datastyle) = @_;

	my $tablecell;

	print "<tr>\n";
	
	my $data;
	my $datastyle;
	
	while (@_){

		$data		= shift @_;
		$datastyle	= shift @_;
		
		if (!$data){
			
			$data = "";
			
		}

		if (!$datastyle){
			
			$datastyle = "";
			
		}
		
		print "<td class=\"$datastyle\">$data</td>\n";

		$data = "";
		$datastyle = "";
		
		
	}	

	print "</tr>\n";
	
	#print "<tr>\n";
	#print "<td class=\"$namestyle\">$name</td>\n";
	#print "<td class=\"$datastyle\">$data</td>\n";
	#print "</tr>\n";

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

#################################################################################
# End list of subroutines.							#
#################################################################################

if (!$http_query_confirm){

	$http_query_confirm = 0;

}

if ($http_query_confirm eq 1){

	# The confirm value has been given so get the data from the query.

	my $http_query_imagesuripath		= $form_data->{'imagesuripath'};
	my $http_query_scansuripath		= $form_data->{'scansuripath'};
	my $http_query_scansfspath		= $form_data->{'scansfspath'};

	my $http_query_dateformat		= $form_data->{'dateformat'};
	my $http_query_customdateformat		= $form_data->{'customdateformat'};

	my $http_query_language			= $form_data->{'language'};

	my $http_query_presmodule		= $form_data->{'presmodule'};
	my $http_query_outputmodule		= $form_data->{'outputmodule'};
	my $http_query_authmodule		= $form_data->{'authmodule'};

	my $http_query_databaseserver		= $form_data->{'databaseserver'};
	my $http_query_databaseport		= $form_data->{'databaseport'};
	my $http_query_databaseprotocol		= $form_data->{'databaseprotocol'};
 	my $http_query_databasename		= $form_data->{'databasename'};
 	my $http_query_databaseusername		= $form_data->{'databaseusername'};
 	my $http_query_databasepassword		= $form_data->{'databasepassword'};
 	my $http_query_databasetableprefix	= $form_data->{'databasetableprefix'};
	
 	my $http_query_removeinstallscript	= $form_data->{'removeinstallscript'};
 	my $http_query_removemultiuserinstallscript	= $form_data->{'removemultiuserinstallscript'};

	# Check the length of the variables.

	my $xestiascan_imagesuripath_length_check 	= xestiascan_variablecheck($http_query_imagesuripath, "maxlength", 512, 1);
	my $xestiascan_scansuripath_length_check 	= xestiascan_variablecheck($http_query_scansuripath, "maxlength", 512, 1);
	my $xestiascan_scansfspath_length_check 	= xestiascan_variablecheck($http_query_scansfspath, "maxlength", 4096, 1);
	my $xestiascan_dateformat_length_check 		= xestiascan_variablecheck($http_query_dateformat, "maxlength", 32, 1);
	my $xestiascan_customdateformat_length_check	= xestiascan_variablecheck($http_query_customdateformat, "maxlength", 32, 1);
	my $xestiascan_language_length_check		= xestiascan_variablecheck($http_query_language, "maxlength", 16, 1);

	# Check if any errors occured while checking the
	# length of the variables.

	if ($xestiascan_imagesuripath_length_check eq 1){

		# The images URI path given is too long
		# so return an error.

		xestiascan_error("imagesuripathtoolong");

	}
	
	if ($xestiascan_scansuripath_length_check eq 1){
		
		# The scans URI path given is too long
		# so return an error.
		
		xestiascan_error("scansuripathtoolong");
		
	}
	
	if ($xestiascan_scansfspath_length_check eq 1){
		
		# The scans filesystem path given is too long
		# so return an error.
		
		xestiascan_error("scansfspathtoolong");
		
	}

	if ($xestiascan_dateformat_length_check eq 1){

		# The date format given is too long
		# so return an error.

		xestiascan_error("dateformattoolong");

	}

	if ($xestiascan_customdateformat_length_check eq 1){

		# The date format given is too long
		# so return an error.

		xestiascan_error("customdateformattoolong");

	}

	if ($xestiascan_language_length_check eq 1){

		# The language filename given is too long
		# so return an error.

		xestiascan_error("languagefilenametoolong");

	}

	# Check if the custom date and time setting has anything
	# set and if it doesn't then use the predefined one set.

	my $finaldateformat = "";

	if ($http_query_customdateformat ne ""){

		$finaldateformat = $http_query_customdateformat;

	} else {

		$finaldateformat = $http_query_dateformat;

	}

	my $xestiascan_datetime_check		= xestiascan_variablecheck($finaldateformat, "datetime", 0, 1);

	if ($xestiascan_datetime_check eq 1){

		# The date and time format is blank so return
		# an error.

		xestiascan_error("dateformatblank");

	} elsif ($xestiascan_datetime_check eq 2){

		# The date and time format is invalid so
		# return an error.

		xestiascan_error("dateformatinvalid");

	}

	# Check if the language filename given is valid.

	my $xestiascan_language_languagefilename_check = xestiascan_variablecheck($http_query_language, "language_filename", "", 1);

	if ($xestiascan_language_languagefilename_check eq 1) {

		# The language filename given is blank so
		# return an error.

		xestiascan_error("languagefilenameblank");

	} elsif ($xestiascan_language_languagefilename_check eq 2){

		# The language filename given is invalid so
		# return an error.

		xestiascan_error("languagefilenameinvalid");

	}

	# Check the module names to see if they're valid.

	my $xestiascan_presmodule_modulename_check 	= xestiascan_variablecheck($http_query_presmodule, "module", 0, 1);
	my $xestiascan_outputmodule_modulename_check	= xestiascan_variablecheck($http_query_outputmodule, "module", 0, 1);
	my $xestiascan_authmodule_modulename_check		= xestiascan_variablecheck($http_query_authmodule, "module", 0, 1);

	if ($xestiascan_presmodule_modulename_check eq 1){

		# The presentation module name is blank, so return
		# an error.

		xestiascan_error("presmoduleblank");

	}

	if ($xestiascan_presmodule_modulename_check eq 2){

		# The presentation module name is invalid, so return
		# an error.

		xestiascan_error("presmoduleinvalid");

	}

	if ($xestiascan_outputmodule_modulename_check eq 1){

		# The output module name is blank, so return
		# an error.

		xestiascan_error("outputmoduleblank");

	}

	if ($xestiascan_outputmodule_modulename_check eq 2){

		# The output module name is invalid, so return
		# an error.

		xestiascan_error("outputmoduleinvalid");

	}

	if ($xestiascan_authmodule_modulename_check eq 1){

		# The database module name is blank, so return
		# an error.

		xestiascan_error("authmoduleblank");

	}

	if ($xestiascan_authmodule_modulename_check eq 2){

		# The database module name is invalid, so return
		# an error.

		xestiascan_error("authmoduleinvalid");

	}

	# Check if the database module, presentation module,
	# output module and language file exists.

	if (!-e "Modules/Presentation/" . $http_query_presmodule . ".pm"){

		# The presentation module is missing so return an
		# error.

		xestiascan_error("presmodulemissing");

	}

	if (!-e "Modules/Output/" . $http_query_outputmodule . ".pm"){

		# The database module is missing so return an
		# error.

		xestiascan_error("outputmodulemissing");

	}

	if (!-e "Modules/Auth/" . $http_query_authmodule . ".pm"){

		# The database module is missing so return an
		# error.

		xestiascan_error("authmodulemissing");

	}

	if (!-e "lang/" . $http_query_language . ".lang"){

		# The language file is missing so return an
		# error.

		xestiascan_error("languagefilenamemissing");

	}

	# Check the database server settings.

	my $xestiascan_databaseserver_length_check		= xestiascan_variablecheck($http_query_databaseserver, "maxlength", 128, 1);
	my $xestiascan_databaseserver_lettersnumbers_check	= xestiascan_variablecheck($http_query_databaseserver, "lettersnumbers", 0, 1);
	my $xestiascan_databaseport_length_check			= xestiascan_variablecheck($http_query_databaseport, "maxlength", 5, 1);
	my $xestiascan_databaseport_numbers_check		= xestiascan_variablecheck($http_query_databaseport, "numbers", 0, 1);
	my $xestiascan_databaseport_port_check			= xestiascan_variablecheck($http_query_databaseport, "port", 0, 1);
	my $xestiascan_databaseprotocol_length_check		= xestiascan_variablecheck($http_query_databaseprotocol, "maxlength", 5, 1);
	my $xestiascan_databaseprotocol_protocol_check		= xestiascan_variablecheck($http_query_databaseprotocol, "serverprotocol", 0, 1);
	my $xestiascan_databasename_length_check			= xestiascan_variablecheck($http_query_databasename, "maxlength", 32, 1);
	my $xestiascan_databasename_lettersnumbers_check		= xestiascan_variablecheck($http_query_databasename, "lettersnumbers", 0, 1);
	my $xestiascan_databaseusername_length_check		= xestiascan_variablecheck($http_query_databaseusername, "maxlength", 16, 1);
	my $xestiascan_databaseusername_lettersnumbers_check	= xestiascan_variablecheck($http_query_databaseusername, "lettersnumbers", 0, 1);
	my $xestiascan_databasepassword_length_check		= xestiascan_variablecheck($http_query_databasepassword, "maxlength", 64, 1);
	my $xestiascan_databasetableprefix_length_check		= xestiascan_variablecheck($http_query_databasetableprefix, "maxlength", 16, 1);
	my $xestiascan_databasetableprefix_lettersnumbers_check	= xestiascan_variablecheck($http_query_databasetableprefix, "lettersnumbers", 0, 1);

	if ($xestiascan_databaseserver_length_check eq 1){

		# The length of the database server name is too long so
		# return an error.

		xestiascan_error("servernametoolong");

	}

	if ($xestiascan_databaseserver_lettersnumbers_check eq 1){

		# The database server name contains characters other
		# than letters and numbers, so return an error.

		xestiascan_error("servernameinvalid");

	}

	if ($xestiascan_databaseport_length_check eq 1){

		# The database port number length is too long so return
		# an error.

		xestiascan_error("serverportnumbertoolong");

	}

	if ($xestiascan_databaseport_numbers_check eq 1){

		# The database port number contains characters other
		# than numbers so return an error.

		xestiascan_error("serverportnumberinvalidcharacters");

	}

	if ($xestiascan_databaseport_port_check eq 1){

		# The database port number given is invalid so return
		# an error.

		xestiascan_error("serverportnumberinvalid");

	}

	if ($xestiascan_databaseprotocol_length_check eq 1){

		# The database protocol name given is too long so
		# return an error.

		xestiascan_error("serverprotocolnametoolong");

	}

	if ($xestiascan_databaseprotocol_protocol_check eq 1){

		# The server protcol given is invalid so return
		# an error.

		xestiascan_error("serverprotocolinvalid");

	}

	if ($xestiascan_databasename_length_check eq 1){

		# The SQL database name is too long so return
		# an error.

		xestiascan_error("serverdatabasenametoolong");

	}

	if ($xestiascan_databasename_lettersnumbers_check eq 1){

		# The database name contains invalid characters
		# so return an error.

		xestiascan_error("serverdatabasenameinvalid");

	}

	if ($xestiascan_databaseusername_length_check eq 1){

		# The database username given is too long so
		# return an error.

		xestiascan_error("serverdatabaseusernametoolong");

	}

	if ($xestiascan_databaseusername_lettersnumbers_check eq 1){

		# The database username contains invalid characters
		# so return an error.

		xestiascan_error("serverdatabaseusernameinvalid");

	}

	if ($xestiascan_databasepassword_length_check eq 1){

		# The database password given is too long so return
		# an error.

		xestiascan_error("serverdatabasepasswordtoolong");

	}

	if ($xestiascan_databasetableprefix_length_check eq 1){

		# The database table prefix given is too long so
		# return an error.

		xestiascan_error("serverdatabasetableprefixtoolong");

	}

	if ($xestiascan_databasetableprefix_lettersnumbers_check eq 1){

		# The database table prefix given contains invalid
		# characters so return an error.

		xestiascan_error("serverdatabasetableprefixinvalid");

	}

	# Check the length of value of the checkboxes.

	my $xestiascan_removeinstallscript_length_check	= xestiascan_variablecheck($http_query_removeinstallscript, "maxlength", 2, 1);

	if ($xestiascan_removeinstallscript_length_check eq 1){

		# The remove install script value is too long
		# so return an error.

		xestiascan_error("removeinstallscripttoolong");

	}
	
	my $xestiascan_removemultiuserinstallscript_length_check	= xestiascan_variablecheck($http_query_removemultiuserinstallscript, "maxlength", 2, 1);
	
	if ($xestiascan_removemultiuserinstallscript_length_check eq 1){
		
		# The remove install script value is too long
		# so return an error.
		
		xestiascan_error("removemultiuserinstallscripttoolong");
		
	}

	# Check if there is write permissions for the directory.

	if (!-w '.'){

		# No write permissions for the directory the
		# script is running from so return an error.

		xestiascan_error("cannotwriteconfigurationindirectory");

	}

	# Check if the configuration file already exists.

	if (-e 'xsdss.cfg'){

		# Check if the configuration file has read permissions.

		if (!-r 'xsdss.cfg'){

			# The configuration file has invalid read permissions
			# set so return an error.

			xestiascan_error("configurationfilereadpermissionsinvalid");

		}

		# Check if the configuration file has write permissions.

		if (!-w 'xsdss.cfg'){

			# The configuration file has invalid write permissions
			# set so return an error.

			xestiascan_error("configurationfilewritepermissionsinvalid");

		}

	}

	# Include the Modules directory.
	
	use lib "Modules/";
	
	# Load the authentication module.

	my %capabilities;
	my $multiuser = 0;
	my $encodedpassword = "";
	
	my $presmodulename = "Auth::" . $http_query_authmodule;
 	($presmodulename) = $presmodulename =~ m/^(.*)$/g; # CHECK THIS!!
 	eval "use " . $presmodulename;
 	$presmodulename = "Modules::Auth::" . $http_query_authmodule;
	
	# Work out if database module is 
	
	%capabilities = $presmodulename->capabilities();
	
	$multiuser = $capabilities{multiuser};
	
	if (!$multiuser){
	
		$multiuser = 0;
		
	}
	
	# Write the new configuration file.

	xestiascan_writeconfig({ ScansURIPath => $http_query_scansuripath, ScansFSPath => $http_query_scansfspath , ImagesURIPath => $http_query_imagesuripath, DateFormat => $finaldateformat, Language => $http_query_language, PresentationModule => $http_query_presmodule, OutputModule => $http_query_outputmodule, AuthModule => $http_query_authmodule, DatabaseServer => $http_query_databaseserver, DatabasePort => $http_query_databaseport, DatabaseProtocol => $http_query_databaseprotocol, DatabaseName => $http_query_databasename, DatabaseUsername => $http_query_databaseusername, DatabasePassword => $http_query_databasepassword, DatabaseTablePrefix => $http_query_databasetableprefix });

	my $installscriptmessage	= "";
	
	# Check if the installation script should be deleted.

	if (!$http_query_removeinstallscript){

		$http_query_removeinstallscript = "off";

	}
	
	if (!$http_query_removemultiuserinstallscript){
	
		$http_query_removemultiuserinstallscript = "off";
		
	}

	# Check to see if multiuser is enabled and go to the multiuser script if needed.
	
	if ($http_query_removeinstallscript eq "on" && $multiuser eq 0){

		if (unlink($installscriptname)){

			$installscriptmessage = $xestiascan_lang{$language_selected}{installscriptremoved};

		} else {

			$installscriptmessage = $xestiascan_lang{$language_selected}{cannotremovescript};
			$installscriptmessage =~ s/%s/$!/g;

		}

	}
	
	if ($http_query_removemultiuserinstallscript eq "on" && $multiuser eq 0){
	
		if (unlink($installscriptname)){
			
			$installscriptmessage = $xestiascan_lang{$language_selected}{installscriptremoved};
			
		} else {
			
			$installscriptmessage = $xestiascan_lang{$language_selected}{cannotremovescript};
			$installscriptmessage =~ s/%s/$!/g;
			
		}		
		
	}
	
	if ($multiuser eq 1){
	
		$installscriptmessage = $xestiascan_lang{$language_selected}{multiuserinstall};
		
	}

	print "Content-type: text/html; charset=utf-8;\r\n\r\n";

	#print start_html({ -title => $xestiascan_lang{$language_selected}{installertitle}, -style => { -code => $cssstyle }});
	print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
	print "<head>\n<title>$xestiascan_lang{$language_selected}{installertitle}</title>\n<style type=\"text/css\" media=\"screen\">$cssstyle</style>\n</head>\n<body>\n";
	print "<div class=\"topbar\"><span class=\"title\">Xestia Scanner Server Installer</span></div>";
	print "<div class=\"pagespacing\">\n";
	print $xestiascan_lang{$language_selected}{installedmessage};

	if ($installscriptmessage){

		print "<br /><br />\n";
		print $installscriptmessage;

 	}

	print "<br /><br />\n";
	
	if ($multiuser eq 0){
	
		print $xestiascan_lang{$language_selected}{usexestiascannerservertext};
		print "<br /><br />\n";
		print "<a href=\"" . $xestiascanscriptname . "\">$xestiascan_lang{$language_selected}{usexestiascannerserverlink}</a>";
	
	} elsif ($multiuser eq 1){
			
		print "<a href=\"" . $multiuserinstallscriptname . "\">$xestiascan_lang{$language_selected}{multiuserinstalllink}</a>";		
		
	}
	
	print "</div>";
	print "</body>\n</html>";

	exit;

}

# Create a list of common date and time formats.

my @datetime_formats = ( 
	'DD/MM/YY (hh:mm:ss)', 'DD/MM/YY hh:mm:ss', 'D/M/Y (hh:mm:ss)',
	'D/M/Y hh:mm:ss', 'D/M/YY (hh:mm:ss)', 'D/M/YY hh:mm:ss',
	'DD/MM (hh:mm:ss)', 'D/M (hh:mm:ss)', 'DD/MM hh:mm:ss', 
	'D/M hh:mm:ss', 'DD/MM hh:mm', 'D/M hh:mm',
	'DD/MM/YY', 'D/M/Y', 'DD/MM',

	'YY-MM-DD (hh:mm:ss)', 'YY-MM-DD hh:mm:ss', 'Y-M-D (hh:mm:ss)',
	'Y-M-D hh:mm:ss', 'M-D (hh:mm:ss)', 'M-D hh:mm:ss',
	'YY-MM-DD', 'MM-DD' 
);

# Create the list of tests to do.

my %test_list;
my %dependency_results;
my %database_results;
my %file_results;

tie(%test_list, "Tie::IxHash");
tie(%dependency_results, "Tie::IxHash");
tie(%database_results, "Tie::IxHash");
tie(%file_results, "Tie::IxHash");

my $test;
my $date;

my $dependency_error = 0;
my $database_onemodule = 0;
my $database_error = 0;
my $file_error = 0;

my $module_version;

my $language_name;
my $language_xml_data;
my $language_file_friendly;

my $presentation_file_friendly;

# Check to see if the needed Perl modules are installed.

$test_list{CheckDBI}{Name} 		= "DBI";
$test_list{CheckDBI}{Type} 		= "dependency";
$test_list{CheckDBI}{Code} 		= "DBI";
$test_list{CheckDBI}{Version}		= "1.605";

$test_list{CheckCGILite}{Name}		= "CGI::Lite";
$test_list{CheckCGILite}{Type}		= "dependency";
$test_list{CheckCGILite}{Code}		= "CGI::Lite";
$test_list{CheckCGILite}{Version}	= "2.02";

$test_list{Encode}{Name}		= "Encode";
$test_list{Encode}{Type}		= "dependency";
$test_list{Encode}{Code}		= "Encode";
$test_list{Encode}{Version}		= "2.23";

$test_list{HashSearch}{Name}		= "Hash::Search";
$test_list{HashSearch}{Type}		= "dependency";
$test_list{HashSearch}{Code}		= "Hash::Search";
$test_list{HashSearch}{Version}		= "0.03";

$test_list{CheckTieHash}{Name}		= "Tie::IxHash";
$test_list{CheckTieHash}{Type} 		= "dependency";
$test_list{CheckTieHash}{Code} 		= "Tie::IxHash";
$test_list{CheckTieHash}{Version}	= "1.22";

$test_list{CheckMimeBase64}{Name}	= "MIME::Base64";
$test_list{CheckMimeBase64}{Type} 	= "dependency";
$test_list{CheckMimeBase64}{Code} 	= "MIME::Base64";
$test_list{CheckMimeBase64}{Version}	= "3.13";

$test_list{CheckSane}{Name}		= "Sane";
$test_list{CheckSane}{Type}		= "dependency";
$test_list{CheckSane}{Code}		= "Sane";
$test_list{CheckSane}{Version}		= "0.03";

$test_list{CheckFileCopy}{Name}		= "File::Copy";
$test_list{CheckFileCopy}{Type}		= "dependency";
$test_list{CheckFileCopy}{Code}		= "File::Copy";
$test_list{CheckFileCopy}{Version}	= "2.11";

$test_list{CheckFileBasename}{Name}		= "File::Basename";
$test_list{CheckFileBasename}{Type}		= "dependency";
$test_list{CheckFileBasename}{Code}		= "File::Basename";
$test_list{CheckFileBasename}{Version}		= "2.76";

$test_list{CheckSysHostname}{Name}		= "Sys::Hostname";
$test_list{CheckSysHostname}{Type}		= "dependency";
$test_list{CheckSysHostname}{Code}		= "Sys::Hostname";
$test_list{CheckSysHostname}{Version}		= "1.11";

$test_list{CheckImageMagick}{Name}		= "Image::Magick";
$test_list{CheckImageMagick}{Type}		= "dependency";
$test_list{CheckImageMagick}{Code}		= "Image::Magick";
$test_list{CheckImageMagick}{Version}		= "6.3.7";

$test_list{CheckDigest}{Name}		= "Digest";
$test_list{CheckDigest}{Type}		= "dependency";
$test_list{CheckDigest}{Code}		= "Digest";
$test_list{CheckDigest}{Version}	= "1.15";

$test_list{CheckNetSMTP}{Name}		= "Net::SMTP";
$test_list{CheckNetSMTP}{Type}		= "dependency";
$test_list{CheckNetSMTP}{Code}		= "Net::SMTP";
$test_list{CheckNetSMTP}{Version}	= "2.31";

$test_list{CheckFileMimeInfo}{Name}		= "File::MimeInfo";
$test_list{CheckFileMimeInfo}{Type}		= "dependency";
$test_list{CheckFileMimeInfo}{Code}		= "File::MimeInfo";
$test_list{CheckFileMimeInfo}{Version}		= "0.15";


$test_list{DBDPg}{Name}			= "DBD::Pg";
$test_list{DBDPg}{Type}			= "database";
$test_list{DBDPg}{Code}			= "DBD::Pg";
$test_list{DBDPg}{Version}		= "2.17.1";

# Check the file and directory permissions to see if they are correct.

$test_list{MainDirectory}{Name}		= "Xestia Scanner Server Directory (.)";
$test_list{MainDirectory}{Type}		= "file";
$test_list{MainDirectory}{Code}		= ".";
$test_list{MainDirectory}{Writeable}	= "1";

$test_list{LanguageDirectory}{Name}		= "Language Directory (lang)";
$test_list{LanguageDirectory}{Type}		= "file";
$test_list{LanguageDirectory}{Code}		= "lang";
$test_list{LanguageDirectory}{Writeable}	= "0";

$test_list{ModulesDirectory}{Name}		= "Modules Directory (Modules)";
$test_list{ModulesDirectory}{Type}		= "file";
$test_list{ModulesDirectory}{Code}		= "Modules";
$test_list{ModulesDirectory}{Writeable}		= "0";

$test_list{AuthModulesDirectory}{Name}		= "Authentication Modules Directory (Modules/Auth)";
$test_list{AuthModulesDirectory}{Type}		= "file";
$test_list{AuthModulesDirectory}{Code}		= "Modules/Auth";
$test_list{AuthModulesDirectory}{Writeable}	= "0";

$test_list{ExportModulesDirectory}{Name}	= "Export Modules Directory (Modules/Export)";
$test_list{ExportModulesDirectory}{Type}	= "file";
$test_list{ExportModulesDirectory}{Code}	= "Modules/Export";
$test_list{ExportModulesDirectory}{Writeable}	= "0";

$test_list{OutputModulesDirectory}{Name}	= "Output Modules Directory (Modules/Output)";
$test_list{OutputModulesDirectory}{Type}	= "file";
$test_list{OutputModulesDirectory}{Code}	= "Modules/Output";
$test_list{OutputModulesDirectory}{Writeable}	= "0";

$test_list{PresModulesDirectory}{Name}		= "Presentation Modules Directory (Modules/Presentation)";
$test_list{PresModulesDirectory}{Type}		= "file";
$test_list{PresModulesDirectory}{Code}		= "Modules/Presentation";
$test_list{PresModulesDirectory}{Writeable}	= "0";

$test_list{SystemModulesDirectory}{Name}	= "System Modules Directory (Modules/System)";
$test_list{SystemModulesDirectory}{Type}	= "file";
$test_list{SystemModulesDirectory}{Code}	= "Modules/System";
$test_list{SystemModulesDirectory}{Writeable}	= "0";

# Preform those tests.

foreach $test (keys %test_list){

	# Check the type of test.

	$ENV{PATH}='/bin:/usr/bin';
	
	if ($test_list{$test}{Type} eq "dependency"){
		
		if (eval "require " . $test_list{$test}{Code}){
			
			# The module exists and is working correctly.

			$dependency_results{$test_list{$test}{Name}}{result} 	= $xestiascan_lang{$language_selected}{testpass};
			
			# Get the current version of the module (if possible);
			
			# Launch another copy of Perl, this probably is the only memory efficent way.
			
			my $command = "perl -M$test_list{$test}{Code} -e \'print \"\$$test_list{$test}{Code}::VERSION\"\'";
			my $result = `$command`;
			
			$dependency_results{$test_list{$test}{Name}}{version}	= $result;
			$dependency_results{$test_list{$test}{Name}}{testname}	= $test;
			
		} else {

			# The module does not exist or has an error.

			$dependency_error = 1;
			$dependency_results{$test_list{$test}{Name}}{result} 	= $xestiascan_lang{$language_selected}{testfail} . " ($!)";
			$dependency_results{$test_list{$test}{Name}}{version}	= "N/A";
			$dependency_results{$test_list{$test}{Name}}{testname}	= $test;

		}
		
	} elsif ($test_list{$test}{Type} eq "database"){

		if (eval "require " . $test_list{$test}{Code}){

			# The module exists and it is working correctly.

			$database_results{$test_list{$test}{Name}}{result} 	= $xestiascan_lang{$language_selected}{testpass};
			$database_onemodule = 1;
			
			# Launch another copy of Perl, this probably is the only memory efficent way.
			
			my $command = "perl -M$test_list{$test}{Code} -e \'print \"\$$test_list{$test}{Code}::VERSION\"\'";
			my $result = `$command`;
			
			$database_results{$test_list{$test}{Name}}{version}	= $result;
			$database_results{$test_list{$test}{Name}}{testname}	= $test;

		} else {

			# The module does not exist or has an error.

			$database_error = 1;
			$database_results{$test_list{$test}{Name}}{result} 	= $xestiascan_lang{$language_selected}{testfail};
			$database_results{$test_list{$test}{Name}}{version}	= "N/A";
			$database_results{$test_list{$test}{Name}}{testname}	= $test;

		}

	} elsif ($test_list{$test}{Type} eq "file"){

		if (-e $test_list{$test}{Code}){

			# The filename given does exist.

		} else {

			# the filename given does not exist.

			$file_error = 1;
			$file_results{$test_list{$test}{Name}}{result} 	= $xestiascan_lang{$language_selected}{errormessage} . $xestiascan_lang{$language_selected}{doesnotexist};

		}	

		# Test to see if the filename given has read
		# permissions.

		if (-r $test_list{$test}{Code}){

			# The filename given has valid permissions set.

			$file_results{$test_list{$test}{Name}}{result} 	= $xestiascan_lang{$language_selected}{testpass};

		} else {

			# The filename given has invalid permissions set.

			$file_error = 1;
			$file_results{$test_list{$test}{Name}}{result} = $xestiascan_lang{$language_selected}{errormessage} . $xestiascan_lang{$language_selected}{invalidpermissionsset};

		}

		if ($test_list{$test}{Writeable} eq 1){

			# Test to see if the filename given has write
			# permissions.

			if (-w $test_list{$test}{Code}){

				# The filename given has valid permissions set.

				$file_results{$test_list{$test}{Name}}{result} 	= $xestiascan_lang{$language_selected}{testpass};

			} else {

				# The filename given has invalid permissions set.

				$file_error = 1;
				$file_results{$test_list{$test}{Name}}{result} 	= $xestiascan_lang{$language_selected}{errormessage} . $xestiascan_lang{$language_selected}{invalidpermissionsset};

			}

		}

	}

}

# Print the header.

print "Content-Type: text/html; charset=utf-8;\r\n\r\n";

# Print the page for installing Kiriwrite.

print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
print "<head>\n<title>$xestiascan_lang{$language_selected}{installertitle}</title>\n";
print "<style type=\"text/css\" media=\"screen\">$cssstyle</style>\n</head>\n<body>";

print "<div class=\"topbar\">
<span class=\"title\">" . $xestiascan_lang{$language_selected}{installertitle} .  "</span>";
my $language_name_short;
my $language_list_seek = 0;
my $installlanguage_out = "";

$installlanguage_out = "<select name=\"installlanguage\">\n";

foreach $language_name_short (@language_list_short){

	$installlanguage_out = $installlanguage_out . "<option value=\"" . $language_name_short . "\">" . $language_list_long[$language_list_seek] . "</option>\n";
	$language_list_seek++;

}

$installlanguage_out = $installlanguage_out . "</select>\n";

print "<form action=\"" . $installscriptname . "\" method=\"POST\">\n$installlanguage_out\n<input type=\"submit\" value=\"$xestiascan_lang{$language_selected}{switch}\">\n</form>\n";
print "</div>";

print "<div class=\"pagespacing\">\n";

print "<span class=\"pageheader\">$xestiascan_lang{$language_selected}{installertitle}</span><br /><br />\n";
print $xestiascan_lang{$language_selected}{installertext} . "<br /><br />\n";

#if ($modperlenabled eq 1){
#	print "<br /><br />";
#	print $xestiascan_lang{$language_selected}{modperlnotice};
#}

print "<span class=\"subheader\">$xestiascan_lang{$language_selected}{dependencytitle}</span><br /><br />\n";
print "<b>$xestiascan_lang{$language_selected}{requiredmodules}</b><br /><br />\n";
print $xestiascan_lang{$language_selected}{perlmodules};
print "<br /><br />\n";

if ($dependency_error eq 1){

	print $xestiascan_lang{$language_selected}{errormessage};
	print $xestiascan_lang{$language_selected}{dependencyperlmodulesmissing};
	print "<br /><br />\n";

}

print "<table>\n";

xestiascan_addtablerow($xestiascan_lang{$language_selected}{module}, "tablecellheader", $xestiascan_lang{$language_selected}{result}, "tablecellheader", $xestiascan_lang{$language_selected}{requiredver}, "tablecellheader", $xestiascan_lang{$language_selected}{installedver}, "tablecellheader");

foreach $test (keys %dependency_results) {
	
	xestiascan_addtablerow($test, "tablename", $dependency_results{$test}{result}, "tabledata", $test_list{$dependency_results{$test}{testname}}{Version}, "tabledata", $dependency_results{$test}{version}, "tabledata");

}

print "</table>";

print "<br /><b>$xestiascan_lang{$language_selected}{databasemodules}</b><br /><br />\n";
print $xestiascan_lang{$language_selected}{databasemodulestext};
print "<br /><br />\n";

print "<table>\n";

if ($database_error eq 1){

	print $xestiascan_lang{$language_selected}{warningmessage};
	print $xestiascan_lang{$language_selected}{databaseperlmodulesmissing};
	print "<br /><br />\n";

}

xestiascan_addtablerow($xestiascan_lang{$language_selected}{module}, "tablecellheader", $xestiascan_lang{$language_selected}{result}, "tablecellheader", $xestiascan_lang{$language_selected}{requiredver}, "tablecellheader", $xestiascan_lang{$language_selected}{installedver}, "tablecellheader");

foreach $test (keys %database_results) {

	xestiascan_addtablerow($test, "tablename", $database_results{$test}{result}, "tabledata", $test_list{$database_results{$test}{testname}}{Version}, "tabledata", $database_results{$test}{version}, "tabledata");

}

print "</table><br />";

print "<b>$xestiascan_lang{$language_selected}{filepermissions}</b><br /><br />\n";

print $xestiascan_lang{$language_selected}{filepermissionstext};
print "<br /><br />\n";

if ($file_error eq 1){

	print $xestiascan_lang{$language_selected}{errormessage};
	print $xestiascan_lang{$language_selected}{filepermissionsinvalid};
	print "<br /><br />\n";

}

print "<table>";

xestiascan_addtablerow($xestiascan_lang{$language_selected}{filename}, "tablecellheader", "Result", "tablecellheader");

foreach $test (keys %file_results) {

	xestiascan_addtablerow($test, "tablename", $file_results{$test}{result}, "tabledata");

}

print "</table>";

if ($dependency_error eq 1){

	print "<hr />\n";
	print "<b>$xestiascan_lang{$language_selected}{criticalerror}</b><br /><br />\n";
	print $xestiascan_lang{$language_selected}{dependencymodulesnotinstalled} . "\n";
	print "</body>\n</html>";
	exit;

}

if ($database_onemodule eq 0){

	print "<hr />\n";
	print "<b>$xestiascan_lang{$language_selected}{criticalerror}</b><br /><br />\n";
	print $xestiascan_lang{$language_selected}{databasemodulesnotinstalled} . "\n";
	print "</body>\n</html>";
	exit;

}

if ($file_error eq 1){

	print "<hr />\n";
	print "<b>$xestiascan_lang{$language_selected}{criticalerror}</b><br /><br />\n";
	print $xestiascan_lang{$language_selected}{filepermissionerrors} . "\n";
	print "</body>\n</html>";
	exit;

}

my @language_short;
my (%available_languages, $available_languages);
my @presentation_modules;
my @output_modules;
my @auth_modules;
my $select_data = "";
my (%language_data, $language_data);
my @lang_data;
my $xestiascan_languagefilehandle;
my $language_out = "";
my ($presmodule_name, $presmodule_out) = "";
my ($authmodule_name, $authmodule_out) = "";
my ($outputmodule_name, $outputmodule_out) = "";

# Get the list of available languages.

tie(%available_languages, 'Tie::IxHash');

opendir(LANGUAGEDIR, "lang");
my @language_directory = grep /m*\.lang$/, readdir(LANGUAGEDIR);
closedir(LANGUAGEDIR);

foreach my $language_file (@language_directory){

	# Load the language file.

	next if $language_file =~ m/^\./;
	next if $language_file !~ m/.lang$/;
	
	open ($xestiascan_languagefilehandle, "lang/" . $language_file);
	@lang_data = <$xestiascan_languagefilehandle>;
	%language_data = xestiascan_processconfig(@lang_data);
	close ($xestiascan_languagefilehandle);

	# Get the friendly name for the language file.

	$language_file_friendly = $language_file;
	$language_file_friendly =~ s/.lang$//g;

	$language_name = $language_data{about}{name};

	$available_languages{$language_file_friendly} = $language_name . " (" . $language_file_friendly . ")";

}

# Get the list of presentation modules.

opendir(OUTPUTSYSTEMDIR, "Modules/Presentation");
my @presmodule_directory = grep /m*\.pm$/, readdir(OUTPUTSYSTEMDIR);
closedir(OUTPUTSYSTEMDIR);

foreach my $presmodule_file (@presmodule_directory){

	# Get the friendly name for the database module.

	next if $presmodule_file =~ m/^\./;
	next if $presmodule_file !~ m/.pm$/;
	$presmodule_file =~ s/.pm$//g;
	push(@presentation_modules, $presmodule_file);

}

# Get the list of output modules.

opendir(OUTPUTDIR, "Modules/Output");
my @outputmodule_directory = grep /m*\.pm$/, readdir(OUTPUTDIR);
closedir(OUTPUTDIR);

foreach my $outputmodule_file (@outputmodule_directory){

	# Get the friendly name for the database module.

	next if $outputmodule_file =~ m/^\./;
	next if $outputmodule_file !~ m/.pm$/;
	$outputmodule_file =~ s/.pm$//g;
	push(@output_modules, $outputmodule_file);

}

# Get the list of database modules.

opendir(DATABASEDIR, "Modules/Auth");
my @authmodule_directory = grep /m*\.pm$/, readdir(DATABASEDIR);
closedir(DATABASEDIR);

foreach my $authmodule_file (@authmodule_directory){

	# Get the friendly name for the database module.

	next if $authmodule_file =~ m/^\./;
	next if $authmodule_file !~ m/.pm$/;
	$authmodule_file =~ s/.pm$//g;
	push(@auth_modules, $authmodule_file);

}

print "<h3>$xestiascan_lang{$language_selected}{settingstitle}</h3>";
print $xestiascan_lang{$language_selected}{settingstext};
print "<br /><br />\n";

print "<form action=\"" . $installscriptname . "\" method=\"POST\">";
print "<input type=\"hidden\" name=\"confirm\" value=\"1\">\n<input type=\"hidden\" name=\"installlanguage\" value=\"$language_selected\">\n";

print "<table width=\"100%\">";
xestiascan_addtablerow($xestiascan_lang{$language_selected}{setting}, "tablecellheader", $xestiascan_lang{$language_selected}{value}, "tablecellheader");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{directories}, "tablecellheader", "", "tablecellheader");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{imagesuripath}, "tablename", "<input type=\"text\" name=\"imagesuripath\" size=\"32\" maxlength=\"512\" value=\"$default_imagesuri\">", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{scansuripath}, "tablename", "<input type=\"text\" name=\"scansuripath\" size=\"32\" maxlength=\"512\" value=\"$default_scansuri\">", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{scansfspath}, "tablename", "<input type=\"text\" name=\"scansfspath\" size=\"64\" maxlength=\"4096\" value=\"$default_scansfs\">", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{date}, "tablecellheader", "", "tablecellheader");

foreach my $select_name (@datetime_formats){
 	$select_data = $select_data . "<option value=\"$select_name\">" . $select_name . "</option>\n";
}

xestiascan_addtablerow($xestiascan_lang{$language_selected}{dateformat}, "tablename", "<select name=\"dateformat\">$select_data</select>\n<input type=\"text\" size=\"32\" maxlength=\"64\" name=\"customdateformat\">", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{language}, "tablecellheader", "", "tablecellheader");

foreach my $language (keys %available_languages){
	if ($language eq $language_selected){
		$language_out = $language_out . "<option value=\"" . $language . "\" selected=selected>" . $available_languages{$language} . "</option>\n";
	} else {
		$language_out = $language_out . "<option value=\"" . $language . "\">" . $available_languages{$language} . "</option>\n";
	}
}

xestiascan_addtablerow($xestiascan_lang{$language_selected}{systemlanguage}, "tablename", "<select name=\"language\">\r\n$language_out\r\n</select>", "tabledata");

xestiascan_addtablerow($xestiascan_lang{$language_selected}{modules}, "tablecellheader", "", "tablecellheader");

foreach $presmodule_name (@presentation_modules){
	$presmodule_out = $presmodule_out . "<option value=\"$presmodule_name\">$presmodule_name</option>";
}
xestiascan_addtablerow($xestiascan_lang{$language_selected}{presentationmodule}, "tablename", "<select name=\"presmodule\">$presmodule_out</select>", "tabledata");

foreach $outputmodule_name (@output_modules){
	if ($default_outputmodule = $outputmodule_name){
		$outputmodule_out = $outputmodule_out . "<option value=\"$outputmodule_name\" selected>$outputmodule_name</option>";		
	} else {
		$outputmodule_out = $outputmodule_out . "<option value=\"$outputmodule_name\">$outputmodule_name</option>";
	}
}
xestiascan_addtablerow($xestiascan_lang{$language_selected}{outputmodule}, "tablename", "<select name=\"outputmodule\">$outputmodule_out</select>", "tabledata");

foreach $authmodule_name (@auth_modules){
	$authmodule_out = $authmodule_out . "<option value=\"$authmodule_name\">$authmodule_name</option>";
}
xestiascan_addtablerow($xestiascan_lang{$language_selected}{authmodule}, "tablename", "<select name=\"authmodule\">$authmodule_out</select>", "tabledata");

xestiascan_addtablerow($xestiascan_lang{$language_selected}{databaseserver}, "tablename", "<input type=\"text\" name=\"databaseserver\" size=\"32\" maxlength=\"128\" value=\"$default_server\">\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databaseport}, "tablename", "<input type=\"text\" name=\"databaseport\" maxlength=\"5\" size=\"5\" value=\"$default_port\">\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databaseprotocol}, "tablename", "<select name=\"databaseprotocol\">\n<option value=\"tcp\">tcp</option>\n<option value=\"udp\">udp</option>\n</select>\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databasename}, "tablename", "<input type=\"text\" name=\"databasename\" size=\"32\" maxlength=\"32\" value=\"$default_name\">\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databaseusername}, "tablename", "<input type=\"text\" name=\"databaseusername\" size=\"16\" maxlength=\"16\" value=\"$default_username\">\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databasepassword}, "tablename", "<input type=\"password\" name=\"databasepassword\" size=\"32\" maxlength=\"64\">\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databasetableprefix}, "tablename", "<input type=\"text\" name=\"databasetableprefix\" size=\"32\" maxlength=\"32\" value=\"$default_prefix\">\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{installationoptions}, "tablecellheader", "", "tablecellheader");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{installoptions}, "tablename", "<input type=\"checkbox\" name=\"removeinstallscript\" checked=checked value=\"on\"> $xestiascan_lang{$language_selected}{removeinstallscript}\n<br />\n<input type=\"checkbox\" name=\"removemultiuserinstallscript\" checked=checked value=\"on\"> $xestiascan_lang{$language_selected}{removemultiuserinstallscript}\n", "tabledata");

print "</table>\n";

print "<br />\n<input type=\"submit\" value=\"$xestiascan_lang{$language_selected}{savesettingsbutton}\"> | <input type=\"reset\" value=\"$xestiascan_lang{$language_selected}{resetsettingsbutton}\">\n";

print "</form>\n</div>\n</body>\n</html>";
exit;

__END__