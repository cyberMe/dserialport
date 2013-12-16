module dserialport.info;

version(OS_with_udev)
{
    import dserialport.infoprivate_udev;
}

class DSerialPortInfo
{
    string portName()
    {
        return mImpl ? mImpl.portName : null;
    }

    string systemLocation()
    {
        return mImpl ? mImpl.systemLocation : null;
    }

    string description()
    {
        return mImpl ? mImpl.description : null;
    }

    string manufacturer()
    {
        return mImpl ? mImpl.manufacturer : null;
    }

    ushort vendorIdentifier()
    {
        return mImpl ? mImpl.vendorIdentifier : 0;
    }

    ushort productIdentifier()
    {
        return mImpl ? mImpl.productIdentifier : 0;
    }

    private DSerialPortInfoPrivate mImpl;
}
