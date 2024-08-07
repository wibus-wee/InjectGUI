#!/bin/sh

#  uninstall-helper.sh
#  InjectGUI
#
#  Created by wibus on 2024/8/6.
#

sudo /bin/launchctl unload /Library/LaunchDaemons/dev.wibus-wee.InjectGUI.helper.plist
sudo /usr/bin/killall -u root -9 dev.wibus-wee.InjectGUI.helper
sudo /bin/rm /Library/LaunchDaemons/dev.wibus-wee.InjectGUI.helper.plist
sudo /bin/rm /Library/PrivilegedHelperTools/dev.wibus-wee.InjectGUI.helper
