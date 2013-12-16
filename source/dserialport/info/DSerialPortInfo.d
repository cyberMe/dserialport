module dserialport.info;

version(OS_with_udev)
{
	import dserialport.infoprivate_udev;
}

class DSerialPortInfo
{
	void swap(DSerialPortInfo other)
	{
		DSerialPortInfoPrivate thisImpl = mImpl;
		mImpl = other.mImpl;
		other.mImpl = thisImpl;
	}

	private DSerialPortInfoPrivate mImpl;
}
