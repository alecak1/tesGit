<?xml version="1.0" encoding="utf-8"?>
<mx:Application xmlns:mx="http://www.adobe.com/2006/mxml"
	layout="absolute" alpha="1.0" backgroundGradientAlphas="[0,0,0,0]"
	creationComplete="init()">
 
<mx:Script>
	<![CDATA[
		import flash.external.ExternalInterface;
		import mx.events.SliderEvent;
 
		// bind the variables so that can be notified of value updates
        [Bindable] private var slideInterval:int;
        [Bindable] private var minSliderValue:int;
        [Bindable] private var maxSliderValue:int;
        [Bindable] private var sliderLabels:Array = new Array();
        [Bindable] private var sliderTickValues:Array = new Array();
        [Bindable] private var callbackFunction:String;
        private var startSliderValue:int;
        private var boundDomId:String;
 
		// method to be called immediately after component is created
		private function init():void {
 
			// set some values passed in from the Visualforce page
			startSliderValue = this.parameters.startSliderValue;
			minSliderValue = this.parameters.minSliderValue;
			maxSliderValue = this.parameters.maxSliderValue;
			slideInterval = this.parameters.slideInterval;
			// add the min & max as the slider labels
			sliderLabels.push(minSliderValue,maxSliderValue);
			// add the min & max as the slider values
			sliderTickValues.push(minSliderValue,maxSliderValue);
 
			// set name of the callback javascript function
			callbackFunction = this.parameters.callbackFunction;
			// set the id of the DOM element attached to the slider so we can reference it
			boundDomId = this.parameters.boundDomId;
 
			// set the values initially for the component
			mySlider.tickValues = sliderTickValues;
			mySlider.labels = sliderLabels;
			mySlider.value = startSliderValue;
 
			// set the background color of the flex component so it matches the page
			Application.application.setStyle("backgroundColor",this.parameters.bgColor ? this.parameters.bgColor : "#F3F3EC");
 
		}
 
		// notify the external interface that the slider was changed
		public function handleSliderChange(evt:SliderEvent):void {
			ExternalInterface.call(this.callbackFunction,evt.currentTarget.value,this.boundDomId);
		}
	]]>
</mx:Script>
 
<mx:HSlider
	id="mySlider"
	minimum="{minSliderValue}"
	maximum="{maxSliderValue}"
	snapInterval="{slideInterval}"
	tickValues="{sliderTickValues}"
	labels="{sliderLabels}"
	allowTrackClick="false"
	liveDragging="false"
	change="handleSliderChange(event)"/>
 
</mx:Application>