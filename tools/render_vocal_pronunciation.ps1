$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Speech

$outputRoot = Join-Path (Split-Path $PSScriptRoot -Parent) 'assets\audio\music\vocal_work'
New-Item -ItemType Directory -Force -Path $outputRoot | Out-Null

$parts = @(
    @{ File='greek_01.wav'; Voice='Microsoft Kangkang'; Rate=-2; Pitch=-8; Text='Ook oh-loh-len, hoh kos-mos.' },
    @{ File='greek_02.wav'; Voice='Microsoft Kangkang'; Rate=-2; Pitch=-8; Text='Eh-tee foh-neh, foh-neh dee-doh-seen.' },
    @{ File='greek_03.wav'; Voice='Microsoft Kangkang'; Rate=-2; Pitch=-8; Text='Fohs foh-tee, droh-mon ah-noy-gay.' },
    @{ File='greek_04.wav'; Voice='Microsoft Kangkang'; Rate=-2; Pitch=-8; Text='Zoh-eh deh, ehk lee-thoo ah-nees-tah-tie.' },
    @{ File='latin_01.wav'; Voice='Microsoft Zira Desktop'; Rate=-2; Pitch=5; Text='Non peh-ree-eet, moon-doos.' },
    @{ File='latin_02.wav'; Voice='Microsoft Zira Desktop'; Rate=-2; Pitch=5; Text='Ad-hook voks, voh-chee res-pon-det.' },
    @{ File='latin_03.wav'; Voice='Microsoft Zira Desktop'; Rate=-2; Pitch=5; Text='Looks loo-chee, vee-am ah-peh-reet.' },
    @{ File='latin_04.wav'; Voice='Microsoft Zira Desktop'; Rate=-2; Pitch=5; Text='Vee-tah-kweh eh lah-pee-deh, soor-geet.' }
)

foreach ($part in $parts) {
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    $synth.SelectVoice($part.Voice)
    $target = Join-Path $outputRoot $part.File
    $synth.SetOutputToWaveFile($target)
    $escaped = [System.Security.SecurityElement]::Escape($part.Text)
    $ssml = "<speak version='1.0' xml:lang='en-US'><prosody rate='$($part.Rate)' pitch='$($part.Pitch)%'>$escaped</prosody></speak>"
    $synth.SpeakSsml($ssml)
    $synth.Dispose()
    Write-Output "WROTE $target"
}
