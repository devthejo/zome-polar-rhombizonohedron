#https://github.com/takion/zome-polar-rhombizonahedron jo@redcat.ninja

require 'sketchup.rb'
include Math
module Surikat
class RhombiZonaedrePolaire
	def self.generation func
		self.new func
	end
	def initialize func
		eval("#{func}")
	end
	def start
		$mo = Sketchup.active_model
		Sketchup::set_status_text("Modélisation du Zome en cours ...")
		$mo.start_operation "PolarZonahedron - Structure Processing"
		@t1 = Time.now
		$entities = $mo.active_entities.add_group.entities
	end
	def ending
		$mo.commit_operation
		if not $takion_z_l
			UI.messagebox("\nZome Creator" <<
			"\nLogiciel libre développé par Jo - jo@redcat.ninja" <<
			"\nhttps://github.com/takion/zome-polar-rhombizonahedron/", "Zome Creator - Logiciel libre")
			$takion_z_l = true
		end
	end
	def add_note(msg)
		$mo.add_note msg, 0, 0.03
	end
	def rayon_polygone_regulier n_cotes,segment_length
		return (segment_length/2.0)/(Math.sin((360.0/n_cotes)/(2.0*(180.0/Math::PI))))
	end
	def aire_polygone_regulier n_cotes,segment_length,radius
		if not radius
			radius = rayon_polygone_regulier n_cotes,segment_length
		end
		area = n_cotes*(0.5*(segment_length*Math.sqrt((radius*radius)-((segment_length*segment_length)/4.0))))*$u_inch*1000.0
		return area.inch
	end
	def draw_face(pts)
		if($takion_zome['T_Modelisation']=='Faces')
			face = $entities.add_face(pts)
			face.back_material = $takion_zome['RVB_BACK_FACES']
			face.material = $takion_zome['RVB_FACES']
		end
		if($takion_zome['T_Modelisation']=='Squelette')
			line = $entities.add_line( pts )
		end
		if($takion_zome['T_Modelisation']=='Tubes')
			line = $entities.add_line(pts)
			create_tubes(line,$takion_zome['L_TubesDiametre'])
		end
	end
	def create_tubes(line,radius)
		edges = [line]
		verts=[]
		newVerts=[]
		startEdge=startVert=nil
		edges.each {|edge|verts.push(edge.vertices)}
		verts.flatten!
		vertsShort=[]
		vertsLong=[]
		verts.each do |v|
			if vertsLong.include?(v)
				vertsShort.push(v)
			else
				vertsLong.push(v)
			end
		end
		if (startVert=(vertsLong-vertsShort).first)==nil
			startVert=vertsLong.first
			closed=true
			startEdge = startVert.edges.first
		else
			closed=false
			startEdge = (edges & startVert.edges).first
		end
		#SORT VERTICES, LIMITING TO THOSE IN THE SELECTION SET
		if startVert==startEdge.start
			newVerts=[startVert]
			counter=0
			while newVerts.length < verts.length
				edges.each do |edge|
					if edge.end==newVerts.last
						newVerts.push(edge.start)
					elsif edge.start==newVerts.last
						newVerts.push(edge.end)
					end
				end
				counter+=1
				if counter > verts.length
					return nil if UI.messagebox("There seems to be a problem. Try again?", MB_YESNO)!=6
					newVerts.reverse!
					reversed=true
				end
			end
		else
			newVerts=[startVert]
			counter=0
			while newVerts.length < verts.length
				edges.each do |edge|
					if edge.end==newVerts.last
						newVerts.push(edge.start)
					elsif edge.start==newVerts.last
						newVerts.push(edge.end)
					end
				end
				counter+=1
				if counter > verts.length
					return nil if UI.messagebox("There seems to be a problem. Try again?", MB_YESNO)!=6
					newVerts.reverse!
					reversed=true
				end
			end
		end
		###newVerts.uniq! ### allow IF closed
		newVerts.reverse! if reversed
		#CONVERT VERTICES TO POINT3Ds
		newVerts.collect!{|x| x.position}
		###newVerts.push(newVerts[0])
		### now have an array of vertices in order with NO forced closed loop ...
		### - do stuff - ###
		pt1 = newVerts[0]
		pt2 = newVerts[1]
		vec = pt1.vector_to pt2
		theCircle = $entities.add_circle pt1, vec, radius
		# theCircle = $entities.add_ngon pt1, vec, radius, 4
		theFace = $entities.add_face theCircle
		i = 0
		@@theEdges= []
		0.upto(newVerts.length - 2) do |something|
		  @@theEdges[i] = $entities.add_line(newVerts[i],newVerts[i+1])  ### make vertices into edges
		  i = i + 1
		end
		### follow me along selected edges
		theFace.reverse!.followme @@theEdges ###
		$mo.commit_operation
		### restore selection set of edges and display them
		i = 0
		theEdgeX = []
		0.upto(newVerts.length - 2) do |something|
		  theEdgeX[i] = $entities.add_line(newVerts[i],newVerts[i+1])  ### make vertices into edges
		  i = i + 1
		end
		$mo.selection.clear
		$mo.selection.add theEdgeX
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
			p_rotate = Geom::Transformation.rotation( pts[0] , Geom::Vector3d.new(0,0,1), i*2*PI/bases )

			pts[1] = pts[0].transform( vector )
			pts[3] = pts[1].transform( p_rotate )
			pts[2] = pts[3].transform( vector )
			# mb = i*2*PI/bases
			# UI.messagebox "#{mb.radians}"
			points[i] = []
			0.upto(bases-1){ |j| 
				f_rotate = Geom::Transformation.rotation( Geom::Point3d.new(0,0,0) , Geom::Vector3d.new(0,0,1), j*2*PI/bases)
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
					if($takion_zome['T_Tirants']=='Horizontaux')
						if(i<niveaux)
							pt2 = points[i][j][2]
							faces.push [pt1,pt2,pt3] 
						end
						faces.push [pt1,pt4,pt3]
						faces.push [pt3,pt1,pt4] #tirants						
					end
					if($takion_zome['T_Tirants']=='Aucun')
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
			# if($takion_zome['T_Tuiles2D']=='Oui')
				# create_tiles $takion_zome
			# end
			msg += rapport_complet $takion_zome
		end
		return [diametre_r,hauteur_r,msg]
	end
	def create_tiles params
		
	end
	def rapport_complet params
		sixbranch_connection = (@connecteurs_nb-(params['N_Cotes']*2))-1
		tubes_length = params["L_RayonConnecteurs"]*( (params['N_Cotes']*4)+(sixbranch_connection*6)+(params['N_Cotes']*5)+params['N_Cotes'] )
		tubes_length = tubes_length.inch
		rayonConnecteurs = params["L_RayonConnecteurs"].inch
		msg = ""
		msg += " Côtés: #{params["N_Cotes"]} \n"
		msg += " Niveaux: #{params["N_Niveaux"]} \n"
		msg += " Hauteur: #{params["L_Hauteur"]} \n"
		msg += " Diamètre au sol: #{params["L_Diametre"]} \n"
		# msg += " Aire au sol: #{@ground_area}² \n"
		msg += "\n Nombre de Connecteurs: #{@connecteurs_nb} \n"
		msg += " #{params['N_Cotes']} x Connecteurs 4 branches \n"
		msg += " #{sixbranch_connection} x Connecteurs 6 branches \n"
		msg += " #{params['N_Cotes']} x Connecteurs 5 branches \n"
		msg += " 1 x Connecteur #{params['N_Cotes']} branches \n"
		msg += "\n Rayon des connecteurs: #{rayonConnecteurs} \n"
		msg += "  -> Longueur de tube nécessaire: #{tubes_length} \n"
		msg += "\n Nombre Total de Segments: #{@segments_nb} \n"
		# msg += " Longeur totale des segments: #{segments_lenth} \n"
		msg += " Nombre de Tirants: #{@tirants_nb} \n"
		
		return msg
	end
	def zome_al
		config = [
			['N_Cotes',10,'Côtés de Révolution'],
			['N_Niveaux',5,'Niveaux en Hauteur'],
			['L_AngleDeForme',35.2643896827547,'Angle de forme'],
			['L_Arrete',1.m,'Arête'],
			['T_Tirants','Horizontaux','Tirants',"Horizontaux|Aucun"],
			['L_RayonConnecteurs',150.mm,'Rayon des Connecteurs'],
			['T_Ground','Non','Sol',"Oui|Non"],
			['T_Modelisation','Faces','Modélisation',"Squelette|Faces|Tubes"]
		]
		$takion_zome = {} if not $takion_zome
		0.upto(config.length-1){ |i|
			$takion_zome[config[i][0]] = config[i][1] if not $takion_zome[config[i][0]]
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
			results = UI.inputbox prompts,defaults,drops,'Zonohèdre Polaire sur Angle de forme et Arête'
			return unless results
			0.upto(config.length-1){ |i|
				$takion_zome[config[i][0]] = results[i]
			}
			#<validation>
			raise "Nombre de niveaux différents du nombre de côtés requis"  if ( $takion_zome['N_Niveaux'] == $takion_zome['N_Cotes'] )
			raise "Nombre de niveaux non nulle requis"  if ( $takion_zome['N_Niveaux'] <= 0 )
			raise "Minimum 2 niveaux requis pour un Zome cohérent"  if ( $takion_zome['N_Niveaux'] < 2 )
			raise "Nombre de côtés non nulle requis"  if( $takion_zome['N_Cotes'] <= 0 )
			raise "Minimum 3 côtés pour un Zome cohérent"  if ( $takion_zome['N_Cotes'] < 3 )
			raise "Hauteur non nulle requise"  if ( $takion_zome['L_Hauteur'] <= 0 )
			raise "L'angle ne peux pas être à 90"  if ( $takion_zome['L_AngleDeForme'] == 90 )
			#</validation>
		rescue
			UI.messagebox $!.message
			retry
		end
		if($takion_zome['T_Modelisation']=="Tubes")
			begin
				results_tubes = UI.inputbox ['Diamètre des Tubes'],[28.mm],[],'Modélisation Tubes'
				return unless results_tubes
				$takion_zome['L_TubesDiametre'] = results_tubes[0]
				raise "Valeur non nulle requise"  if ( $takion_zome['L_TubesDiametre'] <= 0 )
			rescue
				UI.messagebox $!.message
				retry
			end			
		end
		
		start
		
		angle_forme = $takion_zome['L_AngleDeForme'].degrees
		hypotenus = $takion_zome['L_Arrete']
		msg = ""
		
		sinus = cos(angle_forme)
		cosinus = sin(angle_forme)
		retour = create_polarzonaedre(true,$takion_zome['N_Cotes'],$takion_zome['N_Niveaux'],sinus,cosinus,hypotenus)
		
		msg += "Bases: #{$takion_zome['N_Cotes']} \n"
		msg += "Niveaux: #{$takion_zome['N_Niveaux']} \n"
		msg += "Diamètre: #{retour[0].inch} \n"
		msg += "Hauteur: #{retour[1].inch} \n"
		msg += "Angle de forme: #{angle_forme.radians} \n"
		msg += "Arête: #{hypotenus.inch} \n"
		
		msg += retour[2]
		
		add_note msg
		ending
	end

	def zome_ah
		config = [
			['N_Cotes',10,'Côtés de Révolution'],
			['N_Niveaux',5,'Niveaux en Hauteur'],
			['L_AngleDeForme',35.2643896827547,'Angle de forme'],
			['L_Hauteur',3000.mm,'Hauteur au Sommet'],
			['T_Tirants','Horizontaux','Tirants',"Horizontaux|Aucun"],
			['L_RayonConnecteurs',150.mm,'Rayon des Connecteurs'],
			['T_Ground','Non','Sol',"Oui|Non"],
			['T_Modelisation','Faces','Modélisation',"Squelette|Faces|Tubes"]
		]
		$takion_zome = {} if not $takion_zome
		0.upto(config.length-1){ |i|
			$takion_zome[config[i][0]] = config[i][1] if not $takion_zome[config[i][0]]
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
			results = UI.inputbox prompts,defaults,drops,'RhombiZonaèdre Polaire sur Angle de forme et Hauteur'
			return unless results
			0.upto(config.length-1){ |i|
				$takion_zome[config[i][0]] = results[i]
			}
			#<validation>
			raise "Nombre de niveaux non nulle requis"  if ( $takion_zome['N_Niveaux'] <= 0 )
			raise "Minimum 2 niveaux requis pour un Zome cohérent"  if ( $takion_zome['N_Niveaux'] < 2 )
			raise "Nombre de côtés non nulle requis"  if( $takion_zome['N_Cotes'] <= 0 )
			raise "Minimum 3 côtés pour un Zome cohérent"  if ( $takion_zome['N_Cotes'] < 3 )
			raise "Hauteur non nulle requise"  if ( $takion_zome['L_Hauteur'] <= 0 )
			raise "L'angle ne peux pas être à 90"  if ( $takion_zome['L_AngleDeForme'] == 90 )
			#</validation>
		rescue
			UI.messagebox $!.message
			retry
		end
		if($takion_zome['T_Modelisation']=="Tubes")
			begin
				results_tubes = UI.inputbox ['Diamètre des Tubes'],[28.mm],[],'Modélisation Tubes'
				return unless results_tubes
				$takion_zome['L_TubesDiametre'] = results_tubes[0]
				raise "Valeur non nulle requise"  if ( $takion_zome['L_TubesDiametre'] <= 0 )
			rescue
				UI.messagebox $!.message
				retry
			end			
		end
		
		start
		
		msg = ""
		
		angle_forme = $takion_zome['L_AngleDeForme'].degrees

		adjacent = $takion_zome['L_Hauteur']/$takion_zome['N_Niveaux']
		hypotenus = adjacent/angle_forme
		oppose = sqrt(hypotenus*hypotenus - adjacent*adjacent)
		
		sinus = cos(angle_forme)
		cosinus = sin(angle_forme)
		
		retour1 = create_polarzonaedre(false,$takion_zome['N_Cotes'],$takion_zome['N_Niveaux'],sinus,cosinus,hypotenus)
		hypotenus *= $takion_zome['L_Hauteur']/retour1[1]
		retour2 = create_polarzonaedre(true,$takion_zome['N_Cotes'],$takion_zome['N_Niveaux'],sinus,cosinus,hypotenus)
		
		msg += "Bases: #{$takion_zome['N_Cotes']} \n"
		msg += "Niveaux: #{$takion_zome['N_Niveaux']} \n"
		msg += "Diamètre: #{retour2[0].inch} \n"
		msg += "Hauteur: #{retour2[1].inch} \n"
		msg += "Angle de forme: #{angle_forme.radians} \n"
		msg += "Arête: #{hypotenus.inch} \n"
		msg += retour2[2]
		add_note msg
		ending
	end

	def zomes_ad		
		config = [
			['N_Cotes',10,'Côtés de Révolution'],
			['N_Niveaux',5,'Niveaux en Hauteur'],
			['L_AngleDeForme',35.2643896827547,'Angle de forme'],
			['L_Diametre',6000.mm,'Diamètre au sol'],
			['L_RayonConnecteurs',150.mm,'Rayon des Connecteurs'],
			['T_Ground','Non','Sol',"Oui|Non"],
			['T_Modelisation','Faces','Modélisation',"Squelette|Faces|Tubes"]
		]
		$takion_zome = {} if not $takion_zome
		0.upto(config.length-1){ |i|
			$takion_zome[config[i][0]] = config[i][1] if not $takion_zome[config[i][0]]
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
			results = UI.inputbox prompts,defaults,drops,'RhombiZonaèdre Polaire sur Angle de forme et Diamètre'
			return unless results
			0.upto(config.length-1){ |i|
				$takion_zome[config[i][0]] = results[i]
			}
			#<validation>
			raise "Nombre de niveaux non nulle requis"  if ( $takion_zome['N_Niveaux'] <= 0 )
			raise "Minimum 2 niveaux requis pour un Zome cohérent"  if ( $takion_zome['N_Niveaux'] < 2 )
			raise "Nombre de côtés non nulle requis"  if( $takion_zome['N_Cotes'] <= 0 )
			raise "Minimum 3 côtés pour un Zome cohérent"  if ( $takion_zome['N_Cotes'] < 3 )
			raise "Diamètre non nulle requis"  if ( $takion_zome['L_Diametre'] <= 0 )
			raise "L'angle ne peux pas être à 90"  if ( $takion_zome['L_AngleDeForme'] == 90 )
			#</validation>
		rescue
			UI.messagebox $!.message
			retry
		end
		if($takion_zome['T_Modelisation']=="Tubes")
			begin
				results_tubes = UI.inputbox ['Diamètre des Tubes'],[28.mm],[],'Modélisation Tubes'
				return unless results_tubes
				$takion_zome['L_TubesDiametre'] = results_tubes[0]
				raise "Valeur non nulle requise"  if ( $takion_zome['L_TubesDiametre'] <= 0 )
			rescue
				UI.messagebox $!.message
				retry
			end			
		end
		
		start
		
		
		msg = ""
		
		angle_forme = $takion_zome['L_AngleDeForme'].degrees
		hypotenus = $takion_zome['L_Diametre']/2/PI
		
		sinus = cos(angle_forme)
		cosinus = sin(angle_forme)

		retour1 = create_polarzonaedre(false,$takion_zome['N_Cotes'],$takion_zome['N_Niveaux'],sinus,cosinus,hypotenus)
		
		hypotenus *= $takion_zome['L_Diametre']/retour1[0]	
		retour2 = create_polarzonaedre(true,$takion_zome['N_Cotes'],$takion_zome['N_Niveaux'],sinus,cosinus,hypotenus)
		
		msg += "Bases: #{$takion_zome['N_Cotes']} \n"
		msg += "Niveaux: #{$takion_zome['N_Niveaux']} \n"
		msg += "Diamètre: #{$takion_zome['L_Diametre'].inch} \n"
		msg += "Hauteur: #{retour2[1].inch} \n"
		msg += "Angle de forme: #{angle_forme.radians} \n"
		msg += "Arête: #{hypotenus.inch} \n"
		msg += retour2[2]
		add_note msg
		ending
	end

	def zome_dh
		config = [	
			['N_Cotes',10,'Côtés de Révolution'],
			['N_Niveaux',5,'Niveaux en Hauteur'],
			['L_Diametre',6000.mm,'Diamètre au sol'],
			['L_Hauteur',3000.mm,'Hauteur au Sommet'],
			['T_Tirants','Aucun','Tirants',"Horizontaux|Aucun"],
			['L_RayonConnecteurs',150.mm,'Rayon des Connecteurs'],
			['T_Ground','Non','Sol',"Oui|Non"],
			['T_Modelisation','Squelette','Modélisation',"Squelette|Faces|Tubes"]
		]
		$takion_zome = {} if not $takion_zome
		0.upto(config.length-1){ |i|
			$takion_zome[config[i][0]] = config[i][1] if not $takion_zome[config[i][0]]
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
			results = UI.inputbox prompts,defaults,drops,'RhombiZonaèdre Polaire sur Diamètre et Hauteur'
			return unless results
			0.upto(config.length-1){ |i|
				$takion_zome[config[i][0]] = results[i]
			}
			#<validation>
			raise "Nombre de niveaux non nulle requis"  if ( $takion_zome['N_Niveaux'] <= 0 )
			raise "Minimum 2 niveaux requis pour un Zome cohérent"  if ( $takion_zome['N_Niveaux'] < 2 )
			raise "Nombre de côtés non nulle requis"  if( $takion_zome['N_Cotes'] <= 0 )
			raise "Minimum 3 côtés pour un Zome cohérent"  if ( $takion_zome['N_Cotes'] < 3 )
			raise "Diamètre non nulle requis"  if ( $takion_zome['L_Diametre'] <= 0 )
			raise "Hauteur non nulle requise"  if ( $takion_zome['L_Hauteur'] <= 0 )
			#</validation>
		rescue
			UI.messagebox $!.message
			retry
		end
		if($takion_zome['T_Modelisation']=="Tubes")
			begin
				results_tubes = UI.inputbox ['Diamètre des Tubes'],[28.mm],[],'Modélisation Tubes'
				return unless results_tubes
				$takion_zome['L_TubesDiametre'] = results_tubes[0]
				raise "Valeur non nulle requise"  if ( $takion_zome['L_TubesDiametre'] <= 0 )
			rescue
				UI.messagebox $!.message
				retry
			end			
		end
		
		start
		
		
		msg = ""
		
		adjacent = $takion_zome['L_Hauteur']/$takion_zome['N_Niveaux']
		
		oppose = $takion_zome['L_Diametre']/$takion_zome['N_Niveaux']/2
		hypotenus = sqrt(adjacent*adjacent + oppose*oppose)
		sinus = oppose/hypotenus
		cosinus = adjacent/hypotenus
		retour1 = create_polarzonaedre(false,$takion_zome['N_Cotes'],$takion_zome['N_Niveaux'],sinus,cosinus,hypotenus)
		ndiametre = $takion_zome['L_Diametre']*($takion_zome['L_Diametre']/retour1[0])
		
		oppose = ndiametre/$takion_zome['N_Niveaux']/2
		hypotenus = sqrt(adjacent*adjacent + oppose*oppose)
		sinus = oppose/hypotenus
		cosinus = adjacent/hypotenus
		retour2 = create_polarzonaedre(true,$takion_zome['N_Cotes'],$takion_zome['N_Niveaux'],sinus,cosinus,hypotenus)
		
		msg += "Bases: #{$takion_zome['N_Cotes']} \n"
		msg += "Niveaux: #{$takion_zome['N_Niveaux']} \n"
		msg += "Diamètre: #{$takion_zome['L_Diametre'].inch} \n"
		msg += "Hauteur: #{$takion_zome['L_Hauteur'].inch} \n"
		msg += "Arête: #{hypotenus.inch} \n"
		# msg += "Angle de forme: #{asin(cosinus).radians} \n"
		msg += "Angle de forme: #{acos(sinus).radians} \n"
		msg += "Angle entre l'axe et l'arête du dernier niveaux: #{asin(sinus).radians} \n"
		
		msg += retour2[2]
		
		add_note msg
		ending
	end
end
end

zomes_menu = UI.menu("Plugins").add_submenu("Zome")
zomes_menu.add_item("sur diametre et hauteur") { Surikat::RhombiZonaedrePolaire.generation('zome_dh') }
zomes_menu.add_item("sur angle et arête") { Surikat::RhombiZonaedrePolaire.generation('zome_al') }
zomes_menu.add_item("sur angle et hauteur") { Surikat::RhombiZonaedrePolaire.generation('zome_ah') }
zomes_menu.add_item("sur angle et diametre") { Surikat::RhombiZonaedrePolaire.generation('zomes_ad') }
file_loaded(File.basename(__FILE__))
