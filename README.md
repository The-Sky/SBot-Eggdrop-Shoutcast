## SBot: ReadMe ##

**SBot** is a shoucast radio bot that was built inside Eggdrop using TCL. It is semi-easily configurable and has a large amount of features.

Written by: Sky

Table of Contents
-----------------

1. Command List
2. Working with the Variables
3. Different Channels Function
4. MySQL Database
5. PHP for DJ Logs
6. CSS for PHP Tables

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

Shoutcast Website Variables:

- **$siteurl** - Your Main Shoutcast Website URL
- **$listenurl** - Your Listen Url (listen.pls usually)
- **$lastplayed** - Your Last Played URL (played.html usually)

MySQL Variables:

- **$dbhost** - Your Database Hostname
- **$dbuser** - Your Database Username
- **$dbpass** - Your Database Password
- **$dbname** - Your Database Name

3. Different Channels Function
-----------------
- **$radiochan** - Your Main Radio Channel. 
- **$djchan** - Your DJ Channel.
- **$mainchan** - Main channel (sister channels, less spam [more restrictive])
- **$logchan** - Personal Channel that bot will log messages to.

4. MySQL Database
-----------------
# 
**Creating the DJ Log Table**:

```
CREATE TABLE `djlog` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `dj_name` varchar(30) DEFAULT NULL,
  `total_time` bigint(255) DEFAULT NULL,
  `total_sessions` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
)
```

# 
**Creating the Session Log**:
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
I have provided some PHP to show your DJ/Session logs on a website. You will find it in the file named **djlog.php**.

```
				<div class="title">DJ Sessions and Top DJ's</div>
					<?php
					$hostname="localhost";
					$username="user";
					$password="pass";
					$database="db";


					$con = mysql_connect($hostname,$username,$password);;
					if (!$con)
					{
					die('Could not connect: ' . mysql_error());
					}
					@mysql_select_db($database, $con) or die( "Unable to select database");
					$query="SELECT * FROM session_log order by id desc";
					$result=mysql_query($query);
					$num=mysql_numrows($result);

					mysql_close();
					?>
					<table class="hovertable" border="1" cellspacing="2" cellpadding="2">
					<tr onmouseover="this.style.backgroundColor='#1D9AE2';" onmouseout="this.style.backgroundColor='#444444';">
					<td><font face="Arial, Helvetica, sans-serif">DJ</font></td>
					<td><font face="Arial, Helvetica, sans-serif">Onair</font></td>
					<td><font face="Arial, Helvetica, sans-serif">Offair</font></td>
					<td><font face="Arial, Helvetica, sans-serif">Session</font></td>
					</tr>

					<?php
					$i=0;
					while ($i < $num) {

					$f2=mysql_result($result,$i,"dj_name");
					$f3=mysql_result($result,$i,"onair_time");
					$f4=mysql_result($result,$i,"offair_time");
					$f5=mysql_result($result,$i,"session_time");
					?>

					<tr onmouseover="this.style.backgroundColor='#1D9AE2';" onmouseout="this.style.backgroundColor='#444444';">
					<td><font face="Arial, Helvetica, sans-serif"><?php echo $f2; ?></font></td>
					<td><font face="Arial, Helvetica, sans-serif"><?php echo $f3; ?></font></td>
					<td><font face="Arial, Helvetica, sans-serif"><?php echo $f4; ?></font></td>
					<td><font face="Arial, Helvetica, sans-serif"><?php echo ' ' .duration($f5). ' '; ?></font></td>
					</tr>

					<?php
					$i++;
					}
					?>
					</font>
					</table>
					
         						<?php					
					$hostname="localhost";
					$username="user";
					$password="pass";
					$database="db";
					$con = mysql_connect($hostname,$username,$password);;
					if (!$con)
					{
					die('Could not connect: ' . mysql_error());
					}
					@mysql_select_db($database, $con) or die( "Unable to select database");
					$query="SELECT * FROM djlog order by total_time desc";
					$result=mysql_query($query);
					$num=mysql_numrows($result);

					mysql_close();
					?>
					<table class="hovertable" border="1" cellspacing="2" cellpadding="2">
					<tr onmouseover="this.style.backgroundColor='#1D9AE2';" onmouseout="this.style.backgroundColor='#444444';">
					<td><font face="Arial, Helvetica, sans-serif">DJ</font></td>
					<td><font face="Arial, Helvetica, sans-serif">Total</font></td>
					<td><font face="Arial, Helvetica, sans-serif">Sessions</font></td>
					</tr>

					<?php
					$i=0;
					while ($i < $num) {

					$f2=mysql_result($result,$i,"dj_name");
					$f3=mysql_result($result,$i,"total_time");
					$f4=mysql_result($result,$i,"total_sessions");
					?>

					<tr onmouseover="this.style.backgroundColor='#1D9AE2';" onmouseout="this.style.backgroundColor='#444444';">
					<td><font face="Arial, Helvetica, sans-serif"><?php echo $f2; ?></font></td>
					<td nowrap><font face="Arial, Helvetica, sans-serif"><?php echo ' ' .duration($f3). ' '; ?></font></td>
					<td><font face="Arial, Helvetica, sans-serif"><?php echo $f4; ?></font></td>
					</tr>

					<?php
					$i++;
					}
					?>
				</table>
			</div>
```

All you really need to edit is the following variables (and add a layout around it):

- **$hostname** - Your Database Hostname / IP
- **$username** - Your Database Username
- **$password** - Your Database Password
- **$database** - Your Database Name

Anything else is up to you.

6. CSS for PHP Tables
-----------------
```
<style type="text/css">
table.hovertable {
	margin-left: 20px;
	font-family: verdana,arial,sans-serif;
	font-size:13px;
	color:#ffffff;
	border-width: 1px;
	border-color: #999999;
	padding: 10px;
	float: left;
	border-collapse: collapse;
}
table.hovertable th {
	background-color:#191919;
	border-width: 1px;
	padding: 8px;
	border-style: solid;
	border-color: #a9c6c9;
}
table.hovertable tr {
	background-color:#444444;
}
table.hovertable td {
	border-width: 1px;
	padding: 8px;
	border-style: solid;
	border-color: #a9c6c9;
}
</style>
```
