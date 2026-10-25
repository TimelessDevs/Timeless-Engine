package tscript;

import haxe.crypto.Md5;
import haxe.ds.StringMap;

/**
 * Content-aware cache for imported TScript modules.
 * A module is parsed/evaluated by the future interpreter once per content version.
 * Call acquire() when an importer starts using it and release() when that importer
 * is unloaded or stops referencing it. Zero-reference entries are evicted immediately.
 */
class TScriptModuleCache {
    private static var entries:StringMap<Entry> = new StringMap();

    public static function acquire(path:String, source:String):Entry {
        var key = normalize(path);
        var hash = Md5.encode(source);
        var entry = entries.get(key);
        if (entry == null || entry.hash != hash) {
            // Content changed: invalidate the previous version and cache the new source.
            entry = new Entry(key, hash, source);
            entries.set(key, entry);
        }
        entry.references++;
        return entry;
    }

    public static function peek(path:String, source:String):Entry {
        var key = normalize(path);
        var hash = Md5.encode(source);
        var entry = entries.get(key);
        if (entry == null || entry.hash != hash) {
            entry = new Entry(key, hash, source);
            entries.set(key, entry);
        }
        return entry;
    }

    public static function release(path:String):Void {
        var key = normalize(path);
        var entry = entries.get(key);
        if (entry == null) return;
        if (entry.references > 0) entry.references--;
        if (entry.references <= 0) entries.remove(key);
    }

    public static function invalidate(path:String):Void entries.remove(normalize(path));
    public static function clear():Void entries.clear();
    public static function count():Int {
        var n = 0;
        for (_ in entries) n++;
        return n;
    }

    static function normalize(path:String):String return StringTools.replace(path, "\\", "/");
}

class Entry {
    public final path:String;
    public final hash:String;
    public final source:String;
    public var references:Int = 0;
    /** Interpreter-owned evaluated exports can be attached here after parser/runtime lands. */
    public var exports:Dynamic = null;
    public function new(path:String, hash:String, source:String) {
        this.path = path;
        this.hash = hash;
        this.source = source;
    }
}
