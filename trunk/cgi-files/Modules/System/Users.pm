#################################################################################
# Xestia Scanner Server - Users System Module					#
# Version 0.1.0									#
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

package Modules::System::Users;

use Modules::System::Common;
use Modules::System::Scan;
use strict;
use warnings;
use Exporter;
use Sane;

our @ISA = qw(Exporter);
our @EXPORT = qw(xestiascan_users_list xestiascan_users_add xestiascan_users_edit xestiascan_users_delete xestiascan_users_flush);

sub xestiascan_users_list{
#################################################################################
# xestiascan_users_list: Get the list of available users.			#
#										#
# Usage:									#
#										#
# xestiascan_users_list(options);						#
#										#
# Specifies the following options as a hash (in any order).			#
#										#
# HideDeactivatedUsers	Hide deactivated users.					#
#################################################################################

	# Get the values that have been passed to the subroutine.

	my ($options) = @_;

	my $showdeactivated = 0;

	if ($options->{"ShowDeactivatedUsers"} && $options->{"ShowDeactivatedUsers"} eq 1){

		# Show deactivated users.

		$showdeactivated = 1;

	}

	# Connect to the database server.

	$main::xestiascan_authmodule->connect();

	# Check if any errors occured while connecting to the database server.

	if ($main::xestiascan_authmodule->geterror eq "AuthConnectionError"){

		# A database connection error has occured so return
		# an error.

		xestiascan_error("authconnectionerror", $main::xestiascan_authmodule->geterror(1));

	}

	# Get the permissions for the user and check if the user is allowed to access this.
	
	my $access_userlist = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "Admin" });

	xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
	xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
	xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
    
	if ($access_userlist ne 1){

		# User not allowed to access the user list so return an error.
		xestiascan_error("notpermitted");

	}

	my %user_list;
	my $user_name;
	my $cssstyle = 0;
	my $cssname = "";

	# Print the top menu.

	$main::xestiascan_presmodule->startbox("sectionboxnofloat");
	$main::xestiascan_presmodule->startbox("sectiontitle");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{listusers});
	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->startbox("secondbox");
	
	$main::xestiascan_presmodule->startform($main::xestiascan_env{"script_filename"}, "POST");
	$main::xestiascan_presmodule->addhiddendata("mode", "users");
	
	$main::xestiascan_presmodule->addbutton("action", { Value => "add", Description => $main::xestiascan_lang{users}{adduser} });
	$main::xestiascan_presmodule->addtext(" | ");
	$main::xestiascan_presmodule->addbutton("action", { Value => "flush", Description => $main::xestiascan_lang{users}{logoutallusers} });
	
	$main::xestiascan_presmodule->addlinebreak();
	
	$main::xestiascan_presmodule->addcheckbox("showdeactivated", { OptionDescription => $main::xestiascan_lang{users}{showdeactivated}, Checked => $showdeactivated });
	$main::xestiascan_presmodule->addtext(" | ");
	$main::xestiascan_presmodule->addsubmit($main::xestiascan_lang{users}{update});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->endform();

	# Get the list of users and return a message if the permissions system is
	# unsupported by this database server type.

	%user_list = $main::xestiascan_authmodule->getuserlist({ Reduced => 1, ShowDeactivated => $showdeactivated });

 	if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){

		# A database error has occured so return an error with
		# the extended error information.

		xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1));

	}

	$main::xestiascan_presmodule->starttable("", { CellPadding => "5", CellSpacing => "0" });
	$main::xestiascan_presmodule->startheader();
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{username}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{name}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{options}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->endheader();

	foreach $user_name (keys %user_list){

		$main::xestiascan_presmodule->startrow();

		if ($cssstyle eq 0){

			$cssname = "tablecell1";
			$cssstyle = 1;

		} else {

			$cssname = "tablecell2";
			$cssstyle = 0;

		}

		$cssname = "tablecelldisabled" if $user_list{$user_name}{deactivated} eq 1;

		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($user_list{$user_name}{username});
		$main::xestiascan_presmodule->endcell();
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($user_list{$user_name}{name});
		$main::xestiascan_presmodule->endcell();
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addlink($main::xestiascan_env{"script_filename"}  . "?mode=users&action=edit&user=" . $user_list{$user_name}{username}, { Text => $main::xestiascan_lang{options}{edit} });
		$main::xestiascan_presmodule->addlink($main::xestiascan_env{"script_filename"}  . "?mode=users&action=delete&user=" . $user_list{$user_name}{username}, { Text => $main::xestiascan_lang{options}{delete} });
		$main::xestiascan_presmodule->endcell();

		$main::xestiascan_presmodule->endrow();

	}

	$main::xestiascan_presmodule->endtable();

	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->endbox();
	
	# Disconnect from the database server.

	$main::xestiascan_authmodule->disconnect();

	return $main::xestiascan_presmodule->grab();

}

sub xestiascan_users_add{
#################################################################################
# xestiascan_users_add: Add a user to the user list.				#
#										#
# Usage:									#
#										#
# xestiascan_users_add(username, userinfo, scannerinfo, outputmoduleinfo,	#
#			exportmoduleinfo, confirm);				#
#										#
# username		Specifies the username to add to the user list.		#
# userinfo		Specifies the userinfo as a hashref.			#
# scannerinfo		Specifies the scanner permissions as a hashref.		#
# outputmoduleinfo	Specifies the output module permissions as a hashref.	#
# exportmoduleinfo	Specifies the export module permissions as a hashref.	#
# confirm		Confirms the action to add a user to the user list.	#
#################################################################################

	my $username	= shift;
	
	my $passed_userinfo		= shift;
	my $passed_scannerinfo		= shift;
	my $passed_outputmoduleinfo	= shift;
	my $passed_exportmoduleinfo	= shift;
	
	my $confirm = shift;
	
	$confirm = 0 if !$confirm;
	
	# Connect to the database server.

	$main::xestiascan_authmodule->connect();

	# Check if any errors occured while connecting to the database server.

	if ($main::xestiascan_authmodule->geterror eq "AuthConnectionError"){

		# A database connection error has occured so return
		# an error.

		xestiascan_error("authconnectionerror", $main::xestiascan_authmodule->geterror(1));

	}

	# Check to see if the user has permission to manage users.

	my $access_userlist = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "Admin" });

	xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
	xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
	xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
	
	if ($access_userlist ne 1){

		# User not allowed to access the user list so return an error.
		xestiascan_error("notpermitted");

	}

	# Check if there is a value in the username value and if there is then
	# assume a user is being added.

	if ($confirm eq 1){
		
		my %final_userinfo		= ();
		my %final_scannerinfo		= ();
		my %final_outputmoduleinfo	= ();
		my %final_exportmoduleinfo	= ();
		my $hashkey;
		my $hashkey_short;
		
		# De-reference the user information hash.
		
		$hashkey = "";
		
		foreach $hashkey (keys %$passed_userinfo){
			
			$final_userinfo{$hashkey} = $$passed_userinfo{$hashkey};
			
		}
		
		# De-reference the scanner information hash.
		
		$hashkey = "";
		$hashkey_short = "";
		
		foreach $hashkey (keys %$passed_scannerinfo){
			
			$hashkey_short = $hashkey;
			$hashkey_short =~ s/^scanner_//g;
			
			$final_scannerinfo{$hashkey_short} = $$passed_scannerinfo{$hashkey};
			
		}
		
		# De-reference the output module information hash.
		
		$hashkey = "";
		$hashkey_short = "";
		
		foreach $hashkey (keys %$passed_outputmoduleinfo){
			
			$hashkey_short = $hashkey;
			$hashkey_short =~ s/^outputmodule_//g;
			
			$final_outputmoduleinfo{$hashkey_short} = $$passed_outputmoduleinfo{$hashkey};
			
		}
		
		# De-reference the export module information hash.
		
		$hashkey = "";
		$hashkey_short = "";
		
		foreach $hashkey (keys %$passed_exportmoduleinfo){
			
			$hashkey_short = $hashkey;
			$hashkey_short =~ s/^exportmodule_//g;
			
			$final_exportmoduleinfo{$hashkey_short} = $$passed_exportmoduleinfo{$hashkey};
			
		}
		
		# Check if the username and password are blank and if they are
		# then return an error.
		
		if (!$username){
			
			xestiascan_error("usernameblank");
			
		}
		
		if (!$final_userinfo{Password}){
			
			xestiascan_error("passwordblank");
			
		}
		
		# Check if the password matches with the confirm password value
		# and return an error if this is not the case.
		
		if ($final_userinfo{Password} ne $final_userinfo{ConfirmPassword}){
		
			xestiascan_error("passwordsdonotmatch");
			
		}
		
		# Check all the values being passed to this subroutine are UTF-8
		# valid.
		
		xestiascan_variablecheck(xestiascan_utf8convert($username), "utf8", 0, 0);
		xestiascan_variablecheck(xestiascan_utf8convert($final_userinfo{Name}), "utf8", 0, 0);
		xestiascan_variablecheck(xestiascan_utf8convert($final_userinfo{Password}), "utf8", 0, 0);
		
		# Check the length of the username, name and password to make sure
		# they are valid.
		
		my $username_maxlength_check = xestiascan_variablecheck(xestiascan_utf8convert($username), "maxlength", 64, 1);
		my $name_maxlength_check = xestiascan_variablecheck(xestiascan_utf8convert($final_userinfo{Name}), "maxlength", 256, 1);
		my $password_maxlength_check = xestiascan_variablecheck(xestiascan_utf8convert($final_userinfo{Password}), "maxlength", 128, 1);
		
		if ($username_maxlength_check eq 1){
			
			# Username is too long so return an error.
			
			xestiascan_error("usernametoolong");
			
		}
		
		if ($name_maxlength_check eq 1){
			
			# Name is too long so return an error.
			
			xestiascan_error("nametoolong");
			
		}
		
		if ($password_maxlength_check eq 1){
			
			# Password is too long so return an error,
			
			xestiascan_error("passwordtoolong");
			
		}
		
		my $final_scanner;
		
		foreach $final_scanner (keys %final_scannerinfo){
		
			# Check to make sure that the scanner name and value
			# are both valid UTF8.
			
			xestiascan_variablecheck($final_scanner, "utf8", 0, 0);
			xestiascan_variablecheck($final_scannerinfo{$final_scanner}, "utf8", 0, 0);
			
		}
		
		# Check that the export and output modules contain valid UTF8
		# and are valid filenames.
		
		my $final_module;
		my $module_lettersnumbers_check;
		
		foreach $final_module (keys %final_outputmoduleinfo){
			
			xestiascan_variablecheck($final_module, "utf8", 0, 0);
			xestiascan_variablecheck($final_outputmoduleinfo{$final_module}, "utf8", 0, 0);
			
			$module_lettersnumbers_check = xestiascan_variablecheck($final_module, "lettersnumbers", 0, 1);
			xestiascan_error("moduleinvalid", xestiascan_language($main::xestiascan_lang{scan}{nameofoutputmoduleerror}, $final_module)) if $module_lettersnumbers_check eq 1;
			
		}
		
		$final_module = "";
		$module_lettersnumbers_check = 0;
		
		foreach $final_module (keys %final_exportmoduleinfo){
			
			xestiascan_variablecheck($final_module, "utf8", 0, 0);
			xestiascan_variablecheck($final_exportmoduleinfo{$final_module}, "utf8", 0, 0);
			
			$module_lettersnumbers_check = xestiascan_variablecheck($final_module, "lettersnumbers", 0, 1);
			xestiascan_error("moduleinvalid", xestiascan_language($main::xestiascan_lang{scan}{nameofexportmoduleerror}, $final_module)) if $module_lettersnumbers_check eq 1;
			
		}
		
		# Add the user via adduser and pass the permissions to the 
		# edituser subroutine for the authentication module.
		
		$main::xestiascan_authmodule->adduser($username, %final_userinfo);

		if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
		
			xestiascan_error("userediterror", $main::xestiascan_authmodule->geterror(1));
			
		}
		
		if ($main::xestiascan_authmodule->geterror eq "UserExists"){
			
			xestiascan_error("userexists");
			
		}
		
		$main::xestiascan_authmodule->edituser($username, "Scanner", %final_scannerinfo);

		if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
			
			xestiascan_error("userediterror", $main::xestiascan_authmodule->geterror(1));
			
		}
		
		$main::xestiascan_authmodule->edituser($username, "OutputModule", %final_outputmoduleinfo);

		if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
			
			xestiascan_error("userediterror", $main::xestiascan_authmodule->geterror(1));
			
		}
		
		$main::xestiascan_authmodule->edituser($username, "ExportModule", %final_exportmoduleinfo);
		
		if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
			
			xestiascan_error("userediterror", $main::xestiascan_authmodule->geterror(1));
			
		}
		
		# Disconnect from the database server.

		$main::xestiascan_authmodule->disconnect();

 		if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){

			# A database error has occured so return an error with
			# the extended error information.

			xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1));

		}	

		# Write a message saying that the user has been added.

		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{useradded}, { Style => "pageheader" });
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addtext(xestiascan_language($main::xestiascan_lang{users}{useraddedtolist}, xestiascan_utf8convert($username)));
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlink($main::xestiascan_env{"script_filename"} . "?mode=users", { Text => $main::xestiascan_lang{users}{returnuserlist} });
		
		
		return $main::xestiascan_presmodule->grab();

	}

	# Disconnect from the database server.

	$main::xestiascan_authmodule->disconnect();

	# As there is no username value, print a form for adding a user.

	# Get the list of available scanners.
	
	my %scannerlist;
	my $scanner;
	
	tie(%scannerlist, 'Tie::IxHash');
	
	foreach $scanner (Sane->get_devices){
		$scannerlist{$scanner->{'name'}}{name}		= $scanner->{'name'};
		$scannerlist{$scanner->{'name'}}{model}		= $scanner->{'model'};
		$scannerlist{$scanner->{'name'}}{vendor}	= $scanner->{'vendor'};
	}
	
	# Get the list of available output modules.
	
	my @availableoutputmodules;
	@availableoutputmodules = xestiascan_scan_getoutputmodules;
	
	# Get the list of available export modules.
	
	my @availableexportmodules;
	@availableexportmodules = xestiascan_scan_getexportmodules;
	
	# Print out the form for editing the user.	
	
	$main::xestiascan_presmodule->startbox("sectionboxnofloat");
	$main::xestiascan_presmodule->startbox("sectiontitle");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{adduser});
	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->startbox("secondbox");	
	
	$main::xestiascan_presmodule->startform($main::xestiascan_env{"script_filename"}, "POST");
	$main::xestiascan_presmodule->addhiddendata("mode", "users");
	$main::xestiascan_presmodule->addhiddendata("action", "add");
	$main::xestiascan_presmodule->addhiddendata("confirm", "1");

	# Process the user information.
	
	$main::xestiascan_presmodule->addboldtext($main::xestiascan_lang{users}{userdetails});
	
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();	
	
	$main::xestiascan_presmodule->starttable("", { CellPadding => "5", CellSpacing => "0" });
	$main::xestiascan_presmodule->startheader();
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{common}{setting}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{common}{value}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->endheader();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{username});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addinputbox("username", { MaxLength => "64", Size => "32"});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{name});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("name", { MaxLength => "128", Size => "32" });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{adminprivs});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addcheckbox("admin");
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{accountenabled});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addcheckbox("enabled");
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{password});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addinputbox("password", { MaxLength => "256", Size => "32", Password => 1 });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{confirmpassword});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("confirmpassword", { MaxLength => "256", Size => "32", Password => 1 });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();	
	
	$main::xestiascan_presmodule->endtable();
	
	
	$main::xestiascan_presmodule->addlinebreak();	
	
	# Process the list of available scanners.
	
	$main::xestiascan_presmodule->addboldtext($main::xestiascan_lang{users}{scannerlist});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	
	$main::xestiascan_presmodule->starttable("", { CellPadding => "5", CellSpacing => "0" });
	$main::xestiascan_presmodule->startheader();
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{scannername}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{allowaccess}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->endheader();
	
	my $scannername;
	my $cssname = "";
	my $cssstyle = 0;
	my @connectedscanners;
	
	# Process the list of connected scanners.
	
	foreach $scannername (keys %scannerlist){
		
		$main::xestiascan_presmodule->startrow();
		
		# Setup the styling for the row.
		
		if ($cssstyle eq 0){
			
			$cssname = "tablecell1";
			$cssstyle = 1;
			
		} else {
			
			$cssname = "tablecell2";
			$cssstyle = 0;
			
		}
		
		# Add the name of the scanner.
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addboldtext($scannerlist{$scannername}{vendor} . " " . $scannerlist{$scannername}{model});
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->additalictext($scannerlist{$scannername}{name});
		$main::xestiascan_presmodule->endcell();
		
		# See if it has permissions (or not) to use the scanner.
		
		$main::xestiascan_presmodule->addcell($cssname);
			
		$main::xestiascan_presmodule->addcheckbox("scanner_" . $scannerlist{$scannername}{name}, { Checked => 0 });
		
		$main::xestiascan_presmodule->endcell();
		
		push(@connectedscanners, $scannername);
		
		$main::xestiascan_presmodule->endrow();
		
	}
	
	$main::xestiascan_presmodule->endtable();
	
	$main::xestiascan_presmodule->addlinebreak();
	
	$main::xestiascan_presmodule->addboldtext($main::xestiascan_lang{users}{outputmodulelist});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();	
	
	$main::xestiascan_presmodule->starttable("", { CellPadding => "5", CellSpacing => "0" });
	$main::xestiascan_presmodule->startheader();
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{modulename}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{allowaccess}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->endheader();
	
	my $outputmodulename;
	my $outputmoduleavailable = 0;
	my $outputmoduleavailname;
	$cssstyle = 0;
	
	# Process the list of available user output modules.
	
	foreach $outputmodulename (@availableoutputmodules){
		
		# Check if the module is in the list of available
		# output modules, otherwise mark as not available.
		
		# Setup the styling for the row.
		
		if ($cssstyle eq 0){
			
			$cssname = "tablecell1";
			$cssstyle = 1;
			
		} else {
			
			$cssname = "tablecell2";
			$cssstyle = 0;
			
		}
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($outputmodulename);
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->addcell($cssname);
			
		$main::xestiascan_presmodule->addcheckbox("outputmodule_" . $outputmodulename, { Checked => 0 });
		
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->endrow();
		
	}
	
	$main::xestiascan_presmodule->endtable();
	
	$main::xestiascan_presmodule->addlinebreak();
	
	$main::xestiascan_presmodule->addboldtext($main::xestiascan_lang{users}{exportmodulelist});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	
	$main::xestiascan_presmodule->starttable("", { CellPadding => "5", CellSpacing => "0" });
	$main::xestiascan_presmodule->startheader();
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{modulename}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{allowaccess}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->endheader();
	
	my $exportmodulename;
	my $exportmoduleavailable = 0;
	my $exportmoduleavailname;
	$cssstyle = 0;
	
	# Process the list of available user export modules.
	
	foreach $exportmodulename (@availableexportmodules){
		
		# Setup the styling for the row.
		
		if ($cssstyle eq 0){
			
			$cssname = "tablecell1";
			$cssstyle = 1;
			
		} else {
			
			$cssname = "tablecell2";
			$cssstyle = 0;
			
		}
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($exportmodulename);
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->addcell($cssname);
			
		$main::xestiascan_presmodule->addcheckbox("exportmodule_" . $exportmodulename, { Checked => 0 });
		
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->endrow();
		
	}
	
	$main::xestiascan_presmodule->endtable();
	
	$main::xestiascan_presmodule->addlinebreak();

	$main::xestiascan_presmodule->addsubmit($main::xestiascan_lang{users}{adduserbutton});
	$main::xestiascan_presmodule->addtext(" | ");
	$main::xestiascan_presmodule->addreset($main::xestiascan_lang{common}{clearvalues});

	$main::xestiascan_presmodule->endform();
	
	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->endbox();

	return $main::xestiascan_presmodule->grab();

}

sub xestiascan_users_edit{
#################################################################################
# xestiascan_users_edit: Edit a user in the user list.				#
#										#
# Usage:									#
#										#
# xestiascan_users_edit(username, userinfo, scannerinfo, outputmoduleinfo,	#
#			exportmoduleinfo, confirm);				#
#										#
# username		Specifies the username to edit.				#
# userinfo		Specifies the user information as a hash.		#
# scannerinfo		Specifies the scanner information as a hash.		#
# outputmoduleinfo	Specifies the output module information as a hash.	#
# exportmoduleinfo	Specifies the export module information as a hash.	#
# confirm		Specifies if the action to edit has been confirmed.	#
#################################################################################
	
	my $username	= shift;
	
	my $passed_userinfo		= shift;
	my $passed_scannerinfo		= shift;
	my $passed_outputmoduleinfo	= shift;
	my $passed_exportmoduleinfo	= shift;
	
	my $confirm = shift;
	
	if (!$username){
	
		# Username is blank so return an error.
		
		xestiascan_error("usernameblank");
		
	}
	
	if (!$confirm){
	
		$confirm = 0;
		
	}
	
	# Check to see if the username is valid.
	
	xestiascan_variablecheck(xestiascan_utf8convert($username), "utf8", 0, 0);
	
	my $username_maxlength_check = xestiascan_variablecheck(xestiascan_utf8convert($username), "maxlength", 64, 1);
	
	if ($username_maxlength_check eq 1){
		
		# Username is too long so return an error.
		
		xestiascan_error("usernametoolong");
		
	}	
	
	# Connect to the database server.
	
	$main::xestiascan_authmodule->connect();

	# Check if any errors occured while connecting to the database server.
	
	if ($main::xestiascan_authmodule->geterror eq "AuthConnectionError"){
		
		# A database connection error has occured so return
		# an error.
		
		xestiascan_error("authconnectionerror", $main::xestiascan_authmodule->geterror(1));
		
	}
	
	# Check to see if the user has permission to manage users.
	
	my $access_userlist = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "Admin" });
	
	xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
	xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
	xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
	
	if ($access_userlist ne 1){
		
		# User not allowed to access the user list so return an error.
		xestiascan_error("notpermitted");
		
	}	
	

	# Check to see if the action to edit the user has been confirmed and
	# if it has then edit the user.
	
	if ($confirm eq 1){
		
		my %final_userinfo		= ();
		my %final_scannerinfo		= ();
		my %final_outputmoduleinfo	= ();
		my %final_exportmoduleinfo	= ();
		my $hashkey;
		my $hashkey_short;
		
		# De-reference the user information hash.
		
		$hashkey = "";
		
		foreach $hashkey (keys %$passed_userinfo){
		
			$final_userinfo{$hashkey} = $$passed_userinfo{$hashkey};
			
		}
		
		# De-reference the scanner information hash.
		
		$hashkey = "";
		$hashkey_short = "";

		foreach $hashkey (keys %$passed_scannerinfo){
			
			$hashkey_short = $hashkey;
			$hashkey_short =~ s/^scanner_//g;
			
			$final_scannerinfo{$hashkey_short} = $$passed_scannerinfo{$hashkey};
			
		}
		
		# De-reference the output module information hash.
		
		$hashkey = "";
		$hashkey_short = "";
		
		foreach $hashkey (keys %$passed_outputmoduleinfo){

			$hashkey_short = $hashkey;
			$hashkey_short =~ s/^outputmodule_//g;
			
			$final_outputmoduleinfo{$hashkey_short} = $$passed_outputmoduleinfo{$hashkey};
			
		}
		
		# De-reference the export module information hash.
		
		$hashkey = "";
		$hashkey_short = "";
		
		foreach $hashkey (keys %$passed_exportmoduleinfo){
			
			$hashkey_short = $hashkey;
			$hashkey_short =~ s/^exportmodule_//g;
			
			$final_exportmoduleinfo{$hashkey_short} = $$passed_exportmoduleinfo{$hashkey};
			
		}		
		
		# Check if the username and password are blank and if they are
		# then return an error.
		
		if (!$username){
			
			xestiascan_error("usernameblank");
			
		}
		
		# Check if the password matches with the confirm password value
		# and return an error if this is not the case.
		
		if ($final_userinfo{Password} ne $final_userinfo{ConfirmPassword}){
			
			xestiascan_error("passwordsdonotmatch");
			
		}
		
		# Check all the values being passed to this subroutine are UTF-8
		# valid.
		
		xestiascan_variablecheck(xestiascan_utf8convert($username), "utf8", 0, 0);
		xestiascan_variablecheck(xestiascan_utf8convert($final_userinfo{NewUsername}), "utf8", 0, 0);
		xestiascan_variablecheck(xestiascan_utf8convert($final_userinfo{Name}), "utf8", 0, 0);
		xestiascan_variablecheck(xestiascan_utf8convert($final_userinfo{Password}), "utf8", 0, 0);
		
		# Check the length of the username, name and password to make sure
		# they are valid.
		
		my $username_maxlength_check = xestiascan_variablecheck(xestiascan_utf8convert($username), "maxlength", 64, 1);
		my $newusername_maxlength_check = xestiascan_variablecheck(xestiascan_utf8convert($final_userinfo{NewUsername}), "maxlength", 32, 1);
		my $name_maxlength_check = xestiascan_variablecheck(xestiascan_utf8convert($final_userinfo{Name}), "maxlength", 256, 1);
		my $password_maxlength_check = xestiascan_variablecheck(xestiascan_utf8convert($final_userinfo{Password}), "maxlength", 128, 1);
		
		if ($username_maxlength_check eq 1){
			
			# Username is too long so return an error.
			
			xestiascan_error("usernametoolong");
			
		}
		
		if ($name_maxlength_check eq 1){
			
			# Name is too long so return an error.
			
			xestiascan_error("nametoolong");
			
		}
		
		if ($password_maxlength_check eq 1){
			
			# Password is too long so return an error,
			
			xestiascan_error("passwordtoolong");
			
		}
		
		my $final_scanner;
		
		foreach $final_scanner (keys %final_scannerinfo){
			
			# Check to make sure that the scanner name and value
			# are both valid UTF8.
			
			xestiascan_variablecheck($final_scanner, "utf8", 0, 0);
			xestiascan_variablecheck($final_scannerinfo{$final_scanner}, "utf8", 0, 0);
			
		}
		
		# Check that the export and output modules contain valid UTF8
		# and are valid filenames.
		
		my $final_module;
		my $module_lettersnumbers_check;
		
		foreach $final_module (keys %final_outputmoduleinfo){
			
			xestiascan_variablecheck($final_module, "utf8", 0, 0);
			xestiascan_variablecheck($final_outputmoduleinfo{$final_module}, "utf8", 0, 0);
			
			$module_lettersnumbers_check = xestiascan_variablecheck($final_module, "lettersnumbers", 0, 1);
			xestiascan_error("moduleinvalid", xestiascan_language($main::xestiascan_lang{scan}{nameofoutputmoduleerror}, $final_module)) if $module_lettersnumbers_check eq 1;
			
		}
		
		$final_module = "";
		$module_lettersnumbers_check = 0;
		
		foreach $final_module (keys %final_exportmoduleinfo){
			
			xestiascan_variablecheck($final_module, "utf8", 0, 0);
			xestiascan_variablecheck($final_exportmoduleinfo{$final_module}, "utf8", 0, 0);
			
			$module_lettersnumbers_check = xestiascan_variablecheck($final_module, "lettersnumbers", 0, 1);
			xestiascan_error("moduleinvalid", xestiascan_language($main::xestiascan_lang{scan}{nameofexportmoduleerror}, $final_module)) if $module_lettersnumbers_check eq 1;
			
		}
		
		# Get the list of available scanners.
		
		my %scannerlist;
		my $scanner;
		
		tie(%scannerlist, 'Tie::IxHash');
		
		foreach $scanner (Sane->get_devices){
			$scannerlist{$scanner->{'name'}}{name}		= $scanner->{'name'};
			$scannerlist{$scanner->{'name'}}{model}		= $scanner->{'model'};
			$scannerlist{$scanner->{'name'}}{vendor}	= $scanner->{'vendor'};
		}
		
		# Get the list of available output modules.
		
		my @availableoutputmodules;
		@availableoutputmodules = xestiascan_scan_getoutputmodules;
		
		# Get the list of available export modules.
		
		my @availableexportmodules;
		@availableexportmodules = xestiascan_scan_getexportmodules;
		
		# Pass the permissions to the edituser subroutine
		# for the authentication module.
		
		$main::xestiascan_authmodule->edituser($username, "User", %final_userinfo);

		if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
			
			xestiascan_error("userediterror", $main::xestiascan_authmodule->geterror(1));
			
		}
		
		$main::xestiascan_authmodule->edituser($username, "Scanner", %final_scannerinfo);

		if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
			
			xestiascan_error("userediterror", $main::xestiascan_authmodule->geterror(1));
			
		}
		
		$main::xestiascan_authmodule->edituser($username, "OutputModule", %final_outputmoduleinfo);

		if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
			
			xestiascan_error("userediterror", $main::xestiascan_authmodule->geterror(1));
			
		}
		
		$main::xestiascan_authmodule->edituser($username, "ExportModule", %final_exportmoduleinfo);
		
		if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
			
			xestiascan_error("userediterror", $main::xestiascan_authmodule->geterror(1));
			
		}
		
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{useredited}, { Style => "pageheader" });
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addtext(xestiascan_language($main::xestiascan_lang{users}{usereditedsuccess}, xestiascan_utf8convert($username)))	;
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlink($main::xestiascan_env{"script_filename"} . "?mode=users", { Text => $main::xestiascan_lang{users}{returnuserlist} });
		
		return $main::xestiascan_presmodule->grab();
		
	}
	
	
	# Get the general information about the user.
	
	my %userinfo;
	
	%userinfo = $main::xestiascan_authmodule->getpermissions({ Username => xestiascan_utf8convert($username), PermissionType => "UserInfo" });

	xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
	xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
	xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
	
	# Get the list of scanners with permissions for the user.
	
	my %userscannerinfo;
	
	%userscannerinfo = $main::xestiascan_authmodule->getpermissions({ Username => xestiascan_utf8convert($username), PermissionType => "Scanner" });

	xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
	xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
	xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
	
	# Get the list of output modules with permissions for the user.
	
	my %useroutputinfo;

	%useroutputinfo = $main::xestiascan_authmodule->getpermissions({ Username => xestiascan_utf8convert($username), PermissionType => "OutputModule" });

	xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
	xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
	xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
	
	# Get the list of export modules with permissions for the user.
	
	my %userexportinfo;
	
	%userexportinfo = $main::xestiascan_authmodule->getpermissions({ Username => xestiascan_utf8convert($username), PermissionType => "ExportModule" });

	xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
	xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
	xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
	
	# Get the list of available scanners.
	
	my %scannerlist;
	my $scanner;
	
	tie(%scannerlist, 'Tie::IxHash');
	
	foreach $scanner (Sane->get_devices){
		$scannerlist{$scanner->{'name'}}{name}		= $scanner->{'name'};
		$scannerlist{$scanner->{'name'}}{model}		= $scanner->{'model'};
		$scannerlist{$scanner->{'name'}}{vendor}	= $scanner->{'vendor'};
	}
	
	# Get the list of available output modules.
	
	my @availableoutputmodules;
	@availableoutputmodules = xestiascan_scan_getoutputmodules;
	
	# Get the list of available export modules.
	
	my @availableexportmodules;
	@availableexportmodules = xestiascan_scan_getexportmodules;
	
	# Print out the form for editing the user.	
	
	$main::xestiascan_presmodule->startbox("sectionboxnofloat");
	$main::xestiascan_presmodule->startbox("sectiontitle");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{edituser});
	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->startbox("secondbox");	

	$main::xestiascan_presmodule->startform($main::xestiascan_env{"script_filename"}, "POST");
	$main::xestiascan_presmodule->addhiddendata("mode", "users");
	$main::xestiascan_presmodule->addhiddendata("action", "edit");
	$main::xestiascan_presmodule->addhiddendata("confirm", "1");
	$main::xestiascan_presmodule->addhiddendata("username_original", xestiascan_utf8convert($username));
	
	# Process the user information.
	
	$main::xestiascan_presmodule->addboldtext($main::xestiascan_lang{users}{userdetails});

	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();	
	
	$main::xestiascan_presmodule->starttable("", { CellPadding => "5", CellSpacing => "0" });
	$main::xestiascan_presmodule->startheader();
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{common}{setting}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{common}{value}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->endheader();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{username});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addinputbox("username", { MaxLength => "64", Size => "32", Value => $userinfo{Username} });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{name});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("name", { MaxLength => "128", Size => "32", Value => $userinfo{Name} });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{adminprivs});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addcheckbox("admin", { Checked => $userinfo{Admin} });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{accountenabled});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addcheckbox("enabled", { Checked => $userinfo{Enabled} });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{newpassword});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addinputbox("password", { MaxLength => "256", Size => "32", Password => 1 });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{confirmnewpassword});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("confirmpassword", { MaxLength => "256", Size => "32", Password => 1 });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();	
	
	$main::xestiascan_presmodule->endtable();
	
	
	$main::xestiascan_presmodule->addlinebreak();	
	
	# Process the list of available scanners.
	
	$main::xestiascan_presmodule->addboldtext($main::xestiascan_lang{users}{scannerlist});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	
	$main::xestiascan_presmodule->starttable("", { CellPadding => "5", CellSpacing => "0" });
	$main::xestiascan_presmodule->startheader();
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{scannername}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{allowaccess}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{connected}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->endheader();
	
	my $scannername;
	my $cssname = "";
	my $cssstyle = 0;
	my @connectedscanners;
	
	# Process the list of connected scanners.
	
	foreach $scannername (keys %scannerlist){
	
		$main::xestiascan_presmodule->startrow();

		# Setup the styling for the row.
		
		if ($cssstyle eq 0){
			
			$cssname = "tablecell1";
			$cssstyle = 1;
			
		} else {
			
			$cssname = "tablecell2";
			$cssstyle = 0;
			
		}
		
		# Add the name of the scanner.
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addboldtext($scannerlist{$scannername}{vendor} . " " . $scannerlist{$scannername}{model});
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->additalictext($scannerlist{$scannername}{name});
		$main::xestiascan_presmodule->endcell();
		
		# See if it has permissions (or not) to use the scanner.
		
		$main::xestiascan_presmodule->addcell($cssname);
		
		if ($userscannerinfo{$scannername}){
		
			if ($userscannerinfo{$scannername} eq 1){
		
				$main::xestiascan_presmodule->addcheckbox("scanner_" . $scannerlist{$scannername}{name}, { Checked => 1 });
			
			} else {
			
				$main::xestiascan_presmodule->addcheckbox("scanner_" . $scannerlist{$scannername}{name}, { Checked => 0 });
				
			}
		
		} else {
		
			$main::xestiascan_presmodule->addcheckbox("scanner_" . $scannerlist{$scannername}{name}, { Checked => 0 });
			
		}
		
		$main::xestiascan_presmodule->endcell();
			
		# As we are dealing with the connected scanners first,
		# Write 'Yes' for connected.
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{devconnected});
		$main::xestiascan_presmodule->endcell();		
		
		push(@connectedscanners, $scannername);
		
		$main::xestiascan_presmodule->endrow();
		
	}
	
	# Process the list of disconnected scanners.
	
	$scannername = "";
	my $duplicatescannername;
	my $duplicatescannerfound = 0;
	
	foreach $scannername (keys %userscannerinfo){
	
		# Check the list of connected scanners and skip
		# this bit if the scanner name matches this list.
		
		$duplicatescannerfound = 0;
		
		foreach $duplicatescannername (@connectedscanners){
		
			if ($duplicatescannername eq $scannername){
			
				$duplicatescannerfound = 1;
				
			}
			
		}
		
		next if $duplicatescannerfound eq 1;

		# Setup the styling for the row.
		
		if ($cssstyle eq 0){
			
			$cssname = "tablecell1";
			$cssstyle = 1;
			
		} else {
			
			$cssname = "tablecell2";
			$cssstyle = 0;
			
		}
		
		# Add the name of the scanner.
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addboldtext($scannerlist{$scannername}{vendor} . " " . $scannerlist{$scannername}{model});
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->additalictext($scannerlist{$scannername}{name});
		$main::xestiascan_presmodule->endcell();
		
		# See if it has permissions (or not) to use the scanner.
		
		$main::xestiascan_presmodule->addcell($cssname);
		
		if ($userscannerinfo{$scannername}){
			
			if ($userscannerinfo{$scannername} eq 1){
				
				$main::xestiascan_presmodule->addcheckbox("scanner_" . $scannerlist{$scannername}{name}, { Checked => 1 });
				
			} else {
				
				$main::xestiascan_presmodule->addcheckbox("scanner_" . $scannerlist{$scannername}{name}, { Checked => 0 });
				
			}
			
		} else {
			
			$main::xestiascan_presmodule->addcheckbox("scanner_" . $scannerlist{$scannername}{name}, { Checked => 0 });
			
		}
		
		$main::xestiascan_presmodule->endcell();
		
		# As we are dealing with the connected scanners first,
		# Write 'Yes' for connected.
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{devdisconnected});
		$main::xestiascan_presmodule->endcell();		
		
		$main::xestiascan_presmodule->endrow();
		
	}
	
	$main::xestiascan_presmodule->endtable();
	
	$main::xestiascan_presmodule->addlinebreak();
	
	$main::xestiascan_presmodule->addboldtext($main::xestiascan_lang{users}{outputmodulelist});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();	
	
	$main::xestiascan_presmodule->starttable("", { CellPadding => "5", CellSpacing => "0" });
	$main::xestiascan_presmodule->startheader();
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{modulename}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{allowaccess}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{available}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->endheader();
	
	my $outputmodulename;
	my $outputmoduleavailable = 0;
	my $outputmoduleavailname;
	$cssstyle = 0;
	
	# Process the list of available user output modules.
	
	foreach $outputmodulename (@availableoutputmodules){
	
		# Check if the module is in the list of available
		# output modules, otherwise mark as not available.

		# Setup the styling for the row.
		
		if ($cssstyle eq 0){
			
			$cssname = "tablecell1";
			$cssstyle = 1;
			
		} else {
			
			$cssname = "tablecell2";
			$cssstyle = 0;
			
		}
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($outputmodulename);
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->addcell($cssname);
		
		if ($useroutputinfo{$outputmodulename}){
			
			if ($useroutputinfo{$outputmodulename} eq 1){
			
				$main::xestiascan_presmodule->addcheckbox("outputmodule_" . $outputmodulename, { Checked => 1 });
				
			} else {

				$main::xestiascan_presmodule->addcheckbox("outputmodule_" . $outputmodulename, { Checked => 0 });
				
			}
					
		} else {
		
			$main::xestiascan_presmodule->addcheckbox("outputmodule_" . $outputmodulename, { Checked => 0 });
			
		}
		
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{modavailable});
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->endrow();
		
	}
	
	# Process the list of not available output modules.
	
	$outputmodulename = "";
	my $duplicateoutputmodulename = "";
	my $duplicateoutputmodulefound = 0;
	
	foreach $outputmodulename (keys %useroutputinfo){
	
		# Check the list of available output modules and skip
		# this bit if the output module name matches this list.
		
		$duplicateoutputmodulefound = 0;
		
		foreach $duplicateoutputmodulename (@availableoutputmodules){
			
			if ($duplicateoutputmodulename eq $outputmodulename){
				
				$duplicateoutputmodulefound = 1;
				
			}
			
		}
		
		next if $duplicateoutputmodulefound eq 1;		

		# Setup the styling for the row.
		
		if ($cssstyle eq 0){
			
			$cssname = "tablecell1";
			$cssstyle = 1;
			
		} else {
			
			$cssname = "tablecell2";
			$cssstyle = 0;
			
		}
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($outputmodulename);
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->addcell($cssname);
		
		if ($useroutputinfo{$outputmodulename}){
			
			if ($useroutputinfo{$outputmodulename} eq 1){
				
				$main::xestiascan_presmodule->addcheckbox("outputmodule_" . $outputmodulename, { Checked => 1 });
				
			} else {
				
				$main::xestiascan_presmodule->addcheckbox("outputmodule_" . $outputmodulename, { Checked => 0 });
				
			}
			
		} else {
			
			$main::xestiascan_presmodule->addcheckbox("outputmodule_" . $outputmodulename, { Checked => 0 });
			
		}
		
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{modunavailable});
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->endrow();
		
	}
	
	$main::xestiascan_presmodule->endtable();

	$main::xestiascan_presmodule->addlinebreak();
	
	$main::xestiascan_presmodule->addboldtext($main::xestiascan_lang{users}{exportmodulelist});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();

	$main::xestiascan_presmodule->starttable("", { CellPadding => "5", CellSpacing => "0" });
	$main::xestiascan_presmodule->startheader();
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{modulename}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{allowaccess}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->addheader($main::xestiascan_lang{users}{available}, { Style => "tablecellheader" });
	$main::xestiascan_presmodule->endheader();
	
	my $exportmodulename;
	my $exportmoduleavailable = 0;
	my $exportmoduleavailname;
	$cssstyle = 0;

	# Process the list of available user export modules.
	
	foreach $exportmodulename (@availableexportmodules){
		
		# Setup the styling for the row.
		
		if ($cssstyle eq 0){
			
			$cssname = "tablecell1";
			$cssstyle = 1;
			
		} else {
			
			$cssname = "tablecell2";
			$cssstyle = 0;
			
		}
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($exportmodulename);
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->addcell($cssname);
		
		if ($userexportinfo{$exportmodulename}){
			
			if ($userexportinfo{$exportmodulename} eq 1){
				
				$main::xestiascan_presmodule->addcheckbox("exportmodule_" . $exportmodulename, { Checked => 1 });
				
			} else {
				
				$main::xestiascan_presmodule->addcheckbox("exportmodule_" . $exportmodulename, { Checked => 0 });
				
			}
			
		} else {
			
			$main::xestiascan_presmodule->addcheckbox("exportmodule_" . $exportmodulename, { Checked => 0 });
			
		}
		
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{modavailable});
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->endrow();
		
	}

	# Process the list of not available user export modules.
	
	$exportmodulename = "";
	my $duplicateexportmodulename = "";
	my $duplicateexportmodulefound = 0;
	
	foreach $exportmodulename (keys %userexportinfo){
		
		# Check the list of available output modules and skip
		# this bit if the output module name matches this list.
		
		$duplicateexportmodulefound = 0;
		
		foreach $duplicateexportmodulename (@availableexportmodules){
			
			if ($duplicateexportmodulename eq $exportmodulename){
				
				$duplicateexportmodulefound = 1;
				
			}
			
		}
		
		next if $duplicateexportmodulefound eq 1;		
		
		# Setup the styling for the row.
		
		if ($cssstyle eq 0){
			
			$cssname = "tablecell1";
			$cssstyle = 1;
			
		} else {
			
			$cssname = "tablecell2";
			$cssstyle = 0;
			
		}
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($exportmodulename);
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->addcell($cssname);
		
		if ($userexportinfo{$outputmodulename}){
			
			if ($userexportinfo{$outputmodulename} eq 1){
				
				$main::xestiascan_presmodule->addcheckbox("exportmodule_" . $exportmodulename, { Checked => 1 });
				
			} else {
				
				$main::xestiascan_presmodule->addcheckbox("exportmodule_" . $exportmodulename, { Checked => 0 });
				
			}
			
		} else {
			
			$main::xestiascan_presmodule->addcheckbox("exportmodule_" . $exportmodulename, { Checked => 0 });
			
		}
		
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->addcell($cssname);
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{modunavailable});
		$main::xestiascan_presmodule->endcell();
		
		$main::xestiascan_presmodule->endrow();
		
	}	
	
	$main::xestiascan_presmodule->endtable();
	
	$main::xestiascan_presmodule->addlinebreak();
	
	# User Information table.
		
	$main::xestiascan_presmodule->addsubmit($main::xestiascan_lang{users}{edituserbutton});
	$main::xestiascan_presmodule->addtext(" | ");
	$main::xestiascan_presmodule->addreset($main::xestiascan_lang{common}{clearvalues});
	
	$main::xestiascan_presmodule->endform();	

	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->endbox();
	
	return $main::xestiascan_presmodule->grab();
	
}

sub xestiascan_users_delete{
#################################################################################
# xestiascan_users_delete: Delete a user in the user list.			#
#										#
# Usage:									#
#										#
# xestiascan_users_delete(username, confirm);					#
#										#
# username	Specifies the user to delete.					#
# confirm	Confirms if the user should be deleted.				#
#################################################################################
	
	my $username = shift;
	my $confirm = shift;
	
	if (!$confirm){
	
		$confirm = 0;
		
	}

	if (!$username){
		
		# The username is blank so return an error.
		
		xestiascan_error("usernameblank");
		
	}
	
	# Connect to the database server.
	
	$main::xestiascan_authmodule->connect();
	
	# Check if any errors occured while connecting to the database server.
	
	if ($main::xestiascan_authmodule->geterror eq "AuthConnectionError"){
		
		# A database connection error has occured so return
		# an error.
		
		xestiascan_error("authconnectionerror", $main::xestiascan_authmodule->geterror(1));
		
	}
	
	# Check to see if the user has permission to manage users.
	
	my $access_userlist = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "Admin" });
	
 	if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
		
		# A database error has occured so return an error with
		# the extended error information.
		
		xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1));
		
	}
	
	if ($access_userlist ne 1){
		
		# User not allowed to access the user list so return an error.
		xestiascan_error("notpermitted");
		
	}
	
	# Check the user name to see if it is valid.
	
	xestiascan_variablecheck($username, "utf8", 0, 0);
	
	my $username_maxlength_check = xestiascan_variablecheck(xestiascan_utf8convert($username), "maxlength", 32, 1);
	
	if ($username_maxlength_check eq 1){
		
		# Username is too long so return an error.
		
		xestiascan_error("usernametoolong");
		
	}
	
	# Check to see if the user exists.
	
	$main::xestiascan_authmodule->getpermissions({ Username => $username, PermissionType => "Enabled" });
	
	if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
		
		# A database error has occured so return an error with
		# the extended error information.
		
		xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1));
		
	}
	

	
	if ($main::xestiascan_authmodule->geterror eq "UserDoesNotExist"){
		
		xestiascan_error("usernameinvalid");
		
	}
	
	if ($confirm eq 1){
	
		# The action to delete the user has been confirmed.
		
		$main::xestiascan_authmodule->deleteuser($username);
		
		if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
			
			# A database error has occured so return an error with
			# the extended error information.
			
			xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1));
			
		}
		
		if ($main::xestiascan_authmodule->geterror eq "UserDoesNotExist"){
			
			xestiascan_error("usernameinvalid");
			
		}
		
		# Disconnect from the database server.
		
		$main::xestiascan_authmodule->disconnect();
		
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{userdeleted}, { Style => "pageheader" });
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addtext(xestiascan_language($main::xestiascan_lang{users}{userdeletedsuccess}, xestiascan_utf8convert($username)));
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlink($main::xestiascan_env{"script_filename"} . "?mode=users", { Text => $main::xestiascan_lang{users}{returnuserlist} });		

		return $main::xestiascan_presmodule->grab();
		
	}
	
	# Disconnect from the database server.
	
	$main::xestiascan_authmodule->disconnect();
	
	# The action to delete the user has not been confirmed so
	# write out a form asking the user to confirm it.
	
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{deleteuser}, { Style => "pageheader" });
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext(xestiascan_language($main::xestiascan_lang{users}{deleteuserareyousure}, xestiascan_utf8convert($username)));
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	
	$main::xestiascan_presmodule->startform($main::xestiascan_env{"script_filename"}, "POST");
	$main::xestiascan_presmodule->addhiddendata("mode", "users");
	$main::xestiascan_presmodule->addhiddendata("action", "delete");
	$main::xestiascan_presmodule->addhiddendata("confirm", "1");
	$main::xestiascan_presmodule->addhiddendata("user", xestiascan_utf8convert($username));
	$main::xestiascan_presmodule->addsubmit($main::xestiascan_lang{users}{deleteuserbutton});
	$main::xestiascan_presmodule->addtext(" | ");
	$main::xestiascan_presmodule->addlink($main::xestiascan_env{"script_filename"}  . "?mode=users", { Text => $main::xestiascan_lang{users}{noreturnuserlist} });
	$main::xestiascan_presmodule->endform();
	
	return $main::xestiascan_presmodule->grab();
	
}

sub xestiascan_users_flush{
#################################################################################
# xestiascan_users_flush: Flush the users out of the sessions table.		#
#										#
# Usage:									#
#										#
# xestiascan_users_flush(confirm);						#
#										#
# confirm	Confirms the actions to flush the users out of the sessions	#
#		table.								#
#################################################################################
	
	my $confirm = shift;
	
	if (!$confirm){
		
		$confirm = 0;
		
	}

	# Connect to the database server.
	
	$main::xestiascan_authmodule->connect();
	
	# Check if any errors occured while connecting to the database server.
	
	if ($main::xestiascan_authmodule->geterror eq "AuthConnectionError"){
		
		# A database connection error has occured so return
		# an error.
		
		xestiascan_error("authconnectionerror", $main::xestiascan_authmodule->geterror(1));
		
	}
	
	# Check to see if the user has permission to manage users.
	
	my $access_userlist = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "Admin" });
	
 	if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
		
		# A database error has occured so return an error with
		# the extended error information.
		
		xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1));
		
	}
	
	if ($access_userlist ne 1){
		
		# User not allowed to access the user list so return an error.
		xestiascan_error("notpermitted");

		if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
			
			# A database error has occured so return an error with
			# the extended error information.
			
			xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1));
			
		}
		
	}
	
	# Check to see if the action to flush the users from session 
	# table has been confirmed.
	
	if ($confirm eq 1){
		
		# Action confirmed, so flush the users table.
		
		$main::xestiascan_authmodule->flushusers();
		
		# Check to see if an error occured while flushing the users out of the session table.
		
		if ($main::xestiascan_authmodule->geterror eq "DatabaseError"){
			
			# A database error has occured so return an error with
			# the extended error information.
			
			xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1));
			
		}
		
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{logoutallusers}, {Style => "pageheader" });
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{logoutallsuccess});
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{logoutallloginagain});
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addlink($main::xestiascan_env{"script_filename"}, { Text => $main::xestiascan_lang{users}{logoutallcontinue} });
		
		return $main::xestiascan_presmodule->grab();
		
	}

	# Disconnect from server.
	
	$main::xestiascan_authmodule->disconnect();
	
	# The action to flush the users from the session tables has not
	# been confirmed so write a message asking for confiramation.
	
	# $main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{deleteuser}, { Style => "pageheader" });
	# $main::xestiascan_presmodule->addlinebreak();
	# $main::xestiascan_presmodule->addlinebreak();
	# $main::xestiascan_presmodule->addtext(xestiascan_language($main::xestiascan_lang{users}{deleteuserareyousure}, $username));
	# $main::xestiascan_presmodule->addlinebreak();
	# $main::xestiascan_presmodule->addlinebreak();

	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{logoutallusers}, {Style => "pageheader" });
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{logoutallquestion});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{users}{logoutallwarning});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	
	$main::xestiascan_presmodule->startform($main::xestiascan_env{"script_filename"}, "POST");
	$main::xestiascan_presmodule->addhiddendata("mode", "users");
	$main::xestiascan_presmodule->addhiddendata("action", "flush");
	$main::xestiascan_presmodule->addhiddendata("confirm", "1");
	$main::xestiascan_presmodule->addsubmit($main::xestiascan_lang{users}{logoutallbutton});
	$main::xestiascan_presmodule->addtext(" | ");
	$main::xestiascan_presmodule->addlink($main::xestiascan_env{"script_filename"}  . "?mode=users", { Text => $main::xestiascan_lang{users}{noreturnuserlist} });
	$main::xestiascan_presmodule->endform();
	
	return $main::xestiascan_presmodule->grab();
	
}