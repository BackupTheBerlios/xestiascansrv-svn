#################################################################################
# Xestia Scanner Server - Download Export Module.				#
# Presents the scanned image after being processed as a download link.		#
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

# Define the package (perl module) name.

package Modules::Export::Download;

# Enable strict and use warnings.

use strict;
use warnings;
use Encode qw(decode_utf8);
use Modules::System::Common;
use File::Copy;
use File::Basename;

# Set the following values.

our $VERSION = "0.1.0";

my $error_flag = 0;
my $error_message = "";
my $language_name = "";
my %optionshash = ();

sub new{
#################################################################################
# new: Create an instance of Modules::Output::Normal				#
# 										#
# Usage:									#
#										#
# $dbmodule = Modules::Output::Normal->new();					#
#################################################################################
	
	# Get the perl module name.

	my $class = shift;
	my $self = {};

	return bless($self, $class);

}

sub initialise{
#################################################################################
# initialise: Initialises the output module.					#
#										#
# Usage:									#
#										#
# $outputmodule->initialise();							#
#################################################################################

}

sub loadsettings{
#################################################################################
# loadsettings: Loads some settings for the output module.			#
#										#
# Usage:									#
#										#
# $outputmodule->loadsettings(language);					#
#										#
# language	Specifies the language to use.					#
#################################################################################
	
	my $class = shift;
	my $passed_lang = shift;
	
	$language_name = $passed_lang;
	
}

sub getoptions{
#################################################################################
# getoptions: Gets the options that will be used.				#
#										#
# Usage:									#
#										#
# %options = $outputmodule->getoptions();					#
#################################################################################

	my (%options, $options);
	tie(%options, "Tie::IxHash");
	
	$options{filenameforexport}{type} = "textbox";
	$options{filenameforexport}{string} = languagestrings("filenametouse");
	$options{filenameforexport}{maxlength} = "256";
	$options{filenameforexport}{size} = "64";
	
	return %options;

}

sub exportimage{
#################################################################################
# exportimage: Exports the image.						#
#										#
# Usage:									#
#										#
# $exportmodule->exportimage(processedfilename, scansuridirectory,		#
#				scansfsdirectory, exportoptions);		#
#										#
# processedfilename	Specifies the processed file to export.			#
# scansuridirectory	Specifies the URI of the scans directory.		#
# scansfsdirectory	Specifies the FS location of the scans directory.	#
# exportoptions		Specifies the options for the export module.		#
#################################################################################

	my ($exportoptions, %exportoptions);
	
	my $class = shift;
	my $processed_filename = shift;
	my $scans_uri = shift;
	my $scans_fs = shift;
	%exportoptions = @_;
	
	# Copy the file to the download directory.
	
	$! = 0;

	# Remove everything before the last slash.
	
	my $processed_filename_nopath = fileparse($processed_filename);
	
	copy($processed_filename, "scans/" . $processed_filename_nopath) or ($error_flag = 1, $error_message = $!, return);
	
	# Move the file into the scans folder.
	
	if ($exportoptions{filenameforexport}){
		
		# Remove everything before the last slash.
		
		my $processedexportname = basename($exportoptions{filenameforexport});
		
		move("scans/" . $processed_filename_nopath, $scans_fs . "/" . $processedexportname) or ($error_flag = 1, $error_message = $!, return);
		$processed_filename_nopath = $processedexportname;

		
	} else {
	
		move("scans/" . $processed_filename_nopath, $scans_fs . "/" . $processed_filename_nopath) or ($error_flag = 1, $error_message = $!, return);
		
	}
	
	# Print Link.
	
	$main::xestiascan_presmodule->addlink($scans_uri . "/" . $processed_filename_nopath, { Text => languagestrings("clicklink") });
	
	return;

}

sub errorflag{
#################################################################################
# errorflag: Returns an error flag (if any).					#
#										#
# Usage:									#
#										#
# $errorflag 	= $outputmodule->errorflag();					#
#################################################################################
	
	return $error_flag;

}

sub errormessage{
#################################################################################
# errormessage: Returns an error message (if any).				#
#										#
# Usage:									#
#										#
# $errormessage = $outputmodule->errormessage();				#
#################################################################################

	return $error_message;

}

sub clearflag{
#################################################################################
# clearflag: Clears the error message flag and the error message itself.	#
#										#
# Usage:									#
#										#
# $outputmodule->clearflag();							#
#################################################################################

	$error_flag 	= 0;
	$error_message	= "";

}

sub languagestrings{
#################################################################################
# languagestrings: Language strings that are used in this module.		#
#										#
# Usage:									#
#										#
# $string = $outputmodule->languagestrings("langstring");			#
#################################################################################

	my $langstring = shift;

	my $language_string;
	my ($language_strings, %language_strings);
	my $item;
	
	if ($language_name eq "en-GB"){

		# Language strings for English (British) language.
		
		$language_strings{clicklink} = "Click on or select this link to download the image.";
		$language_strings{filenametouse} = "Filename to use (leave blank for default):";

	} else {

		# Invalid language so use English (British) as default.

		$language_strings{clicklink} = "Click on or select this link to download the image.";
		$language_strings{filenametouse} = "Filename to use (leave blank for default):";
		
	}

	$language_string = $language_strings{$langstring};
	
	foreach $item (@_){

                $language_string =~ s/%s/$item/;

        }

	return $language_string;

}

1;