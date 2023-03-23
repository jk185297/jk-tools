$file = "~\grc_ping.txt"
while (1) {
    get-date | Out-File $file -Append
    ping -n 5 s-azp21.grc.local | Out-File $file -Append
    Start-Sleep 5
}
