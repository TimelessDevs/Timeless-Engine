package tscript;

import haxe.ds.StringMap;

/** Namespaced host API registry; real Psych bindings are added by the engine adapter. */
class TScriptApi {
    final functions:StringMap<Dynamic> = new StringMap();
    final values:StringMap<Dynamic> = new StringMap();
    final namespaces:StringMap<StringMap<Dynamic>> = new StringMap();
    public function new() {}
    public function registerFunction(name:String, fn:Dynamic):Void functions.set(name, fn);
    public function registerValue(name:String, value:Dynamic):Void values.set(name, value);
    public function registerNamespace(namespace:String, name:String, value:Dynamic):Void {
        var entries = namespaces.get(namespace);
        if (entries == null) { entries = new StringMap<Dynamic>(); namespaces.set(namespace, entries); }
        entries.set(name, value);
    }
    public function hasFunction(name:String):Bool return functions.exists(name);
    public function getFunction(name:String):Dynamic return functions.get(name);
    public function hasValue(name:String):Bool return values.exists(name);
    public function getValue(name:String):Dynamic return values.get(name);
    public function getNamespace(name:String):StringMap<Dynamic> return namespaces.get(name);
    public function call(name:String, args:Array<Dynamic>):Dynamic {
        var fn = functions.get(name);
        if (fn == null) throw 'TScript API: unknown function "$name".';
        return Reflect.callMethod(null, fn, args == null ? [] : args);
    }
}
