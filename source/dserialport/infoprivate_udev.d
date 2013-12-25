module dserialport.infoprivate_udev;

import std.conv;

import dserialport.portinfo;

// udev's entities
struct udev;
struct udev_enumerate;
struct udev_list_entry;
struct udev_device;

extern (C) udev * udev_new();
extern (C) void udev_unref(udev * udev_);
extern (C) udev_enumerate * udev_enumerate_new(udev * udev_);
extern (C) void udev_enumerate_unref(udev_enumerate * udev_enumerate_);
extern (C) int udev_enumerate_add_match_subsystem(udev_enumerate * udev_enumerate_, const(char) * subsystem_);
extern (C) int udev_enumerate_scan_devices(udev_enumerate * udev_enumerate_);
extern (C) udev_list_entry * udev_enumerate_get_list_entry(udev_enumerate * udev_enumerate_);
extern (C) udev_list_entry * udev_list_entry_get_next(udev_list_entry * list_entry_);
extern (C) udev_device * udev_device_new_from_syspath(udev * udev_, const(char) * syspath_);
extern (C) void udev_device_unref(udev_device * udev_device_);
extern (C) const(char) * udev_list_entry_get_name(udev_list_entry * list_entry_);
extern (C) const(char) * udev_device_get_devnode(udev_device * udev_device_);
extern (C) const(char) * udev_device_get_sysname(udev_device * udev_device_);
extern (C) udev_device * udev_device_get_parent(udev_device * udev_device_);

package class SerialPortInfoPrivate
{
public:
    static SerialPortInfo[] getAvailablePorts()
    {
        SerialPortInfo[] availablePorts;

        udev * udevHandle = udev_new();
        if (null == udevHandle)
            return availablePorts;
    
        scope(exit)
            udev_unref(udevHandle);
    
        // enumerate all devices with 'tty' subsystem
        udev_enumerate * udevEnumerateHandle = udev_enumerate_new(udevHandle);
        if (null == udevEnumerateHandle)
            return availablePorts;
    
        scope(exit)
            udev_enumerate_unref(udevEnumerateHandle);
    
        int result = udev_enumerate_add_match_subsystem(udevEnumerateHandle, "tty");
    
        result = udev_enumerate_scan_devices(udevEnumerateHandle);
    
        for (udev_list_entry * currentEntry = udev_enumerate_get_list_entry(udevEnumerateHandle);
            null != currentEntry;
            currentEntry = udev_list_entry_get_next(currentEntry))
        {
            const(char) * deviceSystemPath = udev_list_entry_get_name(currentEntry);
            udev_device * device = udev_device_new_from_syspath(udevHandle, deviceSystemPath);
    
            if (null == device)
                continue;
    
            scope(exit)
                udev_device_unref(device);

            // now only devices with parent are supported
            udev_device * parentDevice = udev_device_get_parent(device);
            if (null == parentDevice)
                continue;

            const(char) * deviceNode = udev_device_get_devnode(device);
            const(char) * systemName = udev_device_get_sysname(device);

            auto port = new SerialPortInfo();
            port.mImpl.systemLocation = to!(string)(deviceNode);
            port.mImpl.portName = to!(string)(systemName);

            availablePorts ~= port;
        }

        return availablePorts;
    }

    string portName;
    string systemLocation;
    string description;
    string manufacturer;
    ushort vendorIdentifier;
    ushort productIdentifier;
}
