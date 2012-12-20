####################################
## Fun Command: Give Cookie to Bot##
####################################

bind pub -|- +cookie cookie
proc cookie { nick uhost hand chan arg} {
	global main test
	if {$chan != $main} {
		if {[isop $nick $chan] == 1 || [ishalfop $nick $chan] == 1} {
			set cookiefile [open "cookie.txt" r]
			gets $cookiefile line
			set cookieamt $line
			close $cookiefile
			# Create a Timestamp for the file
			set timestamp [clock format [clock seconds] -format {%Y%m%d%H%M%S}]
			set filename "cookie.txt"
			# Create a Temp and Backup File
			set temp $filename.new.$timestamp
			# Set In/Out to Open Peak.txt in Read-Only/Write-Only
			set in [open $filename r]
			set out [open $temp w]
			while {[gets $in line] != -1} {
				if {[llength $arg]==0} {
					set cookieamt [expr {$cookieamt + 1}]
					set line $cookieamt
					puts $out $line
				} else {
					set cookieamt [expr {$cookieamt + $arg}]
					set line $cookieamt
					puts $out $line
				}
			}
			# Close Both Files
			close $in
			close $out
			# Rename Temp to Original File Name
			file rename -force $temp $filename
			putnow "PRIVMSG $chan :Thank you, Master. I now have $cookieamt cookies."
		}
	}
}


####################################
## Fun Command: Take Cookie to Bot##
####################################

bind pub -|- -cookie takecookie
proc takecookie { nick uhost hand chan arg} {
	global main test
	if {$chan != $main} {
		if {[isop $nick $chan] == 1 || [ishalfop $nick $chan] == 1} {
			set cookiefile [open "cookie.txt" r]
			gets $cookiefile line
			set cookieamt $line
			close $cookiefile
			# Create a Timestamp for the file
			set timestamp [clock format [clock seconds] -format {%Y%m%d%H%M%S}]
			set filename "cookie.txt"
			# Create a Temp and Backup File
			set temp $filename.new.$timestamp
			# Set In/Out to Open Peak.txt in Read-Only/Write-Only
			set in [open $filename r]
			set out [open $temp w]
			while {[gets $in line] != -1} {
				if {[llength $arg]==0} {
					set cookieamt [expr {$cookieamt - 1}]
					set line $cookieamt
					puts $out $line
				} else {
					set cookieamt [expr {$cookieamt - $arg}]
					set line $cookieamt
					puts $out $line
				}
			}
			# Close Both Files
			close $in
			close $out
			# Rename Temp to Original File Name
			file rename -force $temp $filename
			putnow "PRIVMSG $chan :Nooo, I only have $cookieamt cookies now.."
		}
	}
}

putlog "Cookies.tcl loaded.."