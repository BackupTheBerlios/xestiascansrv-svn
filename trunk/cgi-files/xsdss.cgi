#!/usr/bin/perl -w

#################################################################################
# Xestia Scanner Server (xsdss.cgi)						#
# Main program script			     					#
#										#
# Version: 0.1.0								#
#										#
# Copyright (C) 2005-2011 Steve Brokenshire <sbrokenshire@xestia.co.uk>		#
#										#
# This code has been forked from Kiriwrite <http://xestia.co.uk/kiriwrite>.	#
# Save development time, recycle your code where possible!			#
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

use strict;
use warnings;

use utf8;
use CGI::Lite;
use Tie::IxHash;
use MIME::Base64 3.13 qw(decode_base64url);

binmode STDOUT, ':utf8';

# This is commented out because it uses a fair bit of CPU usage.

#use CGI::Carp('fatalsToBrowser'); 	# Output errors to the browser.

# Declare global variables for Xestia Scanner Server settings and languages.

our ($xestiascan_config, %xestiascan_config, %xestiascan_lang, $xestiascan_lang, $xestiascan_version, %xestiascan_version, $xestiascan_env, %xestiascan_env, $xestiascan_presmodule, $xestiascan_authmodule, $xestiascan_script_name, $xestiascan_env_path);
our ($form_data, %form_data);
our ($loggedin_user);
our $successful_auth = 0;

# If you are using mod_perl please change these settings to the correct
# directory where this script is being run from.

use lib '.';
chdir('.');

# Load the common functions module.

use Modules::System::Common;

# Setup the version information for Xestia Scanner Version.

%xestiascan_version = (
	"major" 	=> 0,
	"minor" 	=> 1,
	"revision" 	=> 0
);

xestiascan_initialise;		# Initialise the Xestia Scanner Server enviroment.
xestiascan_settings_load;	# Load the configuration options.

my $query_lite = new CGI::Lite;
$form_data = $query_lite->parse_form_data();

# Check to see if the user is logged in and present a form if not.

use Modules::System::Auth;

# Check to see if the module is a multiuser module.

my %authmodule_capabilities = $xestiascan_authmodule->capabilities();

if ($authmodule_capabilities{'multiuser'} eq 0){
	
	# Module does not have multiuser support so don't do
	# any authentication.
	
	$successful_auth = 1;
	
}

my $auth_username = "";
my $auth_password = "";
my $auth_seed = "";
my $auth_stayloggedin = "";
my $auth_validinput = 1;
my $cookie_expirestime = 0;
my $auth_failure = int(0);
my $print_cookie = 0;
my $auth_result = "none";
	
my $cookie_data = $query_lite->parse_cookies;

$auth_username	= decode_base64url($cookie_data->{ $main::xestiascan_config{'database_tableprefix'} . '_auth_username'});
$auth_seed	= $cookie_data->{ $main::xestiascan_config{'database_tableprefix'} . '_auth_seed'};

if (!$auth_username || !$auth_seed){

	# The authentication data contains invalid input.
	
	$auth_validinput = 0;
	
}

# Check to see if the username and seed are valid and
# skip to the login form if it isn't.
	
if ($auth_validinput eq 1){
	
	# Connect to the database server and authenticate.
	
	$xestiascan_authmodule->connect();

	# Check if any errors occured while connecting to the database server.
	
	if ($main::xestiascan_authmodule->geterror eq "AuthConnectionError"){
		
		# A database connection error has occured so return
		# an error.
		
		xestiascan_error("authconnectionerror", $main::xestiascan_authmodule->geterror(1));
		
	}
	
	$auth_result = $xestiascan_authmodule->userauth("seed", $auth_username, $auth_seed);
	
	if ($xestiascan_authmodule->geterror eq "DatabaseError"){
			
		# A database error has occured so return an error with
		# the extended error information.
			
		xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1));
			
	}
		
	$successful_auth = 1 if $auth_result eq 1;
	$auth_failure = 1 if $auth_result ne 1;
	$auth_failure = 0 if (!$auth_seed || $auth_seed eq "");
	
	# Disconnect from the database server.
	
	#$xestiascan_authmodule->disconnect();
		
}

if ($form_data->{'mode'} && $form_data->{'mode'} eq "auth" && $successful_auth eq 0){
	
	$auth_username		= $form_data->{'username'};
	$auth_password		= $form_data->{'password'};
	$auth_stayloggedin	= $form_data->{'stayloggedin'};
	
	if (!$auth_stayloggedin || $auth_stayloggedin ne "on"){
		
		$auth_stayloggedin = 0;
		$cookie_expirestime = 10800;
		
	} else {
		
		$auth_stayloggedin = 1;
		$cookie_expirestime = 31536000;
		
	}

	$xestiascan_authmodule->connect();

	# Check if any errors occured while connecting to the database server.
	
	if ($main::xestiascan_authmodule->geterror eq "AuthConnectionError"){
		
		# A database connection error has occured so return
		# an error.
		
		xestiascan_error("authconnectionerror", $main::xestiascan_authmodule->geterror(1));
		
	}
	
	($auth_result, $auth_seed)	= $xestiascan_authmodule->userauth("password", $auth_username, $auth_password, $auth_stayloggedin);
	
	if ($xestiascan_authmodule->geterror eq "DatabaseError"){
		
		# A database error has occured so return an error with
		# the extended error information.
		
		xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1));
		
	}
	
	$successful_auth = 1 if $auth_result eq 1;
	$auth_failure = 1 if $auth_result ne 1;

	# Disconnect from the database server.
	
	#$xestiascan_authmodule->disconnect();
	
	$form_data->{'mode'} = "";

	$print_cookie = 1;
	
}

if ($successful_auth eq 0) {

	# No valid authenication credentials are available so write a form.
	
	my $authpagedata = xestiascan_auth_authenticate($auth_failure);

	xestiascan_output_header;
	xestiascan_output_page("Login", $authpagedata, "none");
	exit;
	
}

if ($successful_auth eq 1){

	$loggedin_user = $auth_username;
	
}

# endif

# Check if a mode has been specified and if a mode has been specified, continue
# and work out what mode has been specified.

if ($form_data->{'mode'}){
	my $http_query_mode = $form_data->{'mode'};

	if ($http_query_mode eq "scan"){

		use Modules::System::Scan;
		
		if ($form_data->{'action'}){
		
			my $http_query_action = $form_data->{'action'};
			
			if ($http_query_action eq "scan"){
			
				my $http_query_previewdocument = $form_data->{'previewdocument'};
				my $http_query_switch = $form_data->{'switch'};

				$http_query_previewdocument = "no" if !$http_query_previewdocument;
				$http_query_switch = "no" if !$http_query_switch;
				
				# Get the variables needed for the subroutine.
				
				my %previewoptions;
				
				$previewoptions{ScannerID} = $form_data->{'scanner'};
				$previewoptions{Brightness} = $form_data->{'brightness'};
				$previewoptions{Contrast} = $form_data->{'contrast'};
				$previewoptions{Rotate} = $form_data->{'rotate'};
				$previewoptions{Colour} = $form_data->{'colourtype'};
				$previewoptions{Resolution} = $form_data->{'imagedpi'};
				$previewoptions{TopLeftX} = $form_data->{'topleftx'};
				$previewoptions{TopLeftY} = $form_data->{'toplefty'};
				$previewoptions{BottomRightX} = $form_data->{'bottomrightx'};
				$previewoptions{BottomRightY} = $form_data->{'bottomrighty'};
				
				$previewoptions{TopLeftX} = "0" if !$previewoptions{TopLeftX};
				
				if ($http_query_switch eq "switched"){
				
					# Switching scanners so don't need to scan.
					
					my $pagedata = xestiascan_scan_preview("off", %previewoptions);

					# Output the header to browser/console/stdout.
					
					xestiascan_output_header;
					xestiascan_output_page($xestiascan_lang{scan}{scanconfig}, $pagedata, "database");	# Output the page to browser/console/stdout.
					exit;	# End the script.
					
				}
				
				if ($http_query_previewdocument eq "on"){
					
					# No action specified so write out default form.
					
					my $pagedata = xestiascan_scan_preview("on", %previewoptions);
					
					# Output the header to browser/console/stdout.
					
					xestiascan_output_header;
					xestiascan_output_page($xestiascan_lang{scan}{scanconfig}, $pagedata, "database");	# Output the page to browser/console/stdout.
					exit;	# End the script.
			
				} else {

					my $http_query_outputformat = $form_data->{'outputformat'};
					my $http_query_formatswitch = $form_data->{'formatswitch'};
					my $http_query_confirm = $form_data->{'confirm'};
					my $http_query_imagehex = $form_data->{'imagehex'};
					
					$http_query_formatswitch = "no" if !$http_query_formatswitch;
					$previewoptions{Switched} = $http_query_formatswitch;
					
					if (!$http_query_confirm){
						$http_query_confirm = 0;
					}
					
					if ($http_query_formatswitch eq "yes"){
						$http_query_confirm = 0;
					}
					
					$previewoptions{ImageHex} = $http_query_imagehex if $http_query_imagehex;
					$previewoptions{OutputFormat} = $http_query_outputformat if $http_query_outputformat;
					
					my $pagedata = xestiascan_scan_final($http_query_confirm, %previewoptions);
			
					xestiascan_output_header;
					xestiascan_output_page($xestiascan_lang{scan}{picturesettings}, $pagedata, "database");	# Output the page to browser/console/stdout.
					exit;	# End the script.
					
				}
				
			} elsif ($http_query_action eq "getpreviewimage"){
			
				my $http_query_pictureid = $form_data->{'pictureid'};
				my $http_query_dontclear = $form_data->{'dontclear'};
				
				if (!$http_query_dontclear){
					$http_query_dontclear = 0;
				}
				
				xestiascan_scan_getpreviewimage($http_query_pictureid, $http_query_dontclear);
				exit;
				
			}
				
		}
			
		# No action specified so write out default form.
			
		my $pagedata = xestiascan_scan_preview();
			
		# Output the header to browser/console/stdout.
			
		xestiascan_output_header;
		xestiascan_output_page($xestiascan_lang{scan}{scanconfig}, $pagedata, "database");	# Output the page to browser/console/stdout.
		exit;	# End the script.
		
	} elsif ($http_query_mode eq "users"){

		use Modules::System::Users;

 		if ($form_data->{'action'}){

			my $http_query_action = $form_data->{'action'};

			if ($http_query_action eq "add"){

				my $http_query_confirm = $form_data->{'confirm'};
				
				if (!$http_query_confirm){
					
					# The http_query_confirm variable is uninitialised, so place a
					# '0' (meaning an unconfirmed action).
					
					$http_query_confirm = 0;
					
				}
				
				if ($http_query_confirm eq 1){
				
					use Hash::Search;
					my $hs = new Hash::Search;
					my %http_userinfo;
					%form_data = $query_lite->parse_form_data();
					
					$http_userinfo{'Username'}		= $form_data->{'username'};
					$http_userinfo{'Name'}			= $form_data->{'name'};
					$http_userinfo{'Password'}		= $form_data->{'password'};
					$http_userinfo{'ConfirmPassword'}	= $form_data->{'confirmpassword'};
					$http_userinfo{'Admin'}			= $form_data->{'admin'};
					$http_userinfo{'Enabled'}		= $form_data->{'enabled'};
					
					# Get the list of scanners from the query.
					
					$hs->hash_search("^scanner_", %form_data);
					my %http_scanner = $hs->hash_search_resultdata;
					
					# Get the list of output modules from the query.
					
					$hs->hash_search("^outputmodule_", %form_data);
					my %http_outputmodules = $hs->hash_search_resultdata;
					
					# Get the list of export modules from the query.
					
					$hs->hash_search("^exportmodule_", %form_data);
					my %http_exportmodules = $hs->hash_search_resultdata;
					
					my $pagedata = xestiascan_users_add($http_userinfo{Username}, \%http_userinfo, \%http_scanner, \%http_outputmodules, \%http_exportmodules, $http_query_confirm);
					
					xestiascan_output_header;	# Output the header to browser/console/stdout;
					xestiascan_output_page($xestiascan_lang{users}{adduser}, $pagedata, "users");	# Output the page to browser/console/stdout;
					exit;				# End the script.
					
				}

				my $pagedata = xestiascan_users_add;

				xestiascan_output_header;	# Output the header to browser/console/stdout;
				xestiascan_output_page($xestiascan_lang{users}{adduser}, $pagedata, "users");	# Output the page to browser/console/stdout;
				exit;				# End the script.				

			} elsif ($http_query_action eq "edit"){
				
				my $http_query_confirm	= $form_data->{'confirm'};
				my $http_query_username	= $form_data->{'user'};

				if (!$http_query_confirm){
					
					# The http_query_confirm variable is uninitialised, so place a
					# '0' (meaning an unconfirmed action).
					
					$http_query_confirm = 0;
					
				}				
				
				if ($http_query_confirm eq 1){
				
					# The action to edit the user has been confirmed so collect
					# the information needed for the xestiascan_users_edit
					# subroutine.
					
					use Hash::Search;
					my $hs = new Hash::Search;
					my %http_userinfo;
					my %form_data = $query_lite->parse_form_data();
					
					my $confirm				= $form_data->{'confirm'};
					$http_userinfo{'OriginalUsername'}	= $form_data->{'username_original'};
					$http_userinfo{'NewUsername'}		= $form_data->{'username'};
					$http_userinfo{'Name'}			= $form_data->{'name'};
					$http_userinfo{'Password'}		= $form_data->{'password'};
					$http_userinfo{'ConfirmPassword'}	= $form_data->{'confirmpassword'};
					$http_userinfo{'Admin'}			= $form_data->{'admin'};
					$http_userinfo{'Enabled'}		= $form_data->{'enabled'};
					
					# Get the list of scanners from the query.
					
					$hs->hash_search("^scanner_", %form_data);
					my %http_scanner = $hs->hash_search_resultdata;
					
					# Get the list of output modules from the query.
					
					$hs->hash_search("^outputmodule_", %form_data);
					my %http_outputmodules = $hs->hash_search_resultdata;
					
					# Get the list of export modules from the query.
					
					$hs->hash_search("^exportmodule_", %form_data);
					my %http_exportmodules = $hs->hash_search_resultdata;
					
					my $pagedata = xestiascan_users_edit($http_userinfo{OriginalUsername}, \%http_userinfo, \%http_scanner, \%http_outputmodules, \%http_exportmodules, $confirm);
					
					xestiascan_output_header;	# Output the header to browser/console/stdout;
					xestiascan_output_page($xestiascan_lang{users}{edituser}, $pagedata, "users");	# Output the page to browser/console/stdout;
					exit;				# End the script.					
					
				}
				
				my $pagedata = xestiascan_users_edit($http_query_username);
				
				xestiascan_output_header;	# Output the header to browser/console/stdout;
				xestiascan_output_page($xestiascan_lang{users}{edituser}, $pagedata, "users");	# Output the page to browser/console/stdout;
				exit;				# End the script.				
				
			} elsif ($http_query_action eq "delete"){

				my $http_query_confirm	= $form_data->{'confirm'};
				my $http_query_username	= $form_data->{'user'};
				
				if (!$http_query_confirm){
					
					# The http_query_confirm variable is uninitialised, so place a
					# '0' (meaning an unconfirmed action).
					
					$http_query_confirm = 0;
					
				}
				
				if ($http_query_confirm eq 1){
				
					# The action to delete a user has been confirmed.
					
					my $pagedata = xestiascan_users_delete($http_query_username, $http_query_confirm);
					
					xestiascan_output_header;	# Output the header to browser/console/stdout;
					xestiascan_output_page($xestiascan_lang{users}{deleteuser}, $pagedata, "users");	# Output the page to browser/console/stdout;
					exit;				# End the script.
					
				}
				
				my $pagedata = xestiascan_users_delete($http_query_username);
				
				xestiascan_output_header;	# Output the header to browser/console/stdout;
				xestiascan_output_page($xestiascan_lang{users}{deleteuser}, $pagedata, "users");	# Output the page to browser/console/stdout;
				exit;				# End the script.
				
			} elsif ($http_query_action eq "flush"){
				
				my $http_query_confirm = $form_data->{'confirm'};
				
				$http_query_confirm = 0 if !$http_query_confirm;
				
				my $pagedata = xestiascan_users_flush($http_query_confirm);
				
				xestiascan_output_header;	# Output the header to browser/console/stdout;
				xestiascan_output_page($xestiascan_lang{users}{logoutallusers}, $pagedata, "users");	# Output the page to browser/console/stdout;
				exit;				# End the script.
				
			} else {
		
				# The action specified was something else other than those
				# above, so return an error.
		
				xestiascan_error("invalidaction");

			}		

		} 		

		my $showdeactivated = 0;

		if ($form_data->{'showdeactivated'} && $form_data->{'showdeactivated'} eq "on"){
			
			$showdeactivated = 1;

		}

		my $pagedata = xestiascan_users_list({ ShowDeactivatedUsers => $showdeactivated });

		xestiascan_output_header;	# Output the header to browser/console/stdout;
		xestiascan_output_page($xestiascan_lang{users}{userslist}, $pagedata, "users");	# Output the page to browser/console/stdout;
		exit;				# End the script.

	} elsif ($http_query_mode eq "settings"){

		use Modules::System::Settings;

		if ($form_data->{'action'}){
			my $http_query_action = $form_data->{'action'};
		
			if ($http_query_action eq "edit"){
		
				# The action specified is to edit the settings. Check if the action
				# to edit the settings has been confirmed.
		
				my $http_query_confirm = $form_data->{'confirm'};
		
				if (!$http_query_confirm){
		
					# The confirm value is blank, so set it to 0.
		
					$http_query_confirm = 0;
		
				}
		
				if ($http_query_confirm eq 1){
		
					# The action to edit the settings has been confirmed. Get the
					# required settings from the HTTP query.
		
					my $http_query_imagesuri	= $form_data->{'imagesuripath'};
					my $http_query_scansuri		= $form_data->{'scansuripath'};
					my $http_query_scansfs		= $form_data->{'scansfspath'};
					my $http_query_datetimeformat	= $form_data->{'datetime'};
					my $http_query_systemlanguage	= $form_data->{'language'};
					my $http_query_presmodule	= $form_data->{'presmodule'};
					my $http_query_authmodule	= $form_data->{'authmodule'};
					my $http_query_outputmodule	= $form_data->{'outputmodule'};
		
					my $http_query_database_server		= $form_data->{'database_server'};
					my $http_query_database_port		= $form_data->{'database_port'};
					my $http_query_database_protocol	= $form_data->{'database_protocol'};
					my $http_query_database_sqldatabase	= $form_data->{'database_sqldatabase'};
					my $http_query_database_username	= $form_data->{'database_username'};
					my $http_query_database_passwordkeep	= $form_data->{'database_password_keep'};
					my $http_query_database_password	= $form_data->{'database_password'};
					my $http_query_database_tableprefix	= $form_data->{'database_tableprefix'};
		
					my $pagedata = xestiascan_settings_edit({ ImagesURIPath => $http_query_imagesuri, ScansURIPath => $http_query_scansuri, ScansFSPath => $http_query_scansfs, DateTimeFormat => $http_query_datetimeformat, SystemLanguage => $http_query_systemlanguage, PresentationModule => $http_query_presmodule, OutputModule => $http_query_outputmodule, AuthModule => $http_query_authmodule, DatabaseServer => $http_query_database_server, DatabasePort => $http_query_database_port, DatabaseProtocol => $http_query_database_protocol, DatabaseSQLDatabase => $http_query_database_sqldatabase, DatabaseUsername => $http_query_database_username, DatabasePasswordKeep => $http_query_database_passwordkeep, DatabasePassword => $http_query_database_password, DatabaseTablePrefix => $http_query_database_tableprefix, Confirm => 1 });
		
					xestiascan_output_header;	# Output the header to browser/console/stdout.
					xestiascan_output_page($xestiascan_lang{setting}{editsettings}, $pagedata, "settings");	# Output the page to browser/console/stdout.
					exit;				# End the script.
		
				}
		
				# The action to edit the settings has not been confirmed.
		
				my $pagedata = xestiascan_settings_edit();
		
				xestiascan_output_header;	# Output the header to browser/console/stdout.
				xestiascan_output_page($xestiascan_lang{setting}{editsettings}, $pagedata, "settings");	# Output the page to browser/console/stdout.
				exit;				# End the script.
		
			} else {
		
				# The action specified was something else other than those
				# above, so return an error.
		
				xestiascan_error("invalidaction");
		
			}
		
		}
		
		# No action has been specified, so print out the list of settings currently being used.
		
		my $pagedata = xestiascan_settings_view();
		
		xestiascan_output_header;		# Output the header to browser/console/stdout.
		xestiascan_output_page($xestiascan_lang{setting}{viewsettings}, $pagedata, "settings");	# Output the page to browser/console/stdout.
		exit;					# End the script.

	} elsif ($http_query_mode eq "logout"){
		
		# The mode selected is to logout the user.
		
		my $pagedata = xestiascan_auth_logout();
		
		xestiascan_output_header("cookie_logout");	# Output the header to browser/console/stdout.
		xestiascan_output_page($xestiascan_lang{setting}{logout}, $pagedata, "settings");	# Output the page to browser/console/stdout.
		exit;						# End the script.
		
	} else {

		# An invalid mode has been specified so return
		# an error.

		xestiascan_error("invalidmode");

	}
	
} else {

	# No mode has been specified, so print the default "first-run" view of the
	# scanning setup.

	use Modules::System::Scan;
		
	my $pagedata = xestiascan_scan_preview();

	# Output the header to browser/console/stdout.

	if ($print_cookie eq 1){
		xestiascan_output_header("cookie", $auth_username, $auth_seed, $cookie_expirestime);
	} else {
		xestiascan_output_header;
	}

	xestiascan_output_page($xestiascan_lang{scan}{scanconfig}, $pagedata, "database");	# Output the page to browser/console/stdout.
	exit;	# End the script.
	
}

__END__