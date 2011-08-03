#################################################################################
# Xestia Scanner Server - Settings System Module				#
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

package Modules::System::Settings;

use Modules::System::Common;
use Modules::System::Scan;
use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(xestiascan_settings_view xestiascan_settings_edit xestiascan_output_config); 

sub xestiascan_settings_getauthmodules{
#################################################################################
# xestiascan_settings_getauthmodules: Gets the list of available authentication	#
#				      modules.					#
#										#
# Usage:									#
#										#
# @authmodules = xestiascan_settings_getauthmodules;				#
#################################################################################
	
	my (@authmoduleslist, @authmoduleslist_final);
	my $authmodulefile;
	
	opendir(AUTHMODULEDIR, "Modules/Auth");
	@authmoduleslist = grep /m*\.pm$/, sort(readdir(AUTHMODULEDIR));
	closedir(AUTHMODULEDIR);
	
	foreach $authmodulefile (@authmoduleslist){
		next if $authmodulefile =~ m/^\./;
		next if $authmodulefile !~ m/.pm$/;
		$authmodulefile =~ s/.pm$//;
		push(@authmoduleslist_final, $authmodulefile);
	}
	
	return @authmoduleslist_final;
	
}

sub xestiascan_settings_getpresmodules{
#################################################################################
# xestiascan_settings_getpresmodules: Gets the list of available presentation	#
#				      modules.					#
#										#
# Usage:									#
#										#
# @presmodules = xestiascan_settings_getpresmodules;				#
#################################################################################
	
	my (@presmoduleslist, @presmoduleslist_final);
	my $presmodulefile;
	
	opendir(PRESMODULEDIR, "Modules/Presentation");
	@presmoduleslist = grep /m*\.pm$/, sort(readdir(PRESMODULEDIR));
	closedir(PRESMODULEDIR);
	
	foreach $presmodulefile (@presmoduleslist){
		next if $presmodulefile =~ m/^\./;
		next if $presmodulefile !~ m/.pm$/;
		$presmodulefile =~ s/.pm$//;
		push(@presmoduleslist_final, $presmodulefile);
	}
	
	return @presmoduleslist_final;
	
}

sub xestiascan_settings_getlanguages{
#################################################################################
# xestiascan_settings_getlanguages: Gets the list of available languages.	#
#										#
# Usage:									#
#										#
# @languages = xestiascan_settings_getlanguages;				#
#################################################################################
	
	my (@langmoduleslist, @langmoduleslist_final);
	my $langmodulefile;
	
	opendir(LANGUAGESDIR, "lang");
	@langmoduleslist = grep /m*\.lang$/, sort(readdir(LANGUAGESDIR));
	closedir(LANGUAGESDIR);
	
	foreach $langmodulefile (@langmoduleslist){
		next if $langmodulefile =~ m/^\./;
		next if $langmodulefile !~ m/.lang$/;
		$langmodulefile =~ s/.lang$//;
		push(@langmoduleslist_final, $langmodulefile);
	}
	
	return @langmoduleslist_final;
	
}

sub xestiascan_settings_view{
#################################################################################
# xestiascan_options_view: Writes out the list of options and variables.		#
#										#
# Usage:									#
#										#
# xestiascan_settings_view();							#
#################################################################################
	
	# Connect to the database server.
	
	$main::xestiascan_authmodule->connect();
	
	# Check if any errors occured while connecting to the database server.
	
	if ($main::xestiascan_authmodule->geterror eq "AuthConnectionError"){
		
		# A database connection error has occured so return
		# an error.
		
		xestiascan_error("authconnectionerror", $main::xestiascan_authmodule->geterror(1));
		
	}
	
	my $access_viewsettings = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "Admin" });
	
 	if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
		
		# A database error has occured so return an error with
		# the extended error information.
		
		xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1));
		
	}
	
	if ($access_viewsettings ne 1){
		
		# User not allowed to perform this action so return an error.
		xestiascan_error("notpermitted");
		
	}
	
	# Disconnect from the database server.
	
	$main::xestiascan_authmodule->disconnect();
	
	# Get the settings.

	my $settings_noncgi_images		= $main::xestiascan_config{"directory_noncgi_images"};
	my $settings_noncgi_scans		= $main::xestiascan_config{"directory_noncgi_scans"};
	my $settings_fs_scans			= $main::xestiascan_config{"directory_fs_scans"};
	my $settings_system_datetime		= $main::xestiascan_config{"system_datetime"};
	my $settings_system_language		= $main::xestiascan_config{"system_language"};
	my $settings_system_presentation	= $main::xestiascan_config{"system_presmodule"};
	my $settings_system_auth		= $main::xestiascan_config{"system_authmodule"};
	my $settings_system_output		= $main::xestiascan_config{"system_outputmodule"};

	$main::xestiascan_presmodule->startbox("sectionboxnofloat");
	$main::xestiascan_presmodule->startbox("sectiontitle");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{viewsettings});
	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->startbox("secondbox");	

	$main::xestiascan_presmodule->startform($main::xestiascan_env{"script_filename"}, "POST");
	$main::xestiascan_presmodule->addhiddendata("mode", "settings");
	$main::xestiascan_presmodule->addbutton("action", { Value => "edit", Description => $main::xestiascan_lang{setting}{editsettings} });
	$main::xestiascan_presmodule->endform();
	$main::xestiascan_presmodule->addlinebreak();
	
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{currentsettings});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->starttable("", { CellPadding => 5, CellSpacing => 0 });

	$main::xestiascan_presmodule->startheader();
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{common}{setting}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{common}{value}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->endheader();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{directories});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{imagesuripath});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($settings_noncgi_images);
	$main::xestiascan_presmodule->endcell();
	$main::main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{scansuripath});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($settings_noncgi_scans);
	$main::xestiascan_presmodule->endcell();
	$main::main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{scansfspath});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($settings_fs_scans);
	$main::xestiascan_presmodule->endcell();
	$main::main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{date});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{dateformat});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($settings_system_datetime);
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{language});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{systemlanguage});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($settings_system_language);
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{modules});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{presentationmodule});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($settings_system_presentation);
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{outputmodule});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($settings_system_output);
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{authmodule});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($settings_system_auth);
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->endtable();

	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{altersettings});

	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->endbox();
	
	return $main::xestiascan_presmodule->grab();

}

sub xestiascan_settings_edit{
#################################################################################
# xestiascan_settings_edit: Edits the options.					#
#										#
# Usage:									#
#										#
# xestiascan_settings_edit(options);						#
#										#
# options		Specifies the following options in any order.		#
#										#
# ScansURIPath		Specifies the new URI path for scanned images.		#
# ScansFSPath		Specifies the new filesystem path for scanned images.	#
# DateTimeFormat	Specifies the new date and time format to use.		#
# ImagesURIPath		Specifies the new URI path for images.			#
# DateTimeFormat	Specifies the new date and time format.			#
# SystemLanguage	Specifies the new language to use for Xestia Scanner	#
#			Server.							#
# PrsentationModule	Specifies the new presentation module to use for	#
#			Xestia Scanner Server.					#
# AuthModule		Specifies the new authentication module to use for	#
#			Xestia Scanner Server.					#
# OutputModule		Specifies the new output module to use for Xestia	#
#			Scanner Server.						#
#										#
# Options for server-based authentication modules.				#
#										#
# DatabaseServer	Specifies the database server to use.			#
# DaravasePort		Specifies the port the database server is running on.	#
# DatabaseProtocol	Specifies the protocol the database server is using.	#
# DatabaseSQLDatabase	Specifies the SQL database name to use.			#
# DatabaseUsername	Specifies the database server username.			#
# DatabasePasswordKeep	Keeps the current password in the configuration file.	#
# DatabasePassword	Specifies the password for the database server username.#
# DatabaseTablePrefix	Specifies the prefix used for tables.			#
#################################################################################

	# Get the values that have been passed to the subroutine.

	my ($passedoptions) = @_;

	# Get the values from the hash.

	my $settings_imagesuri			= $passedoptions->{"ImagesURIPath"};
	my $settings_scansuri			= $passedoptions->{"ScansURIPath"};
	my $settings_scansfs			= $passedoptions->{"ScansFSPath"};
	my $settings_datetimeformat		= $passedoptions->{"DateTimeFormat"};
	my $settings_languagesystem		= $passedoptions->{"SystemLanguage"};
	my $settings_presmodule			= $passedoptions->{"PresentationModule"};
	my $settings_outputmodule		= $passedoptions->{"OutputModule"};
	my $settings_authmodule			= $passedoptions->{"AuthModule"};

	my $settings_database_server		= $passedoptions->{"DatabaseServer"};
	my $settings_database_port		= $passedoptions->{"DatabasePort"};
	my $settings_database_protocol		= $passedoptions->{"DatabaseProtocol"};
	my $settings_database_sqldatabase	= $passedoptions->{"DatabaseSQLDatabase"};
	my $settings_database_username		= $passedoptions->{"DatabaseUsername"};
	my $settings_database_passwordkeep	= $passedoptions->{"DatabasePasswordKeep"};
	my $settings_database_password		= $passedoptions->{"DatabasePassword"};
	my $settings_database_tableprefix	= $passedoptions->{"DatabaseTablePrefix"};

	my $confirm				= $passedoptions->{"Confirm"};

	# Connect to the database server.
	
	$main::xestiascan_authmodule->connect();
	
	# Check if any errors occured while connecting to the database server.
	
	if ($main::xestiascan_authmodule->geterror eq "AuthConnectionError"){
		
		# A database connection error has occured so return
		# an error.
		
		xestiascan_error("authconnectionerror", $main::xestiascan_authmodule->geterror(1));
		
	}
	
	my $access_editsettings = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "Admin" });
	
 	if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
		
		# A database error has occured so return an error with
		# the extended error information.
		
		xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1));
		
	}
	
	if ($access_editsettings ne 1){
		
		# User not allowed to perform this action so return an error.
		xestiascan_error("notpermitted");
		
	}
	
	# Disconnect from the database server.
	
	$main::xestiascan_authmodule->disconnect();
	
	if (!$confirm){

		# If the confirm value is blank, then set the confirm
		# value to 0.

		$confirm = 0;

	}

	if ($confirm eq "1"){

		# The action to edit the settings has been confirmed.
		# Start by checking each variable about to be placed
		# in the settings file is valid.

		# Deinfe some variables for later.

		my @xestiascan_new_settings;

		# Check the length of the directory names.

		xestiascan_variablecheck($settings_imagesuri, "maxlength", 512, 0);
		xestiascan_variablecheck($settings_scansuri, "maxlength", 512, 0);
		xestiascan_variablecheck($settings_scansfs, "maxlength", 4096, 0);
		xestiascan_variablecheck($settings_datetimeformat, "maxlength", 32, 0);

		xestiascan_variablecheck($settings_languagesystem, "language_filename", "", 0);

		# Check the module names to see if they're valid.

		my $xestiascan_presmodule_modulename_check 	= xestiascan_variablecheck($settings_presmodule, "module", 0, 1);
		my $xestiascan_authmodule_modulename_check		= xestiascan_variablecheck($settings_authmodule, "module", 0, 1);
		my $xestiascan_outputmodule_modulename_check	= xestiascan_variablecheck($settings_outputmodule, "module", 0, 1);

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

		# Check if the directory names only contain letters and numbers and
		# return a specific error if they don't.

		xestiascan_variablecheck($settings_datetimeformat, "datetime", 0, 0);

		# Check if the presentation module with the filename given exists.

		my $presmodule_exists = xestiascan_fileexists("Modules/Presentation/" . $settings_presmodule . ".pm");

		if ($presmodule_exists eq 1){

			# The presentation module does not exist so return an error.

			xestiascan_error("presmodulemissing");

		}

		# Check if the database module with the filename given exists.

		my $authmodule_exists = xestiascan_fileexists("Modules/Auth/" . $settings_authmodule . ".pm");

		if ($authmodule_exists eq 1){

			# The database module does not exist so return an error.

			xestiascan_error("dbmodulemissing");

		}

		# Check if the language filename given exists.

		my $languagefile_exists = xestiascan_fileexists("lang/" . $settings_languagesystem . ".lang");

		if ($languagefile_exists eq 1){

			# The language filename given does not exist so return an error.

			xestiascan_error("languagefilenamemissing");		

		}

		# Check the database server options to see if they are valid.

		my $xestiascan_databaseserver_length_check		= xestiascan_variablecheck($settings_database_server, "maxlength", 128, 1);
		my $xestiascan_databaseserver_lettersnumbers_check	= xestiascan_variablecheck($settings_database_server, "lettersnumbers", 0, 1);
		my $xestiascan_databaseport_length_check			= xestiascan_variablecheck($settings_database_port, "maxlength", 5, 1);
		my $xestiascan_databaseport_numbers_check		= xestiascan_variablecheck($settings_database_port, "numbers", 0, 1);
		my $xestiascan_databaseport_port_check			= xestiascan_variablecheck($settings_database_port, "port", 0, 1);
		my $xestiascan_databaseprotocol_length_check		= xestiascan_variablecheck($settings_database_protocol, "maxlength", 5, 1);
		my $xestiascan_databaseprotocol_protocol_check		= xestiascan_variablecheck($settings_database_protocol, "serverprotocol", 0, 1);
		my $xestiascan_databasename_length_check			= xestiascan_variablecheck($settings_database_sqldatabase, "maxlength", 32, 1);
		my $xestiascan_databasename_lettersnumbers_check		= xestiascan_variablecheck($settings_database_sqldatabase, "lettersnumbers", 0, 1);
		my $xestiascan_databaseusername_length_check		= xestiascan_variablecheck($settings_database_username, "maxlength", 16, 1);
		my $xestiascan_databaseusername_lettersnumbers_check	= xestiascan_variablecheck($settings_database_username, "lettersnumbers", 0, 1);
		my $xestiascan_databasepassword_length_check		= xestiascan_variablecheck($settings_database_password, "maxlength", 64, 1);
		my $xestiascan_databasetableprefix_length_check		= xestiascan_variablecheck($settings_database_tableprefix, "maxlength", 16, 1);
		my $xestiascan_databasetableprefix_lettersnumbers_check	= xestiascan_variablecheck($settings_database_tableprefix, "lettersnumbers", 0, 1);

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

		# Check if the current password should be kept.

		if ($settings_database_passwordkeep eq "on"){

			# The current password in the configuration file should be used.

			$settings_database_password 	= $main::xestiascan_config{"database_password"};

		}

		# Write the new settings to the configuration file.

		xestiascan_output_config({ ImagesURIPath => $settings_imagesuri,
			ScansURIPath => $settings_scansuri,
			ScansFSPath => $settings_scansfs,
			DateTimeFormat => $settings_datetimeformat, 
			SystemLanguage => $settings_languagesystem, 
			PresentationModule => $settings_presmodule, 
			OutputModule => $settings_outputmodule, 
			AuthModule => $settings_authmodule, 
			DatabaseServer => $settings_database_server, 
			DatabasePort => $settings_database_port, 
			DatabaseProtocol => $settings_database_protocol, 
			DatabaseSQLDatabase => $settings_database_sqldatabase, 
			DatabaseUsername => $settings_database_username, 
			DatabasePassword => $settings_database_password, 
			DatabaseTablePrefix => $settings_database_tableprefix 
		});

		# Write a confirmation message.

		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{settingsedited}, { Style => "pageheader" });
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{settingseditedmessage});
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlink($main::xestiascan_env{"script_filename"} . "?mode=settings", { Text => $main::xestiascan_lang{setting}{returnsettingslist} });

		return $main::xestiascan_presmodule->grab();

	}

	# Get the list of languages available.

	my %language_list;
	my @language_directory 		= "";
	my $language;
	my ($language_file, %language_file);
	my $language_filename 		= "";
	my $language_file_localname	= "";
	my $language_file_count		= 0;
	my $language_config		= $main::xestiascan_config{"system_language"};
	my @lang_data;
	my $xestiascan_languagefilehandle;

	tie(%language_list, 'Tie::IxHash');

	@language_directory = xestiascan_settings_getlanguages;
	
	# Process each language by loading the language file
	# used for each language and then get the System name and 
	# the local name of the language.
	
	foreach $language_filename (@language_directory){
		
		# Load the language file currently selected.
		
		open($xestiascan_languagefilehandle, "lang/" . $language_filename . ".lang");
		@lang_data = <$xestiascan_languagefilehandle>;
		%language_file = xestiascan_processconfig(@lang_data);
		close($xestiascan_languagefilehandle);

		# Get the system name and the local name of the language.

		$language_file_localname = $language_file{about}{name};

		# Check if either the system name or the local name of the language
		# is blank and if it is, then don't add the language to the list.

		if (!$language_file_localname){

			# The system name or the local name is blank so don't add
			# the language to the list.
		
		} else {

			# Append the language to the available languages list.

			$language_list{$language_file_count}{Filename} = $language_filename;
			$language_list{$language_file_count}{Name} = $language_file_localname;
			$language_file_count++;

		}

		undef $language_file;

	}

	# Get the list of presentation modules available.

	my %presmodule_list;
	my @presmodule_directory;
	my $presmodule;
	my $presmodule_file 		= "";
	my $presmodule_count		= 0;
	my $presmodule_config		= $main::xestiascan_config{"system_presmodule"};

	# Open and get the list of presentation modules (perl modules) by getting
	# only files which end in .pm.

	@presmodule_directory = xestiascan_settings_getpresmodules;

	foreach $presmodule_file (@presmodule_directory){
		
		$presmodule_list{$presmodule_count}{Filename} = $presmodule_file;
		$presmodule_count++;

	}

	# Get the list of database modules available.

	my %authmodule_list;
	my @authmodule_directory;
	my $authmodule;
	my $authmodule_file 		= "";
	my $authmodule_count		= 0;
	my $authmodule_config		= $main::xestiascan_config{"system_authmodule"};

	# Open and get the list of database modules (perl modules) by getting
	# only files which end in .pm.

	@authmodule_directory = xestiascan_settings_getauthmodules;

	foreach $authmodule_file (@authmodule_directory){

		$authmodule_list{$authmodule_count}{Filename} = $authmodule_file;
		$authmodule_count++;

	}

	my %outputmodule_list;
	my @outputmodule_directory;
	my $outputmodule;
	my $outputmodule_file 		= "";
	my $outputmodule_count		= 0;
	my $outputmodule_config		= $main::xestiascan_config{"system_outputmodule"};

	# Open and get the list of output modules (perl modules) by getting
	# only files which end in .pm.

	@outputmodule_directory = xestiascan_scan_getoutputmodules;

	foreach $outputmodule_file (@outputmodule_directory){

		$outputmodule_list{$outputmodule_count}{Filename} = $outputmodule_file;
		$outputmodule_count++;

	}

	# Get the directory settings.

	my $directory_settings_imagesuri 	= $main::xestiascan_config{"directory_noncgi_images"};
	my $directory_settings_scansuri 	= $main::xestiascan_config{"directory_noncgi_scans"};
	my $directory_settings_scansfs		= $main::xestiascan_config{"directory_fs_scans"};
	my $datetime_setting			= $main::xestiascan_config{"system_datetime"};

	my $database_server			= $main::xestiascan_config{"database_server"};
	my $database_port			= $main::xestiascan_config{"database_port"};
	my $database_protocol			= $main::xestiascan_config{"database_protocol"};
	my $database_sqldatabase		= $main::xestiascan_config{"database_sqldatabase"};
	my $database_username			= $main::xestiascan_config{"database_username"};
	my $database_passwordhash		= $main::xestiascan_config{"database_passwordhash"};
	my $database_password			= $main::xestiascan_config{"database_password"};
	my $database_prefix			= $main::xestiascan_config{"database_tableprefix"};

	# Print out a form for editing the settings.

	$main::xestiascan_presmodule->startbox("sectionboxnofloat");
	$main::xestiascan_presmodule->startbox("sectiontitle");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{editsettings});
	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->startbox("secondbox");
	
	$main::xestiascan_presmodule->addboldtext($main::xestiascan_lang{setting}{warning});
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{warningmessage});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();

	$main::xestiascan_presmodule->startform($main::xestiascan_env{"script_filename"}, "POST");
	$main::xestiascan_presmodule->startbox();
	$main::xestiascan_presmodule->addhiddendata("mode", "settings");
	$main::xestiascan_presmodule->addhiddendata("action", "edit");
	$main::xestiascan_presmodule->addhiddendata("confirm", 1);

	$main::xestiascan_presmodule->starttable("", { CellPadding => 5, CellSpacing => 0 });

	$main::xestiascan_presmodule->startheader();
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{common}{setting}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{common}{value}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->endheader();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{directories});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{imagesuripath});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("imagesuripath", { Size => 32, MaxLength => 512, Value => $directory_settings_imagesuri });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{scansuripath});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("scansuripath", { Size => 32, MaxLength => 512, Value => $directory_settings_scansuri });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{scansfspath});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("scansfspath", { Size => 64, MaxLength => 4096, Value => $directory_settings_scansfs });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{date});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{dateformat});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("datetime", { Size => 32, MaxLength => 64, Value => $datetime_setting });
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->startbox("datalist");

	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{singleday});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{doubleday});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{singlemonth});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{doublemonth});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{singleyear});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{doubleyear});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{singlehour});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{doublehour});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{singleminute});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{doubleminute});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{singlesecond});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{doublesecond});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{othercharacters});
	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{language});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{systemlanguage});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");

	$main::xestiascan_presmodule->addselectbox("language");

	# Process the list of available languages.

	foreach $language (keys %language_list){

		# Check if the language filename matches the filename in the configuration
		# file.

		if ($language_list{$language}{Filename} eq $language_config){

			$main::xestiascan_presmodule->addoption($language_list{$language}{Name}, { Value => $language_list{$language}{Filename} , Selected => 1 });

		} else {

			$main::xestiascan_presmodule->addoption($language_list{$language}{Name}, { Value => $language_list{$language}{Filename} });

		}

	}

	$main::xestiascan_presmodule->endselectbox();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{modules});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecellheader");
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{presentationmodule});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");

	$main::xestiascan_presmodule->addselectbox("presmodule");

	# Process the list of available presentation modules.

	foreach $presmodule (keys %presmodule_list){

		# Check if the presentation module fileanme matches the filename in the 
		# configuration file.

		if ($presmodule_list{$presmodule}{Filename} eq $presmodule_config){

			$main::xestiascan_presmodule->addoption($presmodule_list{$presmodule}{Filename}, { Value => $presmodule_list{$presmodule}{Filename} , Selected => 1 });

		} else {

 			$main::xestiascan_presmodule->addoption($presmodule_list{$presmodule}{Filename}, { Value => $presmodule_list{$presmodule}{Filename} });

		}

	}

	$main::xestiascan_presmodule->endselectbox();

	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{outputmodule});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");

	# Process the list of available output modules.

	$main::xestiascan_presmodule->addselectbox("outputmodule");

	foreach $outputmodule (keys %outputmodule_list){

		# Check if the output module fileanme matches the filename in the 
		# configuration file.

		if ($outputmodule_list{$outputmodule}{Filename} eq $outputmodule_config){

			$main::xestiascan_presmodule->addoption($outputmodule_list{$outputmodule}{Filename}, { Value => $outputmodule_list{$outputmodule}{Filename} , Selected => 1 });

		} else {

 			$main::xestiascan_presmodule->addoption($outputmodule_list{$outputmodule}{Filename}, { Value => $outputmodule_list{$outputmodule}{Filename} });

		}


	}

	$main::xestiascan_presmodule->endselectbox();

	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{authmodule});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");

	# Process the list of available database modules.

	$main::xestiascan_presmodule->addselectbox("authmodule");

	foreach $authmodule (keys %authmodule_list){

		# Check if the database module fileanme matches the filename in the 
		# configuration file.

		if ($authmodule_list{$authmodule}{Filename} eq $authmodule_config){

			$main::xestiascan_presmodule->addoption($authmodule_list{$authmodule}{Filename}, { Value => $authmodule_list{$authmodule}{Filename} , Selected => 1 });

		} else {

 			$main::xestiascan_presmodule->addoption($authmodule_list{$authmodule}{Filename}, { Value => $authmodule_list{$authmodule}{Filename} });

		}


	}

	$main::xestiascan_presmodule->endselectbox();

	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{databaseserver});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("database_server", { Size => 32, MaxLength => 128, Value => $database_server });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{databaseport});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("database_port", { Size => 5, MaxLength => 5, Value => $database_port });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{databaseprotocol});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");

	# Check if TCP is being used.

	$main::xestiascan_presmodule->addselectbox("database_protocol");

	if ($database_protocol eq "tcp"){

		# The TCP protocol is selected so have the TCP option selected.

		$main::xestiascan_presmodule->addoption("TCP", { Value => "tcp", Selected => 1});

	} else {

		# The TCP protocol is not selected.

		$main::xestiascan_presmodule->addoption("TCP", { Value => "tcp"});

	} 

	# Check if UDP is being used.

	if ($database_protocol eq "udp"){

		# The UDP protocol is selected so have the UDP option selected.

		$main::xestiascan_presmodule->addoption("UDP", { Value => "udp", Selected => 1});

	} else {

		# The UDP protocol is not selected.

		$main::xestiascan_presmodule->addoption("UDP", { Value => "udp"});

	}

	$main::xestiascan_presmodule->endselectbox();

	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{databasename});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("database_sqldatabase", { Size => 32, MaxLength => 32, Value => $database_sqldatabase });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{databaseusername});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("database_username", { Size => 16, MaxLength => 16, Value => $database_username });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{databasepassword});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("database_password", { Size => 16, MaxLength => 64, Password => 1 });
	$main::xestiascan_presmodule->addtext(" ");
	$main::xestiascan_presmodule->addcheckbox("database_password_keep", { OptionDescription => $main::xestiascan_lang{setting}{keepcurrentpassword}, Checked => 1 });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{setting}{tableprefix});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("database_tableprefix", { Size => 16, MaxLength => 16, Value => $database_prefix });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();

	$main::xestiascan_presmodule->endtable();

	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addsubmit($main::xestiascan_lang{setting}{changesettingsbutton});
	$main::xestiascan_presmodule->addtext(" | ");
	$main::xestiascan_presmodule->addreset($main::xestiascan_lang{common}{restorecurrent});
	$main::xestiascan_presmodule->addtext(" | ");
	$main::xestiascan_presmodule->addlink($main::xestiascan_env{"script_filename"} . "?mode=settings", { Text => $main::xestiascan_lang{setting}->{returnsettingslist} });
	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->endform();

	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->endbox();
	
	return $main::xestiascan_presmodule->grab();

} 

sub xestiascan_output_config{
#################################################################################
# xestiascan_output_config: Outputs the configuration file.			#
#										#
# Usage:									#
#										#
# xestiascan_output_config(settings);						#
#										#
# settings	Specifies the following settings in any order.			#
#										#
# Settings for Xesita Scanner Server configuration files:			#
#										#
# ImagesURIPath		Specifies the new URI path for images.			#
# ScansURIPath		Specifies the new URI path for scans.			#
# ScansFSPath		Specifies the new filesystem path for scans.		#
# DateTimeFormat	Specifies the new date and time format.			#
# SystemLanguage	Specifies the new language to use for Xestia Scanner	#
#			Server.							#
# PrsentationModule	Specifies the new presentation module to use for	#
#			Xestia Scanner Server.					#
# OutputModule		Specifies the new output module to use for Xestia	#
#			Scanner Server.						#
# AuthModule		Specifies the new authentication module to use for	#
#			Xestia Scanner Server.					#
# DatabaseServer	Specifies the database server to use.			#
# DaravasePort		Specifies the port the database server is running on.	#
# DatabaseProtocol	Specifies the protocol the database server is using.	#
# DatabaseSQLDatabase	Specifies the SQL database name to use.			#
# DatabaseUsername	Specifies the database server username.			#
# DatabasePassword	Specifies the password for the database server username.#
# DatabaseTablePrefix	Specifies the table prefix to use.			#
#################################################################################

	# Get the variables passed from the subroutine.

	my ($passedsettings)	= @_;

	# Get the data from the hash.

	my $settings_imagesuri			= $passedsettings->{"ImagesURIPath"};
	my $settings_scansuri			= $passedsettings->{"ScansURIPath"};
	my $settings_scansfs			= $passedsettings->{"ScansFSPath"};
	my $settings_datetime			= $passedsettings->{"DateTimeFormat"};
	my $settings_systemlanguage		= $passedsettings->{"SystemLanguage"};
	my $settings_presmodule			= $passedsettings->{"PresentationModule"};
	my $settings_outputmodule		= $passedsettings->{"OutputModule"};
	my $settings_authmodule			= $passedsettings->{"AuthModule"};

	my $settings_database_server		= $passedsettings->{"DatabaseServer"};
	my $settings_database_port		= $passedsettings->{"DatabasePort"};
	my $settings_database_protocol		= $passedsettings->{"DatabaseProtocol"};
	my $settings_database_sqldatabase	= $passedsettings->{"DatabaseSQLDatabase"};
	my $settings_database_username		= $passedsettings->{"DatabaseUsername"};
	my $settings_database_password		= $passedsettings->{"DatabasePassword"};
	my $settings_database_tableprefix	= $passedsettings->{"DatabaseTablePrefix"};

	# Convert the password to make sure it can be read properly.

	if ($settings_database_password){

		$settings_database_password =~ s/\0//g;
		$settings_database_password =~ s/</&lt;/g;
		$settings_database_password =~ s/>/&gt;/g;

	}

	# Convert the less than and greater than characters are there and
	# convert them.

	if ($settings_imagesuri){

		$settings_imagesuri =~ s/</&lt;/g;
		$settings_imagesuri =~ s/>/&gt;/g;
		$settings_imagesuri =~ s/\r//g;
		$settings_imagesuri =~ s/\n//g;

	}

	if ($settings_scansuri){
		
		$settings_scansuri =~ s/</&lt;/g;
		$settings_scansuri =~ s/>/&gt;/g;
		$settings_scansuri =~ s/\r//g;
		$settings_scansuri =~ s/\n//g;
		
	}
	
	if ($settings_scansfs){
		
		$settings_scansfs =~ s/</&lt;/g;
		$settings_scansfs =~ s/>/&gt;/g;
		$settings_scansfs =~ s/\r//g;
		$settings_scansfs =~ s/\n//g;
		
	}

	# Check if the database password value is undefined and if it is then
	# set it blank.

	if (!$settings_database_password){

		$settings_database_password = "";

	}

	# Create the Xestia Scanner Server configuration file layout.

	my $configdata = "[config]\r\n";

	$configdata = $configdata . "directory_noncgi_images = "  . $settings_imagesuri . "\r\n";
	$configdata = $configdata . "directory_noncgi_scans = "  . $settings_scansuri . "\r\n";
	$configdata = $configdata . "directory_fs_scans = "  . $settings_scansfs . "\r\n\r\n";

	$configdata = $configdata . "system_language = "  . $settings_systemlanguage . "\r\n";
	$configdata = $configdata . "system_presmodule = "  . $settings_presmodule . "\r\n";
	$configdata = $configdata . "system_authmodule = "  . $settings_authmodule . "\r\n";
	$configdata = $configdata . "system_outputmodule = "  . $settings_outputmodule . "\r\n";
	$configdata = $configdata . "system_datetime = "  . $settings_datetime . "\r\n\r\n";

	$configdata = $configdata . "database_server = "  . $settings_database_server . "\r\n";
	$configdata = $configdata . "database_port = "  . $settings_database_port . "\r\n";
	$configdata = $configdata . "database_protocol = "  . $settings_database_protocol . "\r\n";
	$configdata = $configdata . "database_sqldatabase = "  . $settings_database_sqldatabase . "\r\n";
	$configdata = $configdata . "database_username = "  . $settings_database_username . "\r\n";
	$configdata = $configdata . "database_password = "  . $settings_database_password . "\r\n";
	$configdata = $configdata . "database_tableprefix = "  . $settings_database_tableprefix . "\r\n\r\n";

	# Open the Xestia Scanner Server configuration file, write the new 
	# settings to the configuration file and make sure the file
	# permissions are set to the correct value.

	open(my $filehandle_config, "> ", "xsdss.cfg");
	print $filehandle_config $configdata;
	close($filehandle_config);
	chmod(0660, "xsdss.cfg");
	
	return;

};

1;