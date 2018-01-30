require 'sketchup.rb'
require 'extensions.rb'

zome_extension = SketchupExtension.new('Zome', 'Zome/core.rb')
zome_extension.version = '1.2.4'
zome_extension.copyright = '2018'
zome_extension.description = 'Zome Creator - PolarZonahedron'
zome_extension.creator = 'Jo Takion <jo@redcat.ninja>'
Sketchup.register_extension(zome_extension, true)
