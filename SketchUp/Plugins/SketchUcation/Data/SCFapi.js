//
jQuery.support.cors = true;
//
// https://github.com/mattfawcett/form-data-compatibility
// (c) Matthew Fawcett & Ignacio M Bataller 2013
window.FormDataCompatibility = (function() {

  function FormDataCompatibility(form) {
    this.fields = {};
    this.boundary = this.generateBoundary();
    this.contentType = "multipart/form-data; boundary=" + this.boundary;
    this.CRLF = "\r\n";
    if (typeof form !== 'undefined') {
      for (var i = 0; i < form.elements.length; i++) {
        var e = form.elements[i];
		// If not set, the element's name is auto-generated
        var name = (e.name !== null && e.name !== '') ? e.name : this.getElementNameByIndex(i);
        this.append(name, e);
      }
    }
  }

  FormDataCompatibility.prototype.getElementNameByIndex = function(index) {
    return '___form_element__' + index;	// Strange enough to avoid collision with user-defined names
  }

  FormDataCompatibility.prototype.append = function(key, value) {
    return this.fields[key] = value;
  };

  FormDataCompatibility.prototype.setContentTypeHeader = function(xhr) {
    return xhr.setRequestHeader("Content-Type", this.contentType);
  };

  FormDataCompatibility.prototype.getContentType = function() {
    return this.contentType;
  };

  FormDataCompatibility.prototype.generateBoundary = function() {
    return "AJAX--------------" + ((new Date).getTime());
  };

  FormDataCompatibility.prototype.buildBody = function() {
    var body, key, parts, value, _ref;
    parts = [];
    _ref = this.fields;
    for (key in _ref) {
      value = _ref[key];
      parts.push(this.buildPart(key, value));
    }
    body = "--" + this.boundary + this.CRLF;
    body += parts.join("--" + this.boundary + this.CRLF);
    body += "--" + this.boundary + "--" + this.CRLF;
    return body;
  };

  FormDataCompatibility.prototype.buildPart = function(key, value) {
    var part;
    if (typeof value === "string") {
      part = "Content-Disposition: form-data; name=\"" + key + "\"" + this.CRLF;
      part += "Content-Type: text/plain; charset=utf-8" + this.CRLF + this.CRLF;
      part += unescape(encodeURIComponent(value)) + this.CRLF;	// UTF-8 encoded like in real FormData
    } else if (typeof value === typeof File) {
        part = "Content-Disposition: form-data; name=\"" + key + "\"; filename=\"" + value.fileName + "\"" + this.CRLF;
        part += "Content-Type: " + value.type + this.CRLF + this.CRLF;
        part += value.getAsBinary() + this.CRLF;
    } else if (typeof value === typeof HTMLInputElement) {
      if (value.type == 'file') {
        // Unsupported
      } else {
        part = "Content-Disposition: form-data; name=\"" + key + "\"" + this.CRLF;
        part += "Content-Type: text/plain; charset=utf-8" + this.CRLF + this.CRLF;
        part += unescape(encodeURIComponent(value.value)) + this.CRLF;	// UTF-8 encoded like in real FormData
      }
    }
    return part;
  };

  return FormDataCompatibility;

})();
//
// SCFapi code (c) SketchUcation 2014
function getter(apicall) {
	//
	var data = {};
	var split = apicall.split('?');
	var url = split[0];
	var dat = split[1];
	var calls = dat.split('&');
	var key = '';
	var val = '';
	for (i in calls) {
		split = calls[i].split('=');
		key = split[0];
		val = split[1];
		data[key] = val;
	}
	//
	$.ajax({
		type: 'GET', 
		url : url, 
		contentType: "application/json; charset=utf-8", 
		dataType: 'json', 
		data : data, 
		crossDomain: true, 
		timeout: 10000, 
		success: function(resp) {
			var cmd = 'skp:get_callback@' + resp;
			window.location = cmd;
			//alert(resp);
			return resp;
		}, 
		error: function (jqXHR, textStatus, errorThrown) {
			var txt = errorThrown+'.. '+textStatus;
			var cmd = 'skp:get_callback@' + txt;
			window.location = cmd;
		}
	});
}
//
function poster(apicall) {
	//
	var split = apicall.split('?');
	var url = split[0];
	//
	xhr = new XMLHttpRequest();
	xhr.onreadystatechange = function(){
		if (xhr.readyState == 4){
			var cmd = 'skp:post_callback@' + 'true';
			window.location = cmd;
		}
	};
	xhr.open("POST", url, true);
	//
	if(typeof(FormData) == 'undefined'){
		// This browser does not have native FormData support. 
		// Use the FormDataCompatibility class which implements 
		// the needed fuctionality for building multi-part HTTP POST requests
		var formdata = new FormDataCompatibility();
	} else {
		var formdata = new FormData();
	}
	// setup data
	var dat = split.slice(1).join('?')
	var calls = dat.split('&');
	var key = '';
	var val = '';
	for (i in calls) {
		split = calls[i].split('=');
		key = split[0];
		val = split[1];
		formdata.append(key, val);
	}
	//
	if(typeof(FormData) == 'undefined'){
		// This browser does not have native FormData support so manually 
		// set the multi-part header and use the sendAsBinary function to 
		// send a string of the POST body
		try
			{
				formdata.setContentTypeHeader(xhr);
				xhr.sendAsBinary(formdata.buildBody());
			}
		catch(err)
			{
				// if POST fails we have to GET it !
				post2get(apicall);
				return;
			}
	} else {
		// This browser has native FormData support so just call send with the FormData
		// and let the browser construct the POST
		xhr.send(formdata);
	}
}
//
function post2get(apicall) {
	//
	var data = {};
	var split = apicall.split('?');
	var url = split[0];
	var dat = split[1];
	var calls = dat.split('&');
	var key = '';
	var val = '';
	for (i in calls) {
		split = calls[i].split('=');
		key = split[0];
		val = split[1];
		data[key] = val;
	}
	//
	$.ajax({
		type: 'GET', 
		url : url, 
		contentType: "application/json; charset=utf-8", 
		dataType: 'json', 
		data : data, 
		crossDomain: true, 
		timeout: 10000, 
		success: function(resp) {
			var cmd = 'skp:post_callback@' + 'true';
			window.location = cmd;
		}, 
		error: function (jqXHR, textStatus, errorThrown) {
			var txt = errorThrown+'.. '+textStatus;
			var cmd = 'skp:post_callback@' + txt;
			window.location = cmd;
		}
	});
}
//