#################################################################################
# Xestia Scanner Server - Email Export Module.					#
# Sends the page as an email.							#
#										#
# Copyright (C) 2011 Steve Brokenshire <sbrokenshire@xestia.co.uk>		#
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

package Modules::Export::Email;

# Enable strict and use warnings.

use strict;
use warnings;
use Encode qw(decode_utf8);
use Tie::IxHash;
use Modules::System::Common;
use MIME::Base64 3.13 qw(encode_base64);
use File::Basename;
use Net::Domain qw(hostfqdn);
use Net::SMTP;
use File::Basename;
use File::MimeInfo;

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
	
	$options{servername}{type} = "textbox";
	$options{servername}{string} = languagestrings("servername");
	$options{servername}{maxlength} = "256";
	$options{servername}{size} = "64";
	
	$options{serverport}{type} = "textbox";
	$options{serverport}{string} = languagestrings("serverport");
	$options{serverport}{value} = "25";
	$options{serverport}{maxlength} = "5";
	$options{serverport}{size} = "5";
	
	#$options{smtpssl}{type} = "checkbox";
	#$options{smtpssl}{string} = "Enable SSL/TLS";
	#$options{smtpssl}{checked} = 1;

	$options{senderaddress}{type} = "textbox";
	$options{senderaddress}{string} = languagestrings("senderaddress");
	$options{senderaddress}{maxlength} = "256";
	$options{senderaddress}{size} = "64";
	
	$options{emailaddress}{type} = "textbox";
	$options{emailaddress}{string} = languagestrings("emailaddress");
	$options{emailaddress}{maxlength} = "256";
	$options{emailaddress}{size} = "64";
	
	$options{username}{type} = "textbox";
	$options{username}{string} = languagestrings("username");
	$options{username}{maxlength} = "256";
	$options{username}{size} = "32";
	
	$options{password}{type} = "textbox";
	$options{password}{string} = languagestrings("password");
	$options{password}{maxlength} = "256";
	$options{password}{password} = 1;
	$options{password}{size} = "32";

	$options{filename}{type} = "textbox";
	$options{filename}{string} = languagestrings("filename");
	$options{filename}{maxlength} = "256";
	$options{filename}{size} = "64";
	
	$options{subjectline}{type} = "textbox";
	$options{subjectline}{string} = languagestrings("subjectline");
	$options{subjectline}{maxlength} = "256";
	$options{subjectline}{value} = languagestrings("scannedimage");
	$options{subjectline}{size} = "64";
	
	$options{personalmessage}{type} = "textbox";
	$options{personalmessage}{string} = languagestrings("personalmessage");
	$options{personalmessage}{maxlength} = "1024";
	$options{personalmessage}{size} = "64";
	
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
	
	if (!$exportoptions{filename}){
	
		$exportoptions{filename} = basename($processed_filename);
		
	}
	
	# Try to connect to the SMTP server.
	
	my $smtp = Net::SMTP->new($exportoptions{servername},
		Hello => hostfqdn,
		Port => $exportoptions{serverport}
	) or ($error_flag = 1, $error_message = $!, return);
	
	$smtp->auth($exportoptions{username}, $exportoptions{password}) or ($error_flag = 1, $error_message = $smtp->message(), return);
	
	# Setup the sender and recipient addresses.
	
	$smtp->mail($exportoptions{senderaddress}) or ($error_flag = 1, $error_message = $smtp->message(), return);
	
	$smtp->recipient($exportoptions{emailaddress}) or ($error_flag = 1, $error_message = $smtp->message(), return);
	
	$smtp->data() or ($error_flag = 1, $error_message = $smtp->message(), return);
	
	# Generate a random value and get the MIME type for the file.
	
	my $randomhex = uc(sprintf("%x",int(rand(75000000))));
	my $mime_type = mimetype($processed_filename);
	
	# Write out the header.

	$smtp->datasend("Content-Disposition: inline\n");
	$smtp->datasend("Content-Type: multipart/mixed; boundary=\"=-" . $randomhex ."\"\n");
	$smtp->datasend("MIME-Version: 1.0\n");
	$smtp->datasend("Subject: " . $exportoptions{subjectline} . "\n");
	$smtp->datasend("To:" . $exportoptions{emailaddress} . "\n");
	$smtp->datasend("X-Mailer: Xestia Scanner Server 0.1.0 (Email.pm; http://xestia.co.uk/scannerserver)\n");
	
	# Write the message (if there).
	
	$smtp->datasend("\n");
	
	$smtp->datasend("--=-" . $randomhex . "\n");
	$smtp->datasend("Content-Type: text/plain;\n");
	$smtp->datasend("\tcharset=utf-8\n");
	$smtp->datasend("Content-Transfer-Encoding: 7bit\n\n");
	
	$smtp->datasend($exportoptions{personalmessage} . "\n\n");

	$smtp->datasend("--=-" . $randomhex . "\n");
	
	# Encode the file to Base64 and "attach" to the email.

	$smtp->datasend("Content-Disposition: attachment;\n");
	$smtp->datasend("\tfilename=" . $exportoptions{filename} . "\n");
	$smtp->datasend("Content-Type: " . $mime_type . ";\n");
	$smtp->datasend("\tcharset=us-ascii;\n");
	$smtp->datasend("\tname=" . $exportoptions{filename} . "\n");
	$smtp->datasend("Content-Transfer-Encoding: base64\n\n");

	# Open the file and process it into Base64.
	
	open((my $picture), "<", $processed_filename) or ($error_flag = 1, $error_message = $!, return);
	binmode($picture);
	
	my $line;
	
	while (read($picture, $line, 60*57)){
		
		$smtp->datasend(encode_base64($line));
		
	}
	
	close($picture);
	
	$smtp->datasend("--" . $randomhex . "--\n");
	$smtp->datasend("\n--=-" . $randomhex . "--\n");
	
	$smtp->dataend();
	
	$smtp->quit();
	
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
		
		$language_strings{servername} = "Server name:";
		$language_strings{serverport} = "Server port:";
		$language_strings{senderaddress} = "Sender email address:";
		$language_strings{emailaddress} = "Recipient email address:";
		$language_strings{username} = "Username:";
		$language_strings{password} = "Password:";
		$language_strings{filename} = "Filename for image (blank for default):";
		$language_strings{subjectline} = "Subject line:";
		$language_strings{scannedimage} = "Scanned Image";
		$language_strings{personalmessage} = "Personal Message:";
		
	} else {
		
		# Invalid language so use English (British) as default.
		
		$language_strings{servername} = "Server name:";
		$language_strings{serverport} = "Server port:";
		$language_strings{senderaddress} = "Sender email address:";
		$language_strings{emailaddress} = "Recipient email address:";
		$language_strings{username} = "Username:";
		$language_strings{password} = "Password:";
		$language_strings{filename} = "Filename for image (blank for default):";
		$language_strings{subjectline} = "Subject line:";
		$language_strings{scannedimage} = "Scanned Image";
		$language_strings{personalmessage} = "Personal Message:";
		
	}
	
	$language_string = $language_strings{$langstring};
	
	foreach $item (@_){
		
                $language_string =~ s/%s/$item/;
		
        }
	
	return $language_string;
	
}

1;