# OZO AD Lab Implement Customization Prerequisites

## Description
An interactive script automates [part](https://onezeroone.dev/active-directory-lab-part-ii-customization-prerequisites/) of a One Zero One [series](https://onezeroone.dev/active-directory-lab-part-i-introduction/) illustrating how to automate the process of deploying an AD Lab. It implements the customization prerequisites of the One Zero One AD Lab.

## Installation
This script is published to [PowerShell Gallery](https://learn.microsoft.com/en-us/powershell/scripting/gallery/overview?view=powershell-5.1). Ensure your system is configured for this repository then execute the following in an _Administrator_ PowerShell:

```powershell
Install-Script ozo-ad-lab-implement-customization-prerequisites
```

## Usage
```powershell
ozo-ad-lab-implement-customization-prerequisites
    [-FeatureName]
    [-InternalIP]
    [-InternalSwitchName]
    [-LocalGroup]
    [-OscdimgExePath]
    [-OZOADLabDirLike]
    [-OZOADLabPath]
    [-OZOADLabZipPath]
    [-OZOADLabZipUri]
    [-PrefixLength]
    [-SimExePath]
    [-Subnet]
    [-WinAdkFileUri]
    [-WinAdkPath]
```

## Parameters
|Parameter|Description|
|---------|-----------|
|`FeatureName`|The name of the Windows feature to install. Default is _Microsoft-Hyper-V-All_.|
|`InternalIP`|The internal IP address for the lab network. Default is `172.16.1.1`.|
|`InternalSwitchName`|The name of the internal virtual switch. Default is _OZO AD Lab NAT_.|
|`LocalGroup`|The local group to which the current user should be added. Default is _Hyper-V Administrators_.|
|`OscdimgExePath`|The path to the Oscdimg executable. Default is the typical installation path within the Windows Kits directory.|
|`OZOADLabDirLike`|he pattern to identify the OZO AD Lab directory. Default is `onezeroone-dev-OZO-AD-Lab*`.|
|`OZOADLabPath`|The path to the OZO AD Lab directory. Default is `$Env:SystemDrive\ozo-ad-lab`.|
|`OZOADLabISOs`|A hashtable of ISO filenames and their corresponding download URIs.|
|`OZOADLabZipPath`|The path to the OZO AD Lab ZIP file. Default is `$Env:SystemDrive\ozo-ad-lab.zip`.|
|`OZOADLabZipUri`|The URI to download the latest OZO AD Lab ZIP file. Default is _https://api.github.com/repos/onezeroone-dev/OZO-AD-Lab/releases/latest_.|
|`PrefixLength`|The prefix length for the lab network subnet. Default is 24.|
|`SimExePath`|The path to the SIM executable. Default is the typical installation path within the Windows Kits directory.
|`Subnet`|The subnet for the lab network. Default is `172.16.1.0`.|
|`WinAdkFileUri`|The URI to download the Windows ADK setup file. Default is _https://go.microsoft.com/fwlink/?linkid=2128854_.|
|`WinAdkPath`|The path to the Windows ADK setup file. Default is `$Env:USERPROFILE\Downloads\adksetup.exe`.|

## Examples
```powershell
ozo-ad-lab-implement-customization-prerequisites
```
## Notes
Run this script in an _Administrator_ PowerShell.

## Acknowledgements
Special thanks to my employer, [Sonic Healthcare USA](https://sonichealthcareusa.com), who supports the growth of my PowerShell skillset and enables me to contribute portions of my work product to the PowerShell community.
