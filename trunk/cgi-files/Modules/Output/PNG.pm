#################################################################################
# Xestia Scanner Server Output Module - PNG Output Module.			#
# Outputs the image into the PNG format.					#
#										#
# Copyright (C) 2010-11 Steve Brokenshire <sbrokenshire@xestia.co.uk>		#
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

package Modules::Output::PNG;

# Enable strict and use warnings.

use strict;
use warnings;
use Encode qw(decode_utf8);
use Tie::IxHash;
use Modules::System::Common;
use Image::Magick;

# Set the following values.

our $VERSION = "0.1.0";
my ($pages, %pages);
my $error_flag = 0;
my $error_message = "";
my $language_name = "";
my %optionshash = ();

tie(%pages, "Tie::IxHash");

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

	#$options{seperatedirdatabase}{type} = "checkbox";
	#$options{seperatedirdatabase}{string} = "Disable content type (make browser guess!)";
	return %options;

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

sub processimage{
#################################################################################
# processimage: Processes the image.						#
#										#
# Usage:									#
#										#
# $outputmodule->processimage(hexnumber, outputmoduleoptions);			#
#										#
# hexnumber		Specifies the hex number for the image.			#
# outputmoduleoptions	Specifies the options for the output module as a hash.	#
#################################################################################
	
	my $class = shift;
	my $hexnumber = shift;
	my $outputmoduleoptions = @_;
	
	my $errmsg;
	
	my $im = new Image::Magick;
	$errmsg = $im->Read("/tmp/xestiascanserver-preview-" . $hexnumber . ".pnm");
	
	if ($errmsg){
		
		$error_flag = 1;
		$error_message = $errmsg;
		return;
		
	}
	
	$errmsg = $im->Write("/tmp/xestiascanserver-final-" . $hexnumber . ".png");

	if ($errmsg){
		
		$error_flag = 1;
		$error_message = $errmsg;
		return;
		
	}
	
	return "/tmp/xestiascanserver-final-" . $hexnumber . ".png";
	
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

	if ($language_name eq "en-GB" or !$language_name){

		# Language strings for English (British) language.

		$language_strings{seperatedirdatabase} = "Seperate directory for each database.";
		$language_strings{invalidpermissionset} = "Invalid file permissions set.";

	} else {

		# Invalid language so use English (British) as default.

		$language_strings{seperatedirdatabase} = "Seperate directory for each database.";
		$language_strings{invalidpermissionset} = "Invalid file permissions set.";

	}

	$language_string = $language_strings{$langstring};
	
	foreach $item (@_){

                $language_string =~ s/%s/$item/;

        }

	return $language_string;

}

1;