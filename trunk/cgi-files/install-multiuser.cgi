#!/usr/bin/perl -Tw

#################################################################################
# Xestia Scanner Server Installer Script (install-multiuser.cgi)		#
# Multiuser installation script for Xestia Scanner Server	     		#
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

use strict;				# Throw errors if there's something wrong.
use warnings;				# Write warnings to the HTTP Server Log file.

use utf8;

eval "use CGI::Lite";

if ($@){
	print "Content-type: text/html;\r\n\r\n";
	print "The CGI::Lite Perl Module is not installed. Please install CGI::Lite and then run this installation script again. CGI::Lite can be installed through CPAN.";
	exit;
}

my $modperlenabled = 0;
my $installscriptname = "install-multiuser.cgi";
my $originstallscriptname = "install.cgi";
my $xestiascanscriptname = "xsdss.cgi";
my $language_selected = "en-GB";

my %xestiascan_config;

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

select {
	#font-size: 12px;
	#padding: 3px;
	#background-color: #408080;
	#color: #FFFFFF;
	#border-color: #102020;
	#border-style: solid;
	#border-width: 1px;
	#padding: 3px;
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

# Default settings.

my $default_dbmodule		= "PostgreSQL";
my $default_server		= "localhost";
my $default_port		= "5432";
my $default_protocol		= "tcp";
my $default_name		= "database";
my $default_username		= "username";
my $default_prefix		= "xestiascan";

my $default_adminusername	= "Administrator";
my $default_adminpassword	= "Password";

my $query_lite = new CGI::Lite;
my $form_data = $query_lite->parse_form_data;

my ($xestiascan_lang, %xestiascan_lang);

$xestiascan_lang{"en-GB"}{"languagename"}	= "English (British)";
	$xestiascan_lang{"en-GB"}{"testpass"}		= "OK";
	$xestiascan_lang{"en-GB"}{"testfail"}		= "Error";

	$xestiascan_lang{"en-GB"}{"invalidconfigfile"}		= "An error occured whilst reading the configuration file. It may be in an invalid format, missings or that no permissions are set! You will need to enter these details manually below.";

	$xestiascan_lang{"en-GB"}{"generic"}			= "An error occured which is not known to the Xestia Scanner Server multiuser installer.";
	$xestiascan_lang{"en-GB"}{"invalidvariable"}		= "The variable given was invalid.";
	$xestiascan_lang{"en-GB"}{"invalidvalue"}		= "The value given was invalid.";
	$xestiascan_lang{"en-GB"}{"invalidutf8"}		= "The value given has does not contain valid UTF8.";
	$xestiascan_lang{"en-GB"}{"invalidoption"}		= "The option given was invalid.";
	$xestiascan_lang{"en-GB"}{"variabletoolong"}		= "The variable given is too long.";
	$xestiascan_lang{"en-GB"}{"blankdirectory"}		= "The directory name given is blank.";
	$xestiascan_lang{"en-GB"}{"invaliddirectory"}		= "The directory name given is invalid.";
	$xestiascan_lang{"en-GB"}{"moduleblank"}			= "The module filename given is blank.";
	$xestiascan_lang{"en-GB"}{"moduleinvalid"}		= "The module filename given is invalid.";

	$xestiascan_lang{"en-GB"}{"dbdirectorytoolong"}		= "The database directory name given is too long.";
	$xestiascan_lang{"en-GB"}{"outputdirectorytoolong"}	= "The output directory name given is too long.";
	$xestiascan_lang{"en-GB"}{"imagesuripathtoolong"}	= "The images URI path name given is too long.";
	$xestiascan_lang{"en-GB"}{"dateformattoolong"}		= "The date format given is too long.";
	$xestiascan_lang{"en-GB"}{"customdateformattoolong"}	= "The custom date format given is too long.";
	$xestiascan_lang{"en-GB"}{"languagefilenametoolong"}	= "The language filename given is too long.";

	$xestiascan_lang{"en-GB"}{"authmoduleinvalidpermissions"}	= "The authentication moudle has invalid file permissions set.";

	$xestiascan_lang{"en-GB"}{"dateformatblank"}		= "The date format given was blank.";
	$xestiascan_lang{"en-GB"}{"dateformatinvalid"}		= "The date format given is invalid.";
	$xestiascan_lang{"en-GB"}{"languagefilenameinvalid"}	= "The language filename given is invalid.";

	$xestiascan_lang{"en-GB"}{"dbdirectoryblank"}		= "The database directory name given is blank.";
	$xestiascan_lang{"en-GB"}{"dbdirectoryinvalid"}		= "The database directory name given is invalid.";

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

	$xestiascan_lang{"en-GB"}{"authmoduleblank"}		= "The database module name given is blank.";
	$xestiascan_lang{"en-GB"}{"dbmoduleinvalid"}		= "The database module name given is invalid.";
 
	$xestiascan_lang{"en-GB"}{"outputmoduleblank"}		= "The output module name given is blank.";
	$xestiascan_lang{"en-GB"}{"outputmoduleinvalid"}		= "The output module name given is invalid.";
 
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
	$xestiascan_lang{"en-GB"}{"createmodulestoolong"}	= "The create modules value given is too long.";
	$xestiascan_lang{"en-GB"}{"createscannerstoolong"}	= "The create scanners value given is too long.";
	$xestiascan_lang{"en-GB"}{"createsessionstoolong"}	= "The create sessions value given is too long.";
	$xestiascan_lang{"en-GB"}{"createuserstoolong"}		= "The create users value given is too long.";
	$xestiascan_lang{"en-GB"}{"forcerecreatetoolong"}	= "The force recreate value given is too long.";
	$xestiascan_lang{"en-GB"}{"deleteinstalltoolong"}	= "The delete installer value given is too long.";
	$xestiascan_lang{"en-GB"}{"deletemultiusertoolong"}	= "The delete multiuser installer value given is too long.";

	$xestiascan_lang{"en-GB"}{"notmultiuser"}		= "The module given is not a multiuser module.";

	$xestiascan_lang{"en-GB"}{"removeinstallscripttoolong"}	= "The remove install script value given is too long.";
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
	$xestiascan_lang{"en-GB"}{"databasemodulesnotinstalled"}	= "None of Perl modules that are used by the database modules are not installed. See the Xestia Scanner Server documentation for more information on this.";
	$xestiascan_lang{"en-GB"}{"filepermissionerrors"}	= "One or more filenames checked has errors. See the Xestia Scanner Server documentation for more information on this.",

	$xestiascan_lang{"en-GB"}{"installertitle"}	= "Xestia Scanner Server Multiuser Installer";
	$xestiascan_lang{"en-GB"}{"installertext"}	= "This installer script will setup the user and session tables needed for your multiuser installation of Xestia Scanner Server. If you already have user or session tables then they will be skipped unless you have selected the recreate table checkbox.";
	$xestiascan_lang{"en-GB"}{"modperlnotice"}	= "mod_perl has been detected. Please ensure that you have setup this script and the main Xestia Scanner Server script so that mod_perl can use Xestia Scanner Server properly. Please read the mod_perl specific part of Chapter 1: Installation in the Xestia Scanner Server documentation.";
	$xestiascan_lang{"en-GB"}{"dependencytitle"}	= "Dependency and file testing results";
	$xestiascan_lang{"en-GB"}{"requiredmodules"}	= "Required Modules";
	$xestiascan_lang{"en-GB"}{"perlmodules"}		= "These Perl modules are used internally by Xestia Scanner Server.";
	$xestiascan_lang{"en-GB"}{"databasemodules"}	= "Perl Database Modules";
	$xestiascan_lang{"en-GB"}{"databasemodulestext"}	= "These Perl modules are used by the database modules.";
	$xestiascan_lang{"en-GB"}{"filepermissions"}	= "File permissions";
	$xestiascan_lang{"en-GB"}{"filepermissionstext"}	= "The file permissions are for file and directories that are critical to Xestia Scanner Server such as module and language directories.";
	
	$xestiascan_lang{"en-GB"}{"settingstitle"}	= "Xestia Scanner Server Settings";
	$xestiascan_lang{"en-GB"}{"settingstext"}	= "The settings given here will be used by Xestia Scanner Server. Some default settings are given here. Certain database modules (like SQLite) do not need the database server settings and can be left alone.";
	$xestiascan_lang{"en-GB"}{"directories"}		= "Directories";
	$xestiascan_lang{"en-GB"}{"databasedirectory"}	= "Database Directory";
	$xestiascan_lang{"en-GB"}{"outputdirectory"}	= "Output Directory";
	$xestiascan_lang{"en-GB"}{"imagesuripath"}	= "Images (URI path)";
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
	$xestiascan_lang{"en-GB"}{"authsettings"}	= "Authentication Settings";
	$xestiascan_lang{"en-GB"}{"authenticationmodule"}	= "Authentication Module";
	$xestiascan_lang{"en-GB"}{"multiuseronly"}	= "Only multiuser-supported authentication modules are listed.";
	$xestiascan_lang{"en-GB"}{"databaseserver"}	= "Database Server";
	$xestiascan_lang{"en-GB"}{"databaseport"}	= "Database Port";
	$xestiascan_lang{"en-GB"}{"databaseprotocol"}	= "Database Protocol";
	$xestiascan_lang{"en-GB"}{"databasename"}	= "Database Name";
	$xestiascan_lang{"en-GB"}{"databaseusername"}	= "Database Username";
	$xestiascan_lang{"en-GB"}{"databasepassword"}	= "Database Password";
	$xestiascan_lang{"en-GB"}{"databasetableprefix"}	= "Database Table Prefix";
	$xestiascan_lang{"en-GB"}{"adminuseraccountsettings"}	= "Administrative User Account Settings";
	$xestiascan_lang{"en-GB"}{"adminusername"}	= "Username:";
	$xestiascan_lang{"en-GB"}{"adminpassword"}	= "Password:";
	$xestiascan_lang{"en-GB"}{"installationoptions"}	= "Installation Options";
	$xestiascan_lang{"en-GB"}{"installoptions"}	= "Install Options";
	$xestiascan_lang{"en-GB"}{"installationoptions"}	= "Installation Options";
	$xestiascan_lang{"en-GB"}{"createtables"} = "Create tables";
	$xestiascan_lang{"en-GB"}{"createtablemodulepermissions"} = "Create the modules permissions table.";
	$xestiascan_lang{"en-GB"}{"createtablescannerspermissions"} = "Create the scanners permissions table.";
	$xestiascan_lang{"en-GB"}{"createtablesessions"} = "Create the sessions table.";
	$xestiascan_lang{"en-GB"}{"createtableusers"} = "Create the users table.";
	$xestiascan_lang{"en-GB"}{"forcerecreate"}	= "Force recreate";
	$xestiascan_lang{"en-GB"}{"forcerecreatetables"}	= "Force recreation of the selected tables.";
	$xestiascan_lang{"en-GB"}{"deleteinstallscripts"}	= "Delete install scripts";
	$xestiascan_lang{"en-GB"}{"removeinstallscript"}	= "Delete the Xestia Scanner Server Installer script.";
	$xestiascan_lang{"en-GB"}{"removemultiuserinstallscript"}	= "Delete the Xestia Scanner Server Multiuser Installer script.";
	$xestiascan_lang{"en-GB"}{"recommendremoving"}	= "Deleting the installer scripts after you have finished using them is strongly recommended to secure your Xestia Scanner Server multiuser installation!";
	$xestiascan_lang{"en-GB"}{"savesettingsbutton"}	= "Save Settings";
	$xestiascan_lang{"en-GB"}{"resetsettingsbutton"}	= "Reset Settings";

	$xestiascan_lang{"en-GB"}{"adminaccountname"} = "Administrator";
	$xestiascan_lang{"en-GB"}{"adminaccountpassword"} = "Password";

	$xestiascan_lang{"en-GB"}{"installscriptkept"} = "Warning: The installer script has not been removed.";
	$xestiascan_lang{"en-GB"}{"multiuserinstallscriptkept"} = "Warning: The multiuser installer script has not been removed.";
	$xestiascan_lang{"en-GB"}{"multiuserscriptremoved"}	= "The multiuser installer script was removed.";
	$xestiascan_lang{"en-GB"}{"installscriptremoved"}	= "The installer script was removed.";
	$xestiascan_lang{"en-GB"}{"installedmessage"}	= "The configuration file for Xestia Scanner Server has been written. To change the settings in the configuration file at a later date use the Edit Settings link in the View Settings sub-menu at the top of the page when using Xestia Scanner Server.";
	$xestiascan_lang{"en-GB"}{"cannotremovemultiuserinstallerscript"}	= "Unable to remove the multiuser installer script: %s. The multiuser installer script will have to be deleted manually.";
	$xestiascan_lang{"en-GB"}{"cannotremoveinstallerscript"}	= "Unable to remove the installer script: %s. The installer script will have to be deleted manually.";
	$xestiascan_lang{"en-GB"}{"usexestiascannerservertext"}	= "To use Xestia Scanner Server click or select the link below (will not work if the Xestia Scanner Server script is not called xsdss.cgi):";
	$xestiascan_lang{"en-GB"}{"usexestiascannerserverlink"}	= "Start using Xestia Scanner Server";

	$xestiascan_lang{"en-GB"}{"multiuserresults"} = "The multiuser installer has preformed the following actions:";
	$xestiascan_lang{"en-GB"}{"forciblyrecreated"} = "The tables will be forcibly recreated.";
	$xestiascan_lang{"en-GB"}{"notforciblyrecreated"} = "The tables will not be forcibly recreated.";
	$xestiascan_lang{"en-GB"}{"modulestableerror"} = "An error occured while creating the permissions table for modules: ";
	$xestiascan_lang{"en-GB"}{"modulestablesuccess"} = "The permissions table for modules was created successfully.";
	$xestiascan_lang{"en-GB"}{"scannerstableerror"} = "An error occured while creating the permissions table for scanners: ";
	$xestiascan_lang{"en-GB"}{"scannerstablesuccess"} = "The permissions table for scanners was created successfully.";
	$xestiascan_lang{"en-GB"}{"sessionstableerror"} = "An error occured while creating the permissions table for scanners: ";
	$xestiascan_lang{"en-GB"}{"sessionstablesuccess"} = "The sessions table was created successfully.";
	$xestiascan_lang{"en-GB"}{"userstableerror"} = "An error occured while creating the permissions table for users: ";
	$xestiascan_lang{"en-GB"}{"userstablesuccess"} = "The users table was created successfully.";
	$xestiascan_lang{"en-GB"}{"adminaccounterror"} = "An error occured whilst trying to create the administrative account: ";
	$xestiascan_lang{"en-GB"}{"adminaccountsuccess"} = "The administrative account was created successfully.";

	$xestiascan_lang{"en-GB"}{"autherroroccured"} = "An error occured whilst using the authentication module: ";


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
# noerror	Specifies if Xestia Scanner Server should return an error or not#
#		on certain values.						#
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

		"dbdirectorytoolong" 		=> $xestiascan_lang{$language_selected}{dbdirectorytoolong},
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
		"authmoduleinvalidpermissions"	=> $xestiascan_lang{$language_selected}{authmoduleinvalidpermissions},

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
		"createmodulestoolong"			=> $xestiascan_lang{$language_selected}{createmodulestoolong},
		"createscannerstoolong"			=> $xestiascan_lang{$language_selected}{createscannerstoolong},
		"createsessionstoolong"			=> $xestiascan_lang{$language_selected}{createsessionstoolong},
		"createuserstoolong"			=> $xestiascan_lang{$language_selected}{createuserstoolong},
		"forcerecreatetoolong"			=> $xestiascan_lang{$language_selected}{forcerecreatetoolong},
		"deleteinstalltoolong"			=> $xestiascan_lang{$language_selected}{deleteinstalltoolong},
		"deletemultiusertoolong"		=> $xestiascan_lang{$language_selected}{deletemultiusertoolong},
	
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

sub xestiascan_settings_load{
#################################################################################
# xestiascan_settings_load: Load the configuration settings into the global	#
# variables.									#
#										#
# Usage:									#
#										#
# xestiascan_settings_load();							#
#################################################################################

	# Check if the Xestia Scanner Server configuration file exists before using it and
	# return an critical error if it doesn't exist.

	my ($xestiascan_settingsfilehandle, @config_data, %config, $config);
	my $xestiascan_conf_exist = xestiascan_fileexists("xsdss.cfg");

	if ($xestiascan_conf_exist eq 1){

		# The configuration really does not exist so return an critical error.
		
		return 1;

	}
	
	# Check if the Xestia Scanner Server configuration file has valid permission settings
	# before using it and return an critical error if it doesn't have the
	# valid permission settings.

	my $xestiascan_conf_permissions = xestiascan_filepermissions("xsdss.cfg", 1, 0);

	if ($xestiascan_conf_permissions eq 1){

		# The permission settings for the Xestia Scanner Server configuration file are
		# invalid, so return an critical error.
		
		return 1;

	}

	# Converts the file into meaningful data for later on in this subroutine.

	my $xestiascan_conf_file = 'xsdss.cfg';

	open($xestiascan_settingsfilehandle, $xestiascan_conf_file);
	binmode $xestiascan_settingsfilehandle, ':utf8';
	@config_data = <$xestiascan_settingsfilehandle>;
	%config = xestiascan_processconfig(@config_data);
	close($xestiascan_settingsfilehandle);

	# Go and fetch the settings and place them into a hash.
	
	%xestiascan_config = (

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

	my $xestiascan_config_dbmodule_filename = xestiascan_variablecheck($xestiascan_config{"system_authmodule"}, "module", 0, 1);

	# Check if the database module name is valid.

	if ($xestiascan_config_dbmodule_filename eq 1){

		# The database module filename given is blank so return.
		
		return 1;

	}

	if ($xestiascan_config_dbmodule_filename eq 2){

		# The database module filename given is invalid so return
		# an critical error.

		return 1;

	}

	# Check if the database module does exist before loading it and return an critical error
	# if the database module does not exist.

	my $xestiascan_config_dbmodule_fileexists = xestiascan_fileexists("Modules/Auth/" . $xestiascan_config{"system_authmodule"} . ".pm");

	if ($xestiascan_config_dbmodule_fileexists eq 1){

		# Database module does not exist so return an critical error.
		
		return 1;

	}

	# Check if the database module does have the valid permission settings and return an
	# critical error if the database module contains invalid permission settings.

	my $xestiascan_config_dbmodule_permissions = xestiascan_filepermissions("Modules/Auth/" . $xestiascan_config{"system_authmodule"} . ".pm", 1, 0);

	if ($xestiascan_config_dbmodule_permissions eq 1){

		# Presentation module contains invalid permissions so return an critical error.
		
		return 1;

	}
	
	return 0;

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

	my ($name, $namestyle, $data, $datastyle) = @_;

	if (!$data){

		$data = "";

	}

	print "<tr>\n";
	print "<td class=\"$namestyle\">$name</td>\n";
	print "<td class=\"$datastyle\">$data</td>\n";
	print "</tr>\n";

}

#################################################################################
# End list of subroutines.							#
#################################################################################

# Process the list of available languages.

my $language_list_name;
my @language_list_short;
my @language_list_long;

foreach my $language (keys %xestiascan_lang){

	$language_list_name = $xestiascan_lang{$language}{"languagename"} . " (" . $language .  ")";
	push(@language_list_short, $language);
	push(@language_list_long, $language_list_name);

}

my $http_query_confirm = $form_data->{'confirm'};

$http_query_confirm = 0 if !$http_query_confirm;

if ($http_query_confirm eq 1){

	# The action to create the tables has been confirmed. Get
	# the required values.
	
	my $http_query_authmodule	= $form_data->{'authmodule'};
	
	my $http_query_databaseserver	= $form_data->{'databaseserver'};
	my $http_query_databaseport	= $form_data->{'databaseport'};
	my $http_query_databaseprotocol	= $form_data->{'databaseprotocol'};
	my $http_query_databasename	= $form_data->{'databasename'};
	my $http_query_databaseusername	= $form_data->{'databaseusername'};
	my $http_query_databasepassword	= $form_data->{'databasepassword'};
	my $http_query_databasetableprefix	= $form_data->{'databasetableprefix'};
	
	my $http_query_adminusername	= $form_data->{'multiuseradminusername'};
	my $http_query_adminpassword	= $form_data->{'multiuseradminpassword'};
	
	my $http_query_createmodules	= $form_data->{'createmodules'};
	my $http_query_createscanners	= $form_data->{'createscanners'};
	my $http_query_createsessions	= $form_data->{'createsessions'};
	my $http_query_createusers	= $form_data->{'createusers'};
	
	my $http_query_forcerecreate	= $form_data->{'forcerecreate'};
	
	my $http_query_deleteinstall	= $form_data->{'deleteinstall'};
	my $http_query_deletemultiuser	= $form_data->{'deleteinstallmultiuser'};
	
	# Check the data that has been passed to the multiuser installer.
	
	if (!$http_query_createmodules){
		
		$http_query_createmodules = "off";
		
	}

	if (!$http_query_createscanners){
		
		$http_query_createscanners = "off";
		
	}

	if (!$http_query_createsessions){
		
		$http_query_createsessions = "off";
		
	}
	
	if (!$http_query_createusers){
		
		$http_query_createusers = "off";
		
	}
	
	if (!$http_query_forcerecreate){
		
		$http_query_forcerecreate = "off";
		
	}
	
	if (!$http_query_deleteinstall){
	
		$http_query_deleteinstall = "off";
		
	}
	
	if (!$http_query_deletemultiuser){
		
		$http_query_deletemultiuser = "off";
		
	}
	
	my $xestiascan_authmodule_modulename_check		= xestiascan_variablecheck($http_query_authmodule, "module", 0, 1);
	my $xestiascan_databaseserver_length_check		= xestiascan_variablecheck($http_query_databaseserver, "maxlength", 128, 1);
	my $xestiascan_databaseserver_lettersnumbers_check	= xestiascan_variablecheck($http_query_databaseserver, "lettersnumbers", 0, 1);
	my $xestiascan_databaseport_length_check		= xestiascan_variablecheck($http_query_databaseport, "maxlength", 5, 1);
	my $xestiascan_databaseport_numbers_check		= xestiascan_variablecheck($http_query_databaseport, "numbers", 0, 1);
	my $xestiascan_databaseport_port_check			= xestiascan_variablecheck($http_query_databaseport, "port", 0, 1);
	my $xestiascan_databaseprotocol_length_check		= xestiascan_variablecheck($http_query_databaseprotocol, "maxlength", 5, 1);
	my $xestiascan_databaseprotocol_protocol_check		= xestiascan_variablecheck($http_query_databaseprotocol, "serverprotocol", 0, 1);
	my $xestiascan_databasename_length_check		= xestiascan_variablecheck($http_query_databasename, "maxlength", 32, 1);
	my $xestiascan_databasename_lettersnumbers_check	= xestiascan_variablecheck($http_query_databasename, "lettersnumbers", 0, 1);
	my $xestiascan_databaseusername_length_check		= xestiascan_variablecheck($http_query_databaseusername, "maxlength", 16, 1);
	my $xestiascan_databaseusername_lettersnumbers_check	= xestiascan_variablecheck($http_query_databaseusername, "lettersnumbers", 0, 1);
	my $xestiascan_databasepassword_length_check		= xestiascan_variablecheck($http_query_databasepassword, "maxlength", 64, 1);
	my $xestiascan_databasetableprefix_length_check		= xestiascan_variablecheck($http_query_databasetableprefix, "maxlength", 16, 1);
	my $xestiascan_databasetableprefix_lettersnumbers_check	= xestiascan_variablecheck($http_query_databasetableprefix, "lettersnumbers", 0, 1);
	
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
	
	if (!-e "Modules/Auth/" . $http_query_authmodule . ".pm"){
		
		# The database module is missing so return an
		# error.
		
		xestiascan_error("authmodulemissing");
		
	}
	
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
	
	# Check the admin username and password to make sure they have valid UTF-8.

	xestiascan_variablecheck($http_query_adminusername, "utf8", 0, 0);
	xestiascan_variablecheck($http_query_adminpassword, "utf8", 0, 0);
	
	# Check the checkable values.
	
	my $xestiascan_createmodules_length_check		= xestiascan_variablecheck($http_query_createmodules, "maxlength", 3, 1);
	my $xestiascan_createscanners_length_check		= xestiascan_variablecheck($http_query_createscanners, "maxlength", 3, 1);
	my $xestiascan_createsessions_length_check		= xestiascan_variablecheck($http_query_createsessions, "maxlength", 3, 1);
	my $xestiascan_createusers_length_check			= xestiascan_variablecheck($http_query_createusers, "maxlength", 3, 1);
	my $xestiascan_forcerecreate_length_check		= xestiascan_variablecheck($http_query_forcerecreate, "maxlength", 3, 1);
	my $xestiascan_deleteinstall_length_check		= xestiascan_variablecheck($http_query_deleteinstall, "maxlength", 3, 1);
	my $xestiascan_deletemultiuser_length_check		= xestiascan_variablecheck($http_query_deletemultiuser, "maxlength", 3, 1);
	
	if ($xestiascan_createmodules_length_check eq 1){
		
		xestiascan_error("createmodulestoolong");
		
	}
	
	if ($xestiascan_createscanners_length_check eq 1){
	
		xestiascan_error("createscannerstoolong");
		
	}
	
	if ($xestiascan_createsessions_length_check eq 1){

		xestiascan_error("createsessionstoolong");
		
	}
	
	if ($xestiascan_createusers_length_check eq 1){
	
		xestiascan_error("createuserstoolong");
		
	}
	
	if ($xestiascan_forcerecreate_length_check eq 1){

		xestiascan_error("forcerecreatetoolong");
		
	}
	
	if ($xestiascan_deleteinstall_length_check eq 1){
		
		xestiascan_error("deleteinstalltoolong");
		
	}
	
	if ($xestiascan_deletemultiuser_length_check eq 1){
		
		xestiascan_error("deletemultiusertoolong");
		
	}
	
	# Check to see if the tables need to be recreated forcibly.
	
	my $forcerecreate = 0;
	
	if ($http_query_forcerecreate eq "on"){
		
		$forcerecreate = 1;
		
	}
	
	# Load the authentication module. Double check to make sure
	# it really is a multiuser module and throw an error if not.
	
 	my $authmodule_fullname = "Auth::" . $http_query_authmodule;
 	($authmodule_fullname) = $authmodule_fullname =~ m/^(.*)$/g; # CHECK THIS!!
 	eval "use " . $authmodule_fullname;
 	$authmodule_fullname = "Modules::Auth::" . $http_query_authmodule;
 	my $authmodule = $authmodule_fullname->new();
	
	my %authmodule_capabilities = $authmodule->capabilities();
	
	if ($authmodule_capabilities{'multiuser'} ne 1){
	
		# Return an error, this module is not a multiuser module.
		
		xestiascan_error("notmultiuser");
		
	}
	
	# Check if password value is blank and load settings files
	# if this is the case.
	
	if (!$http_query_databasepassword){
		
		if (xestiascan_settings_load eq 0){
			
			$http_query_databasepassword = $xestiascan_config{"database_password"};
			
		}
		
	}
	
	# Load the settings for the database server.
	
 	$authmodule->loadsettings({ DateTime => "DD/MM/YY hh:mm:ss", Server => $http_query_databaseserver, Port => $http_query_databaseport, Protocol => $http_query_databaseprotocol, Database => $http_query_databasename, Username => $http_query_databaseusername, Password => $http_query_databasepassword, TablePrefix => $http_query_databasetableprefix });
	
	# Connect to the database server.
	
	$authmodule->connect();

	if ($authmodule->geterror eq "AuthConnectionError"){
		
		# A database connection error has occured so return
		# an error.
		
		print "Content-Type: text/html; charset=utf-8;\r\n\r\n";
		print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
		print "<head>\n<title>$xestiascan_lang{$language_selected}{installertitle}</title>\n";
		print "<style type=\"text/css\" media=\"screen\">$cssstyle</style>\n</head>\n<body>";
		
		print "<div class=\"topbar\">
		<span class=\"title\">" . $xestiascan_lang{$language_selected}{installertitle} .  "</span>";
		print "</div>";	
		
		print "<div class=\"pagespacing\">";
		print $xestiascan_lang{$language_selected}{autherroroccured} . $authmodule->geterror(1);
		print "</div>";
		
		exit;
		
	}

	# Print the header part.
	
	print "Content-type: text/html; charset=utf-8;\r\n\r\n";
	
	print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
	print "<head>\n<title>$xestiascan_lang{$language_selected}{installertitle}</title>\n";
	print "<style type=\"text/css\" media=\"screen\">$cssstyle</style>\n</head>\n<body>";

	print "<div class=\"topbar\">
	<span class=\"title\">" . $xestiascan_lang{$language_selected}{installertitle} .  "</span>";
	print "</div>";	
	
	print "<div class=\"pagespacing\">\n";
	print "<span class=\"pageheader\">$xestiascan_lang{$language_selected}{installertitle}</span><br /><br />\n";
	
	print $xestiascan_lang{$language_selected}{multiuserresults} . "<br /><br />";
	
	# Create/Recreate the tables as needed.
	
	if ($forcerecreate eq 1){
	
		print $xestiascan_lang{$language_selected}{forciblyrecreated};
		
	} else {
	
		print $xestiascan_lang{$language_selected}{notforciblyrecreated};
		
	}
	
	print "<br /><br />";
	
	# Create/Recreate the modules permissions table.
	
	if ($http_query_createmodules eq "on"){
	
		$authmodule->populatetables("modules", $forcerecreate);
	
		if ($authmodule->geterror eq "DatabaseError"){
		
			print $xestiascan_lang{$language_selected}{modulestableerror} . $authmodule->geterror(1) . "<br />";	
	
		} else {
			
			print $xestiascan_lang{$language_selected}{modulestablesuccess} . "<br />";
			
		}
			
	}
		
	# Create/Recreate the scanners permissions table.

	if ($http_query_createscanners eq "on"){
	
		$authmodule->populatetables("scanners", $forcerecreate);

		if ($authmodule->geterror eq "DatabaseError"){
		
			print $xestiascan_lang{$language_selected}{scannerstableerror} . $authmodule->geterror(1) . "<br />";	
	
		} else {
		
			print $xestiascan_lang{$language_selected}{scannerstablesuccess} . "<br />";
			
		}
			
	}
		
	# Create/Recreate the sessions permissions table.

	if ($http_query_createsessions eq "on"){
	
		$authmodule->populatetables("sessions", $forcerecreate);
		
		if ($authmodule->geterror eq "DatabaseError"){
		
			print $xestiascan_lang{$language_selected}{sessionstableerror} . $authmodule->geterror(1) . "<br />";
			
		} else {
			
			print $xestiascan_lang{$language_selected}{sessionstablesuccess} . "<br />";
			
		}
		
	}
	
	# Create/Recreate the users table.
	
	if ($http_query_createusers eq "on"){
	
		$authmodule->populatetables("users", $forcerecreate);
		
		if ($authmodule->geterror eq "DatabaseError"){
			
			print $xestiascan_lang{$language_selected}{userstableerror} . $authmodule->geterror(1) . "<br />";
			
		} else {
			
			print $xestiascan_lang{$language_selected}{userstablesuccess} . "<br />";
		
			# Since the users table was created, add the Administrative account.
			
			my (%userinfo, $userinfo);
			
			$userinfo{Username} = $http_query_adminusername;
			$userinfo{Name} = "Administrator";
			$userinfo{Password} = $http_query_adminpassword; 
			$userinfo{Enabled} = "on";
			$userinfo{Admin} = "on";
			
			$authmodule->adduser($http_query_adminusername, %userinfo);
			
			if ($authmodule->geterror eq "DatabaseError"){
			
				print $xestiascan_lang{$language_selected}{adminaccounterror} . $authmodule->geterror(1) . "<br />";
				
			} else {
				
				print $xestiascan_lang{$language_selected}{adminaccountsuccess} . "<br />";
				
			}
			
		}
		
	}
	
	print "<br />";

	# Check if the scripts need deleting.
	
	my $installscriptmessage;
	
	if ($http_query_deleteinstall eq "on"){
		
		if (unlink($originstallscriptname)){
			
			print $xestiascan_lang{$language_selected}{installscriptremoved} . "<br />";
			
		} else {

			$installscriptmessage = $xestiascan_lang{$language_selected}{cannotremoveinstallerscript};
			$installscriptmessage =~ s/%s/$!/g;
			
			print $installscriptmessage . "<br />";
			
		}
		
	} else {
	
		print $xestiascan_lang{$language_selected}{installscriptkept} . "<br />";
		
	}
	
	if ($http_query_deletemultiuser eq "on"){
		
		if (unlink($installscriptname)){
		
			print $xestiascan_lang{$language_selected}{multiuserscriptremoved} . "<br />";	
			
		} else {
			
			$installscriptmessage = $xestiascan_lang{$language_selected}{cannotremovemultiuserinstallerscript};
			$installscriptmessage =~ s/%s/$!/g;
			
			print $installscriptmessage . "<br />";		
			
		}
		
	} else {
		
		print $xestiascan_lang{$language_selected}{multiuserinstallscriptkept} . "<br />";
		
	}
	
	print "<br />";
	
	print $xestiascan_lang{$language_selected}{usexestiascannerservertext} . "<br /><br />";
	
	print "<a href=\"" . $xestiascanscriptname . "\">$xestiascan_lang{$language_selected}{usexestiascannerserverlink}</a>";
	
	print "</div>";
	
	exit;
	
}

# Load the configuration file and get the required settings.

# Check to see if the settings file is valid.

# Get the list of database modules.

opendir(DATABASEDIR, "Modules/Auth");
my @dbmodule_directory = grep /m*\.pm$/, readdir(DATABASEDIR);
closedir(DATABASEDIR);

my @database_modules;

foreach my $dbmodule_file (@dbmodule_directory){

	# Get the friendly name for the database module.

	next if $dbmodule_file =~ m/^\./;
	next if $dbmodule_file !~ m/.pm$/;
	$dbmodule_file =~ s/.pm$//g;
	push(@database_modules, $dbmodule_file);

}


# Check to see if the database module does support a multiuser configuration.

my $dbmodule;
my $dbmodule_out = "";
my @dbmodule_multiuser;
my $dbmodule_fullname;
my %dbmodule_capabilities;
use lib "Modules/";

foreach my $dbmodule_file (@database_modules){

	# Load the module and see if has multiuser support and
	# if it has then add it to the list of multiuser supported
	# database modules and then unload it.

 	my $dbmodule_fullname = "Auth::" . $dbmodule_file;
 	($dbmodule_fullname) = $dbmodule_fullname =~ m/^(.*)$/g; # CHECK THIS!!
 	eval "use " . $dbmodule_fullname;
 	$dbmodule_fullname = "Modules::Auth::" . $dbmodule_file;
 	$dbmodule = $dbmodule_fullname->new();

	%dbmodule_capabilities = $dbmodule->capabilities();

	undef($dbmodule);
	
	push(@dbmodule_multiuser, $dbmodule_file) if $dbmodule_capabilities{'multiuser'} eq 1;

}

# Print out a form specifying if the users and/or sessions table should be created.

my $config_fail = 0;

if (xestiascan_settings_load ne 0){

	$config_fail = 1;
	
} else {
	
	$default_dbmodule	= $xestiascan_config{system_authmodule};
	$default_server		= $xestiascan_config{database_server};
	$default_port		= $xestiascan_config{database_port};
	$default_protocol	= $xestiascan_config{database_protocol};
	$default_name		= $xestiascan_config{database_sqldatabase};
	$default_username	= $xestiascan_config{database_username};
	$default_prefix		= $xestiascan_config{database_tableprefix};
	
}

print "Content-type: text/html; charset=utf-8;\r\n\r\n";

print "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">\n";
print "<head>\n<title>$xestiascan_lang{$language_selected}{installertitle}</title>\n";
print "<style type=\"text/css\" media=\"screen\">$cssstyle</style>\n</head>\n<body>";

# Start language bar.

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

print "<div class=\"pagespacing\">";

print "<span class=\"pageheader\">$xestiascan_lang{$language_selected}{installertitle}</span><br /><br />\n";
print $xestiascan_lang{$language_selected}{installertext};

print "<br /><br />";

if ($config_fail eq 1){

	print $xestiascan_lang{$language_selected}{invalidconfigfile};
	print "<br /><br />";
	
}

print "<form action=\"" . $installscriptname . "\" method=\"POST\">";
print "<input type=\"hidden\" name=\"confirm\" value=\"1\">\n<input type=\"hidden\" name=\"installlanguage\" value=\"$language_selected\">\n";

# End of language bar, begin main installer part.

print "<table width=\"100%\">";
xestiascan_addtablerow($xestiascan_lang{$language_selected}{authsettings}, "tablecellheader", "", "tablecellheader");

$dbmodule_out = "<select name=\"authmodule\">";

foreach my $dbmodule_file (@dbmodule_multiuser){
	if ($default_dbmodule eq $dbmodule_file){
		$dbmodule_out = $dbmodule_out . "<option value=\"$dbmodule_file\" selected>$dbmodule_file</option>";		
	} else {
		$dbmodule_out = $dbmodule_out . "<option value=\"$dbmodule_file\">$dbmodule_file</option>";
	}
}

$dbmodule_out = $dbmodule_out . "</select><br />" . $xestiascan_lang{$language_selected}{multiuseronly};

xestiascan_addtablerow($xestiascan_lang{$language_selected}{authenticationmodule}, "tablename", $dbmodule_out, "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databaseserver}, "tablename", "<input type=\"text\" name=\"databaseserver\" size=\"32\" maxlength=\"128\" value=\"$default_server\">\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databaseport}, "tablename", "<input type=\"text\" name=\"databaseport\" maxlength=\"5\" size=\"5\" value=\"$default_port\">\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databaseprotocol}, "tablename", "<select name=\"databaseprotocol\">\n<option value=\"tcp\">tcp</option>\n<option value=\"udp\">udp</option>\n</select>\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databasename}, "tablename", "<input type=\"text\" name=\"databasename\" size=\"32\" maxlength=\"32\" value=\"$default_name\">\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databaseusername}, "tablename", "<input type=\"text\" name=\"databaseusername\" size=\"16\" maxlength=\"16\" value=\"$default_username\">\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databasepassword}, "tablename", "<input type=\"password\" name=\"databasepassword\" size=\"32\" maxlength=\"64\"><br />Leave password blank to use password in configuration file.\n", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{databasetableprefix}, "tablename", "<input type=\"text\" name=\"databasetableprefix\" size=\"32\" maxlength=\"32\" value=\"$default_prefix\">\n", "tabledata");

xestiascan_addtablerow($xestiascan_lang{$language_selected}{adminuseraccountsettings}, "tablecellheader", "", "tablecellheader");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{adminusername}, "tablename", "<input type=\"text\" name=\"multiuseradminusername\" size=\"32\" maxlength=\"32\" value=\"$xestiascan_lang{$language_selected}{adminaccountname}\">", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{adminpassword}, "tablename", "<input type=\"password\" name=\"multiuseradminpassword\" size=\"32\" maxlength=\"128\" value=\"$xestiascan_lang{$language_selected}{adminaccountpassword}\">", "tabledata");

xestiascan_addtablerow($xestiascan_lang{$language_selected}{installationoptions}, "tablecellheader", "", "tablecellheader");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{createtables}, "tablename", "<input type=\"checkbox\" name=\"createmodules\" checked>" . $xestiascan_lang{$language_selected}{createtablemodulepermissions} . "<br /><input type=\"checkbox\" name=\"createscanners\" checked>" . $xestiascan_lang{$language_selected}{createtablescannerspermissions} . "<br /><input type=\"checkbox\" name=\"createsessions\" checked>" . $xestiascan_lang{$language_selected}{createtablesessions} . "<br /><input type=\"checkbox\" name=\"createusers\" checked>" . $xestiascan_lang{$language_selected}{createtableusers} . "<br />", "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{forcerecreate}, "tablename", "<input type=\"checkbox\" name=\"forcerecreate\">" . $xestiascan_lang{$language_selected}{forcerecreatetables}, "tabledata");
xestiascan_addtablerow($xestiascan_lang{$language_selected}{deleteinstallscripts}, "tablename", "<input type=\"checkbox\" name=\"deleteinstall\" checked>" . $xestiascan_lang{$language_selected}{removeinstallscript} . "<br /><input type=\"checkbox\" name=\"deleteinstallmultiuser\" checked>" . $xestiascan_lang{$language_selected}{removemultiuserinstallscript} . "<br /><br /><b>" . $xestiascan_lang{$language_selected}{warningmessage} . $xestiascan_lang{$language_selected}{recommendremoving} . "</b>", "tabledata");

print "</table>\n";

print "<input type=\"submit\" value=\"Create tables\"> | <input type=\"reset\" value=\"Reset settings\">";

print "</form></div>";

print "</body></html>";

__END__