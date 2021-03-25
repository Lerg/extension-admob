package extension.admob;

import android.text.TextUtils;
import android.util.Log;

import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;

class LuaScriptListener {
	int listener = Lua.REFNIL;
	int script_instance = Lua.REFNIL;
}

abstract class JavaFunction {
	abstract public int invoke(long L);
}

abstract class Utils {
	private static ArrayList<JavaFunction> tasks = new ArrayList<JavaFunction>();
	private static boolean is_debug = false;

	static void enable_debug() {
		is_debug = true;
	}

	static int new_ref(long L) {
		return Lua.ref(L, Lua.REF_OWNER);
	}

	static int new_ref(long L, int index) {
		Lua.pushvalue(L, index);
		return Lua.ref(L, Lua.REF_OWNER);
	}

	static void delete_ref(long L, int ref) {
		if (ref > 0) {
			Lua.unref(L, Lua.REF_OWNER, ref);
		}
	}

	private static String TAG = "debug";

	static void set_tag(String tag) {
		TAG = tag;
	}

	static void log(String message) {
		Log.i(TAG, message);
	}

	static void debug_log(String message) {
		if (is_debug) {
			Log.d(TAG, message);
		}
	}

	static void check_arg_count(long L, int count_exact) {
		int count = Lua.gettop(L);
		if (count != count_exact) {
			Log.e(TAG, "This function requires " + count_exact + " arguments. Got " + count + ".");
			Lua.error(L, "This function requires " + count_exact + " arguments. Got " + count + ".");
		}
	}

	static void check_arg_count(long L, int count_from, int count_to) {
		int count = Lua.gettop(L);
		if ((count < count_from) || (count > count_to)) {
			Log.e(TAG, "This function requires from " + count_from + " to " + count_to + " arguments. Got " + count + ".");
			Lua.error(L, "This function requires from " + count_from + " to " + count_to + " arguments. Got " + count + ".");
		}
	}

	static void delete_ref_if_not_nil(long L, int ref) {
		if ((ref != Lua.REFNIL) && (ref != Lua.NOREF)) {
			delete_ref(L, ref);
		}
	}

	static void put(Hashtable<Object, Object> hastable, String key, Object value) {
		if (value != null) {
			hastable.put(key, value);
		}
	}

	static Hashtable<Object, Object> new_event(String name) {
		Hashtable<Object, Object> event = new Hashtable<Object, Object>();
		event.put("name", name);
		return event;
	}

	static void dispatch_event(final LuaScriptListener script_listener, final Hashtable<Object, Object> event) {
		dispatch_event(script_listener, event, false);
	}

	static void dispatch_event(final LuaScriptListener script_listener, final Hashtable<Object, Object> event, final boolean should_delete_ref) {
		if ((script_listener == null) || (script_listener.listener == Lua.REFNIL) || (script_listener.listener == Lua.NOREF) || (script_listener.script_instance == Lua.REFNIL) || (script_listener.script_instance == Lua.NOREF)) {
			return;
		}
		JavaFunction task = new JavaFunction() {
			public int invoke(long L) {
				Lua.rawget(L, Lua.REF_OWNER, script_listener.listener);
				Lua.rawget(L, Lua.REF_OWNER, script_listener.script_instance);
				Lua.dmscript_setinstance(L);
				push_hashtable(L, event);
				Lua.call(L, 1, 0);
				if (should_delete_ref) {
					delete_ref(L, script_listener.listener);
					delete_ref(L, script_listener.script_instance);
				}
				return 0;
			}
		};
		tasks.add(task);
	}

	static void execute_tasks(long L) {
		while (!tasks.isEmpty()) {
			JavaFunction task = tasks.remove(0);
			task.invoke(L);
		}
	}

	static class LuaLightuserdata {
		long pointer;

		LuaLightuserdata(long pointer) {
			this.pointer = pointer;
		}
	}

	static class LuaValue {
		int reference = Lua.REFNIL;

		LuaValue(long L, int index) {
			reference = new_ref(L, index);
		}

		void delete(long L) {
			if (reference != Lua.REFNIL) {
				delete_ref(L, reference);
			}
		}
	}

	interface LuaPushable {
		void push(long L);
	}

	static class Table {
		private long L;
		private int index;
		private Hashtable<Object, Object> hashtable;
		private Scheme scheme;

		Table (long L, int index) {
			this.L = L;
			this.index = index;
		}

		Table parse(Scheme scheme) {
			this.scheme = scheme;
			hashtable = to_hashtable(L, index, null);
			return this;
		}

		Boolean get_boolean(String path, Boolean default_value) {
			Boolean result = get_boolean(path);
			if (result != null) {
				return result;
			} else {
				return default_value;
			}
		}

		Boolean get_boolean(String path) {
			if ((get(path) != null) && (get(path) instanceof Boolean)) {
				return (Boolean) get(path);
			} else {
				return null;
			}
		}

		String get_string(String path, String default_value) {
			String result = get_string(path);
			if (result != null) {
				return result;
			} else {
				return default_value;
			}
		}

		String get_string(String path) {
			if ((get(path) != null) && (get(path) instanceof String)) {
				return (String) get(path);
			} else {
				return null;
			}
		}

		String get_string_not_null(String path) {
			String result = get_string(path);
			if (result != null) {
				return result;
			} else {
				Log.e(TAG, "ERROR: Table's property '" + path + "' is not a string.");
				Lua.error(L, "ERROR: Table's property '" + path + "' is not a string.");
				return null;
			}
		}

		Double get_double(String path, double default_value) {
			Double result = get_double(path);
			if (result != null) {
				return result;
			} else {
				return default_value;
			}
		}

		Double get_double(String path) {
			if ((get(path) != null) && (get(path) instanceof Double)) {
				return (Double) get(path);
			} else {
				return null;
			}
		}

		Double get_double_not_null(String path) {
			Double result = get_double(path);
			if (result != null) {
				return result;
			} else {
				Log.e(TAG, "ERROR: Table's property '" + path + "' is not a number.");
				Lua.error(L, "ERROR: Table's property '" + path + "' is not a number.");
				return null;
			}
		}

		Integer get_integer(String path, int default_value) {
			Integer result = get_integer(path);
			if (result != null) {
				return result;
			} else {
				return default_value;
			}
		}

		Integer get_integer(String path) {
			if ((get(path) != null) && (get(path) instanceof Double)) {
				return ((Double) get(path)).intValue();
			} else {
				return null;
			}
		}

		Integer get_integer_not_null(String path) {
			Integer result = get_integer(path);
			if (result != null) {
				return result;
			} else {
				Log.e(TAG, "ERROR: Table's property '" + path + "' is not a number.");
				Lua.error(L, "ERROR: Table's property '" + path + "' is not a number.");
				return null;
			}
		}

		Long get_long(String path, long default_value) {
			Long result = get_long(path);
			if (result != null) {
				return result;
			} else {
				return default_value;
			}
		}

		Long get_long(String path) {
			if ((get(path) != null) && (get(path) instanceof Double)) {
				return ((Double) get(path)).longValue();
			} else {
				return null;
			}
		}

		Long get_long_not_null(String path) {
			Long result = get_long(path);
			if (result != null) {
				return result;
			} else {
				Log.e(TAG, "ERROR: Table's property '" + path + "' is not a number.");
				Lua.error(L, "ERROR: Table's property '" + path + "' is not a number.");
				return null;
			}
		}

		byte[] get_byte_array(String path, byte[] default_value) {
			byte[] result = get_byte_array(path);
			if (result != null) {
				return result;
			} else {
				return default_value;
			}
		}

		byte[] get_byte_array(String path) {
			if ((get(path) != null) && (get(path) instanceof byte[])) {
				return (byte[]) get(path);
			} else {
				return null;
			}
		}

		byte[] get_byte_array_not_null(String path) {
			byte[] result = get_byte_array(path);
			if (result != null) {
				return result;
			} else {
				Log.e(TAG, "ERROR: Table's property '" + path + "' is not a byte array.");
				Lua.error(L, "ERROR: Table's property '" + path + "' is not a byte array.");
				return null;
			}
		}

		LuaLightuserdata get_lightuserdata(String path, Long default_value) {
			LuaLightuserdata result = get_lightuserdata(path);
			if (result != null) {
				return result;
			} else {
				return new LuaLightuserdata(default_value);
			}
		}

		LuaLightuserdata get_lightuserdata(String path) {
			if ((get(path) != null) && (get(path) instanceof LuaLightuserdata)) {
				return (LuaLightuserdata) get(path);
			} else {
				return null;
			}
		}

		LuaLightuserdata get_lightuserdata_not_null(String path) {
			LuaLightuserdata result = get_lightuserdata(path);
			if (result != null) {
				return result;
			} else {
				Log.e(TAG, "ERROR: Table's property '" + path + "' is not a lightuserdata.");
				Lua.error(L, "ERROR: Table's property '" + path + "' is not a lightuserdata.");
				return null;
			}
		}

		Integer get_function(String path, Integer default_value) {
			Integer result = get_function(path);
			if (result != null) {
				return result;
			} else {
				return default_value;
			}
		}

		Integer get_function(String path) {
			if ((get(path) != null) && (get(path) instanceof Integer)) {
				return (Integer) get(path);
			} else {
				return null;
			}
		}

		@SuppressWarnings("unchecked")
		Hashtable<Object, Object> get_table(String path) {
			if ((get(path) != null) && (get(path) instanceof Hashtable)) {
				return (Hashtable<Object, Object>) get(path);
			} else {
				return null;
			}
		}

		Object get(String path) {
			if (path.isEmpty()) {
				return hashtable;
			} else {
				Object current = null;
				for (String p : path.split("\\.")) {
					if (current == null) {
						current = hashtable.get(p);
					} else if (current instanceof Hashtable) {
						Hashtable h = (Hashtable) current;
						current = h.get(p);
					}
				}
				return current;
			}
		}

		private Object to_value(long L, int index, ArrayList<String> path_list) {
			if ((index < 0) && (index > Lua.registryindex(L))) {
				index = Lua.gettop(L) + index + 1;
			}
			Object o = null;
			if (scheme == null) {
				switch (Lua.type(L, index)) {
					case STRING:
						o = Lua.tostring(L, index);
						break;
					case NUMBER:
						o = Lua.tonumber(L, index);
						break;
					case BOOLEAN:
						o = Lua.toboolean(L, index);
						break;
					case LIGHTUSERDATA:
						o = new LuaLightuserdata(Lua.topointer(L, index));
						break;
					case TABLE:
						o = to_hashtable(L, index, path_list);
						break;
				}
			} else {
				String path = TextUtils.join(".", path_list);
				Object rule = scheme.get(path);
				if (rule == null && path_list.size() > 1) {
					path = TextUtils.join(".", path_list.subList(0, path_list.size() - 1)) + ".#";
					rule = scheme.get(path);
				}
				switch (Lua.type(L, index)) {
					case STRING:
						if (rule == Lua.Type.STRING) {
							o = Lua.tostring(L, index);
						} else if (rule == Scheme.LuaTypeNumeric) {
							String value = Lua.tostring(L, index);
							boolean is_numeric = true;
							try {
								Double.parseDouble(value); // Not ignored
							} catch(NumberFormatException e) {
								is_numeric = false;
							}
							if (is_numeric) {
								o = value;
							}
						}
						break;
					case NUMBER:
						if ((rule == Lua.Type.NUMBER) || (rule == Scheme.LuaTypeNumeric)) {
							o = Lua.tonumber(L, index);
						}
						break;
					case BOOLEAN:
						if (rule == Lua.Type.BOOLEAN) {
							o = Lua.toboolean(L, index);
						}
						break;
					case LIGHTUSERDATA:
						if (rule == Lua.Type.LIGHTUSERDATA) {
							o = new LuaLightuserdata(Lua.topointer(L, index));
						}
						break;
					case USERDATA:
						if (rule == Lua.Type.USERDATA) {
							o = Lua.topointer(L, index);
						}
						break;
					case FUNCTION:
						if (rule == Lua.Type.FUNCTION) {
							o = new_ref(L, index);
						}
						break;
					case TABLE:
						if (rule == Lua.Type.TABLE) {
							o = to_hashtable(L, index, path_list);
						}
				}
			}
			return o;
		}

		private Hashtable<Object, Object> to_hashtable(long L, int index, ArrayList<String> path_list) {
			if ((index < 0) && (index > Lua.registryindex(L))) {
				index = Lua.gettop(L) + index + 1;
			}

			Hashtable<Object, Object> result = new Hashtable<Object, Object>();
			if (Lua.type(L, index) != Lua.Type.TABLE) {
				return result;
			}
			Lua.pushnil(L);

			ArrayList<String> path = path_list != null ? path_list : new ArrayList<String>();
			for(; Lua.next(L, index); Lua.pop(L, 1)) {
				Object key = null;
				if (Lua.type(L, -2) == Lua.Type.STRING) {
					key = Lua.tostring(L, -2);
					path.add((String) key);
				} else if (Lua.type(L, -2) == Lua.Type.NUMBER) {
					key = Lua.tonumber(L, -2);
					path.add("#");
				}
				if (key != null) {
					Object value = to_value(L, -1, path);
					if (value != null) {
						result.put(key, value);
					}
					path.remove(path.size() - 1);
				}
			}

			return result;
		}
	}

	static class Scheme {
		Hashtable<String, Object> scheme = new Hashtable<String, Object>();

		final static Integer LuaTypeNumeric = 1000;

		Scheme string(String path) {
			scheme.put(path, Lua.Type.STRING);
			return this;
		}

		Scheme number(String path) {
			scheme.put(path, Lua.Type.NUMBER);
			return this;
		}

		Scheme bool(String path) {
			scheme.put(path, Lua.Type.BOOLEAN);
			return this;
		}

		Scheme table(String path) {
			scheme.put(path, Lua.Type.TABLE);
			return this;
		}

		Scheme function(String path) {
			scheme.put(path, Lua.Type.FUNCTION);
			return this;
		}

		Scheme lightuserdata(String path) {
			scheme.put(path, Lua.Type.LIGHTUSERDATA);
			return this;
		}

		Scheme userdata(String path) {
			scheme.put(path, Lua.Type.USERDATA);
			return this;
		}

		Scheme numeric(String path) {
			scheme.put(path, LuaTypeNumeric);
			return this;
		}

		Object get(String path) {
			return scheme.get(path);
		}
	}

	@SuppressWarnings("unchecked")
	static void push_value(long L, Object object) {
		if(object instanceof String) {
			Lua.pushstring(L, (String)object);
		} else if(object instanceof Integer) {
			Lua.pushinteger(L, (Integer)object);
		} else if(object instanceof Long) {
			Lua.pushnumber(L, ((Long)object).doubleValue());
		} else if(object instanceof Double) {
			Lua.pushnumber(L, (Double)object);
		} else if(object instanceof Boolean) {
			Lua.pushboolean(L, (Boolean)object);
		} else if(object instanceof LuaValue) {
			LuaValue value = (LuaValue) object;
			Lua.ref(L, value.reference);
			value.delete(L);
		} else if(object instanceof LuaPushable) {
			((LuaPushable) object).push(L);
		} else if(object instanceof List) {
			Hashtable<Object, Object> hashtable = new Hashtable<Object, Object>();
			int i = 1;
			for (Object o : (List)object) {
				hashtable.put(i, o);
			}
			push_hashtable(L, hashtable);
		} else if(object instanceof Hashtable) {
			push_hashtable(L, (Hashtable)object);
		} else {
			Lua.pushnil(L);
		}
	}

	static void push_hashtable(long L, Hashtable<Object, Object> hashtable) {
		if (hashtable == null) {
			Lua.newtable(L);
		} else {
			Lua.newtable(L, 0, hashtable.size());
			int tableIndex = Lua.gettop(L);
			for (Object o : hashtable.entrySet()) {
				Map.Entry entry = (Map.Entry) o;
				push_value(L, entry.getKey());
				push_value(L, entry.getValue());
				Lua.settable(L, tableIndex);
			}
		}
	}
}
