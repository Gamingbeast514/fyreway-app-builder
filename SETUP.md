# Kovra VPN - Day 1 setup

Run these once, in PowerShell, inside this folder:

    cd "$HOME\AndroidStudioProjects\kovra_vpn"
    flutter create --org com.yourstudio --project-name kovra_vpn --platforms android,ios .
    flutter run

`flutter create .` only ADDS the missing Android/iOS build folders.
It does not overwrite the code in lib/.

## What's where
- lib/main.dart                     app entry + theme
- lib/theme.dart                    colours
- lib/models/server.dart            server list
- lib/services/vpn_controller.dart  connect logic (SIMULATED today, WireGuard on Day 2)
- lib/screens/                      Welcome, Home, Choose location
- lib/widgets/                      logo, ad banner placeholder
