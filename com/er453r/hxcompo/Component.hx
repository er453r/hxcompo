package com.er453r.hxcompo;

import js.html.Element;
import js.html.TouchEvent;
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

	private function buildFromString(html:String){
		var template:TemplateElement = cast Browser.document.createElement("template");

		template.innerHTML = html;

		viewElement = cast template.content.firstChild;
	}

	private function find(selector:String):Element{
		return viewElement.querySelector(selector);
	}

	private function append(?component:Component, ?element:Element){
		if(component != null)
			find(CONTENT_SELECTOR).appendChild(component.viewElement);

		if(element != null)
			find(CONTENT_SELECTOR).appendChild(element);
	}

	private function remove(){
		this.viewElement.remove();
	}

	private function clear(){
		var node:Element = find(CONTENT_SELECTOR);

		if(node == null)
			return;

		while(node.firstChild != null)
			node.removeChild(node.firstChild);
	}

	private function dispatch<T>(type:String, ?data:T){
		var event:CustomEvent = new CustomEvent(type);

		event.initCustomEvent(type, true, true, data);

		viewElement.dispatchEvent(event);
	}

	private function on<T>(selector:String, ?type:String,
						   ?onMouse:MouseEvent->Void, ?onTouch:TouchEvent->Void, ?onWheel:WheelEvent->Void,
						   ?onMouseElement:Element->MouseEvent->Void, ?onTouchElement:Element->TouchEvent->Void, ?onWheelElement:Element->WheelEvent->Void,
						   ?onCustomElement:Element->T->Void, ?onVoidElement:Element->Void,
						   ?onCustom:T->Void, ?onVoid:Void->Void){
		if(type == null){ // attach listener to self
			type = selector;

			if(onMouse != null)
				viewElement.addEventListener(type, onMouse);

			if(onTouch != null)
				viewElement.addEventListener(type, onTouch);

			if(onWheel != null)
				viewElement.addEventListener(type, onWheel);

			if(onVoid != null)
				viewElement.addEventListener(type, onVoid);

			if(onCustom != null){
				viewElement.addEventListener(type, function(event:CustomEvent){
					onCustom(event.detail);
				});
			}
		}
		else{ // delegate
			viewElement.addEventListener(type, function(event:Event){
				var element:Element = cast event.target;

				while(element != null){
					if(element.matches(selector)){
						if(onMouseElement != null)
							onMouseElement(element, cast event);

						if(onTouchElement != null)
							onTouchElement(element, cast event);

						if(onWheelElement != null)
							onWheelElement(element, cast event);

						if(onVoidElement != null)
							onVoidElement(element);

						if(onCustomElement != null){
							var customEvent:CustomEvent = cast event;

							onCustomElement(element, customEvent.detail);
						}

						return;
					}

					if(element == this.viewElement) // break on self
						return;

					element = element.parentElement;
				}
			});
		}
	}
}
