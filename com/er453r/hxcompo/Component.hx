package com.er453r.hxcompo;

import js.html.Element;
import js.html.MouseEvent;
import js.html.WheelEvent;
import js.html.Event;
import js.Browser;
import js.html.CustomEvent;

@:autoBuild(com.er453r.hxcompo.macros.ComponentBuilder.build())
class Component {
	private static inline var CONTENT_SELECTOR:String = "*[data-content]";

	private var viewElement:Element;

	static function __init__(){
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

	private function append(?component:Component, ?element:Element):Void{
		if(component != null){
			find(CONTENT_SELECTOR).appendChild(component.viewElement);

			component.onAddedToParent(this);
		}

		if(element != null)
			find(CONTENT_SELECTOR).appendChild(element);
	}

	private function remove(component:Component):Void{
		component.viewElement.remove();
	}

	private function onAddedToParent(parent:Component):Void{

	}

	private function clear():Void{
		var node:Element = find(CONTENT_SELECTOR);

		while(node.firstChild != null)
			node.removeChild(node.firstChild);
	}

	private function dispatch<T>(type:String, ?data:T):Void{
		var event:CustomEvent = new CustomEvent(type);

		event.initCustomEvent(type, true, true, data);

		viewElement.dispatchEvent(event);
	}

	private function delegate<T>(type:String, selector:String, ?mouseListener:Element->MouseEvent->Void, ?listener:Element->T->Void, ?listenerVoid:Element->Void):Void{
		viewElement.addEventListener(type, function(event:Event){
			var element:Element = cast event.target;

			while(element != null){
				if(element == this.viewElement) // break on self
					return;

				if(element.matches(selector)){
					if(mouseListener != null)
						mouseListener(element, cast event);

					if(listener != null){
						var customEvent:CustomEvent = cast event;

						listener(element, customEvent.detail);
					}

					if(listenerVoid != null)
						listenerVoid(element);

					return;
				}

				element = element.parentElement;
			}
		});
	}

	private function listen<T>(type:String, ?mouseListener:MouseEvent->Void, ?wheelListener:WheelEvent->Void, ?listener:T->Void, ?listenerVoid:Void->Void):Void{
		if(mouseListener != null)
			viewElement.addEventListener(type, mouseListener);

		if(wheelListener != null)
			viewElement.addEventListener(type, wheelListener);

		if(listener != null){
			viewElement.addEventListener(type, function(event:CustomEvent){
				listener(event.detail);
			});
		}

		if(listenerVoid != null){
			viewElement.addEventListener(type, function(event:CustomEvent){
				listenerVoid();
			});
		}
	}
}
