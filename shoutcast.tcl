##########################################################################
## ##
## Torrent-Invites Radio Bot ##
## ##
##########################################################################


####################################
## Setting up different constants ##
####################################

set siteurl "http://216.104.37.26:9005"
set playlist "http://216.104.37.26:9005/listen.pls"
set urlhistory "http://216.104.37.26:9005/played.html"
set server "216.104.37.26"
set port "9005"
set agent "Mozilla"
set djch "#DJ"
set main "#Torrent-Invites"
set test "#BotDev"
set streamch "#TI-Radio"
set irpg "#IdleRPG"
set isair 0
set userair 0
set firstad 0
set song 0

package require http


####################################
## Functions: Start and Stop Timer##
####################################

proc hasTimers {} {
	set timerList [timers];
	return [llength $timerList];
}

proc stop {} {
	set timerList [timers];
	foreach timer $timerList {
		killtimer [lindex $timer 2];
	}
}

####################################
## Refreshing bot resets timers ##
####################################

proc start {} {
	global test
	if {[hasTimers] == 0} {
		putnow "PRIVMSG $test :It Seems You Rehashed Me Master."
		putnow "PRIVMSG $test :No Timers Active. Activating Timer Now."
		#Starting Check DJ Timer
		checkdj
		#Starting Check Peak Timer
		maxlisteners
		#Starting Advertisment Timer
		run_periodically #TI-Radio
		#Starting Advertisement Timer
		run_periodically #Torrent-Invites
		#Starting Delete Request Timer
		deletereq
	} else {
		putnow "PRIVMSG $test :It Seems You Rehashed Me Master."
		putnow "PRIVMSG $test :Timer Active Already. Killing Active Timer Now."
		stop
		putnow "PRIVMSG $test :Activating Timer Now"
		#Starting Check DJ Timer
		checkdj
		#Starting Check Peak Timer
		maxlisteners
		#Starting Advertisment Timer
		run_periodically #Torrent-Invites
		#Starting Advertisement Timer
		run_periodically #TI-Radio
		#Starting Delete Request Timer
		deletereq
	}
}

####################################
## Advertisments for who is !NP ##
####################################

proc run_periodically {chan} {
	if {[validchan #BotDev] && [botonchan #BotDev]} {
		global siteurl djch title dj test playlist streamch dj song genre firstad
		::http::config -useragent "Mozilla/5.0; Shoutinfo"
		timer 60 [list run_periodically $chan]
		set http_req [::http::geturl $siteurl -timeout 2000]
		if {[::http::status $http_req] != "ok"} {
			putnow "PRIVMSG $test :ABORT ABORT"
		} else {
			set data [::http::data $http_req]
			::http::cleanup $http_req
			if {[regexp {<font class=default>Stream Title: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
				set dj $title
			} else {
				unset dj
			}
			if {[regexp {<font class=default>Stream Genre: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
				set genre $title
			} else {
				unset genre
			}
			if {[regexp {<font class=default>Current Song: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
				set song $title
			} else {
				unset song
			}
			if {$firstad != 0} {
				if {$dj == "TI-Radio AutoDj" || $song == 0 || $dj == 0 || $dj == 0} {
					putnow "PRIVMSG $test :AutoDJ is On or Server is Offline."
				} else {
					if {[string match *c* [lindex [split [getchanmode $chan]] 0]]} {
						set a "\002$dj is live on the TI-Radio\002 || \002Genre\002: $genre || "
						set b  "\002Now Playing \002: $song || \002Listen @ $playlist \002"
						putnow "PRIVMSG $chan : $a$b"
					} else {
						set c "\002\00303$dj is live on the TI-Radio\002\00303\00307 ||  "
						set d "\00307\003\002Genre\002: $genre \003\00307|| \00307\003\002Now Playing "
						set e "\002: $song \003\00307||\00307 \003\00304\002 Listen @ $playlist \002\00304"
						putnow "PRIVMSG $chan : $c$d$e"
					}
				}
			} else {
				set firstad 1
			}
		}
		return 1;
	}
}

####################################
## Functions for if DJ is Online ##
####################################

proc djonline {} {
	global dj
	return [info exists dj]
}

proc djauto {} {
	global dj
	if {![djonline]} { return 0 }
	return [isautodj $dj]
}

proc isautodj {string} {
	expr {$string == "TI-Radio AutoDj"}
}

####################################
## Command to get Last Played List##
####################################

bind pub -|- !lp songlist
proc songlist {nick uhost hand chan arg} {
	global dj test siteurl newdj urlhistory djch length title
	if {![validchan #BotDev] || ![botonchan #BotDev]} { return }
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $urlhistory -timeout 2000]
	if {[::http::status $http_req] != "ok"} {
		# we assume the server is offline
		putnow "PRIVMSG $test : Unable to connect"
		return
	}
	set data [::http::data $http_req]
	::http::cleanup $http_req
	set testvalue 0
	foreach {x length title} [regexp -all -inline {<td>(\d\d:\d\d:\d\d)</td><td>([^<]+-[^<]+)<} $data] {
		if {$testvalue != 0} {
			putnow "notice $nick :#$testvalue: $length | $title"
			incr testvalue
		} else {
			putnow "notice $nick :\002Current Song\002: $length | $title "
			incr testvalue
		}

	}
}

####################################
## Checks if DJ has changed - 10s ##
####################################

proc checkdj {} {
	global dj test siteurl newdj djch
	if {![validchan #BotDev] || ![botonchan #BotDev]} { return }
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	after 10000 [list checkdj]
	if {[::http::status $http_req] != "ok"} {
		# we assume the server is offline
		putnow "PRIVMSG $test :Assumption: Server is Offline or Lagging"
		return
	}
	set data [::http::data $http_req]
	::http::cleanup $http_req
	if {![regexp {<font class=default>Stream Title: </font></td><td><font class=default><b>([^<]+)</b>} $data x newdj]} {
		if {[djonline]} {
			#Online -> Offline
			if {[djauto]} {
				#Auto DJ -> Offline
				serveroffline
				unset dj
			} elseif {![isautodj $newdj]} {
				#Real DJ -> Offline
				offair
				unset dj
			}
		}
		return
	}

	if {![djonline]} {
		# Offline -> Online
		if {![isautodj $newdj]} {
			#Offline -> Real DJ
			onair
		} else {
			#Offline -> Auto DJ
			autodjon
		}
	} elseif {$dj != $newdj} {
		# Generic state change
		if {[djauto]} {
			#AutoDJ -> Real DJ
			onair
		} elseif {[isautodj $newdj]} {
			#Real DJ -> AutoDJ
			autooffair
		} else {
			#Real DJ -> Real DJ
			tempoffair
			set dj $newdj
			onair
		}
	}
	set dj $newdj
	return 1;
}

####################################
## Checks if peaked in listeners ##
####################################

proc maxlisteners {} {
	global test siteurl peakfile djch
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	after 100000 [list maxlisteners]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $test :Assumption: Server is Offline or Lagging"
	} else {
		set data [::http::data $http_req]
		::http::cleanup $http_req
		if {[regexp {<font class=default>Listener Peak: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
			set testdata $title
			set peakfile [open "peak.txt" r]
			gets $peakfile line
			set peakhigh $line
			close $peakfile
			if {$testdata > $peakhigh} {
				# Create a Timestamp for the file
				set timestamp [clock format [clock seconds] -format {%Y%m%d%H%M%S}]
				set filename "peak.txt"
				# Create a Temp and Backup File
				set temp $filename.new.$timestamp
				# Set In/Out to Open Peak.txt in Read-Only/Write-Only
				set in [open $filename r]
				set out [open $temp w]
				while {[gets $in line] != -1} {
					set line $testdata
					puts $out $line
				}
				putnow "PRIVMSG $djch :Max Viewers has increased :D! Good job."
				# Close Both Files
				close $in
				close $out
				# Rename Temp to Original File Name
				file rename -force $temp $filename
			}
		}
	}
}

####################################
## Advert if Offline->RealDJ ##
####################################

proc onair {} {
	global streamch djch isair siteurl userair djcheck dj newdj main
	set a "\002$newdj\002 - Is Now Broadcasting Live! Tune "
	set b "in @ http://216.104.37.26:9005/listen.pls"
	set c "$newdj is now ON AIR @ "
	set d "#TI-Radio (http://216.104.37.26:9005/listen.pls)"
	set e "Torrent-Invites Radio || Status: DJ On Air || $newdj Is Now Broadcasting || "
	set f "URL: http://216.104.37.26:9005/listen.pls || Want to be a DJ?: http://bit.ly/J6cWtN"
	putnow "PRIVMSG $streamch : $a$b"
	putnow "PRIVMSG $djch :\002ON AIR\002: $newdj is now ON AIR."
	putnow "PRIVMSG $main : $c$d"
	putnow "TOPIC $streamch : $e$f"
}

####################################
## Advert if RealDJ->RealDJ ##
####################################

proc tempoffair {} {
	global streamch djch userair djcheck dj main
	set streamch [string tolower $streamch]
	if {$dj != 0} {
		putnow "PRIVMSG $streamch :\002OFF AIR\002: $dj is now OFF AIR."
		putnow "PRIVMSG $djch :\002OFF AIR\002: $dj is now OFF AIR."
	}
}

####################################
## Advert if Offline->AutoDJ ##
####################################

proc autodjon {} {
	global streamch djch userair djcheck dj main
	set streamch [string tolower $streamch]
	set a "Torrent-Invites Radio || Status: AutoDJ ||"
	set b "URL: http://216.104.37.26:9005/listen.pls || Want to be a DJ?: http://bit.ly/J6cWtN" 
	putnow "TOPIC $streamch : $a$b"
}

####################################
## Advert if Someone->Offline ##
####################################

proc serveroffline {} {
	global streamch djch userair djcheck dj main
	set streamch [string tolower $streamch]
	set a "Torrent-Invites Radio || Status: Stream Offline ||"
	set b " URL: http://216.104.37.26:9005/listen.pls || Want to be a DJ?: http://bit.ly/J6cWtN"
	putnow "TOPIC $streamch : $a$b"
}

####################################
## Advert if RealDJ->AutoDJ ##
####################################

proc autooffair {} {
	global streamch djch userair djcheck dj main
	set streamch [string tolower $streamch]
	set a "Torrent-Invites Radio || Status: AutoDJ || "
	set b "URL: http://216.104.37.26:9005/listen.pls || Want to be a DJ?: http://bit.ly/J6cWtN"
	putnow "PRIVMSG $streamch :\002OFF AIR\002: $dj is now OFF AIR."
	putnow "PRIVMSG $djch :\002OFF AIR\002: $dj is now OFF AIR."
	putnow "TOPIC $streamch : $a$b"

}

####################################
## Advert if Server if Offline ##
####################################

proc offair {} {
	global streamch djch userair djcheck dj main
	set streamch [string tolower $streamch]
	set a "Torrent-Invites Radio || Status: Stream Offline || "
	set b "URL: http://216.104.37.26:9005/listen.pls || Want to be a DJ?: http://bit.ly/J6cWtN"
	putnow "PRIVMSG $streamch :\002OFF AIR\002: $dj is now OFF AIR."
	putnow "PRIVMSG $djch :\002OFF AIR\002: $dj is now OFF AIR."
	putnow "PRIVMSG $djch :\00304$dj, please remember to \002TURN ON AUTODJ\002 \00304"
	putnow "TOPIC $streamch : $a$b"
}

####################################
## Save Song Info (Personal) ##
####################################

bind pub n|n !save saving
proc saving {nick uhost hand chan arg} {
	global siteurl test
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $test :ABORT ABORT"
	} else {
		set data [::http::data $http_req]
		::http::cleanup $http_req
		if {[regexp {<font class=default>Current Song: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
			set savefile [open "savedsongs.txt" w]
			puts $savefile $title
			putnow "PRIVMSG $chan :Song has been saved"
			close $savefile
		}
	}
}

####################################
## Advert the Request List ##
####################################

bind pub -|- !reqlist requestlist
proc requestlist {nick uhost hand chan arg} {
	global djch
	putnow "NOTICE $nick :\002\The OLDEST request will be deleted every 10 minutes.\002"
	if {$chan == $djch} {
		set reqnumber 0
		set filename "requestlist.txt"
		set in [open $filename r]
		while {1} {
			set line [gets $in]
			if {$line == ""} {
				putnow "PRIVMSG $djch :There are no requests at the moment."
				break
			} else {
				if {[eof $in]} {
					putnow "PRIVMSG $djch :Oldest: $line"
					close $in
					break
				}
				if {$reqnumber == 0} {
					putnow "PRIVMSG $djch :Newest: $line"
					incr reqnumber
				} else {
					putnow "PRIVMSG $djch :$reqnumber: $line"
					incr reqnumber
				}
			}
		}
	}
}

####################################
## Clear the Request List ##
####################################

bind pub -|- !clearlist clearlist
proc clearlist {nick uhost hand chan arg} {
	global djch
	if {$chan == $djch} {
		if {[isop $nick $chan] == 1 || [ishalfop $nick $chan] == 1} {
			set filename "requestlist.txt"
			set out [open $filename w]
			set line ""
			puts $out $line
			putnow "PRIVMSG $djch :$nick has cleared the request list."
			close $out
		}
	}
}

####################################
## Delete Request Func + Timer ##
####################################

proc deletereq {} {
	global djch test
	timer 10 [list deletereq]
	set filename "requestlist.txt"
	set fp [open $filename r+]
	set data [read -nonewline $fp]
	set lines [split $data "\n"]
	close $fp
	set line_to_delete [expr [llength $lines] - 1]
	set lines [lreplace $lines $line_to_delete $line_to_delete]
	set fp [open $filename w+]
	if {[gets $fp data] >= 1} {
		puts -nonewline $fp $lines
		close $fp
	} else {
		puts -nonewline $fp [join $lines "\n"]
		close $fp
	}
	putnow "PRIVMSG $test :Deleting a Request"
}

####################################
## Delete Request Func + Timer ##
####################################

proc requestproc {reqitem} {
	set filename "requestlist.txt"
	set testin [open $filename r]
	set line [gets $testin]
	close $testin
	if {$line == ""} {
		set out [open $filename [list RDWR APPEND CREAT]]
		set newline $reqitem
		puts -nonewline $out $newline
		close $out
	} else {
		# Create a Timestamp for the file
		set timestamp [clock format [clock seconds] -format {%Y%m%d%H%M%S}]
		# Create a Temp and Backup File
		set temp $filename.new.$timestamp
		# Set In/Out to Open Peak.txt in Read-Only/Write-Only
		set in [open $filename r]
		set out [open $temp [list RDWR APPEND CREAT]]
		set line $reqitem
		puts $out $line
		set file_data [read $in]
		puts -nonewline $out $file_data
		close $in
		close $out
		file rename -force $temp $filename
	}
}

####################################
## Command to Start Timers ##
####################################

bind pub -|- !start starttimers
proc starttimers {nick uhost hand chan arg} {
	global djch
	if {$chan == $djch} {
		if {[isop $nick $djch] == 1 || [ishalfop $nick $djch] == 1} {
			putserv "PRIVMSG $chan :$nick started the timers."
			putlog "$nick started the timers."
			start
		}
	}
}

####################################
## Command to Rehash the Bot ##
####################################

bind pub -|- !rehash prehash
proc prehash {nick uhost hand chan arg} {
	global djch
	if {$chan == $djch} {
		if {[isop $nick $djch] == 1 || [ishalfop $nick $djch] == 1} {
			putserv "PRIVMSG $chan :$nick rehashed me."
			putlog "$nick rehashed the bot"
			[rehash]
		}
	}
}

####################################
## Command to Show Now Playing ##
####################################

bind pub -|- !np song
proc song {nick uhost hand chan arg} {
	global siteurl streamch dj djch main
	set streamch [string tolower $streamch]
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $chan :Stream is unavailable";
	}
	set data [::http::data $http_req]
	::http::cleanup $http_req
	if {[regexp {<font class=default>Current Song: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
		putnow "PRIVMSG $chan :\002Current Song\002: $title"
	} else {
		if {$chan != $main} {
			putnow "PRIVMSG $chan :Couldn't receive any information, checking server status..."
		} else {
			putnow "NOTICE $nick :Couldn't receive any information, checking server status..."
		}
	}

}

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

####################################
## Command to show who is DJ ##
####################################

bind pub -|- !dj deejay
proc deejay {nick uhost hand chan arg} {
	global siteurl streamch dj title djch main
	set streamch [string tolower $streamch]
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $chan :Stream is unavailable";
	}
	set data [::http::data $http_req]
	::http::cleanup $http_req
	if {[regexp {<font class=default>Stream Title: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
		if {$chan != $main} {
			putnow "PRIVMSG $chan :\002DJ\002: $title"
			set dj $title
		} else {
			putnow "NOTICE $nick :\002DJ\002: $title"
			set dj $title
		}
	} else {
		if {$chan != $main} {
			putnow "PRIVMSG $chan :Couldn't receive any information, checking server status..."
		} else {
			putnow "NOTICE $nick :Couldn't receive any information, checking server status..."
		}
	}
}

####################################
## Command to get Login Info ##
####################################

bind pub -|- !login login
proc login {nick uhost hand chan arg} {
	global test djch main
	if {$chan == $djch} {
		if {[isop $nick $djch] == 1 || [ishalfop $nick $djch] == 1} {
			putnow "NOTICE $nick : URL: http://panel5.hostingmembercenter.com"
			putnow "NOTICE $nick : Username: grjwalfd"
			putnow "NOTICE $nick : Password: tiradiorocksme"
		} else {
			putnow "NOTICE $nick :Sorry $nick, but you're not a halfop or greater in #DJ."
		}
	} else {
		putnow "NOTICE $nick :Sorry $nick, this is a DJ Channel only command."
	}
}

####################################
## Command to get URL Info ##
####################################

bind pub -|- !url site
proc site {nick uhost hand chan arg} {
	global siteurl streamch djch main url
	if {$chan != $main} {
		putnow "PRIVMSG $chan :\002Website\002: $siteurl"
	} else {
		putnow "NOTICE $nick :\002Website\002: $siteurl"
	}
}

####################################
## Command to get Server Info ##
####################################

bind pub -|- !server servers
proc servers {nick uhost hand chan arg} {
	global siteurl streamch djch main
	set streamch [string tolower $streamch]
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $chan :Stream is unavailable";
	}
	set data [::http::data $http_req]
	::http::cleanup $http_req
	if {[regexp {<font class=default>Server Status: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
		if {$chan != $main} {
			putnow "PRIVMSG $chan :\ 002Server \002: $title"
		} else {
			putnow "PRIVMSG $nick :\ 002Server \002: $title"
		}
	} else {
		if {$chan != $main} {
			putnow "PRIVMSG $chan :Couldn't contact the server, please check the configuration and/or streaming server"
		} else {
			putnow "NOTICE $nick :Couldn't contact the server, please check the configuration and/or streaming server"
		}
	}
}

####################################
## Command to get current Genre ##
####################################

bind pub -|- !genre genre
proc genre {nick uhost hand chan arg} {
	global siteurl streamch djch main
	set streamch [string tolower $streamch]
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $chan :Stream is unavailable";
	}
	set data [::http::data $http_req]
	::http::cleanup $http_req
	if {[regexp {<font class=default>Stream Genre: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
		if {$chan != $main} {
			putnow "PRIVMSG $chan :\002Genre\002: $title"
		} else {
			putnow "NOTICE $nick :\002Genre\002: $title"
		}
	} else {
		if {$chan != $main} {
			putnow "PRIVMSG $chan :Couldn't receive any information, checking server status..."
		} else {
			putnow "NOTICE $nick :Couldn't receive any information, checking server status..."
		}
	}
}

####################################
## Command to get Server Status ##
####################################

bind pub -|- !status status
proc status {nick uhost hand chan arg} {
	global siteurl streamch djch main
	set streamch [string tolower $streamch]
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $chan :Stream is unavailable";
	}
	set data [::http::data $http_req]
	::http::cleanup $http_req
	if {[regexp {B>([^<]+) of} $data x title]} {
		regexp { of ([^<]+) listeners} $data x title2
		regexp {listeners ([^<]+)} $data x title3
		regexp {Stream is up at ([^<]+) with} $data x title4
		if {$chan != $main} {
			putnow "PRIVMSG $chan :\002Status\002: $title of $title2 $title3 at $title4"
		} else {
			putnow "NOTICE $nick :\002Status\002: $title of $title2 $title3 at $title4"
		}
	} else {
		if {$chan != $main} {
			putnow "PRIVMSG $chan :Couldn't receive any information, checking server status..."
		} else {
			putnow "NOTICE $nick :Couldn't receive any information, checking server status..."
		}
	}
}

####################################
## Command to get Peak Info ##
####################################

bind pub -|- !peak peak
proc peak {nick uhost hand chan arg} {
	global siteurl streamch djch main
	set streamch [string tolower $streamch]
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $chan :Stream is unavailable";
	}
	set data [::http::data $http_req]
	::http::cleanup $http_req
	if {[regexp {<font class=default>Listener Peak: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
		if {$chan != $main} {
			set peakfile [open "peak.txt" r]
			gets $peakfile line
			set peakhigh $line
			close $peakfile
			putnow "PRIVMSG $chan :\002Session Peak\002: $title \002Overall Peak\002: $peakhigh "
		}
	} else {
		if {$chan != $main} {
			putnow "PRIVMSG $chan :Couldn't receive any information, checking server status..."
		} else {
			putnow "NOTICE $nick :Couldn't receive any information, checking server status..."
		}
	}
}

####################################
## Command to get Listen ##
####################################

bind pub -|- !listen pls
proc pls {nick uhost hand chan arg} {
	global playlist
	putnow "PRIVMSG $chan :\002Stream/Listen\002: $playlist"
}


####################################
## Command to get Command FAQ     ##
####################################

bind pub -|- !commands commands
proc commands {nick uhost hand chan arg} {
	global streamch commands djch main
	set streamch [string tolower $streamch]
	if {$chan != $main} {
		if {$chan == $djch} {
			set a "\002DJ/Admin Commands\002: !rehash !start !login "
			set b "+cookie -cookie !reqlist !clearlist"
			set c "\002Radio Commands\002: !listen !np !lp !dj !peak"
			set d "!request !status !genre !server"
			putnow "PRIVMSG $chan : $a$b"
			putnow "PRIVMSG $chan : $c$d"
		} else {
			set e "\002Radio Commands\002: !listen !np !lp !dj !peak "
			set f "!request !status !genre !server"
			putnow "PRIVMSG $chan : $e$f"
		}
	} else {
		set g "\002Radio Commands\002: !listen !np !lp !dj !peak "  
		set h "!request !status !genre !server"
		putnow "NOTICE $nick : $g$h"
	}
}

####################################
## Command to submit a request ##
####################################

bind pub -|- !request request
proc request {nick uhost hand chan arg} {
	global streamch djch reqitem
	set streamch [string tolower $streamch]
	if {[string tolower $chan] == "$streamch"} {
		if {[llength $arg]==0} {
			putnow "PRIVMSG $chan :\002Syntax\002: !request <Artist - Title>"
		} else {
			if {[string match *Bieber* $arg] || [string match *Beiber* $arg]} {
				putnow "PRIVMSG $chan :Troll Alert!"
				putkick $chan $nick "Stop trolling.."
			} else {
				set reqitem $arg
				requestproc $reqitem
				set query1 "http://www.waffles.fm/browse.php?q="
				set query2 "http://what.cd/torrents.php?searchstr="
				for { set index 0 } { $index<[llength $arg] } { incr index } {
					set query1 "$query1[lindex $arg $index]"
					if {$index<[llength $arg]-1} then {
						set query1 "$query1+"
					}
				}
				for { set index 0 } { $index<[llength $arg] } { incr index } {
					set query2 "$query2[lindex $arg $index]"
					if {$index<[llength $arg]-1} then {
						set query2 "$query2+"
					}
				}
				set a "PRIVMSG $djch :\002\Request\002: $arg | Requested by:\002 "
				set b "$nick \002 | \002Waffles\002: $query1 | \002What.CD\002: $query2"
				putnow "$a$b"
				putnow "NOTICE $nick :\002$arg\002 is succesfully requested"
				set token [http::config -useragent "Mozilla/5.0; Shoutinfo"]
				set token [http::geturl $query1]
				puts stderr ""
				upvar #0 $token state
				set max 0
			}

		}
	}
}
