#################################################################################
# Xestia Scanner Server - Scan System Module					#
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

package Modules::System::Scan;

use Modules::System::Common;
use strict;
use warnings;
use Exporter;
use Tie::IxHash;
use Hash::Search;
use Sane;
use Image::Magick;
use CGI::Lite;

our @ISA = qw(Exporter);
our @EXPORT = qw(xestiascan_scan_preview xestiascan_scan_final xestiascan_scan_getpreviewimage xestiascan_scan_getoutputmodules xestiascan_scan_getexportmodules);
our $scan_device;

sub xestiascan_scan_getoutputmodules{
#################################################################################
# xestiascan_scan_getoutputmodules: Gets the list of available output modules.	#
#										#
# Usage:									#
#										#
# @outputmodules = xestiascan_scan_getoutputmodules;				#
#################################################################################

	my (@outputmoduleslist, @outputmoduleslist_final);
	my $outputmodulefile;

	opendir(OUTPUTMODULEDIR, "Modules/Output");
	@outputmoduleslist = grep /m*\.pm$/, sort(readdir(OUTPUTMODULEDIR));
	closedir(OUTPUTMODULEDIR);

	foreach $outputmodulefile (@outputmoduleslist){
		next if $outputmodulefile =~ m/^\./;
		next if $outputmodulefile !~ m/.pm$/;
		$outputmodulefile =~ s/.pm$//;
		push(@outputmoduleslist_final, $outputmodulefile);
	}

	return @outputmoduleslist_final;
	
}

sub xestiascan_scan_getexportmodules{
#################################################################################
# xestiascan_scan_getexportmodules: Gets the list of available export modules.	#
#										#
# Usage:									#
#										#
# @exportmodules = xestiascan_scan_getexportmodules;				#
#################################################################################

	my (@exportmoduleslist, @exportmoduleslist_final);
	my $exportmodulefile;

	opendir(EXPORTMODULEDIR, "Modules/Export");
	@exportmoduleslist = grep /m*\.pm$/, sort(readdir(EXPORTMODULEDIR));
	closedir(EXPORTMODULEDIR);

	foreach $exportmodulefile (@exportmoduleslist){
		next if $exportmodulefile =~ m/^\./;
		next if $exportmodulefile !~ m/.pm$/;
		$exportmodulefile =~ s/.pm$//;
		push(@exportmoduleslist_final, $exportmodulefile);
	}

	return @exportmoduleslist_final;
	
}

sub xestiascan_scan_preview{
#################################################################################
# xestiascan_scan_preview: Previews a scanning.					#
#										#
# Usage:									#
#										#
# xestiascan_scan_preview(previewdocument, previewoptions);			#
#										#
# previewdocument	Specifies a preview of the document should be made.	#
# previewoptions	Specifies the options for the document preview.		#
#################################################################################

	# Get the values passed to this subroutine.
	
	my $previewdocument = shift;
	
	if (!$previewdocument){
	
		$previewdocument = "off";
		
	}
	
	# Setup some variables for later.
	
	my $scan_settings = 0;
	
	my $picture_resolution = "75";
	my $picture_brightness = "100";
	my $picture_contrast = "100";
	my $picture_topleftx = 0;
	my $picture_toplefty = 0;
	my $picture_bottomrightx = 0;
	my $picture_bottomrighty = 0;
	
	# Check if the preview document checkbox is selected and if it is then
	# scan the image and preview it.
	
	my $randomhex = int(0);
	my %previewoptions;
	
	my $scannerpermission;
	
	if ($previewdocument eq "on"){
		
		(%previewoptions) = @_;
		
		# Check the parameters passed to the subroutine.
		
		# Brightness.
		
		xestiascan_error("brightnessblank") if !$previewoptions{Brightness};
		my $brightness_numberscheck = xestiascan_variablecheck($previewoptions{Brightness}, "numbers", 0, 1);
		xestiascan_error("brightnessinvalidnumber") if $brightness_numberscheck eq 1;
		
		# Rotate. (Should be either 0, 90, 180, 270 degrees).
		
		xestiascan_error("rotateblank") if !$previewoptions{Rotate};
		if ($previewoptions{Rotate} eq "0deg" || $previewoptions{Rotate} eq "90deg" || $previewoptions{Rotate} eq "180deg" || $previewoptions{Rotate} eq "270deg"){
			
		} else {
		
			xestiascan_error("rotateinvalidoption");
		
		}
		
		# Colour.
		
		xestiascan_error("colourblank") if !$previewoptions{Colour};
		if ($previewoptions{Colour} eq "rgb" || $previewoptions{Colour} eq "grey" ){
			
		} else {
		
			xestiascan_error("colourinvalidoption");
			
		}
		
		# Resolution.
		
		xestiascan_error("resolutionblank") if !defined($previewoptions{Resolution});
		my $resolution_numberscheck = xestiascan_variablecheck($previewoptions{Resolution}, "numbers", 0, 1);
		xestiascan_error("resolutioninvalidnumber") if $resolution_numberscheck eq 1;
		
		# Top Left X (Pointy figure);
		
		xestiascan_error("topleftxblank") if !defined($previewoptions{TopLeftX});
		my $topleftx_decimalcheck = xestiascan_variablecheck($previewoptions{TopLeftX}, "decimal", 0, 1);
		xestiascan_error("topleftxinvalidnumber") if $topleftx_decimalcheck eq 1;
		
		# Top Left Y (Pointy figure).
		
		xestiascan_error("topleftyblank") if !defined($previewoptions{TopLeftY});
		my $toplefty_decimalcheck = xestiascan_variablecheck($previewoptions{TopLeftY}, "decimal", 0, 1);
		xestiascan_error("topleftyinvalidnumber") if $toplefty_decimalcheck eq 1;		
		
		# Bottom Right X (Pointy figure).
		
		xestiascan_error("bottomrightx") if !defined($previewoptions{BottomRightX});
		my $bottomrightx_decimalcheck = xestiascan_variablecheck($previewoptions{BottomRightX}, "decimal", 0, 1);
		xestiascan_error("bottomrightxinvalidnumber") if $bottomrightx_decimalcheck eq 1;
		
		# Bottom Right Y (Pointy figure).
		
		xestiascan_error("bottomrighty") if !defined($previewoptions{BottomRightY});
		my $bottomrighty_decimalcheck = xestiascan_variablecheck($previewoptions{BottomRightY}, "decimal", 0, 1);
		xestiascan_error("bottomrightyinvalidnumber") if $bottomrighty_decimalcheck eq 1;
		
		# Check to see if the user has permission to use the scanner.
		
		$scannerpermission = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "Scanner", PermissionName => $previewoptions{ScannerID} });
		
		xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
		xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
		xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
		
		if ($scannerpermission eq 1){
			
			# User has permission to use the scanner so start scanning.
			
			# Generate a random hex value and use this to write a temporary file.
			
			$randomhex = hex(int(rand(16777216)));
			
			# Set variables for scanner and return an error if they were
			# not set correctly.
			
			$scan_device = Sane::Device->open($previewoptions{ScannerID});
			xestiascan_error("scannererror", $Sane::STATUS) if $Sane::STATUS;
			
			xestiascan_scan_setscannervalue(SANE_NAME_SCAN_RESOLUTION, $previewoptions{Resolution});
			xestiascan_error("scannererror", xestiascan_language($main::xestiascan_lang{scan}{causedpictureresolution}, $Sane::STATUS)) if $Sane::STATUS;
			
			xestiascan_scan_setscannervalue(SANE_NAME_SCAN_TL_X, $previewoptions{TopLeftX});
			xestiascan_error("scannererror", xestiascan_language($main::xestiascan_lang{scan}{causedtopleftx}, $Sane::STATUS)) if $Sane::STATUS;
			
			xestiascan_scan_setscannervalue(SANE_NAME_SCAN_TL_Y, $previewoptions{TopLeftY});
			xestiascan_error("scannererror", xestiascan_language($main::xestiascan_lang{scan}{causedtoplefty}, $Sane::STATUS)) if $Sane::STATUS;
			
			xestiascan_scan_setscannervalue(SANE_NAME_SCAN_BR_X, $previewoptions{BottomRightX});
			xestiascan_error("scannererror", xestiascan_language($main::xestiascan_lang{scan}{causedbottomrightx}, $Sane::STATUS)) if $Sane::STATUS;
			
			xestiascan_scan_setscannervalue(SANE_NAME_SCAN_BR_Y, $previewoptions{BottomRightY});
			xestiascan_error("scannererror", xestiascan_language($main::xestiascan_lang{scan}{causedbottomrighty}, $Sane::STATUS)) if $Sane::STATUS;
			
			# Get Sane to scan based on what has been passed (scanner name).
			
			if ($Sane::STATUS == SANE_STATUS_GOOD){
				$scan_device->start;
			} else {
			
				# An error occured whilst trying to use the scanner
				# so return an error.
				
				xestiascan_error("scannererror", $Sane::STATUS);
				
			}
			
			my $param = $scan_device->get_parameters;
			my $fh;
			open ($fh, '>', "/tmp/xestiascanserver-" . $randomhex . ".pnm") or xestiascan_error("filepermissionerror", $!);
			$scan_device->write_pnm_header($fh, $param->{format}, 
			$param->{pixels_per_line},
			$param->{lines}, $param->{depth});
			my ($data, $len);
			do{ 
				($data, $len) = $scan_device->read ($param->{bytes_per_line});
				print $fh $data if $data;
			} until ($Sane::STATUS == SANE_STATUS_EOF);
			close ($fh);
			
			# Get the current scanner values.
			
			$picture_resolution = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_RESOLUTION);
			$picture_topleftx = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_TL_X);
			$picture_toplefty = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_TL_Y);
			$picture_bottomrightx = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_BR_X);
			$picture_bottomrighty = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_BR_Y);
			
			$scan_settings = 1;
			
			$picture_topleftx = int(0) if $picture_topleftx eq 0;
			
			# Convert the PNM based image into PNG format.
			
			my $im = new Image::Magick;
			$im->Read("/tmp/xestiascanserver-" . $randomhex . ".pnm");
			
			# Rotate the document if needed.
			
			my $rotate = $previewoptions{Rotate};
			my $numrotate = 0;
			my $numrotateseek = 0;
			
			if ($previewoptions{Rotate} ne "0deg" ){
				$numrotate = 1 if $rotate eq "90deg";
				$numrotate = 2 if $rotate eq "180deg";
				$numrotate = 3 if $rotate eq "270deg";
				#$im->Rotate({ degrees => "180" }) if $rotate eq "180deg";
				#$im->Rotate({ degrees => "270" }) if $rotate eq "270deg";
				
				do {
					$im->Rotate();
					$numrotateseek++;
				} until ($numrotateseek eq $numrotate || $numrotateseek > $numrotate);
				
			}
			
			# Change the colour type of the document if needed.
			
			if ($previewoptions{Colour} eq "rgb"){
				
				# Set the document to colour.
				
				$im->Quantize(colorspace => 'RGB');
				
			} elsif ($previewoptions{Colour} eq "grey"){
				
				# Set the document to greyscale.
				
				$im->Quantize(colorspace =>'gray');
				
			}
		
			# Adjust the brightness.
			
			xestiascan_error("brightnessblank") if !$previewoptions{Brightness};
			
			my $brightness_numberscheck = xestiascan_variablecheck($previewoptions{Brightness}, "numbers", 0, 1);
			xestiascan_error("brightnessinvalidnumber") if $brightness_numberscheck eq 1;
			
			$picture_brightness = $previewoptions{Brightness};
			$im->Modulate(brightness=> $picture_brightness);
			
			$im->Minify;		# As it is a preview, Minify it.
			
			$im->Write("/tmp/xestiascanserver-preview-" . $randomhex . ".png");
			
			# Delete the PNM file.
			
			unlink("/tmp/xestiascanserver-preview-" . $randomhex . ".pnm");
			
		}
		
	}
	
	my $selectedscandevice;
	
	if (@_){
		
		(%previewoptions) = @_;
		
		$selectedscandevice = $previewoptions{ScannerID};
		
	}
	
	$selectedscandevice = "" if !$selectedscandevice;
	
	# Get the list of available scanners and process the list.
	
	my %scanners;
	tie(%scanners, "Tie::IxHash");
	%scanners = xestiascan_scan_getscannerlist();
	
	# Print out the form.
	
	$main::xestiascan_presmodule->startform("xsdss.cgi", "POST");
	$main::xestiascan_presmodule->addhiddendata("mode", "scan");
	$main::xestiascan_presmodule->addhiddendata("action", "scan");
	$main::xestiascan_presmodule->startbox("scannermenu");
	
	if (!%scanners){
		
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{noscanners});
		$main::xestiascan_presmodule->endbox();
		return $main::xestiascan_presmodule->grab();
		
	}
	
	$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{scanner});
	$main::xestiascan_presmodule->addselectbox("scanner");
	
	my $scannername;
	my $scandevice;
	my $notfirstscanner = 0;
	
	foreach $scandevice (keys %scanners){
	
		# Check if scanner matches the name of the selected
		# scan device.
		
		if ($scanners{$scandevice}{name} eq $selectedscandevice){
			
			$main::xestiascan_presmodule->addoption($scanners{$scandevice}{vendor} . ": ". $scanners{$scandevice}{model}, {Value => $scanners{$scandevice}{name}, Selected => 1});
			
		} else {
		
			$main::xestiascan_presmodule->addoption($scanners{$scandevice}{vendor} . ": ". $scanners{$scandevice}{model}, {Value => $scanners{$scandevice}{name}});
		
		}
		
		if ($notfirstscanner ne 1){
		
			$scannername = $scanners{$scandevice}{name};
			$notfirstscanner = 1;
			
		}
		
	}
	
	$main::xestiascan_presmodule->endselectbox();
	
	# Check to see if the user has permission to use this scanner.
	# Otherwise return an error message.
	
	$scannerpermission = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "Scanner", PermissionName => $scannername });

	xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
	xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
	xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
	
	$scannerpermission = 0 if !$scannerpermission;
	
	if ($scannerpermission eq 1){
	
		# The user has permission to use this scanner.
		
		if (!$previewoptions{ScannerID}){
			
			$scan_device = Sane::Device->open($scannername);
			
			xestiascan_error("scannererror", $Sane::STATUS) if $Sane::STATUS;
			
			$picture_resolution = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_RESOLUTION);
			$picture_topleftx = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_TL_X);
			$picture_toplefty = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_TL_Y);
			$picture_bottomrightx = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_BR_X);
			$picture_bottomrighty = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_BR_Y);		

		} else {
			
			$scan_device = Sane::Device->open($previewoptions{ScannerID}) if !$scan_device;
			
			$picture_resolution = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_RESOLUTION);
			$picture_topleftx = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_TL_X);
			$picture_toplefty = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_TL_Y);
			$picture_bottomrightx = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_BR_X);
			$picture_bottomrighty = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_BR_Y);
			
		}
			
		$main::xestiascan_presmodule->addtext(" | ");
		$main::xestiascan_presmodule->addbutton("switch", { Value => "switched", Description => $main::xestiascan_lang{scan}{switchscanner} });
		
		$main::xestiascan_presmodule->addtext(" | ");
		
		if ($previewdocument eq "on"){
			$main::xestiascan_presmodule->addcheckbox("previewdocument", { OptionDescription => $main::xestiascan_lang{scan}{previewdocument}, Checked => 1 });
		} else {
			$main::xestiascan_presmodule->addcheckbox("previewdocument", { OptionDescription => $main::xestiascan_lang{scan}{previewdocument} });
		}
		
		$main::xestiascan_presmodule->addtext(" | ");
		$main::xestiascan_presmodule->addsubmit($main::xestiascan_lang{scan}{startscanning});
		$main::xestiascan_presmodule->endbox();
		
		if ($previewdocument eq "on"){
			
			$main::xestiascan_presmodule->startbox("sectionbox");
			$main::xestiascan_presmodule->startbox("sectiontitle");
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{documentpreview});
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->startbox("secondbox");
			$main::xestiascan_presmodule->addimage("xsdss.cgi?mode=scan&action=getpreviewimage&pictureid=" . $randomhex);
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->endbox();
			
		}
		
		$main::xestiascan_presmodule->startbox("sectionbox");
		$main::xestiascan_presmodule->startbox("sectiontitle");
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{documentsettings});
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->startbox("secondbox");
		
		$main::xestiascan_presmodule->addboldtext($main::xestiascan_lang{scan}{picturedimensions});
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{topleftx});
		$main::xestiascan_presmodule->addinputbox("topleftx", { MaxLength => "5", Size => "5", ZeroInteger => 1, Value => $picture_topleftx });
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{mm});
		$main::xestiascan_presmodule->addlinebreak();
		
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{toplefty});
		$main::xestiascan_presmodule->addinputbox("toplefty", { MaxLength => "5", Size => "5", ZeroInteger => 1,  Value => $picture_toplefty });
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{mm});
		$main::xestiascan_presmodule->addlinebreak();
		
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{bottomrightx});
		$main::xestiascan_presmodule->addinputbox("bottomrightx", { MaxLength => "5", Size => "5", ZeroInteger => 1, Value => $picture_bottomrightx });
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{mm});
		$main::xestiascan_presmodule->addlinebreak();
		
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{bottomrighty});
		$main::xestiascan_presmodule->addinputbox("bottomrighty", { MaxLength => "5", Size => "5", ZeroInteger => 1, Value => $picture_bottomrighty });
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{mm});
		$main::xestiascan_presmodule->addlinebreak();
		
		$main::xestiascan_presmodule->addhorizontalline();
		
		$main::xestiascan_presmodule->addboldtext($main::xestiascan_lang{scan}{picturesettings});
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{pictureresolution});
		$main::xestiascan_presmodule->addinputbox("imagedpi", { MaxLength => "4", Size => "4", Value => $picture_resolution});
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{dpi});
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{rotate});
		$main::xestiascan_presmodule->addselectbox("rotate");
		
		if ($previewoptions{Rotate}){
			
			# If the value matches with one of these in the list then
			# set that as the selected value.
			
			if ($previewoptions{Rotate} eq "0deg"){
				
				$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{r0deg}, { Value => "0deg", Selected => 1 });
				
			} else {
				
				$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{r0deg}, { Value => "0deg" });
				
			}
			
			if ($previewoptions{Rotate} eq "90deg"){
				
				$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{r90deg}, { Value => "90deg", Selected => 1 });
				
			} else {
				
				$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{r90deg}, { Value => "90deg" });
				
			}
			
			if ($previewoptions{Rotate} eq "180deg"){
				
				$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{r180deg}, { Value => "180deg", Selected => 1 });
				
			} else {
				
				$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{r180deg}, { Value => "180deg" });
				
			}
			
			if ($previewoptions{Rotate} eq "270deg"){
				
				$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{r270deg}, { Value => "270deg", Selected => 1 });
				
			} else {
				
				$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{r270deg}, { Value => "270deg" });
				
			}
			
			
			
		} else {
			
			$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{r0deg}, { Value => "0deg", Selected => 1 });
			$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{r90deg}, { Value => "90deg" });
			$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{r180deg}, { Value => "180deg" });
			$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{r270deg}, { Value => "270deg" });
			
		}
		
		$main::xestiascan_presmodule->endselectbox();
		$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{brightness});
		$main::xestiascan_presmodule->addinputbox("brightness", { MaxLength => "3", Size => "3", Value => $picture_brightness });
		$main::xestiascan_presmodule->addtext("%");
		$main::xestiascan_presmodule->addlinebreak();
		#$main::xestiascan_presmodule->addtext("Contrast: ");
		#$main::xestiascan_presmodule->addinputbox("contrast", { MaxLength => "3", Size => "3", Value => $picture_contrast })#;
		#$main::xestiascan_presmodule->addtext("%");
		#$main::xestiascan_presmodule->addlinebreak();
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{colour});
		$main::xestiascan_presmodule->addselectbox("colourtype");
		
		if (!$previewoptions{Colour} || $previewoptions{Colour} eq "rgb"){
			
			$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{colourrgb}, { Value => "rgb", Selected => 1 });
			
		} else {
			
			$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{colourrgb}, { Value => "rgb" });
			
		}
		
		if ($previewoptions{Colour} && $previewoptions{Colour} eq "grey"){
			
			$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{grey}, { Value => "grey", Selected => 1 });
			
		} else {
			
			$main::xestiascan_presmodule->addoption($main::xestiascan_lang{scan}{grey}, { Value => "grey" });
			
		}
		
		$main::xestiascan_presmodule->endselectbox();
		
		
		$main::xestiascan_presmodule->addlinebreak();
		
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->endbox();
		
		$main::xestiascan_presmodule->endform();
		
	} else {
	
		# The user does not have permission to use this scanner.
		
		$main::xestiascan_presmodule->addtext(" | ");
		$main::xestiascan_presmodule->addbutton("switch", { Value => "switched", Description => $main::xestiascan_lang{scan}{switchscanner} });
		$main::xestiascan_presmodule->endbox();
		
		$main::xestiascan_presmodule->startbox("errorsectionbox");
		$main::xestiascan_presmodule->startbox("errorboxheader");
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{error});
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->startbox("errorbox");
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{scannerpermissioninvalid});
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->endbox();
		
	}
	
	return $main::xestiascan_presmodule->grab();
	
}

sub xestiascan_scan_final{
#################################################################################
# xestiascan_scan_final: Get the final image and present a list of available	#
#			 options.						#
#										#
# Usage:									#
#										#
# xestiascan_scan_final(confirm, pageoptions);					#
#										#
# confirm		Specifies to confirm the processing of the page.	#
# pageoptions		Specifies the options for the page.			#
#################################################################################
	
	# Get the variables passed to the subroutine.
	
	my $confirm	= shift;
	
	if (!$confirm){
	
		# The confirm value is not set so set it to 0.
		
		$confirm = 0;
	
	}
	
	my (%previewoptions) = @_;
	
	# Check if the user has permission to use the scanner
	# and return an error if this is not the case.
	
	my $scannerpermission = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "Scanner", PermissionName => $previewoptions{ScannerID} });
	
	xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
	xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
	xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
	
	$scannerpermission = 0 if !$scannerpermission;
	
	if ($scannerpermission ne 1 && !$previewoptions{OutputFormat}){
	
		# The user does not have permission to use this scanner,
		# so return an error message.
		
		$main::xestiascan_presmodule->startbox("errorsectionbox");
		$main::xestiascan_presmodule->startbox("errorboxheader");
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{error});
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->startbox("errorbox");
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{scannerpermissioninvalid});
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->endbox();
		
		return $main::xestiascan_presmodule->grab();
		
	}
	
	if ($confirm eq 1){
	
		# The action to process the page has been confirmed so process the image.
		
		# Convert the PNM image into the correct format.
		
		my $outputmodule = $previewoptions{OutputFormat};
		my $hexnumber = int($previewoptions{ImageHex});
		
		# Check if the output module has a valid name.
		
		my $outputmodulevalid = xestiascan_variablecheck($previewoptions{OutputFormat}, "module", 0, 1);
		
		if ($outputmodulevalid eq 1){
		
			# The output module is missing so write a message saying
			# the name is invalid.
			
			$main::xestiascan_presmodule->startbox("errorsectionbox");
			$main::xestiascan_presmodule->startbox("errorboxheader");
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{error});
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->startbox("errorbox");
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{outputmoduleinvalidname});
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->endbox();
			
			return $main::xestiascan_presmodule->grab();
			
		}
		
		# Check if the module exists.
		
		my $outputmoduleexists = xestiascan_fileexists("Modules/Output/" . $previewoptions{OutputFormat} . ".pm");
		
		if ($outputmoduleexists eq 1){
		
			# The output module is missing so write a message saying
			# it does not exist.
			
			$main::xestiascan_presmodule->startbox("errorsectionbox");
			$main::xestiascan_presmodule->startbox("errorboxheader");
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{error});
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->startbox("errorbox");
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{outputmodulemissing});
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->endbox();			
			
			return $main::xestiascan_presmodule->grab();
			
		}
		
		# Check if the module has valid file permissions.
		
		my $outputmodulefilepermission = xestiascan_filepermissions("Modules/Output/" . $previewoptions{OutputFormat} . ".pm", 1, 0, 0);
		
		if ($outputmodulefilepermission eq 1){
		
			# The output module has invalid file permissions so
			# write a message.
			
			$main::xestiascan_presmodule->startbox("errorsectionbox");
			$main::xestiascan_presmodule->startbox("errorboxheader");
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{error});
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->startbox("errorbox");
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{outputmoduleinvalidfilepermissions});
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->endbox();			
			
			return $main::xestiascan_presmodule->grab();			
			
		}
		
		# Check to see if the user has permission to use the output module and return an error if not.
		
		my $outputmodulepermission = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "OutputModule", PermissionName => $outputmodule });

		xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
		xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
		xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
		
		$outputmodulepermission = 0 if !$outputmodulepermission;
		
		if ($outputmodulepermission eq 0){
		
			# The user does not have permission so write an error message
			# saying the user does not have permission.
			
			$main::xestiascan_presmodule->startbox("errorsectionbox");
			$main::xestiascan_presmodule->startbox("errorboxheader");
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{error});
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->startbox("errorbox");
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{outputmoduleinvaliddbpermissions});
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->endbox();			
			
			return $main::xestiascan_presmodule->grab();
			
		}
		
		my $outputmodulename = "Modules::Output::" . $outputmodule;
		eval "use " . $outputmodulename;
		my $xestiascan_outputmodule = $outputmodulename->new();
		my ($outputmodule_options, %outputmodule_options);
		tie(%outputmodule_options, "Tie::IxHash");
		$xestiascan_outputmodule->initialise();
		$xestiascan_outputmodule->loadsettings($main::xestiascan_config{"system_language"});
		%outputmodule_options = $xestiascan_outputmodule->getoptions();
		my $option_name;
		my $outputmodule_selected = 0;
		my $outputmodule_readonly = 0;
		my $combobox_count = 0;
		my @outputmodule_comboboxnames;
		my @outputmodule_comboboxvalues;
		my $outputmodule_comboboxname;
		my $outputmodule_comboboxvalue;
		
		# Setup the original filename.
		
		my $original_filename = "";
		my $processed_filename = "";
		
		# Get the output module settings.
		
		my ($outputmodule_passedoptions, %outputmodule_passedoptions);
		my %outputmodulesettings;
		my %outputmodulesettings_final;
		tie(%outputmodule_passedoptions, "Tie::IxHash");
		
		my $hs = new Hash::Search;
		my $cgilite = new CGI::Lite;
		my %form_data = $cgilite->parse_form_data;
		
		$hs->hash_search("^outputmodule_", %form_data);
		%outputmodulesettings = $hs->hash_search_resultdata;
		
		# Strip the outputmodule_ prefix.
		
		my $outputmodule_settings_unprocessed;
		my $outputmodule_settings_regex;
		
		foreach $outputmodule_settings_unprocessed (keys %outputmodulesettings){
		
			$outputmodule_settings_regex = "^outputmodule_";
			$outputmodule_settings_unprocessed =~ s/^$outputmodule_settings_regex//;
			
			$outputmodulesettings_final{$outputmodule_settings_unprocessed} = $outputmodulesettings{"outputmodule_" . $outputmodule_settings_unprocessed};
			
		}
		
		# Proceed with the output module processing.
		
		$main::xestiascan_presmodule->startbox("sectionboxnofloat");
		$main::xestiascan_presmodule->startbox("sectiontitle");
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{outputmoduleresults});
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->startbox("secondbox");
		
		$main::xestiascan_presmodule->startbox("outputmoduletitle");
		$main::xestiascan_presmodule->addtext(xestiascan_language($main::xestiascan_lang{scan}{resultsuffix}, $outputmodule));
		$main::xestiascan_presmodule->endbox();

		$processed_filename = $xestiascan_outputmodule->processimage($hexnumber, %outputmodulesettings_final);
		
		$main::xestiascan_presmodule->startbox("outputmoduleoptions");

		if ($xestiascan_outputmodule->errorflag ne 0){
			
			# An error occurred so stop processing and end the script.
			
			$main::xestiascan_presmodule->addtext(xestiascan_language($main::xestiascan_lang{scan}{outputmodulefailed}, $xestiascan_outputmodule->errormessage));
			$main::xestiascan_presmodule->addlinebreak();
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{outputmoduleunable});
			$main::xestiascan_presmodule->endbox();
			
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->endbox();
			
			return $main::xestiascan_presmodule->grab();
			
		} else {
		
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{outputmodulecomplete});
			
		}
		
		$main::xestiascan_presmodule->endbox();
		
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->endbox();
		
		# Process the selected export modules.
		
		$main::xestiascan_presmodule->startbox("sectionboxnofloat");
		$main::xestiascan_presmodule->startbox("sectiontitle");
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{exportmoduleresults});
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->startbox("secondbox");
		
		# Check the list of selected export modules.
		
		my (%selectedmodules, $selectedmodules);
		
		my (%exportmodulesettings, $exportmodulesettings);
		my (%exportmodulesettings_final);
		
		$hs->hash_search("^module_", %form_data);
		%selectedmodules = $hs->hash_search_resultdata;
		
		my $exportmodule_count = 0;
		my $exportmodule_name = "";
		my $exportmodule_unprocessed = "";
		
		my $exportmodule_settings_unprocessed = "";
		my $exportmodule_settings_regex = "";
		
		my @activemodules;
		
		foreach $exportmodule_unprocessed (keys %selectedmodules){
		
			# Skip if the module wasn't selected in the first place.
			
			next if $selectedmodules{$exportmodule_unprocessed} ne "on";
			
			# Add the module to the selected modules list.
			
			$exportmodule_unprocessed =~ s/^module_//;
			push(@activemodules, $exportmodule_unprocessed);
			$exportmodule_count++;
			
		}
		
		@activemodules = sort(@activemodules);
		
		# Process the export modules.
		
		foreach $exportmodule_name (@activemodules){

			# Write the beginning part of the box for the results of the module.
			
			$main::xestiascan_presmodule->startbox("exportmoduletitle");
			$main::xestiascan_presmodule->addtext(xestiascan_language($main::xestiascan_lang{scan}{resultsuffix}, $exportmodule_name));
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->startbox("exportmoduleoptions");
			
			# Check to see if the export module exists and process the next
			# one if this is not the case.
			
			my $exportmodulecheck = xestiascan_variablecheck($exportmodule_name, "module", 0, 1);
			
			if ($exportmodulecheck eq 1){
			
				# The export module name given is invalid. Skip and
				# process the next one.
				
				$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{exportmoduleinvalidname});
				$main::xestiascan_presmodule->endbox();
				
				next;
				
			}
			
			my $exportmoduleexists = xestiascan_fileexists("Modules/Export/" . $exportmodule_name . ".pm");
			
			if ($exportmoduleexists eq 1){
				
				# The export moudle with the name given is missing.
				# Skip and process the next one.
				
				$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{exportmodulemissing});
				$main::xestiascan_presmodule->endbox();
				
				next;
				
				
			}
			
			my $exportmodulefilepermission = xestiascan_filepermissions("Modules/Export/" . $exportmodule_name . ".pm");
			
			if ($exportmodulefilepermission eq 1){
			
				# The export module with the name given has invalid
				# file permissions.
				
				$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{exportmodulemissing});
				$main::xestiascan_presmodule->endbox();
				
				next;				
				
			}
			
			# Check if the user has permission to use this export
			# module and write a message if not.
			
			my $exportmodulepermission = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "ExportModule", PermissionName => $exportmodule_name });

			xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
			xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
			xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
			
			$exportmodulepermission = 0 if !$exportmodulepermission;
			
			if ($exportmodulepermission eq 0){
			
				# The user does not have permission to use this export
				# module so write a message.
				
				$main::xestiascan_presmodule->addtext($main::xestiascan_lang{error}{exportmoduleinvaliddbpermissions});
				$main::xestiascan_presmodule->endbox();
				
				next;
				
			}
			
			# Get the module settings.
			
			my ($exportmodule_options, %exportmodule_options);
			tie(%exportmodule_options, "Tie::IxHash");
			
			$hs->hash_search("^exportmodule_" . $exportmodule_name . "_", %form_data);
			%exportmodulesettings = $hs->hash_search_resultdata;
			
			# Strip the module settings.
			
			foreach $exportmodule_settings_unprocessed (keys %exportmodulesettings){
				
				$exportmodule_settings_regex = "^exportmodule_" . $exportmodule_name . "_";
				$exportmodule_settings_unprocessed =~ s/^$exportmodule_settings_regex//;
				
				$exportmodule_options{$exportmodule_settings_unprocessed} = $exportmodulesettings{"exportmodule_" . $exportmodule_name . "_" . $exportmodule_settings_unprocessed};
				
			}
			
			# Load the export module.
			
			my $exportmodulename = "Modules::Export::" . $exportmodule_name;
			eval "use " . $exportmodulename;
			my $xestiascan_exportmodule = $exportmodulename->new();
			
			$xestiascan_exportmodule->initialise();
			$xestiascan_exportmodule->loadsettings($main::xestiascan_config{"system_language"});
			
			# Process the outputted file.
			
			$xestiascan_exportmodule->exportimage($processed_filename, $main::xestiascan_config{"directory_noncgi_scans"}, $main::xestiascan_config{"directory_fs_scans"}, %exportmodule_options);
			
			# Check if an error occured.
			
			$main::xestiascan_presmodule->addhorizontalline();
			
			if ($xestiascan_exportmodule->errorflag ne 0){
				
				$main::xestiascan_presmodule->addtext(xestiascan_language($main::xestiascan_lang{scan}{exportmodulefailed}, $xestiascan_exportmodule->errormessage));
				
			} else {
		
				$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{exportmodulecomplete});
				
			}
			
			# Delete the export module.
			
			undef($xestiascan_exportmodule);
			
			# Finish the results box for this export module.
			
			$main::xestiascan_presmodule->endbox();
		
		}
		
		if (!@activemodules){
		
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{noexportmoduleselected});
			
		}
		
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->endbox();		
		
	} else {
	
		my $randomhex = 0;
		
		if ($previewoptions{Switched} eq "no"){
		
			# Get the image, generate a random number, write the file as PNM and display
			# some options for the scanned image.
			
			# Brightness.
			
			xestiascan_error("brightnessblank") if !$previewoptions{Brightness};
			my $brightness_numberscheck = xestiascan_variablecheck($previewoptions{Brightness}, "numbers", 0, 1);
			xestiascan_error("brightnessinvalidnumber") if $brightness_numberscheck eq 1;
			
			# Rotate. (Should be either 0, 90, 180, 270 degrees).
			
			xestiascan_error("rotateblank") if !$previewoptions{Rotate};
			if ($previewoptions{Rotate} eq "0deg" || $previewoptions{Rotate} eq "90deg" || $previewoptions{Rotate} eq "180deg" || $previewoptions{Rotate} eq "270deg"){
				
			} else {
				
				xestiascan_error("rotateinvalidoption");
				
			}
			
			# Colour.
			
			xestiascan_error("colourblank") if !$previewoptions{Colour};
			if ($previewoptions{Colour} eq "rgb" || $previewoptions{Colour} eq "grey" ){
				
			} else {
				
				xestiascan_error("colourinvalidoption");
				
			}
			
			# Resolution.
			
			xestiascan_error("resolutionblank") if !defined($previewoptions{Resolution});
			my $resolution_numberscheck = xestiascan_variablecheck($previewoptions{Resolution}, "numbers", 0, 1);
			xestiascan_error("resolutioninvalidnumber") if $resolution_numberscheck eq 1;
			
			# Top Left X (Pointy figure);
			
			xestiascan_error("topleftxblank") if !defined($previewoptions{TopLeftX});
			my $topleftx_decimalcheck = xestiascan_variablecheck($previewoptions{TopLeftX}, "decimal", 0, 1);
			xestiascan_error("topleftxinvalidnumber") if $topleftx_decimalcheck eq 1;
			
			# Top Left Y (Pointy figure).
			
			xestiascan_error("topleftyblank") if !defined($previewoptions{TopLeftY});
			my $toplefty_decimalcheck = xestiascan_variablecheck($previewoptions{TopLeftY}, "decimal", 0, 1);
			xestiascan_error("topleftyinvalidnumber") if $toplefty_decimalcheck eq 1;		
			
			# Bottom Right X (Pointy figure).
			
			xestiascan_error("bottomrightx") if !defined($previewoptions{BottomRightX});
			my $bottomrightx_decimalcheck = xestiascan_variablecheck($previewoptions{BottomRightX}, "decimal", 0, 1);
			xestiascan_error("bottomrightxinvalidnumber") if $bottomrightx_decimalcheck eq 1;
			
			# Bottom Right Y (Pointy figure).
			
			xestiascan_error("bottomrighty") if !defined($previewoptions{BottomRightY});
			my $bottomrighty_decimalcheck = xestiascan_variablecheck($previewoptions{BottomRightY}, "decimal", 0, 1);
			xestiascan_error("bottomrightyinvalidnumber") if $bottomrighty_decimalcheck eq 1;
			
			# Generate a random hex value and use this to write a temporary file.
			
			$randomhex = 0;
			
			if (!$previewoptions{ImageHex}){
			
				$randomhex = hex(int(rand(16777216)));
			
				# Set variables for scanner.
			
				$scan_device = Sane::Device->open($previewoptions{ScannerID});
			
				xestiascan_scan_setscannervalue(SANE_NAME_SCAN_RESOLUTION, $previewoptions{Resolution});
				xestiascan_scan_setscannervalue(SANE_NAME_SCAN_TL_X, $previewoptions{TopLeftX});
				xestiascan_scan_setscannervalue(SANE_NAME_SCAN_TL_Y, $previewoptions{TopLeftY});
				xestiascan_scan_setscannervalue(SANE_NAME_SCAN_BR_X, $previewoptions{BottomRightX});
				xestiascan_scan_setscannervalue(SANE_NAME_SCAN_BR_Y, $previewoptions{BottomRightY});
			
				# Get Sane to scan based on what has been passed (scanner name).
			
				if ($Sane::STATUS == SANE_STATUS_GOOD){
					$scan_device->start;
				}
			
				my $param = $scan_device->get_parameters;
				my $fh;
				open ($fh, '>', "/tmp/xestiascanserver-preview-" . $randomhex . ".pnm") or die("error: $!");
				$scan_device->write_pnm_header($fh, $param->{format}, 
				$param->{pixels_per_line},
				$param->{lines}, $param->{depth});
				my ($data, $len);
				do{ 
					($data, $len) = $scan_device->read ($param->{bytes_per_line});
					print $fh $data if $data;
				} until ($Sane::STATUS == SANE_STATUS_EOF);
				close ($fh);
			
				# Get the current scanner values.
				
				my $picture_resolution = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_RESOLUTION);
				my $picture_topleftx = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_TL_X);
				my $picture_toplefty = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_TL_Y);
				my $picture_bottomrightx = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_BR_X);
				my $picture_bottomrighty = xestiascan_scan_getscannervalue(SANE_NAME_SCAN_BR_Y);
				
				$picture_topleftx = int(0) if $picture_topleftx eq 0;
				
				# Convert the PNM based image into PNG format.
				
				my $im = new Image::Magick;
				$im->Read("/tmp/xestiascanserver-preview-" . $randomhex . ".pnm");
				
				# Rotate the document if needed.
				
				my $rotate = $previewoptions{Rotate};
				my $numrotate = 0;
				my $numrotateseek = 0;
				
				if ($previewoptions{Rotate} ne "0deg" ){
					$numrotate = 1 if $rotate eq "90deg";
					$numrotate = 2 if $rotate eq "180deg";
					$numrotate = 3 if $rotate eq "270deg";
					
					do {
						$im->Rotate();
						$numrotateseek++;
					} until ($numrotateseek eq $numrotate || $numrotateseek > $numrotate);
					
				}
				
				# Change the colour type of the document if needed.
				
				if ($previewoptions{Colour} eq "rgb"){
					
					# Set the document to colour.
					
					$im->Quantize(colorspace => 'RGB');
					
				} elsif ($previewoptions{Colour} eq "grey"){
					
					# Set the document to greyscale.
					
					$im->Quantize(colorspace =>'gray');
					
				}
				
				# Adjust the brightness.
				
				xestiascan_error("brightnessblank") if !$previewoptions{Brightness};
				
				my $brightness_numberscheck = xestiascan_variablecheck($previewoptions{Brightness}, "numbers", 0, 1);
				xestiascan_error("brightnessinvalidnumber") if $brightness_numberscheck eq 1;
				
				my $picture_brightness = $previewoptions{Brightness};
				$im->Modulate( brightness=> $picture_brightness );
				
				$im->Write("/tmp/xestiascanserver-preview-" . $randomhex . ".pnm");
				
				$im->Minify;
				
				$im->Write("/tmp/xestiascanserver-preview-" . $randomhex . ".png");

			} else {
			
				$randomhex = $previewoptions{ImageHex};
				
			}
			
		} else {
			
			$randomhex = $previewoptions{ImageHex};
			
		}
		
		my ($outputmodule, $outputmodulesname, $exportmodule);
		
		# Get the output modules.
		
		my @outputmodules = xestiascan_scan_getoutputmodules;
		$outputmodule = $previewoptions{OutputFormat} if $previewoptions{OutputFormat};
		
		# Get the export modules.
		
		my @exportmodules = xestiascan_scan_getexportmodules;
		
		$main::xestiascan_presmodule->startform("xsdss.cgi", "GET");
		$main::xestiascan_presmodule->addhiddendata("mode", "scan");
		$main::xestiascan_presmodule->addhiddendata("action", "scan");
		$main::xestiascan_presmodule->addhiddendata("confirm", "1");
		$main::xestiascan_presmodule->addhiddendata("imagehex", $randomhex);
		
		$main::xestiascan_presmodule->startbox("sectionboxnofloat");
		$main::xestiascan_presmodule->startbox("sectiontitle");
		
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{imagepreview});
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->startbox("secondbox, previewimage");
		
		# Get a preview of the image.
		
		$main::xestiascan_presmodule->addimage("xsdss.cgi?mode=scan&action=getpreviewimage&dontclear=1&pictureid=" . $randomhex);
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->endbox();

		$main::xestiascan_presmodule->startbox("sectionboxnofloat");
		$main::xestiascan_presmodule->startbox("sectiontitle");
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{outputformatsettings});
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->startbox("secondbox");
		
		$main::xestiascan_presmodule->startbox("outputmoduletitle");
		
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{outputmodule});
		
		$outputmodule = $main::xestiascan_config{"system_outputmodule"} if !$outputmodule;
		
		if (!@outputmodules){
		
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{noneavailable});
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->startbox("outputmoduleoptions");
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{nooutputmodulesavail});
			$main::xestiascan_presmodule->endbox();
			return $main::xestiascan_presmodule->grab();
			
		} else {
		
			$main::xestiascan_presmodule->addselectbox("outputformat");
			
			foreach $outputmodulesname (@outputmodules){
				if ($outputmodule eq $outputmodulesname){
					$main::xestiascan_presmodule->addoption($outputmodulesname, { Value => $outputmodulesname, Selected => 1 });
				} else {
					$main::xestiascan_presmodule->addoption($outputmodulesname, { Value => $outputmodulesname });
				}
			}
			
			$main::xestiascan_presmodule->endselectbox();
			$main::xestiascan_presmodule->addbutton("formatswitch", { Value => "yes", Description => "Switch Module" });
			
		}
			
		$main::xestiascan_presmodule->endbox();
		
		$outputmodule = $outputmodules[0] if !$outputmodule;
		
		# Check to see if the user has permission to use this
		# output module.
		
		my $outputmodulepermission = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "OutputModule", PermissionName => $outputmodule });

		xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
		xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
		xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
		
		$outputmodulepermission = 0 if !$outputmodulepermission;
		
		# Get the settings for the active output module.
		
		my $option_name;
		my $combobox_count = 0;
		
		my $outputmodulefilepermissions = xestiascan_filepermissions("Modules/Output/" . $outputmodule . ".pm", 1, 0, 0);
		
		if ($outputmodulepermission eq 1 && $outputmodulefilepermissions eq 0){
			
			# Load the output module.
			
			my $outputmodulename = "Modules::Output::" . $outputmodule;
			eval "use " . $outputmodulename;
			my $xestiascan_outputmodule = $outputmodulename->new();
			my ($outputmodule_options, %outputmodule_options);
			tie(%outputmodule_options, "Tie::IxHash");
			$xestiascan_outputmodule->initialise();
			$xestiascan_outputmodule->loadsettings($main::xestiascan_config{"system_language"});
			%outputmodule_options = $xestiascan_outputmodule->getoptions();
			my $outputmodule_selected = 0;
			my $outputmodule_readonly = 0;
			my @outputmodule_comboboxnames;
			my @outputmodule_comboboxvalues;
			my $outputmodule_comboboxname;
			my $outputmodule_comboboxvalue;
			
			$main::xestiascan_presmodule->startbox("outputmoduleoptions");		
			
			foreach $option_name (keys %outputmodule_options){
				
				# Check if the option is a checkbox option.
				
				if ($outputmodule_options{$option_name}{type} eq "checkbox"){
					
					$main::xestiascan_presmodule->addcheckbox("outputmodule_" . $option_name, { Checked => $outputmodule_options{$option_name}{checked}, OptionDescription => $outputmodule_options{$option_name}{string}, ReadOnly => $outputmodule_readonly });
					
				}
				
				# Check if the option is a string option.
				
				if ($outputmodule_options{$option_name}{type} eq "textbox"){
					
					if (!$outputmodule_options{$option_name}{password}){
						$outputmodule_options{$option_name}{password} = 0;
					}
					
					$main::xestiascan_presmodule->addtext($outputmodule_options{$option_name}{string} . " ");
					$main::xestiascan_presmodule->addinputbox("outputmodule_" . $option_name, { Size => $outputmodule_options{$option_name}{size}, MaxLength => $outputmodule_options->{$option_name}{maxlength}, Value => $outputmodule_options{$option_name}{value}, Password => $outputmodule_options{$option_name}{password}, ReadOnly => $outputmodule_readonly });
					
				}
				
				# Check if the option is a combobox option.
				
				if ($outputmodule_options{$option_name}{type} eq "combobox"){
					
					$combobox_count		= 0;
					
					@outputmodule_comboboxnames = split(/\|/, $outputmodule_options{$option_name}{optionnames});
					@outputmodule_comboboxvalues = split(/\|/, $outputmodule_options{$option_name}{optionvalues});
					
					$main::xestiascan_presmodule->addtext($outputmodule_options{$option_name}{string} . " ");
					$main::xestiascan_presmodule->addselectbox("outputmodule_" . $option_name);
					
					foreach $outputmodule_comboboxname (@outputmodule_comboboxnames){
						
						$main::xestiascan_presmodule->addoption($outputmodule_comboboxname, { Value => $outputmodule_comboboxvalues[$combobox_count], ReadOnly => $outputmodule_readonly });
						$combobox_count++;
						
					}
					
					$main::xestiascan_presmodule->endselectbox;
					
				}
				
				# Check if the option is a radio option.
				
				if ($outputmodule_options{$option_name}{type} eq "radio"){
					
					# Check if the selected value is blank and if it is then
					# set it to 0.
					
					if (!$outputmodule_options{$option_name}{selected}){
						$outputmodule_selected = 0;
					} else {
						$outputmodule_selected = 1;
					}
					
					$main::xestiascan_presmodule->addradiobox("outputmodule_" . $outputmodule_options{$option_name}{name}, { Description => $outputmodule_options{$option_name}{string}, Value => $outputmodule_options{$option_name}{value}, Selected => $outputmodule_selected, ReadOnly => $outputmodule_readonly });
					
				}
				
				$main::xestiascan_presmodule->addlinebreak();
				
			}

			# If there are no options available then write a message
			# to say no options are available for this module.
			
			if (!%outputmodule_options){
			
				$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{nooutputmoduleopts});
				
			}
			
		} elsif ($outputmodulefilepermissions eq 1) {
			
			$main::xestiascan_presmodule->startbox("outputmoduleoptions");
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{outputmoduleinvalidfilepermissions});			
			
		} else {
		
			$main::xestiascan_presmodule->startbox("outputmoduleoptions");
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{outputmoduleinvaliddbpermissions});
			
		}
		
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->endbox();
		
		$main::xestiascan_presmodule->startbox("sectionboxnofloat");
		$main::xestiascan_presmodule->startbox("sectiontitle");
		$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{exportformatsettings});
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->startbox("secondbox");
		
		# Process the list of export modules.
		
		my $exportmodulename;
		my $xestiascan_exportmodule;
		my ($exportmodule_options, %exportmodule_options);
		my $exportmodule_readonly = 0;
		my $exportmodule_selected = 0;
		my @exportmodule_comboboxnames;
		my @exportmodule_comboboxvalues;
		my $exportmodule_comboboxname;
		my $exportmodule_comboboxvalue;
		
		if (!@exportmodules){
		
			$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{noexportmodulesavail});
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->endbox();
			$main::xestiascan_presmodule->endbox();
			return $main::xestiascan_presmodule->grab();
			
		}
		
		my $exportmodulepermission;
		my $exportmodulefilepermission;
		
		foreach $exportmodule (@exportmodules){
			
			# Check to see if the user has permission to use the export
			# module and return an error if this is not the case.
			
			$exportmodulepermission = $main::xestiascan_authmodule->getpermissions({ Username => $main::loggedin_user, PermissionType => "ExportModule", PermissionName => $exportmodule });

			xestiascan_error("usernameblank") if ($main::xestiascan_authmodule->geterror eq "UsernameBlank");
			xestiascan_error("permissiontypeblank") if ($main::xestiascan_authmodule->geterror eq "PermissionTypeBlank");
			xestiascan_error("autherror", $main::xestiascan_authmodule->geterror(1)) if ($main::xestiascan_authmodule->geterror eq "DatabaseError");
			
			$exportmodulepermission = 0 if !$exportmodulepermission;
			
			# Check the file permissions for the export module
			# has been set correctly.
			
			$exportmodulefilepermission = xestiascan_filepermissions("Modules/Export/" . $exportmodule . ".pm", 1, 0, 0);
			
			if ($exportmodulepermission eq 0){
			
				# We don't have permission so write an error message.
				
				$main::xestiascan_presmodule->startbox("exportmoduletitle");
				$main::xestiascan_presmodule->addtext($exportmodule);
				$main::xestiascan_presmodule->endbox();
				
				$main::xestiascan_presmodule->startbox("exportmoduleoptions");
				$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{exportmoduleinvalidfilepermissions});
				$main::xestiascan_presmodule->endbox();
				
				next;
				
			}
			
			if ($exportmodulefilepermission ne 0){
			
				# The file permissions are invalid so write an error message.
				
				$main::xestiascan_presmodule->startbox("exportmoduletitle");
				$main::xestiascan_presmodule->addtext($exportmodule);
				$main::xestiascan_presmodule->endbox();
				
				$main::xestiascan_presmodule->startbox("exportmoduleoptions");
				$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{exportmoduleinvaliddbpermissions});
				$main::xestiascan_presmodule->endbox();
				
				next;
				
			}
			
			# Load the export module.
			
			$exportmodulename = "Modules::Export::" . $exportmodule;
			eval "use " . $exportmodulename;
			$xestiascan_exportmodule = $exportmodulename->new();
			tie(%exportmodule_options, "Tie::IxHash");
			$xestiascan_exportmodule->initialise();
			$xestiascan_exportmodule->loadsettings($main::xestiascan_config{"system_language"});
			%exportmodule_options = $xestiascan_exportmodule->getoptions();
			
			$main::xestiascan_presmodule->startbox("exportmoduletitle");
			$main::xestiascan_presmodule->addcheckbox("module_" . $exportmodule, { OptionDescription => "" });
			$main::xestiascan_presmodule->addtext($exportmodule);
			$main::xestiascan_presmodule->endbox();
			
			$main::xestiascan_presmodule->startbox("exportmoduleoptions");
			foreach $option_name (keys %exportmodule_options){
				
				# Check if the option is a checkbox option.
				
				if ($exportmodule_options{$option_name}{type} eq "checkbox"){
					 
					$main::xestiascan_presmodule->addcheckbox("exportmodule_" . $exportmodule . "_" . $option_name, { Checked => $exportmodule_options{$option_name}{checked}, OptionDescription => $exportmodule_options{$option_name}{string}, ReadOnly => $exportmodule_readonly });
					
				}
				
				# Check if the option is a string option.
				
				if ($exportmodule_options{$option_name}{type} eq "textbox"){
					
					if (!$exportmodule_options{$option_name}{password}){
						$exportmodule_options{$option_name}{password} = 0;
					}
					
					$main::xestiascan_presmodule->addtext($exportmodule_options{$option_name}{string} . " ");
					$main::xestiascan_presmodule->addinputbox("exportmodule_" . $exportmodule . "_" . $option_name, { Size => $exportmodule_options{$option_name}{size}, MaxLength => $exportmodule_options->{$option_name}{maxlength}, Value => $exportmodule_options{$option_name}{value}, Password => $exportmodule_options{$option_name}{password}, ReadOnly => $exportmodule_readonly });
					
				}
				
				# Check if the option is a combobox option.
				
				if ($exportmodule_options{$option_name}{type} eq "combobox"){
					
					$combobox_count		= 0;
					
					@exportmodule_comboboxnames = split(/\|/, $exportmodule_options{$option_name}{optionnames});
					@exportmodule_comboboxvalues = split(/\|/, $exportmodule_options{$option_name}{optionvalues});
					
					$main::xestiascan_presmodule->addtext($exportmodule_options{$option_name}{string} . " ");
					$main::xestiascan_presmodule->addselectbox("exportmodule_" . $exportmodule . "_" . $option_name);
					
					foreach $exportmodule_comboboxname (@exportmodule_comboboxnames){
						
						$main::xestiascan_presmodule->addoption($exportmodule_comboboxname, { Value => $exportmodule_comboboxvalues[$combobox_count], ReadOnly => $exportmodule_readonly });
						$combobox_count++;
						
					}
					
					$main::xestiascan_presmodule->endselectbox;
					
				}
				
				# Check if the option is a radio option.
				
				if ($exportmodule_options{$option_name}{type} eq "radio"){
					
					# Check if the selected value is blank and if it is then
					# set it to 0.
					
					if (!$exportmodule_options{$option_name}{selected}){
						$exportmodule_selected = 0;
					} else {
						$exportmodule_selected = 1;
					}
					
					$main::xestiascan_presmodule->addradiobox("exportmodule_" . $exportmodule . "_" . $exportmodule_options{$option_name}{name}, { Description => $exportmodule_options{$option_name}{string}, Value => $exportmodule_options{$option_name}{value}, Selected => $exportmodule_selected, ReadOnly => $exportmodule_readonly });
					
				}
				
				$main::xestiascan_presmodule->addlinebreak();
				
			}			
			$main::xestiascan_presmodule->endbox();
			
			if (!%exportmodule_options){
				
				$main::xestiascan_presmodule->addtext($main::xestiascan_lang{scan}{noexportmoduleopts});
				
			}
			
			# Delete (free) the export module.
			
			undef($xestiascan_exportmodule);
			
		}
		
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->endbox();
		$main::xestiascan_presmodule->endbox();
		
		$main::xestiascan_presmodule->addsubmit($main::xestiascan_lang{scan}{process});
		$main::xestiascan_presmodule->addreset($main::xestiascan_lang{common}{restoredefault});
		
		$main::xestiascan_presmodule->endform();
		
	}
	
	return $main::xestiascan_presmodule->grab();
	
}


sub xestiascan_scan_getpreviewimage{
#################################################################################
# xestiascan_scan_getpreviewimage: Get the preview image.			#
#										#
# Usage:									#
#										#
# xestiascan_scan_getpreviewimage(previewid);					#
#										#
# previewid		Specifies the picture ID.				#
#################################################################################
	
	# Get the values from the subroutine.
	
	my $pictureid = shift;
	my $dontclear = shift;
	
	if (!$dontclear){
	
		$dontclear = 0;
		
	}
	
	# Return an error message if picture ID is blank.
	
	if (!$pictureid){
	
		xestiascan_error("blankpictureid");
		
	}
	
	xestiascan_error("invalidpictureid") if xestiascan_variablecheck($pictureid, "numbers", 0, 1) eq 1;
	
	print "Content-Type: image/png\r\n\r\n";
	
	binmode(STDOUT, ":bytes");
	
	my $imgfh;
	open($imgfh, "/tmp/xestiascanserver-preview-" . $pictureid . ".png");
	my @lines = <$imgfh>;
	print @lines;
	close ($imgfh);
	
	unlink("/tmp/xestiascanserver-preview-" . $pictureid . ".png") if $dontclear < 1;
	
}	

sub xestiascan_scan_getscannerlist{
#################################################################################
# xestiascan_scan_getscannerlist: Gets the list of available scanners.		#
#										#
# Usage:									#
#										#
# xestiascan_scan_getscannerlist;						#
#################################################################################	
	
	my %scannerlist;
	my $scanner;
	
	tie(%scannerlist, 'Tie::IxHash');
	
	foreach $scanner (Sane->get_devices){
		$scannerlist{$scanner->{'name'}}{name}		= $scanner->{'name'};
		$scannerlist{$scanner->{'name'}}{model}		= $scanner->{'model'};
		$scannerlist{$scanner->{'name'}}{vendor}	= $scanner->{'vendor'};
		#	if ($scanner->{'name'} eq $http_scannerdevice){
		#		print "<option value=\"" . $scanner->{'name'}  . "\" 
		#selected=selected>" . $scanner->{'vendor'} . ": " . $scanner->{'model'} . "</option>";
		#	} else {
		#		print "<option value=\"" . $scanner->{'name'}  . "\">" . 
		#$scanner->{'vendor'} . ": " . $scanner->{'model'} . "</option>";
		#	}
	}
	
	return %scannerlist;
	
}

sub xestiascan_scan_getscannervalue{
#################################################################################
# xestiascan_scan_getscannervalue: Gets a specific option value.		#
#										#
# Usage:									#
#										#
# xestiascan_scan_getscannervalue(name);					#
#										#
# name			Specifies the name of option.				#
#################################################################################
	
	my $option_name = shift;
	
	my $option_value;
	my $option_found = 0;
	my $value = 0;
	
	my $option_total = $scan_device->get_option(0);
	my $option_seek = 0;
	
	my $option;
	
	do {
		
		$option = $scan_device->get_option_descriptor($option_seek);
		
		if (!$option->{name}){
			
		} else {
			
			if ($option_name eq $option->{name}){
				
				if ($option->{type} eq SANE_TYPE_FIXED){
					$value = $scan_device->get_option($option_seek);
					$value = int(0) if !$value;
				} else {
					$value = $scan_device->get_option($option_seek);
				}
				$option_found = 1;
				
			}
			
		}
		
		$option_seek++;
		
	} until ($option_seek > $option_total || $option_found eq 1);

	return $value;
	
}

sub xestiascan_scan_setscannervalue{
#################################################################################
# xestiascan_scan_setscannervalue: Gets a specific option value.		#
#										#
# Usage:									#
#										#
# xestiascan_scan_setscannervalue(name, value);					#
#										#
# name			Specifies the name of the option.			#
# value			Specifies the value of the option.			#
#################################################################################
	
	my $option_name		= shift;
	my $option_value	= shift;
	
	my $option_total = $scan_device->get_option(0);
	my $option_seek = 0;
	
	my $option_found = 0;
	
	my $option_final_value;
	
	my $option;
	
	do {
		
		$option = $scan_device->get_option_descriptor($option_seek);
		
		if ($option_name eq $option->{name}){
			
			if ($option->{type} eq SANE_TYPE_FIXED){

				$scan_device->set_option($option_seek, $option_value) or return;
				
			} else {
			
				$scan_device->set_option($option_seek, $option_value) or return;
				
			}
			
			$option_found = 1;
			
		}
		
		$option_seek++;
		
	} until ($option_seek > $option_total || $option_found eq 1);
	
	return 1;	# Setting set successfully.
	
}

1;