import flash.desktop.ClipboardFormats;
import flash.desktop.NativeApplication;
import flash.desktop.NativeDragManager;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.display.NativeMenu;
import flash.display.NativeMenuItem;
import flash.display.NativeWindow;
import flash.events.Event;
import flash.events.NativeDragEvent;
import flash.filesystem.File;
import flash.geom.Point;
import flash.net.URLRequest;

import mx.containers.Canvas;
import mx.controls.Alert;
import mx.events.ResizeEvent;

import net.onthewings.filters.ColorblindFilter;

private var workaroundFilterBug:Boolean = true;
private var filterCanvas:Canvas;
private var filterB:Bitmap;
private var filterBD:BitmapData;

private var loader:Loader;
private var file:File;

private var imgExtList:String = "*.jpg;*.gif;*.png";
private var swfExtList:String = "*.swf"
private var webpageExtList:String = "*.html;*.htm";
private var extList:String = imgExtList + ';' + webpageExtList + ';' + swfExtList; //the list of extensions we accept

private var cbFilter:ColorblindFilter;
private var types:Array = ["Normal vision", ColorblindFilter.TYPE_PROTANOPIA, ColorblindFilter.TYPE_DEUTERANOPIA, ColorblindFilter.TYPE_TRITANOPIA, ColorblindFilter.TYPE_DOG];

private var windowSizes:Vector.<String> = Vector.<String>(["800x600", "1024x768"]);

private var cbTypeMenu:NativeMenu;

private const SOURCE_URL:String = "http://github.com/andyli/Colorblink";

private function init():void {
	var menu:NativeMenu;
	if (NativeWindow.supportsMenu) {
		if (!this.nativeWindow.menu)
			this.nativeWindow.menu = new NativeMenu();

		menu = this.nativeWindow.menu;
	} else if (NativeApplication.supportsMenu) {
		if (!this.nativeApplication.menu)
			this.nativeApplication.menu = new NativeMenu();

		menu = this.nativeApplication.menu;
	}

	//create selection menu
	cbTypeMenu = new NativeMenu();
	for each (var type:String in types) {
		var menuItem:NativeMenuItem = new NativeMenuItem(type);
		menuItem.addEventListener(Event.SELECT, onMenuSelect);
		cbTypeMenu.addItem(menuItem);
	}
	menu.addSubmenu(cbTypeMenu, "simulate");

	var resizeMenu:NativeMenu = new NativeMenu();
	for each (type in windowSizes) {
		menuItem = new NativeMenuItem(type);
		menuItem.addEventListener(Event.SELECT, onResizeMenuSelect);
		resizeMenu.addItem(menuItem);
	}
	menu.addSubmenu(resizeMenu, "resize window");

	cbTypeMenu.items[0].checked = true; //check the "Normal vision" one as default

	//init the loader which loads the dropped file
	loader = new Loader();
	loader.visible = false;
	appHolder.rawChildren.addChild(loader);
	loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);

	//this is the filter to simulate color blind
	cbFilter = new ColorblindFilter(ColorblindFilter.TYPE_PROTANOPIA);
}

private function onCreationComplete():void {
	//start listening to native drag and drop
	this.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragEnter);
	this.addEventListener(NativeDragEvent.NATIVE_DRAG_EXIT, onDragExit);
	this.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDropBoxDragEnter);
	this.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDrop);

	if (workaroundFilterBug) {
		this.addEventListener(ResizeEvent.RESIZE, onResize);
		this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		filterCanvas = new Canvas();
		filterCanvas.visible = false;
		filterCanvas.mouseEnabled = false;
		filterCanvas.mouseChildren = false;
		this.addChild(filterCanvas);
	}

	realOnResize();
}

private function onResize(evt:ResizeEvent, force:Boolean = false):void {
	this.callLater(realOnResize);
}

private function realOnResize():void {
	if (filterB && filterB.parent) {
		filterB.parent.removeChild(filterB);
	}
	if (filterBD) {
		filterBD.dispose();
	}

	filterBD = new BitmapData(this.width, this.height, false);
	filterB = new Bitmap(filterBD);
	filterCanvas.rawChildren.addChild(filterB);
}

private function onEnterFrame(evt:Event):void {
	filterCanvas.visible = true;
	filterBD.lock();
	filterBD.draw(this);
	if (!cbTypeMenu.items[0].checked) {
		filterBD.applyFilter(filterBD, filterBD.rect, new Point(), cbFilter);
	}
	filterBD.unlock();
}

private function onMenuSelect(evt:Event):void {
	var menuItem:NativeMenuItem;

	//uncheck all meun items
	for each (menuItem in cbTypeMenu.items) {
		menuItem.checked = false;
	}

	//check the current one
	menuItem = evt.target as NativeMenuItem;
	menuItem.checked = true;

	if (menuItem.label == types[0]) {
		appHolder.filters = []; //Normal vision means no filter.
	} else {
		//set the color blind type and apply it
		cbFilter.type = menuItem.label;

		if (!workaroundFilterBug) {
			appHolder.filters = [cbFilter];
		}
	}
}

private function onResizeMenuSelect(evt:Event):void {
	var menuItem:NativeMenuItem = evt.target as NativeMenuItem;
	var size:Array = menuItem.label.split('x');
	resizeWindowTo(size[0], size[1], false);
}

private function onDropBoxDragEnter(evt:NativeDragEvent):void {
	if (evt.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT)) {
		//get the first file, ignore the rest
		var file:File = evt.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0];

		if (isAcceptableExt(file.extension, extList))
			NativeDragManager.acceptDragDrop(this);
	}
}

private function onDragEnter(evt:NativeDragEvent):void {
	dropBox.visible = true;
	if (evt.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT)) {
		//get the first file, ignore the rest
		var file:File = evt.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0];

		if (isAcceptableExt(file.extension, extList)) {
			dropBoxText.text = "Drop " + file.name + " here to open.";
		} else {
			dropBoxText.text = "Can't reconize" + file.name + "...";
		}
	}
}

private function onDragExit(evt:NativeDragEvent):void {
	dropBox.visible = false;
}

private function onDrop(evt:NativeDragEvent):void {
	if (loader.content)
		loader.unloadAndStop();
		
	//remove the info box
	if (infoBox.parent)
		this.removeChild(infoBox);

	//get the first file, ignore the rest
	file = evt.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0];
	if (isAcceptableExt(file.extension, webpageExtList)) {
		htmlHolder.location = file.url;
		loader.visible = false;
		htmlHolder.visible = true;
	} else {
		//load it
		loader.load(new URLRequest(file.url));
	}
}

private function resizeWindowTo(width:Number, height:Number, includeBorder:Boolean = true):void {
	if (includeBorder) {
		//resize the window according to the loaded content
		this.nativeWindow.width = width;
		this.nativeWindow.height = height;
	} else {
		//calculate how much the window border consumes
		var wAdd:Number = this.nativeWindow.width - this.systemManager.stage.stageWidth;
		var hAdd:Number = this.nativeWindow.height - this.systemManager.stage.stageHeight;

		resizeWindowTo(width + wAdd, height + hAdd);
	}
}

private function onLoadComplete(evt:Event):void {
	resizeWindowTo(loader.contentLoaderInfo.width, loader.contentLoaderInfo.height, false);

	if (isAcceptableExt(file.extension, swfExtList)) {
		loader.unloadAndStop();
		htmlHolder.location = "/swfHolder/index.html?" + escape(file.url);
		loader.visible = false;
		htmlHolder.visible = true;
	} else if (isAcceptableExt(file.extension, imgExtList)) {
		loader.visible = true;
		htmlHolder.visible = false;
	}
}

//return if the extension is acceptable
private function isAcceptableExt(ext:String, extList:String):Boolean {
	if (!ext || ext.length <= 0)
		return false;

	var extAry:Array = extList.split(';');
	var lowerExt:String = ext.toLowerCase();
	for each (var aext:String in extAry) {
		if (aext.substr(2) == lowerExt)
			return true;
	}
	return false;
}

private function onDomDragOver(e:*):void {
	//e.preventDefault();
	Alert.show("here");
	NativeDragManager.acceptDragDrop(this);
}