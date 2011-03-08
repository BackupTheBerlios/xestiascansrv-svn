#################################################################################
# Xestia Scanner Server - Auth System Module					#
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

package Modules::System::Auth;

use Modules::System::Common;
use strict;
use warnings;
use Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(xestiascan_auth_authenticate xestiascan_auth_logout);

sub xestiascan_auth_authenticate{
#################################################################################
# xestiascan_auth_authenticate: Provides a form for authentication.		#
#										#
# Usage:									#
#										#
# xestiascan_auth_authenticate(authfailure);					#
#										#
# authfailure	Display authentication failure message.				#
#################################################################################
	
	my $authfailure = shift;
	
	$authfailure = 0 if !$authfailure;
	
	if ($authfailure eq 1){
	
		$main::xestiascan_presmodule->startbox("errorsectionbox");
		$main::xestiascan_presmodule->startbox("errorboxheader");
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{error});
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->startbox("errorbox");
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{auth}{loginerror});
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->endbox();		
		
	}
	
	$main::xestiascan_presmodule->startbox("sectionbox");
	$main::xestiascan_presmodule->startbox("sectiontitle");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{auth}{login});
	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->startbox("secondbox");
	
	$main::xestiascan_presmodule->startform($main::xestiascan_env{"script_filename"}, "POST");
	$main::xestiascan_presmodule->addhiddendata("mode", "auth");
	$main::xestiascan_presmodule->starttable("", { CellPadding => "5", CellSpacing => "0" });
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{auth}{username});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("username", { Size => 32, MaxLength => 32 });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{auth}{password});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addinputbox("password", { Size => 64, MaxLength => 128, Password => 1 });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();
	$main::xestiascan_presmodule->startrow();
	$main::xestiascan_presmodule->addcell("tablecell1");
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{common}{options});
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->addcell("tablecell2");
	$main::xestiascan_presmodule->addcheckbox("stayloggedin", { OptionDescription => $main::xestiascan_lang{auth}{keeploggedin} });
	$main::xestiascan_presmodule->endcell();
	$main::xestiascan_presmodule->endrow();	
	$main::xestiascan_presmodule->endtable();
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addsubmit($main::xestiascan_lang{auth}{loginbutton});
	$main::xestiascan_presmodule->addtext(" | ");
	$main::xestiascan_presmodule->addreset($main::xestiascan_lang{common}{clearvalues});
	$main::xestiascan_presmodule->endform();
	
	$main::xestiascan_presmodule->endbox();
	$main::xestiascan_presmodule->endbox();
	
	return $main::xestiascan_presmodule->grab();
	
}

sub xestiascan_auth_logout{
#################################################################################
# xestiascan_auth_logout: Logout of the Xestia Scanner Server installation.	#
#################################################################################
	
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{auth}{loggedout}, { Style => "pageheader" });
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{auth}{loggedoutmsg});
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlinebreak();
	$main::xestiascan_presmodule->addlink($main::xestiascan_env{"script_filename"}, { Text => $main::xestiascan_lang{auth}{displaylogin} });
	
	return $main::xestiascan_presmodule->grab();
	
}