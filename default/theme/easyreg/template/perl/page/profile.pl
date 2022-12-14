#!/usr/bin/perl -T

use strict;
use warnings;

sub GetProfileDialog {
	my $profileWindowContents = GetTemplate('html/form/profile.template');

	my $profileWindow = GetWindowTemplate(
		$profileWindowContents,
		'Profile',
	);

	return $profileWindow;
} # GetProfileDialog()

sub GetProfilePage { # returns profile page (allows sign in/out)
	#not the author page

	#called by page.pl
	my $txtIndex = "";
	my $title = "Profile";
	my $titleHtml = "Profile";

	if (GetConfig('admin/js/enable') || GetConfig('admin/php/enable')) {
		# js or php is required for profiles to work

		$txtIndex = GetPageHeader('identity');
		$txtIndex .= GetTemplate('html/maincontent.template');

		my $profileWindow = GetProfileDialog();
		$txtIndex .= $profileWindow;

		$txtIndex .= GetPageFooter('identity');

		if (GetConfig('admin/js/enable')) {
			$txtIndex = InjectJs($txtIndex, qw(avatar settings utils profile timestamp write puzzle voting easy_register));
			$txtIndex = AddAttributeToTag(
				$txtIndex,
				'input id=btnEasyRegister',
				'onclick',
				'if (window.EasyRegister) { return EasyRegister(this); }'
			);
		} else {
			# js is disabled
		}
	}

	return $txtIndex;
} # GetProfilePage()

1;