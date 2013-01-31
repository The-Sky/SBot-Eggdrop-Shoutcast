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
