module dserialport.info;

version(OS_with_udev)
{
    import dserialport.infoprivate_udev;
}

class SerialPortInfo
{
public:
    string portName() const @property
    {
        return mImpl.portName;
    }

    string systemLocation() const @property
    {
        return mImpl.systemLocation;
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

private:
    this()
    {
        mImpl = new SerialPortInfoPrivate();
    }

    SerialPortInfoPrivate mImpl;
}
