param(
    [Parameter(Mandatory=$true)][string]$InputPath,
    [Parameter(Mandatory=$true)][string]$OutputPath
)

Add-Type -AssemblyName System.Drawing
$source = [System.Drawing.Bitmap]::new($InputPath)
$target = [System.Drawing.Bitmap]::new(1024, 1536, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [System.Drawing.Graphics]::FromImage($target)
$graphics.Clear([System.Drawing.Color]::Transparent)
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$sourceCellWidth = [Math]::Floor($source.Width / 2)
$sourceCellHeight = [Math]::Floor($source.Height / 2)

for ($index = 0; $index -lt 4; $index++) {
    $column = $index % 2
    $row = [Math]::Floor($index / 2)
    $sourceRect = [System.Drawing.Rectangle]::new(
        $column * $sourceCellWidth,
        $row * $sourceCellHeight,
        $sourceCellWidth,
        $sourceCellHeight
    )
    $scale = [Math]::Min(512.0 / $sourceCellWidth, 768.0 / $sourceCellHeight)
    $width = [Math]::Round($sourceCellWidth * $scale)
    $height = [Math]::Round($sourceCellHeight * $scale)
    $x = $column * 512 + [Math]::Floor((512 - $width) / 2)
    $y = $row * 768 + (768 - $height)
    $targetRect = [System.Drawing.Rectangle]::new($x, $y, $width, $height)
    $graphics.DrawImage($source, $targetRect, $sourceRect, [System.Drawing.GraphicsUnit]::Pixel)
}

$target.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$graphics.Dispose()
$target.Dispose()
$source.Dispose()
