## SBot: ReadMe ##

**SBot** is a shoucast radio bot that was built inside Eggdrop using TCL. It is semi-easily configurable and has a large amount of features.

Written by: Sky

Table of Contents
-----------------

1. Command List
2. Working with the Variables
3. Different Channel Functions
4. MySQL Database
5. PHP for DJ Logs

1. Command List
-----------------

- **!lst** (arg) - Shows last # (5 if empty) DJ sessions
- **!start** - Starts timers for multiple commands
- **!lp** (arg) - Shows last # (10 max) tracks
- **!server** - Shows the status of the server
- **!clearlist** - Clears the Request List
- **!reqlist** - Shows the Request List
- **!np** - Shows what song is Now Playing
- **!request (arg)** - Command to Request a Song
- **!peak** - Shows All Time/Session Peaks
- **!dj** - Shows what DJ is on
- **!genre** - Shows what the DJ's genre is
- **!listen** - Provides a link to listen (.pls [playlist file])
- **!log** (arg) - Shows DJ's total time and sessions OnAir
- **!topdj** (arg) - Shows Top # of DJ's in order 
- **!url** - Shows the URL to your Shoutcast Page
- **!commands** - Shows Command List

2. Working with the Variables
-----------------

- siteurl
- listenurl
- last played

3. Different Channel Functions
-----------------
- radiochan - Your Main Radio Channel. 
- djchan - Your DJ Channel.
- mainchan - Main channel (sister channels, less spam [more restrictive])
- logchan - Personal Channel that bot will log messages to.

4. MySQL Database
-----------------
# 
Creating the DJ Log Table:

```CREATE TABLE `djlog` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dj_name` varchar(30) DEFAULT NULL,
  `total_time` bigint(255) DEFAULT NULL,
  `total_sessions` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
)```

# 

Creating the Session Log:
```
CREATE TABLE `session_log` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dj_name` varchar(30) DEFAULT NULL,
  `onair_time` varchar(30) DEFAULT NULL,
  `offair_time` varchar(30) DEFAULT NULL,
  `session_time` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`id`)
)
```

5. PHP for DJ Logs
-----------------
