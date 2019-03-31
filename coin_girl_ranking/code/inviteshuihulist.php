<?php

header("Access-Control-Allow-Origin: *");

$dsn = 'mysql:dbname=bnrank;host=db;port=3306';
$user = 'root';
$password = 'linkidrank233';

$addr = $_GET["address"];
$status = $_GET["t"];
$net = $_GET["witchnet"];

try {

	$conn = new PDO($dsn, $user, $password);
	$conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

	$sth = $conn->prepare("SELECT address,paid,cardcount,rebate,serialnum from shuihuinvite where inviteaddress = :ivaddr and txstatus = :st and nettype = :net");
    $sth->bindValue(':ivaddr', $addr, PDO::PARAM_STR);
    $sth->bindValue(':st', $status, PDO::PARAM_STR);
    $sth->bindValue(':net', $net, PDO::PARAM_STR);
	$sth->execute();
	$result = $sth->fetchAll(PDO::FETCH_ASSOC);
	$json = json_encode($result);
	print_r($json);

} catch (PDOException $e) {
	echo $e->getMessage();
}

?>