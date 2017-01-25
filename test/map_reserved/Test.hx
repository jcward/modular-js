class Test
{
  public static function main()
  {
    var a = new haxe.ds.StringMap<String>();
 
    try {
      a.set("foo", "bar");
      trace(a.get("foo")=="bar" ? "Success!" : "FAILED!");
    } catch (e:Dynamic) {
      trace("FAILED, threw!");
    }
  }
}
