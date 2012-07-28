$: << '.' unless $:.include? '.'
require 'ncplaylister/ncrss'
require 'ncplaylister/nocontrol'

class NCPlaylister

  def self.test
    NoControl.test
  end

end