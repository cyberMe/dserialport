module dserialport.infoprivate_windows;

pragma(lib, "advapi32.lib");
pragma(lib, "setupapi.lib");

import std.string;
import std.conv;
import std.algorithm : canFind;
import std.array : empty;
import std.utf : toUTF8;
import std.c.windows.com : GUID;
import core.sys.windows.windows;

import dserialport.portinfo;

private
{

struct SP_DEVINFO_DATA
{
    DWORD cbSize;
    GUID ClassGuid;
    DWORD DevInst;
    ULONG_PTR Reserved;
}

alias PVOID HDEVINFO;
alias SP_DEVINFO_DATA *PSP_DEVINFO_DATA;

// Flags controlling what is included in the device information set built
// by SetupDiGetClassDevs
enum
{
    DIGCF_DEFAULT         = 0x00000001, // only valid with DIGCF_DEVICEINTERFACE
    DIGCF_PRESENT         = 0x00000002,
    DIGCF_ALLCLASSES      = 0x00000004,
    DIGCF_PROFILE         = 0x00000008,
    DIGCF_DEVICEINTERFACE = 0x00000010
}

// Values specifying the scope of a device property change
enum
{
    DICS_FLAG_GLOBAL         = 0x00000001,  // make change in all hardware profiles
    DICS_FLAG_CONFIGSPECIFIC = 0x00000002,  // make change in specified profile only
    DICS_FLAG_CONFIGGENERAL  = 0x00000004  // 1 or more hardware profile-specific
}

// KeyType values for SetupDiCreateDevRegKey, SetupDiOpenDevRegKey, and
// SetupDiDeleteDevRegKey.
enum
{
    DIREG_DEV  = 0x00000001,  // Open/Create/Delete device key
    DIREG_DRV  = 0x00000002,  // Open/Create/Delete driver key
    DIREG_BOTH = 0x00000004  // Delete both driver and Device key
}

// Device registry property codes
// (Codes marked as read-only (R) may only be used for
// SetupDiGetDeviceRegistryProperty)
//
// These values should cover the same set of registry properties
// as defined by the CM_DRP codes in cfgmgr32.h.
//
// Note that SPDRP codes are zero based while CM_DRP codes are one based!
enum
{
    SPDRP_DEVICEDESC                  = 0x00000000,  // DeviceDesc (R/W)
    SPDRP_HARDWAREID                  = 0x00000001,  // HardwareID (R/W)
    SPDRP_COMPATIBLEIDS               = 0x00000002,  // CompatibleIDs (R/W)
    SPDRP_UNUSED0                     = 0x00000003,  // unused
    SPDRP_SERVICE                     = 0x00000004,  // Service (R/W)
    SPDRP_UNUSED1                     = 0x00000005,  // unused
    SPDRP_UNUSED2                     = 0x00000006,  // unused
    SPDRP_CLASS                       = 0x00000007,  // Class (R--tied to ClassGUID)
    SPDRP_CLASSGUID                   = 0x00000008,  // ClassGUID (R/W)
    SPDRP_DRIVER                      = 0x00000009,  // Driver (R/W)
    SPDRP_CONFIGFLAGS                 = 0x0000000A,  // ConfigFlags (R/W)
    SPDRP_MFG                         = 0x0000000B,  // Mfg (R/W)
    SPDRP_FRIENDLYNAME                = 0x0000000C,  // FriendlyName (R/W)
    SPDRP_LOCATION_INFORMATION        = 0x0000000D,  // LocationInformation (R/W)
    SPDRP_PHYSICAL_DEVICE_OBJECT_NAME = 0x0000000E,  // PhysicalDeviceObjectName (R)
    SPDRP_CAPABILITIES                = 0x0000000F,  // Capabilities (R)
    SPDRP_UI_NUMBER                   = 0x00000010,  // UiNumber (R)
    SPDRP_UPPERFILTERS                = 0x00000011,  // UpperFilters (R/W)
    SPDRP_LOWERFILTERS                = 0x00000012,  // LowerFilters (R/W)
    SPDRP_BUSTYPEGUID                 = 0x00000013,  // BusTypeGUID (R)
    SPDRP_LEGACYBUSTYPE               = 0x00000014,  // LegacyBusType (R)
    SPDRP_BUSNUMBER                   = 0x00000015,  // BusNumber (R)
    SPDRP_ENUMERATOR_NAME             = 0x00000016,  // Enumerator Name (R)
    SPDRP_SECURITY                    = 0x00000017,  // Security (R/W, binary form)
    SPDRP_SECURITY_SDS                = 0x00000018,  // Security (W, SDS form)
    SPDRP_DEVTYPE                     = 0x00000019,  // Device Type (R/W)
    SPDRP_EXCLUSIVE                   = 0x0000001A,  // Device is exclusive-access (R/W)
    SPDRP_CHARACTERISTICS             = 0x0000001B,  // Device Characteristics (R/W)
    SPDRP_ADDRESS                     = 0x0000001C,  // Device Address (R)
    SPDRP_UI_NUMBER_DESC_FORMAT       = 0X0000001D,  // UiNumberDescFormat (R/W)
    SPDRP_DEVICE_POWER_DATA           = 0x0000001E,  // Device Power Data (R)
    SPDRP_REMOVAL_POLICY              = 0x0000001F,  // Removal Policy (R)
    SPDRP_REMOVAL_POLICY_HW_DEFAULT   = 0x00000020,  // Hardware Removal Policy (R)
    SPDRP_REMOVAL_POLICY_OVERRIDE     = 0x00000021,  // Removal Policy Override (RW)
    SPDRP_INSTALL_STATE               = 0x00000022,  // Device Install State (R)
    SPDRP_LOCATION_PATHS              = 0x00000023,  // Device Location Paths (R)
    SPDRP_BASE_CONTAINERID            = 0x00000024,  // Base ContainerID (R)

    SPDRP_MAXIMUM_PROPERTY            = 0x00000025  // Upper bound on ordinals
}

extern (Windows)
{
    HDEVINFO SetupDiGetClassDevsW(in GUID *ClassGuid, in PCWSTR Enumerator, in HWND hwndParent, in DWORD Flags);
    BOOL SetupDiEnumDeviceInfo(in HDEVINFO DeviceInfoSet, in DWORD MemberIndex, PSP_DEVINFO_DATA DeviceInfoData);
    BOOL SetupDiDestroyDeviceInfoList(in HDEVINFO DeviceInfoSet);
    HKEY SetupDiOpenDevRegKey(in HDEVINFO DeviceInfoSet, in PSP_DEVINFO_DATA DeviceInfoData,
        in DWORD Scope, in DWORD HwProfile, in DWORD KeyType, in REGSAM samDesired);
    BOOL SetupDiGetDeviceRegistryPropertyW(in HDEVINFO DeviceInfoSet, in PSP_DEVINFO_DATA DeviceInfoData,
        in DWORD Property, PDWORD PropertyRegDataType, PBYTE PropertyBuffer,
        in DWORD PropertyBufferSize, PDWORD RequiredSize);
    BOOL SetupDiGetDeviceInstanceIdW(in HDEVINFO DeviceInfoSet,in PSP_DEVINFO_DATA DeviceInfoData,
        PWSTR DeviceInstanceId, in DWORD DeviceInstanceIdSize, PDWORD RequiredSize);
}

immutable defaultPathPrefix = r"\\.\";

immutable GUID guids[] =
[
    // Windows Ports Class GUID
    { 0x4D36E978, 0xE325, 0x11CE, [ 0xBF, 0xC1, 0x08, 0x00, 0x2B, 0xE1, 0x03, 0x18 ] },
    // Virtual Ports Class GUID (i.e. com0com and etc)
    { 0xDF799E12, 0x3C56, 0x421B, [ 0xB2, 0x98, 0xB6, 0xD3, 0x64, 0x2B, 0xC8, 0x78 ] },
    // Windows Modems Class GUID
    { 0x4D36E96D, 0xE325, 0x11CE, [ 0xBF, 0xC1, 0x08, 0x00, 0x2B, 0xE1, 0x03, 0x18 ] },
    // Eltima Virtual Serial Port Driver v4 GUID
    { 0xCC0EF009, 0xB820, 0x42F4, [ 0x95, 0xA9, 0x9B, 0xFA, 0x6A, 0x5A, 0xB7, 0xAB ] },
    // Advanced Virtual COM Port GUID
    { 0x9341CD95, 0x4371, 0x4A37, [ 0xA5, 0xAF, 0xFD, 0xB0, 0xA9, 0xD1, 0x96, 0x31 ] },
];

string devicePortName(in HDEVINFO deviceInfoSet, in PSP_DEVINFO_DATA deviceInfoData)
{
    // String literals are already null-terminated
    static immutable portKeyName = "PortName"w;

    const key = SetupDiOpenDevRegKey(deviceInfoSet, deviceInfoData, DICS_FLAG_GLOBAL,
                                         0, DIREG_DEV, KEY_READ);
    if (INVALID_HANDLE_VALUE == key)
    {
        return null;
    }
    scope(exit) RegCloseKey(key);

    DWORD byteCount = 0;
    if (RegQueryValueExW(key, portKeyName.ptr, null, null, null, &byteCount) != ERROR_SUCCESS)
    {
        return null;
    }

    wchar[] data;
    data.length = byteCount / typeof(data[0]).sizeof;
    if (RegQueryValueExW(key, portKeyName.ptr, null, null, data.ptr, &byteCount) != ERROR_SUCCESS)
    {
        return null;
    }

    // Skip null-character
    return toUTF8(data[0 .. $ - 1]);
}

string deviceRegistryProperty(in HDEVINFO deviceInfoSet, in PSP_DEVINFO_DATA deviceInfoData, in DWORD property)
{
    DWORD dataType = 0;
    DWORD byteCount = 0;
    // This function returns ERROR_INSUFFICIENT_BUFFER after try to get required buffer size
    // Also it has bug with DBCS for win2000 http://support.microsoft.com/kb/888609/en-us
    SetupDiGetDeviceRegistryPropertyW(deviceInfoSet, deviceInfoData, property, &dataType, null, 0, &byteCount);
    if (0 == byteCount)
    {
        return null;
    }

    wchar[] data;
    data.length = byteCount / typeof(data[0]).sizeof;
    if (!SetupDiGetDeviceRegistryPropertyW(deviceInfoSet, deviceInfoData, property,
            null, cast(PBYTE)data.ptr, byteCount, null))
    {
        return null;
    }

    switch (dataType)
    {
        case REG_EXPAND_SZ:
        case REG_SZ:
        {
            // Skip null-character
            return toUTF8(data[0 .. $ - 1]);
        }

        case REG_MULTI_SZ:
        {
            /*QStringList list;
            int i = 0;
            forever {
                QString s = QString::fromWCharArray(reinterpret_cast<const wchar_t *>(data.constData()) + i);
                i += s.length() + 1;
                if (s.isEmpty())
                    break;
                list.append(s);
            }
            return QVariant(list);*/
            assert(false, "TODO: not implemented");
        }

        default:
            return null;
    }
}

string deviceInstanceIdentifier(in HDEVINFO deviceInfoSet, in PSP_DEVINFO_DATA deviceInfoData)
{
    DWORD wcharCount = 0;
    // This function returns ERROR_INSUFFICIENT_BUFFER after try to get required buffer size
    SetupDiGetDeviceInstanceIdW(deviceInfoSet, deviceInfoData, null, 0, &wcharCount);
    if (0 == wcharCount)
    {
        return null;
    }

    wchar[] data;
    data.length = wcharCount;
    if (!SetupDiGetDeviceInstanceIdW(deviceInfoSet, deviceInfoData, data.ptr, data.length, null))
    {
        // TODO: error handling with GetLastError
        return null;
    }

    // Skip null-character
    return toUTF8(data[0 .. $ - 1]);
}

} // private

package class SerialPortInfoPrivate
{
public:
    static SerialPortInfo[] availablePorts() @property
    {
        static immutable usbVendorIdentifierPrefix = "VID_";
        static immutable usbProductIdentifierPrefix = "PID_";
        static immutable pciVendorIdentifierPrefix = "VEN_";
        static immutable pciDeviceIdentifierPrefix = "DEV_";

        static immutable vendorIdentifierSize = 4;
        static immutable productIdentifierSize = 4;

        SerialPortInfo[] serialPortInfoList = null;
        foreach (ref guid; guids)
        {
            const deviceInfoSet = SetupDiGetClassDevsW(&guid, null, null, DIGCF_PRESENT);
            if (INVALID_HANDLE_VALUE == deviceInfoSet)
            {
                return serialPortInfoList;
            }
            scope(exit) SetupDiDestroyDeviceInfoList(deviceInfoSet);

            SP_DEVINFO_DATA deviceInfoData = { cbSize:SP_DEVINFO_DATA.sizeof };
            DWORD index = 0;
            while (SetupDiEnumDeviceInfo(deviceInfoSet, index++, &deviceInfoData))
            {
                SerialPortInfo serialPortInfo = new SerialPortInfo();

                string devicePortName = devicePortName(deviceInfoSet, &deviceInfoData);
                if (devicePortName.empty || devicePortName.canFind("LPT"))
                {
                    continue;
                }

                with(serialPortInfo.mImpl)
                {
                    portName = devicePortName;
                    device = portNameToSystemLocation(devicePortName);
                    description = deviceRegistryProperty(deviceInfoSet, &deviceInfoData, SPDRP_DEVICEDESC);
                    manufacturer = deviceRegistryProperty(deviceInfoSet, &deviceInfoData, SPDRP_MFG);
                }

                bool getIdentifierFromHex(in string content, in string key, in int size, out ushort identifier)
                {
                    auto index = content.indexOf(key);
                    if (-1 == index)
                    {
                        return false;
                    }

                    index += key.length;
                    try
                    {
                        identifier = content[index .. index + size].toImpl!ushort(16);
                    }
                    catch(ConvException)
                    {
                        return false;
                    }
                    return true;
                }

                immutable deviceIdentifier = deviceInstanceIdentifier(deviceInfoSet, &deviceInfoData).toUpper();

                with(serialPortInfo.mImpl)
                {
                    hasVendorIdentifier = getIdentifierFromHex(deviceIdentifier,
                        usbVendorIdentifierPrefix, vendorIdentifierSize, vendorIdentifier);
                    if (!hasVendorIdentifier)
                    {
                        hasVendorIdentifier = getIdentifierFromHex(deviceIdentifier,
                            pciVendorIdentifierPrefix, vendorIdentifierSize, vendorIdentifier);
                    }

                    hasProductIdentifier = getIdentifierFromHex(deviceIdentifier,
                        usbProductIdentifierPrefix, productIdentifierSize, productIdentifier);
                    if (!hasProductIdentifier)
                    {
                        hasProductIdentifier = getIdentifierFromHex(deviceIdentifier,
                            pciDeviceIdentifierPrefix, productIdentifierSize, productIdentifier);
                    }
                }

                serialPortInfoList ~= serialPortInfo;
            }
        }
        return serialPortInfoList;
    }
    
    static string portNameToSystemLocation(in string port)
    {
        if (port.startsWith(defaultPathPrefix))
        {
            return port;
        }
        return defaultPathPrefix ~ port;
    }

    string portName;
    string device;
    string description;
    string manufacturer;
    ushort vendorIdentifier;
    ushort productIdentifier;
    bool hasVendorIdentifier;
    bool hasProductIdentifier;
}
