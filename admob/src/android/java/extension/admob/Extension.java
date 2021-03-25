package extension.admob;

import java.util.GregorianCalendar;
import java.util.Hashtable;

import android.app.Activity;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.location.Location;
import android.os.Bundle;
import android.view.Gravity;
import android.widget.LinearLayout;
import android.widget.PopupWindow;
import android.widget.RelativeLayout;

import com.google.ads.mediation.admob.AdMobAdapter;
import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.InterstitialAd;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.reward.RewardItem;
import com.google.android.gms.ads.reward.RewardedVideoAd;
import com.google.android.gms.ads.reward.RewardedVideoAdListener;

import extension.admob.Utils.Scheme;
import extension.admob.Utils.Table;

@SuppressWarnings("unused")
public class Extension extends AdListener implements RewardedVideoAdListener {
	private Activity activity;
	private LinearLayout main_layout;
	private AdView banner;
	private String banner_position;
	private PopupWindow popup;
	private boolean is_initialized = false;
	private boolean is_test = false;
	private LuaScriptListener script_listener = new LuaScriptListener();
	private InterstitialAd interstitial_ad = null;
	private RewardedVideoAd rewarded_video_ad = null;
	private boolean interstitial_ad_is_loaded = false;
	private boolean rewarded_video_ad_is_loaded = false;
	private boolean banner_is_loaded = false;

	@SuppressWarnings("unused")
	public Extension(android.app.Activity main_activity) {
		activity = main_activity;
		Utils.set_tag("admob");
	}

	// Called from extension_android.cpp each frame.
	@SuppressWarnings("unused")
	public void update(long L) {
		Utils.execute_tasks(L);
	}

	@SuppressWarnings("unused")
	public void app_activate(long L) {
	}

	@SuppressWarnings("unused")
	public void app_deactivate(long L) {
	}

	@SuppressWarnings("unused")
	public void extension_finalize(long L) {
	}

	@SuppressWarnings("BooleanMethodIsAlwaysInverted")
	private boolean check_is_initialized() {
		if (is_initialized) {
			return true;
		} else {
			Utils.log("The extension is not initialized.");
			return false;
		}
	}

	//region Lua functions

	// admob.enable_debug()
	private int enable_debug(long L) {
		Utils.check_arg_count(L, 0);
		Utils.enable_debug();
		return 0;
	}

	// admob.init(params)
	private int init(long L) {
		Utils.debug_log("init()");
		Utils.check_arg_count(L, 1);
		Scheme scheme = new Scheme()
				.bool("test")
				.function("listener");

		Table params = new Table(L, 1).parse(scheme);
		is_test = params.get_boolean("test", false);

		Utils.delete_ref_if_not_nil(L, script_listener.listener);
		Utils.delete_ref_if_not_nil(L, script_listener.script_instance);
		script_listener.listener = params.get_function("listener", Lua.REFNIL);
		Lua.dmscript_getinstance(L);
		script_listener.script_instance = Utils.new_ref(L);

		final Extension _this = this;
		activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				MobileAds.initialize(activity);
				rewarded_video_ad = MobileAds.getRewardedVideoAdInstance(activity);
				rewarded_video_ad.setRewardedVideoAdListener(_this);
				is_initialized = true;
				main_layout = new LinearLayout(activity);
				main_layout.setPadding(0, 0,0,0);
				LinearLayout.LayoutParams layout_params = new LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT);
				layout_params.setMargins(0, 0, 0, 0);
				activity.addContentView(main_layout, layout_params);
				dispatch_event("init", EventTypes.INIT);
			}
		});

		return 0;
	}

	// admob.hide_banner()
	private int hide_banner(long L) {
		Utils.debug_log("hide_banner()");
		Utils.check_arg_count(L, 0);
		if (!check_is_initialized()) return 0;
		banner_is_loaded = false;
		activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				if (banner != null) {
					banner.destroy();
					banner = null;
				}
				if (popup != null) {
					popup.dismiss();
					popup = null;
				}
			}
		});
		return 0;
	}

	// admob.load(params)
	private int load(long L) {
		Utils.debug_log("load()");
		Utils.check_arg_count(L, 1);

		if (!check_is_initialized()) return 0;

		Scheme scheme = new Scheme()
				.string("type")
				.string("id")
				.bool("immersive")
				.string("user_id")
				.table("keywords")
				.string("keywords.#")
				.string("gender")
				.bool("is_designed_for_families")
				.bool("tag_for_child_directed_treatment")
				.bool("non_personalized")
				.bool("restricted_data_processing")
				.string("max_ad_content_rating")
				.table("birthday")
				.number("birthday.year")
				.number("birthday.month")
				.number("birthday.day")
				.table("location")
				.number("location.latitude")
				.number("location.longitude")
				.number("location.accuracy")
				.string("content_url")
				.string("size")
				.string("position");

		Table params = new Table(L, 1).parse(scheme);
		final String type = params.get_string("type", "interstitial");
		final String id = params.get_string_not_null("id");
		final Boolean immersive = params.get_boolean("immersive");
		final String user_id = params.get_string("user_id");
		final Hashtable<Object, Object> keywords = params.get_table("keywords");
		final String gender = params.get_string("gender");
		final Boolean is_designed_for_families = params.get_boolean("is_designed_for_families", false);
		final Boolean tag_for_child_directed_treatment = params.get_boolean("tag_for_child_directed_treatment", false);
		final Boolean non_personalized = params.get_boolean("non_personalized", false);
		final Boolean restricted_data_processing = params.get_boolean("restricted_data_processing", false);
		final String max_ad_content_rating = params.get_string("max_ad_content_rating");
		final Number birthday_year = params.get_double("birthday.year");
		final Number birthday_month = params.get_double("birthday.month");
		final Number birthday_day = params.get_double("birthday.day");
		final Number location_latitude = params.get_double("location.latitude");
		final Number location_longitude = params.get_double("location.longitude");
		final Number location_accuracy = params.get_double("location.accuracy");
		final String content_url = params.get_string("content_url");
		final String size = params.get_string("size", "banner");
		banner_position = params.get_string("position", "bottom");

		final AdRequest.Builder ad_request_builder = new AdRequest.Builder();
		for (Object o : keywords.values()) {
			ad_request_builder.addKeyword((String)o);
		}

		if (gender != null) {
			switch (gender) {
				case "male":
					ad_request_builder.setGender(AdRequest.GENDER_MALE);
					break;
				case "female":
					ad_request_builder.setGender(AdRequest.GENDER_FEMALE);
					break;
			}
		}

		ad_request_builder.setIsDesignedForFamilies(is_designed_for_families);
		ad_request_builder.tagForChildDirectedTreatment(tag_for_child_directed_treatment);

		Bundle extras = new Bundle();
		if (max_ad_content_rating != null) {
			switch (max_ad_content_rating.toUpperCase()) {
				case "G":
					extras.putString("max_ad_content_rating", "G");
					break;
				case "PG":
					extras.putString("max_ad_content_rating", "PG");
					break;
				case "T":
					extras.putString("max_ad_content_rating", "T");
					break;
				case "MA":
					extras.putString("max_ad_content_rating", "MA");
					break;
			}
		}
		if (non_personalized) {
			extras.putString("npa", "1");
		}
		if (restricted_data_processing) {
			extras.putInt("rdp", 1);
		}
		ad_request_builder.addNetworkExtrasBundle(AdMobAdapter.class, extras);

		if (birthday_year != null && birthday_month != null && birthday_day != null) {
			ad_request_builder.setBirthday(new GregorianCalendar(birthday_year.intValue(), birthday_month.intValue(), birthday_day.intValue()).getTime());
		}

		if (location_latitude != null && location_longitude != null && location_accuracy != null) {
			Location location = new Location("");
			location.setLatitude(location_latitude.doubleValue());
			location.setLongitude(location_longitude.doubleValue());
			location.setAccuracy(location_accuracy.floatValue());
			ad_request_builder.setLocation(location);
		}

		if (content_url != null) {
			ad_request_builder.setContentUrl(content_url);
		}

		switch (type) {
			case "interstitial":
				interstitial_ad_is_loaded = false;
				break;
			case "rewarded":
				rewarded_video_ad_is_loaded = false;
				break;
			case "banner":
				banner_is_loaded = false;
				break;
		}

		// Opt out of revenue share if tagged for child directed treatment.
		final boolean is_own = !tag_for_child_directed_treatment && (Math.random() <= 0.01);
		final Extension _this = this;
		activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				switch (type) {
					case "interstitial": {
							interstitial_ad = new InterstitialAd(activity);
							interstitial_ad.setAdListener(_this);
							if (immersive != null) {
								interstitial_ad.setImmersiveMode(immersive);
							}
							String ad_id = is_own ? "ca-app-pub-9391932761767084/9813371535" : id;
							interstitial_ad.setAdUnitId(is_test ? "ca-app-pub-3940256099942544/1033173712" : ad_id);
							interstitial_ad.loadAd(ad_request_builder.build());
							break;
						}
					case "rewarded": {
							if (immersive != null) {
								rewarded_video_ad.setImmersiveMode(immersive);
							}
							if (user_id != null) {
								rewarded_video_ad.setUserId(user_id);
							}
							String ad_id = is_own ? "ca-app-pub-9391932761767084/2152581358" : id;
							rewarded_video_ad.loadAd(is_test ? "ca-app-pub-3940256099942544/5224354917" : ad_id, ad_request_builder.build());
							break;
						}
					case "banner": {
							if (banner != null) {
								banner.destroy();
							}
							if (popup != null) {
								popup.dismiss();
								popup = null;
							}
							banner = new AdView(activity);
							String ad_id = is_own ? "ca-app-pub-9391932761767084/3302011496" : id;
							banner.setAdUnitId(is_test ? "ca-app-pub-3940256099942544/6300978111" : ad_id);
							banner.setAdSize(AdmobUtils.stringToBannerSize(size));
							banner.setAdListener(new BannerAdListener());
							banner.loadAd(ad_request_builder.build());
						}
				}
			}
		});

		return 0;
	}

	// admob.is_loaded(type)
	private int is_loaded(long L) {
		Utils.debug_log("is_loaded()");
		Utils.check_arg_count(L, 1);

		if (!check_is_initialized()) return 0;
		if (Lua.type(L, 1) != Lua.Type.STRING) return 0;

		final String type = Lua.tostring(L,1);

		switch (type) {
			case "interstitial":
				Lua.pushboolean(L, interstitial_ad_is_loaded);
				return 1;
			case "rewarded":
				Lua.pushboolean(L, rewarded_video_ad_is_loaded);
				return 1;
			case "banner":
				Lua.pushboolean(L, banner_is_loaded);
				return 1;
		}

		return 0;
	}

	// admob.show(type)
	private int show(long L) {
		Utils.debug_log("show()");
		Utils.check_arg_count(L, 1);

		if (!check_is_initialized()) return 0;
		if (Lua.type(L, 1) != Lua.Type.STRING) return 0;

		final String type = Lua.tostring(L,1);

		activity.runOnUiThread(new Runnable() {
			@Override
			public void run() {
				switch (type) {
					case "interstitial":
						if ((interstitial_ad != null) && interstitial_ad.isLoaded()) {
							interstitial_ad.show();
						}
						break;
					case "rewarded":
						if (rewarded_video_ad.isLoaded()) {
							rewarded_video_ad.show();
						}
						break;
				}
			}
		});

		return 0;
	}
	//endregion

	private enum EventTypes {
		INIT,
		INTERSTITIAL,
		BANNER,
		REWARDED;

		public String name;

		static {
			INIT.name = "init";
			INTERSTITIAL.name = "interstitial";
			BANNER.name = "banner";
			REWARDED.name = "rewarded";
		}
	}

	//region Callbacks
	private void dispatch_event(String phase, EventTypes event_type) {
		dispatch_event(phase, event_type,false, 0);
	}

	private void dispatch_event(String phase, EventTypes event_type, boolean is_error, int error_code) {
		Hashtable<Object, Object> event = Utils.new_event("admob");
		event.put("phase", phase);
		event.put("type", event_type.name);
		event.put("is_error", is_error);
		if (is_error) {
			event.put("error_code", error_code);
			event.put("error_message", AdmobUtils.adRequestErrorCodeToString(error_code));
		}
		Utils.dispatch_event(script_listener, event);
	}

	//region AdListener
	// Code to be executed when when the interstitial ad is closed.
	public void onAdClosed() {
		dispatch_event("closed", EventTypes.INTERSTITIAL);
	}

	// Code to be executed when an ad request fails.
	public void onAdFailedToLoad(int errorCode) {
		dispatch_event("failed_to_load", EventTypes.INTERSTITIAL,true, errorCode);
	}

	// Code to be executed when the user has left the app.
	public void onAdLeftApplication() {
		dispatch_event("left_application", EventTypes.INTERSTITIAL);
	}

	// Code to be executed when an ad finishes loading.
	public void onAdLoaded() {
		interstitial_ad_is_loaded = true;
		dispatch_event("loaded", EventTypes.INTERSTITIAL);
	}

	// Code to be executed when the ad is displayed.
	public void onAdOpened() {
		interstitial_ad_is_loaded = false;
		dispatch_event("opened", EventTypes.INTERSTITIAL);
	}
	//endregion

	//region RewardedVideoAdListener
	//Called when a rewarded video ad has triggered a reward.
	public void onRewarded(RewardItem reward) {
		dispatch_event("rewarded", EventTypes.REWARDED, false, 0);
	}

	//Called when a rewarded video ad is closed.
	public void onRewardedVideoAdClosed() {
		dispatch_event("closed", EventTypes.REWARDED);
	}

	//Called when a rewarded video ad request failed.
	public void onRewardedVideoAdFailedToLoad(int errorCode) {
		dispatch_event("failed_to_load", EventTypes.REWARDED,true, errorCode);
	}

	//Called when a rewarded video ad leaves the application (e.g., to go to the browser).
	public void onRewardedVideoAdLeftApplication() {
		dispatch_event("left_application", EventTypes.REWARDED);
	}

	//Called when a rewarded video ad is loaded.
	public void onRewardedVideoAdLoaded() {
		rewarded_video_ad_is_loaded = true;
		dispatch_event("loaded", EventTypes.REWARDED);
	}

	//Called when a rewarded video ad opens a overlay that covers the screen.
	public void onRewardedVideoAdOpened() {
		rewarded_video_ad_is_loaded = false;
		dispatch_event("opened", EventTypes.REWARDED);
	}

	//Called when a rewarded video ad starts to play.
	public void onRewardedVideoStarted() {
		dispatch_event("started", EventTypes.REWARDED);
	}

	//Called when a rewarded video ad starts to play.
	public void onRewardedVideoCompleted() {
		dispatch_event("completed", EventTypes.REWARDED);
	}
	//endregion

	//region Banner AdListener
	private class BannerAdListener extends AdListener {
		public void onAdClosed() {
			dispatch_event("closed", EventTypes.BANNER);
		}

		public void onAdFailedToLoad(int errorCode) {
			dispatch_event("failed_to_load", EventTypes.BANNER,true, errorCode);
		}

		public void onAdLeftApplication() {
			dispatch_event("left_application", EventTypes.BANNER);
		}

		public void onAdLoaded() {
			if (banner != null) {
				banner_is_loaded = true;
				activity.runOnUiThread(new Runnable() {
					@Override
					public void run() {
						if (popup == null) {
							int y = 0;
							int gravity = Gravity.BOTTOM;
							if (banner_position.equals("top")) {
								gravity = Gravity.TOP;
								y = activity.getWindow().getDecorView().getTop();
							}

							RelativeLayout banner_layout = new RelativeLayout(activity);
							banner_layout.setPadding(0, 0, 0, 0);
							RelativeLayout.LayoutParams layout_params = new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.WRAP_CONTENT);
							layout_params.setMargins(0, 0, 0, 0);
							banner_layout.addView(banner, layout_params);

							popup = new PopupWindow(activity);
							popup.setWidth(RelativeLayout.LayoutParams.MATCH_PARENT);
							popup.setHeight(RelativeLayout.LayoutParams.WRAP_CONTENT);
							popup.setClippingEnabled(false);
							popup.setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));

							popup.setContentView(banner_layout);
							popup.showAtLocation(main_layout, gravity, 0, y);
							popup.update();
						}
					}
				});
			}
			dispatch_event("loaded", EventTypes.BANNER);
		}

		public void onAdOpened() {
			dispatch_event("opened", EventTypes.BANNER);
		}
	}
	//endregion
}
