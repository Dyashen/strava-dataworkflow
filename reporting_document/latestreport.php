<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reporting hub</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@100;900&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="css/main.css">

    <style>
        h1{font-family: 'Montserrat', sans-serif;}
    </style>
    
</head>

<body>
    <div class="container_graphs">

    <div class="contentrow"> 
    <h1>Latest reports</h1>
    <h3>
    <?php
        $directory = "graphs/daily/";
        $files = scandir ($directory);
        $firstFile = $directory . $files[2];
        $date = date ("F d Y H:i:s.", filectime($firstFile));
    echo $date;
    ?>
    </h3>
    <h3><a href="index.php">Back to title screen</a></h3>
    </div>

    <div class=contentrow>
    <h3>Statistics</h3>
    <?php
    $files = scandir('graphs/daily/');
    foreach($files as $file){
        $fname = pathinfo($file, PATHINFO_FILENAME);
        $pattern = '/^regular/i';
        if(preg_match($pattern, $fname)){
            echo "<img src='graphs/daily/$file' />";
        }
    }
    ?>
    </div>

    <div class=contentrow>
    <h3>Leaderboards</h3>
    <?php
    $files = scandir('graphs/daily/');
    foreach($files as $file){
        $fname = pathinfo($file, PATHINFO_FILENAME);
        $pattern = '/^leaderboard/i';
        if(preg_match($pattern, $fname)){
            echo "<img src='graphs/daily/$file' />";
        }
    }
    ?>
    </div>
    </div>
</body>
</html>