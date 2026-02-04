/**********************************************************************
* Copyright (c) 2013-2014  Red Hat, Inc.
*
* Developed by Daynix Computing LTD.
*
* Authors:
*     Dmitry Fleytman <dmitry@daynix.com>
*     Pavel Gurvich <pavel@daynix.com>
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
**********************************************************************/

#include "stdafx.h"
#include "Installer.h"
#include "Public.h"
#include "DeviceMgr.h"
#include <iterator>


#define SYSTEM32_DRIVERS    TEXT("\\System32\\Drivers\\")

#define UPPER_FILTER_REGISTRY_SUBTREE TEXT("System\\CurrentControlSet\\Control\\Class\\{36FC9E60-C465-11CF-8056-444553540000}\\")
#define UPPER_FILTER_REGISTRY_KEY TEXT("UpperFilters")

// Windows 11 specific error codes
#ifndef ERROR_DRIVER_BLOCKED
#define ERROR_DRIVER_BLOCKED 0x4E6  // Driver is blocked by policy
#endif
#ifndef ERROR_DRIVER_FAILED_PRIOR_UNLOAD
#define ERROR_DRIVER_FAILED_PRIOR_UNLOAD 0x28C  // Previous driver version failed to unload
#endif

// Machine type constants for ARM64 detection
#ifndef IMAGE_FILE_MACHINE_I386
#define IMAGE_FILE_MACHINE_I386 0x014c
#endif
#ifndef IMAGE_FILE_MACHINE_AMD64
#define IMAGE_FILE_MACHINE_AMD64 0x8664
#endif
#ifndef IMAGE_FILE_MACHINE_ARMNT
#define IMAGE_FILE_MACHINE_ARMNT 0x01c4
#endif
#ifndef IMAGE_FILE_MACHINE_ARM64
#define IMAGE_FILE_MACHINE_ARM64 0xAA64
#endif

using namespace std;

UsbDkInstaller::UsbDkInstaller()
{
    validatePlatform();

    m_regAccess.SetPrimaryKey(HKEY_LOCAL_MACHINE);
}

bool UsbDkInstaller::Install(bool &NeedRollBack)
{
    NeedRollBack = false;
    
    // Check and handle driver signing requirements for Windows 11
    // This will attempt to enable test signing mode if needed
    // Returns false if reboot is required for test signing
    bool signingOk = checkAndHandleDriverSigningRequirements();
    
    auto driverLocation = CopyDriver();
    NeedRollBack = true;
    auto infFilePath = buildInfFilePath();

    auto rebootRequired = !m_wdfCoinstaller.PreDeviceInstallEx(infFilePath);

    m_scManager.CreateServiceObject(USBDK_DRIVER_NAME, driverLocation.c_str());

    verifyDriverCanStart();

    m_wdfCoinstaller.PostDeviceInstall(infFilePath);
    addUsbDkToRegistry();

    // If test signing was just enabled, reboot is required
    if (!signingOk)
    {
        rebootRequired = true;
    }

    return rebootRequired ? false : DeviceMgr::ResetDeviceByClass(GUID_DEVINTERFACE_USB_HOST_CONTROLLER);
}

void UsbDkInstaller::Uninstall()
{
    removeUsbDkFromRegistry();

    DeviceMgr::ResetDeviceByClass(GUID_DEVINTERFACE_USB_HOST_CONTROLLER);

    DeleteDriver();

    auto infFilePath = buildInfFilePath();

    m_wdfCoinstaller.PreDeviceRemove(infFilePath);

    m_scManager.DeleteServiceObject(USBDK_DRIVER_NAME);

    m_wdfCoinstaller.PostDeviceRemove(infFilePath);
}

tstring UsbDkInstaller::CopyDriver()
{
    TCHAR currDirectory[MAX_PATH];
    if (!GetCurrentDirectory(MAX_PATH, currDirectory))
    {
        throw UsbDkInstallerFailedException(TEXT("GetCurrentDirectory failed!"));
    }

    tstring driverOrigLocationStr(tstring(currDirectory) + TEXT("\\") USBDK_DRIVER_FILE_NAME);

    auto driverDestLocation = buildDriverPath(USBDK_DRIVER_FILE_NAME);

    if (!CopyFile(driverOrigLocationStr.c_str(), driverDestLocation.c_str(), TRUE))
    {
        throw UsbDkInstallerFailedException(tstring(TEXT("CopyFile from ")) + driverOrigLocationStr + TEXT(" to ") + driverDestLocation + TEXT(" failed."));
    }

    return driverDestLocation;
}

void UsbDkInstaller::DeleteDriver()
{
    auto driverDestLocation = buildDriverPath(USBDK_DRIVER_FILE_NAME);

    if (!DeleteFile(driverDestLocation.c_str()))
    {
        auto errCode = GetLastError();
        if (errCode != ERROR_FILE_NOT_FOUND)
        {
            throw UsbDkInstallerFailedException(TEXT("DeleteFile failed."), errCode);
        }
        return;
    }
}

tstring UsbDkInstaller::buildDriverPath(const tstring &DriverFileName)
{
    TCHAR    driverDestPath[MAX_PATH];
    GetWindowsDirectory(driverDestPath, MAX_PATH);

    return tstring(driverDestPath) + SYSTEM32_DRIVERS + DriverFileName;
}

tstring UsbDkInstaller::buildInfFilePath()
{
    TCHAR currDir[MAX_PATH];
    if (GetCurrentDirectory(MAX_PATH, currDir) == 0)
    {
        throw UsbDkInstallerFailedException(TEXT("GetCurrentDirectory failed!"));
    }

    return tstring(currDir) + TEXT("\\") + USBDK_DRIVER_INF_NAME;
}

void UsbDkInstaller::addUsbDkToRegistry()
{
    LPCTSTR upperFilterString = UPPER_FILTER_REGISTRY_KEY;
    LPCTSTR upperFiltersKeyStr = UPPER_FILTER_REGISTRY_SUBTREE;

    // check for value size
    DWORD valLen = 0;
    auto errCode = m_regAccess.ReadMultiString(upperFilterString, nullptr, 0, valLen, upperFiltersKeyStr);

    if (errCode != ERROR_FILE_NOT_FOUND && errCode != ERROR_SUCCESS)
    {
        throw UsbDkInstallerFailedException(TEXT("addUsbDkToRegistry failed in ReadMultiString!"), errCode);
    }

    vector<TCHAR> valVector;
    tstringlist newfiltersList;
    if (valLen)
    {
        // get the value
        valVector.resize(valLen);
        errCode = m_regAccess.ReadMultiString(upperFilterString, &valVector[0], valLen, valLen, upperFiltersKeyStr);

        if (errCode != ERROR_FILE_NOT_FOUND && errCode != ERROR_SUCCESS)
        {
            throw UsbDkInstallerFailedException(TEXT("addUsbDkToRegistry failed in ReadMultiString!"), errCode);
        }

        tstringlist filtersList;
        buildStringListFromVector(filtersList, valVector);
        buildNewListWithoutEement(newfiltersList, filtersList, USBDK_DRIVER_NAME);
    }

    newfiltersList.push_back(USBDK_DRIVER_NAME);

    valVector.clear();
    buildMultiStringVectorFromList(valVector, newfiltersList);

    // set new value to registry
    if (!m_regAccess.WriteMultiString(upperFilterString,
                                      &valVector[0],
                                      static_cast<DWORD>(sizeof(TCHAR) * valVector.size()),
                                      upperFiltersKeyStr))
    {
        throw UsbDkInstallerFailedException(TEXT("addUsbDkToRegistry failed in WriteMultiString."));
    }
}

void UsbDkInstaller::removeUsbDkFromRegistry()
{
    // If key exists, and value (Multiple string) includes "UsbDk", remove it from value.

    LPCTSTR upperFilterString = UPPER_FILTER_REGISTRY_KEY;
    LPCTSTR upperFiltersKeyStr = UPPER_FILTER_REGISTRY_SUBTREE;

    // check for value size
    DWORD valLen = 0;
    auto errCode = m_regAccess.ReadMultiString(upperFilterString, nullptr, 0, valLen, upperFiltersKeyStr);

    if (errCode != ERROR_FILE_NOT_FOUND && errCode != ERROR_SUCCESS)
    {
        throw UsbDkInstallerFailedException(TEXT("addUsbDkToRegistry failed in ReadMultiString!"), errCode);
    }

    if (valLen)
    {
        // get the value
        vector<TCHAR> valVector(valLen);
        errCode = m_regAccess.ReadMultiString(upperFilterString, &valVector[0], valLen, valLen, upperFiltersKeyStr);

        if (errCode != ERROR_FILE_NOT_FOUND && errCode != ERROR_SUCCESS)
        {
            throw UsbDkInstallerFailedException(TEXT("addUsbDkToRegistry failed in ReadMultiString!"), errCode);
        }

        if (!valLen)
        {
            return;
        }

        tstringlist filtersList;
        buildStringListFromVector(filtersList, valVector);

        tstringlist newfiltersList;
        buildNewListWithoutEement(newfiltersList, filtersList, USBDK_DRIVER_NAME);

        valVector.clear();
        buildMultiStringVectorFromList(valVector, newfiltersList);

        // set new value to registry
        if (!m_regAccess.WriteMultiString(upperFilterString,
                                          &valVector[0],
                                          static_cast<DWORD>(sizeof(TCHAR) * valVector.size()),
                                          upperFiltersKeyStr))
        {
            return;
        }
    }
}

void UsbDkInstaller::buildMultiStringVectorFromList(vector<TCHAR> &valVector, tstringlist &newfiltersList)
{
    for (auto filter : newfiltersList)
    {
        std::copy(filter.begin(), filter.end(), std::back_inserter(valVector));
        valVector.push_back(TEXT('\0'));
    }
    if (valVector.empty())
    {
        valVector.push_back(TEXT('\0'));
    }
    valVector.push_back(TEXT('\0'));
}

void UsbDkInstaller::buildStringListFromVector(tstringlist &filtersList, vector<TCHAR> &valVector)
{
    tstring currFilter;
    tstring::size_type currPos = 0;

    do
    {
        currFilter = &valVector[currPos];

        if (!currFilter.empty())
        {
            filtersList.push_back(currFilter);
        }

        currPos += currFilter.size() + 1;
        if (currPos >= valVector.size())
        {
            break;
        }

    } while (!currFilter.empty());
}

void UsbDkInstaller::buildNewListWithoutEement(tstringlist &newfiltersList, tstringlist &filtersList, tstring element)
{
    for (auto filter : filtersList)
    {
        if (filter != USBDK_DRIVER_NAME)
        {
            newfiltersList.push_back(filter);
        }
    }
}

void UsbDkInstaller::validatePlatform()
{
    if (isWow64B())
    {
        throw UsbDkInstallerFailedException(TEXT("Running 32Bit package on 64Bit OS not supported."),
                                            ERROR_EXE_MACHINE_TYPE_MISMATCH);
    }
}

bool UsbDkInstaller::isWow64B()
{
    BOOL bIsWow64 = FALSE;

    typedef BOOL(WINAPI *LPFN_ISWOW64PROCESS) (HANDLE, PBOOL);
    typedef BOOL(WINAPI *LPFN_ISWOW64PROCESS2) (HANDLE, USHORT*, USHORT*);

    // First try IsWow64Process2 for better ARM64 detection (Windows 10 1511+, Windows 11)
    LPFN_ISWOW64PROCESS2 fnIsWow64Process2 = reinterpret_cast<LPFN_ISWOW64PROCESS2>(
        GetProcAddress(GetModuleHandle(TEXT("kernel32")), "IsWow64Process2"));
    
    if (nullptr != fnIsWow64Process2)
    {
        USHORT processMachine = 0;
        USHORT nativeMachine = 0;
        if (fnIsWow64Process2(GetCurrentProcess(), &processMachine, &nativeMachine))
        {
            // Check if we're running 32-bit (x86 or ARM32) on 64-bit system (x64 or ARM64)
            if ((processMachine == IMAGE_FILE_MACHINE_I386 && nativeMachine == IMAGE_FILE_MACHINE_AMD64) ||  // x86 on x64
                (processMachine == IMAGE_FILE_MACHINE_ARMNT && nativeMachine == IMAGE_FILE_MACHINE_ARM64))    // ARM32 on ARM64
            {
                return true;
            }
            return false;
        }
    }

    // Fallback to IsWow64Process for older Windows versions
    LPFN_ISWOW64PROCESS  fnIsWow64Process = reinterpret_cast<LPFN_ISWOW64PROCESS>(
        GetProcAddress(GetModuleHandle(TEXT("kernel32")), "IsWow64Process"));
    if (nullptr != fnIsWow64Process)
    {
        if (!fnIsWow64Process(GetCurrentProcess(), &bIsWow64))
        {
            return false;
        }
    }
    return bIsWow64 ? true : false;
}

void UsbDkInstaller::verifyDriverCanStart()
{
    try
    {
        m_scManager.StartServiceObject(USBDK_DRIVER_NAME);
        m_scManager.StopServiceObject(USBDK_DRIVER_NAME);
    }
    catch (const UsbDkServiceManagerFailedException &e)
    {
        auto err = e.GetErrorCode();
       /* ERROR_SERVICE_DISABLED occurs in case we are attempting to start the
        * driver without associating it with a device.
        * Windows 11 specific errors are also handled:
        * - ERROR_DRIVER_BLOCKED: Driver is blocked by policy
        * - ERROR_DRIVER_FAILED_PRIOR_UNLOAD: Previous driver version failed to unload
        */
        if (err != ERROR_SERVICE_DISABLED && 
            err != ERROR_DRIVER_BLOCKED &&
            err != ERROR_DRIVER_FAILED_PRIOR_UNLOAD)
        {
            try
            {
                m_scManager.DeleteServiceObject(USBDK_DRIVER_NAME);
            }
            catch (const exception &e)
            {
                UNREFERENCED_PARAMETER(e);
            }
            throw UsbDkInstallerAbortedException();
        }
    }
}

bool UsbDkInstaller::isTestSigningEnabled()
{
    // Check BCD store to see if test signing is enabled
    DWORD testSigningValue = 0;
    if (m_regAccess.ReadDWord(TEXT("TestSigning"), &testSigningValue, TEXT("System\\CurrentControlSet\\Control\\CI\\Policy")))
    {
        return (testSigningValue != 0);
    }
    return false;
}

bool UsbDkInstaller::enableTestSigningMode()
{
    // Use bcdedit to enable test signing mode
    // This requires administrator privileges
    TCHAR cmdLine[MAX_PATH];
    _tcscpy_s(cmdLine, MAX_PATH, TEXT("bcdedit.exe /set testsigning on"));
    
    STARTUPINFO si = { sizeof(STARTUPINFO) };
    PROCESS_INFORMATION pi = { 0 };
    
    if (!CreateProcess(NULL, cmdLine, NULL, NULL, FALSE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi))
    {
        OutputDebugString(TEXT("UsbDkInstaller: Failed to launch bcdedit"));
        return false;
    }
    
    // Wait for bcdedit to complete (30 second timeout)
    DWORD waitResult = WaitForSingleObject(pi.hProcess, 30000);
    
    DWORD exitCode = 1; // Default to error
    if (waitResult == WAIT_OBJECT_0)
    {
        // Process completed successfully
        GetExitCodeProcess(pi.hProcess, &exitCode);
    }
    else if (waitResult == WAIT_TIMEOUT)
    {
        OutputDebugString(TEXT("UsbDkInstaller: bcdedit timed out"));
        TerminateProcess(pi.hProcess, 1);
    }
    else
    {
        OutputDebugString(TEXT("UsbDkInstaller: WaitForSingleObject failed"));
    }
    
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
    
    return (exitCode == 0);
}

bool UsbDkInstaller::checkAndHandleDriverSigningRequirements()
{
    // Check if running on Windows 10 1607+ or Windows 11
    // These versions have stricter signing requirements
    TCHAR buildNumberStr[32] = {0};
    DWORD buildNumberLen = ARRAYSIZE(buildNumberStr);
    
    if (m_regAccess.ReadString(TEXT("CurrentBuild"), buildNumberStr, buildNumberLen, TEXT("Software\\Microsoft\\Windows NT\\CurrentVersion")) == ERROR_SUCCESS)
    {
        DWORD buildNumber = _ttoi(buildNumberStr);
        
        // Windows 10 1607 = build 14393, Windows 11 = build 22000+
        if (buildNumber >= 14393)
        {
            OutputDebugString(TEXT("UsbDkInstaller: Detected Windows 10 1607+ or Windows 11, checking test signing..."));
            
            // Check if test signing is already enabled
            if (!isTestSigningEnabled())
            {
                OutputDebugString(TEXT("UsbDkInstaller: Test signing not enabled, attempting to enable..."));
                
                // Try to enable test signing mode
                if (enableTestSigningMode())
                {
                    OutputDebugString(TEXT("UsbDkInstaller: Test signing enabled successfully. Reboot required."));
                    return false; // Return false to indicate reboot needed
                }
                else
                {
                    OutputDebugString(TEXT("UsbDkInstaller: Failed to enable test signing mode automatically."));
                    // Continue anyway - maybe the driver is properly signed
                    return true;
                }
            }
            else
            {
                OutputDebugString(TEXT("UsbDkInstaller: Test signing already enabled."));
            }
        }
    }
    return true;
}
