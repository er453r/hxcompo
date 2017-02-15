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

	static public function getClassType():ClassType{
		var classType:ClassType;
		switch (Context.getLocalType()) {
			case TInst(r, _):
				classType = r.get();
			case _:
		}

		return classType;
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

	static public function parseHTML(fileName:String):Xml{
		var html:String = getFileContent(fileName);

		var xml:Xml;

		try{
			xml = Xml.parse(html);

			if(nodeChildren(xml).length != 1)
				Context.error('View File ${fileName} has to contain exactly 1 root node', Context.currentPos());
		}
		catch(err:String){
			Context.error('Error parsing file ${fileName}: ${err}', Context.currentPos());
		}

		return xml.firstChild();
	}

	static public function nodeChildren(node:Xml):Array<Xml>{
		var children:Array<Xml> = [];

		var iterator:Iterator<Xml> = node.iterator();

		var emptyRegEx:EReg = ~/^\s*$/;

		while(iterator.hasNext()){
			var child:Xml = iterator.next();

			var string:String = child.toString();

			if(emptyRegEx.match(string))
				continue;

			children.push(child);
		}

		return children;
	}

	static public function findNodesWithAttr(node:Xml, attr:String):Array<Xml>{
		var ids:Array<Xml> = [];

		if(node.exists(attr))
			ids.push(node);

		var iterator:Iterator<Xml> = node.elements();

		while(iterator.hasNext())
			ids = ids.concat(findNodesWithAttr(iterator.next(), attr));

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
		var meta:MetadataEntry = getMetaEntry(name);

		if(meta != null && meta.params.length > 0)
				return ExprTools.getValue(meta.params[0]);

		return null;
	}

	static public function getMetaEntry(name:String):MetadataEntry {
		var classType:ClassType;

		switch (Context.getLocalType()) {
			case TInst(r, _):
				classType = r.get();
			case _:
		}

		for (meta in classType.meta.get())
			if(meta.name == name)
				return meta;

		return null;
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

	static public inline function asComplexType(s:String, ?params){
		return TPath(asTypePath(s, params));
	}

	static public inline function tagNameToClassName(tag:String){
		var tagMap:Map<String, String> = ["img" => "image"];

		if(tagMap.exists(tag))
			tag = tagMap.get(tag);

		tag = tag.substring(0, 1).toUpperCase() + tag.substring(1).toLowerCase();

		var className:String = 'js.html.${tag}Element';

		if(!classExists(className))
			className = 'js.html.Element';

		return className;
	}

	static public inline function classExists(className:String):Bool{
		var exists:Bool = false;

		try{
			Context.getType(className);

			exists = true;
		}
		catch(err:String){}

		return exists;
	}
}
