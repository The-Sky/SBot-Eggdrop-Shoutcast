# Usage:

# 1) Set the configs below
# 2) .chanset #channelname +urltitle ;# enable script
# 3) .chanset #channelname +logurltitle ;# enable logging
# Then just input a url in channel and the script will retrieve the title from the corresponding page.

################################################################################################################

# Configs:

set urltitle(ignore) "bdkqr|dkqr" ;# User flags script will ignore input from
set urltitle(pubmflags) "-|-" ;# user flags required for channel eggdrop use
set urltitle(length) 5	;# minimum url length to trigger channel eggdrop use
set urltitle(delay) 1 ;# minimum seconds to wait before another eggdrop use
set urltitle(timeout) 60000 ;# geturl timeout (1/1000ths of a second)

################################################################################################################

# Script begins:

package require http ;# You need the http package..
set urltitle(last) 111 ;# Internal variable, stores time of last eggdrop use, don't change..
setudef flag urltitle ;# Channel flag to enable script.
setudef flag logurltitle ;# Channel flag to enable logging of script.

set urltitlever "0.01a"
set message ""

bind pubm $urltitle(pubmflags) {*://*} pubm:urltitle
proc pubm:urltitle {nick host user chan text} {
	global urltitle this message
	set response ""
	if {$nick != "Hobbes"} {
		if {([channel get $chan urltitle]) && ([expr [unixtime] - $urltitle(delay)] > $urltitle(last)) && \
				(![matchattr $user $urltitle(ignore)])} {
			foreach word [split $text] {
				if {[string length $word] >= $urltitle(length) && [regexp {^(f|ht)tp(s|)://} $word] && ![regexp {://([^/:]*:([^/]*@|\d+(/|$))|.*/\.)} $word]} {
						if {![string match {*torrent-invites.com*} $word]} {
						set urltitle(last) [unixtime]
						set urtitle [urltitle $word]
						if {[string length $urtitle]} {
							set message "http://hidemyass.com/?$word"
							string trim $message
							set out [maketiny $message $nick $chan]
							set response "$out"
							if {$chan == "#torrent-invites"} {
								puthelp "PRIVMSG #BotDev :Zucchini: $urtitle - $response"
							} else {
								puthelp "PRIVMSG $chan : $urtitle - $response"
							}
						}
						break
					}
				}
			}
		}
	}
}

proc urltitle {url} {
	global this
	if {[info exists url] && [string length $url]} {
		set this $url
		catch {set http [::http::geturl $url -timeout $::urltitle(timeout)]} error
		if {[string match -nocase "*couldn't open socket*" $error]} {
			return "Error: couldn't connect..Try again later"
		}
		if { [::http::status $http] == "timeout" } {
			return "Error: connection timed out while trying to contact $url"
		}
		set data [split [::http::data $http] \n]
		::http::cleanup $http
		set title ""
		if {[regexp -nocase {<title>(.*?)</title>} $data match title]} {
			return [string map { {href=} "" \" "" } $title]
		} else {
			return "No title found."
		}
	}
}

proc maketiny {url nick chan} {
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set user_url $url
	set url "http://tinyurl.com/create.php"
	set postdata [http::formatQuery url $user_url submit "Make TinyURL!"]
	set response [http::geturl $url -query $postdata]
	set lines [http::data $response]
	http::cleanup $response
	foreach line [split $lines \n] {
		if {[regexp -all -nocase {\[<a\shref=\"(.+?)\"} $line all_matches myurl]} {
			putlog "tinyurl created for $nick: $myurl"
			return $myurl
		}
	}
	putlog "tinyurl failed for $nick: $user_url"
}

putlog "Url Title Grabber $urltitlever (rosc) script loaded.."
