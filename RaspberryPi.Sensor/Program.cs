namespace RaspberryPi.Sensor
{
    using System.Diagnostics;

    using RaspberryPiDotNet;
    using RaspberryPiDotNet.MicroLiquidCrystal;

    public class Program
    {
        public void Main(string[] args)
        {
            Debug.WriteLine("RaspberryPi.Sensor Starting...");
            RaspPiGPIOMemLcdTransferProvider lcdProvider = new RaspPiGPIOMemLcdTransferProvider(
                GPIOPins.Pin_P1_21,
                GPIOPins.Pin_P1_18,
                GPIOPins.Pin_P1_11,
                GPIOPins.Pin_P1_13,
                GPIOPins.Pin_P1_15,
                GPIOPins.Pin_P1_19);


            //Lcd lcd = new Lcd(lcdProvider);
            //lcd.Begin(16, 2);
            //lcd.Clear();
            //lcd.SetCursorPosition(0, 0);
            //lcd.Write("Hello World!"); Debug.WriteLine("RaspberryPi.Sensor Exiting...");
        }
    }
}
