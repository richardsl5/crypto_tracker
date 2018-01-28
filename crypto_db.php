<html>
	<head>
		<title>Crypto Coin Price Summary</title>
		<style>
			th {
				background-color: #00ffff;
				}
			table, th, td {
				border: 1px solid black;
				border-collapse: collapse;
			}
			tr:nth-child(even) {background-color: #f2f2f2;}
		</style>
	</head>

	<body onload="setSort()">
	<script>
	function reloadpage() {
		var x = document.getElementById("t2").rows.length;
		document.getElementById("t2").rows[x-1].cells[1].innerHTML ="<font color=\"red\">Updating </font>";
		var sel = document.getElementById("sel1").value;
		var url = window.location.href;
		var arr = url.split("?");
		url = arr[0];
		url += '?sortBy=' + sel;
		window.location.href = url;
	};
	function goToOldPage() {
		var url = window.location.href;
		var arr = url.split("/");
		url = arr[0] + "/crypto.php";
		window.location.href = url;
	};
	function setSort() { 
		var url = window.location.href;
		var arr = url.split("?");
		var sortby;
		if (typeof arr[1] != 'undefined') {
			var arr2 = arr[1].split('=');
			sortBy = arr2[1];
			document.getElementById("sel1").value = sortBy;
		};
	};
	</script>
		<?php
			echo "<h1 align=\"center\">Crypto Prices</h1>";
			$exec_str = "./crypto_db.pl " . $_GET['sortBy'];
			exec ($exec_str);
		?>

		<table style="width: 100%" class="w3-table w3-striped">
		<thead>
			<tr>
				<th>Currency</th>
				<th>Symbol</th>
				<th>Rank</th>
				<th>Price (USD)</th>
				<th>Buy Price</th>
				<th>Change %</th>
				<th>Qty</th>
				<th>Value (USD)</th>
				<th>Value (HKD)</th>
				<th>Change USD</th>
				<th>Change 1h</th>
				<th>Change 24h</th>
				<th>Change 7d</th>
			</tr>
			</thead>
			<tbody>
		<?php 
			$total = 0;
			$lines = file('crypto_data/pricedata_db');
			foreach ($lines as $line) {
				echo "<tr>";
				$row = explode("/",$line);
				$idx = 0;
				foreach ($row as $r) {
					$str = "";
					if ($idx > 1) {
						$str = "align=\"right\">";
					} else {
						$str = "align\"left\">";
					};
					if ($idx > 7) {
						if ($r < 0) { 
							$str .= "<font color=\"red\">"  ;
						} else { 
							$str .= "<font color=\"green\">" ;
						};
					} else {
						$str .= "<font color=\"black\">";
					};
					echo "<td {$str} {$r} </font></td>"; 
					$idx++;
				};
			};
		?>
		</tbody>
		</table>

		<br/><br/>
	
		<table border="0" id="t2">
		<tbody>
			<?php
				$sumdat = file('crypto_data/summarydata'); 
				foreach ($sumdat as $l) {
					echo "<tr>" ; 
					$row = explode("/",$l);
					foreach ($row as $r) {
						echo "<td align=\"left\">{$r}</td>";
					} ;
					echo "</tr>";
				}
			?>
			<tbody/>
		</table>

		<br/>
		Order By: 
		<select onchange="reloadpage()" id="sel1">
			<option value="none">None</option>
			<option value="rank">Rank</option>
			<option value="name">Name</option>
			<option value="qty">Quantity</option>
			<option value="value_usd">USD Value</option>
			<option value="change_pct">Percent Change</option>
			<option value="change_1h">Percent Change 1H</option>
			<option value="change_24h">Percent Change 24H</option>
			<option value="change_7d">Percent Change 7D</option>
		</select>
		<br/>
		<button align="center" type="submit" onclick="reloadpage()">Refresh</button>
		<button align="center" type="submit" onclick="goToOldPage()">Old Style</button>

	</body>
</html>
