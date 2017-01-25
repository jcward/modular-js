package modular.js;

import haxe.macro.*;
import haxe.macro.Type.ClassType;
import haxe.macro.Type.ClassField;
import haxe.ds.StringMap;
import modular.js.interfaces.IField;
import modular.js.interfaces.IKlass;

using StringTools;
using modular.js.StringExtender;


class Klass extends Module implements IKlass {
    public var members: StringMap<IField> = new StringMap();
    public var init = "";

    public var superClass:String = null;
    public var interfaces:Array<String> = new Array();
    public var properties:Array<String> = new Array();
    public var not_real_variables:Array<String> = new Array();

    public function isEmpty() {
        return code.trim() == "" && !members.keys().hasNext() && init.trim() == "";
    }

    public function getCode() {
        var t = new haxe.Template('
// Class: ::path::
::if (dependencies.length > 0)::
// Dependencies:
    ::foreach dependencies::
//  ::__current__::
    ::end::
::end::
::if (overrideBase)::::if (useHxClasses)::$$hxClasses["::path::"] = ::className::::end::
::else::var ::className:: = ::if (useHxClasses == true)::$$hxClasses["::path::"] = ::end::::code::;
::if (interfaces != "")::::className::.__interfaces__ = [::interfaces::];
::end::::if (superClass != null)::::className::.__super__ = ::superClass::;
::className::.prototype = $$extend(::superClass::.prototype, {
::else::::className::.prototype = {
::end::::if (propertyString != "")::    "__properties__": ::propertyString::,
::end::::foreach members::  ::propertyAccessName::: ::code::,
::end:: __class__: ::className::
}::if (superClass != null)::)::end::;
::className::.__name__ = ::pathArray::;::end::
::foreach statics::::className::::fieldAccessName:: = ::code::;
::end::::if (init)::::init::
::end::
');
        function filterMember(member:IField) {
            var f = new Field(gen);
            f.name = member.name;
            f.fieldAccessName = f.name.asJSFieldAccess(gen.api);
            f.propertyAccessName = f.name.asJSPropertyAccess(gen.api);
            f.isStatic = member.isStatic;
            f.code = member.getCode();
            if (!f.isStatic) {
                f.code = f.code.indent(1);
            }
            return f;
        }

        // Properties must $extend super.prototype.__properties__ to
        // allow Reflect.setProperty to utilize a setter method
        var superHasProperties = superClass!=null;
        var propertyObjectString = '{'+[for (prop in properties) '"$prop":"$prop"'].join(',')+'}';
        var propertyString = superHasProperties ?
          '$$extend($superClass.prototype.__properties__,$propertyObjectString)' :
          propertyObjectString;

        // Technically this will generate empty __properties__ objects on all
        // classes, and expects all supers to have __properties__, which seems
        // to be fine.

        var data = {
            overrideBase: gen.isJSExtern(name),
            className: name,
            path: path,
            pathArray: haxe.Json.stringify(path.split(".")),
            code: code,
            init: if (!globalInit && init != "") init else "",
            useHxClasses: gen.hasFeature('Type.resolveClass') || gen.hasFeature('Type.resolveEnum'),
            dependencies: [for (key in dependencies.keys()) key],
            interfaces: interfaces.join(','),
            superClass: superClass,
            propertyString: propertyString,
            members: [for (member in members.iterator()) filterMember(member)].filter(function(m) { return !m.isStatic && !(not_real_variables.indexOf(m.name)>=0); }),
            statics: [for (member in members.iterator()) filterMember(member)].filter(function(m) { return m.isStatic; })
        };
        return t.execute(data);
    }

    public function addField(c: ClassType, f: ClassField) {
        gen.checkFieldName(c, f);
        gen.setContext(path + '.' + f.name);

        switch( f.kind )
        {
            case FVar(acc_get, acc_set):
                // If a variable defines a getter or a setter, those getter/setters
                // are expected properties
                if( acc_get == AccCall ) properties.push("get_"+f.name);
                if( acc_set == AccCall ) properties.push("set_"+f.name);

                // Must check metadata to tell the difference between:
                // @:isVar public var yes_real_var(get,set):String;
                //         public var not_real_var(get,set):String;
                var var_is_real = acc_get==AccNormal || acc_set==AccNormal || acc_get==AccNo || acc_set==AccNo ||
                  // Search for @:isVar metadata (not sure why f.meta.has(':isVar') isn't working)
                  ((f.meta.get().filter(function(me) { return me.name==':isVar'; }).length>0));

                if (!var_is_real) not_real_variables.push(f.name);

                if( acc_get == AccResolve ) return;

            default:
        }

        var field = new Field(gen);
        field.build(f, path);
        for (dep in field.dependencies.keys()) {
            addDependency(dep);
        }
        members.set(f.name, field);
    }

    public function addStaticField(c: ClassType, f: ClassField) {
        gen.checkFieldName(c, f);
        gen.setContext(path + '.' + f.name);
        var field = new Field(gen);
        field.build(f, path);
        field.isStatic = true;
        for (dep in field.dependencies.keys()) {
            addDependency(dep);
        }
        members.set(field.name, field);
    }

    public function build(c: ClassType) {
        name = c.name;
        path = gen.getPath(c);

        gen.setContext(path);
        if (c.init != null) {
            init = gen.api.generateStatement(c.init);
            if (name == 'Resource') {
                globalInit = true;
            } else {
                //init.indexOf('$name.') != -1 ||
                globalInit = name == 'Std';
            }
        }

        if( c.constructor != null ) {
            code = gen.api.generateStatement(c.constructor.get().expr());
        } else {
            code = "function() {}";
        }

        // Add Haxe type metadata
        if( c.interfaces.length > 0 ) {
            interfaces = [for (i in c.interfaces) gen.getTypeFromPath(gen.getPath(i.t.get()))];
        }
        if( c.superClass != null ) {
            gen.addDependency('extend_stub', this);
            superClass = gen.getTypeFromPath(gen.getPath(c.superClass.t.get()));
        }
        for (dep in gen.getDependencies().keys()) {
            addDependency(dep);
        }

        if (!c.isExtern) {
            for( f in c.fields.get() ) {
                addField(c, f);
            }

            for( f in c.statics.get() ) {
                addStaticField(c, f);
            }
        }
    }
}
