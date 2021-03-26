package extension.admob;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdSize;

abstract class AdmobUtils {
	static int clamp(int value, int min, int max) {
		if (value > max) {
			return max;
		} else if (value < min) {
			return min;
		} else {
			return value;
		}
	}

	static double clamp(double value, double min, double max) {
		if (value > max) {
			return max;
		} else if (value < min) {
			return min;
		} else {
			return value;
		}
	}

	static String adRequestErrorCodeToString(int error_code) {
		switch (error_code) {
			case AdRequest.ERROR_CODE_INTERNAL_ERROR:
				return "Something happened internally; for instance, an invalid response was received from the ad server.";
			case AdRequest.ERROR_CODE_INVALID_REQUEST:
				return "The ad request was invalid; for instance, the ad unit ID was incorrect.";
			case AdRequest.ERROR_CODE_NETWORK_ERROR:
				return "The ad request was unsuccessful due to network connectivity.";
			case AdRequest.ERROR_CODE_NO_FILL:
				return "The ad request was successful, but no ad was returned due to lack of ad inventory.";
		}
		return "";
	}

	static AdSize stringToBannerSize(String value) {
		switch (value) {
			case "large":
				return AdSize.LARGE_BANNER;
			case "medium":
				return AdSize.MEDIUM_RECTANGLE;
			case "full":
				return AdSize.FULL_BANNER;
			case "leaderboard":
				return AdSize.LEADERBOARD;
			case "smart":
			case "smart_portrait":
			case "smart_landscape":
				return AdSize.SMART_BANNER;
			case "banner":
			default:
				return AdSize.BANNER;
		}
	}
}