---
title: Installing app variants on the same device
---

import ImageSpotlight from '~/components/plugins/ImageSpotlight'

When creating [development, preview, and production builds](../eas-json.md#common-use-cases), it's common to want to install one of each build on your device at the same time. This allows you to do development work, preview the next version of your app, and run the production version all on the same device, without needing to uninstall and reinstall the app.

In order to be able to have multiple instances of an app installed on your device, each instance must have a unique Application ID (Android) or Bundle Identifier (iOS).

**If you have a bare project**, you can accomplish this using flavors (Android) and targets (iOS). To configure which flavor is used, use the `gradleCommand` field on your build profile; to configure which target is used, use the `scheme` field for iOS.

**If you have a managed project**, this can be accomplished by using **app.config.js** and environment variables in **eas.json**.

## Example: configuring development and production variants in managed project

Let's say we wanted a development build and production build of our managed Expo project. Your **eas.json** might look like this:

```json
{
  "build": {
    "development": {
      "developmentClient": true
    },
    "production": {}
  }
}
```

And your **app.json** might look like this:

```json
{
  "expo": {
    "name": "MyApp",
    "slug": "my-app",
    "ios": {
      "bundleIdentifier": "com.myapp"
    },
    "android": {
      "package": "com.myapp"
    }
  }
}
```

Let's convert this to **app.config.js** so we can make it more dynamic:

```javascript
export default {
  name: "MyApp",
  slug: "my-app",
  ios: {
    bundleIdentifier: "com.myapp",
  },
  android: {
    package: "com.myapp",
  },
};
```

Now let's switch out the iOS `bundleIdentifier` and Android `package` (which becomes the Application ID) based on the presence of an environment variable in **app.config.js**:

```js
const IS_DEV = process.env.APP_VARIANT === "development";

export default {
  // You can also switch out the app icon and other properties to further
  // differentiate the app on your device.
  name: IS_DEV ? "MyApp (Dev)" : "MyApp",
  slug: "my-app",
  ios: {
    bundleIdentifier: IS_DEV ? "com.myapp.dev" : "com.myapp",
  },
  android: {
    package: IS_DEV ? "com.myapp.dev" : "com.myapp",
  },
};
```

> **Note**: if you are using any libraries that require you to register your application identifier with an external service to use the SDK, such as Google Maps, you will need to have a separate configuration for that API for the iOS Bundle Identifier and Android Package. You can also swap this configuration in using the same approach as above.

To automatically set the `APP_VARIANT` environment variable when running builds with the "development" profile, we can use `env` in **eas.json**:

```json
{
  "build": {
    "development": {
      "developmentClient": true,
      "env": {
        "APP_VARIANT": "development"
      }
    },
    "production": {}
  }
}
```

Now when you run `eas build --profile development`, the environment variable `APP_VARIANT` will be set to `"development"` when evaluating **app.config.js** both locally and on the EAS Build worker. When you start your development server, you will need to run `APP_VARIANT=development expo start` (or the platform equivalent if you use Windows); a shortcut for this could be to add a script to your **package.json** such as `"dev": "APP_VARIANT=development expo start"`.

When you run `eas build --profile production` the `APP_VARIANT` variable environment will not be set, and the build will run as the production variant.

> **Note**: if you use `expo-updates` to publish JavaScript updates to your app, you should be cautious to set the correct environment variables for the app variant that you are publishing for when you run the `expo publish` command. Refer to the EAS Build ["Environment variables and secrets" guide](/build/updates.md) for more information.

## Example: configuring development and production variants in bare project

### Android

Create separate flavor in `./android/app/build.gradle` for every profile you want to build for.

```groovy
android {
    ...
    flavorDimensions "env"
    productFlavors {
        production {
            dimension "env"
            applicationId 'com.myapp'
        }
        development {
            dimension "env"
            applicationId 'com.myapp.dev'
        }
    }
    ...
}
```

> **Note**: `eas-cli` supports only `applicationId` field, if you use `applicationIdSuffix` inside `productFlavors` or `buildTypes` section then this value will not be detected correctly.

Assign android flavors to EAS build profiles by specifying `gradleCommand` in `eas.json`

```json
{
  "build": {
    "development": {
        "android": {
            "gradleCommand": ":app:assembleDevelopmentDebug"
        }
    },
    "production": {
        "android": {
            "gradleCommand": ":app:bundleProductionRelease"
        }
    }
  }
}
```

By default every flavor can be built in the debug and release mode, if you want to restrict that to only specific combinations you can add bellow code in the build.gradle

```groovy
android {
    ...
    variantFilter { variant ->
        def validVariants = [
                ["production", "release"],
                ["development", "debug"],
        ]
        def buildTypeName = variant.buildType*.name
        def flavorName = variant.flavors*.name

        def isValid = validVariants.any { flavorName.contains(it[0]) && buildTypeName.contains(it[1]) }
        if (!isValid) {
            setIgnore(true)
        }
    }
    ...
}
```

The est of the configuration at this point is not specific to EAS, it's the same as it would be for any android project with flavors. There are a few common configurations that you might need to apply in your project
 - to change name of the app built using development profile create `./android/app/src/development/res/value/strings.xml`
    ```xml
    <resources>
        <string name="app_name">MyApp - Dev</string>
    </resources>
    ```
 - to change icon of the app built using development profile create `./android/app/src/development/res/midimap-*` directories with appropriate assets (you can copy it from `./android/app/src/main/res` and replace icon files).
 - to specify `google-services.json` for specific flavor put it in `./android/app/src/{flavor}/google-services.json`
 - to configure sentry add `project.ext.sentryCli = [ flavorAware: true ]` in the `./android/app/build.gradle` and name your properties file `./android/sentry-{flavor}-{buildType}.properties` (e.g. `./android/sentry-production-release.properties`)

### iOS

Assign separate scheme to every build profile in `eas.json`:

```json
{
  "build": {
    "development": {
        "ios": {
            "buildConfiguration": "Debug",
            "scheme": "myapp"
        }
    },
    "production": {
        "ios": {
            "buildConfiguration": "Release",
            "scheme": "myapp-dev"
        }
    }
  }
}
```

Your existing `Podfile` should have target defined like this:

```ruby
target 'myapp' do
    ...
end
```

Replace it with abstract target, where common configuration can be copied from old target.

```ruby
abstract_target 'common' do
  # put common target configuration here

  target 'myapp' do
  end

  target 'myapp-dev' do
  end
end
```

Open project in the Xcode -> Click on the project name in navigation panel -> Right click on the existing target -> "Duplicate":

<ImageSpotlight alt="Duplicate Xcode target" src="/static/images/eas-build/variants/1-ios-duplicate-target.png" style={{maxWidth: 720}} />

Rename target to something more meaningful e.g `myapp copy` -> `myapp-dev`.

Configure scheme for new target:
- Go to `Product` -> `Scheme` -> `Manage schemes`
- Find scheme `myapp copy` on the list
- Change scheme name `myapp copy` -> `myapp-dev`
- By default new scheme should be marked as shared, but Xcode does not create `.xcscheme` files. To fix that uncheck "Shared" checkbox and check it again, after that new `.xcscheme` file should show up in `ios/myapp.xcodeproj/xcshareddata/xcschemes` directory.

<ImageSpotlight alt="Xcode scheme list" src="/static/images/eas-build/variants/2-scheme-list.png" style={{maxWidth: 720}} />

By default newly created target has separate Info.plist file (in our case it's `./ios/myapp copy-Info.plist`), to simplify your project we recommend to use the same file for all targets:
- Delete `./ios/myapp copy-Info.plist`
- Click on the new target.
- Go to `Build Settings` tab.
- Find `Packaging` section.
- Change `Info.plist` value `myapp copy-Info.plist` -> `myapp/Info.plist`.
- Change `Product Bundle Identifier`.

<ImageSpotlight alt="Xcode build settings" src="/static/images/eas-build/variants/3-target-build-settings.png" style={{maxWidth: 720}} />

To change display name:
- Open `Info.plist` and add key `Bundle display name` with value `$(DISPLAY_NAME)`.
- Open `Build Settings` for both targets and find `User-Defined` section.
- Add key `DISIPLAY_NAME` with the name you want to use for that target.

To change app icon:
- Create new image set(you can create it from existing image set for current icon, usually named `AppIcon`)
- Open `Build Settings` for a target that you want to change icon.
- Find `Asset Catalog Compiler - Options` section.
- Change `Primary App Icon Set Name` to the name of the new image set.
