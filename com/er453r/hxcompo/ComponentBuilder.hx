package com.er453r.hxcompo;

import haxe.macro.TypeTools;
import haxe.macro.ExprTools;
import haxe.macro.Type.ClassType;
import haxe.macro.Context;
import haxe.macro.Expr;

class ComponentBuilder {
	private static inline var VIEW_ANNOTATION:String = ":view";

	public static function build():Array<Field> {
		var file:String;

		var classType:ClassType;
		switch (Context.getLocalType()) {
			case TInst(r, _):
				classType = r.get();
			case _:
		}

		for (meta in classType.meta.get()){
			if(meta.name == VIEW_ANNOTATION)
				if(meta.params.length > 0)
					file = ExprTools.getValue(meta.params[0]);
		}

		var superClass:String;

		if(classType.superClass != null)
			superClass = classType.superClass.t.toString();

		if(superClass != Type.getClassName(Component))
			Context.error('Class has to extend ${Type.getClassName(Component)}', Context.currentPos());

		var classString:String = Context.getLocalClass().toString();

		var parts:Array<String> = classString.split(".");
		parts.pop();
		var path:String = parts.join("/");

		var p = Context.resolvePath(path + "/" + file);

		var string:String = sys.io.File.getContent(p);

		var xml:Xml;

		try{
			xml = Xml.parse(string);

			var childrenCount:UInt = 0;

			var iterator:Iterator<Xml> = xml.elements();

			while(iterator.hasNext()){
				childrenCount++;
				iterator.next();
			}

			if(childrenCount != 1)
				Context.error('View File ${p} has to contain exactly 1 root node', Context.currentPos());
		}
		catch(err:String){
			Context.error('Error parsing file ${p}: ${err}', Context.currentPos());
		}

		var fields:Array<Field> = Context.getBuildFields();

		var hasConstructor:Bool = false;

		for(field in fields){
			if(field.name == "new"){
				hasConstructor = true;

				break;
			}
		}

		if(!hasConstructor){
			fields.push({name: 'new', doc: null, access: [Access.APublic], kind: FieldType.FFun({
				params : [],
				args : [],
				expr: macro {},
				ret : macro : Void
			}), pos: Context.currentPos()});
		}

		for(field in fields){
			if(field.name == "new"){
				switch(field.kind){
					case FFun(func):{
						func.expr = macro {
							buildFromString(this.contents);
							${func.expr};
						};
					}

					default: {}
				}
			}
		}

		fields.push({name: 'contents', doc: null, access: [Access.APrivate], kind: FieldType.FVar(macro:String, macro $v{string}), pos: Context.currentPos()});

		var args:Array<String> = Sys.args();

		var mainIndex:Int = args.indexOf('-main');

		if(mainIndex != -1){
			var mainClass:String = args[mainIndex + 1];

			var type = asTypePath(mainClass);

			if(TypeTools.toString(Context.getLocalType()) == mainClass){
				fields.push({name: 'main', doc: null, access: [Access.APublic, Access.AStatic], kind: FieldType.FFun({
					params : [],
					args : [],
					expr: macro {
						js.Browser.document.addEventListener("DOMContentLoaded", function(event){
						js.Browser.document.body.appendChild(new $type().view);
					});
					},
					ret : macro : Void
				}), pos: Context.currentPos()});
			}
		}

		return fields;
	}

	static public function asTypePath(s:String, ?params):TypePath {
		var parts = s.split('.');
		var name = parts.pop(),
		sub = null;
		if (parts.length > 0 && parts[parts.length - 1].charCodeAt(0) < 0x5B) {
			sub = name;
			name = parts.pop();
			if(sub == name) sub = null;
		}
		return {
			name: name,
			pack: parts,
			params: params == null ? [] : params,
			sub: sub
		};
	}
}
