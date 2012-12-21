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
set urltitle(last) 111 ;# Internal variable, stores time of last eggdrop use, don't change..

################################################################################################################

# Script begins:

package require http ;# You need the http package..
package require tls 

setudef flag urltitle ;# Channel flag to enable script.
setudef flag logurltitle ;# Channel flag to enable logging of script.

bind pubm $urltitle(pubmflags) {*://*} pubm:urltitle

proc pubm:urltitle {nick host user chan text} {
	global urltitle this message
		# If the Channel has Urltitle tag, isn't ignored by our flags and isn't Hobbes.
		if {([channel get $chan urltitle]) && (![matchattr $user $urltitle(ignore)]) \
		&& $nick != "Hobbes"} {
			foreach word [split $text] {
				if {[string length $word] >= $urltitle(length) && \
				[regexp {^(f|ht)tp(s|)://} $word] \
				&& ![regexp {://([^/:]*:([^/]*@|\d+(/|$))|.*/\.)} $word]} {
					if {![string match {*torrent-invites.com*} $word]} {
						set urltitle(last) [unixtime]
					# Run urltitle on our url in $word
					set urtitle [urltitle $word]
					if {[string length $urtitle]} {
						# Merge pasted url with HideMyAss Anon Refer
						set message "http://blankrefer.com/?$word"
						# Remove Blank Space
						string trim $message
						# Make the Tiny Url
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

proc urltitle {url} {
	global this
	if {[info exists url] && [string length $url]} {
		# If https is in the url
		if {[string match -nocase "*https*" $url]} {
			# Use TLS
			http::register https 443 tls::socket
		}
		set this $url
		#Catch 
		catch {set http [::http::geturl $url -timeout $::urltitle(timeout)]} error
		# If the Socket would not open
		if {[string match -nocase "*couldn't open socket*" $error]} {
			return "Error: couldn't connect..Try again later"
		}
		# If the page says timed out
		if { [::http::status $http] == "timeout" } {
			return "Error: connection timed out"
		}
		# Set Lines as $data and split the lines up
		set data [split [::http::data $http] \n]
		::http::cleanup $http
		# Regex to find the title tags and take out the title
		if {[regexp -nocase {<title>(.*?)</title>} $data match title]} {
			return [string map { {href=} "" \" "" } $title]
		} else {
			return "No title found."
		}
		http::unregister https
	}
}

proc maketiny {url nick chan} {
	::http::config -useragent "Mozilla/5.0; Shoutinfo"
	set user_url $url
	set url "http://tinyurl.com/create.php"
	# Input our url into TinyURL and then submit the form
	set postdata [http::formatQuery url $user_url submit "Make TinyURL!"]
	set response [http::geturl $url -query $postdata]
	set lines [http::data $response]
	http::cleanup $response
	# Loop to run through the HTML from TinyURL
	foreach line [split $lines \n] {
		# Regex to find the correct field in $line and extract that link as $myurl
		if {[regexp -all -nocase {\[<a\shref=\"(.+?)\"} $line all_matches myurl]} {
			putlog "tinyurl created for $nick: $myurl"
			return $myurl
		}
	}
	putlog "tinyurl failed for $nick: $user_url"
}

putlog "Urltitle.tcl loaded.."
