#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************
# Copyright 2004, @Last Software, Inc.
# Updated Dec. 2007 by Fredo6

# This software is provided as an example of using the Ruby interface to SketchUp.

# Permission to use, copy, modify, and distribute this software for 
# any purpose and without fee is hereby granted, provided that the above
# copyright notice appear in all copies.

# THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#-----------------------------------------------------------------------------
# Name		:   Bezierspline.rb
# Type		:   Sketchup Tool
# Description	:   A tool to create and edit Bezier, Cubic Bezier, Polyline and other mathematical curves.
# Menu Item	:   Draw --> one menu item for each curve type
# Context Menu	:   Edit xxx Curve, Convert to xxx curve
# Usage		:   See Tutorial on  'Bezierspline' in PDF format
# Initial Date	:   10 Dec 2007 (original Bezier.rb 8/26/2004)
# Releases		:   08 Jan 2008 -- fixed some bugs in inference drawing
#			:   17 Oct 2008 -- fixed other bugs, cleanup menu and more flexible on icons
#			:   01 Sep 2010 -- Clean release with all extensions, bug fixing and handling of load errors
# Credits	           ;   CadFather for the toolbar icons
#-------------------------------------------------------------------------------------------------------------------------------------------------
#*************************************************************************************************

require 'sketchup.rb'
begin
	require 'LibTraductor.rb'		# for language translation
rescue LoadError
end

#Specify the two curve extensions: Bezier Classic and Polyline
BZ____LIST = ["BZ__BezierClassic", "BZ__Polyline"]

#***********************************************************************************************
#***********************************************************************************************
# MODULE BEZIER CLASSIC - Original Bezier curve with mathematical algorithm as in bezier.rb
# Calculate a Bezier curve based on an array of control points.
# This is based on the technique described in "CAGD  A Practical Guide, 4th Edition", by Gerald Farin. page 60
# Credit to @Last software, 2004, for first publishing of the algorithm in script bezier.rb 
#***********************************************************************************************
#***********************************************************************************************

module BZ__BezierClassic

BZ_TYPENAME = "Bezier"			#Need to keep this name for backward compatibility - DO NOT TRANSLATE

#The string BZ_MENUNAME can be translated to other languages respecting syntax of Traductor
BZ_MENUNAME = ["Classic Bezier curve", 
               "|FR|Courbe de Bezier classique",
			   "|DE|klassische Bezierkurve",
			   "|HU|Klasszikus Bezier gõrbe",
			   "|ES|Curva Bezier clásica",
			   "|PT|Curva de Bezier clássica"] 
BZ_ICON = "BZ__ClassicBezier"

BZ_PRECISION_MIN = 7
BZ_PRECISION_MAX = 300
BZ_PRECISION_DEFAULT = 20

BZ_CONTROL_MIN = 3
BZ_CONTROL_MAX = 200
BZ_CONTROL_DEFAULT = 99

BZ_LOOPMODE = -15		#allow closing by segment and by Bezier curve
			   
#Standard Interface function for calculating the curve
def BZ__BezierClassic.bz_compute_curve(pts, numseg)
	crvpts = BZ__BezierClassic.points pts, numseg
end
	
# Evaluate the curve at a number of points and return the points in an array
def BZ__BezierClassic.points(pts, numpts)
    
    curvepts = []
    dt = 1.0 / numpts

    # evaluate the points on the curve
    for i in 0..numpts
        t = i * dt
        curvepts[i] = BZ__BezierClassic.evaluate(pts, t)
    end
    
    curvepts
end

def BZ__BezierClassic.evaluate(pts, t)

    degree = pts.length - 1
    if degree < 1
        return nil
    end
    
    t1 = 1.0 - t
    fact = 1.0
    n_choose_i = 1

    x = pts[0].x * t1
    y = pts[0].y * t1
    z = pts[0].z * t1
    
    for i in 1...degree
		fact = fact*t
		n_choose_i = n_choose_i*(degree-i+1)/i
        fn = fact * n_choose_i
		x = (x + fn*pts[i].x) * t1
		y = (y + fn*pts[i].y) * t1
		z = (z + fn*pts[i].z) * t1
    end

	x = x + fact*t*pts[degree].x
	y = y + fact*t*pts[degree].y
	z = z + fact*t*pts[degree].z

    Geom::Point3d.new(x, y, z)
    
end # method eval

end #Module BZ__BezierClassic

#***********************************************************************************************
#***********************************************************************************************
# MODULE POLYLINE - Just draw segments between specified control points
#***********************************************************************************************
#***********************************************************************************************

module BZ__Polyline

BZ_TYPENAME = "BZ__Polyline"
BZ_MENUNAME = ["Polyline", "|ES| Polilínea"]					#kept the same name in English and French
BZ_PRECISION_MIN = BZ_PRECISION_MAX = 1		#no precision
BZ_CONTROL_MIN = 2							#allow to have a polyline with only one segment
BZ_CONTROL_MAX = 300						#hope it is enough!
BZ_CONTROL_DEFAULT = 999					#open end drawing
BZ_CONVERT = "*"							#convert any curve made of at least 2 segments
BZ_LOOPMODE = -1							#allow closing by segment done by bezierspline.rb

#the calculation method just returns the polygon of control points
def BZ__Polyline.bz_compute_curve(pts, numseg)
	pts
end

end #End module BZ__Polyline

#***********************************************************************************************
#***********************************************************************************************
# MODULE BEZIERSPLINE - Master code of the macro
#***********************************************************************************************
#***********************************************************************************************

module Bezierspline

#BZ_IMAGE_Folder = "IMAGES_Standard"			# old icons"
BZ_IMAGE_Folder = "IMAGES_CadFather"	#ricons designed by CadFather

#Local constants for language translation

BZMNU_Title = ["BezierSpline curves", 
               "|FR|Courbes BezierSpline",
			   "|DE|BezierSpline Kurve",
			   "|HU|BezierSpline gõrbe",
			   "|ES|Curvas BezierSpline",
			   "|PT|Curvas BezierSpline"]

BZMNU_EditMenu = ["Edit", 
                  "|FR|Editer",
				  "|DE|Bearbeiten",
				  "|HU|Szerkesztés",
				  "|ES|Editar",
				  "|PT|Editar"]
BZMNU_EditDone = ["Done", 
                  "|FR|Terminé",
			      "|DE|Abschließen",
				  "|HU|Kész",
				  "|ES|Terminar",
				  "|PT|Terminar"]
BZMNU_CreateDone = ["Done and Exit tool", 
                    "|FR|Valider et sortir",
			        "|DE|Abschließen und Verlassen",
					"|HU|Kész és kilép",
					"|ES|Terminar y Salir",
					"|PT|Ferramenta Terminar e Sair"]
BZMNU_CreateEdit = ["Done and Switch to Edition (double-click)", 
                    "|FR|Valider et passer en mode Edition (double-clic)",
			        "|DE|Abschließen und zur Ausgabe wechseln (Doppelklick)",
					"|HU|Kész és váltás szerkesztésre (dupla kattintás)",
					"|ES|Terminar y pasar a Modo Edición (doble-clic)",
					"|PT|Terminar e passar para modo de editao (clique duplo)"]
BZMNU_CreateNext = ["Done and create another curve", 
                    "|FR|Valider et créer une courbe",
			        "|DE|Abschließen und andere Kurve beginnen",
					"|HU|Kész és újabb gõrbe készítése",
					"|ES|Terminar y crear otra Curva",
					"|PT|Terminar e criar outra curva"]
BZMNU_UndoLast = ["Undo last change", 
                  "|FR|Annuler dernière modification",
			      "|DE|Rückgängig letzte Änderung",
				  "|HU|Utolsó változtatás visszavonása",
				  "|ES|Anular la última modificación",
				  "|PT|Anular a Última Modificação"]
BZMNU_UndoAll = ["Undo all changes", 
                 "|FR|Annuler toutes les modifications",
		 	     "|DE|Rückgängig alle Änderungen",
				 "|HU|Összes változtatás visszavonása",
				 "|ES|Anular todas las modificaciones",
				 "|PT|Anular todas as modificações"]
BZMNU_Restart = ["Restart", 
                 "|FR|Recommencer",
			     "|DE|Neustart",
				 "|HU|Újrakezdés",
				 "|ES|Reiniciar",
				 "|PT|Recomeçar"]
BZMNU_OpChangePrecision = ["Change of precision", 
                           "|FR|Modification de précision",
				           "|DE|Präzisionsänderung",
						   "|HU|Pontosság megváltoztatása",
						   "|ES|Modificar la precisión",
						   "|PT|Modificação de precisão"]
BZMNU_OpAddPoint = ["Insertion of Control Point", 
                    "|FR|Insertion d'un point de contrôle",
			        "|DE|Kontrollpunkt einfügen",
					"|HU|Kontrollpont beillesztése",
			        "|ES|Insertar Punto de Control",
					"|PT|Inserção de um ponto de precisão"]
BZMNU_OpDelPoint = ["Deletion of Control Point", 
                    "|FR|Effacement d'un point de contrôle",
			        "|DE|Kontrollpunkt löschen",
					"|HU|Kontrollpont törlése",
					"|ES|Eliminar Punto de Control",
					"|PT|Apagar um ponto de controle"]
BZMNU_OpMovePoint = ["Move of Control Point", 
                     "|FR|Déplacement d'un point de contrôle",
			         "|DE|Kontrollpunkt bewegen",
					 "|HU|Kontrollpont áthelyezése",
					 "|ES|Mover Punto de Control",
					 "|PT|Mover um ponto de controle"]
BZMNU_OpCreateCurve = ["Creation of", 
                       "|FR|Création",
			           "|DE|Erstellen",
					   "|HU|Készítés",
					   "|ES|Crear",
					   "|PT|Criar"]				   
BZMNU_ConvertAs = ["Convert to", 
                   "|FR|Convertir en",
			       "|DE|Umwandeln zu",
				   "|HU|Átalakítás",
				   "|ES|Convertir a",
				   "|PT|Converter para"]
BZMNU_TransformAs = ["Transform to (control points)", 
                     "|ES|Transformar en (puntos de control)",
                     "|FR|Transformer en (points de controle)"]
BZMNU_ToggleMark = ["Vertex marks (toggle F5)", 
                    "|FR|Marquer les point (F5)",
			        "|DE| Knotenmarkierung (Strg F5)",
					"|HU|Csúcsjelek (F5)",
					"|ES|Marcar vértices (F5)",
					"|PT|Marcar vértices (F5)"]
BZMNU_LoopLineClose = ["Close loop with line (Toggle F8)", 
                       "|FR|Fermer par un segment (F8)",
			           "|DE|Schleife mit Linie schließen (F8)",
					   "|HU|Hurok zárása egyenessel (F8)",
					   "|ES|Cerrar con una línea (F8)",
					   "|PT|Fechar com uma linha"]
BZMNU_LoopNiceClose = ["Close loop nicely (Toggle F9)", 
                       "|FR|Fermer harmonieusement (F9)",
			           "|DE|Schleife harmonisch schließen (F9)",
					   "|HU|Hurok harmonikus zárása (F9)",
			           "|ES|Cerrar círculo armoniosamente (F9)",
					   "|PT|Fechar circuito harmoniosamente"]
BZMNU_LoopNoClose = ["No loop (F7)", 
                     "|FR|Pas de boucle (F7)",
			         "|DE|Schleife nicht schließen (F7)",
					 "|HU|Nincs hurok (F7)",
					 "|ES|Sin bucle (F7)",
					 "|PT|Sen circuito"]
BZMNU_Extras = ["Extra Parameters (TAB)", 
                "|FR|Parametres Supplémentaires (TAB)",
				"|DE| Extra daten (TAB)",
				"|HU| Extra paraméterek (TAB)",
				"|ES| Parámetros Extras (TAB)",
				"|PT| Extra Parâmetros (TAB)"]
BZMNU_DrawMode = ["Toggle Open-End or Start-End (Double-Shift)", 
                  "|FR|Bascule Courbe ouverte ou Début-fin (Double-Maj)",
				  "|DE| Umschalten offene Kurve / Start- und Endpunkt (Doppel-Shift)",
				  "|HU| Váltás nyílt végu vagy záet végu között (Dupla-Shift)",
				  "|ES| Alternar Curva abierta o Comienzo-Fin (Doble Shift)",
				  "|PT| Alternar Curva aberta / entre começo/fim (Shift-duplo)"]
					 
BZTRS_ChangePrecision = ["Precision --> ", 
                         "|FR|Précision --> ",
				         "|DE|Präzision --> ",
						 "|HU|Pontosság --> ",
						 "|ES|Precisión -->",
						 "|PT|Precisão -->"]
BZTRS_ChangeLoop = ["Loop segt --> ", 
                    "|FR|Boucle --> ",
			        "|DE|Schleifensegmente -->",
					"|HU|Hurokszegmens --> ",
					"|ES|Segmento de bucle --> ",
					"|PT|Segmento de circuito --> "]
BZTRS_ChangeDegree = ["Control points --> ", 
                      "|FR|Pts de contrôle --> ",
			          "|DE|Kontrollpunkte -->",
					  "|HU|Konrollpontok --> ",
					  "|ES|Puntos de Control -->",
					  "|PT|Pontos de controle -->"]
BZTRS_OpenEnd = ["Open-ended curve", 
                 "|FR|Courbe ouverte",
			     "|DE|Offene Kurve",
				 "|HU|Nyílt végû hurok",
				 "|ES|Curva abierta",
				 "|PT|Curva aberta"]
BZTRS_StartEnd = ["Between Start/End", 
                  "|FR|Courbe entre pt début et fin",
			      "|DE|Kurve /über Start- und Endpunkt definieren",
				  "|HU|Kezdet/vég között",
				  "|ES|Curva entre Inicio/Fin",
				  "|PT|Curva entre começo/fim"]

BZINF_Precision = ["Precision", 
                   "|FR|Précision",
			       "|DE|Präzision",
				   "|HU|Pontoság",
				   "|ES|Precisión",
				   "|PT|Precisão"]
BZINF_Loopnbpt = ["Loop", 
                  "|FR|Boucle",
			      "|DE|Schleife",
				  "|HU|Hurok",
				  "|ES|Bucle",
				  "|PT|Circuito"]
BZINF_ControlPoints = ["Control Points", 
                       "|FR|Points de Contrôle",
			           "|DE|Kontrollpunkte",
					   "|HU|Kontrollpontok",
					   "|ES|Puntos de Control",
					   "|PT|Pontos de controle"]
BZINF_EnterStartPoint = ["Click START point", 
                         "|FR|Cliquez le point de DEPART",
				         "|DE|Klick STARTPUNKT",
						 "|HU|Kattints a KEZDÕPONTRA",
						 "|ES|Clic punto INICIAL",
						 "|PT|Clique o ponto INICIAL"]
BZINF_EnterEndPoint = ["Click END point", 
                       "|FR|Cliquez le point de FIN",
			           "|DE|Klick ENDPUNKT",
					   "|HU|Kattints a VÉGPONTRA",
					   "|ES|Clic punto FINAL",
					   "|PT|Clique o ponto FINAL"]
BZINF_EnterPoint = ["Enter Point #", 
                    "|FR|Cliquez le point n°",
			        "|DE|Eingabe Punktanzahl",
					"|HU|Pontok száma",
					"|ES|Introducir Nº de Puntos",
					"|PT|Informe o número do ponto"]	
BZINF_TangentStart = ["Tangent at start point", 
                      "|FR|Tangente au premier point",
			          "|DE|Tangente am Startpunkt",
					  "|HU|Tangens a kezdõpontra",
					  "|ES|Tangente al punto INICIAL",
					  "|PT|Tangente ao ponto INICIAL"]	
BZINF_TangentEnd = ["Tangent at end point", 
                    "|FR|Tangente au dernier point",
			        "|DE|Tangente am Endpunkt",
					"|HU|Tangens a végpontra",
					"|ES|Tangente al punto FINAL",
					"|PT|Tangente ao ponto FINAL"]
BZINF_InfoCreate = ["Double-click to finish and Edit",
                    "|FR| Double-cliquez pour finir",
			        "|DE|Doppelklick zum Abschließen und Erzeugen",
					"|HU|Dupla kattintással befejez és szerkeszt",
					"|ES|Docle clic para Terminar y Editar",
					"|PT|Clique duas vezes para terminar e editar"]	
BZINF_InfoEdit = ["Drag points or double-click to add / remove control points",
				  "|FR|Déplacez les points ou double-cliquez pour ajouter / supprimer points",
				  "|DE|Verschiebe die Punkte oder Doppelklicke um Kontrollpunkte hinzuzufügen oder zu löschen",
				  "|HU|Helyezd át a pontokat vagy dupla kattintással törölj / adj hozzá pontokat",
				  "|ES|Arrastre los Puntos o doble-clic para añadir/borrar Puntos de Control",
				  "|PT|Arraste os pontos ou clique duas vezes para adicionar / remover pontos"]

BZINF_VCBCreate = ["Ctrl pts, Prec.", 
                   "|FR|Pts Ctrl, Préc.",
			       "|DE|Ktrl.-Punkte, Präz.",
				   "|HU|Ktrlpontok, pontossága",
				   "|ES|Ptos. Ctrl, Prec.",
				   "|PT|Ptos. Ctrl, Prec."]	
BZINF_VCBCreateNoPrec = ["Ctrl points", 
                         "|FR|Pts Ctrl",
				         "|DE|Ktrl.-Punkte",
						 "|HU|Ktrlpontok",
						 "|ES|Ptos. Ctrl",
						 "|PT|Ptos. Ctrl"]	
BZINF_VCBEdit = ["Precision", 
                 "|FR|Précision",
			     "|DE|Präzision",
				 "|HU|Pontosság",
				 "|ES|Precisión",
				 "|PT|Precisão"]	
BZINF_VCBDistance = ["Distance", 
                     "|FR|Distance", 
			         "|DE|Distanz",
					 "|HU|Távolság",
					 "|ES|Distancia",
					 "|PT|Distância"]	

ABOUT_About = ["About...", "|FR| A propos...", "|ES| Acerca de..."]
ABOUT_Documentation = ["Documentation...", "|FR| Documentation...", "|ES| Documentación..."]
ABOUT_CheckForUpdate = ["Check for update (Sktechucation)...", "|FR| Vérifier mise à jour (Sketchucation)...", "|ES| Actualizaciones (Sketchucation)..."]
ABOUT_Description = ["Bezier and Spline curves in 3D", 
                     "|FR| Courbes de Bezier et Splines en 3D",
				     "|ES| Curvas de Bezier y Splines en 3D"]
ABOUT_DesignedBy = ["Designed and Developed by Fredo6 © Sep 07 - Dec 08", 
                    "|FR| Conception et Development par Fredo6 © Sep 07 - Dec 08",
				    "|ES| Concepción y Desarrollo por Fredo6 © Sep 07 - Dic 08"]
ABOUT_Date = ["Date:", "|FR| Date :", "|ES| Fecha :"]
ABOUT_AtLast = ["@Last Software: for initial design of bezier.rb",
                "|FR| @Last Software: pour la conception initiale de bezier.rb",
				"|ES| @Last Software: concepción inicial de bezier.rb"]
ABOUT_Carlos = ["Carlos António dos Santos Falé: for the Cubic Bezier algorithm",
                "|FR| Carlos António dos Santos Falé: pour l'algorithme de Cubic Bezier",
				"|ES| Carlos António dos Santos Falé: por el algoritmo inicial de  Bezier Cúbica"]
ABOUT_Cad = ["CadFather: for toolbar icons",
             "|FR| CadFather: pour les icones de la barre d'outils",
			 "|ES| CadFather: por los iconos de la Barra de Utilidades"]

					 
#Symbolic names for storing attaributes in curves - DO NOT ALTER OR TRANSLATE
BZ___Dico = "skp"
BZ___CrvType = "crvtype"
BZ___CrvPts = "crvpts"
BZ___CrvPrecision = "crvprecision"
BZ___CrvLoop = "crvloop"
BZ___CrvLoopNbPt = "crvloopnbpt"
BZ___CrvExtras = "crvextras"

#Short cut keys
BZ___KeyDialogExtras = 9	#TAB - Call extra parameters dialog
BZ___KeyVertexMark = 116	#F5 - toggle show vertex
BZ___KeyLoopNone = 118		#F7 - No loop
BZ___KeyLoopLine = 119		#F8 - Close loop with a segment
BZ___KeyLoopNice = 120		#F9 - Cloase loop with a Bezier curve

#path to search extensions of the Bezierspline macro - DO NOT ALTER OR TRANSLATE
file__ = __FILE__
file__ = file__.force_encoding("UTF-8") if defined?(Encoding)
file__ = file__.gsub(/\\/, '/')
BZ___DirBZ = File.dirname(file__)
BZ___SearchDir = Dir[File.join(BZ___DirBZ, "BZ__*.rb")]

BZ___Toolbar = UI::Toolbar.new  "BZ__Toolbar"

BZ___ValidationToolBar = false

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Define the tool class for creating Bezier curves
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
class CreationBezierTool

def initialize(hmaths)

	#Classe de la courbe
	@hmaths = hmaths

	#Convert BZMNU and BZTRS constants into @msg_ corresponding variables, with the correct translation
	Traductor.load_translation Bezierspline, /BZMNU_/i, binding, "@msg_"
	Traductor.load_translation Bezierspline, /BZTRS_/i, binding, "@msg_"
	
	#Initializing teh working environment and side tools
	@bzlock = BezierLock.new 0   # Manage Lock in Creation mode
	@info = BezierStatusInfo.new @hmaths, false	#set up the status info bar

	#Setting the default values for the class of curve we create
	set_degree @hmaths.control_default + 1			#yes! the code still use the Degree concept!!
	set_precision @hmaths.precision_default
	@info.open_end = @open_end = @hmaths.param_open_end
	@info.transient = (@open_end ? @msg_OpenEnd : @msg_StartEnd)
	@noprecision = @hmaths.noprecision
	@loop = 0
	set_loopnbpt @hmaths.loopmode.abs
	@vertex_mark = (@hmaths.vertex_mark == 0) ? false : true
	
end

def reset
    @pts = []
    @state = 0
	self.showinfo
    @drawn = false
	@bzlock.reset @pts
	MATHS_PLUGINS.set_change_draw_mode_possible true
	@key_shift_time = Time.now
end

def activate
	LibFredo6.register_ruby 'BezierSpline' if defined?(LibFredo6.register_ruby)
	
    # @ip is a temporary input point used to get other positions
    @ip = Sketchup::InputPoint.new
    @iptemp = Sketchup::InputPoint.new
	@ipclick = nil
	@inpt = []		#sequence of input points
	@time_move = Time.now
	
    self.reset
	
	#Calling the custom procedure for extra parameters if applicable
	@extras = {}
	if (@hmaths.has_extras)
		@extras = @hmaths.call_ask_extras 'N', @extras, @pts, @precision
		return UI.start_timer(0.01) {Sketchup.active_model.select_tool nil} unless (@extras)
	end	
	MATHS_PLUGINS.set_create_tool self
	MATHS_PLUGINS.set_vertex_mark @vertex_mark
	MATHS_PLUGINS.set_has_extras @hmaths.has_extras
	MATHS_PLUGINS.set_loop_on @loop
	MATHS_PLUGINS.set_loop_possible @hmaths.loopmode.abs
	MATHS_PLUGINS.set_open_mode(@open_end ? "O" : "S")

end

def deactivate(view)
	MATHS_PLUGINS.set_create_tool nil
    view.invalidate if @drawn
end

def suspend(view)
	#nothing special to do
	MATHS_PLUGINS.set_suspend_mode true
end

def resume(view)
    @drawn = false
	MATHS_PLUGINS.set_suspend_mode false
	self.showinfo
end

def set_degree(degree)
	@info.nbctrl = degree + 1
	@degree = degree
end

def set_precision(precision)
	@info.precision = precision
	@precision = precision
end

def set_loopnbpt(nb)
	@info.loopnbpt = nb
	@loopnbpt = nb
end

def onLButtonDown(flags, x, y, view)
    @iptemp.pick view, x, y
	#We don't take the point if it is at the same position as the previous one
    #return unless @ip.valid? 
    return unless @iptemp.valid? 
	return if @ipclick && (@ip.position == @ipclick.position)
	@ip.copy! @iptemp
	@ipclick = Sketchup::InputPoint.new unless @ipclick
	@ipclick.copy! @ip
	
	case @state
	when 0		# first point
		@pts[0] = @ip.position
		next_pt = @pts [@state]
	when @degree		#end of drawing
		@state += 1
		###terminate_creation 'E'
		terminate_creation 'F'
		return
	when 1
		@pts[2] = @pts[1]
		next_pt = (@open_end) ? @pts[1] : @pts [0]
	when 2...@degree
		next_pt = @pts [@state]
		@pts[@state+1] = @pts[@state] unless @open_end
	end
	@state += 1	
	
	#record points for Locking
	@bzlock.prepare_lock x, y, next_pt, @pts
	self.showinfo
	
	MATHS_PLUGINS.set_change_draw_mode_possible(@pts.length < 3)

end

	
def onMouseMove(flags, x, y, view)
	t = Time.now
	return if (t - @time_move) < 0.01
	@time_move = t
	@xmove = x
	@ymove = y
	@flmove = flags
	@inpt[@state] = Sketchup::InputPoint.new
	

    if (@state == 0) # getting the first end point
        @ip.pick view, x, y
        #if( @ip.valid? && @ip.position != @inpt[0].position )
        if (@ip.valid?)
            @inpt[0].copy! @ip
            view.invalidate
        end
    else  # getting the other  control  points
		if (@open_end || @state == 1)
			offset = 0
			ipinf = @inpt[@state-1]		#inference point
		else
			offset = 1
			ipinf = (@state == 2) ? @inpt[0] : @inpt[1]		#inference point
		end
		@bzlock.input_point_when_create x, y, view, @ip, ipinf, @inpt[@state], @state-offset
    end
    view.tooltip = @ip.tooltip if @ip.valid?
	
	#showing the distance in the VCB
	if @state > 0
		n = (@open_end || @state == 1) ? @pts.length - 1 : @pts.length - 2
		@info.distance(@pts[n-1].distance(@pts[n])) 
	end	
end
	

def showinfo
	@info.curpt = @state
	@info.nbpt = @pts.length
    @info.show
end


def create_curve

	#compute the curve
	model = Sketchup.active_model
    entities = model.active_entities
	
	#advise Sketchup for the text to put in Undo menu
    model.start_operation "#{@msg_OpCreateCurve} #{@hmaths.menuname}"
    
	#compute the curve
    curvepts = @hmaths.call_compute_curve @pts, @precision, @loop, @loopnbpt, @extras
    
    # create the curve
    curve = entities.add_curve(curvepts);
	@curve = curve

    # see if this fills in any new faces
    if( curve )
        edge1 = curve[0]
        edge1.find_faces
        
        # Attach an attribute to the curve with the array of points
        curve = edge1.curve
        if( curve )
            curve.set_attribute BZ___Dico, BZ___CrvType, @hmaths.typename
            curve.set_attribute BZ___Dico, BZ___CrvPrecision, @precision
            curve.set_attribute BZ___Dico, BZ___CrvPts, @pts
            curve.set_attribute BZ___Dico, BZ___CrvLoop, @loop
            curve.set_attribute BZ___Dico, BZ___CrvLoopNbPt, @loopnbpt
            curve.set_attribute BZ___Dico, BZ___CrvExtras, Traductor.hash_marshal(@extras)
        end
        
    end
    model.commit_operation
	
	self.showinfo
    self.reset		#to go to next one
end

def switch_open_mode(view=nil)
	@open_end = ! @open_end
	@info.open_end = @open_end
	@info.transient = (@open_end ? @msg_OpenEnd : @msg_StartEnd)
	MATHS_PLUGINS.set_open_mode(@open_end ? "O" : "S")
	showinfo
	view = Sketchup.active_model.active_view unless view
	view.invalidate
end

def toggle_open_mode(key, rpt, view)
	#Only intercept Shift key, with Repeat 1, and in case where we are drawing the very first segment
	return false unless (key == CONSTRAIN_MODIFIER_KEY && rpt == 1 && @pts.length <= 2)
    if ((Time.now - @key_shift_time) < 0.5)		#toggle OK
		switch_open_mode view
	else
		@key_shift_time = Time.now
	end	
	return true
end	

def toggle_loop_mode(newloop, view=nil)
	return UI.beep if (newloop > @hmaths.loopmode.abs)
	@loop = (newloop == @loop) ? 0 : newloop
	MATHS_PLUGINS.set_loop_on @loop
	view = Sketchup.active_model.active_view unless view
	view.invalidate
end

def toggle_vertex_mark(view=nil)
	@vertex_mark = ! @vertex_mark
	MATHS_PLUGINS.set_vertex_mark @vertex_mark
	view = Sketchup.active_model.active_view unless view
	view.invalidate
	return @vertex_mark
end

def check_shortcuts(key, view=nil)
	status = true
	case key
	when BZ___KeyDialogExtras		#TAB key	Calling the extra parameters
		if (@hmaths.has_extras && (extra = @hmaths.call_ask_extras('N', @extras, @pts, @precision)))
			@extras.replace extra
			view = Sketchup.active_model.active_view unless view
			view.invalidate
		end	
	when BZ___KeyVertexMark			#F5 key	Show mark at vertex
		toggle_vertex_mark view
#		@vertex_mark = ! @vertex_mark
#		view.invalidate
	when BZ___KeyLoopNone			#F7key	No loop mode
		return true if (@loop == 0)
		toggle_loop_mode 0, view
	when BZ___KeyLoopLine			#F8 key	loop with just 1 segment
		toggle_loop_mode 1, view
	when BZ___KeyLoopNice			#F9 key	loop with a Bezier curve
		toggle_loop_mode 2, view
	else
		return false
	end	

	return true
end


def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true
	return if check_shortcuts key, view					#check on TAB and Function keys
	@bzlock.analyze_key_up key, view
end

def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, false
	return if toggle_open_mode(key, rpt, view)			#check on Shift-Shift
	@bzlock.analyze_key_down key, view					#check for plane and axis locks
end
 

def getMenu(menu)
    menu.add_item(@msg_CreateEdit) {terminate_creation 'E'}
    menu.add_item(@msg_CreateNext) {terminate_creation 'N'}
    menu.add_item(@msg_CreateDone) {terminate_creation 'F'}
	menu.add_separator
    menu.add_item(@msg_UndoLast) {self.undo_last}
    menu.add_item(@msg_Restart) {self.undo_all}
	menu.add_separator
	menu.add_item(@msg_DrawMode) {self.switch_open_mode} if (@pts.length < 3)
    menu.add_item(@msg_ToggleMark) {self.check_shortcuts BZ___KeyVertexMark}
	if @hmaths.loopmode.abs > 1
		menu.add_item(@msg_LoopNiceClose) {self.check_shortcuts BZ___KeyLoopNice}
	end	
	if @hmaths.loopmode.abs > 0
	    menu.add_item(@msg_LoopLineClose) {self.check_shortcuts BZ___KeyLoopLine}
	    menu.add_item(@msg_LoopNoClose) {self.check_shortcuts BZ___KeyLoopNone}
	end	
	true
end

def terminate_creation(action)
	
	if (@state < @hmaths.control_min) #need to ahve enough control points to terminate
		UI.beep
		return
	end
	
	finish_before	#finish drawing the curve
	#@info.stop_transient
	
	case action
	when 'F'		#Exit from the tool
		Sketchup.active_model.select_tool nil
	when 'E'		#Switch to Edit mode for the curve
		#UI.start_timer(0.01) {switch_to_edit_mode}
		if Traductor.platform_is_mac?
			switch_to_edit_mode
		else
			switch_to_edit_mode
			#UI.start_timer(0.01) {switch_to_edit_mode}
		end	
	end				#otherwise, continue for creation of next curve
end

def finish_before
	return unless (@state > 2 || (@open_end && @hmaths.control_min == 2)) 
	
	#End the input of the control point before normal termination - rather tricky!!
	n = @pts.length - 1
	if (@state <= @degree)		
		if @open_end
			@pts[n..n] = [] if (@state != @pts.length)
		else
			@pts[n-1] = @pts[n]
			@pts[n..n] = []	
		end	
	end
	
	#creating the curve
	self.create_curve
	
	#prepare for next drawing
	@bzlock.reset []
	self.showinfo	
end

def switch_to_edit_mode
	return unless @curve
	
	#Clearing all selection and reselecting the curve to switch in Edit mode
	model = Sketchup.active_model
	selection = model.selection	
	selection.clear
	status = selection.add [@curve]
	
	#Switching to Edit mode
	Sketchup.active_model.select_tool EditionBezierTool.new(@hmaths,true) if status > 0

end

def onLButtonDoubleClick(flags, x, y, view)
	terminate_creation 'E' unless (@state == 0)
end

#undo input of last point and go back to previous point
def undo_last
	n = @pts.length - 1
	if @state == 0		#exit from tool
		Sketchup.active_model.select_tool nil
		return 
	end
	@pts[(n-1)..(n-1)] = @pts[n] unless @open_end || n == 1
	@pts[n..n] = []
	@state = @state - 1
	view = Sketchup.active_model.active_view
	onMouseMove(@flmove, @xmove+1, @ymove+1, view)
	MATHS_PLUGINS.set_change_draw_mode_possible(@pts.length < 3)
end

def undo_all
	view = Sketchup.active_model.active_view
	view.invalidate if @drawn
    self.reset	
end

def onCancel(flag, view)

	case flag
	when 0		#cancel key pressed
	    if (@key_escape_time && (Time.now - @key_escape_time) < 0.2)		#toggle OK
		else
			undo_last
			@key_escape_time = Time.now
			return
		end	
	when 1
		return nil
	when 2		#Sketchup undo or redo
		return nil
	end	

    view.invalidate if @drawn
    self.reset
end



#-------------------------------------------------------------------------------------------------------------------------------------------------
# VCB Input functions for the number of control points and the Precision parameters
# the original function has been modified  to accept a specified number of segments as digits, followed by 's"
#If a number is entered without the final 's', then it is considered as the number of control points		
#-------------------------------------------------------------------------------------------------------------------------------------------------

def onUserText(text, view)     
	self.acceptVCB text, view
	self.showinfo
end

def acceptVCB (text, view)     

	#check if both parameters were entered in the same input (for instance '25s, 63')
	if (text =~/(,|;)/)
		self.acceptVCB $`, view
		self.acceptVCB $', view
		return
	end

	#check if text is for Degree or Number of Segment - VCB always take a digit as first character
	newval = text.to_i	
	
	#looking for Precision followed by 'r'
	if ((text =~/\d+(c|C)$/) == 0)
		if (@hmaths.loopmode.abs <= 1 || newval > 100)
			UI.beep
			return
		end
		if (newval != @loopnbpt)
			set_loopnbpt newval
			@info.transient = @msg_ChangeLoop + "#{@loopnbpt}c"
		end	
		return 
	end
	
	#looking for Precision followed by 's'
	if ((text =~/\d+(s|S)$/) == 0)
		if (@noprecision)
			UI.beep
			return
		end
		newval = @hmaths.check_precision(newval, true)
		if (newval != @precision)
			set_precision(newval)
			@info.transient = @msg_ChangePrecision + "#{@precision}s"
		end	
		return 
	end
	
    # get the degree from the text - Note that <newval> corresponds to <degree-1>
	newval = @hmaths.check_control(newval, true)
	if (@state < newval)
        set_degree newval - 1
		@info.transient = @msg_ChangeDegree + "#{@degree+1}"
    else
        UI.beep
    end
end

#-------------------------------------------------------------------------------------------------------------------------------------------------
# Function required by Sketchup to have an idea of the extension of the entity
#-------------------------------------------------------------------------------------------------------------------------------------------------

def getExtents
    bb = Geom::BoundingBox.new
    if( @state == 0 )
        # We are getting the first point
        if( @ip.valid? && @ip.display? )
            bb.add @ip.position
        end
    else
        bb.add @pts
    end
    bb
end

def draw(view)

    # Show the current input point
    if( @ip.valid? )
        view.draw_points @ip.position, 10, @bzlock.pick_shape, @bzlock.pick_color
        @drawn = true
    end

    # show the curve
    if( @state < 1 )
		return
	end
	
    if( @state == 1 )
		if (@open_end && @hmaths.control_min == 2)	###
			#it is valid to compute the curve on 2 points
	        view.drawing_color = "black"
	        curvepts = @hmaths.call_compute_curve @pts, @precision, 0, 0, @extras
	        view.draw(GL_LINE_STRIP, curvepts)
			view.draw_points(curvepts, 5, 2, "turquoise") if @vertex_mark
		else
	        # just draw a line from the start to the end point
			begin
		        view.set_color_from_line(@inpt[0], @inpt[1]) if (@inpt[1] && @inpt[0].valid? && @inpt[1].valid?)
		        view.draw(GL_LINE_STRIP, @pts)
			rescue
			end
		end
    else
        # draw the curve
        view.drawing_color = "black"
        curvepts = @hmaths.call_compute_curve @pts, @precision, @loop, @loopnbpt, @extras
        view.draw(GL_LINE_STRIP, curvepts)
		
		#drawing marks for vertex
		view.draw_points(curvepts, 5, 2, "turquoise") if (@vertex_mark && curvepts.length > 2)
		#view.draw_points(curvepts[1..-1], 6, 2, "turquoise") if (@vertex_mark && curvepts.length > 2)
		
        # draw the control polygon
		view.drawing_color = "purple"
		if (@open_end || @state != 2)
			view.draw(GL_LINE_STRIP, @pts[0..(@state-1)])
			view.set_color_from_line(@inpt[@state-1], @inpt[@state]) if (@inpt[@state] && @inpt[@state-1])
		else
			view.draw(GL_LINE_STRIP, @pts[1..2])
			view.set_color_from_line(@inpt[0], @inpt[2]) if (@inpt[0] && @inpt[2])
			view.draw(GL_LINE_STRIP, @pts[0..1])
		end		

		ipinf = (@open_end) ? @inpt[@state-1] : @inpt[1]
		view.set_color_from_line(ipinf, @inpt[@state]) if @inpt[@state]
		view.draw GL_LINE_STRIP, [@pts[@state-1], @pts[@state]]
    end
    @drawn = true
	
    # Draw the control points
	n = @pts.length-1
    view.draw_points(@pts[0..0], 10, 3, "blue")
    view.draw_points(@pts[1..n-1], 10, 3, "red") if n > 1 	
    view.draw_points(@pts[n..n], 10, 3, "green") if n > 0 
	
	#draw the mark on segment depending on the drawing mode (Start-End or Open-End)
	draw_mark view
		
end


def draw_mark(view)
	len = @pts.length - 1
	
	return if len <= 0		#only one point drawn
	
	if @open_end			#indicate Open end
		p1 = @pts[len-1]
		p2 = @pts[len]
		shape = 7		#filled triangle
		color = 'orange'
		size = 10
	elsif (len == 1)		#Start-End mode - first segment
		p1 = @pts[len-1]
		p2 = @pts[len]
		shape = 4		#cross
		color = 'red'
		size = 15
	else
		p1 = @pts[len-2]
		p2 = @pts[len-1]
		shape = 7		#filled triangle
		color = 'orange'			
		size = 10
	end

	pt = Geom::Point3d.linear_combination 0.5, p1, 0.5, p2		#Centered on segment
	view.draw_points pt, size, shape, color
	pt = nil
end

end # class CreationBezierTool

#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------
# Define the tool class for editing Bezier curves
#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------

class EditionBezierTool

def initialize(hmaths, from_menu)

	# <hmaths> represents the Maths Plugin object used, based on the attribute stored in the curve
	@hmaths = hmaths
	@from_menu = from_menu
	@noprecision = hmaths.noprecision

	#loading the string translation
	Traductor.load_translation Bezierspline, /BZMNU_/i, binding, "@msg_"
	Traductor.load_translation Bezierspline, /BZTRS_/i, binding, "@msg_"
	Traductor.load_translation Bezierspline, /BZINF_/i, binding, "@msg_"

	# set up the Lock mechanism
	@bzlock = BezierLock.new 1	  # Manage Lock in Edition mode

	# set up the status line information environment 
	@info = BezierStatusInfo.new @hmaths, true
	
	f = MATHS_PLUGINS.check_icon('Cursor_Arrow_Exit.png')
	@id_cursor_arrow_exit = UI::create_cursor f, 0, 0
	@ptstack = []
end

def activate
	LibFredo6.register_ruby 'BezierSpline' if defined?(LibFredo6.register_ruby)

    @mousedown = false
    @drawn = false
    @selection = nil
    @pt_to_move = nil
    @ip = Sketchup::InputPoint.new
	@first_click = false		#needed because of transmission of double-click between Creation and Edition
	@vertex_mark = (@hmaths.vertex_mark == 0) ? false : true
	
	#loading curve from selection
	self.load_curve
	
	#initializing the Lock mechanism
	@bzlock.reset @pts
	
	#updating the status bar
	@info.show
	
	if (@from_menu)
		n = @pts.length-1
		@@pts_init = nil
		@@pts_init = @pts.clone
		@@prec_init = @precision
		@from_menu = false
	end	
	
	MATHS_PLUGINS.set_edit_tool self
	MATHS_PLUGINS.set_vertex_mark @vertex_mark
	MATHS_PLUGINS.set_has_extras @hmaths.has_extras
	MATHS_PLUGINS.set_loop_on @loop
	MATHS_PLUGINS.set_loop_possible @hmaths.loopmode.abs
	
	Sketchup.active_model.active_view.invalidate
end

def deactivate(view)
	view.invalidate if @drawn
	MATHS_PLUGINS.set_edit_tool nil
    @ip = nil
end

def suspend(view)
	MATHS_PLUGINS.set_suspend_mode true
end

def resume(view)
	MATHS_PLUGINS.set_suspend_mode false
    @drawn = false
	@info.show	
end

def set_degree(degree)
	@info.nbctrl = degree + 1
	@degree = degree
end

def set_precision(precision)
	@info.precision = precision
	@precision = precision
end

def set_loopnbpt(nb)
	@info.loopnbpt = nb
	@loopnbpt = nb
end

def load_curve	
    
    # Make sure that there is really a Bezier curve selected
    @curve = @hmaths.check_selected_curve
    if( not @curve )
        Sketchup.active_model.select_tool nil
        return
    end
    
    # Get the control points
    @pts = @curve.get_attribute BZ___Dico, BZ___CrvPts
	set_degree @pts.length - 1
    if( not @pts )
        UI.beep
        Sketchup.active_model.select_tool nil
        return
    end
    
    # Get the curve points from the vertices
    @vertices = @curve.vertices
    @crvpts = @vertices.collect {|v| v.position}
    set_precision @curve.get_attribute(BZ___Dico, BZ___CrvPrecision, @vertices.length - 1)
	@loop = @curve.get_attribute(BZ___Dico, BZ___CrvLoop, 0)
	set_loopnbpt @curve.get_attribute(BZ___Dico, BZ___CrvLoopNbPt, 0)
	@extras = {}
	a = @curve.get_attribute(BZ___Dico, BZ___CrvExtras, "vide")
	@extras = Traductor.hash_unmarshal a
end    

def reload_curve_after_undo(view)

	#bad trick to retrieve the curve
    model = Sketchup.active_model
    entities = model.active_entities
	selection = model.selection
	n = entities.length
	e = entities[n-1]
	
	#loading the curve
	load_curve
	
	unless @curve
		selection.add e
		load_curve
		if (@curve)
			selection.add @curve.edges
			@bzlock.restore
			view.invalidate
			Sketchup.active_model.select_tool EditionBezierTool.new(@hmaths, false)
		end	
		return
	end
	
	return unless @curve

	@bzlock.restore		# need to restore the Lock status, because user could have pressed Ctrl-Z
	selection.add @curve.edges

	view.invalidate
end




def undo_all
	view = Sketchup.active_model.active_view
	n = @@pts_init.length-1
	@pts = []
	@pts = @@pts_init.clone
	@precision = @@prec_init
    @crvpts = @hmaths.call_compute_curve @pts, @precision, @loop, @loopnbpt, @extras		#recompute the curve
	self.update_curve view
	set_degree = @pts.length-1
	@info.show	

end

def is_initial_curve?

	return false if (@precision != @@prec_init)
	return false if (@pts.length != @@pts_init.length)
	
	n = @pts.length
	i = 0
	while i < n
		return false if @pts[i] != @@pts_init[i]
		i = i + 1
	end	
	true
end

def onCancel(flag, view)

	case flag
	when 0		#Key Escape pressed
	    if (@key_escape_time && (Time.now - @key_escape_time) < 0.2)		#toggle OK
			undo_all
		else
			if (is_initial_curve?)
				UI.beep
				return
			end
			Sketchup.send_action "editUndo:"
			UI.start_timer(0.5) {self.reload_curve_after_undo view}
			@key_escape_time = Time.now
		end	
	when 2		#Sketchup Undo or Redo - we recompute the previous curve from what Sketchup ends up with
		unless (is_initial_curve?)
			UI.start_timer(0.5) {self.reload_curve_after_undo view}
		else
			Sketchup.active_model.select_tool nil
		end	
	end	
end

def toggle_loop_mode(newloop, view=nil)
	return UI.beep if (newloop > @hmaths.loopmode.abs)
	@loop = (newloop == @loop) ? 0 : newloop
	MATHS_PLUGINS.set_loop_on @loop
	view = Sketchup.active_model.active_view unless view
	update_curve_precision @precision
	@info.show
end

def toggle_vertex_mark(view=nil)
	@vertex_mark = ! @vertex_mark
	MATHS_PLUGINS.set_vertex_mark @vertex_mark
	view = Sketchup.active_model.active_view unless view
	view.invalidate
	@info.show
	return @vertex_mark
end

def check_shortcuts(key, view=nil)
	status = true
	case key
	when BZ___KeyDialogExtras		#TAB key	Calling the extra parameters
		if (@hmaths.has_extras && (extra = @hmaths.call_ask_extras('E', @extras, @pts, @precision)))
			@extras.replace extra
			update_curve_precision @precision
			@info.show
		end	
	when BZ___KeyVertexMark			#F5 key	Show mark at vertex
		@vertex_mark = ! @vertex_mark
		view.invalidate
	when BZ___KeyLoopNone			#F7key	No loop mode
		return true if (@loop == 0)
		toggle_loop_mode 0, view
	when BZ___KeyLoopLine			#F8 key	loop with just 1 segment
		toggle_loop_mode 1, view
	when BZ___KeyLoopNice			#F9 key	loop with a Bezier curve
		toggle_loop_mode 2, view
	else
		return false
	end	

	return true
end


def onKeyDown(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true
	@bzlock.analyze_key_down key, view unless rpt > 1
end

def onKeyUp(key, rpt, flags, view)
	key = Traductor.check_key key, flags, true
	return if check_shortcuts key, view					#check on TAB and Function keys
	@bzlock.analyze_key_up key, view
end

def add_or_del_pts_on_segment (x, y, view)
	ph = view.pick_helper
	selection = ph.pick_segment @pts, x, y	#check if we clicked on the control polygon
	
	unless selection	#no valid selection - We end the Edition mode
		Sketchup.active_model.select_tool nil
		return
	end
	
	#ADDING a new control point
    if(selection < 0) 	# We got a point on a segment.  Compute the point coordinates
		return UI.beep unless @pts.length < @hmaths.control_max
		pickray = view.pickray x, y
		i = -selection
		segment = [@pts[i-1], @pts[i]]
		result = Geom.closest_points segment, pickray  #locate point on segment
		@pt_to_move = result[0]
		return unless @pt_to_move
		@pts[i,0] = @pt_to_move		#insert point
		@msg_op = @msg_OpAddPoint
	
	else	#We got a point - Delete it
		return UI.beep unless @pts.length > @hmaths.control_min
		i = selection
		@pt_to_move = @pts [i]		
		@pts [i..i]= []		#delete point
		@msg_op = @msg_OpDelPoint
    end
	
	#Update the curve
    @crvpts = @hmaths.call_compute_curve @pts, @precision, @loop, @loopnbpt, @extras		#recompute the curve
	self.update_curve view
	set_degree @pts.length-1
	@info.show	

end

def pick_point_to_move(x, y, view)
    @old_pt_to_move = @pt_to_move
    ph = view.pick_helper
    @selection = ph.pick_segment @pts, x, y

    if( @selection )
        if( @selection < 0 )
            # We got a point on a segment.  Compute the point closest to the pick ray.
            pickray = view.pickray x, y
            i = -@selection
            segment = [@pts[i-1], @pts[i]]
            result = Geom.closest_points segment, pickray
            @pt_to_move = result[0]
        else
            # we got a control point
            @pt_to_move = @pts[@selection]
        end
    else
        @pt_to_move = nil
    end
    @old_pt_to_move != @pt_to_move
end

def exit_tool
	Sketchup.active_model.select_tool nil
end

def onLButtonDown(flags, x, y, view)
    # Select the segment or control point to move
	@first_click = true
	self.pick_point_to_move x, y, view
    @mousedown = true if( @selection )
	if @pt_to_move 
		@bzlock.prepare_lock x, y, @pt_to_move, @pts 
	else
		exit_tool
	end	
	@mouse_move = false		#must consider the click UP as valid only if the mouse has moved
end

def onLButtonDoubleClick(flags, x, y, view)	#used to ADD or DELETE control points - Otherwise EXIT Edit mode
	self.add_or_del_pts_on_segment x, y, view if @first_click
end

def onLButtonUp(flags, x, y, view)
    return unless @mousedown
    @mousedown = false
	
	#When mouse button is released, we update the curve objet in Sketchup (unless there was no edition of a point)
	self.update_curve view if @mouse_move
	@info.show
end	

def update_curve(view)    
    # Update the actual curve object in Sketchup.  Move the vertices on the curve
    # to the new curve points
    if( @vertices.length != @crvpts.length )
		update_curve_precision @precision
        return
    end

    model = @vertices[0].model
	
	@msg_op = @msg_OpMovePoint if @mouse_move
    model.start_operation @msg_op

    # Update the control points stored with the curve
    @curve.set_attribute BZ___Dico, BZ___CrvPts, @pts
	
    # Move the vertices
    @curve.move_vertices @crvpts
    
    model.commit_operation
end


def onMouseMove(flags, x, y, view)
    # Make sure that the control polygon is shown
    view.invalidate if not @drawn
    @mouse_move = true

    # Move the selected point if mouse button is down
    if( @mousedown && @selection )
        @ip.pick view, x, y
		
		# check for axis locks and compute the 'real' point	
        return if not @ip.valid?
		
		if @ip.degrees_of_freedom == 0
			offset_pt = @ip.position
		else	
			offset_pt = @bzlock.compute_geom_point x, y, view
			if (offset_pt == nil) 
				offset_pt = @ip.position
			end	
		end	
		
        if( @selection >= 0 )
            # Moving a control point
            @pt_to_move = offset_pt
            @pts[@selection] = @pt_to_move
        else
            # moving a segment
            vec = offset_pt - @pt_to_move
            i = -@selection
            @pts[i-1] = @pts[i-1].offset vec
            @pts[i] = @pts[i].offset vec
            @pt_to_move = offset_pt
        end
        @crvpts = @hmaths.call_compute_curve @pts, @precision, @loop, @loopnbpt, @extras
		@info.distance @old_pt_to_move.distance(@pt_to_move) if @old_pt_to_move
        view.invalidate
        view.tooltip = @ip.tooltip if @ip.valid?

    else # if mouse up, see if we can select something to move
        view.invalidate if (self.pick_point_to_move(x, y, view))
		if @pt_to_move
			view.tooltip = @msg_InfoEdit
		else
			view.tooltip = @msg_CreateDone
		end	
    end
end

#Setting the cursor
def onSetCursor
	ic = 0
	unless @mouse_down || @pt_to_move
		ic = @id_cursor_arrow_exit
	end
	UI::set_cursor ic
end

def getMenu(menu)
    menu.add_item(@msg_EditDone) {Sketchup.active_model.select_tool nil}
    menu.add_item(@msg_UndoAll) {self.undo_all}
    menu.add_item(@msg_UndoLast) {Sketchup.send_action "editUndo:"}
	menu.add_separator
    menu.add_item(@msg_ToggleMark) {self.check_shortcuts BZ___KeyVertexMark}

	if @hmaths.loopmode.abs > 1
		menu.add_item(@msg_LoopNiceClose) {self.check_shortcuts BZ___KeyLoopNice}
	end	
	if @hmaths.loopmode.abs > 0
	    menu.add_item(@msg_LoopLineClose) {self.check_shortcuts BZ___KeyLoopLine}
	    menu.add_item(@msg_LoopNoClose) {self.check_shortcuts BZ___KeyLoopNone}
	end	
	true
end

def getExtents
    bb = Geom::BoundingBox.new
    bb.add @pts
    bb
end

def draw(view)
    # Draw the control polygon
    view.drawing_color = "orange"
    view.draw(GL_LINE_STRIP, @pts)
	
	n = @pts.length-1
	view.draw_points(@pts[0..0], 10, 3, "blue")
    view.draw_points(@pts[1..n-1], 10, 3, "red") if n > 1
    view.draw_points(@pts[n..n], 10, 3, "green") if n > 0
	
    #draw the point to move
	if (@pt_to_move)
        ######view.draw_points(@pt_to_move, 10, @bzlock.pick_shape, @bzlock.pick_color)
        view.draw_points(@pt_to_move, 8, @bzlock.pick_shape, @bzlock.pick_color)
    end

    #drawing the curve with new position
	if (@mousedown)
        view.drawing_color = "black"
        view.draw(GL_LINE_STRIP, @crvpts)
    end

	#drawing marks for vertex
	view.draw_points(@crvpts[1..-2], 5, 2, "turquoise") if (@vertex_mark && @crvpts.length > 2)	
    
    @drawn = true
end

def onUserText(text, view)     
	newval = text.to_i
	
	#looking for number of points in the loop, if applicable (number followed by 'c')
	if ((text =~/\d+(c|C)$/) == 0)
		if (@hmaths.loopmode.abs <= 1 || newval > 100)
			UI.beep
			return
		end
		if (newval != @loopnbpt)
			set_loopnbpt newval
			@info.transient = @msg_ChangeLoop + "#{@loopnbpt}c"
			self.update_curve_precision @precision if @loop >= 2
			@info.show
		end	
		return 
	end
	
	#looking for Precision followed by 'r' - Updating the loop number
	if ((text =~/\d+(s|S)$/) == 0 && (! @noprecision))
		newval = @hmaths.check_precision newval, true
		if (@precision != newval)
			self.update_curve_precision newval
			@info.show
			return
		end
	end
	
	#not a valid entry
	UI.beep
	@info.show
end

#Update the curves when a parameter like the precision or nb of control points has changed
def update_curve_precision(nbnew)

    model = Sketchup.active_model
    entities = model.active_entities
	selection = model.selection
	set_precision nbnew
	
    #compute the new Bezier Curve
	@crvpts = @hmaths.call_compute_curve @pts, @precision, @loop, @loopnbpt, @extras
	
	@msg_op = @msg_OpChangePrecision
    model.start_operation @msg_op
	
		# Erase the current curve   
		#@previous_edge = @curve_edges
		layer = @curve.edges[0].layer
		entities.erase_entities @curve.edges
		    
	    # Create the new curve
	    edge = entities.add_curve @crvpts
		edge1 = edge [0]
		edge1.find_faces
		@curve = edge1.curve
	    @curve.set_attribute BZ___Dico, BZ___CrvType, @hmaths.typename
	    @curve.set_attribute BZ___Dico, BZ___CrvPrecision, @precision
	    @curve.set_attribute BZ___Dico, BZ___CrvPts, @pts
        @curve.set_attribute BZ___Dico, BZ___CrvLoop, @loop
        @curve.set_attribute BZ___Dico, BZ___CrvLoopNbPt, @loopnbpt
        @curve.set_attribute BZ___Dico, BZ___CrvExtras, Traductor.hash_marshal(@extras)
		@curve.edges.each {|e| e.layer = layer}
	 	selection.add edge
			
    model.commit_operation
 
	@vertices = @curve.vertices

end
 
end # class EditionBezierTool

#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------
# Define the utility class for managing Axis and Plane Lock for Bezier curves
#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------

class BezierLock

attr_reader :pick_color, :pick_shape, :forcedir, :flgplane, :axis

def initialize (flgaxis)

	@flgaxis = flgaxis		# creation or Edition mode

end

def reset(pts)

	@pts = pts
	@forcedir = 0
	@flgplane = 0
	@axis = nil
	@pick_color = "black"
	@pick_shape = 1
	
	# assume plane lock for creation  or edition of a curve already on plane
	if (@flgaxis == 0 || Bezierspline.is_curve_on_plane(@pts))
		self.analyze_key_down COPY_MODIFIER_KEY, nil	
	end	

end

def save
	@forcedir_old = @forcedir		# need to save the Lock status, becaue user could have pressed Ctrl-Z
	@flgplane_old = @flgplane
	@axis_old = @axis
	@pick_color_old = @pick_color
	@pick_shape_old = @pick_shape
end
	
def restore
	@forcedir = @forcedir_old		# need to save the Lock status, becaue user could have pressed Ctrl-Z
	@flgplane = @flgplane_old
	@axis = @axis_old
	@pick_color = @pick_color_old
	@pick_shape = @pick_shape_old
end
	
def prepare_lock(x, y, origin, pts)
	@origin = origin.clone if origin
	@x0 = x
	@y0 = y
	@pts = pts
end	

def input_point_when_create(x, y, view, ip, ip_inf, ip_cur, i)
    ip.pick view, x, y, ip_inf
	if( ip.valid? && ip != ip_cur )
		ip_cur.copy! ip
		if ip.degrees_of_freedom == 0
			@pts[i] = ip.position
		else	
			offset_pt = self.compute_geom_point x, y, view
			@pts[i] = (offset_pt) ? offset_pt : ip.position
		end	
		view.invalidate
	end
	ip_cur
end

def compute_geom_point(x, y, view)

	if (@flgplane != 0) 
		offset_pt = self.compute_plane_point x, y, view
	elsif (@flgaxis != 0 && @forcedir != 0) 
		offset_pt = self.compute_axis_point x, y, view
	else
		offset_pt = nil
	end	
	offset_pt
end

def compute_axis_point (x, y, view)
	camera = view.camera
	dx = (x - @x0) * @axis.dot(camera.xaxis)
	dy = (y - @y0) * @axis.dot(camera.yaxis)
	# Y direction is + going down
	ds = (dx + -dy) * camera.eye.distance(ORIGIN) * 0.001
	vec = Geom::Vector3d.new(ds*@axis.x, ds*@axis.y, ds*@axis.z)
	offset_pt = @origin.offset(vec)
	return offset_pt
end

def compute_plane_point (x, y, view)
	ray = view.pickray x, y 
	return nil unless ray
	if (@axis)
		plane = [@origin, @axis]
	elsif (@pts.length > 3)
		plane = Geom.fit_plane_to_points @pts[0], @pts[1], @pts[@pts.length-1]
	else
		return nil
	end	
	offset_pt = Geom.intersect_line_plane ray, plane
	return offset_pt
end

def analyze_key_up(char, view)
	if ((char == COPY_MODIFIER_KEY) && view)
		@ctrl_is_down = false
	end	
end
	

def analyze_key_down(char, view)

	#When CTRL key, save the state, as CTRL might be combined with other keys
	self.save
	if (char == COPY_MODIFIER_KEY && view)
		@ctrl_is_down = true
	end
	
	oldforcedir = @forcedir
	if ((char.to_i - @forcedir) == 0)
		a = 0
	else
		a = 1
	end	
	
	# Track CTRL key for locking on Planes
    case char
	when COPY_MODIFIER_KEY 		#Ctrl key
		if (@flgplane == 0)
			@flgplane = 1
			@pick_color = "black"
			@pick_shape = 2
		else
			@flgplane = 0
			@pick_color = "black"
			@pick_shape = 1
		end
		view.invalidate if view
		return
	end

	# Track Arrow keys for locking on axis or on plane normal to axis
    case char
	when VK_UP #UP
		@forcedir = char * a
		@axis = Z_AXIS
		
	when VK_RIGHT #RIGHT
		@forcedir = char * a
		@axis = X_AXIS
		
	when VK_LEFT #LEFT
		@forcedir = char * a
		@axis = Y_AXIS
		
	when VK_DOWN #DOWN
		@forcedir = 0
	end	
	
	return if (@forcedir == oldforcedir)
	
	case @forcedir
	when 0
		@pick_color = "black"
	when VK_UP
		@pick_color = "blue"
	when VK_RIGHT
		@pick_color = "red"
	when VK_LEFT		
		@pick_color = "lightgreen"
	end	
	
	@pick_shape = (@flgplane != 0) ? 2 : (@forcedir == 0 || @flgaxis == 0) ? 1 : 7
	
	view.invalidate if view

end

end  # class BezierLock

#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------
# Class to handle the status bar
#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------
class BezierStatusInfo

attr_writer :curvename, :nbctrl, :precision, :flgedit, :curpt, :message, :nbpt, :transient,
			:open_end, :loopnbpt

def initialize(hmaths, flgedit)

	@hmaths = hmaths
	@curvename = hmaths.menuname
	@flgedit = flgedit
	@transient = nil
	@timer_id = 0

	Traductor.load_translation Bezierspline, /BZINF_/i, binding, "@msg_"  #All translated text for status info bar
end

def distance(d)
	Sketchup::set_status_text @msg_VCBDistance, SB_VCB_LABEL
	Sketchup::set_status_text d, SB_VCB_VALUE
end	

def show
	msgtext = "#{@curvename} - "
	msgtext += "[#{@msg_ControlPoints} = #{@nbctrl} "
	msgtext += " -- #{@msg_Precision} = #{@precision}s " unless @hmaths.noprecision
	msgtext += " -- #{@msg_Loopnbpt} = #{@loopnbpt}c " if (@loopnbpt && @loopnbpt >= 2) 
	msgtext += "]"
	mop = ""
			
	if (@flgedit)
		msgtext += "   (#{@msg_InfoEdit})"
	else
		if (@open_end)
			if (@nbpt == 0)
				m = @msg_EnterStartPoint
			else
				m = @msg_EnterPoint + " #{@curpt+1}"
			end
		else
			if (@nbpt == 0)
				m = @msg_EnterStartPoint
			elsif (@nbpt == 1)
				m = @msg_EnterEndPoint
			else	
				m = @msg_EnterPoint + " #{@curpt}"
			end	
			if (@curpt == 2 && @nbpt == 3)
				mop = " (#{@msg_TangentStart})"
			elsif (@curpt == @nbctrl-1)
				mop = " (#{@msg_TangentEnd})"
			end	
		end
		msgtext += "   -- #{m}" + mop
		msgtext += "   (#{@msg_InfoCreate})" if @nbpt > 2
	end	
	
	#transient message
	if (@transient)
		msgtext += "  [#{@transient}]"
		#UI.stop_timer @timer_id if @timer_id != 0
		@transient = nil
		#@timer_id = UI.start_timer(10) { self.stop_transient }
	end
	
	#Showing the Text
    Sketchup::set_status_text msgtext

	#updating the VCB
    if @hmaths.noprecision			#curve does not require precision parameter
		if @flgedit
			Sketchup::set_status_text "", SB_VCB_LABEL
			Sketchup::set_status_text "", SB_VCB_VALUE
		else
			Sketchup::set_status_text @msg_VCBCreateNoPrec, SB_VCB_LABEL
			Sketchup::set_status_text "#{@nbctrl}", SB_VCB_VALUE	
		end
	elsif @flgedit					#Edition mode - we can only change the precision parameter
		Sketchup::set_status_text @msg_VCBEdit, SB_VCB_LABEL
		Sketchup::set_status_text "#{@precision}s", SB_VCB_VALUE
	else
		Sketchup::set_status_text @msg_VCBCreate, SB_VCB_LABEL
		Sketchup::set_status_text "#{@nbctrl}, #{@precision}s", SB_VCB_VALUE	
	end	
	
end

def stop_transient
	@transient = nil
	UI.stop_timer @timer_id
	@timer_id = 0
	self.show
end

end  #Class BezierStatusInfo

#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------
# Class to handle a curve algorithm
#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------

class BezierMathsCurve

attr_reader :typename, :filename, :modulename, :hmod, :menuname, :control_default, :precision_default,
			:noprecision, :convert_modules, :transform_modules, :control_min, :control_max, :precision_min, :precision_max,
			:loopmode, :vertex_mark, :has_extras, :loopnbpt

def initialize(typename, filename, modulename, hmod, menuname, convert_modules, tr_modules)
	@typename = typename
	@filename = filename
	@modulename = modulename
	@hmod = hmod
	@menuname = menuname
	@convert_modules = convert_modules
	@transform_modules = (tr_modules && tr_modules.length > 0) ? tr_modules : ['*']
end

def param_open_end
	p = Bezierspline.load_constant @hmod, 'BZ_CONTROL_DEFAULT', 0, 'i'
	(p == 999) ? true : false
end

def param_control_min
	df = 2
	p = Bezierspline.load_constant @hmod, 'BZ_CONTROL_MIN', df, 'i'
	(p < df) ? df : p
end
def param_control_max
	df = 500
	p = Bezierspline.load_constant @hmod, 'BZ_CONTROL_MAX', df, 'i'
	(p > df) ? df : p
end
def param_control_default
	dfmin = self.param_control_min
	dfmax = self.param_control_max
	p = Bezierspline.load_constant @hmod, 'BZ_CONTROL_DEFAULT', dfmax, 'i'
	p = (p > dfmax) ? dfmax : p
	(p < dfmin) ? dfmin : p
end

def param_precision_min
	df = 0
	p = Bezierspline.load_constant @hmod, 'BZ_PRECISION_MIN', df, 'i'
end
def param_precision_max
	df = 0
	p = Bezierspline.load_constant @hmod, 'BZ_PRECISION_MAX', df, 'i'
end
def param_precision_default
	dfmin = self.param_precision_min
	dfmax = self.param_precision_max
	p = Bezierspline.load_constant @hmod, 'BZ_PRECISION_DEFAULT', dfmin, 'i'
	p = (p > dfmax) ? dfmax : p
	(p < dfmin) ? dfmin : p
end

def check_precision(newval, beeping)
	a = newval
	if (a > @precision_max)
		a = @precision_max
		UI.beep unless beeping
	elsif (a < @precision_min)
		a = @precision_min
		UI.beep unless beeping
	end
	return a
end

def check_control(newval, beeping)	
	a = newval
	if (a > @control_max)
		a = @control_max
		UI.beep unless beeping
	elsif (a < @control_min)
		a = @control_min
		UI.beep unless beeping
	end
	return a
end

def get_method(methodname, arity)

	begin
		hmeth = @hmod.method(methodname)
	rescue
		#Traductor.log_error "undefined method #{methodname} for #{@modulename} in file #{@filename}"
		return nil
	end
	
	unless (hmeth.arity >= arity)
		Traductor.log_error "incorrect number of arguments for method #{methodname} in #{@modulename} in file #{@filename}"
		return nil
	end
	
	return hmeth
end
 
def load_parameters

	@control_min = param_control_min
	@control_max = param_control_max
	@control_default = param_control_default
	
	@precision_min = param_precision_min
	@precision_max = param_precision_max
	@precision_default = param_precision_default
	@noprecision = (@precision_min == @precision_max) ? true : false
	
	@loopmode = Bezierspline.load_constant @hmod, 'BZ_LOOPMODE', 0, 'i'
	@loopnbpt = (loopmode.abs > 2) ? loopmode.abs : 2
	@vertex_mark = Bezierspline.load_constant @hmod, 'BZ_VERTEX_MARK', 0, 'i'

	#loading the Method for computing curve in the form <mdoulename>.bz_compute_curve
	@hmeth_compute = get_method "bz_compute_curve", 2
	@meth_arity = @hmeth_compute.arity if @hmeth_compute

	#loading the Method for providing extra parameters
	@hmeth_extra = get_method "bz_ask_extras", 4

	@has_extras = (@meth_arity == 4 && @hmeth_extra) ? true : false
end

def call_compute_curve(pts, precision, loop, loopnbpt, extras)
	
	#calling the module method, with right number of arguments
	lp = (@loopmode <= 0 || loop == 0) ? 0 : ((loop == 1) ? 1 : loopnbpt) 
	case @meth_arity
	when 2
		crvpts = @hmeth_compute.call pts, precision
	when 3
		crvpts = @hmeth_compute.call pts, precision, lp
	when 4
		crvpts = @hmeth_compute.call pts, precision, lp, extras
	else
		return pts
	end
	
	#closing the loop with default method
	if (loop > 0 && @loopmode < 0)
		if (loop == 1)
			crvpts = crvpts + pts[0..0]
		else
			numseg = (loopnbpt <= 2) ? precision : loopnbpt
			Bezierspline.close_loop_by_Bezier pts, numseg, crvpts
		end
	end
	
	#returning the computed curve
	crvpts
end

def call_ask_extras(mode, extras, pts, precision)
	extras = (@has_extras) ? @hmeth_extra.call(mode, extras, pts, precision) : extras
end

# Select the Creation tool
def menu_creation_tool
    Sketchup.active_model.select_tool CreationBezierTool.new(self)
end

# Edit a selected Bezier curve
def menu_edition_curve
    curve = self.check_selected_curve
    if( not curve )
        UI.beep
        return
    end
    Sketchup.active_model.select_tool EditionBezierTool.new(self, true)
end

def conversion_curve(transform=false)
	
    model = Sketchup.active_model
    entities = model.active_entities
	selection = model.selection
	
	#getting the old curve and its points
	if transform
		curve = BezierMathsCurve.is_selection_a_curve
		pts = curve.get_attribute BZ___Dico, BZ___CrvPts
		return unless pts
		ledges = curve.edges
		loop = curve.get_attribute BZ___Dico, BZ___CrvLoop
	else
		ll = selection_joint_edges
		return unless ll
		ledges = ll[0]
		pts = ll[1]	
		if (pts[0] == pts[-1])
			loop = 2   ######
			pts[0..0] = []
		else
			loop = 0
		end	
	end	
	
	#Check if the curve to be converted is a loop
	loopnbpt = @loopmode.abs
	precision = param_precision_default			#we use the default precision for the target curve
	
	#Ask for extra parameters
	extras = {}
	if (@has_extras)
		extras = self.call_ask_extras 'C', extras, pts, precision
		return unless (extras)
	end	
	
    #compute the new Bezier Curve
	crvpts =  self.call_compute_curve pts, precision, loop, loopnbpt, extras

	mop = Traductor.s BZMNU_ConvertAs, 'Conversion'
	
    model.start_operation mop + " #{@menuname}"
	
		# Erase the current curve  
		layer = ledges[0].layer
		entities.erase_entities ledges
		    
	    # Create the new curve
	    edge = entities.add_curve crvpts
		edge1 = edge[0]
		edge1.find_faces
		newcurve = edge1.curve
	    newcurve.set_attribute BZ___Dico, BZ___CrvType, @typename
	    newcurve.set_attribute BZ___Dico, BZ___CrvPrecision, precision
	    newcurve.set_attribute BZ___Dico, BZ___CrvPts, pts
        newcurve.set_attribute BZ___Dico, BZ___CrvLoop, loop
        newcurve.set_attribute BZ___Dico, BZ___CrvLoopNbPt, @loopmode.abs
        newcurve.set_attribute BZ___Dico, BZ___CrvExtras, Traductor.hash_marshal(extras)
		newcurve.edges.each {|e| e.layer = layer}
	 	selection.add edge
	
    model.commit_operation
	
	#swicthing in Edit mode
    Sketchup.active_model.select_tool EditionBezierTool.new(self, true)
	
end

def selection_joint_edges
    ss = Sketchup.active_model.selection
	hedges = {}
	ss.each do |e|
		hedges[e.object_id] = e if e.class == Sketchup::Edge
	end	
	return nil if hedges.length == 0
	
	hused = {}
	lpts1 = []
	lpts2 = []
	edge0 = hedges.values[0]
	hused[edge0.object_id] = true
	ls1 = pursue_edge(edge0, edge0.start, hedges, hused, lpts1)
	return nil unless ls1
	if edge0.end != lpts1.last
		ls2 = pursue_edge(edge0, edge0.end, hedges, hused, lpts2)
		return nil unless ls2
	else
		ls2 = []
	end	
	ledges = ls1.reverse + [edge0] + ls2
	return nil if ledges.length != hedges.length
	lpts = lpts1.reverse + lpts2
	[ledges, lpts]
end

def pursue_edge(edge0, v0, hedges, hused, lpts)
	ledges = []
	while true
		lpts.push v0.position
		le = v0.edges.find_all { |ee|  hedges[ee.object_id] && !hused[ee.object_id] }
		return ledges if le.length == 0
		return nil if le.length != 1
		edge0 = le[0]
		ledges.push edge0
		hused[edge0.object_id] = true
		v0 = edge0.other_vertex v0
	end	
	ledges
end

def BezierMathsCurve.is_selection_a_curve
    ss = Sketchup.active_model.selection
	return nil if ss.length > 500
	hcurve = {}
	ss.each do |e|
		next unless e.class == Sketchup::Edge
		curve = e.curve
		hcurve[curve.entityID] = curve if curve
	end	
    return nil if hcurve.length != 1
	hcurve.values[0]
end
		
# Function to test if the selection contains only a Bezier curve
# Returns the curve if there is one or else nil
def check_selected_curve    
	curve = BezierMathsCurve.is_selection_a_curve
	return nil unless curve
    return nil if curve.get_attribute(BZ___Dico, BZ___CrvType) != @typename
    curve
end

# Function to tes if the selection contains a curve that can be converted into one fo the Bezier family curves
# Returns the curve if there true or else nil
def check_convertible_curve
	selection = Sketchup.active_model.selection
	return '' if selection.length > 500
	curve = BezierMathsCurve.is_selection_a_curve
	unless curve
		if selection.find { |e| e.instance_of?(Sketchup::Edge) }
			return 'C'
		else
			return ''
		end	
	else
		ledges = curve.edges
 	end
	
	#checking that the curve has at least 3 points
	n = (ledges.length) + 1
	return '' if (n < @control_min || n > @control_max)
	return 'C' unless curve
	
	#checking if there is a match of types
	type = curve.get_attribute BZ___Dico, BZ___CrvType
	return '' if type == @modulename	#Curve has the same type - no need to convert or transform it as itself

	#Conversion
	status = ''
	@convert_modules.each do |m|
		status += 'C' if m == "*" || type =~ Regexp.new(m)
	end
	
	#Transformation
	@transform_modules.each do |m|
		status += 'T' if m == "*" || type =~ Regexp.new(m)
	end
	
	status		#no match was found
end
	
end #Class BezierMathsCurve

#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------
# Class to handle the overall context of the macro - 
# There is only one instance of this class: MATHS_PLUGINS
#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------

class BezierContext

private_class_method :new
@@classe = nil
def BezierContext.create
unless @@classe 
	@@classe = new 
end	
@@classe
end

#Compute the name of this present file
def this_file_name	
	file__ = __FILE__
	file__ = file__.force_encoding("UTF-8") if defined?(Encoding)
	file__ = file__.gsub(/\\/, '/')
	file__ =~ /\w+\s*\w+\.rb/i
	fil = $&
end

def BezierContext.get_listt ; @@list ; end

def load_modules
	@@list = []
	@suspend_mode = false
	@edit_tool = nil
	@create_tool = nil
	@vertex_mark = false
	@has_extras = nil
	@loop_on = false
	@loop_possible = 2
	@open_mode = ""
	
	#Loading the default Bezier curve plugins in the present file
	load_list_modules this_file_name, "BZ__"

	#loading all other Plugins which are extensions of Bezierspline. Search in Plugins directory and 
	BZ___SearchDir.each do |f|		#Loop on each file
		#if does not respect the naming convention
		filename = File.basename f
		sd = File.basename(File.dirname(f))
		
		#load the Ruby script if not loaded
		require File.join(sd, filename)

		#compute the name of the module from the file name
		filename =~ /BZ__/i
		modulename = "#{$&}#{$'}".chomp '.rb'

		#Load one or several Bezier extension modules in the file
		load_list_modules filename, modulename
		
	end

	#Load the corresponding menus
	load_all_menus
end

def load_list_modules(filename, modulename)
	#First check if there is a global variable in the form <modulename>_LIST, which would contain the list of modules 
	var = modulename.upcase + "__LIST"
	begin		#the global variable is defined and gives the list of modules
		a = Kernel::eval var
		a.each do |m|
			hcurve = load_one_module filename, m.strip
			@@list.push hcurve if hcurve 
		end
	rescue		#otherwise we load the module
		hcurve = load_one_module filename, modulename
		@@list.push hcurve if hcurve	
	end

end

def load_one_module(filename, modulename)
	begin
		hmod = Kernel::eval modulename
	rescue
		Traductor.log_error "undefined module #{modulename} in file #{filename}"
		return nil
	end	
	
	#Getting the unique code name for the curve type - if not present we take <modulename>
	typename = Bezierspline.load_constant hmod, "BZ_TYPENAME", modulename,'s'

	#Getting the method to draw compute the curve in the from <modulename>.compute_curve
	methods = hmod.methods.collect { |a| a.to_s }
	return nil unless (methods.include? "bz_compute_curve")

	#getting the menu name
	#am = Bezierspline.load_constant hmod, "BZ_MENUNAME", typename.to_a, 'as'
	am = Bezierspline.load_constant hmod, "BZ_MENUNAME", typename, 'as'
	menuname = (am)? Traductor.s(am, typename) : typename
	
	#getting the list of curves modules that this curve can convert
	convert_modules = []
	s = Bezierspline.load_constant hmod, "BZ_CONVERT", "", 's'
	s = s.strip
	while s && s != ""
		mn = (s =~ /,/ || s =~ /;/) ? $` : s
		convert_modules.push mn.strip
		s = $'
	end	

	#Getting the list of curves modules that this curve can convert
	tr_modules = []
	s = Bezierspline.load_constant hmod, "BZ_TRANSFORM", "", 's'
	s = s.strip
	while s && s != ""
		mn = (s =~ /,/ || s =~ /;/) ? $` : s
		tr_modules.push mn.strip
		s = $'
	end	
	
	#Creating the Plugin item and returning i
	hmaths = BezierMathsCurve.new typename, filename, modulename, hmod, menuname, convert_modules, tr_modules
	
	#loading other parameters
	hmaths.load_parameters
	
	#returning the newly created curve object
	hmaths
	
end	

#Compute the contextual menu
def compute_contextual_menu(menu)
	medit = 'BZ - ' + Traductor.s(BZMNU_EditMenu, 'Edition')

	sepa = false
	#contextual menu for Editing the curve
	@@list.each do |hmaths|
		if (hmaths.check_selected_curve)		
			unless sepa
				menu.add_separator
				sepa = true
			end	
			menu.add_item(medit + ' ' + hmaths.menuname) { hmaths.menu_edition_curve}
		end
	end
	
	#contextual menu for converting the curve into a Bezier family curve
	submenu_c = nil
	submenu_t = nil
	@@list.each do |hmaths|
		status = hmaths.check_convertible_curve	
		if status =~ /C/		
			submenu_c = menu.add_submenu('BZ - ' + Traductor[BZMNU_ConvertAs]) unless submenu_c
			submenu_c.add_item(hmaths.menuname) { hmaths.conversion_curve}
		end
		if status =~ /T/		
			submenu_t = menu.add_submenu('BZ - ' + Traductor[BZMNU_TransformAs]) unless submenu_t
			submenu_t.add_item(hmaths.menuname) { hmaths.conversion_curve true}
		end
	end	
end	

#Compute the right icons for a command
def compute_icons(cmd, name_icon, tooltip)
	name_icon = name_icon.gsub(/\.png\Z/i, '') if name_icon =~ /\.png\Z/i
	icon_16 = check_icon(name_icon + '_16.png')
	icon_24 = check_icon(name_icon + '_24.png')
	icon = check_icon(name_icon + '.png')
	small_icon = icon_16
	small_icon = icon unless small_icon
	small_icon = icon_24 unless small_icon
	large_icon = icon_24
	large_icon = icon unless large_icon
	large_icon = icon_16 unless large_icon
	if small_icon && large_icon
		cmd.small_icon = small_icon
		cmd.large_icon = large_icon
		cmd.tooltip = tooltip
		return true
	end	
	return false
end

#Load all menus appearing in the "Draw" section,as wellas the contextual menu handler on any selection
def load_all_menus

	#adding a separator to menu 'Draw'
	menudraw = UI.menu("Draw")
	menudraw.add_separator
	menudraw = menudraw.add_submenu Traductor[BZMNU_Title]

	#adding the menu for Creation Tool of curve
	@nb_cmd = 0
	@@list.each do |hmaths|	
		cmd = UI::Command.new(hmaths.menuname) {hmaths.menu_creation_tool}
		name_icon = Bezierspline.load_constant hmaths.hmod, "BZ_ICON", hmaths.typename + '.png', 's'
		if compute_icons(cmd, name_icon, hmaths.menuname)
			BZ___Toolbar.add_item cmd
			@nb_cmd += 1
		end
		cmd.status_bar_text = hmaths.menuname
		menudraw.add_item cmd
	end
	BZ___Toolbar.add_separator if (@nb_cmd > 0)
	
	#About Section
	menudraw.add_separator
	cmd = UI::Command.new(Traductor[ABOUT_About]) {self.show_about}
	menudraw.add_item cmd
	
	if Sketchup.version.to_i > 5
		lf = Dir[File.join(BZ___DirBZ, "*.pdf")]
		menudoc = menudraw.add_submenu Traductor[ABOUT_Documentation]
		lf.each do |f| 
			cmd = UI::Command.new(File.basename(f)) {self.open_doc f}
			menudoc.add_item cmd
		end	
		
		text = Traductor[ABOUT_CheckForUpdate]
		url = "http://forums.sketchucation.com/viewtopic.php?f=323&t=13563#p100509"
		menudraw.add_item(text) { UI.openURL url }
	end	
	
	#adding contextual menu for Curve edition and conversion to other module curves
	UI.add_context_menu_handler do |menu|
		compute_contextual_menu(menu)
	end
	
	#Create all commands
	create_commands
	
	tlb = BZ___Toolbar
	if (@nb_cmd > 0)
		status = tlb.get_last_state
		if status == 1
			tlb.restore
		elsif status == -1	
			tlb.show if tlb
		end	
	end
	
end



def show_about
	text = Bezierspline.get_name + " v" + Bezierspline.get_version
	text += "\n" + Traductor[ABOUT_Description]
	text += "\n\n" + Traductor[ABOUT_DesignedBy]
	text += "\n" + Traductor[ABOUT_Date] + ' '  + Bezierspline.get_date
	
	text += "\n\n" + "CREDITS"
	lc = [ABOUT_AtLast, ABOUT_Carlos, ABOUT_Cad]
	lc.each { |w| text += "\n   - " + Traductor[w] }
	
	UI.messagebox text, MB_OK
end

def open_doc(filename)
	UI.openURL filename if FileTest.exist?(filename)
end

def set_create_tool tool
	@create_tool = tool
end	

def set_edit_tool tool
	@edit_tool = tool
end	

def set_suspend_mode flgsuspend
	@suspend_mode = flgsuspend
end	

def set_vertex_mark flgvertex
	@vertex_mark = flgvertex
end	

def set_has_extras has_extras
	@has_extras = has_extras
end	

def set_loop_on loop
	@loop_on = loop.abs
end	

def set_loop_possible loopmode
	@loop_possible = loopmode
end	

def set_change_draw_mode_possible flg
	return if (@change_draw_mode_possible == flg)
	@change_draw_mode_possible = flg
	return
end	

def set_open_mode flg
	return if (@open_mode == flg)
	@open_mode = flg
	return
end	

def check_icon(name)
	f = File.join(BZ___DirBZ, BZ_IMAGE_Folder, name)
	return (FileTest.exist?(f)) ? f : nil
end

def create_commands
	name_icon = "BZ___EditCurve.png"
	tooltip = @label_edit = Traductor.s(BZMNU_EditMenu, 'Edition')
	cmd = @cmd_edit_curve = UI::Command.new(@label_edit) {tlb_edit_curve}
	cmd.status_bar_text = @label_edit
	if compute_icons cmd, name_icon, tooltip
		BZ___Toolbar.add_item cmd
		@nb_cmd += 1
	end	
	
	name_icon = "BZ___Vertex.png"
	label = Traductor[BZMNU_ToggleMark]
	cmd = @cmd_toggle_mark = UI::Command.new(label) {tlb_toggle_mark}
	cmd.status_bar_text = label
	if compute_icons cmd, name_icon, label
		BZ___Toolbar.add_item cmd
		@nb_cmd += 1
	end	

	name_icon = "BZ___Extras.png"
	label = Traductor.s BZMNU_Extras
	cmd = @cmd_extras = UI::Command.new(label) {tlb_extras}
	cmd.status_bar_text = label
	if compute_icons cmd, name_icon, label
		BZ___Toolbar.add_item cmd
		@nb_cmd += 1
	end	

	name_icon = "BZ___Niceloop.png"
	label = Traductor.s BZMNU_LoopNiceClose
	cmd = @cmd_niceloop = UI::Command.new(label) {tlb_niceloop}
	cmd.status_bar_text = label
	if compute_icons cmd, name_icon, label
		BZ___Toolbar.add_item cmd
		@nb_cmd += 1
	end	

	name_icon = "BZ___Lineloop.png"
	label = Traductor.s BZMNU_LoopLineClose
	cmd = @cmd_lineclose = UI::Command.new(label) {tlb_lineloop}
	cmd.status_bar_text = label
	if compute_icons cmd, name_icon, label
		BZ___Toolbar.add_item cmd
		@nb_cmd += 1
	end		
end

def get_hmaths_from_selection
	curve = BezierMathsCurve.is_selection_a_curve
	return nil unless curve
    typename = curve.get_attribute(BZ___Dico, BZ___CrvType)
	return nil unless typename
	
	@@list.each do |hmaths|
		if (typename == hmaths.typename)
			return hmaths
		end
	end
	return nil
end

def tlb_edit_curve
	hmaths = get_hmaths_from_selection
	return unless hmaths
	if (@edit_tool)
		Sketchup.active_model.select_tool nil
	else
		hmaths.menu_edition_curve if hmaths
	end	
end

def tlbvalid_edit_curve
	hmaths = get_hmaths_from_selection
	unless (hmaths || @suspend_mode)
		@cmd_edit_curve.tooltip = @label_edit
		@cmd_edit_curve.menu_text = @label_edit
		@cmd_edit_curve.status_bar_text= @label_edit
		return MF_GRAYED
	end
	label = @label_edit + ' ' + hmaths.menuname
	@cmd_edit_curve.tooltip= label
	@cmd_edit_curve.menu_text= label
	@cmd_edit_curve.status_bar_text= label
	(@edit_tool) ? MF_CHECKED : MF_ENABLED
end

def tlb_toggle_mark
	if (@edit_tool)
		@edit_tool.toggle_vertex_mark
	elsif (@create_tool)
		@create_tool.toggle_vertex_mark
	end
end

def tlbvalid_toggle_mark
	return MF_GRAYED unless (@edit_tool || @create_tool)
	(@vertex_mark) ? MF_CHECKED : MF_ENABLED
end

def tlb_extras
	if (@edit_tool)
		@edit_tool.check_shortcuts BZ___KeyDialogExtras
	elsif (@create_tool)
		@create_tool.check_shortcuts BZ___KeyDialogExtras
	end
end

def tlbvalid_extras
	((@edit_tool || @create_tool) && (@has_extras)) ? MF_ENABLED : MF_GRAYED
end

def tlb_niceloop
	if (@edit_tool)
		@edit_tool.check_shortcuts BZ___KeyLoopNice
	elsif (@create_tool)
		@create_tool.check_shortcuts BZ___KeyLoopNice
	end
end

def tlbvalid_niceloop 
	return MF_GRAYED unless ((@edit_tool || @create_tool) && (@loop_possible >= 2))
	(@loop_on >= 2) ? MF_CHECKED : MF_ENABLED
end


def tlb_lineloop
	if (@edit_tool)
		@edit_tool.check_shortcuts BZ___KeyLoopLine
	elsif (@create_tool)
		@create_tool.check_shortcuts BZ___KeyLoopLine
	end
end

def tlbvalid_lineloop
	return MF_GRAYED unless ((@edit_tool || @create_tool) && (@loop_possible >= 1))
	(@loop_on == 1) ? MF_CHECKED : MF_ENABLED
end

def tlb_drawmode
	if (@create_tool)
		@create_tool.switch_open_mode
	end
end

def tlbvalid_drawmode
	((@create_tool) && (@change_draw_mode_possible)) ? MF_CHECKED : MF_GRAYED
end


end  #Class BezierContext

#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------
# Some global utilities
#-------------------------------------------------------------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------------------------------------------------------------

#load a constant in a given module
def Bezierspline.load_constant (mod, c, default, type)
	if (mod.const_defined? c) 
		a = mod.const_get(c)
	else
		return default
	end	
	
	#checking the requested type
	case type
	when 'i'	#Integer requested
		return ((a.to_i == 0) ? default : a.to_i) #unless (a.kind_of? Integer)
	when 's'	#string requested
		begin
			return a.strip
		rescue
			return default
		end	
	when 'as'	#array of strings requested - strip them anyway
		begin
			as = []
			a.each do |s|
				begin
					as.push s.strip
				rescue
				end				
			end
			return (as.length == 0) ? default : as	
		rescue
			return default
		end	
	
	end	
	return a
end

#Function to test that all control points (given by pts array) of a curve are on the same plane
def Bezierspline.is_curve_on_plane (pts)
	return false unless (pts && pts.length > 2)	#not enough points to define a plan
	
	nb = pts.length
	plane = Geom.fit_plane_to_points pts[0], pts[1], pts[nb-1] #plane with first 3 points
	return false unless plane
	
	i = 2
	while i < nb-1
		return false unless (pts[i].on_plane? plane)		#this point not on plane
		i += 1
	end
	return true		#all points on plane
end

# Method to close a curve 'nicely' with a Bezier curve
def Bezierspline.close_loop_by_Bezier(pts, numseg, crvpts)
	n = crvpts.length - 1
	np = pts.length - 1
	loopts = []
	factor = 0.5
	dist = (pts[0].distance pts[np]) * factor
	
	#prolongation segment at end
	loopts[0] = ptlast = crvpts[n]
	ptprev = crvpts[n-1]
	vector = ptprev.vector_to ptlast 
	loopts[1] = ptlast.offset vector, dist

	#prolongation segment at beginning
	loopts[3] = ptlast = crvpts[0]
	ptprev = crvpts[1]	
	vector = ptprev.vector_to ptlast 
	loopts[2] = ptlast.offset vector, dist

	#computing the Bezier curve on the <loopts> polygon
	closingcurve = BZ__BezierClassic.bz_compute_curve loopts, numseg
	
	#adding the points to the curve to close the loop
	closingcurve[0..0] = []
	closingcurve.each {|pt| crvpts.push pt}
	
	#returning the concatenated curve
	crvpts
end

# EXECUTED ONCE - Startup procedure and add a menu choice for creating bezier curves
unless $Bezierspline____loaded
	MATHS_PLUGINS = BezierContext.create
	MATHS_PLUGINS.load_modules
	$Bezierspline____loaded = true
end

end # module Bezierspline



