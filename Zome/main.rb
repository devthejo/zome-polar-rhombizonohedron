#https://github.com/takion/zome-polar-rhombizonohedron jo@redcat.ninja

require 'sketchup.rb'
module Takion
	module Zome
		include Math
		class Zome
			def self.gen_dh
				obj = self.new
				obj.zome_dh()
			end
			def self.gen_al
				obj = self.new
				obj.zome_al()
			end
			def self.gen_ah
				obj = self.new
				obj.zome_ah()
			end
			def self.gen_ad
				obj = self.new
				obj.zome_ad()
			end
			
			def initialize
				
			end
			def start
				@mo = Sketchup.active_model
				Sketchup::set_status_text(LH["Zome modelisation in progress..."])
				@mo.start_operation LH["PolarZonohedron - Structure Processing"]
				@t1 = Time.now
				@entities = @mo.active_entities.add_group.entities
			end
			def ending
				@mo.commit_operation
			end
			def add_note(msg)
				@mo.add_note msg, 0, 0.03
			end
			def rayon_polygone_regulier n_cotes,segment_length
				return (segment_length/2.0)/(Math::sin((360.0/n_cotes)/(2.0*(180.0/Math::PI))))
			end
			def aire_polygone_regulier n_cotes,segment_length,radius
				if not radius
					radius = rayon_polygone_regulier n_cotes,segment_length
				end
				area = n_cotes*(0.5*(segment_length*Math::sqrt((radius*radius)-((segment_length*segment_length)/4.0))))*@u_inch*1000.0
				return area.inch
			end
			def draw_face(pts)
				if(@gen_zome['T_Modelisation']==LH['Faces'])
					face = @entities.add_face(pts)
					face.back_material = @gen_zome['RVB_BACK_FACES']
					face.material = @gen_zome['RVB_FACES']
				end
				if(@gen_zome['T_Modelisation']==LH['Squelette'])
					line = @entities.add_line( pts )
				end
			end
			def create_polarzonaedre(draw, bases, niveaux, sinus, cosinus, hypotenus)
				@arretes_nb = (bases*2*niveaux)-bases
				@tirants_nb = (bases*2*niveaux)/2
				@segments_nb = @arretes_nb+@tirants_nb
				@connecteurs_nb = (bases*niveaux)+1
				
				msg = ""
				vector = Geom::Vector3d.new(sinus,0,cosinus)
				vector.length = hypotenus
				pts=[]
				points=[]
				pts[0] = Geom::Point3d.new(0,0,0)
				
				1.upto(niveaux){ |i|
					p_rotate = Geom::Transformation.rotation( pts[0] , Geom::Vector3d.new(0,0,1), i*2*Math::PI/bases )

					pts[1] = pts[0].transform( vector )
					pts[3] = pts[1].transform( p_rotate )
					pts[2] = pts[3].transform( vector )
					# mb = i*2*Math::PI/bases
					# UI.messagebox "#{mb.radians}"
					points[i] = []
					0.upto(bases-1){ |j| 
						f_rotate = Geom::Transformation.rotation( Geom::Point3d.new(0,0,0) , Geom::Vector3d.new(0,0,1), j*2*Math::PI/bases)
						points[i][j] = pts.collect{|p| p.transform(f_rotate)}
						
					}
					pts[0] = pts[3]
				}
				rot = Geom::Transformation.rotation [0,0,0], X_AXIS, 180.degrees
				hauteur_r = points[niveaux-1][0][2][2]

				faces = []
				1.upto(niveaux){ |i|
					0.upto(bases-1){ |j|
						points[i][j].collect{|p|
							p.transform!(rot)
							p[2]+=hauteur_r
						}
						if(draw==true)
							pt1 = points[i][j][1]
							pt3 = points[i][j][3]
							pt4 = points[i][j][0]
							if(@gen_zome['T_Ties']==LH['Horizontal'])
								if(i<niveaux)
									pt2 = points[i][j][2]
									faces.push [pt1,pt2,pt3] 
								end
								faces.push [pt1,pt4,pt3]
								faces.push [pt3,pt1,pt4] #tirants						
							end
							if(@gen_zome['T_Ties']==LH['None'])
								if(i<niveaux)
									pt2 = points[i][j][2]
									faces.push [pt4,pt1,pt2,pt3]
								else
									faces.push [pt1,pt4,pt3]
								end
							end
						end			
					}
				}
				faces.collect{|face|draw_face(face)}
				
				diametre_r = (points[niveaux-1][0][2].distance [0,0,0]) *2
				if(draw==true)
					# if(@gen_zome['T_Tuiles2D']=='Yes')
						# create_tiles @gen_zome
					# end
					msg += rapport_complet @gen_zome
				end
				return [diametre_r,hauteur_r,msg]
			end
			def create_tiles params
				
			end
			def rapport_complet params
				sixbranch_connection = (@connecteurs_nb-(params['N_Cotes']*2))-1
				msg = ""
				msg += " "+LH["Sides"]+": #{params["N_Cotes"]} \n"
				msg += " "+LH["Layers"]+": #{params["N_Niveaux"]} \n"
				msg += " "+LH["Height"]+": #{params["L_Hauteur"]} \n"
				msg += " "+LH["Ground diameter"]+": #{params["L_Diametre"]} \n"
				# msg += " Aire au sol: #{@ground_area}² \n"
				msg += "\n "+LH["Number of connectors"]+": #{@connecteurs_nb} \n"
				msg += " #{params['N_Cotes']} x "+LH["Connectors"]+" 4 "+LH["branches"]+" \n"
				msg += " #{sixbranch_connection} x "+LH["Connectors"]+" 6 "+LH["branches"]+" \n"
				msg += " #{params['N_Cotes']} x "+LH["Connectors"]+" 5 "+LH["branches"]+" \n"
				msg += " 1 x "+LH["Connectors"]+" #{params['N_Cotes']} "+LH["branches"]+" \n"
				msg += "\n "+LH["Segments total number"]+": #{@segments_nb} \n"
				#msg += " "+LH["Segments total length"]+": #{segments_lenth} \n"
				msg += " "+LH["Number of Ties"]+": #{@tirants_nb} \n"
				
				msg += "\n© "+LH["Zome Creator - OpenSource software developed by Jo"]+" - jo@redcat.ninja \nhttps://github.com/takion/zome-polar-rhombizonohedron/"
				
				return msg
			end
			def zome_al
				config = [
					['N_Cotes',10,LH['Sides of rotation around the axis']],
					['N_Niveaux',5,LH['Vertical Layer']],
					['L_AngleDeForme',35.2643896827547,LH['Shape angle']],
					['L_Arrete',1.m,LH['Edges']],
					['T_Ties',LH['Horizontal'],LH['Ties'],LH["Horizontal|None"]],
					['T_Ground',LH['No'],LH['Ground'],LH["Yes|No"]],
					['T_Modelisation',LH['Faces'],LH['Modelisation'],LH["Squelette|Faces"]]
				]
				@gen_zome = {} if not @gen_zome
				0.upto(config.length-1){ |i|
					@gen_zome[config[i][0]] = config[i][1] if not @gen_zome[config[i][0]]
				}
				
				results = nil
				prompts = []
				defaults = []
				drops = []
				0.upto(config.length-1){ |i|
					defaults.push config[i][1]
					prompts.push config[i][2]
					if(config[i][3])
						drops.push config[i][3]
					else
						drops.push ''
					end
				}
				begin
					results = UI.inputbox prompts,defaults,drops,LH['Polar Zonohedron based on shape angle and edges']
					return unless results
					0.upto(config.length-1){ |i|
						@gen_zome[config[i][0]] = results[i]
					}
					#<validation>
					raise LH["Number of layers different from the number of needed sides"]  if ( @gen_zome['N_Niveaux'] == @gen_zome['N_Cotes'] )
					raise LH["Required a number of layers not equal to null"]  if ( @gen_zome['N_Niveaux'] <= 0 )
					raise LH["Minimum 2 layers required for coherent Zome"]  if ( @gen_zome['N_Niveaux'] < 2 )
					raise LH["Required a number of sides not equal to null"]  if( @gen_zome['N_Cotes'] <= 0 )
					raise LH["Minimum 3 sides required for coherent Zome"]  if ( @gen_zome['N_Cotes'] < 3 )
					raise LH["Angle can't be equal to 90"]  if ( @gen_zome['L_AngleDeForme'] == 90 )
					#</validation>
				rescue
					#UI.messagebox $!.message
					#retry
				end
				
				start
				
				angle_forme = @gen_zome['L_AngleDeForme'].degrees
				hypotenus = @gen_zome['L_Arrete']
				msg = ""
				
				sinus = Math::cos(angle_forme)
				cosinus = Math::sin(angle_forme)
				retour = create_polarzonaedre(true,@gen_zome['N_Cotes'],@gen_zome['N_Niveaux'],sinus,cosinus,hypotenus)
				
				msg += LH["Sides"]+": #{@gen_zome['N_Cotes']} \n"
				msg += LH["Layers"]+": #{@gen_zome['N_Niveaux']} \n"
				msg += LH["Diameter"]+": #{retour[0].inch} \n"
				msg += LH["Height"]+": #{retour[1].inch} \n"
				msg += LH["Shape angle"]+": #{angle_forme.radians} \n"
				msg += LH["Edges"]+": #{hypotenus.inch} \n"
				
				msg += retour[2]
				
				add_note msg
				ending
			end

			def zome_ah
				config = [
					['N_Cotes',10,LH['Sides of rotation around the axis']],
					['N_Niveaux',5,LH['Vertical Layer']],
					['L_AngleDeForme',35.2643896827547,LH['Shape angle']],
					['L_Hauteur',3000.mm,LH['Height at the top']],
					['T_Ties',LH['Horizontal'],LH['Ties'],LH["Horizontal|None"]],
					['T_Ground',LH['No'],LH['Ground'],LH["Yes|No"]],
					['T_Modelisation',LH['Faces'],LH['Modelisation'],LH["Squelette|Faces"]]
				]
				@gen_zome = {} if not @gen_zome
				0.upto(config.length-1){ |i|
					@gen_zome[config[i][0]] = config[i][1] if not @gen_zome[config[i][0]]
				}
				
				results = nil
				prompts = []
				defaults = []
				drops = []
				0.upto(config.length-1){ |i|
					defaults.push config[i][1]
					prompts.push config[i][2]
					if(config[i][3])
						drops.push config[i][3]
					else
						drops.push ''
					end
				}
				begin
					results = UI.inputbox prompts,defaults,drops,LH['PolarZonohedron by shapes angle and height']
					return unless results
					0.upto(config.length-1){ |i|
						@gen_zome[config[i][0]] = results[i]
					}
					#<validation>
					raise LH["Required a number of layers not equal to null"]  if ( @gen_zome['N_Niveaux'] <= 0 )
					raise LH["Minimum 2 layers required for coherent Zome"]  if ( @gen_zome['N_Niveaux'] < 2 )
					raise LH["Required a number of sides not equal to null"]  if( @gen_zome['N_Cotes'] <= 0 )
					raise LH["Minimum 3 sides required for coherent Zome"]  if ( @gen_zome['N_Cotes'] < 3 )
					raise LH["Required height not equal to null"]  if ( @gen_zome['L_Hauteur'] <= 0 )
					raise LH["Angle can't be 90"]  if ( @gen_zome['L_AngleDeForme'] == 90 )
					#</validation>
				rescue
					UI.messagebox $!.message
					retry
				end
				
				start
				
				msg = ""
				
				angle_forme = @gen_zome['L_AngleDeForme'].degrees

				adjacent = @gen_zome['L_Hauteur']/@gen_zome['N_Niveaux']
				hypotenus = adjacent/angle_forme
				oppose = Math::sqrt(hypotenus*hypotenus - adjacent*adjacent)
				
				sinus = Math::cos(angle_forme)
				cosinus = Math::sin(angle_forme)
				
				retour1 = create_polarzonaedre(false,@gen_zome['N_Cotes'],@gen_zome['N_Niveaux'],sinus,cosinus,hypotenus)
				hypotenus *= @gen_zome['L_Hauteur']/retour1[1]
				retour2 = create_polarzonaedre(true,@gen_zome['N_Cotes'],@gen_zome['N_Niveaux'],sinus,cosinus,hypotenus)
				
				msg += LH["Bases"]+": #{@gen_zome['N_Cotes']} \n"
				msg += LH["Layers"]+": #{@gen_zome['N_Niveaux']} \n"
				msg += LH["Diameter"]+": #{retour2[0].inch} \n"
				msg += LH["Height"]+": #{retour2[1].inch} \n"
				msg += LH["Shape angle"]+": #{angle_forme.radians} \n"
				msg += LH["Edges"]+": #{hypotenus.inch} \n"
				msg += retour2[2]
				add_note msg
				ending
			end
		
			
			def zome_ad
				config = [
					['N_Cotes',10,LH['Sides of rotation around the axis']],
					['N_Niveaux',5,LH['Vertical Layer']],
					['L_AngleDeForme',35.2643896827547,LH['Shape angle']],
					['L_Diametre',6000.mm,LH['Ground diameter']],
					['T_Ties',LH['Horizontal'],LH['Ties'],LH["Horizontal|None"]],
					['T_Ground',LH['No'],LH['Ground'],LH["Yes|No"]],
					['T_Modelisation',LH['Faces'],LH['Modelisation'],LH["Squelette|Faces"]]
				]
				@gen_zome = {} if not @gen_zome
				0.upto(config.length-1){ |i|
					@gen_zome[config[i][0]] = config[i][1] if not @gen_zome[config[i][0]]
				}
				
				results = nil
				prompts = []
				defaults = []
				drops = []
				0.upto(config.length-1){ |i|
					defaults.push config[i][1]
					prompts.push config[i][2]
					if(config[i][3])
						drops.push config[i][3]
					else
						drops.push ''
					end
				}
				begin
					results = UI.inputbox prompts,defaults,drops,LH['PolarZonohedron by shapes angle and diameter']
					return unless results
					0.upto(config.length-1){ |i|
						@gen_zome[config[i][0]] = results[i]
					}
					#<validation>
					raise LH["Required a number of layers not equal to null"]  if ( @gen_zome['N_Niveaux'] <= 0 )
					raise LH["Minimum 2 layers required for coherent Zome"]  if ( @gen_zome['N_Niveaux'] < 2 )
					raise LH["Required a number of sides not equal to null"]  if( @gen_zome['N_Cotes'] <= 0 )
					raise LH["Minimum 3 sides required for coherent Zome"]  if ( @gen_zome['N_Cotes'] < 3 )
					raise LH["Required diameter not equal to null"]  if ( @gen_zome['L_Diametre'] <= 0 )
					raise LH["Angle can't be 90"]  if ( @gen_zome['L_AngleDeForme'] == 90 )
					#</validation>
				rescue
					UI.messagebox $!.message
					retry
				end
				
				start
				
				msg = ""
				
				angle_forme = @gen_zome['L_AngleDeForme'].degrees
				
				hypotenus = @gen_zome['L_Diametre']/2/Math::PI
				sinus = Math::cos(angle_forme)
				cosinus = Math::sin(angle_forme)
				
				retour1 = create_polarzonaedre(false,@gen_zome['N_Cotes'],@gen_zome['N_Niveaux'],sinus,cosinus,hypotenus)
				hypotenus *= @gen_zome['L_Diametre']/retour1[0]	
				retour2 = create_polarzonaedre(true,@gen_zome['N_Cotes'],@gen_zome['N_Niveaux'],sinus,cosinus,hypotenus)
				
				msg += LH["Bases"]+": #{@gen_zome['N_Cotes']} \n"
				msg += LH["Layers"]+": #{@gen_zome['N_Niveaux']} \n"
				msg += LH["Diameter"]+": #{retour2[0].inch} \n"
				msg += LH["Height"]+": #{retour2[1].inch} \n"
				msg += LH["Shape angle"]+": #{angle_forme.radians} \n"
				msg += LH["Edges"]+": #{hypotenus.inch} \n"
				msg += retour2[2]
				add_note msg
				ending
			end

			def zome_dh
				config = [	
					['N_Cotes',10,LH['Sides of rotation around the axis']],
					['N_Niveaux',5,LH['Vertical Layer']],
					['L_Diametre',6000.mm,LH['Ground diameter']],
					['L_Hauteur',3000.mm,LH['Height at the top']],
					['T_Ties',LH['None'],LH['Ties'],LH["Horizontal|None"]],
					['T_Ground',LH['No'],LH['Ground'],LH["Yes|No"]],
					['T_Modelisation',LH['Faces'],LH['Modelisation'],LH["Squelette|Faces"]]
				]
				@gen_zome = {} if not @gen_zome
				0.upto(config.length-1){ |i|
					@gen_zome[config[i][0]] = config[i][1] if not @gen_zome[config[i][0]]
				}
				
				results = nil
				prompts = []
				defaults = []
				drops = []
				0.upto(config.length-1){ |i|
					defaults.push config[i][1]
					prompts.push config[i][2]
					if(config[i][3])
						drops.push config[i][3]
					else
						drops.push ''
					end
				}
				begin
					results = UI.inputbox prompts,defaults,drops,LH['Polar Zonohedron based on diameter and height']
					return unless results
					0.upto(config.length-1){ |i|
						@gen_zome[config[i][0]] = results[i]
					}
					#<validation>
					raise LH["Required a number of layers not equal to null"]  if ( @gen_zome['N_Niveaux'] <= 0 )
					raise LH["Minimum 2 layers required for a coherent Zome"]  if ( @gen_zome['N_Niveaux'] < 2 )
					raise LH["Required a number of sides not equal to null"]  if( @gen_zome['N_Cotes'] <= 0 )
					raise LH["Minimum 3 sides required for a coherent Zome"]  if ( @gen_zome['N_Cotes'] < 3 )
					raise LH["Diameter can't be equal to null"]  if ( @gen_zome['L_Diametre'] <= 0 )
					raise LH["Required height not equal to null"]  if ( @gen_zome['L_Hauteur'] <= 0 )
					#</validation>
				rescue
					UI.messagebox $!.message
					retry
				end
				
				start
				
				
				msg = ""
				
				adjacent = @gen_zome['L_Hauteur']/@gen_zome['N_Niveaux']
				
				oppose = @gen_zome['L_Diametre']/@gen_zome['N_Niveaux']/2
				hypotenus = Math::sqrt(adjacent*adjacent + oppose*oppose)
				sinus = oppose/hypotenus
				cosinus = adjacent/hypotenus
				retour1 = create_polarzonaedre(false,@gen_zome['N_Cotes'],@gen_zome['N_Niveaux'],sinus,cosinus,hypotenus)
				ndiametre = @gen_zome['L_Diametre']*(@gen_zome['L_Diametre']/retour1[0])
				
				oppose = ndiametre/@gen_zome['N_Niveaux']/2
				hypotenus = Math::sqrt(adjacent*adjacent + oppose*oppose)
				sinus = oppose/hypotenus
				cosinus = adjacent/hypotenus
				retour2 = create_polarzonaedre(true,@gen_zome['N_Cotes'],@gen_zome['N_Niveaux'],sinus,cosinus,hypotenus)
				
				msg += LH["Bases"]+": #{@gen_zome['N_Cotes']} \n"
				msg += LH["Layers"]+": #{@gen_zome['N_Niveaux']} \n"
				msg += LH["Diameter"]+": #{@gen_zome['L_Diametre'].inch} \n"
				msg += LH["Height"]+": #{@gen_zome['L_Hauteur'].inch} \n"
				msg += LH["Edges"]+": #{hypotenus.inch} \n"
				# msg += LH["Shape angle"]+": #{Math::asin(cosinus).radians} \n"
				msg += LH["Shape angle"]+": #{Math::acos(sinus).radians} \n"
				msg += LH["Angle between the axes and the edge of the top layer"]+": #{Math::asin(sinus).radians} \n"
				
				msg += retour2[2]
				
				add_note msg
				ending
			end
		end
		zomes_menu = UI.menu("Plugins").add_submenu("Zome")
		zomes_menu.add_item(LH['by diameter and height']) { Zome.gen_dh() }
		zomes_menu.add_item(LH["by angle and edges"]) { Zome.gen_al() }
		zomes_menu.add_item(LH["by angle and height"]) { Zome.gen_ah() }
		zomes_menu.add_item(LH["by angle and diameter"]) { Zome.gen_ad() }
		file_loaded(File.basename(__FILE__))
	end
end
