class Test
{
  public static function main()
  {
    var a = new haxe.io.Path("/tmp/foo/bar");

    try {
      var name = Type.getClassName(Type.getClass(a));
      trace(name);
      trace(name=="haxe.io.Path" ? "Success!" : "FAILED!");
    } catch (e:Dynamic) {
      trace("FAILED, threw!");
    }
  }
}
