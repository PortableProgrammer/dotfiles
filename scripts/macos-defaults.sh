#!/usr/bin/env bash

# ~/.macos

# Find macOS Defaults at https://macos-defaults.com/

# Close any open System Settings panes, to prevent them from overriding
# settings we’re about to change
osascript -e 'tell application "System Settings" to quit'

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.macos` has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# General UI/UX                                                               #
###############################################################################

# Set Appearance to Auto
defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool true

# Enable full keyboard access for all controls
# (e.g. enable Tab in modal dialogs)
defaults write -g AppleKeyboardUIMode -int 3

# Set region
defaults write -g AppleLanguages -array "en"
defaults write -g AppleLocale -string "en_US"

# Configure region customizations
## Default date format: yyyy-MM-dd 
defaults write -g AppleICUDateFormatStrings -array "y-MM-dd"

# Expand save panel by default
defaults write -g NSNavPanelExpandedStateForSaveMode -bool true
defaults write -g NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write -g PMPrintingExpandedStateForPrint -bool true
defaults write -g PMPrintingExpandedStateForPrint2 -bool true

# Automatically quit printer app once the print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Maximize window on double-click
defaults write -g AppleActionOnDoubleClick -string "Maximize"

# Remove duplicates in the “Open With” menu (also see `lscleanup` alias)
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

###############################################################################
# Energy saving                                                               #
###############################################################################

# Enable lid wakeup
sudo pmset -a lidwake 1

# Restart automatically on power loss
sudo pmset -a autorestart 1

# Restart automatically if the computer freezes
sudo systemsetup -setrestartfreeze on

# Power profiles
## Battery
### Sleep display after 2 minutes
sudo pmset -b displaysleep 2
### Slightly dim display
sudo pmset -b lessbright 1

## AC
### Sleep display after 3 hours (180 minutes)
sudo pmset -c displaysleep 180

###############################################################################
# Screen                                                                      #
###############################################################################

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 5

# Save screenshots to downloads
defaults write com.apple.screencapture location -string "${HOME}/Downloads"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Enable subpixel font rendering on non-Apple LCDs
# Reference: https://github.com/kevinSuttle/macOS-Defaults/issues/17#issuecomment-266633501
defaults write -g AppleFontSmoothing -int 1

###############################################################################
# Finder                                                                      #
###############################################################################

# Finder: show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
defaults write -g AppleShowAllExtensions -bool true

# Hide all icons on the desktop
defaults write com.apple.finder CreateDesktop -bool false

# Hide icons for hard drives, servers, and removable media on the desktop
# Overkill because of the above
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool true

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Use list view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Configure Info panes
defaults write com.apple.finder FXInfoPanesExpanded -dict \
	General -bool true \
    MetaData -bool true \
    Name -bool true \
    Comments -bool false \
	OpenWith -bool true \
    Preview -bool false \
	Privileges -bool false

###############################################################################
# Dock                                                                        #
###############################################################################

# Set the magnification to 1
defaults write com.apple.dock magnification -int 1

# Set the "large" icon size to 72
defaults write com.apple.dock largesize -int 72

# Change minimize/maximize window effect
defaults write com.apple.dock mineffect -string "scale"

# Minimize windows into their application’s icon
defaults write com.apple.dock minimize-to-application -bool true

# Don’t show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Don’t automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Move Dock to the left
defaults write com.apple.dock orientation -string "left"

# Enable Scroll-to-Exposè-app
defaults write com.apple.dock scroll-to-open -bool true

# Enable spring loading for all Dock applications
# e.g. drag a file over any app, opened or unopened, and it will open
defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true

###############################################################################
# Safari                                                                      #
###############################################################################

# Disable AutoFill
defaults write com.apple.Safari AutoFillCreditCardData -bool false
defaults write com.apple.Safari AutoFillFromAddressBook -bool false
defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false
defaults write com.apple.Safari AutoFillPasswords -bool false

# Prevent Safari from opening ‘safe’ files automatically after downloading
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Clear download list upon completion
defaults write com.apple.Safari DownloadsClearingPolicy -int 2

# Make Safari’s search banners default to Contains instead of Starts With
defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false

# Configure Start Page
defaults write com.apple.Safari CloudTabsOnStartPageConsent -bool false
defaults write com.apple.Safari HideHighlightsEmptyItemViewPreferenceKey -bool true
defaults write com.apple.Safari HideStartPageFrecentsEmptyItemView -bool true
defaults write com.apple.Safari HideStartPageRecentlyClosedTabsEmptyItemView -bool false
defaults write com.apple.Safari HideStartPageSiriSuggestionsEmptyItemView -bool true
defaults write com.apple.Safari HideSuggestionsEmptyItemView -bool false
defaults write com.apple.Safari HomePage -string ""

# Allow physically connected mobile devices to be debugged
defaults write com.apple.Safari MobileDeviceRemoteXPCEnabled -bool true

# Private browsing; require auth, allow default search enging
defaults write com.apple.Safari PrivateBrowsingExplanationState -bool true
defaults write com.apple.Safari PrivateBrowsingRequiresAuthentication -bool true
defaults write com.apple.Safari PrivateSearchEngineUsesNormalSearchEngineToggle -bool true

# Various flags for Start Page, Sidebar, Favorites, etc.
defaults write com.apple.Safari ShowBackgroundImageInFavorites -bool false
defaults write com.apple.Safari ShowCloudTabsInFavorites -bool true
defaults write com.apple.Safari "ShowFavoritesBar-v2" -bool false
defaults write com.apple.Safari ShowFrequentlyVisitedSites -bool false
# Show full URL in address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
defaults write com.apple.Safari ShowHighlightsInFavorites -bool false
defaults write com.apple.Safari ShowOverlayStatusBar -bool true
defaults write com.apple.Safari ShowPrivacyReportInFavorites -bool false
defaults write com.apple.Safari ShowReadingListInFavorites -bool false
defaults write com.apple.Safari ShowRecentlyClosedTabsPreferenceKey -bool false
defaults write com.apple.Safari ShowSidebarInNewWindows -bool false
defaults write com.apple.Safari ShowSidebarInTopSites -bool false
defaults write com.apple.Safari ShowSiriSuggestionsPreference -bool true
defaults write com.apple.Safari ShowStandaloneTabBar -bool false
defaults write com.apple.Safari ShowTabGroupFavoritesPreferenceKey -bool false

# Press Tab to highlight each item on a web page
defaults write com.apple.Safari WebKitTabToLinksPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks -bool true

# Hide Safari’s sidebar in Top Sites
defaults write com.apple.Safari ShowSidebarInTopSites -bool false

# Enable the Develop menu and the Web Inspector in Safari
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Add a context menu item for showing the Web Inspector in web views
defaults write -g WebKitDeveloperExtras -bool true

# Warn about fraudulent websites
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Enable “Do Not Track”
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true

# Update extensions automatically
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true

###############################################################################
# Clock                                                                       #
###############################################################################

# Configure the menu bar clock
defaults write com.apple.menuextra.clock FlashDateSeparators -bool false
defaults write com.apple.menuextra.clock IsAnalog -bool false
defaults write com.apple.menuextra.clock Show24Hour -bool false
defaults write com.apple.menuextra.clock ShowAMPM -bool true
defaults write com.apple.menuextra.clock ShowDate -int 1
defaults write com.apple.menuextra.clock ShowDayOfMonth -bool true
defaults write com.apple.menuextra.clock ShowDayOfWeek -bool true
defaults write com.apple.menuextra.clock ShowSeconds -bool false
# As of at least Sequioia (15.x), this setting doesn't do anything
# Defaults to the ISO standard for the region selected
# e.g. en_us is `EEE MMM d` and en_gb is `EEE d MMM`, etc.
#defaults write com.apple.menuextra.clock DateFormat -string "EEE d MMM"

###############################################################################
# Activity Monitor                                                            #
###############################################################################

# Set Dock icon to show CPU history graph
defaults write com.apple.ActivityMonitor IconType -int 6

###############################################################################
# Mail                                                                        #
###############################################################################

# Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false

# Add the keyboard shortcut ⌘ + Enter to send an email in Mail.app
defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" "@\U21a9"

# Display emails in threaded mode, sorted by date (newest at the top)
defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "no"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"

# Mail display options
defaults write com.apple.mail ShouldShowUnreadMessagesInBold -bool true
defaults write com.apple.mail ShowBccHeader -bool true
defaults write com.apple.mail ShowCcHeader -bool true
defaults write com.apple.mail ShowComposeFormatInspectorBar -bool true
defaults write com.apple.mail ShowPriorityControl -bool true
defaults write com.apple.mail ShowReplyToHeader -bool false
defaults write com.apple.mail SignaturePlacedAboveQuotedText -bool true

###############################################################################
# Terminal                                                                    #
###############################################################################

# Use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Install Meslo Nerd Font for Powerlevel10k https://github.com/romkatv/powerlevel10k#fonts
# This currently requires manual input to install and activate the fonts
echo "Waiting for fonts to install..."
open -W '$HOME/.init/*.ttf'
echo "Done."

# Use Smyck theme https://color.smyck.org
# Use Meslo Nerd Font for Powerlevel10k
osascript <<EOD

tell application "Terminal"

	local allOpenedWindows
	local initialOpenedWindows
	local windowID
	set themeName to "Smyck"
	set fontName to "MesloLGS-NF-Regular"

	(* Store the IDs of all the open terminal windows. *)
	set initialOpenedWindows to id of every window

	(* Open the custom theme so that it gets added to the list
	   of available terminal themes (note: this will open two
	   additional terminal windows). *)
	do shell script "open '$HOME/.init/" & themeName & ".terminal'"

	(* Wait a little bit to ensure that the custom theme is added. *)
	delay 1

	(* Set the custom theme as the default terminal theme. *)
	set default settings to settings set themeName
	(* Set the custom font as the default terminal font. *)
	set font name of default settings to fontName

	(* Get the IDs of all the currently opened terminal windows. *)
	set allOpenedWindows to id of every window

	repeat with windowID in allOpenedWindows

		(* Close the additional windows that were opened in order
		   to add the custom theme to the list of terminal themes. *)
		if initialOpenedWindows does not contain windowID then
			close (every window whose id is windowID)

		(* Change the theme for the initial opened terminal windows
		   to remove the need to close them in order for the custom
		   theme to be applied. *)
		else
			set current settings of tabs of (every window whose id is windowID) to settings set themeName
		end if

	end repeat

end tell

EOD

###############################################################################
# App Store and Software Update                                               #
###############################################################################

# Enable Debug Menu in the Mac App Store
defaults write com.apple.appstore ShowDebugMenu -bool true

# Enable the WebKit Developer Tools in the Mac App Store
defaults write com.apple.appstore WebKitDeveloperExtras -bool true

# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true

# Enable the automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install System data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

echo "Closing/restarting affected apps..."
for app in "Activity Monitor" \
	"Calendar" \
	"cfprefsd" \
	"Dock" \
	"Finder" \
	"Mail" \
	"Safari" \
	"SystemUIServer" \
	"Terminal"; do
	killall "${app}" &> /dev/null
done
echo "Done."