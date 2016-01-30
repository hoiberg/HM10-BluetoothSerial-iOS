# HM10 Bluetooth Serial iOS
This is a simple iOS 9 app that lets you communicate with a HM10 (or HM11) Bluetooth UART module. This way you can communicate from your iPhone/iPad with e.g. an Arduino.

It is available for free on the [App Store](https://itunes.apple.com/us/app/hm10-bluetooth-serial/id1030454675?ls=1&mt=8).



Note 1: (IMPORTANT) In the preferences (within the app), select 'Write with response' if you have a fake HM10, or select 'Write without response' if you have a legit HM10 or HM11. If you don't select the right option, the app won't be able to write data to the bluetooth module.

Note 2: The helper class for the bluetooth communication can also be found [here](https://github.com/hoiberg/SwiftBluetoothSerial).
