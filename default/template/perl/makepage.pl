#!/usr/bin/perl -T

use strict;
use warnings;
use utf8;
use 5.010;

# use threads (
# 	'yield',
# 	'stack_size' => 64*4096,
# 	'exit' => 'threads_only',
# 	'stringify'
# );

my @argsFound;
while (my $argFound = shift) {
	push @argsFound, $argFound;
}

require_once('item_list_as_gallery.pl');
require_once('dialog.pl');
require_once('make_simple_page.pl');

sub MakePage { # $pageType, $pageParam, $htmlRoot ; make a page and write it into $HTMLDIR directory; $pageType, $pageParam
# sub makepage {
# sub getpage {
# sub GetTagsPage { MakePage()
# sub GetLabelsPage { MakePage()
# sub GetLabelsDialog {
# sub GetPage {
# sub MakeProfilePage {
# sub GetHelpPage { # sub MakePage {
# sub MakeHelpPage { # sub MakePage {
# sub GetScoresPage { # sub MakePage {

# supported page types so far:
# tag, #hashtag
# author, ABCDEF01234567890
# item, 0123456789abcdef0123456789abcdef01234567
# date, YYYY-MM-DD
# authors
# read
# prefix
# summary (deprecated)
# tags
# labels
# stats
# index
# compost
# bookmark

	state $HTMLDIR = GetDir('html');

	# $pageType = author, item, tags, labels, etc.
	# $pageParam = author_id, item_hash, etc.
	my $pageType = shift;
	my $pageParam = shift;
	my $htmlRoot = shift;

	$pageType = trim($pageType);
	$pageParam = trim($pageParam);
	$htmlRoot = trim($htmlRoot);

	if (0) { # debug
		WriteLog('MakePage: override test: $pageType = ' . ($pageType ? $pageType : 'FALSE') . '; $pageParam = ' . ($pageParam ? $pageParam : 'FALSE') . '; $htmlRoot = ' . ($htmlRoot ? $htmlRoot : 'FALSE'));
		if ($pageType eq 'threads' || $pageType eq 'help') {
			WriteLog('MakePage: testing theme override');
			# always dark theme
			GetConfig('setting/theme', 'override', 'dark');
		} else {
			WriteLog('MakePage: testing theme override reset');
			GetConfig('unmemo');
		}

		WriteLog('MakePage: override test: setting/theme = ' . GetConfig('setting/theme'));
		WriteLog('MakePage: override test: GetActiveThemes() = ' . join(',', GetActiveThemes()));
		WriteLog('MakePage: override test: GetTemplate(memo_count) = ' . GetTemplate('memo_count'));
	}

	if ($htmlRoot) {
		$HTMLDIR = $htmlRoot;
	}

	#todo sanity checks
	#todo sanity checks
	#todo sanity checks

	if (!defined($pageParam)) {
		$pageParam = 0;
	}

	WriteMessage('MakePage(' . $pageType . ', ' . $pageParam . ')');
	WriteLog('MakePage(' . $pageType . ', ' . $pageParam . '); caller = ' . join(',', caller));

	my @listingPages = qw(child chain url deleted compost new raw picture image read authors scores tags labels threads boxes tasks active);
	push @listingPages, qw(browse); # shadowme
	#chain.html #new.html #boxes.html #tasks.html
	# sub GetChainPage {
	# sub GetTagsPage { # tags.html MakePage()
	# sub GetLabelsPage { # labels.html MakePage()

	# my @validPages =
	# valid pages
	my @simplePages = qw(history nocookie queue menu inspector data cloud bookmark help example topics access welcome paint judge calendar profile upload links post cookie chat thanks examples about faq documentation network schedule people donate session);
	push @simplePages, qw(biography interests messages); # shadowme
	# yes, this is what you need for GetXPage() in template/perl/page/x.pl to work!

	if (0) { } # this is to make all the elsifs below have consistent formatting
	elsif (in_array($pageType, @simplePages)) {
		WriteLog('MakePage: found "' . $pageType . '" in @simplePages');
		MakeSimplePage($pageType);
	}
	elsif (in_array($pageType, @listingPages)) {
		# sub MakeImagePage {
		WriteLog('MakePage: found "' . $pageType . '" in @listingPages');
		require_once('item_listing_page.pl');
		my %params;

		# uses WriteItemListingPages() and GetItemListingPage()

		if ($pageType eq 'chain') { # chain.html
			# sub GetChainPage {
			#$params{'dialog_columns'} = 'special_title_labels_list,chain_order,chain_timestamp,add_timestamp,chain_hash,file_hash,tagset_chain,cart';
			$params{'dialog_columns'} = 'item_title,tags_list,chain_order,chain_timestamp,add_timestamp,chain_hash,file_hash,tagset_chain,cart';

			my $verifierScript = GetTemplate('python/script/chain_log_verify.py');
			PutFile("$HTMLDIR/chain_log_verify.txt", $verifierScript);
		}
		if ($pageType eq 'tags' || $pageType eq 'labels') {
			#todo does this need to happen every time a listing page is generated?
			# for the tags page, look at template/query/tags.sql
			my $tagsHorizontal = GetTagPageHeaderLinks();
			PutHtmlFile('tags-horizontal.html', $tagsHorizontal);
		}
		if ($pageType eq 'image' || $pageType eq 'read') {
			#todo unhardcode
			WriteItemListingPages($pageType, 'full_items', \%params);
		} else {
			WriteItemListingPages($pageType, 'dialog_list', \%params);
		}
	} # elsif (in_array($pageType, @listingPages))

	elsif ($pageType eq 'write') {
		WriteLog('MakePage: write');
		MakeWritePage();
	}

	elsif ($pageType eq 'js') {
		WriteLog('MakePage: js');
		MakeJsPages();
	}

	elsif ($pageType eq 'settings') {
		WriteLog('MakePage: settings');

		MakeSimplePage('settings');
		PutStatsPages();
	}

	elsif ($pageType eq 'random') {
		WriteLog('MakePage: random');

		my @itemsRandom = SqliteQueryHashRef('random');
		shift @itemsRandom;

		if (@itemsRandom) {
			my $targetPath = "random.html";
			my $randomPage =
				GetPageHeader('random') .
				GetItemListHtml(\@itemsRandom) .
				#GetDialogX(GetTemplate('query/random')) .
				GetQuerySqlDialog('random') .
				GetPageFooter('random')
			;

			my @jsToInject = qw(settings timestamp voting utils profile);
			if (GetConfig('setting/admin/js/fresh')) {
				push @jsToInject, 'fresh';
			}
			if (GetConfig('setting/html/reply_cart')) {
				push @jsToInject, 'reply_cart';
			}
			$randomPage = InjectJs($randomPage, @jsToInject);

			PutHtmlFile($targetPath, $randomPage);
		} else {
			my $targetPath = "random.html";
			my $randomPage =
				GetPageHeader('random') .
				GetDialogX('Nothing to display on the random page yet.') .
				GetQuerySqlDialog('random') .
				GetPageFooter('random')
			;

			my @jsToInject = qw(settings timestamp voting utils profile);
			if (GetConfig('setting/admin/js/fresh')) {
				push @jsToInject, 'fresh';
			}
			if (GetConfig('setting/html/reply_cart')) {
				push @jsToInject, 'reply_cart';
			}
			$randomPage = InjectJs($randomPage, @jsToInject);

			PutHtmlFile($targetPath, $randomPage);
		}
	} #random

	# label page, get the label name from $pageParam
	elsif ($pageType eq 'label') {
		my $labelName = $pageParam;
		my $targetPath = "label/$labelName.html";
		WriteLog('MakePage: label: $labelName = ' . $labelName);

		my $labelPage = GetReadPage('label', $labelName);
		PutHtmlFile($targetPath, $labelPage);
	}

	# tag page, get the tag name from $pageParam
	elsif ($pageType eq 'tag') {
		my $tagName = $pageParam;
		my $targetPath = "tag/$tagName.html";
		WriteLog('MakePage: tag: $tagName = ' . $tagName);

		if (0) {
			require_once('item_listing_page.pl');

			my %params;
			my %queryParams;
			#$queryParams{'limit_clause'} = "LIMIT 1000"; #todo fix hardcoded limit #todo pagination
			$queryParams{'order_clause'} = "ORDER BY item_score DESC, item_flat.add_timestamp DESC";
			my $scoreThreshold = 0;
			$queryParams{'where_clause'} = "WHERE ','||labels_list||',' LIKE '%,$tagName,%' AND item_score >= $scoreThreshold";

			$params{'query'} = DBGetItemListQuery(\%queryParams);
			$params{'query_params'} = \%queryParams;
			$params{'target_path'} = 'tag/' . $tagName;

			WriteItemListingPages($pageType, 'dialog_list', \%params);
		}

		my $tagPage = GetReadPage('tag', $tagName);
		PutHtmlFile($targetPath, $tagPage);

		MakePage('label', $tagName); #todo this is a shim
	}
	
	elsif ($pageType eq 'date') {
#sub MakeDatePage {
		my $pageDate = $pageParam;
		if ($pageDate && $pageDate =~ m/^([0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9])/) { #basic sanity check
			$pageDate = $1;
			my $targetPath = "date/$pageDate.html";

			WriteLog('MakePage: date: $pageDate = ' . $pageDate);
			my $datePage = GetReadPage('date', $pageDate);
			PutHtmlFile($targetPath, $datePage);
		} else {
			WriteLog('MakePage: date: sanity check failed on $pageDate; caller = ' . join(',', caller));
		}
	}

	elsif ($pageType eq 'speakers') {
		WriteLog('MakePage: speakers');
		my $speakersPage = '';
		$speakersPage = GetPageHeader('speakers');

		my %queryParams;
		$queryParams{'where_clause'} = "WHERE ','||labels_list||',' LIKE '%,speaker,%'";
		$queryParams{'order_clause'} = "ORDER BY file_name";
		#$queryParams{'where_clause'} = "WHERE ','||labels_list||',' LIKE '%,speaker,%'";

		my @itemSpeakers = DBGetItemList(\%queryParams);
		foreach my $itemSpeaker (@itemSpeakers) {
			#$itemSpeaker->{'item_title'} = $itemSpeaker->{'item_name'};
			if (length($itemSpeaker->{'item_title'}) > 48) {
				$itemSpeaker->{'item_title'} = substr($itemSpeaker->{'item_title'}, 0, 45) . '[...]';

			}
			$itemSpeaker->{'item_statusbar'} = GetItemHtmlLink($itemSpeaker->{'file_hash'}, $itemSpeaker->{'item_title'});
			my $itemSpeakerTemplate = GetItemTemplate($itemSpeaker);
			$speakersPage .= $itemSpeakerTemplate;
		}

		$speakersPage .= GetPageFooter('speakers');
		$speakersPage = InjectJs($speakersPage, qw(settings utils));
		PutHtmlFile('speakers.html', $speakersPage);
	}

	elsif ($pageType eq 'committee') {
		WriteLog('MakePage: committee');
		my $committeePage = '';
		$committeePage = GetPageHeader('committee');

		my %queryParams;
		$queryParams{'where_clause'} = "WHERE ','||labels_list||',' LIKE '%,committee,%'";
		$queryParams{'order_clause'} = "ORDER BY item_order";

		my @itemCommittee = DBGetItemList(\%queryParams);
		foreach my $itemCommittee (@itemCommittee) {
			if (GetConfig('admin/mit_expo_mode')) {
				if ($itemCommittee->{'item_name'} eq 'Manish Kumar') {
					#expo mode #todo #bandaid
					$itemCommittee->{'item_title'} = 'Hackathon Co-Chair';
				}
			}
			if (length($itemCommittee->{'item_title'}) > 48) {
				$itemCommittee->{'item_title'} = substr($itemCommittee->{'item_title'}, 0, 43) . '[...]';
			}
			if (!GetConfig('admin/expo_site_edit')) {
				$itemCommittee->{'no_permalink'} = 1;
			}
			my $itemCommitteeTemplate = GetItemTemplate($itemCommittee);
			$committeePage .= $itemCommitteeTemplate;
		}

		$committeePage .= GetPageFooter('committee');
		$committeePage = InjectJs($committeePage, qw(settings utils));
		PutHtmlFile('committee.html', $committeePage);
	}
	elsif ($pageType eq 'sponsors') {
		WriteLog('MakePage: sponsors');
		my $sponsorsPage = '';
		$sponsorsPage = GetPageHeader('sponsors');

		foreach my $sponsorLevel (qw(gold silver)) {
			my %queryParams;
			$queryParams{'where_clause'} = "WHERE ','||labels_list||',' LIKE '%,sponsor,%' AND ','||labels_list||',' LIKE '%,$sponsorLevel,%'";
			$queryParams{'order_clause'} = "ORDER BY file_name";

			my $sponsorsImages = '';

			my @itemSponsors = DBGetItemList(\%queryParams);
			foreach my $itemSponsor (@itemSponsors) {
				if (length($itemSponsor->{'item_title'}) > 48) {
					$itemSponsor->{'item_title'} = substr($itemSponsor->{'item_title'}, 0, 43) . '[...]';
				}
				my $sponsorImage = GetImageContainer($itemSponsor->{'file_hash'}, $itemSponsor->{'item_name'});
				$sponsorImage = AddAttributeToTag($sponsorImage, 'img', 'height', '100');
				$sponsorImage = GetDialogX($sponsorImage, '');
				$sponsorsImages .= $sponsorImage;
				$sponsorsImages .= "<br><br><br>";
				#my $itemSponsorTemplate = GetItemTemplate($itemSponsor);
				#$sponsorsPage .= $itemSponsorTemplate;
			}

			$sponsorsImages = '<center style="padding: 5pt">' . $sponsorsImages . '</center>';
			$sponsorsPage .= GetDialogX('<tr><td>' . $sponsorsImages . '</td></tr>', ucfirst($sponsorLevel) . ' Sponsors');

			$sponsorsPage .= "<br><br>";
		}

		$sponsorsPage .= GetPageFooter('sponsors');
		$sponsorsPage = InjectJs($sponsorsPage, qw(settings utils));

		PutHtmlFile('sponsors.html', $sponsorsPage);
	} #sponsors
	#
	# person page, get person's alias/handle/name from $pageParam
	elsif ($pageType eq 'person') {
	    if ($pageParam =~ m/^([0-9a-zA-Z]+)$/) {
	        $pageParam = $1;
	    } else {
	        WriteLog('MakePage: person: warning: $pageParam failed sanity check; caller = ' . join(',', caller));
	        return '';
	    }

	    my $personName = $pageParam;
	    my $targetPath = "person/$personName/index.html";

	    WriteLog('MakePage: person: ' . $personName);

        require_once('get_person_page.pl');
	    my $personPage = GetPersonPage($personName);;

	    PutHtmlFile($targetPath, $personPage);

	}
	#
	# author page, get author's id from $pageParam
	elsif ($pageType eq 'author') {
		if ($pageParam =~ m/^([0-9A-F]{16})$/) {
			$pageParam = $1;
		} else {
			WriteLog('MakePage: author: warning: $pageParam sanity check failed. returning');
			return '';
		}

		my $authorKey = $pageParam;
		my $targetPath = "author/$authorKey/index.html";

		WriteLog('MakePage: author: ' . $authorKey);

		require_once('get_read_page.pl');
		my $authorPage = GetReadPage('author', $authorKey);
		if (!-e "$HTMLDIR/author/$authorKey") {
		    # #todo make this not use -e
			mkdir ("$HTMLDIR/author/$authorKey");
		}
		PutHtmlFile($targetPath, $authorPage);
	}
	#
	# if $pageType eq item, generate that item's page
	elsif ($pageType eq 'item') {
		WriteLog('MakePage: $pageType = item; caller = ' . join(',', caller));
		# get the item's hash from the param field
		my $fileHash = $pageParam;

		# get item page's path #todo refactor this into a function
		#my $targetPath = $HTMLDIR . '/' . substr($fileHash, 0, 2) . '/' . substr($fileHash, 2) . '.html';
		my $targetPath = GetHtmlFilename($fileHash); # MakePage()

		# get item list using DBGetItemList()
		# #todo clean this up a little, perhaps crete DBGetItem()
		my @files = DBGetItemList({'where_clause' => "WHERE file_hash LIKE '$fileHash%'"});

		if (scalar(@files)) {
			my $file = $files[0];

			if ($file) {
				if ($HTMLDIR =~ m/^(^\s+)$/) { #security #taint #todo
					$HTMLDIR = $1; # untaint
					# create a subdir for the first 2 characters of its hash if it doesn't exist already
					if (!-e ($HTMLDIR . '/' . substr($fileHash, 0, 2))) {
						mkdir(($HTMLDIR . '/' . substr($fileHash, 0, 2)));
					}
					if (!-e ($HTMLDIR . '/' . substr($fileHash, 0, 2) . '/' . substr($fileHash, 2, 2))) {
						mkdir(($HTMLDIR . '/' . substr($fileHash, 0, 2) . '/' . substr($fileHash, 2, 2)));
					}
				}

				# get the page for this item and write it
				WriteLog('MakePage: my $filePage = GetItemPage($file = "' . $file . '")');
				my $filePage = GetItemPage($file);
				WriteLog('PutHtmlFile($targetPath = ' . $targetPath . ', $filePage = ' . length($filePage) . ' bytes)');
				PutHtmlFile($targetPath, $filePage);
			} # if ($file)
			else { # no $file
				#PutHtmlFile($targetPath, 'I looked for that, but could not find it (1)');
				WriteMessage('MakePage: item: warning: $file missing, sanity check failed!');
				WriteLog('MakePage: item: warning: sanity check failed: $file ($files[0]) is missing!');
			} # no $file
		} # if (scalar(@files))
		else { # no @files
			#PutHtmlFile($targetPath, 'I looked for that, but could not find it (2)');
			WriteLog('MakePage: warning: Item not in database; $fileHash = ' . $fileHash . '; caller = ' . join(',', caller));

			my $queryAltHash = "SELECT file_hash FROM item_attribute WHERE attribute = 'alt_hash' AND value LIKE '$fileHash%'";
			WriteLog('MakePage: $queryAltHash = ' . $queryAltHash);
			my $altHash = SqliteGetValue($queryAltHash);
			if ($altHash) {
				if (IsItem($altHash)) {
					WriteLog('MakePage: $altHash = ' . $altHash);

					my @altFiles = DBGetItemList({'where_clause' => "WHERE file_hash LIKE '$altHash%'"});
					if (scalar(@altFiles)) {
						my $altFile = $altFiles[0];
						if ($altFile) {
							if ($HTMLDIR =~ m/^(^\s+)$/) { #security #taint #todo
								$HTMLDIR = $1; # untaint
								# create a subdir for the first 2 characters of its hash if it doesn't exist already
								if (!-e ($HTMLDIR . '/' . substr($altHash, 0, 2))) {
									mkdir(($HTMLDIR . '/' . substr($altHash, 0, 2)));
								}
								if (!-e ($HTMLDIR . '/' . substr($altHash, 0, 2) . '/' . substr($altHash, 2, 2))) {
									mkdir(($HTMLDIR . '/' . substr($altHash, 0, 2) . '/' . substr($altHash, 2, 2)));
								}
							}

							WriteLog('MakePage: my $filePage = GetItemPage($altFile = "' . $altFile . '")');
							my $altFilePage = GetItemPage($altFile);
							WriteLog('PutHtmlFile($targetPath = ' . $targetPath . ', $altFilePage = ' . length($altFilePage) . ' bytes)');
							PutHtmlFile($targetPath, $altFilePage);
						}
					} else {
						WriteLog('MakePage: scalar(@altFiles) was FALSE');
					}
				}
			}
			# item not found in database
			# my $query = GetTemplate('query/new') . " LIMIT 12";
			# my $queryDialog = GetQueryAsDialog($query, 'Newest');
			# my $page =
			# 	GetPageHeader('help') .
			# 	GetDialogX('Could not find item. It may have been renamed?', 'Error') .
			# 	$queryDialog .
			# 	GetPageFooter('help')
			# ;
			# PutHtmlFile($targetPath, $page);
			return '';
		} # nothing in scalar(@files)
	} # $pageType eq 'item' # item page
	#
	# topitems page
	elsif ($pageType eq 'image') {
		WriteLog('MakePage: image');
		require_once('item_listing_page.pl');
		WriteItemListingPages('image', 'image_gallery');
	}
	elsif ($pageType eq 'picture') {
		WriteLog('MakePage: picture');
		require_once('item_listing_page.pl');
		WriteItemListingPages('picture', 'image_gallery');
	}
	#
	# stats page
	elsif ($pageType eq 'stats') {
		WriteLog('MakePage: stats');
		PutStatsPages();
	}
	#
	# topmenu (in all existing pages)
	elsif ($pageType eq 'topmenu') {
		WriteLog('MakePage: topmenu');
		ReplaceMenuInAllPages();
	}
	#
	# item prefix page
	elsif ($pageType eq 'prefix') {
		my $itemPrefix = $pageParam;
		my $itemsPage = GetItemPrefixPage($itemPrefix);
		PutHtmlFile(substr($itemPrefix, 0, 2) . '/' . substr($itemPrefix, 2, 2) . '/index.html', $itemsPage);
	}
	#
	#
	# rss feed
	elsif ($pageType eq 'rss') {
		require_once('page/rss.pl');
		#todo break out into own module and/or auto-generate rss for all relevant pages

		my %queryParams;

		$queryParams{'order_clause'} = 'ORDER BY add_timestamp DESC';
		$queryParams{'limit_clause'} = 'LIMIT 200';
		my @rssFiles = DBGetItemList(\%queryParams);

		PutFile("$HTMLDIR/rss.xml", GetRssFile(@rssFiles));
		# /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml
		# /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml
		# /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml /rss.xml
	}
	#
	# summary pages
	elsif ($pageType eq 'summary') {
		MakeSummaryPages();
	}
	#
	# system pages
	elsif ($pageType eq 'system') {
		MakeSystemPages();
	}
	#
	# item identifier or prefix
	elsif (IsItem($pageType)) {
	    WriteMessage("recognized item identifier\n");
	    MakePage('item', $pageType, 1);
	}
	elsif (IsItemPrefix($pageType)) {
	    WriteMessage("recognized item prefix\n");
	    MakePage('prefix', $pageType, 1);
	}
	#
	# author fingerprint
	elsif (IsFingerprint($pageType)) {
	    WriteMessage("recognized author fingerprint\n");
	    MakePage('author', $pageType, 1);
	}
	#
	# date
	elsif (IsDate($pageType)) {
	    WriteMessage("recognized date\n");
	    MakePage('date', $pageType, 1);
	}
	#
	# #hashtag
	elsif (substr($pageType, 0, 1) eq '#') {
		WriteMessage('recognized #hashtag');
		MakePage('tag', substr($pageType, 1));
	}
	#
	# fallthrough
	else {
		# hi, friend. if you're here, you should probably look for this: 	# my @validPages =
                                                                         	# valid pages

		WriteMessage('Warning: did not recognize that page type: ' . $pageType);
		WriteLog('MakePage: warning: did not recognize that page type: ' . $pageType . '; caller = ' . join(',', caller));
		WriteMessage('=========================================');
	}

	WriteLog("MakePage: finished, calling DBDeletePageTouch($pageType, $pageParam)");
	DBDeletePageTouch($pageType, $pageParam);
} # MakePage()

1;
