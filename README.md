Expanded from the original script to target a couple more disk space eaters that I need to keep cleaning off VDIs (save waiting on WinDirStat)

This now:
1. tests the machine is online
2. get disk space from C drive
3. Get the size of pagefile etc..
4. Get the size of C:\temp (loads of c**p get dumped there)
5. for each user, we will grab the size of the below folders and give the user an option to clear them
5.1  - 'Downloads' 'AppData\Local\Temp'  'AppData\Local\CrashDumps' 'AppData\local\microsoft\teams' 'AppData\roaming\microsoft\teams'

run fired via a controller function (need to tidy output etc..) 

* Run-Cleanup -Domain $Domain  -Hostname $Hostnames -PartialPaths $PartialPaths

Planning a GUI controller function that can be used along with CLI controller Function

This was built by me spoon feeding Github Copilot.

# Original Readme
# Teams Classic Cache Cleanup PowerShell script
This is a PowerShell script written with the help of ChatGPT that will delete Microsoft Teams Classic (previously Teams for work or school) at <ins>%AppData%\Microsoft\Teams</ins> and its cache at <ins>%LocalAppData%\Microsoft\Teams</ins> from all Windows user profiles, leaving these two folders empty. Requires running as an administrator since it affects all users on the computer.

This is great to free up storage space on a shared computer with a lot of user accounts. Each user who's at least opened Teams Classic in the past each may have at least ~700MB of cache if not more, even if have since uninstalled the app, which is pretty much everyone since it opens at startup by default. But, since what became Teams Classic is no longer supported, this is safe to delete. If you legitimately use Teams for work or school, install the new Teams, which saves cache elsewhere.

This will *not* delete any shortcuts to Teams Classic, so a user opening a shortcut to it will get an error stating it can't be found and offer to delete the shortcut. Will have to create new shortcuts to the new Teams.

This was written using ChatGPT, and verified with Google Gemini.

* ChatGPT - https://chatgpt.com/share/6723ed36-4634-8003-ac7d-5fbca504451a
* Gemini - https://g.co/gemini/share/ee4f0ddb1a63

![Teams Classic Cache Cleanup PowerShell ISE screenshot](https://github.com/user-attachments/assets/f8480214-fe04-465c-acd7-0f3534b99d43)
