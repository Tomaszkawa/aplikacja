$flutterBin = "C:\Users\user\flutter\bin"
if (Test-Path $flutterBin) {
    $env:Path = "$flutterBin;" + $env:Path
}
Set-Location $PSScriptRoot\mobile
flutter pub get
flutter run
