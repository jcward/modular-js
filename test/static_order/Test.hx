class Test
{
  public static function SUM(a:Int,b:Int) return a+b;

  public static var ONE = 1;
  public static var TWO = SUM(ONE,ONE);
  public static var THREE = SUM(TWO,ONE);
  public static var FOUR = SUM(THREE,ONE);

  public static function main()
  {
    trace(SUM(2,2)==FOUR);
  }
}
