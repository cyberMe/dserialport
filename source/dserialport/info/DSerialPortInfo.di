// D import file generated from 'DSerialPortInfo.d'
module dserialport.info;

class DSerialPortInfo
{
    string portName();
    string systemLocation();
    string description();
    string manufacturer();
    ushort vendorIdentifier();
    ushort productIdentifier();
    private Object mImpl;
}
