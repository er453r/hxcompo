package com.er453r.hxcompo.macros;

import haxe.macro.TypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;

import sys.FileSystem;
import sys.io.File;
import sys.io.FileOutput;

class ComponentBuilder {
	private static inline var CONTENTS:String = "contents";
	private static inline var ID_ATTR:String = "data-id";
	private static inline var TEMPLATE_ATTR:String = "data-template";
	private static inline var TEMPLATE_ID_ATTR:String = "data-template-id";
	private static inline var TEMPLATE_VARIABLE:String = "componentTemplate";
	private static inline var SETTER_PREFIX:String = "set_";
	private static inline var NEW:String = "new";
	private static inline var MAIN:String = "main";
	private static inline var CSS_FILE:String = "css";

	private static inline var VIEW_ANNOTATION:String = ":view";
	private static inline var STYLE_ANNOTATION:String = ":style";

	public static function build():Array<Field> {
		var className:String = TypeTools.toString(Context.getLocalType());
		var simpleName:String = MacroUtils.getClassName();
		var viewFile:String = MacroUtils.getMeta(VIEW_ANNOTATION);
		var styleFile:String = MacroUtils.getMeta(STYLE_ANNOTATION);
		var styleResult:String = "" + Context.getDefines().get(CSS_FILE);

		// set defaukt names
		if(viewFile == null)
			viewFile = '${simpleName}.htm';

		if(styleFile == null)
			styleFile = '${simpleName}.css';

		if(!MacroUtils.contextFileExists(viewFile))
			Context.error('Class ${simpleName} does not define its view (or the default one "${simpleName}.htm")', Context.currentPos());

		var viewHtml:Xml = MacroUtils.parseHTML(viewFile);

		var fields:Array<Field> = Context.getBuildFields();

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

			if(styleResult != null && FileSystem.exists(styleResult))
				FileSystem.deleteFile(styleResult);
		}

		// if component has css, add it to result file
		if(styleResult != null && MacroUtils.contextFileExists(styleFile)){
			var cssContent:String = MacroUtils.getFileContent(styleFile);

			if(!FileSystem.exists(styleResult)) // create file if it does not exist
				File.write(styleResult).close();

			var fileOutput:FileOutput = File.append(styleResult);
			fileOutput.writeString("/* Component " + className + " */\n");
			fileOutput.writeString(cssContent);
			fileOutput.writeString("\n");
			fileOutput.close();
		}

		// create fields for elements with ids
		var nodes:Array<Xml> = MacroUtils.findNodesWithAttr(viewHtml, ID_ATTR);
		var exprs:Array<Expr> = [];

		for(node in nodes){
			var id:String = node.get(ID_ATTR);
			var tagName:String = node.nodeName;

			var type = MacroUtils.asComplexType(MacroUtils.tagNameToClassName(tagName));

			fields.push({
				name: id,
				doc: null,
				access: [Access.APrivate],
				kind: FieldType.FVar(macro:$type, macro $v{null}),
				pos: Context.currentPos()
			});

			// if not root, then lookm if root assing view
			if(node.parent.parent != null)
				exprs.push(macro this.$id = cast find('*[${ID_ATTR}=${id}]'));
			else
				exprs.push(macro this.$id = cast this.view);
		}

		// create templates for elements with templates
		var nodes:Array<Xml> = MacroUtils.findNodesWithAttr(viewHtml, TEMPLATE_ATTR);
		var templateCounter:UInt = 0;

		for(node in nodes){
			if(MacroUtils.nodeChildren(node).length != 1)
				Context.error('Node ${node.nodeName} with template has to contain only 1 comment block', Context.currentPos());

			var comment:Xml = MacroUtils.nodeChildren(node).pop();

			if(comment.nodeType != Xml.Comment)
				Context.error('Node ${node.nodeName} with template has to contain only 1 comment block', Context.currentPos());

			var variable:String = node.get(TEMPLATE_ATTR);
			var template:String = comment.nodeValue;

			node.removeChild(comment);

			var templateFieldName:String = TEMPLATE_VARIABLE + templateCounter;

			node.set(TEMPLATE_ID_ATTR, templateFieldName);

			fields.push({
				name: templateFieldName,
				doc: null,
				access: [Access.APrivate],
				kind: FieldType.FVar(macro:haxe.Template, macro {new haxe.Template('${template}');}),
				pos: Context.currentPos()
			});

			if(MacroUtils.getField(variable, fields) == null)
				Context.error('Class ${className} does not contain variable "${variable}" required for a template', Context.currentPos());

			if(MacroUtils.getField(SETTER_PREFIX + variable, fields) == null)
				Context.error('Class ${className} does not contain setter for variable "${variable}" required for a template', Context.currentPos());

			// inject code to setter
			switch(MacroUtils.getField(SETTER_PREFIX + variable, fields).kind){
				case FFun(func):{
					func.expr = macro {
						find('${node.nodeName}[${TEMPLATE_ID_ATTR}=${templateFieldName}]').innerHTML = $i{templateFieldName}.execute({$variable: $i{func.args[0].name}});
						${func.expr};
					};
				}

				default: {}
			}

			templateCounter++;
		}

		// if there is no constructor, create an empty one
		if(MacroUtils.getField(NEW, fields) == null){
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
					$b{exprs};
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
			kind: FieldType.FVar(macro:String, macro $v{viewHtml.toString()}),
			pos: Context.currentPos()
		});

		return fields;
	}
}
