<?php

header("Access-Control-Allow-Origin: *");

$dsn = 'mysql:dbname=bnrank;host=db;port=3306';
$user = 'root';
$password = 'linkidrank233';

$snnum = $_POST['sn'];
$st = $_POST['status'];

try {

  if (!empty($snnum) and !empty($st)) {
    $conn = new PDO($dsn, $user, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $conn->prepare("UPDATE shuihuinvite SET txstatus = :st WHERE serialnum = :sn");
    $stmt->bindParam(':sn', $_POST['sn'], PDO::PARAM_STR);
    $stmt->bindParam(':st', $_POST['status'], PDO::PARAM_STR);
    $stmt->execute();
  }

} catch (PDOException $e) {
  echo $e->getMessage();
}

?>