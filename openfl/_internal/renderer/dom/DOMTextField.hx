package openfl._internal.renderer.dom;


import openfl._internal.renderer.RenderSession;
import openfl._internal.text.TextEngine;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.text.TextFormatAlign;

#if (js && html5)
import js.html.Element;
import js.Browser;
#end

@:access(openfl._internal.text.TextEngine)
@:access(openfl.text.TextField)


class DOMTextField {
	
	
	public static function measureText (textField:TextField):Void {
		
	 	#if (js && html5)
	 	
		var textEngine = textField.__textEngine;
		var div:Element = textField.__div;
		
		if (div == null) {
			
			div = cast Browser.document.createElement ("div");
			div.innerHTML = new EReg ("\n", "g").replace (textEngine.text, "<br>");
			div.style.setProperty ("font", TextEngine.getFont (textField.__textFormat), null);
			div.style.setProperty ("pointer-events", "none", null);
			div.style.position = "absolute";
			div.style.top = "110%"; // position off-screen!
			Browser.document.body.appendChild (div);
			
		}
		
		textEngine.__measuredWidth = div.clientWidth;
		
		// Now set the width so that the height is accurate as a
		// function of the flow within the width bounds...
		
		if (textField.__div == null) {
			
			div.style.width = Std.string (textEngine.width - 4) + "px";
			
		}
		
		textEngine.__measuredHeight = div.clientHeight;
		
		if (textField.__div == null) {
			
			Browser.document.body.removeChild (div);
			
		}
		
		#end
		
	}
	
	
	public static inline function render (textField:TextField, renderSession:RenderSession):Void {
		
		#if (js && html5)
		
		var textEngine = textField.__textEngine;
		
		if (textField.stage != null && textField.__worldVisible && textField.__renderable) {
			
			if (textField.__dirty || textField.__renderTransformChanged || textField.__div == null) {
				
				if (textEngine.text != "" || textEngine.background || textEngine.border || textEngine.type == INPUT) {
					
					if (textField.__div == null) {
						
						textField.__div = cast Browser.document.createElement ("div");
						DOMRenderer.initializeElement (textField, textField.__div, renderSession);
						textField.__style.setProperty ("outline", "none", null);
						
						textField.__div.addEventListener ("input", function (event) {
							
							event.preventDefault ();
							
							// TODO: Set caret index, and replace only selection
							
							if (textField.htmlText != textField.__div.innerHTML) {
								
								textField.htmlText = textField.__div.innerHTML;
								
								if (textField.__displayAsPassword) {
									
									// TODO: Enable display as password
									
								}
								
								textField.__dirty = false;
								
							}
							
						}, true);
						
					}
					
					if (!textEngine.wordWrap) {
						
						textField.__style.setProperty ("white-space", "nowrap", null);
						
					} else {
						
						textField.__style.setProperty ("word-wrap", "break-word", null);
						
					}
					
					textField.__style.setProperty ("overflow", "hidden", null);
					
					if (textEngine.selectable) {
						
						textField.__style.setProperty ("cursor", "text", null);
						textField.__style.setProperty ("-webkit-user-select", "text", null);
						textField.__style.setProperty ("-moz-user-select", "text", null);
						textField.__style.setProperty ("-ms-user-select", "text", null);
						textField.__style.setProperty ("-o-user-select", "text", null);
						
					} else {
						
						textField.__style.setProperty ("cursor", "inherit", null);
						
					}
					
					untyped (textField.__div).contentEditable = (textEngine.type == INPUT);
					
					var style = textField.__style;
					
					// TODO: Handle ranges using span
					// TODO: Vertical align
					
					//textField.__div.innerHTML = textEngine.text;
					textField.__div.innerHTML = new EReg ("\n", "g").replace (textEngine.text, "<br>");
					
					if (textEngine.background) {
						
						style.setProperty ("background-color", "#" + StringTools.hex (textEngine.backgroundColor & 0xFFFFFF, 6), null);
						
					} else {
						
						style.removeProperty ("background-color");
						
					}
					
					var w = textEngine.width;
					var h = textEngine.height;
					
					var t = textField.__renderTransform;
					if (t.a != 1.0 || t.d != 1.0) {
						
						var scale:Float;
						if (t.a == t.d) {
							scale = t.a;
							t.a = t.d = 1.0;
						} else if (t.a > t.d) {
							scale = t.a;
							t.d /= t.a;
							t.a = 1.0;
						} else {
							scale = t.d;
							t.a /= t.d;
							t.d = 1.0;
						}
						var realSize = textField.__textFormat.size;
						var scaledFontSize  : Float = realSize * scale;
						
					#if !openfl_dont_half_round_font_sizes
						
						var roundedFontSize = Math.fceil(scaledFontSize * 2) / 2;
						if (roundedFontSize > scaledFontSize) {
							
							var adjustment = (scaledFontSize / roundedFontSize);
							if (adjustment < 1 && (1 - adjustment) < 0.1) {
								t.a = 1;
								t.d = 1;
							} else {
								scale *= adjustment;
								t.a *= adjustment;
								t.d *= adjustment;
							}
							
						}
						untyped textField.__textFormat.size = roundedFontSize;
						
					#else
						
						untyped textField.__textFormat.size = scaledFontSize;
						
					#end
						
						w = Math.ceil(w * scale);
						h = Math.ceil(h * scale);
						
						style.setProperty ("font", TextEngine.getFont (textField.__textFormat), null);
						
						textField.__textFormat.size = realSize;
					
					} else {
						
						style.setProperty ("font", TextEngine.getFont (textField.__textFormat), null);
						
					}
					
					if (textEngine.border) {
						
						style.setProperty ("border", "solid 1px #" + StringTools.hex (textEngine.borderColor & 0xFFFFFF, 6), null);
						textField.__renderTransform.translate (-1, -1);
						textField.__renderTransformChanged = true;
						textField.__transformDirty = true;
						
					} else if (style.border != "") {
						
						style.removeProperty ("border");
						textField.__renderTransformChanged = true;
						
					}
					
					style.setProperty ("color", "#" + StringTools.hex (textField.__textFormat.color & 0xFFFFFF, 6), null);
					
					style.setProperty ("width",  w + "px", null);
					style.setProperty ("height", h + "px", null);
					
					switch (textField.__textFormat.align) {
						
						case TextFormatAlign.CENTER:
							
							style.setProperty ("text-align", "center", null);
						
						case TextFormatAlign.RIGHT:
							
							style.setProperty ("text-align", "right", null);
						
						default:
							
							style.setProperty ("text-align", "left", null);
						
					}
					
					textField.__dirty = false;
					
				} else {
					
					if (textField.__div != null) {
						
						renderSession.element.removeChild (textField.__div);
						textField.__div = null;
						
					}
					
				}
				
			}
			
			if (textField.__div != null) {
				
				DOMRenderer.updateClip (textField, renderSession);
				DOMRenderer.applyStyle (textField, renderSession, true, true, true);
				
			}
			
		} else {
			
			if (textField.__div != null) {
				
				renderSession.element.removeChild (textField.__div);
				textField.__div = null;
				textField.__style = null;
				
			}
			
		}
		
		#end
		
	}
	
	
}
