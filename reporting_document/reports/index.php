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
    <link rel="stylesheet" href="../css/main.css">

    <style>
        h1{font-family: 'Montserrat', sans-serif;}
    </style>

</head>
<body>

<div class="container_reports">

<h1>All reports</h1>

    <h3>
        <a href="../index.php">Back to title screen</a>
    </h3>

    <div class="container_tables">
    <div class="container_table1">
    <table>
    <thead>
        <tr>
            <th>Daily reports</th>
            <th>Download link</th>
        </tr>
    </thead>

    <?php

        $files = scandir('pdf/');
        foreach(array_reverse($files) as $file){
            $ext = pathinfo($file, PATHINFO_EXTENSION);
            $fname = pathinfo($file, PATHINFO_FILENAME);
            $pattern = '/^report/i';
            if($ext == 'pdf' && preg_match($pattern, $fname)){
                echo '<tr><td><a href="pdf/'.$file.'">'.$file.'</a></td><td><a download='.$file.' href=pdf/'.$file.'>Download</a></td></tr>';
            }
        }
    ?>

</table>
</div>


<div class="container_table2">
<table>
    <thead>
        <tr>
            <th>Weekly reports</th>
            <th>Download link</th>
        </tr>
    </thead>

        <?php

        $files = scandir('pdf/');
        foreach(array_reverse($files) as $file){
            $ext = pathinfo($file, PATHINFO_EXTENSION);
            $fname = pathinfo($file, PATHINFO_FILENAME);
            $pattern = '/weekly-report/i';
            if($ext == 'pdf' && preg_match($pattern, $fname)){
                echo '<tr><td><a href="pdf/'.$file.'">'.$file.'</a></td><td><a download='.$file.' href=pdf/'.$file.'>Download</a></td></tr>';
            }
        }
    ?>

</table>
</div>
</div>
</div>
    
</body>
</html>