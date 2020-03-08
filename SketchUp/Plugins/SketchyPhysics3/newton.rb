require 'sketchup.rb'

dir = File.dirname(__FILE__)
if RUBY_VERSION =~ /1.8/
  require File.join(dir, 'lib/dl/import.rb')
  require File.join(dir, 'lib/dl/struct.rb')
else
  require 'fiddle/import.rb'
end

module MSketchyPhysics3
  class << self

    # Dump top level faces
    # Recursively dump the definitions
    # Create instances
    def dumpit
        geom = []
        instances = []
        definitions = {}
        Sketchup.active_model.entities.each { |ent|
            if ent.is_a?(Sketchup::Face)
                pts = []
                ent.mesh.points.each { |p| pts.push(p.to_a) }
                geom << [pts.length, ent.normal.to_a, pts]
            elsif ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
                dguid = MSketchyPhysics3.get_definition(ent).guid
                unless definitions[dguid]
                    out = []
                    dumpents(MSketchyPhysics3.get_definition(ent).entities, out)
                    definitions[dguid] = out
                end
                instances << ent
            end
        }
        #puts ['Geom', geom.length].inspect
        #puts ['Definitions', definitions.length].inspect
        #puts ['Instances', instances.length].inspect
        #dumpents(Sketchup.active_model.entities,out)
        return [geom, definitions, instances]
    end

    def dumpents(ents, out)
        ents.each { |ent|
            if ent.is_a?(Sketchup::Face)
                pts = []
                ent.mesh.points.each { |p| pts << p.to_a }
                out << [pts.length, ent.normal.to_a, pts]
                #puts [ent.class, ent.vertices.length].inspect
            elsif ent.is_a?(Sketchup::Group) || ent.is_a?(Sketchup::ComponentInstance)
                dumpents(MSketchyPhysics3.get_definition(ent).entities, out)
            end
        }
    end

    def testRender
        group = Sketchup.active_model.selection[0]
        tris = []
        normals = []
        group.entities.each { |ent|
            if ent.is_a?(Sketchup::Face)
                normals += ent.normal.to_a
                normals += ent.normal.to_a
                normals += ent.normal.to_a
                ent.mesh.polygons.each_index { |pi|
                    pts = ent.mesh.polygon_points_at( pi+1 ).each { |pt|
                        tris = tris + pt.to_a
                    }
                }
            end
        }
        SketchyRender.buildDisplayList(tris.to_a.pack('f*'), normals.to_a.pack('f*'), tris.length/3).to_i
    end

  end # proxy class
end # module MSketchyPhysics3


module MSketchyPhysics3::SketchyRender

    extend RUBY_VERSION =~ /1.8/ ? DL::Importable : Fiddle::Importer
    dir = File.dirname(__FILE__)

    if RUBY_PLATFORM =~ /mswin|mingw/i
        #dlload File.join(dir, 'lib/SketchyRender.dll')
    else
        #dlload File.join(dir, 'lib/libNewtonServer3.dylib')
    end
    #extern "int buildDisplayList(float*, float*, int)"

end # module MSketchyPhysics3::SketchyRender


module MSketchyPhysics3::NewtonServer

    dir = File.dirname(__FILE__)
    extend RUBY_VERSION =~ /1.8/ ? DL::Importable : Fiddle::Importer

    if RUBY_PLATFORM =~ /mswin|mingw/i
        dlload File.join(dir, 'lib/NewtonServer3.dll')
        # extern "int readJoystick(float *)"
        # extern "int initDirectInput()"
        # extern "void freeDirectInput()"
    else
        dlload File.join(dir, 'lib/libNewtonServer3.dylib')
    end

    extern "void init()"
    extern "void stop()"
    extern "void update(int)"
    extern "int fetchSingleUpdate(float*)"
    extern "void* fetchAllUpdates()"
    extern "void requestUpdate(int)"
    extern "void* NewtonCommand(void*, void*)"
    extern "int CreateBallJoint(float*, NewtonBody*, NewtonBody*)"
    extern "int CreateJoint(void*, float*, float*, NewtonBody*, NewtonBody*, float*)"
    extern "void BodySetMagnet(NewtonBody*, CMagnet*, float*)"
    extern "int GetBodyCollision(NewtonBody*, float*, int)"
    extern "void SetBodyCenterOfMass(NewtonBody*, float*)"
    extern "void BodySetFreeze(NewtonBody*, int)"
    extern "void setJointData(void*, float*)"
    extern "void addImpulse(NewtonBody*, float*, float*)"
    extern "void MagnetMove(CMagnet*, float*)"
    extern "CGlobalForce* addGlobalForce(float*, float*, int, int, int)"
    extern "CGlobalForce* addForce(NewtonBody*, float)"
    extern "void setForceStrength(CGlobalForce*, float)"
    extern "void setBodyMagnetic(NewtonBody*, int)"
    extern "void setBodySolid(NewtonBody*, int)"
    extern "void BodySetMaterial(NewtonBody*, int)"

    extern "CMagnet* MagnetAdd(float*)"
    extern "NewtonCollision* CreateCollision(void*, float*, float*, float*)"
    extern "NewtonCollision* CreateCollisionMesh(float*, int)"

    extern "void DestroyBody(NewtonBody*)"
    extern "void DestroyJoint(NewtonJoint*)"
    extern "void SetMatrix(NewtonBody*, dFloat*, int)"

    extern "NewtonBody* CreateBody(int, NewtonCollision*, int, int, float*, float*, float)"
    extern "void setupBouyancy(float*, float*, float*)"
    extern "int CreateGear(void*, float*, float*, NewtonBody*, NewtonBody*, float)"
    extern "void setJointRotation(ControlledJoint*, float*)"
    extern "void setJointPosition(ControlledJoint*, float*)"
    extern "void setJointAccel(ControlledJoint*, float*)"
    extern "void setJointDamp(ControlledJoint*, float*)"
    extern "void setJointCollisionState(NewtonCustomJoint*, int)"
    extern "void bodyGetVelocity(NewtonBody*, float*)"
    extern "void bodySetVelocity(NewtonBody*, float*)"
    extern "void bodyGetTorque(NewtonBody*, float*)"
    extern "void bodySetTorque(NewtonBody*, float*)"

    extern "void bodySetLinearDamping(NewtonBody*, float)"
    extern "void bodySetAngularDamping(NewtonBody*, float*)"

    extern "void setDesiredMatrix(DesiredJoint*, float*)"
    extern "void setDesiredParams(DesiredJoint*, float*)"

    extern "void bodySetThrust(NewtonBody*, float)"
    extern "void setGyroPinDir(CustomUpVector*, float*)"
    extern "void setBodyCollideCallback(NewtonBody*, void*)"
    extern "void glueBodies(NewtonBody*, NewtonBody*, float)"

    extern "int NewtonWorldGetVersion()"
    extern "void NewtonBodyGetMassMatrix(NewtonBody*, float*, float*, float*, float*)"
    extern "void NewtonBodySetMassMatrix(NewtonBody*, float, float, float, float)"
    extern "void NewtonBodyGetCentreOfMass(NewtonBody*, float*)"
    extern "void NewtonBodySetCentreOfMass(NewtonBody*, com*)"
    extern "void NewtonWorldFreezeBody(NewtonWorld*, NewtonBody*)"
    extern "void NewtonWorldUnfreezeBody(NewtonWorld*, NewtonBody*)"
    extern "NewtonCollision* NewtonBodyGetCollision(NewtonBody*)"
    extern "float NewtonConvexCollisionCalculateVolume(NewtonCollision*)"
    extern "void NewtonConvexCollisionCalculateInertialMatrix(NewtonCollision*, float*, float*)"
    extern "NewtonWorld* NewtonBodyGetWorld(NewtonBody*)"
    extern "int NewtonBodyGetSleepingState(NewtonBody*)"
    extern "void NewtonBodyGetMatrix(NewtonBody*, float*)"
    extern "void NewtonBodySetMatrix(NewtonBody*, float*)"
    extern "void NewtonBodyGetOmega(NewtonBody*, float*)"
    extern "void NewtonBodySetOmega(NewtonBody*, float*)"
    extern "void NewtonBodyGetVelocity(NewtonBody*, float*)"
    extern "void NewtonBodySetVelocity(NewtonBody*, float*)"
    extern "void NewtonBodyGetTorque(NewtonBody*, float*)"
    extern "void NewtonBodySetTorque(NewtonBody*, float*)"
    extern "void NewtonBodyAddTorque(NewtonBody*, float*)"
    extern "void NewtonBodyGetForce(NewtonBody*, float*)"
    extern "void NewtonBodySetForce(NewtonBody*, float*)"
    extern "void NewtonBodyAddForce(NewtonBody*, float*)"
    extern "void* NewtonBodyGetUserData(NewtonBody*)"
    extern "void NewtonBodySetUserData(NewtonBody*, void*)"
    extern "int NewtonBodyGetMaterialGroupID(NewtonBody*)"
    extern "void* NewtonBodyGetForceAndTorqueCallback(NewtonBody*)"
    extern "void NewtonBodySetForceAndTorqueCallback(NewtonBody*, void*)"
    extern "int NewtonBodyGetContinuousCollisionMode(NewtonBody*)"
    extern "void NewtonBodySetContinuousCollisionMode(NewtonBody*, int)"
    extern "void NewtonAddBodyImpulse(NewtonBody*, float*, float*)"

    # In Ruby 2.x.x all capitalized functions remain capitalized.
    if RUBY_VERSION.to_f > 1.8
      def self.newtonCommand(*args); NewtonCommand(*args) end
      def self.createBallJoint(*args); CreateBallJoint(*args) end
      def self.createJoint(*args); CreateJoint(*args) end
      def self.bodySetMagnet(*args); BodySetMagnet(*args) end
      def self.getBodyCollision(*args); GetBodyCollision(*args) end
      def self.setBodyCenterOfMass(*args); SetBodyCenterOfMass(*args) end
      def self.bodySetFreeze(*args); BodySetFreeze(*args) end
      def self.magnetMove(*args); MagnetMove(*args) end
      def self.bodySetMaterial(*args); BodySetMaterial(*args) end
      def self.magnetAdd(*args); MagnetAdd(*args) end
      def self.createCollision(*args); CreateCollision(*args) end
      def self.createCollisionMesh(*args); CreateCollisionMesh(*args) end
      def self.destroyBody(*args); DestroyBody(*args) end
      def self.destroyJoint(*args); DestroyJoint(*args) end
      def self.setMatrix(*args); SetMatrix(*args) end
      def self.createBody(*args); CreateBody(*args) end
      def self.createGear(*args); CreateGear(*args) end
      def self.newtonWorldGetVersion(*args); NewtonWorldGetVersion(*args) end
      def self.newtonBodyGetMassMatrix(*args); NewtonBodyGetMassMatrix(*args) end
      def self.newtonBodySetMassMatrix(*args); NewtonBodySetMassMatrix(*args) end
      def self.newtonBodyGetCentreOfMass(*args); NewtonBodyGetCentreOfMass(*args) end
      def self.newtonBodySetCentreOfMass(*args); NewtonBodySetCentreOfMass(*args) end
      def self.newtonWorldFreezeBody(*args); NewtonWorldFreezeBody(*args) end
      def self.newtonWorldUnfreezeBody(*args); NewtonWorldUnfreezeBody(*args) end
      def self.newtonBodyGetCollision(*args); NewtonBodyGetCollision(*args) end
      def self.newtonConvexCollisionCalculateVolume(*args); NewtonConvexCollisionCalculateVolume(*args) end
      def self.newtonConvexCollisionCalculateInertialMatrix(*args); NewtonConvexCollisionCalculateInertialMatrix(*args) end
      def self.newtonBodyGetWorld(*args); NewtonBodyGetWorld(*args) end
      def self.newtonBodyGetSleepingState(*args); NewtonBodyGetSleepingState(*args) end
      def self.newtonBodyGetMatrix(*args); NewtonBodyGetMatrix(*args) end
      def self.newtonBodySetMatrix(*args); NewtonBodySetMatrix(*args) end
      def self.newtonBodyGetOmega(*args); NewtonBodyGetOmega(*args) end
      def self.newtonBodySetOmega(*args); NewtonBodySetOmega(*args) end
      def self.newtonBodyGetVelocity(*args); NewtonBodyGetVelocity(*args) end
      def self.newtonBodySetVelocity(*args); NewtonBodySetVelocity(*args) end
      def self.newtonBodyGetTorque(*args); NewtonBodyGetTorque(*args) end
      def self.newtonBodySetTorque(*args); NewtonBodySetTorque(*args) end
      def self.newtonBodyAddTorque(*args); NewtonBodyAddTorque(*args) end
      def self.newtonBodyGetForce(*args); NewtonBodyGetForce(*args) end
      def self.newtonBodySetForce(*args); NewtonBodySetForce(*args) end
      def self.newtonBodyAddForce(*args); NewtonBodyAddForce(*args) end
      def self.newtonBodyGetUserData(*args); NewtonBodyGetUserData(*args) end
      def self.newtonBodySetUserData(*args); NewtonBodySetUserData(*args) end
      def self.newtonBodyGetMaterialGroupID(*args); NewtonBodyGetMaterialGroupID(*args) end
      def self.newtonBodyGetForceAndTorqueCallback(*args); NewtonBodyGetForceAndTorqueCallback(*args) end
      def self.newtonBodySetForceAndTorqueCallback(*args); NewtonBodySetForceAndTorqueCallback(*args) end
      def self.newtonBodyGetContinuousCollisionMode(*args); NewtonBodyGetContinuousCollisionMode(*args) end
      def self.newtonBodySetContinuousCollisionMode(*args); NewtonBodySetContinuousCollisionMode(*args) end
      def self.newtonAddBodyImpulse(*args); NewtonAddBodyImpulse(*args) end
    end

    def doCollideCallback(body0, body1, contact_speed, x, y, z)
        return unless $curPhysicsSimulation
        return unless $sketchyPhysicsToolInstance
        #MSketchyPhysics3::NewtonServer.glueBodies(body1, body0, 3300.0)
        if $sketchyPhysicsToolInstance.method(:handleOnTouch).arity == 3
          if $sketchyphysics_version_loaded > 3.2
            s = $curPhysicsSimulation.getWorldScale
            pos = [x*s, y*s, z*s]
          else
            pos = [x, y, z]
          end
          $sketchyPhysicsToolInstance.handleOnTouch([body0, body1], contact_speed, pos)
        else
          # Make it compatible with SP3RC1.
          $sketchyPhysicsToolInstance.handleOnTouch([body0, body1])
        end
    end

    def tempForceAndTorqueCallback(body_ptr, timestep, thread_index)
        return unless $curPhysicsSimulation
        return unless $sketchyPhysicsToolInstance
        # Apply Gravity
        mass = (0.chr*4).to_ptr
        ixx  = (0.chr*4).to_ptr
        iyy  = (0.chr*4).to_ptr
        izz  = (0.chr*4).to_ptr
        MSketchyPhysics3::NewtonServer.newtonBodyGetMassMatrix(body_ptr, mass, ixx, iyy, izz)
        mass = mass.to_a('F')[0]
        gravity = [0, 0, -$curPhysicsSimulation.getGravity*mass*10].pack('F*')
        MSketchyPhysics3::NewtonServer.newtonBodySetForce(body_ptr, gravity)
        # Apply stored forces.
        force = $curPhysicsSimulation.applied_force.to_a.pack('FFF')
        torque = $curPhysicsSimulation.applied_torque.to_a.pack('FFF')
        $curPhysicsSimulation.applied_force = [0,0,0]
        $curPhysicsSimulation.applied_torque = [0,0,0]
        MSketchyPhysics3::NewtonServer.newtonBodyAddForce(body_ptr, force)
        MSketchyPhysics3::NewtonServer.newtonBodyAddTorque(body_ptr, torque)
    end

    if RUBY_VERSION =~ /1.8/
      COLLIDE_CALLBACK = (callback "void doCollideCallback(body*, body*, float, float, float, float)")
      TEMP_FORCE_CALLBACK = (callback "void tempForceAndTorqueCallback(body*, float, int)")
    else
      ptr = Fiddle::TYPE_VOIDP
      float = Fiddle::TYPE_FLOAT
      int = Fiddle::TYPE_INT

      params = [ptr, ptr, float, float, float, float]
      COLLIDE_CALLBACK = bind_function(:collide_callback, Fiddle::TYPE_VOID, params){ |body0, body1, contact_speed, x, y, z|
        next unless $curPhysicsSimulation
        next unless $sketchyPhysicsToolInstance
        if $sketchyPhysicsToolInstance.method(:handleOnTouch).parameters.size == 3
          if $sketchyphysics_version_loaded > 3.2
            s = $curPhysicsSimulation.getWorldScale
            pos = [x*s, y*s, z*s]
          else
            pos = [x, y, z]
          end
          $sketchyPhysicsToolInstance.handleOnTouch([body0, body1], contact_speed, pos)
        else
          # Make it compatible with SP3RC1.
          $sketchyPhysicsToolInstance.handleOnTouch([body0, body1])
        end
      }

      params = [ptr, float, int]
      TEMP_FORCE_CALLBACK = bind_function(:temp_force_callback, Fiddle::TYPE_VOID, params){ |body_ptr, timestep, thread_index|
        next unless $curPhysicsSimulation
        next unless $sketchyPhysicsToolInstance
        # Apply Gravity
        mass = 0.chr*4
        ixx  = 0.chr*4
        iyy  = 0.chr*4
        izz  = 0.chr*4
        MSketchyPhysics3::NewtonServer.newtonBodyGetMassMatrix(body_ptr, mass, ixx, iyy, izz)
        mass = mass.unpack('F')[0]
        gravity = [0, 0, -$curPhysicsSimulation.getGravity*mass*10].pack('F*')
        MSketchyPhysics3::NewtonServer.newtonBodySetForce(body_ptr, gravity)
        # Apply stored forces.
        force = $curPhysicsSimulation.applied_force.to_a.pack('FFF')
        torque = $curPhysicsSimulation.applied_torque.to_a.pack('FFF')
        $curPhysicsSimulation.applied_force = [0,0,0]
        $curPhysicsSimulation.applied_torque = [0,0,0]
        MSketchyPhysics3::NewtonServer.newtonBodyAddForce(body_ptr, force)
        MSketchyPhysics3::NewtonServer.newtonBodyAddTorque(body_ptr, torque)
      }
    end

end # MSketchyPhysics3::NewtonServer
