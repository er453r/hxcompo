package com.er453r.hxcompo;

#if js
import js.html.Element;
import js.Browser;
#end

@:autoBuild(com.er453r.hxcompo.macros.ComponentBuilder.build())
class Component {
	private static inline var CONTENT_SELECTOR:String = "*[data-content]";
#if js
	public var view(default, null):Element;

	static var static_init = {
		[].iterator(); // hack to enable iterator on array after compilation
	};

	private function buildFromString(html:String):Void{
		var template:TemplateElement = cast Browser.document.createElement("template");

		template.innerHTML = html;

		view = cast template.content.firstChild;
	}

	private function find(selector:String):Element{
		return view.querySelector(selector);
	}

	private function appendTo(selector:String, element:Element):Void{
		find(selector).appendChild(element);
	}

	public function append(component:Component):Void{
		find(CONTENT_SELECTOR).appendChild(component.view);
	}

	public function remove(component:Component):Void{
		component.view.remove();
	}
#end
}
