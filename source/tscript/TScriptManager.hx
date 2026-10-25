package tscript;

import haxe.io.Path;
import haxe.ds.StringMap;

/**
 * TScript loader. It deliberately creates the API lazily: no .tsc files means no
 * API registry or runtime contexts are allocated. Execution is attached by the interpreter.
 */
class TScriptManager {
    public static inline var EXTENSION = ".tsc";
    public final events:TScriptEventBus = new TScriptEventBus();
    public final contexts:Array<TScriptContext> = [];
    public var api:TScriptApi = null;
    public var enabled(default, null):Bool = false;
    public var errors(default, null):Array<String> = [];

    public function new() {}

    public static function scriptDirectories(?currentMod:String):Array<String> {
        var result:Array<String> = [];
        if (currentMod != null && StringTools.trim(currentMod) != "") result.push('mods/' + currentMod + '/scripts/');
        result.push('mods/scripts/');
        result.push('assets/scripts/');
        return result;
    }

    public static function discover(?currentMod:String):Array<String> {
        var files:Array<String> = [];
        #if sys
        for (folder in scriptDirectories(currentMod)) {
            if (!sys.FileSystem.exists(folder) || !sys.FileSystem.isDirectory(folder)) continue;
            var names = sys.FileSystem.readDirectory(folder);
            names.sort(Reflect.compare);
            for (name in names) {
                var path = Path.join([folder, name]);
                if (sys.FileSystem.isDirectory(path)) continue;
                if (Path.extension(name).toLowerCase() == "tsc" && sys.FileSystem.exists(path)) {
                    if (files.indexOf(path) < 0) files.push(path);
                }
            }
        }
        #end
        return files;
    }

    /** Returns false and leaves api null when there are no .tsc files. */
    public function loadFound(?currentMod:String):Bool {
        var files = discover(currentMod);
        if (files.length == 0) return false;
        api = createApi();
        enabled = true;
        for (file in files) loadSource(file);
        return contexts.length > 0;
    }

    function createApi():TScriptApi {
        var value = new TScriptApi();
        value.registerFunction("trace", function(v:Dynamic):Void trace('[TScript] ' + Std.string(v)));
        value.registerFunction("toString", function(v:Dynamic):String return Std.string(v));
        value.registerFunction("toInt", function(v:Dynamic):Int return Std.int(v));
        value.registerFunction("toFloat", function(v:Dynamic):Float return Std.parseFloat(Std.string(v)));
        value.registerFunction("typeOf", function(v:Dynamic):String return Type.typeof(v).getName());
        return value;
    }

    public function loadSource(path:String):TScriptContext {
        if (api == null) throw "TScript API must not be initialized before a .tsc file is found.";
        if (Path.extension(path).toLowerCase() != "tsc") throw 'Not a .tsc file: $path';
        for (context in contexts) if (samePath(context.file, path)) return context;
        var context = new TScriptContext(path);
        #if sys
        try {
            context.source = sys.io.File.getContent(path);
            // Keep source in a content-addressed cache; imports can share this entry.
            TScriptModuleCache.acquire(path, context.source);
            context.trackImport(path);
        } catch (e:Dynamic) {
            context.lastError = e;
            errors.push('$path: ${Std.string(e)}');
            return context;
        }
        #end
        contexts.push(context);
        return context;
    }

    /** Refresh a source only when its content hash changes; unchanged source is reused. */
    public function refresh(context:TScriptContext):Bool {
        #if sys
        if (context == null || !context.enabled || !sys.FileSystem.exists(context.file)) return false;
        var fresh = sys.io.File.getContent(context.file);
        var oldHash = haxe.crypto.Md5.encode(context.source);
        var newHash = haxe.crypto.Md5.encode(fresh);
        if (oldHash == newHash) return false;
        context.releaseImports();
        context.source = fresh;
        TScriptModuleCache.acquire(context.file, fresh);
        context.trackImport(context.file);
        // The interpreter should reparse/re-evaluate this context when integrated.
        return true;
        #else
        return false;
        #end
    }

    public function dispatch(event:String, args:Array<Dynamic>):Array<Dynamic> {
        if (!enabled) return [];
        return events.emit(event, args);
    }

    public function unload(context:TScriptContext):Void {
        if (context == null) return;
        context.enabled = false;
        context.releaseImports();
        contexts.remove(context);
    }

    public function unloadAll():Void {
        for (context in contexts.copy()) unload(context);
        contexts.resize(0);
        events.clear();
        TScriptModuleCache.clear();
        enabled = false;
        api = null;
    }

    static function samePath(a:String, b:String):Bool return StringTools.replace(a, "\\", "/") == StringTools.replace(b, "\\", "/");
}
