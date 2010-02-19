package net.onthewings.filters
{
	import flash.display.Shader;
	import flash.filters.ShaderFilter;

	public class ColorblindFilter extends ShaderFilter
	{
		[Embed(source="ColorBlind_Protanopia.pbj", mimeType="application/octet-stream")]
		private static var ProtanopiaByteCode:Class;
		
		[Embed(source="ColorBlind_Deuteranopia.pbj", mimeType="application/octet-stream")]
		private static var DeuteranopiaByteCode:Class;
		
		[Embed(source="ColorBlind_Tritanopia.pbj", mimeType="application/octet-stream")]
		private static var TritanopiaByteCode:Class;
		
		[Embed(source="ColorBlind_Dog.pbj", mimeType="application/octet-stream")]
		private static var DogByteCode:Class;
		
		public static var TYPE_PROTANOPIA:String = "Protanopia";
		public static var TYPE_DEUTERANOPIA:String = "Deuteranopia";
		public static var TYPE_TRITANOPIA:String = "Tritanopia";
		public static var TYPE_DOG:String = "Dog";
		
		public function ColorblindFilter(type:String):void
		{
			super(getShader(type));
			_type = type;
		}
		
		public function set type(val:String):void {
			if (_type == val) return;
			
			shader = getShader(val);
			_type = val;
		}
		
		public function get type():String {
			return _type;
		}
		
		private var _type:String;
		private static function getShader(type:String):Shader {
			var s:Shader;
			switch (type) {
				case TYPE_PROTANOPIA:
					s = new Shader(new ProtanopiaByteCode());
					break;
					
				case TYPE_DEUTERANOPIA:
					s = new Shader(new DeuteranopiaByteCode());
					break;
					
				case TYPE_TRITANOPIA:
					s = new Shader(new TritanopiaByteCode());
					break;
					
				case TYPE_DOG:
					s = new Shader(new DogByteCode());
					break;
			}
			return s;
		}
	}
}