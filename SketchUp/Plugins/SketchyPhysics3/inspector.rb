require 'sketchup.rb'

module MSketchyPhysics3

def array_to_HTMLselect()
    html = '<select>'
    self.each { |ae|
        html += '<OPTION>'+ae.to_s
    }
    html += '</select>'
    return html
end


class PhysicsAppObserver < Sketchup::AppObserver

    def createSelectionObserver
        obj = PhysicsSelectionObserver.new
        Sketchup.active_model.selection.add_observer(obj)
        MSketchyPhysics3.clear_unique_objects
    end

    def initialize
        createSelectionObserver
    end

    def onNewModel(xx)
        createSelectionObserver
    end

    def onOpenModel(xx)
        createSelectionObserver
    end

end # class PhysicsAppObserver


class PhysicsSelectionObserver < Sketchup::SelectionObserver

    def initialize
        $spObjectInspector.cleanup if $spObjectInspector
        $spObjectInspector = PhysicsObjectInspector.new()
        @changed = false
    end

    def onSelectionAdded(selection, element)
        onSelectionBulkChange(selection)
    end

    def onSelectionRemoved(selection, element)
        onSelectionBulkChange(selection)
    end

    def onSelectionBulkChange(selection)
        $spObjectInspector.selectionChanged(selection) if $spObjectInspector
        @changed = true
    end

    def onSelectionCleared(selection)
        @changed = false
        UI.start_timer(0.1, false){
            next if @changed
            $spObjectInspector.selectionChanged(selection) if $spObjectInspector
        }
    end

end # class PhysicsSelectionObserver


class SketchyPhysics

    def self.addWatermarkText(x, y, text, name = 'watermark', component = 'versiontext.skp')
        dir = File.dirname(__FILE__)
        path = File.join(dir, "components/#{component}")
        return unless File.exists?(path)
        model = Sketchup.active_model
        view = model.active_view
        cd = model.definitions.load(path)
        ray = view.pickray(x,y)
        loc = ray[0]+ray[1]
        ci = model.entities.add_instance(cd, Geom::Transformation.new(loc))
        tt = ci.explode[0]
        tt.text = text
        tt.set_attribute('SketchyPhysics', 'name', name)
        mat = model.materials.add('WatermarkText')
        mat.color = [63, 78, 127]
        tt.material = nil
        tt.material = mat
        tt
    end

    def self.updateWaterMark(name, new_text)
        found = false
        Sketchup.active_model.entities.each { |ent|
            next unless ent.is_a?(Sketchup::Text)
            if ent.get_attribute('SketchyPhysics', 'name', nil) == name
                ent.text = new_text + "\n" + ent.text
                found = true
            end
        }
        found
    end

    @@last_active_model = nil
    @@first_time = true

    def self.checkVersion
        model = Sketchup.active_model
        return false if model == @@last_active_model
        @@last_active_model = model
        version = model.get_attribute('sketchyphysics', 'version', nil)
        sp_version = MSketchyPhysics3::VERSION
        # Load compatibility file to undo all script changes.
        unless @@first_time
          @@first_time = false
          dir = File.dirname(__FILE__)
          load File.join(dir, 'compatibility_current.rb')
        end
        # Add version text.
        if version.nil? || version != sp_version
            #~ ask = version.to_s.to_f.between?(3.0, 3.2)
            ask = false
            if ask
              msg = "SP #{version} detected. Your version is #{sp_version}. "
              msg << "Would you like to update the version attribute?"
              msg << "\n\nWarning: Updating version attribute may prevent "
              msg << "advanced scripted model from working in the future!"
              res = UI.messagebox(msg, MB_YESNO)
              update = (res == IDYES)
            else
              update = true
            end
            if update
              model.set_attribute('sketchyphysics', 'version', sp_version)
              text = "Requires SketchyPhysics #{sp_version} !"
              state = updateWaterMark('VersionWaterMark', text)
              if state
                if $spObjectInspector
                  model.start_operation('Fix Physics Errors')
                  $spObjectInspector.inspectModel
                  model.commit_operation
                end
              else
                addWatermarkText(10, 12, text, 'VersionWaterMark')
              end
              model.set_attribute('sketchyphysics', 'version', sp_version)
            end
            version = sp_version if version.nil?
            $sketchyphysics_version_loaded = version.to_f
        end
        true
    end

    def updateBodies
        @bodies = []
        Sketchup.active_model.entities.each { |ent|
            @bodies << ent if isBody(ent)
        }
    end

    def updateCollision(group)
    end

    def inspectCollision(group)
        shape = group.get_attribute('SPOBJ', 'shape', nil)
        shape = group.get_attribute('SPOBJ', 'advancedShape', nil) unless shape
        shapes = []
        shapes << shape if shape
        joints = []
        MSketchyPhysics3.get_entities(group).each { |ent|
            if isJoint(ent)
                joints << ent.get_attribute('SPJOINT', 'name', nil)
            elsif shape.nil? && isShape(ent)
                shapes << inspectCollision(ent)
            end
        }
        shapes << 'default' if shapes.empty?
        return shapes,joints
    end

end # class SketchyPhysics


class PhysicsObjectInspector

    def isPotentialPhysicsObject(ent)
        if ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
            return ent.get_attribute('SPOBJ', 'ignore', nil) ? false : true
        end
        false
    end

    def isShape(ent)
        if ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
            return ent.get_attribute('SPOBJ', 'ignore', nil) ? false : true
        end
        false
    end

    def isBody(ent)
        if (ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)) && ent.parent.is_a?(Sketchup::Model)
            return ent.get_attribute('SPOBJ', 'ignore', nil) ? false : true
        end
        false
    end

    def isJoint(ent)
        if (ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)) #~ && ent.parent.is_a?(Sketchup::Model)
            return ent.get_attribute('SPJOINT', 'name', nil) ? true : false
        end
        false
    end

    def initialize
        @idToGroup = {}
        @allJoints = {}
        @selected_object = nil
        @last_update_time = nil
        @dirty_field = nil
        @physicsInspectorDialog = nil
        selectionChanged(Sketchup.active_model.selection)
        #showDialog if Sketchup.read_default('SketchyPhysics', 'InspectorVisible', false)
    end

    def cleanup
        @physicsInspectorDialog.close() if @physicsInspectorDialog
        @physicsInspectorDialog = nil
    end

    # Anytime you see a joint register it with this function; improves speed.
    def registerJoint(grp)
        name = grp.get_attribute('SPJOINT', 'name', nil)
        raise(ArgumentError, 'Expected a joint.') unless name
        @allJoints[name] = grp
    end

    def findJoint(name)
        grp = @allJoints[name]
        return grp if grp && grp.valid?
        findAllJoints()
        @allJoints[name]
    end

    def makeJointsUnique(group)
        while group.parent.instances.length > 1
            nent = group.parent.instances[1]
            nent.make_unique
            nname = group.get_attribute('SPJOINT', 'type', nil) + nent.entityID.to_s + rand(1000).to_s
            nent.set_attribute('SPJOINT', 'name', nname)
            nent.name = nname
        end
    end

    def findAllJoints
        @allJoints = {}
        Sketchup.active_model.definitions.each { |cd|
            cd.instances.each { |ci|
                jname = ci.get_attribute('SPJOINT', 'name', nil)
                next unless jname
                # Confirm joint is unique
                if ci.parent.class != Sketchup::Model && ci.parent.instances.length > 1
                    # makeJointsUnique(ci)
                    #~ puts "warning " + ci.parent.instances.length.to_s
                    #~ nent = ci.parent.instances[1]
                    #~ nent.make_unique

                    #~ nname = ci.get_attribute('SPJOINT', 'type', nil)+nent.entityID.to_s+rand(1000).to_s
                    #~ nent.set_attribute('SPJOINT', 'name', nname)
                    #~ nent.name = nname

                    #oi = ci.parent.instances[1]
                    #jname = oi.get_attribute('SPJOINT', 'type', nil)+oi.entityID.to_s
                    #oi.parent.instances[1].set_attribute('SPJOINT', 'name', jname)
                end
                if @allJoints[jname]
                    #puts "Duplicated joint NAME #{jname} Renaming."
                    # Rename joint
                    #jname = ci.get_attribute('SPJOINT', 'type', nil) + ci.entityID.to_s
                    #ci.set_attribute('SPJOINT', 'name', jname)
                    #ci.name = jname
                end
                @allJoints[jname] = ci
            }
        }
        @allJoints
    end

    def onDialogSelectJoint(id, name)
        group = @idToGroup[id]
        unless group
            group = findJoint(name)
            unless group
                puts 'Error cant find joint'
                return
            end
        end
        inspectJointProperties(group)
    end

    def selectionChanged(selection)
        #return if @last_update_time and (Time.now - @last_update_time) < 0.25
        @last_update_time = Time.now
        sel = Sketchup.active_model.selection
        grps = []
        sel.each { |e|
            if e.is_a?(Sketchup::Group) or e.is_a?(Sketchup::ComponentInstance)
                grps << e
            end
        }
        @physicsInspectorDialog.execute_script("clearForm();") if @physicsInspectorDialog
        if grps.size != 1
            @selected_object = nil
            return
        end
        @selected_object = grps.first
        @idToGroup[@selected_object.entityID.to_s] = @selected_object
        inspectGroup(@selected_object)
    end

    def toggleDialog
        if @physicsInspectorDialog
            @physicsInspectorDialog.close
            #Sketchup.write_default('SketchyPhysics', 'InspectorVisible', false)
        else
            showDialog
            selectionChanged(Sketchup.active_model.selection)
            #Sketchup.write_default('SketchyPhysics', 'InspectorVisible', true)
        end
    end

    def dialogVisible?
        @physicsInspectorDialog ? true : false
    end

    def dialogCheckDirty
        if @dirty_field
            puts "Web dialog is dirty #{@dirty_field.inspect}" if @dirty_field
            return true
        end
        false
    end

    def dialogMarkDirty(id, dict, key, value)
        if @dirty_field
            @dirty_field = [id, dict, key, value]
            puts "Marking dirty #{@dirty_field.inspect}"
        end
    end

    def dialogClearDirty(id, dict, key, value)
        if @dirty_field
            if [id, dict, key, value] != @dirty_field
                puts "Warn:dirty value do not match: #{@dirty_field.inspect}"
            end
            @dirty_field = nil
            puts 'Cleared dirty'
        end
    end

    def dialogForceUpdate
        if @dirty_field
            java = 'document.getElementsByName("myInput")'
            @physicsInspectorDialog.execute_script(java)
        end
    end

    def showDialog
        dlg = UI::WebDialog.new('SketchyPhysics Inspector', true, 'SP3 Inspector')
        @physicsInspectorDialog = dlg
        last_called_time = nil
        dir = File.dirname(__FILE__)
        path = File.join(dir, 'html/inspector.html')
        dlg.set_file path
        if RUBY_PLATFORM =~ /mswin|mingw/i
            dlg.show { selectionChanged(Sketchup.active_model.selection) }
        else
            dlg.show_modal { selectionChanged(Sketchup.active_model.selection) }
        end
        dlg.set_on_close {
            cmd = 'active = document.activeElement;'
            cmd << 'if (active && active.tagName.indexOf("BODY") == -1 && active.tagName.indexOf("HTML") == -1) document.activeElement.blur();'
            dlg.execute_script(cmd)
            @physicsInspectorDialog = nil
            #Sketchup.write_default('SketchyPhysics', 'InspectorVisible', false)
        }
        dlg.add_action_callback('puts'){ |d,p| puts p }
        dlg.add_action_callback('open_link'){ |d, p|
            UI.openURL(p)
        }
        dlg.add_action_callback('open_ruby_core'){ |d, p|
            v = RUBY_VERSION =~ /1.8/ ? '1.8.6' : '2.0.0'
            UI.openURL("http://ruby-doc.org/core-#{v}/")
        }
        dlg.add_action_callback('valueUpdated'){ |d,p|
            path = p.split('=')[0].split('.')
            id = path[0]
            dict = path[1]
            key = path[2]
            value = p.split("=",2)[1].to_s
            value = d.get_element_value(value)
            @dirty_field = [id, dict, key, value]
            group = @idToGroup[id]
        }
        dlg.add_action_callback('setAttribute'){ |d,p|
            path = p.split('.')
            id = path[0]
            dict = path[1]
            key = path[2].split("=")[0]
            value = p.split("=")[1].to_s.to_f
            group = @idToGroup[id]
            @dirty_field = nil
            group.set_attribute(dict, key, value)
        }
        dlg.add_action_callback('setAttributeBool'){ |d,p|
            path = p.split('.')
            id = path[0]
            dict = path[1]
            key = path[2].split("=")[0]
            value = p.split("=")[1].to_s
            value = (value == 'true')
            group = @idToGroup[id]
            group.set_attribute(dict, key, value)
        }
        dlg.add_action_callback('setAttributeString'){ |d, p|
            # This prevents it from being called twice with no delay.
            next if (last_called_time && Time.now - last_called_time < 0.25)
            last_called_time = Time.now
            path = p.split('=')[0].split('.')
            id = path[0]
            dict = path[1]
            key = path[2]
            value = d.get_element_value(key)
            @dirty_field = nil
            group = @idToGroup[id]
            next unless group
            begin
                # Fix hard spaces.
                value = value.gsub(/[\xC2\xA0]/, "\s")
                if key == 'script'
                    # Add syntax checking here
                else
                    if $spExperimentalFeatures
                        cc = MSketchyPhysics3::SP3xControllerContext.new
                    else
                        cc = MSketchyPhysics3::ControllerContext.new
                    end
                    $curEvalGroup = group
                    cbinding = cc.getBinding(0)
                    #0.upto(value.length-1){ |i| puts [value[i], value[i].chr] }
                    result = eval(value, cbinding)
                end
                group.set_attribute(dict, key, value)
            rescue Exception => e
                if @physicsInspectorDialog
                    UI.messagebox "Script Error:\n#{e}"
                end
            ensure
                $curEvalGroup = nil
            end
        }
        dlg.add_action_callback('setAttributeString2'){ |d, p|
          path = p.split('.')
          id = path[0]
          dict = path[1]
          key = path[2].split('=')[0]
          value = p.split('=')[1].to_s
          group = @idToGroup[id]
          @dirty_field = nil
          group.set_attribute(dict, key, value) if group
        }
        dlg.add_action_callback('onSelectJoint'){ |d, p|
            param = p.split(',')
            id = param[0]
            name = param[1]
            onDialogSelectJoint(id, name)
        }
        dlg.add_action_callback('evalToNumeric'){ |d, id|
          val = d.get_element_value(id)
          begin
            num = eval(val)
            raise unless num.is_a?(Numeric)
          rescue Exception => e
            num = 0
          end
          cmd = "document.getElementById('#{id}').value = '#{sprintf('%.2f', num)}'"
          dlg.execute_script(cmd)
        }
    end

    def clearPropertyGrid
        return unless @physicsInspectorDialog
        @physicsInspectorDialog.execute_script("clearPropertyGrid()")
    end

    def propertyGridAddHeader(name)
        return unless @physicsInspectorDialog
        @physicsInspectorDialog.execute_script("addPropertyGridHeader('#{name}')")
    end

    def propertyGridAddRow(id, name, value, type)
        return unless @physicsInspectorDialog
        cmd = "addPropertyGridRow('#{id}','#{name}','#{value}','#{type}')"
        @physicsInspectorDialog.execute_script(cmd)
    end

    def inspectorAddObjectRef(container, id, name)
        return unless @physicsInspectorDialog
        cmd = "addObjectRef('#{container}','#{id}','#{name}')"
        @physicsInspectorDialog.execute_script(cmd)
    end

    def appendHTML(id, html)
        return unless @physicsInspectorDialog
        cmd = "document.getElementById('#{id}').innerHTML+='"+html+"';"
        @physicsInspectorDialog.execute_script(cmd)
    end

    def insertCell(tableId, text)
    end

    def inspectConnections(group)
        jnames = JointConnectionTool.getParentJointNames(group)
        return if jnames.empty?
        java = "addFlowTableHeader('childJointsGrid','<b>Connected To</b>');"
        @physicsInspectorDialog.execute_script(java)
        jnames.each { |jn|
            joint = findJoint(jn)
            if joint
                id = joint.entityID.to_s
                java = "addFlowTableCell('childJointsGrid','#{id}','#{jn}','#{jn}');"
                @physicsInspectorDialog.execute_script(java)
                @idToGroup[id] = group
                @idToGroup[id] = joint
            else
                #puts "Parent #{jn} not found. Delete connection?"
                JointConnectionTool.disconnectJointNamed(group, jn)
            end
        }
    end

    def inspectJoint(group)
        name = group.get_attribute('SPJOINT', 'name', 'error')
        type = group.get_attribute('SPJOINT', 'type', 'error')
        id = group.entityID.to_s
        java = "addFlowTableCell('childJointsGrid','#{id}','#{name}','#{name}');"
        @physicsInspectorDialog.execute_script(java)
        @idToGroup[id] = group
    end

    def inspectEvents(group)
        %w(timer onFreeze onUnfreeze onValueChanged).each do |key|
            value = group.get_attribute('SPEVENTS', key, nil)
        end
    end

    def escapeHTML(str)
        str = str.to_s.inspect[1..-2]
        str = str.gsub(/&/n, '&amp;').gsub(/\"/n, '&quot;').gsub(/>/n, '&gt;').gsub(/</n, '&lt;').gsub(/\n/n,"\\n").gsub(/\r/n,"").gsub("_", '&#95;').gsub(/\$/n,'&#36;').gsub(/ /n, '&nbsp;')#.gsub("'", '&#39;').gsub("\r", '\r').gsub("\n", '\n')
    end

    def checkJointVersion(joint)
        controller = joint.get_attribute('SPJOINT', 'controller', nil)
        return unless controller
        MSketchyPhysics3.convertControlledJoint(joint)
    end

    def oldcheckJointVersion(group)
        type = group.get_attribute('SPJOINT', 'type', nil)
        case type
            when 'hinge'
                unless group.get_attribute('SPJOINT', 'Controller', nil)
                    group.set_attribute('SPJOINT', 'Controller', '')
                end
                unless group.get_attribute('SPJOINT', 'DesiredRotation', nil)
                    group.set_attribute('SPJOINT', 'DesiredRotation', '')
                end
            when 'servo'
                unless group.get_attribute('SPJOINT', 'DesiredRotation', nil)
                    group.set_attribute('SPJOINT', 'DesiredRotation', '')
                end
            when 'slider'
                unless group.get_attribute('SPJOINT', 'Controller', nil)
                    group.set_attribute('SPJOINT', 'Controller', '')
                    group.set_attribute('SPJOINT', 'accel', 0.0)
                    group.set_attribute('SPJOINT', 'damp', 0.0)
                end
                unless group.get_attribute('SPJOINT', 'DesiredPosition', nil)
                    group.set_attribute('SPJOINT', 'DesiredPosition', '')
                end
            when 'piston'
                unless group.get_attribute('SPJOINT', 'DesiredRotation', nil)
                    group.set_attribute('SPJOINT', 'DesiredRotation', '')
                end
        end
    end

    def inspectJointProperties(group)
        # Convert to new style hinge.
        # This probably belongs elsewhere.
        #~ Sketchup.active_model.start_operation("Convert joint")
        checkJointVersion(group)
        tableBody = ""
        %w(min max accel maxAccel strength damp duration Controller onTick breakingForce ConnectedCollide GearConnectedCollide range falloff delay rate eachFrame gearjoint ratio).each { |key|
            value = group.get_attribute('SPJOINT', key, nil)
            next if value.nil?
            #value=escapeHTML(value)
            # why was this here?
            #propertyGridAddRow(group.entityID, 'spjoint.'+key, value, 'string')
            #tableBody += "<tr><td>#{key}:#{value.class}</td>"
            tableBody += "<tr><td>#{key}</td>"
            #onclick = "puts('#{group.entityID}');puts(this.name);puts(this.innerHTML);"
            fullName = group.entityID.to_s + '.SPJOINT.' + key
            tableBody += "<td>"
            if value.is_a?(Array)
                tableBody += array_to_HTMLselect(value)
            elsif value.is_a?(TrueClass) || value.is_a?(FalseClass)
                #value = group.get_attribute('SPOBJ', sn, false).to_s
                fullName = group.entityID.to_s + '.SPJOINT.' + key
                onclick = "setSkpAttributeBool(this.name, this.checked)"
                checked = value ? 'checked' : ''
                tableBody += "<input type='checkbox' onchange='#{onclick}' name='#{fullName}' #{checked}>"+""+'</input>'
            elsif value.is_a?(String)
                onchange = "setSkpAttributeString(this.name, this.id)"
                onkeydown = "tab_to_tab(event, this)"
                if key == 'Controller'
                    value = escapeHTML(value)
                    tableBody += "<input type='text' class='formulaInput' size='15' id='#{key}' onblur='#{onchange}' onkeyup='markDirty(this, this.name, this.id);' name='#{fullName}' value=#{value}>"
                else
                    tableBody+="<input type='text' id='#{key}' size='15' onblur='#{onchange}' id='#{key}' onkeyup='markDirty(this, this.name, this.id);' name='#{fullName}' value=#{value}>"
                end
            else
                onchange = "evalToNumeric(this.id); setSkpAttribute(this.name, this.value);"
                #tableBody += "<input type='text' size='15' onblur='#{onchange}' id='#{key}' onkeypress='validateNumber();' onkeyup='markDirty(this, this.name, this.id);'  name='#{fullName}' value=#{value}>"
                tableBody += "<input type='text' size='15' onblur='#{onchange}' id='#{key}' name='#{fullName}' value='#{sprintf('%.2f', value.to_f)}'>"
            end
            tableBody += "</td></tr>"
        }
        type = group.get_attribute('SPJOINT', 'type', nil)
        if %w(hinge servo corkscrew ball).include?(type)
          name = group.entityID.to_s + '.SPJOINT.' + 'angleUnit'
          units = %w(radian degree)
          selected = group.get_attribute('SPJOINT', 'angleUnit', 'degree')
          selected = 'degree' unless units.include?(selected)
          tableBody += "<tr><td>Min/Max Angle Unit</td>"
          tableBody += "<td><select name='#{name}' onchange='setSkpAttributeString2(this.name, this.options[this.selectedIndex].value)'>"
          units.each { |unit|
            tableBody += "<option #{unit == selected ? 'selected' : ''} value='#{unit}'>#{unit.capitalize}</option>"
          }
          tableBody += "</select></td></tr>"
        elsif %w(slider piston).include?(type)
          name = group.entityID.to_s + '.SPJOINT.' + 'lengthUnit'
          units = %w(millimeter centimeter decimeter meter inch foot yard)
          selected = group.get_attribute('SPJOINT', 'lengthUnit', 'inch')
          selected = 'inch' unless units.include?(selected)
          tableBody += "<tr><td>Min/Max Length Unit</td>"
          tableBody += "<td><select name='#{name}' onchange='setSkpAttributeString2(this.name, this.options[this.selectedIndex].value)'>"
          units.each { |unit|
            tableBody += "<option #{unit == selected ? 'selected' : ''} value='#{unit}'>#{unit.capitalize}</option>"
          }
          tableBody += "</select></td></tr>"
        end

        html = "<TABLE  class='propertyGrid' style='width:99%;'>" + tableBody + "</table>"
        #html="<tr><td>Key</td><input type='text'  size='30'    value='123'>"
        java = 'document.getElementById("childJointProperties").innerHTML="'+html+'"'
        #java='document.getElementById("childJointProperties").innerHTML="TEST"'
        @physicsInspectorDialog.execute_script(java)
        #@physicsInspectorDialog.bring_to_front()
    end

    def xxinspectJoint(group)
        name = group.get_attribute('SPJOINT', 'name', 'error')
        str = "Joint:" + name
        propertyGridAddHeader(str)
        type = group.get_attribute('SPJOINT', 'type', 'error')
        desc = ''
        # Create a new property grid
        tableBody = ''
        #tableBody += '<th colspan=2>'+type+'</th>'
        #@physicsInspectorDialog.execute_script(java)
        #inspectorAddObjectRef('parentJointsContainer', group.entityID, group.get_attribute('SPJOINT', 'type', 'error')+'<br>')
        group.attribute_dictionary('SPJOINT').each_pair { |key, value|
            next if key == 'name' or key == 'type'
            propertyGridAddRow(group.entityID, 'spjoint.'+key, value, 'string')
            tableBody += "<tr><td>#{key}:#{value.class}</td>"
            #onclick = "puts('#{group.entityID}');puts(this.name);puts(this.innerHTML);"
            fullName = group.entityID.to_s+".SPJOINT."+key
            tableBody += "<td>"
            if value.is_a?(Array)
                tableBody += array_to_HTMLselect(value)
            elsif value.class.is_a?(String)
                onchange = "setSkpAttributeString(this.name, this.value)"
                tableBody += "<input type='text' size='8' onchange='#{onchange}' onblur='#{onchange}' onkeyup='markDirty(this,this.name,this.id);'  onselect='puts(document.selection.createRange().text)' name='#{fullName}' value=#{value}>"
            else
                onchange="setSkpAttribute(this.name,this.value)"
                tableBody += "<input type='text' size='8' onchange='#{onchange}' onblur='#{onchange}' onkeypress='validateNumber();' onkeyup='markDirty(this,this.name,this.id);' onselect='puts(document.selection.createRange().text)' name='#{fullName}' value=#{value}>"
            end
            #controllerTypes=["LAxisUD","LAxisLR","RAxisUD","RAxisLR"]
            #tableBody+=["none","LAxisUD","LAxisLR","RAxisUD","RAxisLR"].to_HTMLselect()
            #to_html(name, type, selectedIndex, onChange)
            tableBody += "</td></tr>"
        }
        desc = type
        tableDef = "<img src='../images/#{type}.png' onclick='toggleDiv(\\\"#{name}\\\")' style='width:16px;height:16px%'>#{desc}<img src='../images/plus.gif' onclick='toggleDiv(\\\"#{name}\\\")'>"
        tableDef += "<div id='#{name}' style='display:none'><TABLE  class='propertyGrid' style='width:99%;'>"
        html = tableDef + tableBody + "</table></div>"
        java = 'document.getElementById("childJointsContainer").innerHTML+="'+html+'"'
        @physicsInspectorDialog.execute_script(java)
        @idToGroup[group.entityID.to_s] = group
        #inspectorAddObjectRef('parentJointsContainer', group.entityID, desc)
    end

    def inspectShape(group)
        shape = group.get_attribute('SPOBJ', 'shape', nil)
        shape = group.get_attribute('SPOBJ', 'advancedShape', 'default') unless shape
        #str = "shape #{shape} #{group}"
        html = "<img src='../images/small/#{shape}.png' style='width:16px;height:16px%'>#{shape}</img>"
        #id=group.entityID.to_s
        #@idToGroup[id]=group
        #java = "addFlowTableCell('childJointsGrid','#{id}','#{shape}','#{shape}');"
        #@physicsInspectorDialog.execute_script(java)
        java = 'document.getElementById("childObjectsContainer").innerHTML+="'+html+'"'
        @physicsInspectorDialog.execute_script(java)
        #inspectorAddObjectRef('childObjectsContainer', group.entityID, shape)
        propertyGridAddRow(group.entityID, 'Shape', shape, 'static')
    end

    # SPParents
    # Jan 12, 09 Unused??
    #~ def inspectState(group)
        #~ java="addFlowTableHeader('childJointsGrid','<b>State</b>');"
        #~ #puts java if $debug
        #~ @physicsInspectorDialog.execute_script(java)
        #~ statenames=['ignore',"frozen","static","staticmesh","showcollision"]
        #~ statenames.each{|sn|
            #~ value=group.get_attribute('SPOBJ',sn,false).to_s
            #~ checked=""
            #~ checked="checked" if(value=='true')

            #~ html="<input type='checkbox' onClick='#{onclick}' name='#{fullName}' #{checked}>"+sn+'</input>'
            #~ puts html
            #~ java="addFlowTableCell('childJointsGrid','#{0}','','#{sn}');"
            #~ puts java if $debug
            #~ @physicsInspectorDialog.execute_script(java)
        #~ }
    #~ end

    #class PhysicsView
      #def update(model)
    #

    def inspectCollision(group)
        shape = group.get_attribute('SPOBJ', 'shape', nil)
        shape = group.get_attribute('SPOBJ', 'advancedShape', nil) unless shape
        shapes = []
        shapes << shape if shape
        joints = []
        MSketchyPhysics3.get_entities(group).each { |ent|
            if isJoint(ent)
                joints << ent.get_attribute('SPJOINT', 'name', nil)
            elsif shape.nil? && isShape(ent)
                shapes << inspectCollision(ent)
            end
        }
        shapes << 'default' if shapes.empty?
        return shapes,joints
    end

    def inspectModel
        #puts "ROOT"
        #puts " Version"
        #puts " Settings"
        #puts " Bodies"
        #bodies = []
        #findAllJoints()
        #puts " Joints"
        allJoints = {}
        Sketchup.active_model.definitions.each { |cd|
            cd.instances.each { |ci|
                # Convert old style joint connections.
                if ci.get_attribute('SPOBJ', 'numParents', nil)
                    JointConnectionTool.convertConnections(ci)
                end
                if isJoint(ci)
                    checkJointVersion(ci)
                    name = ci.get_attribute('SPJOINT', 'name', nil)
                    #puts "  Joint:#{name}"
                    puts "!!Duplicated joint #{name}" if allJoints[name]
                    allJoints[name] = ci
                end
            }
        }
        children = []
        Sketchup.active_model.entities.each { |ent|
            if isBody(ent)
                #ent.make_unique
                #bodies.push(ent)
                #puts "  Body:#{ent} Name:#{ent.name}" if $debug
                #puts "  version:" if $debug
                shapes,joints=inspectCollision(ent)
                # Remove any hierarchy.
                shapes.flatten!
                joints.flatten!
                #puts "  shapes:"+shapes.inspect if (shapes.length>0) if $debug
                #puts "  joints:"+joints.inspect if (joints.length>0) if $debug
                parents = JointConnectionTool.getParentJointNames(ent)
                if MSketchyPhysics3.get_definition(ent).instances[0]!=ent && (parents.length>0 || joints.length>0)
                    unless parents.empty?
                        puts "!!Dupe body with connections!"
                        #JointConnectionTool.disconnectAllJoints(ent)
                    end
                    unless joints.empty?
                        puts "!!Dupe body with joints!"
                        #~ ent.make_unique
                        MSketchyPhysics3.get_entities(ent).each { |pe|
                            type = pe.get_attribute('SPJOINT', 'type', nil)
                            next unless type
                            # Rename joint.
                            #~ pe.make_unique
                            nname = type + (20000 + rand(80000)).to_s
                            pe.set_attribute('SPJOINT', 'name', nname)
                            pe.name = nname
                            puts "Renaming to #{nname}."
                        }
                    end
                end
                #~ # if a not instance[0] then this objecs is a dupe.
                #~ if(MSketchyPhysics3.get_definition(ent).instances[0]!=ent && joints.length>0)
                    #~ puts "!!Dupe body with joints!"
                    #~ ent.make_unique
                    #~ MSketchyPhysics3.get_entities(ent).each{|pe|
                        #~ if(pe.get_attribute('SPJOINT','type',nil)!=nil)
                            #~ #rename joint.
                            #~ #pe.make_unique
                            #~ nname=pe.get_attribute('SPJOINT','type',nil)+(20000+rand(80000)).to_s
                            #~ pe.set_attribute('SPJOINT','name',nname)
                            #~ pe.name=nname
                            #~ puts "Renaming to #{nname}."
                        #~ end
                    #~ }
                #~ end
                common = parents & joints
                unless common.empty?
                    puts "!!Body is connected to #{common.length} of its own joints. Disconnecting."
                    common.each { |jn|
                        JointConnectionTool.disconnectJointNamed(ent,jn)
                    }
                end
                # puts "  connected to:"+parents.inspect if (parents.length>0) if $debug
                children << ent unless parents.empty?
            end
            if isJoint(ent)
                name = ent.get_attribute('SPJOINT', 'name', nil)
                #puts "  Joint:#{ent} Name:#{name}" if $debug
            end
        }
        #puts " Connections" if $debug
        children.each { |ent|
            parents = JointConnectionTool.getParentJointNames(ent)
            parents.each { |parentName|
                joint = allJoints[parentName]
                if joint
                    #puts "  Body #{ent} connected to #{parentName}" if $debug
                else
                    puts "!!Joint not found: #{parentName}"
                    JointConnectionTool.disconnectJointNamed(ent, parentName)
                    # fix
                end
            }
        }
    end

    def inspectGroup(group)
        return unless @physicsInspectorDialog
        propertyGridAddHeader('State')
        ###### HACK. Convert old style static meshes to new.
        if group.get_attribute('SPOBJ', 'shape', nil) == 'staticmesh'
            #group.set_attribute('SPOBJ',"shape",nil);
            #group.set_attribute('SPOBJ',"staticmesh",true);
        end
        html = '<table><tr>'
        statenames = %w(ignore frozen static staticmesh showcollision noautofreeze magnetic nocollison)
        statenames.each{ |sn|
            value = group.get_attribute('SPOBJ', sn, false)
            fullName = group.entityID.to_s + '.SPOBJ.' + sn
            onclick = "setSkpAttributeBool(this.name, this.checked)"
            checked = value ? 'checked' : ''
            html += "<td><input type='checkbox' onblur='#{onclick}' onchange='#{onclick}' name='#{fullName}' #{checked}>"+sn+'</input></td>'
        }
        html += '</tr></table>'
        cmd = "document.getElementById('stateContainer').innerHTML+=\"#{html}\";"
        @physicsInspectorDialog.execute_script(cmd)

        str = ''
        unless isJoint(group)
            statenames = %w(density magnet thruster emitter touchable tickable scripted) # materialid
            statenames.each { |sn|
                value = group.get_attribute('SPOBJ', sn, nil)
                checked = value ? 'checked' : ''
                fullName = group.entityID.to_s + '.SPOBJ.' + sn
                onclick = "setSkpAttributeBool(this.name, this.checked)"
                if sn == 'magnet'
                    strength = escapeHTML(group.get_attribute('SPOBJ', 'strength', 0.0))
                    strname = group.entityID.to_s + '.SPOBJ.' + 'strength'
                    onchange="setSkpAttributeString(this.name, this.id)"
                    html = "<div class='propertyGrid'><table width='100%'><tr><td width='25%' valign='bottom'>"
                    html += "<input type='checkbox' onchange='#{onclick}' name='#{fullName}' #{checked}>Magnet"+'</input></td>'
                    html += "<td width='25%' align='right' valign='bottom'>Strength</td>"
                    html += "<td><input type='text' class='formulaInput' id='strength' style='width:98%' onblur='#{onchange}' onkeyup='markDirty(this,this.name,this.id);' name='#{strname}' value=#{strength}></input>"
                    html += "</td></tr></table></div>"
                    #html = "<br>Magnet Strength<input type='text' size='6' onblur='#{onchange}' name='#{strname}' value='"+strength.to_s+"'></input>"
                elsif sn == 'thruster'
                    strength = escapeHTML(group.get_attribute('SPOBJ', 'tstrength', 0.0))
                    strname = group.entityID.to_s + '.SPOBJ.' + 'tstrength'
                    onchange = "setSkpAttributeString(this.name,this.id)"
                    html = "<div class='propertyGrid'><table width='100%'><tr><td width='25%'>"
                    html += "<input type='checkbox' onchange='#{onclick}' name='#{fullName}' #{checked}>Thruster"+'</input>'
                    html += "<td width='25%' align='right' valign='bottom'>Strength</td>"
                    html += "<td><input type='text' class='formulaInput' id='tstrength' style='width:98%' onblur='#{onchange}' onkeyup='markDirty(this,this.name,this.id);' name='#{strname}' value=#{strength}></input>"
                    html += "</td></tr></table></div>"
                elsif sn == 'materialid'
                    matName = escapeHTML(group.get_attribute('SPOBJ', 'materialid', 0))
                    strname = group.entityID.to_s+'.SPOBJ.'+ 'materialid'
                    onchange = "setSkpAttribute(this.name, this.value)"
                    html = "<div class='propertyGrid'><table width='100%'><tr><td width='50%'>"
                    html += "</td><td>"
                    html += "</td><td>MaterialID<input type='text' size='5' onblur='#{onchange}' onkeypress='validateNumber();' onkeyup='markDirty(this,this.name,this.id);'  name='#{strname}' value=#{matName}>"
                    #html+="ID<input type='text' class='formulaInput' id='materialid' size='12' onBlur='#{onchange}' name='#{strname}' value=#{matName}></input>"
                    html+="</td></tr></table></div>"
                elsif sn == 'density'
                    default = Sketchup.active_model.get_attribute('SPSETTINGS', 'defaultobjectdensity', 0.2).to_f
                    density = group.get_attribute('SPOBJ', 'density', default).to_f
                    density = 0.2 if density <= 0
                    density = escapeHTML(density)
                    strname = group.entityID.to_s + '.SPOBJ.' + 'density'
                    onchange = "setSkpAttribute(this.name, this.value)"
                    html = "<div class='propertyGrid'><table><tr>"
                    html += "<td>Density</td>"
                    html += "<td><input type='text' size='5' onblur='#{onchange}'  onkeypress='validateNumber();' onkeyup='markDirty(this,this.name,this.id);'  name='#{strname}' value=#{density}></td>"
                    #html + ="ID<input type='text' class='formulaInput' id='materialid' size='12' onblur='#{onchange}' name='#{strname}' value=#{matName}></input>"
                    html += "</tr></table></div>"
                elsif sn == 'emitter'
                    html = "<div class='propertyGrid'><table width='100%'><tr><td width='25%'>"
                    html += "<input type='checkbox' onchange='#{onclick}' name='#{fullName}' #{checked}>Emitter"+'</input></td>'
                    onchange = "setSkpAttributeString(this.name,this.id)"
                    strname = group.entityID.to_s + '.SPOBJ.' + 'emitterstrength'
                    strength = escapeHTML(group.get_attribute('SPOBJ', 'emitterstrength', 0.0))
                    html += "<td width='25%' align='right' valign='bottom'>Strength</td>"
                    html += "<td><input type='text' class='formulaInput' id='emitterstrength' style='width:98%;' onblur='#{onchange}'  onkeyup='markDirty(this,this.name,this.id);' name='#{strname}' value=#{strength}></input></td>"
                    html += "</tr></table>"
                    onchange = "setSkpAttributeString(this.name, this.id)"
                    rate = escapeHTML(group.get_attribute('SPOBJ', 'emitterrate', 0))
                    ratestrname = group.entityID.to_s + '.SPOBJ.' + 'emitterrate'
                    html += "<table width='100%'>"
                    html += "<tr><td width='50%' align='right' valign='bottom'>Rate</td>"
                    html += "<td><input type='text' class='formulaInput' id='emitterrate' style='width:98%' onblur='#{onchange}'  onkeyup='markDirty(this,this.name,this.id);' name='#{ratestrname}' value=#{rate}></input></td>"
                    html += "</tr></table>"
                    lifetime = escapeHTML(group.get_attribute('SPOBJ', 'lifetime', 0).to_i)
                    strname = group.entityID.to_s + '.SPOBJ.' + 'lifetime'
                    onchange = "setSkpAttribute(this.name, this.value)"
                    html += "<table width='100%'>"
                    html += "<tr><td width='50%' align='right' valign='bottom'>Lifetime</td>"
                    html += "<td><input type='text' style='width:98%' onblur='#{onchange}' id='lifetime' onkeypress='validateNumber();' onkeyup='markDirty(this,this.name,this.id);' name='#{strname}' value=#{lifetime}></td>"
                    html += "</tr></table>"
                    c = group.get_attribute('SPOBJ', 'emit_continuous_collision_mode', false) ? 'checked' : ''
                    html += "<table width='100%'>"
                    html += "<tr title='Enabling this will prevent emitted bodies from passing other bodies at high speeds.'>"
                    html += "<td width='50%' align='right' valign='bottom'>Emit Continuous Collision Mode</td>"
                    html += "<td><input type='checkbox' onchange='#{onclick}' name='#{group.entityID.to_s + '.SPOBJ.' + 'emit_continuous_collision_mode'}' #{c}></input></td>"
                    html += "</tr></table>"
                    html += "</div>"
                elsif sn == 'touchable'
                    toggleclick = onclick + ';setDivVisibility(\"ontouch\",this.checked)'
                    html = "<div class='propertyGrid' ><table width='100%'><tr>"
                    html += "<td width='50%'><input type='checkbox' onchange='#{toggleclick}' name='#{fullName}' #{checked}>OnTouch"+'</input></td>'
                    onchange = "setSkpAttributeString(this.name,this.id)"
                    rate = escapeHTML(group.get_attribute('SPOBJ', 'touchrate', 0))
                    ratestrname = group.entityID.to_s + '.SPOBJ.' + 'touchrate'
                    html += "<td width='1%' align='right' valign='bottom'>Rate</td><td><input type='text' id='touchrate' style='width:98%' onkeypress='validateNumber();'  onkeyup='markDirty(this,this.name,this.id);' onblur='#{onchange}' name='#{ratestrname}' value=#{rate}></input>"
                    html += "</td>"
                    strname = group.entityID.to_s + '.SPOBJ.' + 'ontouch'
                    ontouch = escapeHTML(group.get_attribute('SPOBJ', 'ontouch', ''))
                    vis = (checked == 'checked') ? 'block' : 'none'
                    html += "<table width='99%'><tr><td><textarea class='formulaInput' type='text' cols=30 ROWS=6 style='width:100%; display:#{vis};' class='formulaInput' id='ontouch' onblur='#{onchange}' onkeyup='markDirty(this,this.name,this.id);'  name='#{strname}' value=#{ontouch}>#{ontouch}</textarea>"
                    html += "</td></tr></table></div>"
                elsif sn == 'tickable'
                    toggleclick = onclick + ';setDivVisibility(\"ontick\",this.checked)'
                    html = "<div class='propertyGrid'><table width='100%'><tr>"
                    html += "<td width='50%'><input type='checkbox' onchange='#{toggleclick}' name='#{fullName}' #{checked}>OnTick"+'</input></td>'
                    onchange = "setSkpAttributeString(this.name, this.id)"
                    rate = escapeHTML(group.get_attribute('SPOBJ', 'tickrate', 0))
                    ratestrname = group.entityID.to_s + '.SPOBJ.' + 'tickrate'
                    html += "<td width='1%' align='right' valign='bottom'>Rate</td><td><input type='text' id='tickrate' style='width:98%' onkeypress='validateNumber();' onblur='#{onchange}'  onkeyup='markDirty(this,this.name,this.id);' name='#{ratestrname}' value=#{rate}></input>"
                    html += "</td>"
                    strname = group.entityID.to_s + '.SPOBJ.' + 'ontick'
                    ontick = escapeHTML(group.get_attribute('SPOBJ', 'ontick', ''))
                    vis = (checked == 'checked') ? 'block' : 'none'
                    html += "<table width='99%'><tr><td><textarea class='formulaInput' type='text' cols=30 ROWS=6 style='width:100%; display:#{vis};' class='formulaInput' id='ontick' onblur='#{onchange}' onkeyup='markDirty(this,this.name,this.id);' name='#{strname}' value=#{ontick}>#{ontick}</textarea>"
                    html += "</td></tr></table></div>"
                elsif sn == 'scripted'
                    toggleclick = onclick + ';setDivVisibility(\"script\",this.checked)'
                    html = "<div class='propertyGrid'><table width='100%'><tr>"
                    html += "<td><input type='checkbox' onchange='#{toggleclick}' name='#{fullName}' #{checked}>Scripted</input></td>"
                    html += "<td style='text-align:left;'><pre style='font-size:11px; padding:0; margin:0;'><a id='http://www.sketchup.com/intl/en/developer/' href='#' onclick='open_link(this.id);'>SketchUp API</a> | <a id='ruby_core' href='#' onclick='open_ruby_core();'>Ruby Core</a> | <a id='http://sketchyphysics.wikia.com/wiki/SketchyPhysicsWiki' href='#' onclick='open_link(this.id);'>SP Wiki</a></pre></td>"
                    onchange = "setSkpAttributeString(this.name,this.id)"
                    strname = group.entityID.to_s + '.SPOBJ.' + 'script'
                    script = escapeHTML(group.get_attribute('SPOBJ', 'script', ''))
                    vis = (checked == 'checked') ? 'block' : 'none'
                    html += "<table width='99%'><tr><td><textarea class='formulaInput' type='text' WRAP=OFF cols=30 ROWS=12 style='width:100%; display:#{vis};' class='formulaInput' id='script' onblur='#{onchange}' onkeyup='markDirty(this,this.name,this.id);' onkeydown='AllowTabCharacter();' name='#{strname}' value=#{script}>#{script}</textarea>"
                    html += "</td></tr></table></div>"
                end
                str += html
            }
            str = 'document.getElementById("propertiesContainer").innerHTML="'+str+'";'
            #script = escapeHTML(group.get_attribute('SPOBJ', 'script', ''))
            #str += 'setScriptCode(document.getElementById('script').value);'
            #str += 'setScriptCode("FFoobar");'
            @physicsInspectorDialog.execute_script(str)
        end
        str = ''
        if isJoint(group)
            str = 'document.getElementById("selectedObjectName").innerHTML+="('+group.get_attribute('SPJOINT', 'type', 'error')+')";'
            @physicsInspectorDialog.execute_script(str)
            # Set dialog name field
            str = 'document.getElementById("selectedObjectName").innerHTML="Joint:'+group.name+'";'
            @physicsInspectorDialog.execute_script(str)
            inspectJoint(group)
            onDialogSelectJoint(group.entityID, group.get_attribute('SPJOINT', 'name', 'error'))
            return
        end
        inspectConnections(group)
        #java = "addFlowTableHeader('childJointsGrid','<b>Shapes</b>');"
        #@physicsInspectorDialog.execute_script(java)
        shape = group.get_attribute('SPOBJ', 'shape', nil)
        shape = group.get_attribute('SPOBJ', 'advancedShape', nil) unless shape
        if shape
            propertyGridAddHeader('Shape:' + shape)
            str = 'document.getElementById("selectedObjectName").innerHTML+="('+shape+')";'
            @physicsInspectorDialog.execute_script(str)
            inspectShape(group)
            # set dialog name field
            str = 'document.getElementById("selectedObjectName").innerHTML="Body:'+group.name+'";'
            @physicsInspectorDialog.execute_script(str)
            # Now find joints. Probably want to do this at the same time as above.
            java = "addFlowTableHeader('childJointsGrid','<b>Internal</b>');"
            @physicsInspectorDialog.execute_script(java)
            MSketchyPhysics3.get_entities(group).each { |ent|
                inspectJoint(ent) if isJoint(ent)
            }
            return
        end
        # case if user selected an object in a group.
        unless group.parent.is_a?(Sketchup::Model)
            propertyGridAddHeader('Shape:default')
            inspectShape(group)
            str = 'document.getElementById("selectedObjectName").innerHTML="Shape:'+group.name+'";'
            @physicsInspectorDialog.execute_script(str)
            return
        end
        bIsCompound = false
        MSketchyPhysics3.get_entities(group).each { |ent|
            if isShape(ent)
                unless bIsCompound
                    bIsCompound = true
                    propertyGridAddHeader('Compound Object')
                    str = 'document.getElementById("selectedObjectName").innerHTML="Compound Object:'+group.name+'";'
                    @physicsInspectorDialog.execute_script(str)
                    #puts 'Body is compound' if $debug
                end
                inspectShape(ent)
            end
            # Add joint check here.
        }
        java = "addFlowTableHeader('childJointsGrid','<b>Internal</b>');"
        #puts java if $debug
        @physicsInspectorDialog.execute_script(java)
        # Now find joints. Probably want to do this at the same time as above.
        MSketchyPhysics3.get_entities(group).each { |ent|
            inspectJoint(ent) if isJoint(ent)
        }
        if shape.nil? && !bIsCompound
            propertyGridAddHeader('Body is default shape')
            str = 'document.getElementById("selectedObjectName").innerHTML="Body:(box):'+group.name+'";'
            @physicsInspectorDialog.execute_script(str)
        end
    end

    def dialogSelect(grp)
    end

    def inspectSelection
        dialogSelect(Sketchup.active_model.selection[0])
    end

    def onLButtonDown(flags, x, y, view)
        @dragCount = 0
        @lButtonDown = true
        @inputPoint = Sketchup::InputPoint.new
        @inputPoint.pick view, x, y
        ph = view.pick_helper
        num = ph.do_pick x,y
        ent = ph.best_picked
        if ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
            Sketchup.active_model.selection.clear
            Sketchup.active_model.selection.add(ent)
            inspectSelection
        end
    end

    def deactivate(view)
        @physicsInspectorDialog.close if @physicsInspectorDialog
        Sketchup.set_status_text ''
    end

    def draw(view)
        #@relatedBounds.each { |rb| view.draw(GL_LINE_STRIP, rb) }
    end

    def getExtents
        bb = Geom::BoundingBox.new
        if(@inputPoint!=nil)
            bb.add @inputPoint.position
            bb.add @inputPoint.position
        end
    end

    # This is called followed directly by onRButtonDown
    def getMenu(menu)
    end

    def onCancel(reason, menu)
    end

    def onKeyDown(key, rpt, flags, view)
        @ctrlDown = true if key == COPY_MODIFIER_KEY && rpt == 1
        @shiftDown = true if key == CONSTRAIN_MODIFIER_KEY && rpt == 1
    end

    def onKeyUp(key, rpt, flags, view)
        @ctrlDown = false if key == COPY_MODIFIER_KEY
        @shiftDown = false if key == CONSTRAIN_MODIFIER_KEY
    end

    def pickEmbeddedJoint(x,y,view)
        ph = view.pick_helper
        num = ph.do_pick x,y
        item = nil
        path = ph.path_at(1)
        return item unless path
        path.length.downto(0){ |i|
            if (path[i].is_a?(Sketchup::Group) &&
                    (path[i].parent.is_a?(Sketchup::Model) || path[i].get_attribute('SPJOINT', 'name', nil) != nil))
                item = path[i]
                #puts "ParentGroup = #{item}" if $debug
                break
            end
        }
        return item
    end

    # NOTE: Called after onLButtonDown and onLButtonUp.
    def onLButtonDoubleClick(flags, x, y, view)
    end

    def onLButtonUp(flags, x, y, view)
    end

    def onMouseMove(flags, x, y, view)
    end

    #def onMouseEnter(view)
    #end

    #def onMouseLeave(view)
    #end

    # NOTE: Called after onrButtonDown and onRButtonUp.
    def onRButtonDoubleClick(flags, x, y, view)
    end

    def onMButtonDoubleClick(flags, x, y, view)
    end

    def onRButtonDown(flags, x, y, view)
    end

    def onMButtonDown(flags, x, y, view)
    end

    def onMButtonUp(flags, x, y, view)
    end

    # Called not only right after a onRButtonDown, but after a onRButtonDoubleClick?
    def onRButtonUp(flags, x, y, view)
    end

    # NOTE: onReturn is followed directly by onKeyDown
    def onReturn(view)
    end

    def onUserText(text, view)
    end

    # Called when I double-click middle mouse button (exits out of orbit)
    def resume(view)
        @ctrlDown = false
        @shiftDown = false
    end

    # Called when I press middle mouse button (goes into orbit)
    def suspend(view)
    end

end # class PhysicsObjectInspector

Sketchup.add_observer(PhysicsAppObserver.new)

end # module MSketchyPhysics3
