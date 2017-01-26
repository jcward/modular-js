class Test
{
  public static function main()
  {
    // Need to define $hx_exports var, though it is global by default...
    untyped __js__("var $hx_exports = (typeof exports != \"undefined\" ? exports : typeof window != \"undefined\" ? window : typeof self != \"undefined\" ? self : this);");

    trace("Looking for $hx_exports.namespace.sub.Foo");
    var cls = null;

    try {
#if js
      untyped __js__("{0} = $hx_exports.namespace.sub.Foo;", cls);
#end

      trace(cls.MyStatic=="blah" ? "Success!" : "FAILED!");
    } catch (e:Dynamic) {
      trace("FAILED! threw");
    }

    trace(cls==Foo ? "Success!" : "FAILED!");
  }
}

@:expose("namespace.sub.Foo")
class Foo
{
  public static var MyStatic = "blah";

  public function new(a:String)
  {
    trace("Hi, "+a);
  }  
}
