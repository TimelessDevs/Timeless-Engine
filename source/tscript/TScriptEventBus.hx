package tscript;

import haxe.ds.StringMap;

class TScriptEventBus {
    final listeners:StringMap<Array<Array<Dynamic>->Dynamic>> = new StringMap();
    public function new() {}
    public function on(event:String, callback:Array<Dynamic>->Dynamic):Void {
        var list = listeners.get(event);
        if (list == null) { list = []; listeners.set(event, list); }
        list.push(callback);
    }
    public function emit(event:String, args:Array<Dynamic>):Array<Dynamic> {
        var results:Array<Dynamic> = [];
        var list = listeners.get(event);
        if (list == null) return results;
        for (callback in list.copy()) try results.push(callback(args == null ? [] : args)) catch (e:Dynamic) {
            results.push({error: Std.string(e), event: event});
        }
        return results;
    }
    public function clear():Void listeners.clear();
}
