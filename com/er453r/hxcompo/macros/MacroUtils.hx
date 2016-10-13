package com.er453r.hxcompo.macros;

import haxe.macro.ExprTools;
import haxe.macro.Type.ClassType;
import haxe.macro.Context;
import haxe.macro.Expr;

import sys.io.File;

class MacroUtils {
	static public function getClassName():String{
		return  Context.getLocalClass().toString().split(".").pop();
	}

	static public function getMainClassName():String{
		var mainClass:String;

		var args:Array<String> = Sys.args();

		var mainIndex:Int = args.indexOf('-main');

		if(mainIndex != -1)
			mainClass = args[mainIndex + 1];

		return mainClass;
	}

	static public function getField(fieldName:String, fields:Array<Field>):Field{
		var found:Field = null;

		for(field in fields){
			if(field.name == fieldName){
				found = field;

				break;
			}
		}

		return found;
	}

	static public function parseHTML(fileName:String):String{
		var html:String = getFileContent(fileName);

		var xml:Xml;

		try{
			xml = Xml.parse(html);

			var childrenCount:UInt = 0;

			var iterator:Iterator<Xml> = xml.elements();

			while(iterator.hasNext()){
				childrenCount++;
				iterator.next();
			}

			if(childrenCount != 1)
				Context.error('View File ${fileName} has to contain exactly 1 root node', Context.currentPos());
		}
		catch(err:String){
			Context.error('Error parsing file ${fileName}: ${err}', Context.currentPos());
		}

		return html;
	}

	static public function findIdTags(fileName:String):Array<String>{
		var html:String = getFileContent(fileName);

		var xml:Xml = Xml.parse(html);

		return findIdTagsInNode(xml.firstChild());
	}

	static private function findIdTagsInNode(node:Xml):Array<String>{
		var ids:Array<String> = [];

		if(node.exists("id"))
			ids.push(node.get("id"));

		var iterator:Iterator<Xml> = node.elements();

		while(iterator.hasNext())
			ids = ids.concat(findIdTagsInNode(iterator.next()));

		return ids;
	}

	static public function getContextPath(fileName:String):String {
		var classString:String = Context.getLocalClass().toString();

		var parts:Array<String> = classString.split(".");
		parts.pop();
		var path:String = parts.join("/");

		return path + "/" + fileName;
	}

	static public function contextFileExists(fileName:String):Bool {
		var exists:Bool = false;

		try{
			Context.resolvePath(getContextPath(fileName));

			exists = true;
		}
		catch(err:String){}

		return exists;
	}

	static public function getFileContent(fileName:String):String {
		return File.getContent(Context.resolvePath(getContextPath(fileName)));
	}

	static public function getMeta(name:String):String {
		var classType:ClassType;

		switch (Context.getLocalType()) {
			case TInst(r, _):
				classType = r.get();
			case _:
		}

		var value:String;

		for (meta in classType.meta.get())
			if(meta.name == name)
			if(meta.params.length > 0)
				value = ExprTools.getValue(meta.params[0]);

		return value;
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
