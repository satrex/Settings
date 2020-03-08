//
var RS = String.fromCharCode(30); // matched by Ruby
var IS_MAC = true; // reset by Ruby
var EXTN = false; // reset by Ruby
var listLeft = document.getElementById('selectLeft');
var listRight = document.getElementById('selectRight');
//
function sleep(milliSeconds){
    var d = new Date();
    var startTime = d.getTime();
	var d1 = new Date();
	var nowTime = d1.getTime();
	while (nowTime < startTime + milliSeconds) { 
		var d1 = new Date();
		var nowTime = d1.getTime(); 
	}
}

function swapSides(side){
	var listLeft = document.getElementById('selectLeft');
	var listRight = document.getElementById('selectRight');
	if(side == 1){
		if(listLeft.options.length == 0){
			return false;
		}else{
			var selectedIndex = listLeft.options.selectedIndex;
			if(selectedIndex < 0){
				return false;
			}else{
				disable();
				if(IS_MAC == true){sleep(50);}
				var selectedArrayI = new Array();
				var selectedArrayV = new Array();
				var selectedArrayT = new Array();
				var selObj = listLeft;
				var i;
				for (i=0; i<selObj.options.length; i++) {
					if (selObj.options[i].selected) {
						selectedArrayI.unshift(i);
						selectedArrayV.unshift(selObj.options[i].value);
						selectedArrayT.unshift(selObj.options[i].text);
					}
				}			  
				for (i=0; i<selectedArrayI.length; i++) {
					var valu=selectedArrayV[i];
					var text=selectedArrayT[i];
					moveSides(listRight, addEX(valu), text);
				}
				for (i=0; i<selectedArrayI.length; i++) {
					var indx=selectedArrayI[i];
					listLeft.remove(indx);
				}
				for (i=0; i<selectedArrayI.length; i++) {
					var valu=selectedArrayV[i];
					updaterR(selectRight, addEX(valu));
				}
			}
		}
	}else if(side == 2){
		if(listRight.options.length == 0){
			return false;
		}else{
			var selectedIndex = listRight.options.selectedIndex;
			if(selectedIndex < 0){
				return false;
			}else{
				enable();
				if(IS_MAC == true){sleep(50);}
				var selectedArrayI = new Array();
				var selectedArrayV = new Array();
				var selectedArrayT = new Array();
				var selObj = listRight;
				var i;
				for (i=0; i<selObj.options.length; i++) {
					if (selObj.options[i].selected) {
						selectedArrayI.unshift(i);
						selectedArrayV.unshift(selObj.options[i].value);
						selectedArrayT.unshift(selObj.options[i].text);
					}
				}			  
				for (i=0; i<selectedArrayI.length; i++) {
					var valu=selectedArrayV[i];
					var text=selectedArrayT[i];
					moveSides(listLeft, remEX(valu), text);
				}
				for (i=0; i<selectedArrayI.length; i++) {
					var indx=selectedArrayI[i];
					listRight.remove(indx);
				}
				for (i=0; i<selectedArrayI.length; i++) {
					var valu=selectedArrayV[i];
					updaterL(selectLeft, remEX(valu));
				}
			}
		}
	}else if(side == 0){
		if(listRight.options.length == 0){
			return false;
		}else{
			var selectedIndex = listRight.options.selectedIndex;
			if(selectedIndex < 0){
				return false;
			}else{
				load();
				if(IS_MAC == true){sleep(50);}
				var selectedArrayI = new Array();
				var selectedArrayV = new Array();
				var selectedArrayT = new Array();
				var selObj = listRight;
				var i;
				for (i=0; i<selObj.options.length; i++) {
					if (selObj.options[i].selected) {
						selectedArrayI.unshift(i);
						selectedArrayV.unshift(selObj.options[i].value);
						selectedArrayT.unshift(selObj.options[i].text);
					}
				}			  
				for (i=0; i<selectedArrayI.length; i++) {
					var valu=selectedArrayV[i];
					updaterC(selectRight, valu); //stays rb!
				}
				sortListBox(selectRight);
			}
		}
	}
}

function addEX(valu){
	if(EXTN==true){
		return valu;
	}else{
		return valu + '!';
	}
}

function remEX(valu){
	if(EXTN==true){
		return valu;
	}else{
		return valu.replace(/!$/,'');
	}
}

function moveSides(box, optionValue, optionDisplayText){
	var newOption = document.createElement("option");
	newOption.value = optionValue;
	newOption.text = optionDisplayText;
	box.add(newOption, box.options.length);
	sortListBox(box);
	return true;
}

function sortListBox(box) {
	// move all RED/GREEN to END of list and auto-scroll to it, if needed.
	box.options[box.options.length-1].selected=true;
	box.options[box.options.length-1].selected=false;
	box.options.selectedIndex=-1;
	//dodesc("");
	disableLR();
}

function mememe(box){
	var listLeft = document.getElementById('selectLeft');
	var listRight = document.getElementById('selectRight');
	disableLR();
	if(box.options.selectedIndex == -1 ){
		dodesc("");
		for (i=0; i<listRight.options.length; i++) {
			listRight.options[i].selected = false;
		}
		for (i=0; i<listLeft.options.length; i++) {
			listLeft.options[i].selected = false;
		}
		return false;
	}else{
		dodesc(box.options[box.options.selectedIndex].value);
		if(box == listLeft){
			for (i=0; i<listRight.options.length; i++) {
				listRight.options[i].selected = false;
			}
			listRight.options.selectedIndex = -1;
			disableL();
		}else if(box == listRight){
			for (i=0; i<listLeft.options.length; i++) {
				listLeft.options[i].selected = false;
			}
			listLeft.options.selectedIndex = -1;
			disableR();
		}
	}
}

function dodesc(p){
	if(EXTN==true){ // extension
		if(IS_MAC == true){sleep(50);}
		var po = p.replace(/!$/,'');
		var st = po;
		cmd = 'skp:dodesc@'+st;
		window.location = cmd;
		if(IS_MAC == true){sleep(10);}
	}else{ // plugin
		var po = p.replace(/x$/,'').replace(/!$/,'');
		var st = encodeURIComponent(po);
		document.getElementById('pdata').src='http://plugin.sketchucation.com/plugininfo.php?loader='+st;
	}
}

function updaterR(box, opt){
	recolor(box, opt, 'red');
}
function updaterL(box, opt){
	recolor(box, opt, 'green');
}
function updaterC(box, opt){
	recolor(box, opt, 'darkorange')
}
function recolor(box, opt, col){
	for(var i = 0; i < box.options.length; i++){
		if('x'+(box.options[i].value)+'x' == 'x'+opt+'x'){
			box.options[i].style.color = col;
		}
	}
}
function backcolor(box, opt, col){
	//col='gainsboro';
	for(var i = 0; i < box.options.length; i++){
		if('x'+(box.options[i].value)+'x' == 'x'+opt+'x'){
			box.options[i].style.backgroundColor = col;
		}
	}
}

function disable(){ 
	txt = setTXT();
	//alert(txt);
	cmd = 'skp:disable@' + txt;
	window.location = cmd;
	if(IS_MAC == true){sleep(50);}
}
function load(){
	txt = setTXTX();
	//alert(txt);
	cmd = 'skp:load@' + txt;
	window.location = cmd;
	if(IS_MAC == true){sleep(50);}
}
function enable(){
	txt = setTXTX();
	//alert(txt);
	cmd = 'skp:enable@' + txt;
	window.location = cmd;
	if(IS_MAC == true){sleep(50);}
}

function setTXT(){
	var listLeft = document.getElementById('selectLeft');
	var txt = '';
	for(var i = 0; i < listLeft.options.length; i++){
		if(listLeft.options[i].selected == true){
		//alert(listLeft.options[i].value);
			txt = txt + RS + (listLeft.options[i].value.replace(/^[#]/g, '|#'));
		//alert(txt);
		}
	}
	txt = txt.replace(/[']/g, '"');
	return txt;
}
function setTXTX(){
	var listRight = document.getElementById('selectRight');
	var txtx = '';
	for(var i = 0; i < listRight.options.length; i++){
		if(listRight.options[i].selected == true){
		//alert(listRight.options[i].value);
			txtx = txtx + RS + (listRight.options[i].value.replace(/^[#]/g, '|#'));
		//alert(txtx);
		}
	}
	txtx = txtx.replace(/[']/g, '"');
	return txtx;
}

function changeplugins(){
	var box = document.getElementById('pluginslist');
	var p = '';
	for(var i = 0; i < box.options.length; i++){
		if(box.options[i].selected == true){
			p = box.options[i].value;
		}
	}
	cmd = 'skp:changeplugins@' + p.replace(/[']/g, '"');
	window.location = cmd;	
	if(IS_MAC == true){sleep(50);}
}

function disableL(){
	enableLR();
	document.getElementById('btnL').disabled='disabled';
	document.getElementById('btnC').disabled='disabled';
}
function disableR(){
	enableLR();
	document.getElementById('btnR').disabled='disabled';
}
function enableLR(){
	document.getElementById('btnL').removeAttribute('disabled', 0);
	document.getElementById('btnC').removeAttribute('disabled', 0);
	document.getElementById('btnR').removeAttribute('disabled', 0);
}
function disableLR(){
	document.getElementById('btnL').disabled='disabled';
	document.getElementById('btnC').disabled='disabled';
	document.getElementById('btnR').disabled='disabled';
}

function xsets() {
	cmd = 'skp:xsets@';
	window.location = cmd;
	if(IS_MAC == true){sleep(50);}
}
function az09(obj) {
	var txt1 = obj.value;
	var txt2 = txt1.replace(/[^A-Za-z0-9.-_]/g, '_');
	obj.value = txt2;
}
function addset() {
	var box = document.getElementById('setlist');
	var p = document.getElementById('newtxt').value
	document.getElementById('newtxt').value=''
	cmd = 'skp:addset@'+p;
	window.location = cmd;
	box.options.selectedIndex=-1;
	if(IS_MAC == true){sleep(50);}
}
function applyset() {
	var box = document.getElementById('setlist');
	var p = '';
	for(var i = 0; i < box.options.length; i++){
		if(box.options[i].selected == true){
			p = box.options[i].value;
		}
	}
	cmd = 'skp:applyset@'+p;
	window.location = cmd;
	box.options.selectedIndex=-1;
	if(IS_MAC == true){sleep(50);}
}
function revertset() {
	var box = document.getElementById('setlist');
	cmd = 'skp:revertset@';
	window.location = cmd;
	box.options.selectedIndex=-1;
	if(IS_MAC == true){sleep(50);}
}
function updateset() {
	var box = document.getElementById('setlist');
	var p = '';
	for(var i = 0; i < box.options.length; i++){
		if(box.options[i].selected == true){
			p = box.options[i].value;
		}
	}
	cmd = 'skp:updateset@'+p;
	window.location = cmd;
	box.options.selectedIndex=-1;
	if(IS_MAC == true){sleep(50);}
}
function deleteset() {
	var box = document.getElementById('setlist');
	var p = '';
	for(var i = 0; i < box.options.length; i++){
		if(box.options[i].selected == true){
			p = box.options[i].value;
		}
	}
	cmd = 'skp:deleteset@'+p;
	window.location = cmd;
	box.options.selectedIndex=-1;
	if(IS_MAC == true){sleep(50);}
}
function exportset() {
	var box = document.getElementById('setlist');
	var p = '';
	for(var i = 0; i < box.options.length; i++){
		if(box.options[i].selected == true){
			p = box.options[i].value;
		}
	}
	cmd = 'skp:exportset@'+p;
	window.location = cmd;
	box.options.selectedIndex=-1;
	if(IS_MAC == true){sleep(50);}
}
function exportallsets() {
	var box = document.getElementById('setlist');
	cmd = 'skp:exportallsets@';
	window.location = cmd;
	box.options.selectedIndex=-1;
	if(IS_MAC == true){sleep(50);}
}
function importset() {
	var box = document.getElementById('setlist');
	cmd = 'skp:importset@';
	window.location = cmd;
	box.options.selectedIndex=-1;
	if(IS_MAC == true){sleep(50);}
}
function importallsets() {
	var box = document.getElementById('setlist');
	cmd = 'skp:importallsets@';
	window.location = cmd;
	box.options.selectedIndex=-1;
	if(IS_MAC == true){sleep(50);}
}

function chooseplugins() {
	document.getElementById('html').className = 'wait';
	var box = document.getElementById('pluginlist');
	var p = '';
	for(var i = 0; i < box.options.length; i++){
		if(box.options[i].selected == true){
			p = box.options[i].value;
		}
	}
	p=p.replace(/[']/g, '"');
	cmd = 'skp:chooseplugins@'+p;
	window.location = cmd;
	box.options.selectedIndex=-1;
	if(IS_MAC == true){sleep(50);}
}

function tidyup() {
	cmd = 'skp:tidyup@';
	window.location = cmd;
	if(IS_MAC == true){sleep(50);}
}

function checkSubmit(e) {
   if(e && e.keyCode == 13)
   {
      chooseplugins();
   }
}

function setList() {
	var box = document.getElementById('setlist');
	var p = box.selectedIndex;
	if(p < 0){
		document.getElementById('applybut').disabled='disabled';
		document.getElementById('revertbut').disabled='disabled';
		document.getElementById('updatebut').disabled='disabled';
		document.getElementById('deletebut').disabled='disabled';
		document.getElementById('exportbut').disabled='disabled';
	}
	else{
		document.getElementById('applybut').removeAttribute('disabled', 0);
		document.getElementById('revertbut').removeAttribute('disabled', 0);
		document.getElementById('updatebut').removeAttribute('disabled', 0);
		document.getElementById('deletebut').removeAttribute('disabled', 0);
		document.getElementById('exportbut').removeAttribute('disabled', 0);
	}
	if(box.options.length == 0){
		document.getElementById('exportallbut').disabled='disabled';
	}
	else{
		document.getElementById('exportallbut').removeAttribute('disabled', 0);
	}
}
//
function move_to_center() {
   window.location = "skp:move_to_center@" + screen.width + "," + screen.height + ":" + document.body.offsetWidth + "," + document.body.offsetHeight;
}
	  
