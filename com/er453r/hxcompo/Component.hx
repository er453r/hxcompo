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
	public var view(default, null):Element;

	private static var static_init = {
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

	private function append(component:Component):Void{
		find(CONTENT_SELECTOR).appendChild(component.view);
	}

	private function remove(component:Component):Void{
		component.view.remove();
	}

	private function dispatch(type:String, data:Dynamic):Void{
		var event:CustomEvent = new CustomEvent(type);

		event.initCustomEvent(type, true, true, data);

		view.dispatchEvent(event);
	}

	private function listen(type:String, listener:CustomEvent->Void):Void{
		view.addEventListener(type, listener);
	}
#end
}
