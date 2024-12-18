# Define the categories
$categories = @(
    "beaches",
    "city",
    "mountains",
    "forests",
    "highways",
    "offices"
)

# Loop through each category and clear files
foreach ($category in $categories) {
    $path = "dataset/LD_dataset/train/$category"

    # Check if the directory exists
    if (Test-Path -Path $path) {
        Get-ChildItem -Path $path -File | Remove-Item -Force
    } else {
        Write-Host "Directory $path does not exist. Skipping."
    }
}

# Loop through each category and move files
foreach ($category in $categories) {
    $sourcePath = "dataset/LD_dataset/new_val/$category"
    $destinationPath = "dataset/LD_dataset/train/$category"

    # Ensure the destination directory exists
    if (-not (Test-Path -Path $destinationPath)) {
        New-Item -ItemType Directory -Path $destinationPath | Out-Null
    }

    # Move files matching the filter
    #Get-ChildItem -Path $sourcePath -Filter "*_line_drawing.png" -File |
    Get-ChildItem -Path $sourcePath -Filter "*_convexity_mirror_taper_concat.png" -File |
    ForEach-Object {
        Move-Item -Path $_.FullName -Destination $destinationPath
    }
}