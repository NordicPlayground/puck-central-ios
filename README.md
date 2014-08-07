Puck Central iOS
================

An iPhone app for managing [Pucks](http://nordicsemiconductor.github.io/puck/).

## Installing

You need to have [cocoapods](http://cocoapods.org) installed.

Clone this project, and run `pod install`.

Open the PuckCentral.xcworkspace file in XCode.

## Adding Actuators

It is easy to extend the functionality of this app by adding a new actuator.

Create a new Actuator class which should implement the NSPActuator protocol defined in NSPActuator.h.

You need to implement the `index` method, assigning a unique number to your actuator, and the `name` method.

You also need to implement the `optionsForm`, which should return a XLFormDescriptor (check out [XLForm's documentation](https://github.com/xmartlabs/XLForm)).

In addition, when a trigger is executed in the app, your `actuate` method will be called. This is where the bulk of your code should be.

Also remember to add the actuator to the list in the NSPAtuatorController class, so it will show up in the list of available actuators.

Check out the code for the included actuators for some examples of different uses.
