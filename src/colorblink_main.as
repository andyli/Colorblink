import flash.desktop.ClipboardFormats;
import flash.desktop.NativeApplication;
import flash.desktop.NativeDragManager;
import flash.display.Loader;
import flash.display.NativeMenu;
import flash.display.NativeMenuItem;
import flash.display.NativeWindow;
import flash.events.Event;
import flash.events.NativeDragEvent;
import flash.filesystem.File;
import flash.net.URLRequest;

import mx.controls.Alert;
import mx.core.Application;
import mx.managers.SystemManager;

import net.onthewings.filters.ColorblindFilter;

private var loader:Loader;
private var extList:String = "*.jpg;*.gif;*.png;*.swf"; //the list of extensions we accept

private var cbFilter:ColorblindFilter;
private var types:Array = ["Normal vision", ColorblindFilter.TYPE_PROTANOPIA, ColorblindFilter.TYPE_DEUTERANOPIA, ColorblindFilter.TYPE_TRITANOPIA, ColorblindFilter.TYPE_DOG];

private var cbTypeMenu:NativeMenu;

private const SOURCE_URL:String = "http://github.com/andyli/Colorblink";

private function init():void {
	//create the selection menu
	cbTypeMenu = new NativeMenu();
	for each (var type:String in types) {
		var menuItem:NativeMenuItem = new NativeMenuItem(type);
		menuItem.addEventListener(Event.SELECT, onMenuSelect);
		cbTypeMenu.addItem(menuItem);
	}
	if (NativeWindow.supportsMenu) {
		if (!this.nativeWindow.menu)
			this.nativeWindow.menu = new NativeMenu();

		this.nativeWindow.menu.addSubmenu(cbTypeMenu, "simulate");
	} else if (NativeApplication.supportsMenu) {
		if (!this.nativeApplication.menu)
			this.nativeApplication.menu = new NativeMenu();

		this.nativeApplication.menu.addSubmenu(cbTypeMenu, "simulate");
	}

	cbTypeMenu.items[0].checked = true; //check the "Normal vision" one as default

	//init the loader which loads the dropped file
	loader = new Loader();
	this.rawChildren.addChild(loader);
	loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoadComplete);

	//this is the filter to simulate color blind
	cbFilter = new ColorblindFilter(ColorblindFilter.TYPE_PROTANOPIA);

	//start listening to native drag and drop
	this.systemManager.stage.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, onDragEnter);
	this.systemManager.stage.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, onDrop);

	//start listening to resize
	this.systemManager.stage.addEventListener(Event.RESIZE, onResize);
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
		filters = []; //Normal vision means no filter.
	} else {
		//set the color blind type and apply it
		cbFilter.type = menuItem.label;
		filters = [cbFilter];
	}
}

private function onDragEnter(evt:NativeDragEvent):void {
	if (evt.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT)) {
		//get the first file, ignore the rest
		var file:File = evt.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0];
		
		if (isAcceptableExt(file.extension))
			NativeDragManager.acceptDragDrop(this.systemManager.stage);
	}
}

private function onDrop(evt:NativeDragEvent):void {
	if (loader.content)
		loader.unloadAndStop();
	
	//get the first file, ignore the rest
	var file:File = evt.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0];
	
	//load it
	loader.load(new URLRequest(file.url));
}

private function onLoadComplete(evt:Event):void {
	//calculate how much the window border consumes
	var wAdd:Number = this.nativeWindow.width - this.systemManager.stage.stageWidth;
	var hAdd:Number = this.nativeWindow.height - this.systemManager.stage.stageHeight;

	//resize the window according to the loaded content
	this.nativeWindow.width = loader.contentLoaderInfo.width + wAdd;
	this.nativeWindow.height = loader.contentLoaderInfo.height + hAdd;


	//remove the info box
	if (infoBox.parent)
		this.removeChild(infoBox);
}

//return if the extension is acceptable
private function isAcceptableExt(ext:String):Boolean {
	var extAry:Array = extList.split(';');
	var lowerExt:String = ext.toLowerCase();
	for each (var aext:String in extAry) {
		if (aext.substr(2) == lowerExt)
			return true;
	}
	return false;
}

private function onResize(evt:Event):void {
	this.callLater(resizeLoader);
}

private function resizeLoader():void {
	loader.width = this.systemManager.stage.stageWidth;
	loader.height = this.systemManager.stage.stageHeight;
}