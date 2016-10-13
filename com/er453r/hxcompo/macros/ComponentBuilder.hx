package com.er453r.hxcompo.macros;

import haxe.macro.TypeTools;
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
		var simpleName:String = MacroUtils.getClassName();
		var viewFile:String = MacroUtils.getMeta(VIEW_ANNOTATION);
		var styleFile:String = MacroUtils.getMeta(STYLE_ANNOTATION);

		var styleResult:String = "style.css";

		// set defaukt names
		if(viewFile == null)
			viewFile = '${simpleName}.htm';

		if(styleFile == null)
			styleFile = '${simpleName}.css';

		if(!MacroUtils.contextFileExists(viewFile))
			Context.error('Class ${simpleName} does not define its view (or the default one "${simpleName}.htm")', Context.currentPos());

		var viewContent:String = MacroUtils.parseHTML(viewFile);

		var fields:Array<Field> = Context.getBuildFields();

		if(MacroUtils.getField(NEW, fields) == null){ // if there is no constructor, create an empty one
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
		switch(MacroUtils.getField(NEW, fields).kind){
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
		if(TypeTools.toString(Context.getLocalType()) == MacroUtils.getMainClassName()){
			var type = MacroUtils.asTypePath(MacroUtils.getMainClassName());

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
		if(MacroUtils.contextFileExists(styleFile)){
			var cssContent:String = MacroUtils.getFileContent(styleFile);

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
}
