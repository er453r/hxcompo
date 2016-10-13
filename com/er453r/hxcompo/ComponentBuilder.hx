package com.er453r.hxcompo;

import haxe.macro.TypeTools;
import haxe.macro.ExprTools;
import haxe.macro.Type.ClassType;
import haxe.macro.Context;
import haxe.macro.Expr;

import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

class ComponentBuilder {
	private static inline var CONTENTS:String = "contents";
	private static inline var NEW:String = "new";
	private static inline var MAIN:String = "main";

	private static inline var VIEW_ANNOTATION:String = ":view";
	private static inline var STYLE_ANNOTATION:String = ":style";

	public static function build():Array<Field> {
		var className:String = TypeTools.toString(Context.getLocalType());
		var viewFile:String = getMeta(VIEW_ANNOTATION);
		var styleFile:String = getMeta(STYLE_ANNOTATION);

		var styleResult:String = "style.css";

		if(viewFile == null)
			Context.error('Class ${className} does not define its view', Context.currentPos());

		var viewContent:String = parseHTML(viewFile);

		var fields:Array<Field> = Context.getBuildFields();

		if(getField(NEW, fields) == null){ // if there is no constructor, create an empty one
			fields.push({
				name: NEW,
				doc: null,
				access: [Access.APublic],
				kind: FieldType.FFun({
					params : [],
					args : [],
					expr: macro {},
					ret : macro : Void
				}),
				pos: Context.currentPos()});
		}

		// inject initialization code to the constructor
		switch(getField(NEW, fields).kind){
			case FFun(func):{
				func.expr = macro {
					buildFromString(this.contents);
					${func.expr};
				};
			}

			default: {}
		}

		// create a variable for html contents
		fields.push({
			name: CONTENTS,
			doc: null,
			access: [Access.APrivate],
			kind: FieldType.FVar(macro:String, macro $v{viewContent}),
			pos: Context.currentPos()
		});

		// check if main class requires a a static main
		if(TypeTools.toString(Context.getLocalType()) == getMainClassName()){
			var type = asTypePath(getMainClassName());

			fields.push({
				name: MAIN,
				doc: null,
				access: [Access.APublic, Access.AStatic],
				kind: FieldType.FFun({
					params : [],
					args : [],
					expr: macro {
						js.Browser.document.addEventListener("DOMContentLoaded", function(event){
							js.Browser.document.body.appendChild(new $type().view);
						});
					},
					ret : macro : Void
				}),
				pos: Context.currentPos()});

			if(FileSystem.exists(styleResult))
				FileSystem.deleteFile(styleResult);
		}

		// if component has css, add it to result file
		if(styleFile != null){
			var cssContent:String = getFileContent(styleFile);

			if(!FileSystem.exists(styleResult)) // create file if it does not exist
				File.write(styleResult).close();
			
			var fileOutput:FileOutput = File.append(styleResult);
			fileOutput.writeString("/* Component " + className + " */\n");
			fileOutput.writeString(cssContent);
			fileOutput.writeString("\n");
			fileOutput.close();
		}

		return fields;
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

	static public function getFileContent(fileName:String):String {
		var classString:String = Context.getLocalClass().toString();

		var parts:Array<String> = classString.split(".");
		parts.pop();
		var path:String = parts.join("/");

		var p = Context.resolvePath(path + "/" + fileName);

		return sys.io.File.getContent(p);
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
