###############################																		
###Shoutcast Radio Bot by Sky##					
###############################                                                                   


# We need to grab stuff from the internet
package require http

# Set Variables to Shoutcast Webpages
set siteurl "http://216.104.37.26:9005"
set listenurl "http://216.104.37.26:9005/listen.pls"
set lastplayed "http://216.104.37.26:9005/played.html"

# Channels Names (Log Channel, DJ Channel, Radio Channel, Main Channel)
set djchan "#dj"
set mainchan "#main"
set logchan "#log"
set radiochan "#radio"

# Set Variables to Database Info
set dbhost "localhost"
set dbuser "user"
set dbpass "password"
set dbname "db"

# AutoDJ's Name
set autodj "AutoDj"

sset song 0

# Binding ! commands to fucntions
bind pub -|- !lst lastsessions
bind pub -|- !start starttimers 
bind pub -|- !lp songlist
bind pub -|- !server serverinfo
bind pub -|- !clearlist clearlist
bind pub -|- !reqlist requestlist
bind pub -|- !np nowplaying
bind pub -|- !request request
bind pub -|- !peak peak
bind pub -|- !dj deejay
bind pub -|- !genre genre
bind pub -|- !listen pls
bind pub -|- !log getlog
bind pub -|- !topdj toplog
bind pub -|- !url site
bind pub -|- !commands commands

# Functions: Start and Stop Timer
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

## Functions for if DJ is Online
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
	global autodj
	expr {$string == $autodj}
}

## Refreshing bot resets timers
proc start {} {
	global logchan
	if {[hasTimers] == 0} {
		putnow "PRIVMSG $logchan :No Timers Active. Activating Timer Now."
	#Starting Check DJ Timer
		checkdj
	#Starting Check Peak Timer
		maxlisteners
	#Starting Advertisment Timer
		#run_periodically #TI-Radio
	#Starting Advertisement Timer
		#run_periodically #
	#Starting Delete Request Timer
		deletereq
		set firstad 0
	} else {
		putnow "PRIVMSG $logchan :Timer Active Already. Killing Active Timer Now."
	# Stop All Timers 2
		stop
		putnow "PRIVMSG $logchan :Activating Timer Now"
	#Starting Check DJ Timer
		checkdj
	#Starting Check Peak Timer
		maxlisteners
	#Starting Advertisment Timer
		#run_periodically #
	#Starting Advertisement Timer
		#run_periodically #TI-Radio
	#Starting Delete Request Timer
		deletereq
		set firstad 0
	}
}

## Advertisments for who is !NP
# proc run_periodically {chan} {
# 	if {[validchan #BotDev] && [botonchan #BotDev]} {
# 		global siteurl djchan title dj logchan listenurl radiochan dj song genre firstad autodj
# 		::http::config -useragent "Mozilla/5.0; Shoutinfo"
# 		timer 60 [list run_periodically $chan]
# 		set http_req [::http::geturl $siteurl -timeout 2000]
# 		if {[::http::status $http_req] != "ok"} {
# 			putnow "PRIVMSG $logchan :ABORT ABORT"
# 		} else {
# 			set data [::http::data $http_req]
# 			::http::cleanup $http_req
# 			if {[regexp {<font class=default>Stream Title: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
# 				set dj $title
# 			} else {
# 				catch {unset dj}
# 			}
# 			if {[regexp {<font class=default>Stream Genre: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
# 				set genre $title
# 			} else {
# 				catch {unset genre}
# 			}
# 			if {[regexp {<font class=default>Current Song: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
# 				set song $title
# 			} else {
# 				catch {unset song}
# 			}
# 				if {$dj == $autodj || $song == 0 || $dj == 0 || $dj == 0} {
# 					putnow "PRIVMSG $logchan :AutoDJ is On or Server is Offline."
# 				} else {
# 					if {[string match *c* [lindex [split [getchanmode $chan]] 0]]} {
# 						set a "\002$dj is live on the TI-Radio\002 || \002Genre\002: $genre || "
# 						set b  "\002Now Playing\002: $song || \002Listen @ $listenurl \002"
# 						putnow "PRIVMSG $chan : $a$b"
# 					} else {
# 						set c "\002\00303$dj is live on the TI-Radio\002\00303\00307 ||  "
# 						set d "\00307\003\002Genre\002: $genre \003\00307|| \00307\003\002Now Playing"
# 						set e "\002: $song \003\00307||\00307 \003\00304\002 Listen @ $listenurl \002\00304"
# 						putnow "PRIVMSG $chan : $c$d$e"
# 					}
# 				}
# 			}
# 		}
# 		return 1;
# 	}

## Checks if DJ has changed - 10s 
proc checkdj {} {
	global dj logchan siteurl newdj djchan
	if {![validchan #BotDev] || ![botonchan #BotDev]} { return }
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	after 10000 [list checkdj]
	if {[::http::status $http_req] != "ok"} {
		# we assume the server is offline
		putnow "PRIVMSG $logchan :Assumption: Server is Offline or Lagging"
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
				catch {unset dj}
			} elseif {![isautodj $newdj]} {
				#Real DJ -> Offline
				offair
				finishsave $dj
				catch {unset dj}
			}
		}
		return
	}

	if {![djonline]} {
		# Offline -> Online
		if {![isautodj $newdj]} {
			#Offline -> Real DJ
			onair
			set dj $newdj
			startsave $dj
		} else {
			#Offline -> Auto DJ
			set dj $newdj
			autodjon
		}
	} elseif {$dj != $newdj} {
		# Generic state change
		if {[djauto]} {
			#AutoDJ -> Real DJ
			set dj $newdj
			startsave $dj
			onair
		} elseif {[isautodj $newdj]} {
			#Real DJ -> AutoDJ
			finishsave $dj
			autooffair
			set dj $newdj
		} else {
			#Real DJ -> Real DJ
			tempoffair
			finishsave $dj
			set dj $newdj
			startsave $dj
			onair
		}
	}
	return
}

## Checks if peaked in listeners 
proc maxlisteners {} {
	global logchan siteurl peakfile djchan
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	after 100000 [list maxlisteners]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $logchan :Assumption: Server is Offline or Lagging"
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
				putnow "PRIVMSG $djchan :Max Viewers has increased :D! Good job."
				# Close Both Files
				close $in
				close $out
				# Rename Temp to Original File Name
				file rename -force $temp $filename
			}
		}
	}
}

## Command to Start Timers 
proc starttimers {nick uhost hand chan arg} {
	global djchan
	if {$chan == $djchan} {
		if {[isop $nick $djchan] == 1 || [ishalfop $nick $djchan] == 1} {
			putserv "PRIVMSG $chan :$nick started the timers."
			putlog "$nick started the timers."
			start
		}
	}
}


## Command to get Last Played List
proc songlist {nick uhost hand chan arg} {
	global dj logchan siteurl newdj lastplayed 
	if {![validchan #BotDev] || ![botonchan #BotDev]} { return }
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $lastplayed -timeout 2000]
	if {[::http::status $http_req] != "ok"} {
		# we assume the server is offline
		putnow "PRIVMSG $logchan : Unable to connect"
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

## Advert the Request List 
proc requestlist {nick uhost hand chan arg} {
	global djchan
	putnow "NOTICE $nick :\002\The OLDEST request will be deleted every 10 minutes.\002"
	if {$chan == $djchan} {
		set reqnumber 0
		set filename "requestlist.txt"
		set in [open $filename r]
		while {1} {
			set line [gets $in]
			if {$line == ""} {
				putnow "PRIVMSG $djchan :There are no requests at the moment."
				break
			} else {
				if {[eof $in]} {
					putnow "PRIVMSG $djchan :Oldest: $line"
					close $in
					break
				}
				if {$reqnumber == 0} {
					putnow "PRIVMSG $djchan :Newest: $line"
					incr reqnumber
				} else {
					putnow "PRIVMSG $djchan :$reqnumber: $line"
					incr reqnumber
				}
			}
		}
	}
}

## Clear the Request List 
proc clearlist {nick uhost hand chan arg} {
	global djchan
	if {$chan == $djchan} {
		if {[isop $nick $chan] == 1 || [ishalfop $nick $chan] == 1} {
			set filename "requestlist.txt"
			set out [open $filename w]
			set line ""
			puts $out $line
			putnow "PRIVMSG $djchan :$nick has cleared the request list."
			close $out
		}
	}
}

## Delete Request Func + Timer
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

## Command to Show Now Playing 
proc nowplaying {nick uhost hand chan arg} {
	global siteurl radiochan mainchan
	set radiochan [string tolower $radiochan]
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
		if {$chan != $mainchan} {
			putnow "PRIVMSG $chan :Couldn't receive any information, checking server status..."
		} else {
			putnow "NOTICE $nick :Couldn't receive any information, checking server status..."
		}
	}

}

## Command to show who is DJ
proc deejay {nick uhost hand chan arg} {
	global siteurl radiochan dj mainchan
	set radiochan [string tolower $radiochan]
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $chan :Stream is unavailable";
	}
	set data [::http::data $http_req]
	::http::cleanup $http_req
	if {[regexp {<font class=default>Stream Title: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
		if {$chan != $mainchan} {
			putnow "PRIVMSG $chan :\002DJ\002: $title"
			set dj $title
		} else {
			putnow "NOTICE $nick :\002DJ\002: $title"
			set dj $title
		}
	} else {
		if {$chan != $mainchan} {
			putnow "PRIVMSG $chan :Couldn't receive any information, checking server status..."
		} else {
			putnow "NOTICE $nick :Couldn't receive any information, checking server status..."
		}
	}
}

## Command to get URL Info
proc site {nick uhost hand chan arg} {
	global siteurl mainchan
	if {$chan != $mainchan} {
		putnow "PRIVMSG $chan :\002Website\002: $siteurl"
	} else {
		putnow "NOTICE $nick :\002Website\002: $siteurl"
	}
}

## Command to get Server Info
proc serverinfo {nick uhost hand chan arg} {
	global siteurl radiochan mainchan
	set radiochan [string tolower $radiochan]
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $chan :Stream is unavailable";
	}
	set data [::http::data $http_req]
	::http::cleanup $http_req
	if {[regexp {<font class=default>Server Status: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
		if {$chan != $mainchan} {
			putnow "PRIVMSG $chan :\  002Server  \002: $title"
		} else {
			putnow "PRIVMSG $nick :\  002Server  \002: $title"
		}
	} else {
		if {$chan != $mainchan} {
			putnow "PRIVMSG $chan :Couldn't contact the server, please check the configuration and/or streaming server"
		} else {
			putnow "NOTICE $nick :Couldn't contact the server, please check the configuration and/or streaming server"
		}
	}
}

## Command to get current Genre
proc genre {nick uhost hand chan arg} {
	global siteurl radiochan mainchan
	set radiochan [string tolower $radiochan]
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 2000]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $chan :Stream is unavailable";
	}
	set data [::http::data $http_req]
	::http::cleanup $http_req
	if {[regexp {<font class=default>Stream Genre: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
		if {$chan != $mainchan} {
			putnow "PRIVMSG $chan :\002Genre\002: $title"
		} else {
			putnow "NOTICE $nick :\002Genre\002: $title"
		}
	} else {
		if {$chan != $mainchan} {
			putnow "PRIVMSG $chan :Couldn't receive any information, checking server status..."
		} else {
			putnow "NOTICE $nick :Couldn't receive any information, checking server status..."
		}
	}
}

## Command to get Peak Info
proc peak {nick uhost hand chan arg} {
	global siteurl radiochan mainchan
	set radiochan [string tolower $radiochan]
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set http_req [::http::geturl $siteurl -timeout 20000]
	if {[::http::status $http_req] != "ok"} {
		putnow "PRIVMSG $chan :Stream is unavailable";
	}
	set data [::http::data $http_req]
	::http::cleanup $http_req
	if {[regexp {<font class=default>Listener Peak: </font></td><td><font class=default><b>([^<]+)</b>} $data x title]} {
		if {$chan != $mainchan} {
			set peakfile [open "peak.txt" r]
			gets $peakfile line
			set peakhigh $line
			close $peakfile
			putnow "PRIVMSG $chan :\002Session Peak\002: $title \002Overall Peak\002: $peakhigh "
		}
	} else {
		if {$chan != $mainchan} {
			putnow "PRIVMSG $chan :Couldn't receive any information, checking server status..."
		} else {
			putnow "NOTICE $nick :Couldn't receive any information, checking server status..."
		}
	}
}

## Command to get Listen
proc pls {nick uhost hand chan arg} {
	global listenurl
	putnow "PRIVMSG $chan :\002Stream/Listen\002: $listenurl"
}

## Command to get Command FAQ
proc commands {nick uhost hand chan arg} {
	global radiochan djchan mainchan
	set radiochan [string tolower $radiochan]
	if {$chan != $mainchan} {
		if {$chan == $djchan} {
			set a "\002DJ/Admin Commands\002: !rehash !start !login "
			set b "+cookie -cookie !reqlist !clearlist"
			set c "\002Radio Commands\002: !listen !np !lp !dj !peak"
			set d "!request !genre !server !topdj"
			putnow "PRIVMSG $chan : $a$b"
			putnow "PRIVMSG $chan : $c$d"
		} else {
			set e "\002Radio Commands\002: !listen !np !lp !dj !peak "
			set f "!request !genre !server !topdj"
			putnow "PRIVMSG $chan : $e$f"
		}
	} else {
		set g "\002Radio Commands\002: !listen !np !lp !dj !peak "
		set h "!request !genre !server !topdj"
		putnow "NOTICE $nick : $g$h"
	}
}

## Command to submit a request
proc request {nick uhost hand chan arg} {
	global radiochan djchan reqitem 
	set radiochan [string tolower $radiochan]
	if {[string tolower $chan] == "$radiochan"} {
		if {[llength $arg]==0} {
			putnow "PRIVMSG $chan :\002Syntax\002: !request <Artist - Title>"
		} else {
			if {[string match *Bieber* $arg] || [string match *Beiber* $arg]} {
				if {[isop $nick $chan] || [ishalfop $nick $chan]} {
					putnow "PRIVMSG $chan :Troll Alert!"
				} else {
					putnow "PRIVMSG $chan :Troll Alert!"
					putkick $chan $nick "Stop trolling.."
				}
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
				set a "PRIVMSG $djchan :\002\Request\002: $arg | Requested by:\002 "
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

##     !log DJ Log Information
proc getlog {nick uhost hand chan arg} {
	global dbhost dbuser dbname dbpass
	set m [mysqlconnect -host $dbhost -user $dbuser -db $dbname -password $dbpass]
	if {[llength $arg]==0} {
		set tt_query "SELECT total_time from djlog where dj_name='$nick'"
		set ts_query "SELECT total_sessions from djlog where dj_name='$nick'"
		set log_name $nick
	} else {
		set tt_query "SELECT total_time from djlog where dj_name='$arg'"
		set ts_query "SELECT total_sessions from djlog where dj_name='$arg'"
		set log_name $arg
	}
	set tt_result [mysqlsel $m $tt_query -list]
	set ts_result [mysqlsel $m $ts_query -list]
	if {$ts_result  != "" && $tt_result != "" } {
		set total_time [lindex $tt_result 0]
		set total_sessions [lindex $ts_result 0]
		set total_time [expr {$total_time*1}]
		set totalt [duration $total_time]
		putnow "PRIVMSG $chan : $log_name has been on air a total of $total_sessions times for $totalt."
	} else {
		putnow "PRIVMSG $chan : Sorry but $arg was not found in the log."
	}
}

##  First Save: Name + Onair Time
proc startsave {dj} {
	global dbhost dbuser dbname dbpass
	set start_time [clock seconds]
	set m [mysqlconnect -host $dbhost -user $dbuser -db $dbname -password $dbpass]
	set query "SELECT dj_name from session_log order by ID desc limit 1"
	set result [mysqlsel $m $query -list]
	set testname [lindex $result 0]
	putnow "PRIVMSG #BotDev : $testname"
	set testquery "SELECT offair_time from session_log order by ID desc limit 1"
	set testresult [mysqlsel $m $testquery -list]
	set testtime [lindex $testresult 0]
	putnow "PRIVMSG #BotDev : $testtime"
	if {$testtime != "{}" && $testname != $dj} {
		#####
		### session_log
		######
		set query "INSERT INTO session_log(dj_name, onair_time) VALUES('$dj', '$start_time')"
		set result [mysqlexec $m $query]
		######
		### djlog
		######
		set query "SELECT dj_name from djlog where dj_name='$dj'"
		set result [mysqlsel $m $query -list]
		set dj_name [lindex $result 0]
		if {$dj_name != ""} {
			set query "SELECT total_sessions from djlog where dj_name='$dj'"
			set result [mysqlsel $m $query -list]
			set total_sessions [lindex $result 0]
			incr total_sessions
			set query "UPDATE djlog set total_sessions=$total_sessions where dj_name='$dj'"
			set result [mysqlexec $m $query]
		} else {
			set query "INSERT INTO djlog(dj_name, total_sessions) VALUES('$dj', '1')"
			set result [mysqlexec $m $query]
		}
		if {$result} {
			putlog "DJ Database Entry Sent. $dj with $start_time"
		} else {
			putlog "Database error."
		}
		mysqlclose $m
	} elseif {$testname == $dj && $testtime != "{}"} {
				#####
		### session_log
		######
		set query "INSERT INTO session_log(dj_name, onair_time) VALUES('$dj', '$start_time')"
		set result [mysqlexec $m $query]
		######
		### djlog
		######
		set query "SELECT dj_name from djlog where dj_name='$dj'"
		set result [mysqlsel $m $query -list]
		set dj_name [lindex $result 0]
		if {$dj_name != ""} {
			set query "SELECT total_sessions from djlog where dj_name='$dj'"
			set result [mysqlsel $m $query -list]
			set total_sessions [lindex $result 0]
			incr total_sessions
			set query "UPDATE djlog set total_sessions=$total_sessions where dj_name='$dj'"
			set result [mysqlexec $m $query]
		} else {
			set query "INSERT INTO djlog(dj_name, total_sessions) VALUES('$dj', '1')"
			set result [mysqlexec $m $query]
		}
		if {$result} {
			putlog "DJ Database Entry Sent. $dj with $start_time"
		} else {
			putlog "Database error."
		}
		mysqlclose $m
	} elseif {$testname == $dj && $testtime == "{}"} {
		putnow "PRIVMSG #DJ :$dj is already in a session."
	}
}

## Second: Offair, Session, Total
proc finishsave {dj} {
	global djchan dbhost dbuser dbname dbpass
	set end_time [clock seconds]
	set m [mysqlconnect -host $dbhost -user $dbuser -db $dbname -password $dbpass]
	# Checking out the Top-Row's DJ Name
	set query "SELECT dj_name from session_log order by ID desc limit 1"
	set result [mysqlsel $m $query -list]
	set dj_name [lindex $result 0]
	set testquery "SELECT offair_time from session_log order by ID desc limit 1"
	set testresult [mysqlsel $m $testquery -list]
	set testtime [lindex $testresult 0]
	# If Our Arg is equal to DJ Name in Top Row
	if {$dj == $dj_name && $testtime == "{}"} {
		# Read when this person logged on-air
		set query "SELECT onair_time from session_log order by ID desc limit 1"
		set result [mysqlsel $m $query -list]
		set onair_time [lindex $result 0]
		# Calculate the session-time
		set session_time [expr {$end_time - $onair_time}]
		# Set session-time
		set query "UPDATE session_log set session_time=$session_time order by ID desc limit 1"
		set result [mysqlexec $m $query]
		# Set Offair-time
		set query "UPDATE session_log set offair_time=$end_time order by ID desc limit 1"
		set result [mysqlexec $m $query]
		######
		### djlog
		######
		
		# Read Total Time
		set query "SELECT total_time from djlog where dj_name='$dj'"
		set result [mysqlsel $m $query -list]
		set total_time [lindex $result 0]
		# This needs to be fixed or two tables created
		if {$total_time != "{}"} {
			set newtotal_time [expr {$total_time + $session_time}]
		} else {
			set newtotal_time $session_time
		}
		# Set New Total Time
		if {$session_time >= 600} {
			set query "UPDATE djlog set total_time=$newtotal_time where dj_name='$dj'"
			set result [mysqlexec $m $query]
			putnow "PRIVMSG $djchan : Session Time: $session_time Total Time: $newtotal_time"
		} else {
			putnow "PRIVMSG $djchan : $dj, your session was less than 10 minutes, thus your time was not recorded."
		}
		if {$result} {
			putlog "DJ Database Entry Sent. $dj with $session_time and $newtotal_time"
		} else {
			putlog "Database error."
		}
	} else {
		putnow "PRIVMSG $djchan :$dj, you never went on-air, thus your time was not recorded."
	}
}

##     Top 5 or $arg of DJ Log
proc toplog {nick uhost hand chan arg} {
	global dbhost dbuser dbname dbpass
	set m [mysqlconnect -host $dbhost -user $dbuser -db $dbname -password $dbpass]
	set name_query "SELECT dj_name from djlog order by total_time desc"
	set name_result [mysqlsel $m $name_query -list]
	set tt_query "SELECT total_time from djlog order by total_time desc"
	set ts_query "SELECT total_sessions from djlog order by total_time desc"
	set ts_result [mysqlsel $m $ts_query -list]
	set tt_result [mysqlsel $m $tt_query -list]
	set i 0
	set n 1
	if {[llength $arg]==0} {
		putnow "PRIVMSG $chan : Top 5 DJ Log"
		while {$i < 5} {
			set name [lindex $name_result $i]
			set total_time [lindex $tt_result $i]
			set total_sessions [lindex $ts_result $i]
			set total_time [expr {$total_time*1}]
			set total_time [duration $total_time]
			putnow "PRIVMSG $chan : #$n: $name with $total_time on-air and $total_sessions sessions."
			incr i
			incr n
		}
	} else {
		putnow "PRIVMSG $chan : Top $arg DJ Log"
		set arg [expr {$arg*1}]
		while {$i < $arg} {
			set name [lindex $name_result $i]
			set total_time [lindex $tt_result $i]
			set total_sessions [lindex $ts_result $i]
			set total_time [expr {$total_time*1}]
			set total_time [duration $total_time]
			putnow "PRIVMSG $chan : #$n: $name with $total_time on-air and $total_sessions sessions."
			incr i
			incr n
		}
	}
}


proc lastsessions {nick uhost hand chan arg} {
	global dbhost dbuser dbname dbpass
	set m [mysqlconnect -host $dbhost -user $dbuser -db $dbname -password $dbpass]
	set name_query "SELECT dj_name from session_log order by id desc"
	set name_result [mysqlsel $m $name_query -list]
	set on_query "SELECT onair_time from session_log order by id desc"
	set off_query "SELECT offair_time from session_log order by id desc"
	set on_result [mysqlsel $m $on_query -list]
	set off_result [mysqlsel $m $off_query -list]
	set session_query "SELECT session_time from session_log order by id desc"
	set session_result [mysqlsel $m $session_query -list]
	set i 0
	set n 1
	if {[llength $arg]==0} {
		putnow "PRIVMSG $chan : Last 5 DJ Sessions"
		while {$i < 5} {
			set name [lindex $name_result $i]
			set onairs [lindex $on_result $i]
			set offairs [lindex $off_result $i]
			set session_time [lindex $session_result $i]
			putnow "PRIVMSG $chan : #$n: $name with $onairs on-air and $offairs offair and $session_time session time."
			incr i
			incr n
		}
	} else {
		putnow "PRIVMSG $chan : Last $arg DJ Sessions"
		set arg [expr {$arg*1}]
		while {$i < $arg} {
			set name [lindex $name_result $i]
			set onairs [lindex $on_result $i]
			set offairs [lindex $off_result $i]
			set session_time [lindex $session_result $i]
			putnow "PRIVMSG $chan : #$n: $name with $onairs on-air and $offairs offair and $session_time session time."
			incr i
			incr n
		}
	}
}

## Delete Request Func + Timer
proc deletereq {} {
	global djchan logchan
	timer 10 [list deletereq]
	set filename "requestlist.txt"
	set fp [open $filename r+]
	set data [read -nonewline $fp]
	set lines [split $data "\n"]
	close $fp
	set line_to_delete [expr {[llength $lines] - 1}]
	set lines [lreplace $lines $line_to_delete $line_to_delete]
	set fp [open $filename w+]
	if {[gets $fp data] >= 1} {
		puts -nonewline $fp $lines
		close $fp
	} else {
		puts -nonewline $fp [join $lines "\n"]
		close $fp
	}
	putnow "PRIVMSG $logchan :Deleting a Request"
}

##  Calculate Seconds to D:H:M:S
proc duration { int_time } {
	set timeList [list]
	foreach div {604800 86400 3600 60 1} mod {0 7 24 60 60} name {wk day hr min sec} {
		set n [expr {$int_time / $div}]
		if {$mod > 0} {set n [expr {$n % $mod}]}
		if {$n > 1} {
			lappend timeList "$n ${name}s"
		} elseif {$n == 1} {
			lappend timeList "$n $name"
		}
	}
	return [join $timeList]
}

## Advert if Offline->RealDJ
proc onair {} {
	global radiochan djchan dj newdj mainchan
	set a "\002$newdj\002 - Is Now Broadcasting Live! Tune "
	set b "in @ http://216.104.37.26:9005/listen.pls"
	set c "$newdj is now ON AIR @ "
	set d "#TI-Radio (http://216.104.37.26:9005/listen.pls)"
	set e "Radio || Status: DJ On Air || $newdj Is Now Broadcasting || "
	set f "URL: http://216.104.37.26:9005/listen.pls || Want to be a DJ?: http://bit.ly/J6cWtN"
	putnow "PRIVMSG $radiochan : $a$b"
	putnow "PRIVMSG $djchan :\002ON AIR\002: $newdj is now ON AIR."
	putnow "PRIVMSG $mainchan : $c$d"
	putnow "TOPIC $radiochan : $e$f"
}

## Advert if RealDJ->RealDJ
proc tempoffair {} {
	global radiochan djchan dj
	set radiochan [string tolower $radiochan]
	if {$dj != 0} {
		putnow "PRIVMSG $radiochan :\002OFF AIR\002: $dj is now OFF AIR."
		putnow "PRIVMSG $djchan :\002OFF AIR\002: $dj is now OFF AIR."
	}
}

## Advert if Offline->AutoDJ
proc autodjon {} {
	global radiochan
	set radiochan [string tolower $radiochan]
	set a "Radio || Status: AutoDJ ||"
	set b "URL: http://216.104.37.26:9005/listen.pls || Want to be a DJ?: http://bit.ly/J6cWtN"
	putnow "TOPIC $radiochan : $a$b"
}

## Advert if Someone->Offline
proc serveroffline {} {
	global radiochan
	set radiochan [string tolower $radiochan]
	set a "Radio || Status: Stream Offline ||"
	set b " URL: http://216.104.37.26:9005/listen.pls || Want to be a DJ?: http://bit.ly/J6cWtN"
	putnow "TOPIC $radiochan : $a$b"
}

## Advert if RealDJ->AutoDJ
proc autooffair {} {
	global radiochan djchan dj
	set radiochan [string tolower $radiochan]
	set a "Radio || Status: AutoDJ || "
	set b "URL: http://216.104.37.26:9005/listen.pls || Want to be a DJ?: http://bit.ly/J6cWtN"
	putnow "PRIVMSG $radiochan :\002OFF AIR\002: $dj is now OFF AIR."
	putnow "PRIVMSG $djchan :\002OFF AIR\002: $dj is now OFF AIR."
	putnow "TOPIC $radiochan : $a$b"

}

## Advert if Server if Offline
proc offair {} {
	global radiochan djchan dj
	set radiochan [string tolower $radiochan]
	set a "Radio || Status: Stream Offline || "
	set b "URL: http://216.104.37.26:9005/listen.pls || Want to be a DJ?: http://bit.ly/J6cWtN"
	putnow "PRIVMSG $radiochan :\002OFF AIR\002: $dj is now OFF AIR."
	putnow "PRIVMSG $djchan :\002OFF AIR\002: $dj is now OFF AIR."
	putnow "PRIVMSG $djchan :\00304$dj, please remember to \002TURN ON AUTODJ\002 \00304"
	putnow "TOPIC $radiochan : $a$b"
}

putlog "Radio Script loaded..        | 1"
start
