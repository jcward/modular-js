class Test
{
  public static function main()
  {
    // Constructor uses the setter
    var a = new Ext("foo");
    expect(a.toString(), "base_var=init:foo and length 8");

    a.prefix = "ext";

    // Setter uses the setter
    a.base_var = "world";
    expect(a.toString(), "base_var=ext:world and length 9");


    a.set_something(5);
    expect(a.toString(), "base_var=ext:Roughly5 and length 12");

    function alphabetic(a:String,b:String):Int return a<b ? -1 : 1;

    var fields = Reflect.fields(a);
    fields.sort(alphabetic);
    expect('Fields: $fields', 'Fields: [base_var,prefix,real_length]');

    fields = Type.getInstanceFields(Type.getClass(a));
    fields.sort(alphabetic);
    expect('getInstanceFields: $fields', 'getInstanceFields: [base_var,get_base_var,get_length,get_not_real_var,get_real_length,prefix,real_length,regular_var,set_base_var,set_not_real_var,set_prefix,set_something,toString]');

    // Moved to init_sequence testcase
    //expect(Ext.greet('world'), 'Hello world');

    var cls = Type.getClass(a);
    expect(Type.getClassName(cls), "Ext");
    fields = Type.getClassFields(cls);
    fields.sort(alphabetic);
    expect('getClassFields(Ext): $fields', 'getClassFields(Ext): [_greeting,dummy,greet]');

    var sup = Type.getSuperClass(cls);
    expect(Type.getClassName(sup), "Base");
    fields = Type.getClassFields(sup);
    fields.sort(alphabetic);
    expect('getClassFields(Base): $fields', 'getClassFields(Base): []');

    // Reflect.setProperty uses the setter
    #if js js.Lib.debug(); #end
    Reflect.setProperty(a, "base_var", "something");
    expect(a.toString(), "base_var=ext:something and length 13");

    // Reflect.setField bypasses the setter
    Reflect.setField(a, "base_var", "something");
    expect(a.toString(), "base_var=something and length 9");

    Reflect.callMethod(a, Reflect.getProperty(a, "set_something"), [3]);
    expect(a.toString(), "base_var=ext:Roughly3 and length 12");
  }

  public static function expect(a:String, b:String)
  {
    if (a==b) {
      trace('Success!');
    } else {
      trace('FAILED:');
      trace('-received: $a');
      trace('-expected: $b');
    }
  }
}

class Base
{
  public var not_real_var(get,set):String;

  @:isVar
  public var base_var(get,set):String;

  // The never means this holds no value and is not a real variable --
  // this declaraction simply implies a getter
  public var length(get,never):Int;

  // The null means this holds a value and is a real variable --
  // while also implying a getter.
  public var real_length(get,null):Int = 15;

  public var inane_var(never,never):Int;

  public var regular_var:Int;

  public function new(value:String)
  {
    this.base_var = value;
  }

  public function get_base_var():String { return this.base_var; }
  public function set_base_var(v:String):String { this.base_var = v; return v; }

  public function get_not_real_var():String { return ""; }
  public function set_not_real_var(v:String):String { return ""; }

  public function get_length():Int { return this.base_var.length; }

  public function get_real_length():Int { return real_length*2; }

  public function toString()
  {
    return "base_var="+base_var+" and length "+length;
  }
}

class Ext extends Base
{
  private static var _greeting = "Salutations";
  public static function greet(name:String):String { return '$_greeting $name'; }
  public static var dummy = (function() { _greeting = "Hello"; return true; })();
  public static function __init__() { _greeting = "Hi"; }

  public var prefix(null,set):String = "init";

  public function new(value:String)
  {
    super(value);
  }

  override public function set_base_var(v:String):String { super.base_var = prefix+":"+v; return super.base_var; }

  public function set_something(val:Int)
  {
    base_var = "Roughly"+val;
  }

  public function set_prefix(val:String):String
  {
    return prefix = val;
  }

}

@:keep
class BaseNoProp
{
  public function new(value:String)
  {
  }
}

@:keep
class ExtProp extends BaseNoProp
{
  public var prefix(null,set):String = "init";

  public function new(value:String)
  {
    super(value);
  }

  public function set_prefix(val:String):String
  {
    return prefix = val;
  }

}
