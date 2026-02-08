#pragma once

// UsbDk driver requires Windows 10 version 2004 (20H1) or later
// for ExAllocatePool2 API support

extern "C"
{
#include <ntifs.h>
#include <wdf.h>
#include <usb.h>
#include <initguid.h>
#include <UsbSpec.h>
#include <devpkey.h>
#include <wdfusb.h>
#include <usbdlib.h>
#include <ntstrsafe.h>
#include <usbioctl.h>
}

// Always use NonPagedPoolNx on Windows 10+
#define USBDK_NON_PAGED_POOL    NonPagedPoolNx

#include "UsbDkCompat.h"
