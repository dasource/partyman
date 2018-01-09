<?php
//
// Converts Bashoutput to colored HTML
//
function convertBash($code) {
    $dictionary = array(

        '[K' => '[',
        '[30m' => '<span style="color:black">',
        '[31m' => '<span style="color:red">',
        '[32m' => '<span style="color:green">',
        '[33m' => '<span style="color:yellow">',
        '[34m' => '<span style="color:blue">',
        '[35m' => '<span style="color:purple">',
        '[36m' => '<span style="color:cyan">',
        '[37m' => '<span style="color:white">',
        '[m'   => '</span>',
        '[0m'   => '</span>'
    );
    $htmlString = str_replace(array_keys($dictionary), $dictionary, $code);
    return preg_replace('/[^0-9!$?#*&\',\-.\/A-Za-z\n\(\)%:<>"= ]/', '', $htmlString);
}

$status = convertBash(file_get_contents('partyman-status.tmp', FILE_USE_INCLUDE_PATH));

?>

<html>
<head>
  <title>Authorised?</title>
</head>
<body style="white-space: pre;font-family: monospace;background: black;color: white;">
<?php echo $status; ?>
</body>
</html>
