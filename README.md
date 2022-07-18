# HM10 Bluetooth Serial iOS
This is a simple iOS 9/10 app that lets you communicate with a HM10 (or HM11 or similar) Bluetooth UART module. This way you can communicate from your iPhone/iPad with e.g. an Arduino.

~~It is available for free on the [App Store](https://itunes.apple.com/us/app/hm10-bluetooth-serial/id1030454675?ls=1&mt=8).~~

The helper class for the bluetooth communication can also be found [here](https://github.com/hoiberg/SwiftBluetoothSerial).

**Update:** It is again on the App Store, made available by someone else: [link](https://apps.apple.com/nl/app/ble-serial-tiny/id1607862132). He also re-uploaded the pro version: [link](https://apps.apple.com/nl/app/bleserial-hm-10/id1602239700).

## Pro Version
~~A Pro version is also available on the App Store --> [HM10 Bluetooth Serial Pro](https://itunes.apple.com/us/app/hm10-bluetooth-serial-pro/id1221924372?ls=1&mt=8).~~

The source code of the Pro version is published [here](https://github.com/hoiberg/BluetoothSerialPro). The code has not been updated in a long time, so it might not readily compile.

It has a tonne more features to help debugging HM10 applications, and also supports creating custom buttons to send pre-set messages.

## Notes
~~Note: (IMPORTANT) In the preferences (within the app), select 'Write with response' if you have a fake HM10, or select 'Write without response' if you have a legit HM10 or HM11. If you don't select the right option, the app won't be able to write data to the bluetooth module.~~ As of version 1.1.2 this is no longer needed. Writetype is now detected automatically!
