package com.er453r.hxcompo;

#if js
import js.html.Element;
import js.Browser;
import js.html.CustomEvent;
import js.html.Event;
#end

@:autoBuild(com.er453r.hxcompo.macros.ComponentBuilder.build())
class Component {
	private static inline var CONTENT_SELECTOR:String = "*[data-content]";
#if js
	private var viewElement:Element;

	private static var static_init = {
		[].iterator(); // hack to enable iterator on array after compilation
	};

	private function buildFromString(html:String):Void{
		var template:TemplateElement = cast Browser.document.createElement("template");

		template.innerHTML = html;

		viewElement = cast template.content.firstChild;
	}

	private function find(selector:String):Element{
		return viewElement.querySelector(selector);
	}

	private function appendTo(selector:String, element:Element):Void{
		find(selector).appendChild(element);
	}

	private function append(component:Component):Void{
		find(CONTENT_SELECTOR).appendChild(component.viewElement);
	}

	private function remove(component:Component):Void{
		component.viewElement.remove();
	}

	private function clear():Void{
		var node:Element = find(CONTENT_SELECTOR);

		while(node.firstChild != null)
			node.removeChild(node.firstChild);
	}

	private function dispatch<T>(type:String, data:T):Void{
		var event:CustomEvent = new CustomEvent(type);

		event.initCustomEvent(type, true, true, data);

		viewElement.dispatchEvent(event);
	}

	private function listen<T>(type:String, listener:T->Void):Void{
		viewElement.addEventListener(type, function(event:CustomEvent){
			listener(event.detail);
		});
	}
#end
}
