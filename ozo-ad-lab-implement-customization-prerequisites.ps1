#Requires -Modules @{ModuleName="OZO";ModuleVersion="1.5.1"},@{ModuleName="OZOLogger";ModuleVersion="1.1.0"} -RunAsAdministrator

<#PSScriptInfo
    .VERSION 0.1.0
    .GUID 2a8769c1-6be2-44f3-ae17-47b4138ea2fa
    .AUTHOR Andy Lievertz <alievertz@onezeroone.dev>
    .COMPANYNAME One Zero One
    .COPYRIGHT This script is released under the terms of the GNU General Public License ("GPL") version 2.0.
    .TAGS
    .LICENSEURI https://github.com/onezeroone-dev/OZO-AD-Lab-Implement-Prerequisites/blob/main/LICENSE
    .PROJECTURI https://github.com/onezeroone-dev/OZO-AD-Lab-Implement-Prerequisites
    .ICONURI
    .EXTERNALMODULEDEPENDENCIES 
    .REQUIREDSCRIPTS
    .EXTERNALSCRIPTDEPENDENCIES
    .RELEASENOTES https://github.com/onezeroone-dev/OZO-AD-Lab-Implement-Prerequisites/blob/main/CHANGELOG.md
    .PRIVATEDATA
#>

<# 
    .SYNOPSIS
    See description.
    .DESCRIPTION 
    Implements the prerequisites for the One Zero One AD Lab.
    .EXAMPLE
    ozo-ad-lab-implement-prerequisites
    .LINK
    https://github.com/onezeroone-dev/OZO-AD-Lab-Implement-Prerequisites/blob/main/README.md
#>

Class ADLIP {
    # PROPERTIES: Booleans, Strings
    [Boolean] $Relog             = $true
    [String]  $currentUser       = $null
    [String]  $downloadsDir      = $null
    [String]  $featureName       = $null
    [String]  $gitExePath        = $null
    [String]  $localGroup        = $null
    [String]  $ozoAdLabDirLike   = $null
    [String]  $ozoAdLabPath      = $null
    [String]  $ozoAdLabZipPath   = $null
    [String]  $ozoAdLabZipUri    = $null
    [String]  $winAdkFileName    = $null
    [String]  $winAdkPath        = $null
    [String]  $winAdkFileUri     = $null
    [String]  $wingetExePath     = $null
    # PROPERTIES: PSCustomObjects
    [PSCustomObject] $ozoLogger = @()
    # PROPERTIES: Lists
    [System.Collections.Generic.List[PSCustomObject]] $ozoADLabISOs = @()
    # METHODS
    # Constructor method
    ADLIP() {
        # Set properties
        $this.currentUser       = ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        $this.downloadsDir      = (Join-Path -Path $Env:USERPROFILE -ChildPath "Downloads")
        $this.featureName       = "Microsoft-Hyper-V-All"
        $this.localGroup        = "Hyper-V Administrators"
        $this.ozoAdLabDirLike   = "onezeroone-dev-OZO-AD-Lab*"
        $this.ozoAdLabPath      = (Join-Path -Path $Env:SystemDrive -ChildPath "ozo-ad-lab")
        $this.ozoAdLabZipPath   = (Join-Path -Path $Env:USERPROFILE -ChildPath "Downloads\ozo-ad-lab-latest.zip")
        $this.ozoAdLabZipUri    = "https://api.github.com/repos/onezeroone-dev/OZO-AD-Lab/releases/latest"
        $this.winAdkFileName    = "adksetup.exe"
        $this.winAdkPath         = (Join-Path -Path $this.downloadsDir -Childpath $this.winAdkFileName)
        $this.winAdkFileUri     = "https://download.microsoft.com/download/2/d/9/2d9c8902-3fcd-48a6-a22a-432b08bed61e/ADK/adksetup.exe"
        $this.wingetExePath     = (Join-Path -Path $Env:LOCALAPPDATA -ChildPath "Microsoft\WindowsApps\winget.exe")
        # Populate the ozoADLabISOs list
        $this.ozoADLabISOs.Add([PSCustomObject]@{Name="almalinux-boot.iso";Uri="https://repo.almalinux.org/almalinux/9.5/isos/x86_64/AlmaLinux-9.5-x86_64-boot.iso"})
        $this.ozoADLabISOs.Add([PSCustomObject]@{Name="microsoft-windows-11-enterprise-evaluation.iso";Uri="https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1742.240906-0331.ge_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"})
        $this.ozoADLabISOs.Add([PSCustomObject]@{Name="microsoft-windows-11-laof.iso";Uri="https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26100.1.240331-1435.ge_release_amd64fre_CLIENT_LOF_PACKAGES_OEM.iso"})
        $this.ozoADLabISOs.Add([PSCustomObject]@{Name="microsoft-windows-server-2022-evaluation.iso";Uri="https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"})
        # Create a logger object
        $this.ozoLogger = (New-OZOLogger)
        # Declare ourselves to the world
        $this.ozoLogger.Write("Process starting.","Information")
        # Call ValidateEnvironment to determine if we can proceed
        If ($this.ValidateEnvironment() -eq $true) {
            # Environment validates; report and call ProcessPrerequisites to ...process the prerequisites
            $this.ozoLogger.Write("Environment validates.","Information")
            $this.ProcessPrerequisites()
        } Else {
            # Environment did not validate
            $this.ozoLogger.Write("The environment did not validate.","Error")
        }
        # Bid adieu to the world
        $this.ozoLogger.Write("Process complete.","Information")
    }
    # Process prerequisites method
    Hidden [Void] ProcessPrerequisites() {
        # Environment validates; install Hyper-V features
        $this.ozoLogger.Write("Installing Hyper-V features.","Information")
        If ($this.InstallHyperV() -eq $true) {
            # Hyper-V features are installed; install the Debian WSL distribution
            If ($this.InstallWSLDebian() -eq $true) {
                # WSL Debian distribution is installed; determine if a reboot is not required
                $this.ozoLogger.Write("Determining if a restart is required.","Information")
                If ($this.RestartRequired() -eq $false) {
                    # Restart is not required; add the local user to the Hyper-V Administrators group
                    $this.ozoLogger.Write("Adding user to the local Hyper-V Administrators group.","Information")
                    If ($this.ManageLocalHyperVAdministratorsGroup() -eq $true) {
                        # Local user is added to the local Hyper-V Administrators group; create the VM switches
                        $this.ozoLogger.Write("Creating the Hyper-V VMSwitches.","Information")
                        If ($this.CreateVMSwitches() -eq $true) {
                            # VM switches are created; installed the Microsoft SDK
                            $this.ozoLogger.Write("Installing the Microsoft ADK (Deployment Tools).","Information")
                            If ($this.InstallMicrosoftADK() -eq $true) {
                                # Microsoft SDK is installed; install Git for Windows
                                $this.ozoLogger.Write("Downloading and extracting the latest release of the OZO AD Lab resources.","Information")
                                If ($this.GetADLabResources() -eq $true) {
                                    # Got AD Lab resources; download the ISOs
                                    $this.ozoLogger.Write("Downloading the source ISOs (this could take some time).","Information")
                                    If ($this.DownloadISOs() -eq $true) {
                                        # ISOs are downloaded; report all prerequisites satisfied
                                        $this.ozoLogger.Write("All prerequisites are satisfied. Please see https://onezeroone.dev/active-directory-lab-customize-the-windows-installer-isos for the next steps.","Information")
                                    } Else {
                                        # Download error
                                        $this.ozoLogger.Write("Error downloading ISOs. Please manually download the required ISOs. Then see https://onezeroone.dev/active-directory-lab-customize-the-windows-installer-isos for the next steps.","Error")
                                    }
                                } Else {
                                    # Unable to get AD Lab Resources
                                    $this.ozoLogger.Write("Error downloading and extracting the latest OZO AD Lab resources. Please manually download and extract the latest release and run this script again to continue. See https://onezeroone.dev/active-directory-lab-prerequisites for more information.","Error")
                                }
                            } Else {
                                # Microsoft SDK installation error
                                $this.ozoLogger.Write("Error attempting to download and install the Microsoft ADK. Please manually download and install and then run this script again to continue. See https://onezeroone.dev/active-directory-lab-prerequisites for more information.","Error")
                            }
                        } Else {
                            # VMSwitch creation error
                            $this.ozoLogger.Write("Error creating the VM switches. Please manually create these switches then run this script again to continue. See https://onezeroone.dev/active-directory-lab-prerequisites for more information.","Error")
                        }
                    } Else {
                        # Error adding user to local Hyper-V Administrators group
                        $this.ozoLogger.Write(("Failure adding user " + $this.currentUser + " to the " + $this.localGroup + " group. Please manually add this user to this group then run this script again to continue. See https://onezeroone.dev/active-directory-lab-prerequisites for more information."),"Error")
                    }
                } Else {
                    # Restart is required
                    $this.ozoLogger.Write("Please restart to complete the feature installation and then run this script again to continue.","Warning")
                    # Get restart decision
                    If ((Get-OZOYesNo) -eq "y") {
                        # User elects to restart
                        Restart-Computer
                    }
                }
            } Else {
                # Error installing WSL Debian
                $this.ozoLogger.Write(("Error installing the WSD Debian distribution. Please manually install this distribution and then run this script again to continue."),"Error")    
            }
        } Else {
            # Error installing Hyper-V Feature
            $this.ozoLogger.Write(("Error installing the " + $this.featureName + " feature. Please manually install this feature and then run this script again to continue."),"Error")
        }
    }
    # Environment validation method
    Hidden [Boolean] ValidateEnvironment() {
        # Control variable
        [Boolean] $Return = $true
        # Determine if this a user-interactive session
        If ((Get-OZOUserInteractive) -eq $false) {
            # Session is not user-interactive
            $this.ozoLogger.Write("Please run this script in a user-interactive session.","Error")
            $Return = $false
        }
        # Determine if user is an Administrator
        If ((Test-OZOLocalAdministrator) -eq $false) {
            # User is not a local administrator
            $this.ozoLogger.Write("Please run this script in an Administrator PowerShell","Error")
            $Return =$false
        }
        # Determine of winget.exe does not exist
        If ((Test-Path -Path $this.wingetExePath) -eq $false) {
            # Did not find winget.exe
            $this.ozoLogger.Write("Missing winget.exe","Error")
            $Return = $false
        }
        # Determine if there is already an "ozo-ad-lab" folder off the root of the SystemDrive
        If ((Test-Path -Path $this.ozoAdLabPath) -eq $true) {
            # There is already an "ozo-ad-lab" folder
            $this.ozoLogger.Write(("Found " + $this.ozoAdLabPath + ". This directory must be removed before proceeding."),"Error")
            $Return = $false
        }
        # Make sure any previous downloaded + extracted releases of OZO-AD-Lab are wiped
        (Get-ChildItem -Path $Env:TEMP | Where-Object {$_.Name -Like $this.ozoAdLabDirLike}) | Remove-Item -Recurse -Force
        # Return
        return $Return
    }
    # Install Hyper-V method
    Hidden [Boolean] InstallHyperV() {
        # Control variable
        [Boolean] $Return = $true
        # Determine if the feature is present
        If ([Boolean](Get-WindowsOptionalFeature -Online -FeatureName $this.featureName) -eq $false) {
            # Feature is not present; try to install it
            Try {
                Enable-WindowsOptionalFeature -Online -FeatureName $this.featureName -ErrorAction Stop
                # Success
            } Catch {
                # Failure
                $Return = $false
            }
        }
        # Return
        return $Return
    }
    Hidden [Boolean] InstallWSLDebian() {
        # Control variable
        [Boolean] $Return = $true
        # Check if WSL is installed/available and can install Debian
        Try {
            & wsl -l --Debian
            # Success
        } Catch {
            # Failure
            $Return = $false
        }
        # Return
        return $Return
    }
    # Reboot required method
    Hidden [Boolean] RestartRequired() {
        # Control variable
        [Boolean] $Return = $false
        # Determine if feature is present
        If ((Get-WindowsOptionalFeature -Online -FeatureName $this.featureName).RestartRequired -eq "Required") {
            # Restart is required
            $this.Return = $true   
        }
        # Return
        return $Return
    }
    # Manage local Hyper-V Administrators group membership
    Hidden [Boolean] ManageLocalHyperVAdministratorsGroup() {
        # Control variable
        [Boolean] $Return = $true
        # Determine if the current user is a member of the local Hyper-V Administrators group
        If ((Get-LocalGroupMember -Name $this.localGroup).Name -NotContains $this.currentUser) {
            # User is not in the local group; try to add them
            Try {
                Add-LocalGroupMember -Group "Hyper-V Administrators" -Member $this.currentUser
                # Success
            } Catch {
                # Failure
                $Return = $false
            }
        }
        # Return
        return $Return
    }
    # Create VM switches method
    Hidden [Boolean] CreateVMSwitches() {
        # Control variable
        [Boolean] $Return          = $true
        [String]  $externalAdapter = $null
        # Determine if the private switch already exists
        If ([Boolean](Get-VMSwitch -Name "AD Lab Private") -eq $false) {
            # Private switch does not exist; try to create it
            Try {
                New-VMSwitch -Name "AD Lab Private" -SwitchType Private -ErrorAction Stop
                # Success
            } Catch {
                # Failure
                $Return = $false
            }
        }
        # Determine if the external switch already exists
        If ([Boolean](Get-VMSwitch -Name "AD Lab External") -eq $false) {
            # External switch does not exist; call Get-NetAdapter to display available network connections
            Write-Host (Get-NetAdapter)
            # Prompt the user for the name of the external network connection until they correctly identify an adapter
            Do {
                $externalAdapter = (Read-Host "Above is the output of the Get-NetAdapter command. Type the Name of the network adapter that corresponds with your external network (Internet) connection")
            } Until ((Get-NetAdapter).Name -Contains $externalAdapter)
            # Try to create the external switch
            Try {
                New-VMSwitch -Name "AD Lab External" -NetAdapterName $externalAdapter -ErrorAction Stop
                # Success
            } Catch {
                # Failure
                $Return = $false
            }
        }
        # Return
        return $Return
    }
    # Install Microsoft SDK method
    Hidden [Boolean] InstallMicrosoftADK() {
        # Control variable
        [Boolean] $Return = $true
        # Local variables
        [String] $oscdimgExePath = (Join-Path -Path ${Env:ProgramFiles(x86)} -ChildPath "Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe")
        [String] $simExePath     = (Join-Path -Path ${Env:ProgramFiles(x86)} -ChildPath "Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\WSIM\x86\imgmgr.exe")
        # Determine if oscdimg.exe is note present
        If ((Test-Path -Path $oscdimgExePath) -eq $false -Or (Test-Path $simExePath) -eq $false) {
            # Did not find oscdimg.exe; try to download and install
            Try {
                Invoke-WebRequest -Uri $this.winAdkFileUri -OutFile $this.winAdkPath -ErrorAction Stop
                # Success; try to install
                Try {
                    Invoke-Command -ScriptBlock { & $this.winAdkPath /quiet /norestart /features OptionId.DeploymentTools } -ErrorAction Stop | Out-Null
                    # Success; sleep until the installation is complete
                    Do {
                        Start-Sleep -Seconds 1
                    } Until ((Test-Path -Path $oscdimgExePath) -eq $true -And (Test-Path $simExePath) -eq $true)
                } Catch {
                    # Failure
                    $Return = $false
                }
            } Catch {
                # Failure; report
                $Return = $false
            }
        }
        # Return
        return $Return
    }
    # Get AD Lab resources method
    Hidden [Boolean] GetADLabResources() {
        # Control variable
        [Boolean] $Return = $true
        # Try to get the latest zipball
        Try {
            Invoke-WebRequest -Uri (Invoke-WebRequest -Uri $this.ozoAdLabZipUri -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop).zipball_url -OutFile $this.ozoAdLabZipPath -ErrorAction Stop
            # Success; expand the archive
            Expand-Archive -Path $this.ozoAdLabZipPath -DestinationPath $Env:TEMP -ErrorAction Stop
            # Remove the archive
            Remove-Item -Path $this.ozoAdLabZipPath -Force
            # Move the extracted folder to the ozoAdLab
            Move-Item -Path (Get-ChildItem -Path $Env:TEMP -ErrorAction Stop | Where-Object {$_.Name -Like $this.ozoAdLabDirLike} | Select-Object -First 1).FullName -Destination $this.ozoAdLabPath
            # Create required (empty) Mount subdirectory
            New-Item -ItemType Directory -Path (Join-Path -Path $this.ozoAdLabPath -ChildPath "Mount") -ErrorAction Stop
        } Catch {
            #Failure
            $Return = $false
        }

        # Return
        return $Return
    }
    # Download ISOs method
    Hidden [Boolean] DownloadISOs() {
        # Control variable
        [Boolean] $Return = $true
        # Iterate through the ISOs
        ForEach ($ozoAdLabIso in $this.ozoADLabISOs) {
            # Try to get the ISO
            Try {
                Invoke-WebRequest -Uri $ozoAdLabIso.Uri -OutFile (Join-Path -Path $this.ozoAdLabPath -ChildPath (Join-Path -Path "ISO" -ChildPath $ozoAdLabIso.Name)) -ErrorAction Stop
                # Success
            } Catch {
                # Failure
                $Return = $false
            }
        }
        # Return
        return $Return
    }
}

Function Get-OZOYesNo {
    # Prompt the user to restart and return the lowercase of the first letter of their response
    [String]$response = $null
    Do {
        $response = (Read-Host "(Y/N)")[0].ToLower()
    } Until ($response -eq "y" -Or $response -eq "n")
    # Return response
    return $response
}

# MAIN
[ADLIP]::new() | Out-Null
