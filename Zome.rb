module Takion
  module Zome

    require 'sketchup.rb'
    require 'extensions.rb'
    require 'langhandler.rb'
    
    LH = LanguageHandler.new('Zome.strings')
    if !LH.respond_to?(:[])
      def LH.[](key)
        GetString(key)
      end
    end
    
    zome_extension = SketchupExtension.new('Zome', 'Zome/main.rb')
    zome_extension.version = '1.2.4'
    zome_extension.copyright = '2018'
    zome_extension.description = LH['Zome Creator - PolarZonahedron']
    zome_extension.creator = 'Jo Takion <jo@redcat.ninja>'
    Sketchup.register_extension(zome_extension, true)
    
  end
end
