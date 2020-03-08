# wxSU
# Copyright (c) 2008 Midwest Research Institute/National Renewable Energy Laboratory
# All rights reserved.  See the file "License.txt" for additional terms and conditions.
include Wx


class ChildFrame < Wx::Frame

  def onCharadded(evt)
    chr =  evt.get_key
    curr_line = @sci.get_current_line

    if(chr == 13)
        if curr_line > 0
          line_ind = @sci.get_line_indentation(curr_line - 1)
          if line_ind > 0
            @sci.set_line_indentation(curr_line, line_ind)
            @sci.goto_pos(@sci.position_from_line(curr_line)+line_ind)
          end
        end
    end
  end

  def onMarginClick(evt)
    line_num = @sci.line_from_position(evt.get_position)
    margin = evt.get_margin

    if(margin == 1)
      @sci.toggle_fold(line_num)
    end
  end

  def initialize(title = "SketchUp", position = Wx::DEFAULT_POSITION, size = Wx::DEFAULT_SIZE, resize = true)
    if (resize)
      style = WxSU::CHILD_FRAME_STYLE | Wx::RESIZE_BORDER
    else
      style = WxSU::CHILD_FRAME_STYLE
    end
    super(WxSU.app.sketchup_frame, -1, title, Wx::Point.new(150, 50), size, style)

    #Wx::init_all_image_handlers()
    #~ xml = Wx::XmlResource.get()
    #~ xml.init_all_handlers()
    #~ xml.load('C:\Program Files\Google\Google SketchUp 6\Plugins\wxSU-Examples\Project1Frm.xml')
    #~ f=xml.load_panel(self,"WxPanel1")
    #~ f=xml.load_frame(WxSU.app.sketchup_frame,"Project1Frm")

    #~ f.show
    #~ return


    frame = self
    #frame.set_client_size(Wx::Size.new(200,200))

    #panel = Wx::Panel.new(self,-1,Wx::DEFAULT_POSITION, Wx::Size.new(200,90))
    sizer = Wx::BoxSizer.new(Wx::VERTICAL)
    #sizer.add(panel, 0, GROW|ALL, 2)



    #next row
    panel = Wx::Panel.new(self,-1,Wx::DEFAULT_POSITION, Wx::Size.new(200,90))
    sizer.add(panel, 0, GROW|ALL, 2)
    psizer = Wx::FlexGridSizer.new(4,0)

    cb=Wx::StaticText.new(panel,-1,"Shape")
    psizer.add(cb, 0, GROW|ALL, 2)

    cb=Wx::ComboBox.new(panel,-1,"sphere",
                  Wx::DEFAULT_POSITION,
                  Wx::DEFAULT_SIZE,
                  ["sphere","cube","cone","cylinder","staticmesh"]
                  )
    #psizer = Wx::BoxSizer.new(Wx::HORIZONTAL)
    psizer.add(cb, 0, GROW|ALL, 2)

    cb=Wx::StaticText.new(panel,-1,"Density")
    psizer.add(cb, 0, GROW|ALL, 2)

    cb=Wx::SpinCtrl.new(panel,-1,"0.2",Wx::DEFAULT_POSITION,Wx::Size.new(60,20))
    psizer.add(cb, 0, GROW|ALL, 2)


    cb=Wx::StaticText.new(panel,-1,"Min")
    psizer.add(cb, 0, GROW|ALL, 2)

    cb=Wx::TextCtrl.new(panel,-1,"0.2",Wx::DEFAULT_POSITION,Wx::Size.new(60,20))
    psizer.add(cb, 0, GROW|ALL, 2)

    cb=Wx::StaticText.new(panel,-1,"Max")
    psizer.add(cb, 0, GROW|ALL, 2)

    cb=Wx::TextCtrl.new(panel,-1,"0.2",Wx::DEFAULT_POSITION,Wx::Size.new(60,20))
    psizer.add(cb, 0, GROW|ALL, 2)



    cb=Wx::StaticText.new(panel,-1,"Accel")
    psizer.add(cb, 0, GROW|ALL, 2)

    cb=Wx::TextCtrl.new(panel,-1,"0.2",Wx::DEFAULT_POSITION,Wx::Size.new(60,20))
    psizer.add(cb, 0, GROW|ALL, 2)

    cb=Wx::StaticText.new(panel,-1,"Damp")
    psizer.add(cb, 0, GROW|ALL, 2)

    cb=Wx::TextCtrl.new(panel,-1,"0.2",Wx::DEFAULT_POSITION,Wx::Size.new(60,20))
    psizer.add(cb, 0, GROW|ALL, 2)

    cb=Wx::CheckBox.new( panel, -1, "Static")
    psizer.add(cb, 0, GROW|ALL, 2)
    cb=Wx::CheckBox.new( panel, -1, 'ignore')
    psizer.add(cb, 0, GROW|ALL, 2)
    cb=Wx::CheckBox.new( panel, -1, "NoCollision")
    psizer.add(cb, 0, GROW|ALL, 2)

    cb=Wx::CheckBox.new( panel, -1, "Frozen")
    psizer.add(cb, 0, GROW|ALL, 2)
    cb=Wx::CheckBox.new( panel, -1, "NoFreeze")
    psizer.add(cb, 0, GROW|ALL, 2)

    cb=Wx::CheckBox.new( panel, -1, "Magnetic")
    psizer.add(cb, 0, GROW|ALL, 2)
    cb=Wx::CheckBox.new( panel, -1, "ShowCollision")
    psizer.add(cb, 0, GROW|ALL, 2)


    #finish
    panel.set_sizer(psizer)


    @sci = Wx::StyledTextCtrl.new(self,-1)

    #font = Wx::Font.new(10, Wx::TELETYPE, Wx::NORMAL, Wx::NORMAL)
    #@sci.style_set_font(Wx::STC_STYLE_DEFAULT, font);

    @ws_visible = false
    @eol_visible = false
    @sci.set_edge_mode(Wx::STC_EDGE_LINE)

    #line_num_margin = @sci.text_width(Wx::STC_STYLE_LINENUMBER, "9999")
    #@sci.set_margin_width(0, line_num_margin)

    @sci.style_set_foreground(Wx::STC_STYLE_DEFAULT, Wx::BLACK);
    @sci.style_set_background(Wx::STC_STYLE_DEFAULT, Wx::WHITE);
    @sci.style_set_foreground(Wx::STC_STYLE_LINENUMBER, Wx::LIGHT_GREY);
    @sci.style_set_background(Wx::STC_STYLE_LINENUMBER, Wx::WHITE);
    @sci.style_set_foreground(Wx::STC_STYLE_INDENTGUIDE, Wx::LIGHT_GREY);

    @sci.set_tab_width(4)
    @sci.set_use_tabs(false)
    @sci.set_tab_indents(true)
    @sci.set_back_space_un_indents(true)
    @sci.set_indent(4)
    @sci.set_edge_column(800)

    @sci.set_lexer(Wx::STC_LEX_RUBY)
    @sci.style_clear_all
    @sci.style_set_foreground(2, Wx::RED)
    @sci.style_set_foreground(3, Wx::GREEN)
    @sci.style_set_foreground(5, Wx::BLUE)
    @sci.style_set_foreground(6, Wx::BLUE)
    @sci.style_set_foreground(7, Wx::BLUE)
    @sci.set_key_words(0, "begin break elsif module retry unless end case next return until class ensure nil self when def false not super while alias defined? for or then yield and do if redo true else in rescue undef")

    @sci.set_property("fold","1")
    @sci.set_property("fold.compact", "0")
    @sci.set_property("fold.comment", "1")
    @sci.set_property("fold.preprocessor", "1")

    @sci.set_margin_width(1, 0)
    @sci.set_margin_type(1, Wx::STC_MARGIN_SYMBOL)
    @sci.set_margin_mask(1, Wx::STC_MASK_FOLDERS)
    @sci.set_margin_width(1, 10)

    @sci.marker_define(Wx::STC_MARKNUM_FOLDER, Wx::STC_MARK_PLUS)
    @sci.marker_define(Wx::STC_MARKNUM_FOLDEROPEN, Wx::STC_MARK_MINUS)
    @sci.marker_define(Wx::STC_MARKNUM_FOLDEREND, Wx::STC_MARK_EMPTY)
    @sci.marker_define(Wx::STC_MARKNUM_FOLDERMIDTAIL, Wx::STC_MARK_EMPTY)
    @sci.marker_define(Wx::STC_MARKNUM_FOLDEROPENMID, Wx::STC_MARK_EMPTY)
    @sci.marker_define(Wx::STC_MARKNUM_FOLDERSUB, Wx::STC_MARK_EMPTY)
    @sci.marker_define(Wx::STC_MARKNUM_FOLDERTAIL, Wx::STC_MARK_EMPTY)
    @sci.set_fold_flags(16)

    @sci.set_margin_sensitive(1,1)
    evt_stc_charadded(@sci.get_id) {|evt| onCharadded(evt)}
    evt_stc_marginclick(@sci.get_id) {|evt| onMarginClick(evt)}

    sizer.add(@sci, 1, Wx::GROW|Wx::ALL, 2)

    frame.set_sizer(sizer)
    frame.show()

  end

end

$f = ChildFrame.new("Body")
$f.show
