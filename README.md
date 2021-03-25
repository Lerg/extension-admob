# Admob Extension for Defold

The Admob extension lets you display banner, interstitial and rewarded ads.

# API Overview

## Functions

- [`admob.enable_debug()`](#function_enable_debug)
- [`admob.init()`](#function_init)
- [`admob.load()`](#function_load)
- [`admob.is_loaded()`](#function_show)
- [`admob.hide_banner()`](#function_hide_banner)

## Events

- [`admob`](#event_admob)

# Project Settings

Open `game.project` and a new entry to the `dependencies` property:

- `https://github.com/Lerg/extension-admob/archive/master.zip`


Then select `Project -> Fetch Libraries` to download the extension in your project.

You need to set the AdMob App Id for your iOS and/or Android app in `game.project`. To do so open your `game.project` and add these lines:
```
[admob]
ios_app_id = ca-app-pub-***~***
android_app_id = ca-app-pub-***~***
```

Replace `ca-app-pub-***~***` with your app ids. It can now be viewed or changed in the normal view of the `game.project` file.

You need Defold version 1.2.165+

# Functions

## <a name="function_enable_debug">`admob.enable_debug()`</a>

Enables additional output for debugging purposes.

---

## <a name="function_init">`admob.init(params)`</a>

Initializes the extension. This function has to be called first, before using any other methods of the extension.

### params <sub>required</sub>
Table. Contains parameters for the call &mdash; see the next section for details.

## Parameter Reference

The `params` table includes parameters for the call.

### test <sub>optional</sub>
Boolean. If `true`, the test ads will be served. ALWAYS use test ads during the development.

### listener <sub>optional</sub>
Function. The callback function which receives all [admob](#event_admob) events.

## Example

```lua
-- Banner id for iOS and Android.
local banner_id = {
	['iPhone OS'] = 'ca-app-pub-3940256099942544/2934735716',
	Android = 'ca-app-pub-3940256099942544/6300978111'
}
local sysinfo = sys.get_sys_info()

local function listener(event)
	print('admob event type', event.type)
	print('admob event phase', event.phase)
	if event.phase == 'init' then -- Admob has been initialized, now it's safe to load a banner.
		admob.load{
			type = 'banner',
			id = banner_id[sysinfo.system_name],
			size = 'smart',
			position = 'bottom',
			keywords = {'puzzle', 'game'}
		}
	end
end

-- Init Admob.
admob.init{
	test = true, -- ALWAYS use test ads, only disable when submitting to the stores.
	listener = listener
}
```

---

## <a name="function_load">`admob.load(params)`</a>

Loads a specified ad unit. It also allows you to specify additional targeting parameters. To understand all of them please read targeting guides for [iOS](https://developers.google.com/admob/ios/targeting) and [Android](https://developers.google.com/admob/android/targeting).

### params <sub>required</sub>
Table. Contains parameters for the call &mdash; see the next section for details.

## Parameter Reference

The `params` table includes parameters for the call.

### type <sub>optional</sub>
String. Type of the ad unit: `'banner'`, `'interstitial'` (default) or `'rewarded'`. 

### id <sub>required</sub>
String. Ad unit id, e.g. `'ca-app-pub-3940256099942544/1033173712'`.

### immersive <sub>optional</sub>
Boolean. If `true`, the video ad will hide onscreen navigation bar on Android.

### user_id <sub>optional</sub>
String. Sets the user ID to be used in server-to-server reward callbacks.

### keywords <sub>optional</sub>
Array. A set of string keywords to be used when an ad is being chosed. E.g. `{'action', 'game'}`. It may increase your revenue by displaying relevant ads.

### gender <sub>optional</sub>
String. User gender: `'male'` or `'female'`.

### is_designed_for_families <sub>optional</sub>
Boolean. Set it to `true` if your app is accepted as "Designed For Families". Android only.

### tag_for_child_directed_treatment <sub>optional</sub>
Boolean. For purposes of the [Children's Online Privacy Protection Act (COPPA)](http://business.ftc.gov/privacy-and-security/children%27s-privacy), there is a setting called "tag for child-directed treatment". By setting this to `true`, you certify that this notification is accurate and you are authorized to act on behalf of the owner of the app. You understand that abuse of this setting may result in termination of your Google account.

### tag_for_under_age_of_consent <sub>optional</sub>
Boolean. See [Users under the age of consent](https://developers.google.com/admob/unity/targeting#users_under_the_age_of_consent), default is `false`. iOS only for now.

### non_personalized <sub>optional</sub>
Boolean. Set it to `true` if you would like to request non-personalized ads. Under the Google EU User Consent Policy, you must make certain disclosures to your users in the European Economic Area (EEA) and obtain their consent to show personalized ads. This policy reflects the requirements of the EU ePrivacy Directive and the General Data Protection Regulation (GDPR).

### restricted_data_processing <sub>optional</sub>
Boolean. Set it to `true` if you would like to [restrict data processing](https://privacy.google.com/businesses/rdp/) for compliance with the [California Consumer Privacy Act (CCPA)](https://support.google.com/admob/answer/9561022).

### max_ad_content_rating <sub>optional</sub>
String. AdMob returns ads with a content rating at or below the specified level. Possible values are: `'G'`, `'PG'`, `'T'`, `'MA'`.

### birthday <sub>optional</sub>
Table. A table with three numeric components of a date: `year`, `month` and `day`. All fields are required. E.g. `{year = 1970, month = 1, day = 1}`.

### location <sub>optional</sub>
Table. A table with three numeric components of a location: `latitude`, `longitude` and `accuracy`. All fields are required. E.g. `{latitude = 59.3385206, longitude = 18.0303522, accuracy = 20}`.

### content_url <sub>optional</sub>
String. When requesting an ad, apps may pass the URL of the content they are serving. E.g. a blog post URL or a news URL that is being shown in your app.

### size <sub>optional</sub>
String. Banner size to load: `'banner'` (default), `'large'`, `'medium'`, `'full'`, `'leaderboard'`, `'smart'`, `'smart_portrait'` (iOS only), `'smart_landscape'` (iOS only).

See "Banner sizes" section on [Admob Android Banner](https://developers.google.com/admob/android/banner) and [Admob iOS Banner](https://developers.google.com/admob/ios/banner) pages for more details.

If a selected banner size can't fit on screen, it won't be displayed. A good option is to use the `'smart'` banner size, in this case the actual size is adapted to the screen width. 

### position <sub>optional</sub>
String. Banner position on screen: `'top'` or `'bottom'` (default).

## Example

```lua
-- Load rewarded video ad.
admob.load{
	type = 'rewarded',
	id = 'ca-app-pub-3940256099942544/5224354917',
	immersive = true,
	keywords = {'action', 'game'}
}

-- Load banner ad.
admob.load{
	type = 'banner',
	id = 'ca-app-pub-3940256099942544/6300978111',
	size = 'smart_portrait',
	position = 'top'
}
```

---

## <a name="function_is_loaded">`admob.is_loaded(type)`</a>

Returns `true` if the specified ad type has been loaded.

### type <sub>required</sub>
String. Which adverstiment type to check: `'banner'`, `'interstitial'` or `'rewarded'`.

## Example
```lua
print('Is an interstitial ad loaded? ' .. (admob.is_loaded('interstitial') and 'Yes' or 'No'))
```

---

## <a name="function_show">`admob.show(type)`</a>

Displays a loaded ads. Use [admob.load()](#function_load) to load an ad before calling this method.

You can check if an ad has been loaded with [admob.is_loaded()](#function_is_loaded) method or you can listen to the [admob](#event_admob) event with a loaded phase:
```lua
-- Inside admob listener.
if event.type == 'interstitial' and event.phase == 'loaded' then
	admob.show('interstitial')
end
```

Banners don't need this method because they are displayed automatically when loaded.

### type <sub>required</sub>
String. Which adverstiment type to display: `'interstitial'` or `'rewarded'`.

## Example

```lua
admob.show('rewarded')
```

---

## <a name="function_hide_banner">`admob.hide_banner()`</a>

Removes a loaded banner from the screen.

---

# Events

## <a name="event_admob">`admob`</a>

Occurs when something has happened with ad units or when the extension has been initialized.

## Properties Overview

#### [event.name](#event_admob_name)

#### [event.is_error](#event_admob_is_error)

#### [event.error_code](#event_admob_error_code)

#### [event.error_message](#event_admob_error_message)

#### [event.phase](#event_admob_phase)

#### [event.type](#event_admob_type)

## Properties

### <a name="event_admob_name">`event.name`</a>

The string `'admob'`.

---

### <a name="event_admob_is_error">`event.is_error`</a>

Boolean. `true` in case of an error.

---

### <a name="event_admob_error_code">`event.error_code`</a>

Number. Unique error code, present when [event.is_error](#event_admob_is_error) is `true`, `nil` otherwise.

---

### <a name="event_admob_error_message">`event.error_message`</a>

String. Description of an error when [event.is_error](#event_admob_is_error) is `true`, `nil` otherwise.

---

### <a name="event_admob_phase">`event.phase`</a>

String. Phase of an ad unit lifetime.

Possible values depend on the ad type [event.type](#event_admob_type). 

### banner

* `'closed'` - banner ad is closed.
* `'failed_to_load'` - banner ad request failed, `is_error` is `true`.
* `'left_application'` - banner ad leaves the application (e.g., to go to the browser).
* `'loaded'` - banner ad is loaded.
* `'opened'` - banner ad is displayed.

### interstitial

* `'closed'` - interstitial ad is closed.
* `'failed_to_load'` - interstitial ad request failed, `is_error` is `true`.
* `'left_application'` - interstitial ad leaves the application (e.g., to go to the browser).
* `'loaded'` - interstitial ad is loaded.
* `'opened'` - interstitial ad is displayed.

### rewarded

* `'closed'` - video ad is closed.
* `'failed_to_load'` - video ad request failed, `is_error` is `true`.
* `'left_application'` - video ad leaves the application (e.g., to go to the browser).
* `'loaded'` - video ad is loaded.
* `'opened'` - video ad opens a overlay that covers the screen.
* `'rewarded'` - video ad has triggered a reward.
* `'started'` - video ad starts to play.

---

### <a name="event_admob_type">`event.type`</a>

String. indicates the ad unit type: `'banner'`, `'interstitial'` or `'rewarded'`. Or extension initialization - `'init'`.

---

# Test Ads

ALWAYS use test ads during the development. Only switch to the real ads for submitting to the stores. To enable test ads use `test = true` option in the [admob.init()](#function_init) call.

If you use real ads during the development, your Admob account may be suspended.

# Demo

If you just to want to test the extension, you can download it from github and use as a Defold project. It will function as a demo. You don't need an Admob account for the demo.

# Usage

Use [admob.init()](#function_init) to initialize it when your app starts. A good place for that would be the `init()` function of some root game object. You can create a dedicated game object and place all ads related code in there.

Once the init process if finished (you can listen for the `'init'` phase/type in the [admob](#event_admob) event or you can just wait), you can start loading ads. It's good to preload ads before you actually need to display it. Use [admob.load()](#function_load) to load and [admob.show()](#function_show) to show the ads.

When an ad has been closed (phase equals `'closed'`) you can preload next ad.

Banners are displayed automatically when loaded, no need to call [admob.show()](#function_show) for them, however to remove a banner, you would need to use [admob.hide_banner()](#function_hide_banner).

--

# Patreon

If you like this extension please consider supporting me on Patreon https://patreon.com/Lerg
