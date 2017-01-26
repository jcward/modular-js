package modular.js;

using StringTools;

class MainPackage extends Package {
  private static var pre = new haxe.Template('// Package: ::packageName::
require([::dependencyNames::],
	    function (::dependencyVars::) {
');
  private static var post = new haxe.Template('
});
');

	public override function getCode() {

		//  Collect the package's dependencies into one array
		var allDeps = new haxe.ds.StringMap();
		var depKeys = [for (k in dependencies.keys()) k];

		var data = {
			packageName: name,
			path: path,
			dependencyNames: depKeys.map(getDependencyName).join(', '),
			dependencyVars: [for (k in depKeys) k.replace('.', '_')].join(', '),
		};
		var _code = pre.execute(data);

		_code += '\t$code';

		_code += post.execute(data);
		return _code;
	}
}
