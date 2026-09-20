#Requires -Modules @{ModuleName="OZO"; ModuleVersion="1.7.0"},OZOLogger -RunAsAdministrator

<#PSScriptInfo
    .VERSION 1.1.0
    .GUID 2a8769c1-6be2-44f3-ae17-47b4138ea2fa
    .AUTHOR Andy Lievertz <alievertz@onezeroone.dev>
    .COMPANYNAME One Zero One
    .COPYRIGHT This script is released under the terms of the GNU General Public License ("GPL") version 2.0.
    .TAGS
    .LICENSEURI https://github.com/onezeroone-dev/OZO-AD-Lab-Implement-Customization-Prerequisites/blob/main/LICENSE
    .PROJECTURI https://github.com/onezeroone-dev/OZO-AD-Lab-Implement-Customization-Prerequisites
    .ICONURI
    .EXTERNALMODULEDEPENDENCIES 
    .REQUIREDSCRIPTS
    .EXTERNALSCRIPTDEPENDENCIES
    .RELEASENOTES https://github.com/onezeroone-dev/OZO-AD-Lab-Implement-Customization-Prerequisites/blob/main/CHANGELOG.md
    .PRIVATEDATA
#>

<# 
    .SYNOPSIS
    See description.
    .DESCRIPTION 
    Implements the customization prerequisites for the One Zero One AD Lab.
    .EXAMPLE
    ozo-ad-lab-implement-customization-prerequisites
    .LINK
    https://github.com/onezeroone-dev/OZO-AD-Lab-Implement-Customization-Prerequisites/blob/main/README.md
#>

#PARAMETERS
[CmdletBinding()] Param(
    [Parameter(Mandatory=$false)][String] $FeatureName = "Microsoft-Hyper-V-All",
    [Parameter(Mandatory=$false)][String] $LocalGroup = "Hyper-V Administrators",
    [Parameter(Mandatory=$false)][String] $OscdimgExePath = (Join-Path -Path ${Env:ProgramFiles(x86)} -ChildPath "Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe"),
    [Parameter(Mandatory=$false)][String] $OZOADLabDirLike = "onezeroone-dev-OZO-AD-Lab*",
    [Parameter(Mandatory=$false)][String] $OZOADLabPath = (Join-Path -Path $Env:SystemDrive -ChildPath "ozo-ad-lab"),
    [Parameter(Mandatory=$false)][HashTable] $OZOADLabISOs = @{
        "microsoft-windows-11-enterprise-evaluation.iso" = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
        "microsoft-windows-server-2025-evaluation.iso" = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso"
    },
    [Parameter(Mandatory=$false)][String] $OZOADLabZipPath = (Join-Path -Path $Env:USERPROFILE -ChildPath "Downloads\ozo-ad-lab-latest.zip"),
    [Parameter(Mandatory=$false)][String] $OZOADLabZipUri = "https://api.github.com/repos/onezeroone-dev/OZO-AD-Lab/releases/latest",
    [Parameter(Mandatory=$false)][String] $SimExePath = (Join-Path -Path ${Env:ProgramFiles(x86)} -ChildPath "Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\WSIM\x86\imgmgr.exe"),
    [Parameter(Mandatory=$false)][String] $WinAdkFileUri = "https://go.microsoft.com/fwlink/?linkid=2128854",
    [Parameter(Mandatory=$false)][String] $WinAdkPath = (Join-Path -Path (Join-Path -Path $Env:USERPROFILE -ChildPath "Downloads") -Childpath "adksetup.exe")
)

# CLASSES
Class Main {
    # PROPERTIES: Booleans
    [Boolean] $prerequisitesSatisfied = $true
    # PROPERTIES: PSCustomObjects
    [PSCustomObject] $ozoLogger = @()
    # METHODS: Constructor method
    Main($FeatureName,$LocalGroup,$OscdimgExePath,$OZOADLabDirLike,$OZOADLabPath,$OZOADLabISOs,$OZOADLabZipPath,$OZOADLabZipUri,$SimExePath,$WinAdkFileUri,$WinAdkPath) {
        # Populate the ozoADLabISOs list
        # Create a logger object
        $this.ozoLogger = (New-OZOLogger)
        # Call ValidateEnvironment to determine if we can proceed
        If ($this.ValidateEnvironment($OZOADLabDirLike,$OZOADLabPath) -eq $true) {
            # Determine if the feature is not installed
            If ($this.InstallFeature($FeatureName) -eq $false) {
                # Feature is not installed
                $this.prerequisitesSatisfied = $false
            } Else {
                # Feature is installed; determine if a restart is required
                If ($this.RestartRequired($FeatureName) -eq $true) {
                    # Restart is required
                    $this.prerequisitesSatisfied = $false
                }
            }
            # Determine if the Debian WSL distribution is not installed
            If ($this.InstallWSLDebian() -eq $false) { $this.prerequisitesSatisfied -eq $false }
            # Determine if the user not is added to the local group
            If ($this.ManageLocalGroup(([System.Security.Principal.WindowsIdentity]::GetCurrent().Name),$LocalGroup) -eq $false) { $this.prerequisitesSatisfied = $false }
            # Determine if the VM switches are not created
            If ($this.CreateVMSwitches() -eq $false) { $this.prerequisitesSatisfied = $false }
            # Determine if the Microsoft ADK is not installed
            If ($this.InstallMicrosoftADK($OscdimgExePath,$SimExePath,$WinAdkFileUri,$WinAdkPath) -eq $false) { $this.prerequisitesSatisfied = $false }
            # Determine if the OZO AD Lab resources are not downloaded and extracted
            If ($this.GetOZOADLabResources($OZOADLabPath,$OZOADLabDirLike,$OZOADLabZipPath,$OZOADLabZipUri) -eq $false) { $this.prerequisitesSatisfied = $false }
            # Determine if the source ISOs are not downloaded
            If ($this.DownloadISOs($OZOADLabISOs,$OZOADLabPath) -eq $false) { $this.prerequisitesSatisfied = $false }
            # Determine if all prerequisites were met
            If ($this.prerequisitesSatisfied -eq $true) {
                # All prerequisites are satisfied
                $this.ozoLogger.Write("All prerequisites are satisfied. Please see https://onezeroone.dev/active-directory-lab-customize-the-windows-installer-isos for the next steps.","Information")
            }
        } Else {
            # Environment did not validate
            $this.ozoLogger.Write("The environment did not validate.","Error")
        }
    }
    # METHODS: Environment validation method
    Hidden [Boolean] ValidateEnvironment($OZOADLabDirLike,$OZOADLabPath) {
        # Control variable
        [Boolean] $Return = $true
        # Determine if this a user-interactive session
        If ((Get-OZOUserInteractive) -eq $false) {
            # Session is not user-interactive
            $this.ozoLogger.Write("Please run this script in a user-interactive session.","Error")
            $Return = $false
        }
        # Determine if there is already an "ozo-ad-lab" folder off the root of the SystemDrive
        If ([Boolean](Test-Path -Path $OZOADLabPath -ErrorAction SilentlyContinue) -eq $true) {
            # There is already an "ozo-ad-lab" folder
            $this.ozoLogger.Write(("Found " + $OZOADLabPath + ". This directory must be removed before proceeding."),"Error")
            $Return = $false
        }
        # Try to make sure any previous downloaded + extracted releases of OZO-AD-Lab are wiped
        Try {
            Get-ChildItem -Path $Env:TEMP -ErrorAction Stop | Where-Object {$_.Name -Like $OZOADLabDirLike} | Remove-Item -Recurse -Force -ErrorAction Stop
            # Success
        } Catch {
            # Failure
            $this.ozoLogger.Write("Unable to clean up previous OZO-AD-Lab releases from the TEMP directory.","Error")
            $Return = $false
        }
        # Return
        return $Return
    }
    # METHODS: Install feature method
    Hidden [Boolean] InstallFeature($FeatureName) {
        # Control variable
        [Boolean] $Return = $true
        # Determine if the feature is present
        If ([Boolean](Get-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction SilentlyContinue) -eq $false) {
            # Report
            $this.ozoLogger.Write(("Installing " + $FeatureName + " feature."),"Information")
            # Feature is not present; try to install it
            Try {
                Enable-WindowsOptionalFeature -Online -FeatureName $FeatureName -ErrorAction Stop
                # Success
            } Catch {
                # Failure
                $this.ozoLogger.Write(("Error installing the " + $FeatureName + " feature. Please manually install this feature and then run this script again to continue. See https://onezeroone.dev/active-directory-lab-part-ii-customization-prerequisites/ for more information."),"Error")
                $Return = $false
            }
        }
        # Return
        return $Return
    }
    # METHODS: Restart required method
    Hidden [Boolean] RestartRequired($FeatureName) {
        # Control variable
        [Boolean] $Return = $false
        # Determine if a restart is required
        If ((Get-WindowsOptionalFeature -Online -FeatureName $FeatureName).RestartRequired -eq "Required") {
            # Restart is required
            $this.ozoLogger.Write(("Please restart to complete the " + $FeatureName + " feature installation and then run this script again to continue."),"Warning")
            $Return = $true
            # Get restart decision
            If ((Get-OZOYesNo) -eq "y") {
                # User elects to restart
                Restart-Computer
            }
        }
        # Return
        return $Return
    }
    # METHODS: Install WSL debian method
    Hidden [Boolean] InstallWSLDebian() {
        # Control variable
        [Boolean] $Return = $true
        # Determine if WSL Debian is not installed
        If ([Boolean](wsl -l | Where-Object {$_.Replace("`0","") -Match '^Debian'}) -eq $false) {
            # Report
            $this.ozoLogger.Write("Attempting to install the WSL Debian distribution.","Information")
            # Try to install WSL Debian
            Try {
                & wsl --install --distribution Debian
                # Success
            } Catch {
                # Failure
                $this.ozoLogger.Write(("Error installing the WSD Debian distribution. Please manually install this distribution and then run this script again to continue. See https://onezeroone.dev/active-directory-lab-part-ii-customization-prerequisites/ for more information."),"Error")
                $Return = $false
            }
        }
        # Return
        return $Return
    }
    # METHODS: Manage local group membership
    Hidden [Boolean] ManageLocalGroup($CurrentUser,$LocalGroup) {
        # Control variable
        [Boolean] $Return = $true
        # Determine if the current user is a member of the local group
        If ((Get-LocalGroupMember -Name $LocalGroup).Name -NotContains $CurrentUser) {
            # Report
            $this.ozoLogger.Write(("Adding user to the local " + $LocalGroup + " group."),"Information")
            # User is not in the local group; try to add them
            Try {
                Add-LocalGroupMember -Group $LocalGroup -Member $CurrentUser -ErrorAction Stop
                # Success
            } Catch {
                # Failure
                $this.ozoLogger.Write(("Failure adding user " + $CurrentUser + " to the " + $LocalGroup + " group. Please manually add this user to this group then run this script again to continue. See https://onezeroone.dev/active-directory-lab-part-ii-customization-prerequisites/ for more information."),"Error")
                $Return = $false
            }
        }
        # Return
        return $Return
    }
    # METHODS: Create VM switches method
    Hidden [Boolean] CreateVMSwitches() {
        # Control variable
        [Boolean] $Return = $true
        # Local variables
        [String] $InternalSwitchName = "OZO AD Lab NAT"
        [String] $SubnetPrefix = "172.16.0.0/24"
        [String] $InternalIP = "172.16.0.1"
        # Determine if the Get-VMSwitch cmdlet is available
        If ([Boolean](Get-Command -Name Get-VMSwitch -ErrorAction SilentlyContinue) -eq $true) {
            # Get-VMSwtich cmdlet is available; determine if the NAT switch does not already exist
            If ([Boolean](Get-VMSwitch -Name $InternalSwitchName -ErrorAction SilentlyContinue) -eq $false) {
                # NAT switch does not already exist; try to create it and set the IP address
                Try {
                    New-VMSwitch -SwitchName $InternalSwitchName -SwitchType Internal -ErrorAction Stop | Out-Null
                    New-NetIPAddress -IPAddress $InternalIP -PrefixLength 24 -InterfaceIndex (Get-NetAdapter -ErrorAction Stop | Where-Object { $_.Name -eq $InternalSwitchName }).ifIndex -ErrorAction SilentlyContinue | Out-Null
                    # Success
                } Catch {
                    # Failure
                    $this.ozoLogger.Write(("Error creating the NAT switch with error " + $_ + ". You may need to log out and back in to refresh your group membership. If that does not resolve the issue, then run this script again to continue. See https://onezeroone.dev/active-directory-lab-part-ii-customization-prerequisites/ for more information."),"Error")
                    $Return = $false
                }
            }
            # Determine if the NAT network already exists
            If ([Boolean](Get-NetNat -Name $InternalSwitchName -ErrorAction SilentlyContinue) -eq $false) {
                # NAT network does not already exist; try to create it
                Try {
                    New-NetNat -Name $InternalSwitchName -InternalIPInterfaceAddressPrefix $SubnetPrefix -ErrorAction Stop | Out-Null
                    # Success
                } Catch {
                    # Failure
                    $this.ozoLogger.Write(("Error creating the NAT network with error " + $_ + ". You may need to manually create this network, then run this script again to continue."),"Error")
                    $Return = $false
                }
            }
            <# Get-VMSwitch cmdlet is available; determine if the private switch already exists
            If ([Boolean](Get-VMSwitch -Name "OZO AD Lab Private") -eq $false) {
                # Report
                $this.ozoLogger.Write("Creating the Hyper-V OZO AD Lab Private VMSwitch.","Information")
                # Private switch does not exist; try to create it
                Try {
                    New-VMSwitch -Name "OZO AD Lab Private" -SwitchType Private -ErrorAction Stop
                    # Success
                } Catch {
                    # Failure
                    $this.ozoLogger.Write("Error creating the VM switches. You may need to log out and back in to refresh your group membership. If that does not help, please manually create these switches. Then run this script again to continue. See https://onezeroone.dev/active-directory-lab-part-ii-customization-prerequisites/ for more information.","Error")
                    $Return = $false
                }
            }
            # Determine if the external switch already exists
            If ([Boolean](Get-VMSwitch -Name "OZO AD Lab External") -eq $false) {
                # Report
                $this.ozoLogger.Write("Creating the Hyper-V OZO AD Lab External VMSwitch.","Information")
                # External switch does not exist; call Get-NetAdapter to display available network connections
                Get-NetAdapter | Out-Host
                # Prompt the user for the name of the external network connection until they correctly identify an adapter
                Do {
                    $externalAdapter = (Read-Host "Above is the output of the Get-NetAdapter command. Type the Name of the network adapter that corresponds with your external network (Internet) connection")
                } Until ((Get-NetAdapter).Name -Contains $externalAdapter)
                # Try to create the external switch
                Try {
                    New-VMSwitch -Name "OZO AD Lab External" -NetAdapterName $externalAdapter -ErrorAction Stop
                    # Success
                } Catch {
                    # Failure
                    $Return = $false
                }
            }
            #>
        } Else {
            # Get-VMSwitch cmdlet is not available
            $Return = $false
        }
        # Return
        return $Return
    }
    # METHODS: Install Microsoft ADK method
    Hidden [Boolean] InstallMicrosoftADK($OscdimgExePath,$SimExePath,$WinAdkFileUri,$WinAdkPath) {
        # Control variable
        [Boolean] $Return = $true
        # Local variables
        # Determine if oscdimg.exe is not present
        If ([Boolean](Test-Path -Path $OscdimgExePath -ErrorAction SilentlyContinue) -eq $false -Or [Boolean](Test-Path $SimExePath -ErrorAction SilentlyContinue) -eq $false) {
            # Report
            $this.ozoLogger.Write("Downloading and installing the Microsoft ADK (Deployment Tools).","Information")
            # Did not find oscdimg.exe; try to download and install
            Try {
                Invoke-WebRequest -Uri $WinAdkFileUri -OutFile $WinAdkPath -ErrorAction Stop
                # Success; try to install
                Try {
                    Invoke-Command -ScriptBlock { & $WinAdkPath /quiet /norestart /features OptionId.DeploymentTools } -ErrorAction Stop | Out-Null
                    # Success; sleep until the installation is complete
                    Do {
                        Start-Sleep -Seconds 1
                    } Until ([Boolean](Test-Path -Path $OscdimgExePath -ErrorAction SilentlyContinue) -eq $true -And [Boolean](Test-Path $SimExePath -ErrorAction SilentlyContinue) -eq $true)
                } Catch {
                    # Failure
                    $this.ozoLogger.Write("Error attempting to download the Microsoft ADK. Please manually download and install and then run this script again to continue. See https://onezeroone.dev/active-directory-lab-part-ii-customization-prerequisites/ for more information.","Error")
                    $Return = $false
                }
            } Catch {
                # Failure
                $this.ozoLogger.Write("Error attempting to install the Microsoft ADK. Please manually download and install and then run this script again to continue. See https://onezeroone.dev/active-directory-lab-part-ii-customization-prerequisites/ for more information.","Error")
                $Return = $false
            }
        }
        # Return
        return $Return
    }
    # METHODS: Get AD Lab resources method
    Hidden [Boolean] GetOZOADLabResources($OZOADLabPath,$OZOADLabDirLike,$OZOADLabZipPath,$OZOADLabZipUri) {
        # Control variable
        [Boolean] $Return = $true
        # Report
        $this.ozoLogger.Write("Downloading and extracting the latest release of the OZO AD Lab resources.","Information")
        # Try to get the latest zipball
        Try {
            Invoke-WebRequest -UseBasicParsing -Uri (Invoke-WebRequest -UseBasicParsing -Uri $OZOADLabZipUri -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop).zipball_url -OutFile $OZOADLabZipPath -ErrorAction Stop
            # Success; expand the archive
            Expand-Archive -Force -Path $OZOADLabZipPath -DestinationPath $Env:TEMP -ErrorAction Stop
            # Remove the archive
            Remove-Item -Path $OZOADLabZipPath -Force
            # Move the extracted folder to the ozoAdLab
            Move-Item -Force -Path (Get-ChildItem -Path $Env:TEMP -ErrorAction Stop | Where-Object {$_.Name -Like $OZOADLabDirLike} | Select-Object -First 1).FullName -Destination $OZOADLabPath
            # Create required (empty) Mount subdirectory
            New-Item -ItemType Directory -Path (Join-Path -Path $OZOADLabPath -ChildPath "Mount") -ErrorAction Stop
        } Catch {
            # Failure
            $this.ozoLogger.Write("Error downloading and extracting the latest OZO AD Lab resources with error " + $_ + ". Please manually download and extract the latest release and run this script again to continue. See https://onezeroone.dev/active-directory-lab-part-ii-customization-prerequisites for more information.","Error")
            $Return = $false
        }
        # Return
        return $Return
    }
    # METHODS: Download ISOs method
    Hidden [Boolean] DownloadISOs($OZOADLabISOs,$OZOADLabPath) {
        # Control variable
        [Boolean] $Return = $true
        # Iterate through the ISOs Hashtable
        Foreach ($ozoADLabIso in $OZOADLabISOs.GetEnumerator()) {
            # Generate the ISO path
            [String] $isoPath = (Join-Path -Path $OZOADLabPath -ChildPath (Join-Path -Path "ISO" -ChildPath $($ozoADLabIso.Key)))
            # Determine if the file does not already exist
            If ([Boolean](Test-Path -Path $isoPath -ErrorAction SilentlyContinue) -eq $false) {
                # Report
                $this.ozoLogger.Write(("Downloading " + $($ozoADLabIso.Key) + " (this could take some time)."),"Information")
                # The ISO does not already exist; try to download
                Try {
                    Invoke-WebRequest -Uri $($ozoADLabIso.Value) -OutFile $isoPath -ErrorAction Stop
                    # Success
                } Catch {
                    # Failure
                    $this.ozoLogger.Write("Error downloading " + $($ozoADLabIso.Key) + ". Please manually download the required ISOs and name them as described in https://onezeroone.dev/active-directory-lab-part-ii-customization-prerequisites.","Error")
                    $Return = $false
                }
            }
        }
        # Return
        return $Return
    }
}

# MAIN
[Main]::new($FeatureName,$LocalGroup,$OscdimgExePath,$OZOADLabDirLike,$OZOADLabPath,$OZOADLabISOs,$OZOADLabZipPath,$OZOADLabZipUri,$SimExePath,$WinAdkFileUri,$WinAdkPath) | Out-Null
