module dserialport.portinfo;

version(OS_with_udev)
{
    import dserialport.infoprivate_udev;
}
else version(Windows)
{
    import dserialport.infoprivate_windows;
}
else
{
    static assert(false, "Unsupported OS");
}

public class SerialPortInfo
{
public:
    static SerialPortInfo[] availablePorts() @property
    {
        return SerialPortInfoPrivate.availablePorts;
    }

    string portName() const @property
    {
        return mImpl.portName;
    }

    string systemLocation() const @property
    {
        return mImpl.device;
    }

    string description() const @property
    {
        return mImpl.description;
    }

    string manufacturer() const @property
    {
        return mImpl.manufacturer;
    }

    ushort vendorIdentifier() const @property
    {
        return mImpl.vendorIdentifier;
    }

    ushort productIdentifier() const @property
    {
        return mImpl.productIdentifier;
    }

    package this()
    {
        mImpl = new SerialPortInfoPrivate();
    }

    package SerialPortInfoPrivate mImpl;
}
