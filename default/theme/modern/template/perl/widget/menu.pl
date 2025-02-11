#!/usr/bin/perl -T

use strict;
use warnings;
use 5.010;
use utf8;

sub GetMenuFromList { # $listName, $templateName = 'html/menuitem.template', $pageType ; returns html menu based on referenced list
# $listName is reference to a list in config/list, e.g. config/list/menu
# $separator is what is inserted between menu items
# sub GetMenuList {
# sub GetPageMenu {
# sub GetMenu {
# sub GetMenuBar {
	my $listName = shift;
	chomp $listName;
	if (!$listName) {
		WriteLog('GetMenuFromList: modern: warning: $listName failed sanity check');
		return;
	}

	my $templateName = shift;
	if (!$templateName) {
		$templateName = 'html/menuitem.template';
	}
	chomp $templateName;

	my $pageType = shift; # which menu item is selected
	if (!$pageType) {
		$pageType = '';
	}

	WriteLog('GetMenuFromList: modern: $listName = ' . $listName . ', $templateName = ' . $templateName . '; caller = ' . join(',', caller));

	my $listText = GetTemplate('list/' . $listName);

	if (index($listText, "\r") != -1) {
		WriteLog('GetMenuFromList: warning: $listText contains carriage return(s), replacing with newline(s); caller = ' . join(',', caller));
		$listText = str_replace("\r", "\n", $listText);
	}

	$listText = str_replace("\r", "\n", $listText); # this shouldn't really be necessary, since it is covered by the sanity check above
	$listText = str_replace("\n\n", "\n", $listText);

	#WriteLog('GetMenuFromList: $listText = ' . $listText);

	my @menuList = split("\n", $listText);

	if (GetConfig('admin/expo_site_mode') && GetConfig('admin/expo_site_edit')) { #todo
		push @menuList, GetSystemMenuList();
	}

	my $menuItems = ''; # output html which will be returned
	my $menuComma = '';

	my @menuSkip;

	if ($listName eq 'menu') {
		# for main menu, hide menu items for features which are not available #hack
		if (!GetConfig('admin/js/enable') || !GetConfig('admin/php/enable')) { #todo profile/enable
			push @menuSkip, 'profile';
		}
		if (!GetConfig('admin/upload/enable')) {
			push @menuSkip, 'upload';
		}
	} else {
		WriteLog('GetMenuFromList: ' . $listName . ' ne ' . 'menu');
	}

	WriteLog('GetMenuFromList: scalar(@menuSkip) = ' . scalar(@menuSkip));

	foreach my $menuItem (@menuList) {
		my $menuItemName = $menuItem;

		if (in_array($menuItemName, @menuSkip)) {
			WriteLog('GetMenuFromList: ' . $listName . ': ' . $menuItemName . ' was found in @menuSkip');
			next;
		} else {
			WriteLog('GetMenuFromList: ' . $listName . ': ' . $menuItemName . ' NOT in @menuSkip, continuing');
		}

		if ($menuItemName) {
			# note, /tag/FooTag.html and /tag/FooLabel.html are automatic
			my $menuItemUrl = '/' . $menuItemName . '.html';

			if (GetConfig('setting/html/menu_expand_address')) {
				if (substr($menuItemName, 0, 1) eq '#') {
					# special case
					$menuItemUrl = '/label/' . substr($menuItemName, 1) . '.html';
				} else {
					#default
					# $menuItemUrl = '/' . $menuItemName . '.html';
				}
			} # if (GetConfig('setting/html/menu_expand_address'))

			# capitalize caption
			my $menuItemCaption = uc(substr($menuItemName, 0, 1)) . substr($menuItemName, 1);

			if ($listName eq 'menu_tag') {
				#deprecated
				$menuItemUrl = '/tag/' . $menuItemName . '.html';
				$menuItemCaption = '#' . $menuItemName;
			}

			my $boolExtUrl = 0;

			if (GetConfig('admin/expo_site_mode')) {
				#deprecated, used for mitbtc theme

				#this avoids creating duplicate urls but currently breaks light mode
				if ($menuItemName eq 'home') {
					$menuItemUrl = '/';
				}

				# add menu item to output

				if (GetString("menu/$menuItem")) {
					$menuItemCaption = GetString("menu/$menuItem");
				}

				if ($menuItem eq 'register') {
					$boolExtUrl = 1;
					$menuItemUrl = 'https://tinyurl.com/4ezdhdk';
				}

				if ($menuItem eq 'hackathon') {
					$boolExtUrl = 1;
					$menuItemUrl = 'https://mit-bitcoin-expo-hackathon.devfolio.co/';
					# $menuItemUrl = 'https://forms.gle/JUvaggfVCNS8P54G7';
				}

				if ($menuItem eq 'mailinglist') {
					$boolExtUrl = 1;
					$menuItemUrl = 'https://eepurl.com/gOVdKb';

				}

				if ($menuItem eq 'priorexpo') {
					$boolExtUrl = 1;
					$menuItemUrl = '/flashback_2020/';
				}
			} # if (GetConfig('admin/expo_site_mode'))

			if (GetString("menu/$menuItem")) {
				# change displayed name if a string is available
				$menuItemCaption = GetString("menu/$menuItem");
			}

			$menuItemCaption = ucfirst($menuItemCaption);

			# this separator is inserted BEFORE the menu entry
			if ($menuComma) {
				if ($menuItem eq '-200') {
					# don't add separator
					#special hack for bash theme
				}
				else {
					$menuItems .= $menuComma;
				}
			} else {
				$menuComma = GetTemplate('html/menu_separator.template'); # ' ; '
				# $menuComma = $menuComma . ' ; ';
				# $menuComma .= ' ; ';
				# menu separator
			}

			if (index($menuItemUrl, "\r") != -1 || index($menuItemCaption, "\r") != -1 || index($templateName, "\r") != -1) {
				# sanity check
				WriteLog('GetMenuFromList: warning: $menuItemUrl or $menuItemCaption or $templateName failed sanity check; caller = ' . join(',', caller));
				return '';
			}

			my $menuItemComposed = GetMenuItem($menuItemUrl, $menuItemCaption, $templateName);
			WriteLog('GetMenuFromList: checking for $menuItemName eq $pageType: ' . $menuItemName . ', ' . $pageType . '; caller = ' . join(',', caller));
			if ($menuItemName eq $pageType) {
				if (GetConfig('setting/html/css/enable') && GetConfig('setting/html/menu_highlight_selected')) {
					#todo should be under css/
					## menu item is for current page
					$menuItemComposed = '<span style="background-color: ' . GetThemeColor('highlight_ready') . ';">' . $menuItemComposed . '</span>';
					#todo $menuItemComposed = '<span style="border: dotted 2pt gray; background-color: ' . GetThemeColor('highlight_ready') . ';">' . $menuItemComposed . '</span>';
					#todo add a class=selected
					#$menuItemComposed = '<span style="font-variant: small-caps; background-color: ' . GetThemeColor('highlight_ready') . ';">' . $menuItemComposed . '</span>';
				}
			}
			$menuItems .= $menuItemComposed;
			if (0 && $boolExtUrl) {
				#mark the url as external #todo
			}

			if (GetConfig('admin/expo_site_mode')) {
				$menuItems .= ' &nbsp; ';
			}
		} # if ($menuItemName)
	} # foreach my $menuItem (@menuList)

	# return template we've built
	return $menuItems;
} # GetMenuFromList()

sub GetMenuTemplate { # $pageType ; returns menubar
# $pageType is the name of the current page, e.g. 'read'
# sub GetMenuDialog {
# sub GetMenubarTemplate {
# sub GetMenubar {
# sub GetMenuBar {
# sub GetTopMenu {
# sub GetMenu {
	my $topMenuTemplate = GetTemplate('html/menu_top.template');
	my $title = 'Welcome Modern Theme';
	my $status = '';

	my $pageType = shift;
	if (!$pageType) {
		$pageType = '';
	}
	if (
		!$pageType ||
		(index($pageType, ' ') != -1)
	) {
		WriteLog('GetMenuTemplate: warning: $pageType failed sanity check; caller = ' . join(',', caller));
	}

	WriteLog('GetMenuTemplate: $pageType = ' . $pageType . '; caller = ' . join(',', caller));

	my $selfLink = '/access.html'; #todo what is this for?
	my $menuItems = GetMenuFromList('menu', '', $pageType); # GetMenuTemplate()

	#WriteLog('GetMenuTemplate: $menuItems = ' . $menuItems);

	my $menuItemsTag = '';
	my $menuItemsAdvanced = '';
	my $menuItemsAdmin = '';

	if (!$menuItems || trim($menuItems) eq '') {
		#fallback menu in case menu config is so jacked the output is empty
		#todo could use more sanity checks here, like are these basic links present?
		WriteLog('GetMenuTemplate: warning: using hard-coded fallback menu list');
		$menuItems = '
			<a href=/>Home</a>
			<a href=/read.html>Read</a>
			<a href=/write.html>Write</a>
			<a href=/help.html>Help</a>
			<a href=/settings.html><font color=gray>Settings</a>
			<span class=advanced title="Fallback menu is in use">!</span>
		';
	}

	my $siteName = GetConfig('site_name');
	if (GetConfig('config/debug')) {
		$siteName .= ' (debug mode)';
	}

	$topMenuTemplate =~ s/\$menuItemsAdvanced/$menuItemsAdvanced/g;
	$topMenuTemplate =~ s/\$menuItemsAdmin/$menuItemsAdmin/g;
	$topMenuTemplate =~ s/\$menuItemsTag/$menuItemsTag/g;
	$topMenuTemplate =~ s/\$menuItems/$menuItems/g;
	$topMenuTemplate =~ s/\$selfLink/$selfLink/g;
	$topMenuTemplate =~ s/\$siteName/$siteName/g;

	if (GetConfig('setting/html/clock')) {
		my $clockTemplate = GetClockWidget();
		$topMenuTemplate = '<form action="/stats.html" name=frmTopMenu>' . $topMenuTemplate . '</form>';
		$topMenuTemplate =~ s/<span id=spnClock><\/span>/$clockTemplate/g;
	} else {
		# code below not approved for public consumoption #todo
		# removes colspan and fixes the hanging cell bug in some browsers
		#$topMenuTemplate =~ s/<td colspan=2>/<td>/g;
	}

	if (GetConfig('admin/js/enable') && GetConfig('admin/js/dragging')) {
		#$windowTemplate = AddAttributeToTag($windowTemplate, 'table', 'onmousedown', 'this.style.zIndex = ++window.draggingZ;');
		$topMenuTemplate = AddAttributeToTag($topMenuTemplate, 'table', 'onmouseenter', 'if (window.SetActiveDialog) { return SetActiveDialog(this); }'); #SetActiveDialog() GetMenuTemplate()
		$topMenuTemplate = AddAttributeToTag($topMenuTemplate, 'table', 'onmousedown', 'if (window.SetActiveDialog) { return SetActiveDialog(this); }'); #SetActiveDialog() GetMenuTemplate()
	}

	if (GetConfig('admin/js/enable') || GetConfig('admin/php/enable')) { #todo there should be a config called profile_enabled
		if ($pageType ne 'profile' && $pageType ne 'identity') {
			#$topMenuTemplate .= GetDialogX(GetTemplate('html/widget/identity.template'), 'Identity');
		}
	}

	my $topMenu = GetDialogX($topMenuTemplate, $title, '', $status);

	return $topMenu;
} # GetMenuTemplate()

require_once('widget/menu_item.pl');

1;
