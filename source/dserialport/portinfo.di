// D import file generated from 'portinfo.d'
module dserialport.portinfo;
class SerialPortInfo
{
	public 
	{
		static @property SerialPortInfo[] availablePorts();

		const @property string portName();
		const @property string systemLocation();
		const @property string description();
		const @property string manufacturer();
		const @property ushort vendorIdentifier();
		const @property ushort productIdentifier();
	}

	private
	{
		this();
		Object mImpl;
	}
}
