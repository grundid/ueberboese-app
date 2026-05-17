# Contributing

Contributions are more than welcome :)

## Code contributions

Before opening a pull request, please open an issue explaining the changes you want to make.

## Local set up
This project uses flutter to create an Android app, a Mac app and a Linux app and potentially in the future also an iOS app.

### Android
See https://docs.flutter.dev/platform-integration/android/setup

Start an emulator by name
```shell
flutter emulators --launch Pixel_9
```

To start the app locally run
```shell
flutter run
```

Hot reload: press `r` in the console were you started flutter

## Before you commit

Before you commit your changes always make sure to run:
```shell
flutter test
flutter analyze
```
