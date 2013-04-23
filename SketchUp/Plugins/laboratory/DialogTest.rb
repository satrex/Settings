require 'Sketchup'

def show_dialog
  dlg = UI::WebDialog.new("DialogTest", false,
   "DialogTest", 200, 150, 150, 150, true);
  html = <<-HTML
  <html>
  <head>
  <script type="text/javascript">
  <!--
    function doubleAlert()
    {
        jsAlert();
        rubyAlert();
    }

    function rubyAlert()
    {
       // ruby経由でメッセージボックスを呼ぶ
       window.location.href="skp:ruby_messagebox@Hello World";
    }

    function jsAlert()
    {
        // javascript経由でメッセージボックスを呼ぶ
        window.alert('alert from javascript');
    }
   -->
    </script>
</head>
<body>
    <form>
      <!--buttonエレメントからは、window.locationが指定できないので、rubyスクリプトは呼べない-->
      <button id="start" onclick="doubleAlert()">button</button>
      </br>
      <!--inputエレメントからは、window.locationが指定できるので、rubyスクリプトが呼べる-->
      <input id="start2" onClick="doubleAlert()" type="button" size="100" value="input">    
      </br>
      <!--リンクからは、urlが指定できるので、rubyスクリプトが呼べる-->
      <a href="javascript:doubleAlert();">link</a>
    </form>
    </html>
  HTML
  
  dlg.set_html html
  dlg.add_action_callback("ruby_messagebox") {|dialog, params|
    UI.messagebox("You called ruby_messagebox with: " + params.to_s)
  }
  dlg.show
end

show_dialog

