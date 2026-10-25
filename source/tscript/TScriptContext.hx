package tscript;

import haxe.ds.StringMap;

/** Per-script state. Imported module paths are tracked so cache references release on unload. */
class TScriptContext {
    public final file:String;
    public final globals:StringMap<Dynamic> = new StringMap();
    public final importedModules:Array<String> = [];
    public var source:String = "";
    public var enabled:Bool = true;
    public var lastError:Dynamic = null;
    public function new(file:String) this.file = file;
    public function trackImport(path:String):Void {
        if (importedModules.indexOf(path) < 0) importedModules.push(path);
    }
    public function releaseImports():Void {
        for (path in importedModules) TScriptModuleCache.release(path);
        importedModules.resize(0);
    }
}
