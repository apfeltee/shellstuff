#!powershell -File

Add-Type -AssemblyName System.Speech;
$so = (New-Object System.Speech.Synthesis.SpeechSynthesizer);
$so.Speak("hello");

