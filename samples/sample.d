module sample;

import std.stdio;
import std.array : empty;

import dserialport.portinfo;

void main()
{
    const availablePorts = SerialPortInfo.availablePorts;
    if (availablePorts.empty)
    {
        writeln("No available ports");
        return;
    }

    foreach(port; availablePorts)
    {
        writeln("portName          = ", port.portName);
        writeln("systemLocation    = ", port.systemLocation);
        writeln("description       = ", port.description);
        writeln("manufacturer      = ", port.manufacturer);
        writeln("vendorIdentifier  = ", port.vendorIdentifier);
        writeln("productIdentifier = ", port.productIdentifier);
        writeln;
    }
}
