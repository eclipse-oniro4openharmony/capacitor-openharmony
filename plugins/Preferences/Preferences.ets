import { CapacitorPlugin } from "../CapacitorPlugin";
import { PluginCall } from "../PluginCall";
import dataPreferences from "@ohos.data.preferences";

export class PreferencesPlugin extends CapacitorPlugin {
  private preferences: dataPreferences.Preferences | null = null;
  private readonly PREF_NAME = "CapacitorStorage";

  getPluginId(): string {
    return "Preferences";
  }

  getMethods(): string[] {
    return ["configure", "get", "set", "remove", "clear", "keys", "migrate"];
  }

  async loadPreferences() {
    if (!this.preferences) {
      try {
        this.preferences = await dataPreferences.getPreferences(this.context, this.PREF_NAME);
      } catch (err) {
        console.error("Failed to load preferences", err);
      }
    }
    return this.preferences;
  }

  async configure(call: PluginCall) {
    call.resolve();
  }

  async get(call: PluginCall) {
    const key = call.getString("key");
    if (!key) {
      call.reject("Must provide key");
      return;
    }

    class GetResult {
      value: string | null = null;
    }

    try {
      const prefs = await this.loadPreferences();
      if (!prefs) {
        call.reject("Preferences not loaded");
        return;
      }

      const has = await prefs.has(key);
      if (!has) {
        let res: GetResult = { value: null };
        call.resolve(res);
        return;
      }

      const val = await prefs.get(key, "");
      let res: GetResult = { value: val as string };
      call.resolve(res);
    } catch (err) {
      // ArkTS: call.reject expects string
      call.reject(JSON.stringify(err));
    }
  }

  async set(call: PluginCall) {
    const key = call.getString("key");
    const value = call.getString("value");
    if (!key || value === undefined) {
      call.reject("Must provide key and value");
      return;
    }

    try {
      const prefs = await this.loadPreferences();
      if (!prefs) {
        call.reject("Preferences not loaded");
        return;
      }
      await prefs.put(key, value);
      await prefs.flush();
      call.resolve();
    } catch (err) {
      call.reject(JSON.stringify(err));
    }
  }

  async remove(call: PluginCall) {
    const key = call.getString("key");
    if (!key) {
      call.reject("Must provide key");
      return;
    }

    try {
      const prefs = await this.loadPreferences();
      if (!prefs) {
        call.reject("Preferences not loaded");
        return;
      }
      await prefs.delete(key);
      await prefs.flush();
      call.resolve();
    } catch (err) {
      call.reject(JSON.stringify(err));
    }
  }

  async clear(call: PluginCall) {
    try {
      const prefs = await this.loadPreferences();
      if (!prefs) {
        call.reject("Preferences not loaded");
        return;
      }
      await prefs.clear();
      await prefs.flush();
      call.resolve();
    } catch (err) {
      call.reject(JSON.stringify(err));
    }
  }

  async keys(call: PluginCall) {
    class KeysResult {
      keys: string[] = [];
    }

    try {
      const prefs = await this.loadPreferences();
      if (!prefs) {
        call.reject("Preferences not loaded");
        return;
      }
      const all = await prefs.getAll();
      const keys = Object.keys(all);
      let res: KeysResult = { keys: keys };
      call.resolve(res);
    } catch (err) {
      call.reject(JSON.stringify(err));
    }
  }

  async migrate(call: PluginCall) {
    class MigrateResult {
      migrated: string[] = [];
    }
    let res: MigrateResult = { migrated: [] };
    call.resolve(res);
  }
}
